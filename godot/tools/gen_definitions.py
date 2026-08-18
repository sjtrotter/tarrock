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
QUESTS_DIR = DOCS_DIR / "quests"

WORLD_STATE_DATA_DIR = "data/world_states"
PROGRESSION_DATA_DIR = "data/progression"
WORLD_STATE_SYSTEM_DIR = "systems/world_state"

DEFINITION_SCRIPT = "res://systems/world_state/definitions/world_state_definition.gd"
CATALOG_SCRIPT = "res://systems/world_state/definitions/world_state_catalog.gd"
ACT_THRESHOLDS_SCRIPT = "res://systems/world_state/definitions/act_thresholds.gd"
RENOWN_LADDER_SCRIPT = "res://systems/world_state/definitions/renown_ladder.gd"

CATALOG_PATH = f"{WORLD_STATE_DATA_DIR}/catalog.tres"
ACT_THRESHOLDS_PATH = f"{WORLD_STATE_DATA_DIR}/act_thresholds.tres"
RENOWN_LADDER_PATH = f"{PROGRESSION_DATA_DIR}/renown_ladder.tres"
WORLD_STATE_IDS_PATH = f"{WORLD_STATE_SYSTEM_DIR}/world_state_ids.gd"

# Every directory this tool writes into, and what it owns there: anything matching
# the glob that this run would not produce is stale (see `stale_paths`). The data
# directories are generated whole; the system directory is hand-written code that
# happens to hold one generated file, so only that file's own name is swept.
GENERATED_GLOBS = {
    WORLD_STATE_DATA_DIR: "*.tres",
    PROGRESSION_DATA_DIR: "*.tres",
    WORLD_STATE_SYSTEM_DIR: WORLD_STATE_IDS_PATH.rsplit("/", 1)[-1],
}

# --- What the docs say -------------------------------------------------------

MATRIX_HEADING = "## World-state matrix"
GLOBAL_STATES_HEADING = "## Global states (act thresholds)"
RENOWN_HEADING = "## Renown"

WORLD_MATRIX_DOC_REF = "docs/design/world.md §World-state matrix"
GLOBAL_STATES_DOC_REF = "docs/design/world.md §Global states (act thresholds)"
RENOWN_DOC_REF = "docs/design/progression.md §Renown"

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


# --- The generation itself ---------------------------------------------------


def generate() -> dict[str, str]:
    """Every generated file, keyed by its path relative to `godot/`."""
    flags = parse_matrix(WORLD_DOC)
    act_ii_min, act_iii_min = parse_act_thresholds(WORLD_DOC)
    tier_names = parse_renown_tiers(PROGRESSION_DOC)

    files: dict[str, str] = {}
    for flag in flags:
        files[flag.resource_path] = flag_resource(flag)
    files[CATALOG_PATH] = catalog_resource(flags)
    files[ACT_THRESHOLDS_PATH] = act_thresholds_resource(act_ii_min, act_iii_min)
    files[RENOWN_LADDER_PATH] = renown_ladder_resource(tier_names)
    files[WORLD_STATE_IDS_PATH] = world_state_ids_script(flags)
    return files


def stale_paths(files: dict[str, str]) -> list[str]:
    """Generated-directory files this run would no longer produce.

    Every directory this tool writes into is swept, under the glob that names what
    the tool owns there: whole directories of `.tres` under `data/`, but only
    `world_state_ids.gd` in `systems/world_state/`, which is full of hand-written
    code the generator must never call stale. A row deleted from the matrix leaves
    its resource behind otherwise, and a `--check` that did not sweep here would
    call the tree clean while the game still loaded the orphan.
    """
    stale: list[str] = []
    for directory, pattern in sorted(GENERATED_GLOBS.items()):
        for existing in sorted((GODOT_DIR / directory).glob(pattern)):
            relative = str(existing.relative_to(GODOT_DIR))
            if relative not in files:
                stale.append(relative)
    return sorted(stale)


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
