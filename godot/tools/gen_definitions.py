#!/usr/bin/env python3
"""Generate Tarrock's Godot definition resources from the design docs.

`docs/` is the source of truth (CLAUDE.md, SSOT rules). Where a doc is already a
table, the `.tres` definitions under `godot/data/` are *generated* from it rather
than transcribed by hand, and a drift test runs this tool in `--check` mode so a
canon edit can never silently fail to reach the game
(docs/design/technical.md, "Generated vs. hand-authored").

What it reads, and what each source produces:

    docs/design/world.md  §World-state matrix   -> one WorldStateDefinition per row
                                                   (UNBINDING), plus one per branch
                                                   flag a row's Effect cell names
                                                   (BRANCH), plus the catalog, plus
                                                   the WorldStateIds constants
    docs/design/world.md  §Global states        -> act_thresholds.tres
    docs/design/progression.md §Renown          -> renown_ladder.tres
    docs/quests/**/*.md   YAML frontmatter      -> one QuestDefinition per quest,
                                                   plus the quest catalog, the
                                                   QuestIds constants, and the
                                                   quest-title translation table
    docs/GLOSSARY.md      §The world            -> the region-name -> region-token
                                                   mapping quest definitions carry
    docs/design/arcana.md §per-Trump blocks      -> one TrumpDefinition per Trump,
                                                   plus the Trump catalog, the
                                                   TrumpIds constants, and the
                                                   Trump-name translation table

A Trump's *effects* are deliberately NOT generated, for the same reason a quest's
state graph is not: what a Trump does is prose, hand-authored under
`godot/data/trumps/effects/TRUMP_NN.tres`, and a generated definition merely links
to it when that file exists. The generator never writes into `effects/`.

A quest's *state graph* is deliberately NOT generated: it is hand-authored under
`godot/data/quests/graphs/<ID>.tres`, and a generated definition merely links to it
when that file exists. So authoring a quest is writing its graph, and regenerating
metadata after a frontmatter edit can never clobber authored work. The generator
never writes into `graphs/` and never calls anything there stale.

It also reads every quest's YAML frontmatter and prints, informationally, any
`WS_*` id a quest names that the matrix does not define. That list is a report to
a human, not a failure: quests are reviewed against `docs/quests/README.md`, and
this tool never edits `docs/`.

Usage:

    python3 godot/tools/gen_definitions.py --write   # write the resources
    python3 godot/tools/gen_definitions.py --check   # exit 1 if anything differs

Python 3 standard library only, deterministic, idempotent: running `--write`
twice changes nothing, and `--check` is exactly `--write` into a temporary
directory followed by a comparison.
"""

from __future__ import annotations

import argparse
import difflib
import re
import sys
import tempfile
from pathlib import Path

# --- Where things live -------------------------------------------------------

TOOLS_DIR = Path(__file__).resolve().parent
GODOT_DIR = TOOLS_DIR.parent
REPO_ROOT = GODOT_DIR.parent
DOCS_DIR = REPO_ROOT / "docs"

WORLD_DOC = DOCS_DIR / "design" / "world.md"
PROGRESSION_DOC = DOCS_DIR / "design" / "progression.md"
ARCANA_DOC = DOCS_DIR / "design" / "arcana.md"
GLOSSARY_DOC = DOCS_DIR / "GLOSSARY.md"
QUESTS_DIR = DOCS_DIR / "quests"

WORLD_STATE_DATA_DIR = "data/world_states"
PROGRESSION_DATA_DIR = "data/progression"
QUEST_DATA_DIR = "data/quests"
QUEST_GRAPH_DIR = f"{QUEST_DATA_DIR}/graphs"
TRUMP_DATA_DIR = "data/trumps"
TRUMP_EFFECTS_DIR = f"{TRUMP_DATA_DIR}/effects"
WORLD_STATE_SYSTEM_DIR = "systems/world_state"
QUEST_SYSTEM_DIR = "systems/quests"
TRUMP_SYSTEM_DIR = "systems/trumps"
LOCALIZATION_DIR = "localization"

DEFINITION_SCRIPT = "res://systems/world_state/definitions/world_state_definition.gd"
CATALOG_SCRIPT = "res://systems/world_state/definitions/world_state_catalog.gd"
ACT_THRESHOLDS_SCRIPT = "res://systems/world_state/definitions/act_thresholds.gd"
RENOWN_LADDER_SCRIPT = "res://systems/world_state/definitions/renown_ladder.gd"
QUEST_DEFINITION_SCRIPT = "res://systems/quests/definitions/quest_definition.gd"
QUEST_CATALOG_SCRIPT = "res://systems/quests/definitions/quest_catalog.gd"
QUEST_BRANCH_GROUP_SCRIPT = "res://systems/quests/definitions/quest_branch_group.gd"
TRUMP_DEFINITION_SCRIPT = "res://systems/trumps/definitions/trump_definition.gd"
TRUMP_CATALOG_SCRIPT = "res://systems/trumps/definitions/trump_catalog.gd"

CATALOG_PATH = f"{WORLD_STATE_DATA_DIR}/catalog.tres"
ACT_THRESHOLDS_PATH = f"{WORLD_STATE_DATA_DIR}/act_thresholds.tres"
RENOWN_LADDER_PATH = f"{PROGRESSION_DATA_DIR}/renown_ladder.tres"
WORLD_STATE_IDS_PATH = f"{WORLD_STATE_SYSTEM_DIR}/world_state_ids.gd"
QUEST_CATALOG_PATH = f"{QUEST_DATA_DIR}/catalog.tres"
QUEST_IDS_PATH = f"{QUEST_SYSTEM_DIR}/quest_ids.gd"
QUEST_TITLES_CSV_PATH = f"{LOCALIZATION_DIR}/quest_titles.csv"
TRUMP_CATALOG_PATH = f"{TRUMP_DATA_DIR}/catalog.tres"
TRUMP_IDS_PATH = f"{TRUMP_SYSTEM_DIR}/trump_ids.gd"
TRUMP_NAMES_CSV_PATH = f"{LOCALIZATION_DIR}/trumps.csv"

# Hand-authored files that live inside a generated directory. They are NOT swept as
# stale and are never written by this tool: `spread_rules.tres` is authored from
# `docs/design/progression.md`'s prose (the numbers it fixes and the ones it leaves
# TBD), which no table in the docs can produce.
HAND_AUTHORED_PATHS = {
    f"{PROGRESSION_DATA_DIR}/spread_rules.tres",
}

# Every directory this tool writes into, and what it owns there: anything matching
# the glob that this run would not produce is stale (see `stale_paths`). The data
# directories are generated whole; the system directory is hand-written code that
# happens to hold one generated file, so only that file's own name is swept.
GENERATED_GLOBS = {
    WORLD_STATE_DATA_DIR: ["*.tres"],
    # `renown_ladder.tres` is generated here; `spread_rules.tres` is hand-authored
    # and is spared by `HAND_AUTHORED_PATHS` rather than by a narrower glob, so the
    # exception is written down once, by name.
    PROGRESSION_DATA_DIR: ["*.tres"],
    # `data/quests/*.tres` is generated whole; `data/quests/graphs/*.tres` is
    # hand-authored and is NOT swept - the glob is deliberately not recursive.
    QUEST_DATA_DIR: ["*.tres"],
    # Same shape for Trumps: `data/trumps/*.tres` is generated whole and
    # `data/trumps/effects/*.tres` is hand-authored, so the glob stays flat.
    TRUMP_DATA_DIR: ["*.tres"],
    WORLD_STATE_SYSTEM_DIR: [WORLD_STATE_IDS_PATH.rsplit("/", 1)[-1]],
    QUEST_SYSTEM_DIR: [QUEST_IDS_PATH.rsplit("/", 1)[-1]],
    TRUMP_SYSTEM_DIR: [TRUMP_IDS_PATH.rsplit("/", 1)[-1]],
    LOCALIZATION_DIR: [
        QUEST_TITLES_CSV_PATH.rsplit("/", 1)[-1],
        TRUMP_NAMES_CSV_PATH.rsplit("/", 1)[-1],
    ],
}

# --- What the docs say -------------------------------------------------------

MATRIX_HEADING = "## World-state matrix"
GLOBAL_STATES_HEADING = "## Global states (act thresholds)"
RENOWN_HEADING = "## Renown"

WORLD_MATRIX_DOC_REF = "docs/design/world.md §World-state matrix"
GLOBAL_STATES_DOC_REF = "docs/design/world.md §Global states (act thresholds)"
RENOWN_DOC_REF = "docs/design/progression.md §Renown"
ARCANA_DOC_REF = "docs/design/arcana.md"

ACT_THRESHOLDS_ID = "ACT_THRESHOLDS"
RENOWN_LADDER_ID = "RENOWN_LADDER"

# The five-tier ladder's *tiers* are canon (progression.md §Renown); the numbers at
# which a suit's standing crosses from one tier to the next are not - they are
# tuning, and nothing in docs/ has set them yet. These placeholders keep the
# resource loadable and the service testable; the `notes` field says so in the data.
RENOWN_TIER_MIN_PLACEHOLDERS = [0, 10, 25, 50, 100]
RENOWN_TIER_NOTES = "thresholds TBD (tuning; not canon) - progression.md owns the tiers, not the numbers"

# A world-state id, wherever one appears.
WS_ID_PATTERN = re.compile(r"WS_[A-Z0-9_]+")
# A quest id in a "Fired by" cell.
QUEST_ID_PATTERN = re.compile(r"MQ(\d{2})")
# The first whole number in a cell, e.g. "7-14 unbound" -> 7.
FIRST_NUMBER_PATTERN = re.compile(r"\d+")

# Card numbers an unbinding flag may carry, mirroring WorldStateDefinition.
FIRST_ARCANA = 1
LAST_ARCANA = 21

# Suffix appended to a branch group id when the members share no common word.
GENERIC_BRANCH_GROUP = "BRANCH"

# Frontmatter keys whose values may name world-state flags.
QUEST_FLAG_KEYS = ("requires", "fires", "branches")


class GeneratorError(RuntimeError):
    """A doc did not have the shape this tool relies on."""


# --- Markdown reading --------------------------------------------------------


def read_section(doc_path: Path, heading: str) -> list[str]:
    """The lines under `heading`, up to the next heading of the same or higher level."""
    text = doc_path.read_text(encoding="utf-8")
    level = len(heading) - len(heading.lstrip("#"))
    lines = text.splitlines()
    try:
        start = lines.index(heading)
    except ValueError as error:
        raise GeneratorError(f"{doc_path} has no '{heading}' section") from error
    section: list[str] = []
    for line in lines[start + 1 :]:
        if line.startswith("#"):
            depth = len(line) - len(line.lstrip("#"))
            if depth <= level:
                break
        section.append(line)
    return section


def tables(lines: list[str]) -> list[list[list[str]]]:
    """Every markdown table in `lines`, each as its body rows of stripped cells.

    A section can hold more than one table (§Renown carries the deed/reaction table
    and then the tier ladder), so they are kept apart rather than concatenated.
    """
    found: list[list[list[str]]] = []
    rows: list[list[str]] = []
    seen_separator = False
    for line in lines:
        stripped = line.strip()
        if not stripped.startswith("|"):
            if rows:
                found.append(rows)
            rows = []
            seen_separator = False
            continue
        cells = [cell.strip() for cell in stripped.strip("|").split("|")]
        if all(set(cell) <= {"-", ":"} and cell for cell in cells):
            seen_separator = True
            continue
        if not seen_separator:
            continue  # the header row
        rows.append(cells)
    if rows:
        found.append(rows)
    return found


def table_rows(lines: list[str]) -> list[list[str]]:
    """Every body row of the first markdown table in `lines`, as stripped cells."""
    found = tables(lines)
    return found[0] if found else []


def unwrap(cell: str) -> str:
    """A table cell with markdown emphasis and code ticks removed."""
    return cell.replace("`", "").replace("**", "").strip()


# --- The world-state matrix --------------------------------------------------


class Flag:
    """One generated WorldStateDefinition."""

    def __init__(
        self,
        state_id: str,
        kind: int,
        fired_by: str,
        arcana_number: int,
        branch_group: str,
        effect_summary: str,
        doc_ref: str,
    ) -> None:
        self.state_id = state_id
        self.kind = kind  # 0 = UNBINDING, 1 = BRANCH (WorldStateDefinition.Kind)
        self.fired_by = fired_by
        self.arcana_number = arcana_number
        self.branch_group = branch_group
        self.effect_summary = effect_summary
        self.doc_ref = doc_ref

    @property
    def is_unbinding(self) -> bool:
        return self.kind == 0

    @property
    def resource_path(self) -> str:
        return f"{WORLD_STATE_DATA_DIR}/{self.state_id}.tres"


def branch_group_id(quest_id: str, member_ids: list[str]) -> str:
    """The stable id of a mutually exclusive set, e.g. `MQ01_TROUPE`.

    The members' own names carry the group: `WS_TROUPE_TRAVELING` and
    `WS_TROUPE_SETTLED` share the word TROUPE. Where they share nothing, the group
    falls back to `<quest>_BRANCH`, which is still unique per quest.
    """
    words = [state_id[len("WS_") :].split("_") for state_id in member_ids]
    common: list[str] = []
    for index in range(min(len(word_list) for word_list in words)):
        candidates = {word_list[index] for word_list in words}
        if len(candidates) != 1:
            break
        common.append(words[0][index])
    if not common:
        return f"{quest_id}_{GENERIC_BRANCH_GROUP}"
    return f"{quest_id}_{'_'.join(common)}"


def parse_matrix(doc_path: Path) -> list[Flag]:
    """Every flag the matrix defines, in doc order, each row followed by its branches.

    The matrix is in card order (MQ01..MQ21), which is what gives each unbinding its
    `arcana_number`; the "Fired by" column is checked against that position rather
    than trusted, so a reordered or missing row fails here instead of shipping.
    """
    rows = table_rows(read_section(doc_path, MATRIX_HEADING))
    if len(rows) != LAST_ARCANA:
        raise GeneratorError(
            f"{MATRIX_HEADING} has {len(rows)} rows, expected {LAST_ARCANA}"
        )
    # An Effect cell names other flags for two different reasons: an unbinding's own
    # row (WS_STAR_UNBOUND's sky "requires night: fully visible only with
    # `WS_SUN_UNBOUND`"), or a branch this quest's choice picks between. The row ids
    # are what tells them apart - a branch flag has no row of its own.
    row_ids = {unwrap(cells[0]) for cells in rows if cells}
    flags: list[Flag] = []
    for position, cells in enumerate(rows, start=FIRST_ARCANA):
        if len(cells) != 3:
            raise GeneratorError(f"matrix row {position} has {len(cells)} columns, expected 3")
        state_id = unwrap(cells[0])
        fired_by = unwrap(cells[1])
        effect = cells[2].strip()
        if not WS_ID_PATTERN.fullmatch(state_id):
            raise GeneratorError(f"matrix row {position} has a malformed id: {state_id!r}")
        quest_match = QUEST_ID_PATTERN.fullmatch(fired_by)
        if quest_match is None:
            raise GeneratorError(f"{state_id} is fired by {fired_by!r}, which is no quest id")
        if int(quest_match.group(1)) != position:
            raise GeneratorError(
                f"{state_id} sits at matrix position {position} but is fired by {fired_by}"
            )
        flags.append(
            Flag(
                state_id=state_id,
                kind=0,
                fired_by=fired_by,
                arcana_number=position,
                branch_group="",
                effect_summary=effect,
                doc_ref=WORLD_MATRIX_DOC_REF,
            )
        )
        branch_ids = [
            found
            for found in dict.fromkeys(WS_ID_PATTERN.findall(effect))
            if found not in row_ids
        ]
        if not branch_ids:
            continue
        if len(branch_ids) < 2:
            raise GeneratorError(
                f"{state_id}'s effect names one branch flag ({branch_ids[0]}); a choice needs two"
            )
        group = branch_group_id(fired_by, branch_ids)
        for branch_id in branch_ids:
            flags.append(
                Flag(
                    state_id=branch_id,
                    kind=1,
                    fired_by=fired_by,
                    arcana_number=0,
                    branch_group=group,
                    # No effect summary: the parent row's Effect describes what the
                    # *unbinding* does, and copying it onto a branch flag would read
                    # as canon this flag asserts. `world.md` says nothing about the
                    # branch flag itself beyond naming it, so the definition says
                    # nothing either - `doc_ref` points at the cell that names it.
                    effect_summary="",
                    doc_ref=f"{WORLD_MATRIX_DOC_REF} ({state_id} row)",
                )
            )
    return flags


def parse_act_thresholds(doc_path: Path) -> tuple[int, int]:
    """`(act_ii_min, act_iii_min)` from §Global states' Condition column."""
    minimums: dict[str, int] = {}
    for cells in table_rows(read_section(doc_path, GLOBAL_STATES_HEADING)):
        if len(cells) < 2:
            continue
        state = unwrap(cells[0])
        if state not in ("ACT_II", "ACT_III"):
            continue
        found = FIRST_NUMBER_PATTERN.search(cells[1])
        if found is None:
            raise GeneratorError(f"{state}'s condition names no number: {cells[1]!r}")
        minimums[state] = int(found.group())
    for state in ("ACT_II", "ACT_III"):
        if state not in minimums:
            raise GeneratorError(f"{GLOBAL_STATES_HEADING} has no {state} row")
    return minimums["ACT_II"], minimums["ACT_III"]


def parse_renown_tiers(doc_path: Path) -> list[str]:
    """The tier words of §Renown's five-tier ladder, lowest standing first."""
    tiers: dict[int, str] = {}
    for rows in tables(read_section(doc_path, RENOWN_HEADING)):
        for cells in rows:
            if len(cells) != 2:
                continue  # the deed/reaction table, which has five columns
            number = unwrap(cells[0])
            if not number.isdigit():
                continue
            tiers[int(number)] = unwrap(cells[1])
    if not tiers:
        raise GeneratorError(f"{RENOWN_HEADING} has no tier table")
    expected = list(range(1, len(tiers) + 1))
    if sorted(tiers) != expected:
        raise GeneratorError(f"the Renown ladder's tiers are numbered {sorted(tiers)}")
    return [tiers[number] for number in expected]


# --- Quest frontmatter (informational) ---------------------------------------


def quest_flag_references(quests_dir: Path) -> dict[str, list[str]]:
    """Every `WS_*` id named by a quest's `requires`/`fires`/`branches`, by id."""
    references: dict[str, list[str]] = {}
    for path in sorted(quests_dir.rglob("*.md")):
        block = frontmatter_lines(path)
        if not block:
            continue
        for state_id in sorted(set(WS_ID_PATTERN.findall(flag_values(block)))):
            references.setdefault(state_id, []).append(
                str(path.relative_to(REPO_ROOT))
            )
    return references


def frontmatter_lines(path: Path) -> list[str]:
    """The lines between the opening `---` fence and its close; empty when absent."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return []
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return lines[1:index]
    return []


def flag_values(block: list[str]) -> str:
    """The frontmatter's flag-bearing values, joined - keys and comments dropped.

    `requires`/`fires` are inline lists; `branches` is a YAML list of lists on the
    following indented lines. Both are collected by taking a flag key's own line
    plus every indented line under it, minus trailing `#` comments (which explain
    the schema in `docs/quests/README.md`'s example and must not be read as data).
    """
    collected: list[str] = []
    collecting = False
    for line in block:
        without_comment = line.split("#", 1)[0]
        if not without_comment.strip():
            continue
        indented = without_comment[0].isspace() or without_comment.lstrip().startswith("-")
        if indented:
            if collecting:
                collected.append(without_comment)
            continue
        key, _, value = without_comment.partition(":")
        collecting = key.strip() in QUEST_FLAG_KEYS
        if collecting:
            collected.append(value)
    return "\n".join(collected)


# --- Regions (docs/GLOSSARY.md §The world) -----------------------------------


# The heading of the glossary's region table. Matched by prefix because the heading
# carries a parenthetical pointer at `design/world.md` that is not an id.
GLOSSARY_WORLD_HEADING_PREFIX = "## The world"

# The world-spanning pseudo-region `SQ-SPREAD-*` quests are homed to. The glossary
# defines "The Spread" as the world itself rather than as a row of the region table,
# so it is named here and nowhere else.
SPREAD_REGION_NAME = "The Spread"

# A gloss a quest's `region:` may carry after the name, e.g.
# "The Spread (world-spanning - all 21 regions plus the Cliff)". Prose for a reader;
# never part of the region's identity.
REGION_GLOSS_PATTERN = re.compile(r"\s*\(.*\)\s*$")

# Articles a region token drops: `The Cliff` -> `CLIFF`, per the `SQ-<REGION>-<nn>`
# scheme `docs/quests/README.md` owns ("uppercase, no 'the'").
REGION_ARTICLE = "The "


def region_token(name: str) -> str:
    """`The Mirrormarsh` -> `MIRRORMARSH`, the token side-quest ids already use."""
    bare = name[len(REGION_ARTICLE) :] if name.startswith(REGION_ARTICLE) else name
    return re.sub(r"[^A-Za-z0-9]", "", bare).upper()


def find_heading(doc_path: Path, prefix: str) -> str:
    """The one heading line in `doc_path` starting with `prefix`."""
    found = [
        line
        for line in doc_path.read_text(encoding="utf-8").splitlines()
        if line.startswith(prefix)
    ]
    if len(found) != 1:
        raise GeneratorError(f"{doc_path} has {len(found)} headings starting '{prefix}'")
    return found[0]


def parse_regions(doc_path: Path) -> dict[str, str]:
    """`region name -> region token` from the glossary's region table, plus the Spread.

    The glossary is the SSOT for every proper noun (CLAUDE.md), so the region names a
    quest's `region:` may use are exactly this table's first column. A quest naming
    anything else fails the generator rather than inventing a token.
    """
    heading = find_heading(doc_path, GLOSSARY_WORLD_HEADING_PREFIX)
    names = [unwrap(cells[0]) for cells in table_rows(read_section(doc_path, heading)) if cells]
    if not names:
        raise GeneratorError(f"{heading} has no region table")
    names.append(SPREAD_REGION_NAME)
    regions: dict[str, str] = {}
    for name in names:
        token = region_token(name)
        if not token:
            raise GeneratorError(f"the region {name!r} yields no token")
        if token in regions.values():
            raise GeneratorError(f"two regions share the token {token}")
        regions[name] = token
    return regions


# --- Quest frontmatter (docs/quests/**/*.md) ---------------------------------


# `arcana:` values, e.g. "XVIII. The Moon". The roman numeral is the card number and
# is the only part read; "none" means the quest belongs to no card.
ARCANA_NONE = "none"
ROMAN_NUMERALS = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7,
    "VIII": 8, "IX": 9, "X": 10, "XI": 11, "XII": 12, "XIII": 13, "XIV": 14,
    "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20, "XXI": 21,
}

# `type:` values, mapped onto QuestDefinition.Type.
QUEST_TYPES = {"main": 0, "side": 1}

# The two id shapes `docs/quests/README.md` allows.
QUEST_ID_SHAPE = re.compile(r"^(MQ\d{2}|SQ-[A-Z]+-\d{2})$")

# The frontmatter keys a QuestDefinition is built from. `status` is deliberately
# absent: it is doc workflow, not game data (technical.md's mapping table).
REQUIRED_FRONTMATTER_KEYS = ("id", "title", "type", "arcana", "region")

# One `- [A, B]` line of a `branches:` block.
BRANCH_ROW_PATTERN = re.compile(r"^\s*-\s*\[(.*)\]\s*$")


class Quest:
    """One generated QuestDefinition."""

    def __init__(
        self,
        quest_id: str,
        title: str,
        quest_type: int,
        arcana_number: int,
        region_id: str,
        required_states: list[str],
        fired_states: list[str],
        branch_groups: list[tuple[str, list[str]]],
        doc_path: str,
    ) -> None:
        self.quest_id = quest_id
        self.title = title
        self.quest_type = quest_type
        self.arcana_number = arcana_number
        self.region_id = region_id
        self.required_states = required_states
        self.fired_states = fired_states
        self.branch_groups = branch_groups
        self.doc_path = doc_path

    @property
    def is_main(self) -> bool:
        return self.quest_type == QUEST_TYPES["main"]

    @property
    def constant_name(self) -> str:
        """`SQ-PRESTIGE-01` -> `SQ_PRESTIGE_01`, a legal GDScript constant name."""
        return self.quest_id.replace("-", "_")

    @property
    def title_key(self) -> str:
        return f"QUEST_{self.constant_name}_TITLE"

    @property
    def resource_path(self) -> str:
        return f"{QUEST_DATA_DIR}/{self.quest_id}.tres"

    @property
    def graph_path(self) -> str:
        return f"{QUEST_GRAPH_DIR}/{self.quest_id}.tres"

    def has_graph(self) -> bool:
        """True when somebody has authored this quest's state machine."""
        return (GODOT_DIR / self.graph_path).is_file()


def frontmatter(path: Path) -> dict[str, str]:
    """A quest doc's frontmatter as `key -> value`, comments and indentation kept.

    A key's value is its own line's remainder plus every indented line under it, so
    `branches:`' YAML list of lists survives. Trailing `#` comments are dropped:
    several quests explain a gate in one (MQ18's hard-gate note) and none of it is
    data.
    """
    values: dict[str, str] = {}
    key = ""
    for line in frontmatter_lines(path):
        without_comment = line.split("#", 1)[0]
        if not without_comment.strip():
            continue
        indented = without_comment[0].isspace() or without_comment.lstrip().startswith("-")
        if indented:
            if key:
                values[key] += "\n" + without_comment
            continue
        name, _, value = without_comment.partition(":")
        key = name.strip()
        values[key] = value
    return values


def parse_list(value: str) -> list[str]:
    """`[WS_A, WS_B]` -> `["WS_A", "WS_B"]`; `[]` and blank -> `[]`."""
    text = value.strip()
    if not text:
        return []
    if not (text.startswith("[") and text.endswith("]")):
        raise GeneratorError(f"{text!r} is not an inline YAML list")
    return [entry.strip() for entry in text[1:-1].split(",") if entry.strip()]


def parse_branches(quest_id: str, value: str) -> list[tuple[str, list[str]]]:
    """A `branches:` block as `[(group id, [flag, ...]), ...]`, in doc order.

    The group id is derived exactly as the world-state matrix derives it
    (`branch_group_id`), so a quest's groups and the matrix's `branch_group` field
    are the same ids by construction rather than by coincidence.
    """
    groups: list[tuple[str, list[str]]] = []
    for line in value.splitlines():
        if not line.strip():
            continue
        found = BRANCH_ROW_PATTERN.match(line)
        if found is None:
            raise GeneratorError(f"{quest_id}'s branches has a row this tool cannot read: {line!r}")
        members = [entry.strip() for entry in found.group(1).split(",") if entry.strip()]
        if len(members) < 2:
            raise GeneratorError(f"{quest_id} has a branch group with {len(members)} members")
        groups.append((branch_group_id(quest_id, members), members))
    return groups


def parse_arcana(quest_id: str, value: str) -> int:
    """`XVIII. The Moon` -> 18; `none` -> 0."""
    text = unwrap(value)
    if text.lower() == ARCANA_NONE:
        return 0
    numeral = text.split(".", 1)[0].strip().upper()
    if numeral not in ROMAN_NUMERALS:
        raise GeneratorError(f"{quest_id} names the card {text!r}, whose numeral is unreadable")
    return ROMAN_NUMERALS[numeral]


def parse_quests(quests_dir: Path, regions: dict[str, str]) -> list[Quest]:
    """Every quest doc's frontmatter, as definitions, in doc order.

    Doc order is `main/` before `side/` and alphabetical within each, which is card
    order for the main quests and id order for the rest - so the catalog reads the way
    `docs/quests/` does.
    """
    quests: list[Quest] = []
    for path in sorted(quests_dir.rglob("*.md")):
        values = frontmatter(path)
        if "id" not in values:
            continue  # README.md, TEMPLATE.md, SLATE.md: docs about quests, not quests
        quest_id = unwrap(values["id"])
        for key in REQUIRED_FRONTMATTER_KEYS:
            if key not in values:
                raise GeneratorError(f"{path.name}'s frontmatter has no '{key}'")
        if QUEST_ID_SHAPE.match(quest_id) is None:
            raise GeneratorError(f"{path.name} has an id no quest scheme allows: {quest_id!r}")
        quest_type = unwrap(values["type"]).lower()
        if quest_type not in QUEST_TYPES:
            raise GeneratorError(f"{quest_id} is of type {quest_type!r}, which is neither main nor side")
        region_name = REGION_GLOSS_PATTERN.sub("", unwrap(values["region"])).strip()
        if region_name not in regions:
            raise GeneratorError(
                f"{quest_id} is homed to {region_name!r}, which docs/GLOSSARY.md does not name"
            )
        quests.append(
            Quest(
                quest_id=quest_id,
                title=unwrap(values["title"]),
                quest_type=QUEST_TYPES[quest_type],
                arcana_number=parse_arcana(quest_id, values["arcana"]),
                region_id=regions[region_name],
                required_states=parse_list(values.get("requires", "")),
                fired_states=parse_list(values.get("fires", "")),
                branch_groups=parse_branches(quest_id, values.get("branches", "")),
                doc_path=str(path.relative_to(REPO_ROOT)),
            )
        )
    seen: dict[str, str] = {}
    for quest in quests:
        if quest.quest_id in seen:
            raise GeneratorError(f"{quest.quest_id} is claimed by two docs")
        seen[quest.quest_id] = quest.doc_path
    if not quests:
        raise GeneratorError(f"{quests_dir} holds no quest frontmatter")
    return quests


# --- Writing Godot text resources --------------------------------------------


def escape(value: str) -> str:
    """A Python string as a Godot text-resource string literal body."""
    return value.replace("\\", "\\\\").replace('"', '\\"')


def resource_header(script_class: str, ext_resources: list[tuple[str, str, str]]) -> str:
    """A `.tres` header: the `gd_resource` line and one `ext_resource` per entry.

    Each entry is `(type, path, id)`. `load_steps` counts the external resources
    plus the resource itself, which is what Godot's own writer records.
    """
    lines = [
        '[gd_resource type="Resource" script_class="%s" load_steps=%d format=3]'
        % (script_class, len(ext_resources) + 1),
        "",
    ]
    for resource_type, path, resource_id in ext_resources:
        lines.append(
            '[ext_resource type="%s" path="%s" id="%s"]' % (resource_type, path, resource_id)
        )
    lines.append("")
    lines.append("")
    return "\n".join(lines)


def flag_resource(flag: Flag) -> str:
    """One `WS_*.tres`."""
    script_id = "1_definition"
    body = resource_header("WorldStateDefinition", [("Script", DEFINITION_SCRIPT, script_id)])
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % script_id,
            'id = &"%s"' % flag.state_id,
            "kind = %d" % flag.kind,
            'fired_by = &"%s"' % flag.fired_by,
            "arcana_number = %d" % flag.arcana_number,
            'branch_group = &"%s"' % flag.branch_group,
            'effect_summary = "%s"' % escape(flag.effect_summary),
            'doc_ref = "%s"' % escape(flag.doc_ref),
            "",
        ]
    )
    return body


def catalog_resource(flags: list[Flag]) -> str:
    """`catalog.tres`, referencing every flag resource in doc order."""
    definition_id = "1_definition"
    catalog_id = "2_catalog"
    ext_resources = [
        ("Script", DEFINITION_SCRIPT, definition_id),
        ("Script", CATALOG_SCRIPT, catalog_id),
    ]
    entry_ids: list[str] = []
    for index, flag in enumerate(flags, start=3):
        entry_id = "%d_%s" % (index, flag.state_id.lower())
        entry_ids.append(entry_id)
        ext_resources.append(("Resource", "res://" + flag.resource_path, entry_id))
    body = resource_header("WorldStateCatalog", ext_resources)
    entries = ", ".join('ExtResource("%s")' % entry_id for entry_id in entry_ids)
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % catalog_id,
            'entries = Array[ExtResource("%s")]([%s])' % (definition_id, entries),
            "",
        ]
    )
    return body


def act_thresholds_resource(act_ii_min: int, act_iii_min: int) -> str:
    """`act_thresholds.tres`."""
    script_id = "1_act_thresholds"
    body = resource_header("ActThresholds", [("Script", ACT_THRESHOLDS_SCRIPT, script_id)])
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % script_id,
            'id = &"%s"' % ACT_THRESHOLDS_ID,
            "act_ii_min = %d" % act_ii_min,
            "act_iii_min = %d" % act_iii_min,
            'doc_ref = "%s"' % escape(GLOBAL_STATES_DOC_REF),
            "",
        ]
    )
    return body


def renown_ladder_resource(tier_names: list[str]) -> str:
    """`renown_ladder.tres`."""
    script_id = "1_renown_ladder"
    if len(tier_names) != len(RENOWN_TIER_MIN_PLACEHOLDERS):
        raise GeneratorError(
            "the Renown ladder has %d tiers but %d placeholder thresholds"
            % (len(tier_names), len(RENOWN_TIER_MIN_PLACEHOLDERS))
        )
    names = ", ".join('"%s"' % escape(name) for name in tier_names)
    values = ", ".join(str(value) for value in RENOWN_TIER_MIN_PLACEHOLDERS)
    body = resource_header("RenownLadder", [("Script", RENOWN_LADDER_SCRIPT, script_id)])
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % script_id,
            'id = &"%s"' % RENOWN_LADDER_ID,
            "tier_names = PackedStringArray(%s)" % names,
            "tier_min_values = PackedInt32Array(%s)" % values,
            'doc_ref = "%s"' % escape(RENOWN_DOC_REF),
            'notes = "%s"' % escape(RENOWN_TIER_NOTES),
            "",
        ]
    )
    return body


def world_state_ids_script(flags: list[Flag]) -> str:
    """`world_state_ids.gd`: the one place a `WS_*` string is written in code."""
    unbinding = [flag for flag in flags if flag.is_unbinding]
    branches = [flag for flag in flags if not flag.is_unbinding]
    lines = [
        "class_name WorldStateIds",
        "extends RefCounted",
        "",
        "## Every world-state flag id, as a constant.",
        "##",
        "## GENERATED by `godot/tools/gen_definitions.py` from",
        "## `%s` - do not edit by hand; edit the doc and" % WORLD_MATRIX_DOC_REF,
        "## regenerate. A drift test fails when this file and the matrix disagree.",
        "##",
        "## Code never types a `WS_*` string: it names one of these constants, or reads",
        "## an id off a `WorldStateDefinition` (docs/design/technical.md, no magic",
        "## strings). The `.tres` data under `res://data/world_states/` is generated",
        "## from the same rows, so the two cannot drift apart.",
        "",
        "## The unbinding flags, in card order (MQ01 first).",
    ]
    for flag in unbinding:
        lines.append(
            "const %s := &\"%s\"  # %s" % (flag.state_id, flag.state_id, flag.fired_by)
        )
    lines.append("")
    lines.append("## The branch flags a quest's closing choice picks between.")
    for flag in branches:
        lines.append(
            "const %s := &\"%s\"  # %s, %s"
            % (flag.state_id, flag.state_id, flag.fired_by, flag.branch_group)
        )
    lines.append("")
    lines.append("## Every unbinding flag, in card order.")
    lines.append("const UNBINDING: Array[StringName] = [")
    for flag in unbinding:
        lines.append("\t%s," % flag.state_id)
    lines.append("]")
    lines.append("")
    lines.append("## Every branch flag, in matrix order.")
    lines.append("const BRANCH: Array[StringName] = [")
    for flag in branches:
        lines.append("\t%s," % flag.state_id)
    lines.append("]")
    lines.append("")
    lines.append("## Every flag the matrix defines.")
    lines.append("const ALL: Array[StringName] = [")
    for flag in flags:
        lines.append("\t%s," % flag.state_id)
    lines.append("]")
    lines.append("")
    return "\n".join(lines)


def string_name_array(ids: list[str]) -> str:
    """`["A", "B"]` as a Godot `Array[StringName]` literal."""
    members = ", ".join('&"%s"' % escape(entry) for entry in ids)
    return "Array[StringName]([%s])" % members


def quest_resource(quest: Quest) -> str:
    """One `data/quests/<ID>.tres`.

    The branch groups are sub-resources rather than files of their own: a group has
    no life outside the quest whose choice it is, and inlining keeps a regenerate to
    exactly one file per quest.
    """
    definition_id = "1_quest"
    branch_script_id = "2_branch_group"
    graph_id = "3_graph"
    ext_resources = [("Script", QUEST_DEFINITION_SCRIPT, definition_id)]
    if quest.branch_groups:
        ext_resources.append(("Script", QUEST_BRANCH_GROUP_SCRIPT, branch_script_id))
    if quest.has_graph():
        ext_resources.append(("Resource", "res://" + quest.graph_path, graph_id))

    sub_resources: list[str] = []
    group_references: list[str] = []
    for group_id, members in quest.branch_groups:
        sub_id = "Resource_%s" % group_id
        group_references.append('SubResource("%s")' % sub_id)
        sub_resources.append(
            "\n".join(
                [
                    '[sub_resource type="Resource" id="%s"]' % sub_id,
                    'script = ExtResource("%s")' % branch_script_id,
                    'group_id = &"%s"' % escape(group_id),
                    "flags = %s" % string_name_array(members),
                    "",
                ]
            )
        )

    lines = [
        '[gd_resource type="Resource" script_class="QuestDefinition" load_steps=%d format=3]'
        % (len(ext_resources) + len(sub_resources) + 1),
        "",
    ]
    for resource_type, path, resource_id in ext_resources:
        lines.append('[ext_resource type="%s" path="%s" id="%s"]' % (resource_type, path, resource_id))
    lines.append("")
    body = "\n".join(lines) + "\n"
    for sub_resource in sub_resources:
        body += sub_resource + "\n"
    groups_literal = "Array[ExtResource(\"%s\")]([%s])" % (
        branch_script_id, ", ".join(group_references)
    ) if quest.branch_groups else "Array[Resource]([])"
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % definition_id,
            'id = &"%s"' % escape(quest.quest_id),
            'title_key = &"%s"' % escape(quest.title_key),
            "type = %d" % quest.quest_type,
            "arcana_number = %d" % quest.arcana_number,
            'region_id = &"%s"' % escape(quest.region_id),
            "required_states = %s" % string_name_array(quest.required_states),
            "fired_states = %s" % string_name_array(quest.fired_states),
            "branch_groups = %s" % groups_literal,
            'graph = ExtResource("%s")' % graph_id if quest.has_graph() else "graph = null",
            'doc_path = "%s"' % escape(quest.doc_path),
            "",
        ]
    )
    return body


def quest_catalog_resource(quests: list[Quest]) -> str:
    """`data/quests/catalog.tres`, referencing every quest resource in doc order."""
    definition_id = "1_quest"
    catalog_id = "2_catalog"
    ext_resources = [
        ("Script", QUEST_DEFINITION_SCRIPT, definition_id),
        ("Script", QUEST_CATALOG_SCRIPT, catalog_id),
    ]
    entry_ids: list[str] = []
    for index, quest in enumerate(quests, start=3):
        entry_id = "%d_%s" % (index, quest.constant_name.lower())
        entry_ids.append(entry_id)
        ext_resources.append(("Resource", "res://" + quest.resource_path, entry_id))
    body = resource_header("QuestCatalog", ext_resources)
    entries = ", ".join('ExtResource("%s")' % entry_id for entry_id in entry_ids)
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % catalog_id,
            'entries = Array[ExtResource("%s")]([%s])' % (definition_id, entries),
            "",
        ]
    )
    return body


def quest_ids_script(quests: list[Quest]) -> str:
    """`quest_ids.gd`: the one place a quest id is written in code."""
    main = [quest for quest in quests if quest.is_main]
    side = [quest for quest in quests if not quest.is_main]
    lines = [
        "class_name QuestIds",
        "extends RefCounted",
        "",
        "## Every quest id, as a constant.",
        "##",
        "## GENERATED by `godot/tools/gen_definitions.py` from the YAML frontmatter of",
        "## every `docs/quests/**/*.md` - do not edit by hand; add the quest doc and",
        "## regenerate. A drift test fails when this file and `docs/quests/` disagree.",
        "##",
        "## Code never types a quest id: it names one of these constants, or reads an id",
        "## off a `QuestDefinition` (docs/design/technical.md, no magic strings). The",
        "## `.tres` data under `res://data/quests/` is generated from the same",
        "## frontmatter, so the two cannot drift apart.",
        "",
        "## The main quests, in card order. MQ00 is the prologue; the number IS the card",
        "## (`docs/quests/README.md` §ID scheme), and there are exactly 22, forever.",
    ]
    for quest in main:
        lines.append('const %s := &"%s"' % (quest.constant_name, quest.quest_id))
    lines.append("")
    lines.append("## The side quests, by id.")
    for quest in side:
        lines.append('const %s := &"%s"' % (quest.constant_name, quest.quest_id))
    lines.append("")
    lines.append("## Every main quest, in card order.")
    lines.append("const MAIN: Array[StringName] = [")
    for quest in main:
        lines.append("\t%s," % quest.constant_name)
    lines.append("]")
    lines.append("")
    lines.append("## Every side quest, by id.")
    lines.append("const SIDE: Array[StringName] = [")
    for quest in side:
        lines.append("\t%s," % quest.constant_name)
    lines.append("]")
    lines.append("")
    lines.append("## Every quest `docs/quests/` defines.")
    lines.append("const ALL: Array[StringName] = [")
    for quest in quests:
        lines.append("\t%s," % quest.constant_name)
    lines.append("]")
    lines.append("")
    return "\n".join(lines)


def csv_field(value: str) -> str:
    """A CSV field, quoted only when it has to be (one quest title has a comma)."""
    if any(character in value for character in (",", '"', "\n")):
        return '"%s"' % value.replace('"', '""')
    return value


def quest_titles_csv(quests: list[Quest]) -> str:
    """`localization/quest_titles.csv`: every quest title, keyed.

    Quest titles are the one player-facing string the frontmatter carries, so they
    leave `docs/` as translation keys and arrive here as the English column - the
    only place the English lives (technical.md §Localization (Godot)).
    """
    lines = ["keys,en"]
    for quest in quests:
        lines.append("%s,%s" % (quest.title_key, csv_field(quest.title)))
    lines.append("")
    return "\n".join(lines)


# --- Trumps (docs/design/arcana.md) ------------------------------------------


# `## I. The Magician - *skill turned to shtick*`: the section a Trump block sits in.
ARCANA_HEADING_PATTERN = re.compile(r"^##\s+([IVXL]+)\.\s+(.+)$")

# `**Trump I \u2014 Manifest.**`: the line that opens a Trump's table.
TRUMP_LINE_PATTERN = re.compile(r"^\*\*Trump ([IVXL]+) \u2014 (.+)\.\*\*$")

# `| Past | Nimble hands: ... |`: one row of the Slot/Upright table.
TRUMP_SLOT_PATTERN = re.compile(r"^\|\s*(Past|Present|Future)\s*\|\s*(.*?)\s*\|$")

# `**Reversed burden \u2014 *the trick costs the trickster*:** effects grow ...`
BURDEN_PATTERN = re.compile(r"^\*\*Reversed burden \u2014 \*(.+?)\*:\*\*\s*(.*)$")

# The tagline after a section heading's em dash: prose, never part of the citation.
HEADING_TAGLINE_SEPARATOR = " \u2014 "

# The three slots, in the order `progression.md` deals them.
TRUMP_SLOTS = ("Past", "Present", "Future")

# `arcana.md` XXI: "The World's card is not carried. It is turned." So the twenty-
# first Arcana yields no Trump and there are exactly twenty.
LAST_TRUMP = 20


class Trump:
    """One generated TrumpDefinition."""

    def __init__(
        self,
        card_number: int,
        name: str,
        granted_by_flag: str,
        slot_summaries: dict[str, str],
        burden_name: str,
        burden_summary: str,
        doc_ref: str,
    ) -> None:
        self.card_number = card_number
        self.name = name
        self.granted_by_flag = granted_by_flag
        self.slot_summaries = slot_summaries
        self.burden_name = burden_name
        self.burden_summary = burden_summary
        self.doc_ref = doc_ref

    @property
    def trump_id(self) -> str:
        return "TRUMP_%02d" % self.card_number

    @property
    def name_key(self) -> str:
        return f"{self.trump_id}_NAME"

    @property
    def resource_path(self) -> str:
        return f"{TRUMP_DATA_DIR}/{self.trump_id}.tres"

    @property
    def effects_path(self) -> str:
        return f"{TRUMP_EFFECTS_DIR}/{self.trump_id}.tres"

    def has_effects(self) -> bool:
        """True when somebody has authored this Trump's six expressions."""
        return (GODOT_DIR / self.effects_path).is_file()


def parse_trumps(doc_path: Path, flags: list[Flag]) -> list[Trump]:
    """Every `**Trump N \u2014 Name.**` block in `arcana.md`, in card order.

    Each block is read whole: the three Upright cells verbatim, the italicised
    burden name and its paragraph verbatim, and the section heading it sits under
    as the citation. The prose is documentation - what a Trump *does* in the game is
    hand-authored under `data/trumps/effects/` and merely linked from here.
    """
    lines = doc_path.read_text(encoding="utf-8").splitlines()
    unbinding_by_card = {
        flag.arcana_number: flag.state_id for flag in flags if flag.is_unbinding
    }
    trumps: list[Trump] = []
    heading = ""
    index = 0
    while index < len(lines):
        line = lines[index]
        found_heading = ARCANA_HEADING_PATTERN.match(line)
        if found_heading is not None:
            heading = line.lstrip("#").strip().split(HEADING_TAGLINE_SEPARATOR, 1)[0].strip()
            index += 1
            continue
        found = TRUMP_LINE_PATTERN.match(line)
        if found is None:
            index += 1
            continue
        numeral = found.group(1)
        if numeral not in ROMAN_NUMERALS:
            raise GeneratorError(f"arcana.md has a Trump numbered {numeral!r}")
        card_number = ROMAN_NUMERALS[numeral]
        if not heading.startswith(f"{numeral}."):
            raise GeneratorError(
                f"Trump {numeral} sits under the section {heading!r}, which is not its own"
            )
        summaries, burden_name, burden_summary, index = read_trump_block(
            lines, index + 1, numeral
        )
        if card_number not in unbinding_by_card:
            raise GeneratorError(
                f"Trump {numeral} is card {card_number}, which no unbinding flag carries"
            )
        trumps.append(
            Trump(
                card_number=card_number,
                name=found.group(2).strip(),
                granted_by_flag=unbinding_by_card[card_number],
                slot_summaries=summaries,
                burden_name=burden_name,
                burden_summary=burden_summary,
                doc_ref=f"{ARCANA_DOC_REF} \u00a7{heading}",
            )
        )
    numbers = [trump.card_number for trump in trumps]
    if numbers != list(range(1, LAST_TRUMP + 1)):
        raise GeneratorError(
            f"arcana.md yields Trumps {numbers}, not I..{LAST_TRUMP} in order"
        )
    return trumps


def read_trump_block(
    lines: list[str], start: int, numeral: str
) -> tuple[dict[str, str], str, str, int]:
    """One Trump's table and burden paragraph, and the line to carry on from.

    Reads to the next `##` heading, which is where the next Arcana starts: the
    Unbinding paragraph in between is `world.md`'s business and is skipped.
    """
    summaries: dict[str, str] = {}
    burden_name = ""
    burden_lines: list[str] = []
    reading_burden = False
    index = start
    while index < len(lines):
        line = lines[index]
        if line.startswith("## "):
            break
        if reading_burden:
            if not line.strip():
                reading_burden = False
            else:
                burden_lines.append(line.strip())
            index += 1
            continue
        found_slot = TRUMP_SLOT_PATTERN.match(line.strip())
        if found_slot is not None:
            summaries[found_slot.group(1)] = found_slot.group(2).strip()
            index += 1
            continue
        found_burden = BURDEN_PATTERN.match(line.strip())
        if found_burden is not None:
            burden_name = found_burden.group(1).strip()
            burden_lines.append(found_burden.group(2).strip())
            reading_burden = True
            index += 1
            continue
        index += 1
    for slot in TRUMP_SLOTS:
        if not summaries.get(slot):
            raise GeneratorError(f"Trump {numeral} has no {slot} row")
    if not burden_name:
        raise GeneratorError(f"Trump {numeral} names no reversed burden")
    burden_summary = " ".join(part for part in burden_lines if part)
    return summaries, burden_name, burden_summary, index


def trump_resource(trump: Trump) -> str:
    """One `data/trumps/TRUMP_NN.tres`."""
    definition_id = "1_trump"
    effects_id = "2_effects"
    ext_resources = [("Script", TRUMP_DEFINITION_SCRIPT, definition_id)]
    if trump.has_effects():
        ext_resources.append(("Resource", "res://" + trump.effects_path, effects_id))
    body = resource_header("TrumpDefinition", ext_resources)
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % definition_id,
            'id = &"%s"' % trump.trump_id,
            "card_number = %d" % trump.card_number,
            'name_key = &"%s"' % trump.name_key,
            'granted_by_flag = &"%s"' % trump.granted_by_flag,
            'past_summary = "%s"' % escape(trump.slot_summaries["Past"]),
            'present_summary = "%s"' % escape(trump.slot_summaries["Present"]),
            'future_summary = "%s"' % escape(trump.slot_summaries["Future"]),
            'burden_name = "%s"' % escape(trump.burden_name),
            'burden_summary = "%s"' % escape(trump.burden_summary),
            'doc_ref = "%s"' % escape(trump.doc_ref),
            (
                'effects = ExtResource("%s")' % effects_id
                if trump.has_effects()
                else "effects = null"
            ),
            "",
        ]
    )
    return body


def trump_catalog_resource(trumps: list[Trump]) -> str:
    """`data/trumps/catalog.tres`, referencing every Trump in card order."""
    definition_id = "1_trump"
    catalog_id = "2_catalog"
    ext_resources = [
        ("Script", TRUMP_DEFINITION_SCRIPT, definition_id),
        ("Script", TRUMP_CATALOG_SCRIPT, catalog_id),
    ]
    entry_ids: list[str] = []
    for index, trump in enumerate(trumps, start=3):
        entry_id = "%d_%s" % (index, trump.trump_id.lower())
        entry_ids.append(entry_id)
        ext_resources.append(("Resource", "res://" + trump.resource_path, entry_id))
    body = resource_header("TrumpCatalog", ext_resources)
    entries = ", ".join('ExtResource("%s")' % entry_id for entry_id in entry_ids)
    body += "\n".join(
        [
            "[resource]",
            'script = ExtResource("%s")' % catalog_id,
            'entries = Array[ExtResource("%s")]([%s])' % (definition_id, entries),
            "",
        ]
    )
    return body


def trump_ids_script(trumps: list[Trump]) -> str:
    """`trump_ids.gd`: the one place a Trump id is written in code."""
    lines = [
        "class_name TrumpIds",
        "extends RefCounted",
        "",
        "## Every Trump id, as a constant.",
        "##",
        "## GENERATED by `godot/tools/gen_definitions.py` from every",
        "## `**Trump N %s Name.**` block in `%s` - do not edit by" % ("\u2014", ARCANA_DOC_REF),
        "## hand; edit the doc and regenerate. A drift test fails when this file and",
        "## `arcana.md` disagree.",
        "##",
        "## There are exactly %d. `arcana.md` XXI: the World's card \"is not carried. It" % LAST_TRUMP,
        "## is turned.\" - so the twenty-first Arcana yields no Trump.",
        "##",
        "## Code never types a Trump id: it names one of these constants, or reads an id",
        "## off a `TrumpDefinition` (docs/design/technical.md, no magic strings).",
        "",
        "## The Trumps, in card order (I first, XX last).",
    ]
    for trump in trumps:
        lines.append(
            'const %s := &"%s"  # %s' % (trump.trump_id, trump.trump_id, trump.name)
        )
    lines.append("")
    lines.append("## Every Trump `arcana.md` defines, in card order.")
    lines.append("const ALL: Array[StringName] = [")
    for trump in trumps:
        lines.append("\t%s," % trump.trump_id)
    lines.append("]")
    lines.append("")
    return "\n".join(lines)


def trump_names_csv(trumps: list[Trump]) -> str:
    """`localization/trumps.csv`: every Trump's name, keyed.

    A Trump's name is player-facing text, so it leaves `arcana.md` as a translation
    key and arrives here as the English column - the only place the English lives
    (technical.md \u00a7Localization (Godot)).
    """
    lines = ["keys,en"]
    for trump in trumps:
        lines.append("%s,%s" % (trump.name_key, csv_field(trump.name)))
    lines.append("")
    return "\n".join(lines)


# --- The generation itself ---------------------------------------------------


def generate() -> dict[str, str]:
    """Every generated file, keyed by its path relative to `godot/`."""
    flags = parse_matrix(WORLD_DOC)
    act_ii_min, act_iii_min = parse_act_thresholds(WORLD_DOC)
    tier_names = parse_renown_tiers(PROGRESSION_DOC)
    regions = parse_regions(GLOSSARY_DOC)
    quests = parse_quests(QUESTS_DIR, regions)
    trumps = parse_trumps(ARCANA_DOC, flags)

    files: dict[str, str] = {}
    for flag in flags:
        files[flag.resource_path] = flag_resource(flag)
    files[CATALOG_PATH] = catalog_resource(flags)
    files[ACT_THRESHOLDS_PATH] = act_thresholds_resource(act_ii_min, act_iii_min)
    files[RENOWN_LADDER_PATH] = renown_ladder_resource(tier_names)
    files[WORLD_STATE_IDS_PATH] = world_state_ids_script(flags)
    for quest in quests:
        files[quest.resource_path] = quest_resource(quest)
    files[QUEST_CATALOG_PATH] = quest_catalog_resource(quests)
    files[QUEST_IDS_PATH] = quest_ids_script(quests)
    files[QUEST_TITLES_CSV_PATH] = quest_titles_csv(quests)
    for trump in trumps:
        files[trump.resource_path] = trump_resource(trump)
    files[TRUMP_CATALOG_PATH] = trump_catalog_resource(trumps)
    files[TRUMP_IDS_PATH] = trump_ids_script(trumps)
    files[TRUMP_NAMES_CSV_PATH] = trump_names_csv(trumps)
    return files


def stale_paths(files: dict[str, str]) -> list[str]:
    """Generated-directory files this run would no longer produce.

    Every directory this tool writes into is swept, under the globs that name what
    the tool owns there: whole directories of `.tres` under `data/`, but only
    `world_state_ids.gd` in `systems/world_state/`, which is full of hand-written
    code the generator must never call stale. A row deleted from the matrix leaves
    its resource behind otherwise, and a `--check` that did not sweep here would
    call the tree clean while the game still loaded the orphan.

    `HAND_AUTHORED_PATHS` names the files that live inside a swept directory
    without being generated; they are spared here and never written.
    """
    stale: list[str] = []
    for directory, patterns in sorted(GENERATED_GLOBS.items()):
        for pattern in patterns:
            for existing in sorted((GODOT_DIR / directory).glob(pattern)):
                relative = str(existing.relative_to(GODOT_DIR))
                if relative in files or relative in HAND_AUTHORED_PATHS:
                    continue
                stale.append(relative)
    return sorted(set(stale))


def write(files: dict[str, str]) -> list[str]:
    """Write every generated file under `godot/`; returns the paths that changed."""
    changed: list[str] = []
    for relative, content in sorted(files.items()):
        target = GODOT_DIR / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() and target.read_text(encoding="utf-8") == content:
            continue
        target.write_text(content, encoding="utf-8")
        changed.append(relative)
    return changed


def check(files: dict[str, str]) -> list[str]:
    """Regenerate into a temp dir and report every difference from what is on disk."""
    problems: list[str] = []
    with tempfile.TemporaryDirectory(prefix="tarrock-gen-") as temporary:
        temporary_root = Path(temporary)
        for relative, content in sorted(files.items()):
            fresh = temporary_root / relative
            fresh.parent.mkdir(parents=True, exist_ok=True)
            fresh.write_text(content, encoding="utf-8")
            target = GODOT_DIR / relative
            if not target.exists():
                problems.append("MISSING  %s (never generated)" % relative)
                continue
            on_disk = target.read_text(encoding="utf-8")
            if on_disk == content:
                continue
            problems.append("CHANGED  %s" % relative)
            problems.extend(
                line.rstrip("\n")
                for line in difflib.unified_diff(
                    on_disk.splitlines(keepends=True),
                    content.splitlines(keepends=True),
                    fromfile="%s (on disk)" % relative,
                    tofile="%s (from docs)" % relative,
                )
            )
    for relative in stale_paths(files):
        problems.append("STALE    %s (no doc row produces it)" % relative)
    return problems


def report_quest_references(files: dict[str, str], flags: set[str]) -> None:
    """Print the `WS_*` ids quests name that the matrix does not define.

    Informational only: `docs/quests/README.md` already forbids it and reviewers
    enforce it, and this tool is not allowed to edit `docs/`.
    """
    if not QUESTS_DIR.is_dir():
        print("quest frontmatter: %s is missing, skipped" % QUESTS_DIR)
        return
    references = quest_flag_references(QUESTS_DIR)
    unknown = {
        state_id: sources
        for state_id, sources in sorted(references.items())
        if state_id not in flags
    }
    print(
        "quest frontmatter: %d distinct WS_* ids referenced, %d not in the matrix"
        % (len(references), len(unknown))
    )
    for state_id, sources in unknown.items():
        print("  %s <- %s" % (state_id, ", ".join(sources)))


def report_regions() -> None:
    """Print the region tokens quest ids and definitions are built from.

    Informational: the tokens come from `docs/GLOSSARY.md` §The world, and a quest
    naming a region the glossary does not have already fails `generate()`.
    """
    regions = parse_regions(GLOSSARY_DOC)
    print("regions: %d tokens from %s" % (len(regions), GLOSSARY_DOC.name))
    for name, token in sorted(regions.items(), key=lambda entry: entry[1]):
        print("  %-12s <- %s" % (token, name))


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true", help="write the generated resources")
    mode.add_argument("--check", action="store_true", help="fail if anything would change")
    arguments = parser.parse_args(argv)

    try:
        files = generate()
    except GeneratorError as error:
        print("gen_definitions: %s" % error, file=sys.stderr)
        return 2

    known = {Path(path).stem for path in files if path.endswith(".tres")}
    report_quest_references(files, known)
    report_regions()

    if arguments.check:
        problems = check(files)
        if problems:
            print("gen_definitions --check: the generated data no longer matches docs/")
            for problem in problems:
                print(problem)
            return 1
        print("gen_definitions --check: %d generated files match docs/" % len(files))
        return 0

    changed = write(files)
    for relative in changed:
        print("wrote %s" % relative)
    print("gen_definitions --write: %d files, %d changed" % (len(files), len(changed)))
    for relative in stale_paths(files):
        print("stale (delete by hand): %s" % relative)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
