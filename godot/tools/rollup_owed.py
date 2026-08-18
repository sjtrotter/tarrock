#!/usr/bin/env python3
"""Roll every owed item in the Godot project up into one markdown page.

    python3 godot/tools/rollup_owed.py            # the roll-up, on stdout
    python3 godot/tools/rollup_owed.py --counts   # just the tallies

Thirteen rounds of the Systems Gauntlet each closed with a list of what they
deliberately did not build, and every one of those lists lives in the folder it
belongs to - which is right (a debt written next to the code it is a debt about is a
debt somebody reads) and useless at hand-off time, because nobody can hold thirteen
READMEs and two hundred `.tres` files in their head at once. This is the other view:
the same facts, gathered, in one page, so the lead can paste it into the hand-off
document and the director can see the whole bill.

It INVENTS NOTHING. Every line it prints is quoted from a file in the repo, and the
file and section it came from are printed with it. There is no judgement about
priority here and there should not be: the owning README is where an item is
described, argued and eventually struck out.

Two sources, because the project keeps owed work in exactly two shapes:

  1. **`godot/systems/*/README.md`** - the section each system's README gives to what
     it owes. The heading is not spelled the same way everywhere (rounds wrote "Owed
     by later rounds", "Owed to later rounds", "Owed / TBD" and "What this round
     deliberately did not build"), so any heading whose words include *owed*, *did
     not build* or *TBD* counts. A README with no such heading is REPORTED as having
     none rather than skipped, and any line in it mentioning TBD is shown - which is
     how `systems/world_state/`'s inline "Known TBD" is caught.

  2. **`godot/data/**/*.tres` `notes` fields** - the doc-only field the localization
     lint exempts precisely so a definition can carry the reason it holds a
     placeholder (`tests/README.md` §The localization lint). Every sentence in one
     that names a TBD is quoted here with its file.

DETERMINISM IS THE POINT: no clock, no host, no environment, files walked in sorted
order, so two runs of the same tree produce byte-identical output and a diff between
two runs is a real change in the debt.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# The `godot/` project directory, from this file rather than from the caller's cwd.
PROJECT_DIR = Path(__file__).resolve().parents[1]
SYSTEMS_DIR = PROJECT_DIR / "systems"
DATA_DIR = PROJECT_DIR / "data"

# A heading is an owed-items heading when its words include one of these. Rounds
# spelled the section four different ways; the tool reads all four rather than asking
# thirteen READMEs to be rewritten into one house style.
HEADING_MARKERS = ("owed", "did not build", "tbd")

# A markdown heading, and the bullet that starts a top-level item under one.
HEADING = re.compile(r"^(#{2,4})\s+(.*?)\s*$")
BULLET = re.compile(r"^[-*]\s+(.*)$")

# The bold lead most items open with: `- **The wheel on screen.** ...`, struck through
# when a later round closed it: `- ~~**Loading from the title screen.**~~ **Done...`.
LEAD = re.compile(r"^~{0,2}\*\*(.+?)\*\*~{0,2}\s*(.*)$", re.DOTALL)

# An item a later round finished. It stays on the page as history in its own README;
# here it is counted and not listed, because a roll-up of what is owed that listed
# what is done would be a worse page.
CLOSED = re.compile(r"^~~.*?~~\s*\*\*Done")

# A leading markdown list bullet or heading hash, and nothing else - a line's own bold
# lead is part of what it says and is left alone.
LIST_MARKER = re.compile(r"^\s*(?:[-*+]\s+|#{1,6}\s+)")

# `notes = "…"` in a `.tres`, single line, with escaped quotes inside.
NOTES = re.compile(r'^notes\s*=\s*"((?:[^"\\]|\\.)*)"\s*$')

# The word this project marks an undecided thing with. Upper case on purpose: the
# convention across `data/` is a shouted TBD, and lower-case "tbd" inside prose is
# usually somebody describing the convention rather than using it.
TBD = re.compile(r"\bTBD\b")

# How much of one item's prose to quote. Long enough to carry the point, short enough
# that the page stays a bill rather than a second copy of thirteen READMEs.
DETAIL_LIMIT = 220

# How many TBD sentences to quote from one `notes` field. `combat_rules.tres` names
# fifty placeholder fields in one sentence; the file is the place to read that list.
MAX_NOTE_SENTENCES = 3


class Item:
    """One owed thing, with where it was written."""

    def __init__(self, source: str, section: str, lead: str, detail: str) -> None:
        self.source = source
        self.section = section
        self.lead = lead
        self.detail = detail


def collapse(text: str) -> str:
    """One line of prose out of a wrapped markdown bullet."""
    return re.sub(r"\s+", " ", text).strip()


def shorten(text: str, limit: int = DETAIL_LIMIT) -> str:
    """`text`, cut at a word boundary near `limit`, with an ellipsis when cut."""
    text = collapse(text)
    if len(text) <= limit:
        return text
    cut = text[:limit].rsplit(" ", 1)[0].rstrip(" ,;:-")
    return cut + " …"


def relative(path: Path) -> str:
    """A path as the repo writes it, so a reader can open what is quoted."""
    return "godot/" + path.relative_to(PROJECT_DIR).as_posix()


def is_owed_heading(title: str) -> bool:
    lowered = title.lower()
    return any(marker in lowered for marker in HEADING_MARKERS)


def split_items(body: list[str]) -> list[tuple[str, str, str]]:
    """The top-level bullets of one section, as `(lead, detail)` pairs.

    A bullet's continuation lines are indented; they are folded into the bullet they
    belong to, so an item wrapped over six lines is one item and not six.
    """
    items: list[tuple[str, str, str]] = []
    current: list[str] = []
    for line in body:
        match = BULLET.match(line)
        if match is not None:
            if current:
                items.append(finish_item(current))
            current = [match.group(1)]
        elif current and line.strip():
            current.append(line.strip())
        elif not line.strip() and current:
            items.append(finish_item(current))
            current = []
    if current:
        items.append(finish_item(current))
    return items


def finish_item(lines: list[str]) -> tuple[str, str, str]:
    """`(lead, detail, raw)` for one bullet. `raw` is kept so the struck-out test can
    read the tildes the lead extraction eats."""
    text = collapse(" ".join(lines))
    lead_match = LEAD.match(text)
    if lead_match is None:
        return ("", text, text)
    return (collapse(lead_match.group(1)), collapse(lead_match.group(2)), text)


def read_system_readme(path: Path) -> tuple[list[Item], list[str], int]:
    """One system README: its owed items, its stray TBD lines, and what is closed."""
    lines = path.read_text(encoding="utf-8").splitlines()
    items: list[Item] = []
    closed = 0
    section = ""
    collecting = False
    body: list[str] = []
    sections: list[tuple[str, list[str]]] = []
    for line in lines:
        heading = HEADING.match(line)
        if heading is not None:
            if collecting:
                sections.append((section, body))
            section = heading.group(2)
            collecting = is_owed_heading(section)
            body = []
            continue
        if collecting:
            body.append(line)
    if collecting:
        sections.append((section, body))

    for title, section_body in sections:
        for lead, detail, raw in split_items(section_body):
            if CLOSED.match(raw):
                closed += 1
                continue
            items.append(Item(relative(path), title, lead, detail))

    stray: list[str] = []
    if not sections:
        for line in lines:
            if TBD.search(line):
                stray.append(collapse(LIST_MARKER.sub("", line, count=1)))
    return items, stray, closed


def read_notes(path: Path) -> list[str]:
    """Every sentence of every `notes` field in one `.tres` that names a TBD."""
    found: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = NOTES.match(line.strip())
        if match is None:
            continue
        note = match.group(1).replace('\\"', '"').replace("\\n", " ")
        if not TBD.search(note):
            continue
        sentences = [
            collapse(sentence)
            for sentence in re.split(r"(?<=[.;])\s+", note)
            if TBD.search(sentence)
        ]
        for sentence in sentences[:MAX_NOTE_SENTENCES]:
            found.append(shorten(sentence))
        if len(sentences) > MAX_NOTE_SENTENCES:
            found.append("… and %d more TBD sentences in the same note" % (
                len(sentences) - MAX_NOTE_SENTENCES
            ))
    return found


def gather() -> tuple[list[tuple[Path, list[Item], list[str], int]], list[tuple[Path, list[str]]]]:
    systems: list[tuple[Path, list[Item], list[str], int]] = []
    for readme in sorted(SYSTEMS_DIR.glob("*/README.md")):
        items, stray, closed = read_system_readme(readme)
        systems.append((readme, items, stray, closed))
    data: list[tuple[Path, list[str]]] = []
    for resource in sorted(DATA_DIR.rglob("*.tres")):
        notes = read_notes(resource)
        if notes:
            data.append((resource, notes))
    return systems, data


def render(systems, data) -> str:
    out: list[str] = []
    owed_total = sum(len(items) for _, items, _, _ in systems)
    closed_total = sum(closed for _, _, _, closed in systems)
    data_notes = sum(len(notes) for _, notes in data)

    out.append("# Owed items — the whole bill")
    out.append("")
    out.append(
        "Generated by `godot/tools/rollup_owed.py`. Every line below is quoted from the "
        "file named beside it; the tool decides nothing and prioritises nothing. Edit the "
        "owning README or `.tres` to change what appears here."
    )
    out.append("")
    out.append("| | |")
    out.append("|---|---|")
    out.append("| Systems reporting something owed | %d of %d |" % (
        sum(1 for _, items, stray, _ in systems if items or stray), len(systems)
    ))
    out.append("| Owed items still open | %d |" % owed_total)
    out.append("| Owed items a later round struck out | %d |" % closed_total)
    out.append("| `.tres` files whose `notes` name a TBD | %d |" % len(data))
    out.append("| TBD sentences in those notes | %d |" % data_notes)
    out.append("")

    out.append("## By system")
    out.append("")
    for readme, items, stray, closed in systems:
        name = readme.parent.name
        out.append("### `systems/%s/`" % name)
        out.append("")
        if not items and not stray:
            out.append(
                "_No owed section and no TBD anywhere in `%s` — this system claims to owe "
                "nothing._" % relative(readme)
            )
            out.append("")
            continue
        if closed:
            out.append("_%d item(s) here were struck out by a later round and are not listed._" % closed)
            out.append("")
        section = ""
        for item in items:
            if item.section != section:
                section = item.section
                out.append("**%s** — `%s`" % (section, relative(readme)))
                out.append("")
            if item.lead:
                out.append("- **%s** %s" % (item.lead, shorten(item.detail)))
            else:
                out.append("- %s" % shorten(item.detail))
        if stray:
            out.append(
                "**No owed section** — TBDs found in the prose of `%s`:" % relative(readme)
            )
            out.append("")
            for line in stray:
                out.append("- %s" % shorten(line))
        out.append("")

    out.append("## By data file")
    out.append("")
    out.append(
        "The `notes` field is doc-only and exempt from the localization lint precisely so a "
        "definition can carry the reason it holds a placeholder. These are the ones that say TBD."
    )
    out.append("")
    for resource, notes in data:
        out.append("**`%s`**" % relative(resource))
        out.append("")
        for note in notes:
            out.append("- %s" % note)
        out.append("")
    return "\n".join(out).rstrip() + "\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Roll every owed item up into one markdown page.")
    parser.add_argument(
        "--counts",
        action="store_true",
        help="print only the tallies, one per line, for a script that watches the number",
    )
    args = parser.parse_args(argv)

    if not SYSTEMS_DIR.is_dir():
        print("rollup_owed.py: no %s - run it from a checkout" % SYSTEMS_DIR, file=sys.stderr)
        return 2

    systems, data = gather()
    if args.counts:
        print("systems: %d" % len(systems))
        print("owed_items: %d" % sum(len(items) for _, items, _, _ in systems))
        print("closed_items: %d" % sum(closed for _, _, _, closed in systems))
        print("tres_with_tbd_notes: %d" % len(data))
        print("tbd_note_sentences: %d" % sum(len(notes) for _, notes in data))
        return 0
    sys.stdout.write(render(systems, data))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
