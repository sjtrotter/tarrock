#!/usr/bin/env python3
"""Measure a character sprite family's per-frame pivots, so nobody eyeballs them.

`godot/scripts/player.gd` carries hand-measured pivot tables for the Fool and says
"Do not eyeball these"; this is the tool that produced the same kind of numbers for
round 8's Blank family, and it is checked in so the next family's numbers have a
provenance rather than a story.

The convention is `CharacterAnimator`'s, and it is the one thing here that matters:

    anchor  = (alpha-weighted centroid x, lowest opaque pixel y)
    offset  = cell centre - anchor

The centroid is the steadiest horizontal landmark across a cycle (the frames drift
across the cell), and the lowest opaque pixel is the planted foot, so a walk cycle
stays on its ground line instead of bobbing.

A cycle's `scale` is derived rather than measured: an action cell (320 px) and a
direction cell (512 px) are different sizes, so a clip needs its own uniform scale to
keep the figure the same height on screen. `--match-height` is the on-screen height in
pixels every clip is solved for; the Fool's direction sheet at his authored 0.28 is
the reference (435 px of opaque bbox x 0.28 = 121.8).

Usage:

    python3 godot/tools/measure_sprite_pivots.py --family blank_sword_two
    python3 godot/tools/measure_sprite_pivots.py --family fool --match-height 121.8

It prints GDScript-shaped tables ready to paste, plus the raw measurements. It writes
nothing: the numbers land in code by a human copying them, with this command in the
comment above them.

Needs Pillow (`python3 -m pip install --user pillow`). Not run by the test suite: the
art it measures is checked in, so the numbers it produced are checked in too.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent
GODOT_DIR = TOOLS_DIR.parent
PACK_DIR = GODOT_DIR / "art" / "game-ready-sprites-v1" / "frames"

DIRECTIONS = [
    "east",
    "southeast",
    "south",
    "southwest",
    "west",
    "northwest",
    "north",
    "northeast",
]

# The Fool's authored direction sheet at his authored scale: 435 px of opaque bbox
# times 0.28. Every other clip is solved to the same on-screen height so a Blank and
# the Fool stand on the same ground at the same size.
DEFAULT_MATCH_HEIGHT = 121.8


def measure(path: Path) -> dict[str, float]:
    """One frame's anchor, offset, opaque bbox height and cell size."""
    from PIL import Image  # imported here so --help works without Pillow
    import numpy as np

    image = Image.open(path).convert("RGBA")
    alpha = np.array(image)[:, :, 3].astype(float)
    height, width = alpha.shape
    total = alpha.sum()
    if total <= 0.0:
        raise SystemExit("%s is fully transparent" % path)
    columns = np.arange(width)[None, :]
    centroid_x = float((alpha * columns).sum() / total)
    rows = np.nonzero(alpha > 0)[0]
    bottom_y = float(rows.max())
    return {
        "centroid_x": centroid_x,
        "bottom_y": bottom_y,
        "offset_x": width / 2.0 - centroid_x,
        "offset_y": height / 2.0 - bottom_y,
        "bbox_height": float(rows.max() - rows.min() + 1),
        "cell": float(width),
    }


def report(title: str, frames: list[tuple[str, Path]], match_height: float) -> None:
    """Print one group's measurements and the GDScript table for it."""
    print("### %s" % title)
    rows = []
    for name, path in frames:
        if not path.exists():
            print("  (missing) %s" % path.relative_to(GODOT_DIR))
            continue
        found = measure(path)
        rows.append((name, found))
        print(
            "  %-12s cell %d  centroid_x %7.2f  bottom_y %6.1f  bbox_h %5.0f"
            % (name, found["cell"], found["centroid_x"], found["bottom_y"], found["bbox_height"])
        )
    if not rows:
        return
    mean_bbox = sum(found["bbox_height"] for _, found in rows) / len(rows)
    scale = match_height / mean_bbox
    print("  mean bbox height %.1f -> scale %.4f for %.1f px on screen" % (
        mean_bbox, scale, match_height
    ))
    print("  GDScript:")
    for name, found in rows:
        print('    "%s": Vector2(%.1f, %.1f),' % (name, found["offset_x"], found["offset_y"]))
    print("    scale = %.4f" % scale)
    print()


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--family", required=True, help="a folder under art/.../frames/")
    parser.add_argument(
        "--match-height",
        type=float,
        default=DEFAULT_MATCH_HEIGHT,
        help="on-screen height in pixels every clip is solved for",
    )
    arguments = parser.parse_args(argv)

    family_dir = PACK_DIR / arguments.family
    if not family_dir.is_dir():
        print("no such sprite family: %s" % family_dir, file=sys.stderr)
        return 2

    directions = [
        (name, family_dir / "directions" / ("%s.png" % name)) for name in DIRECTIONS
    ]
    report("%s directions" % arguments.family, directions, arguments.match_height)

    actions_dir = family_dir / "actions"
    if actions_dir.is_dir():
        rows: dict[str, list[tuple[str, Path]]] = {}
        for path in sorted(actions_dir.glob("*.png")):
            action = path.stem.rsplit("-", 1)[0]
            rows.setdefault(action, []).append((path.stem, path))
        for action, frames in sorted(rows.items()):
            report("%s %s" % (arguments.family, action), frames, arguments.match_height)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
