#!/usr/bin/env python3
"""Cut the Fool's SOUTH facing still into cutout-rig parts (animation spike A2).

South is the hard facing for a cutout rig and that is exactly why it is here:
walking towards the camera, the stride happens along the view axis, so almost
none of it can be expressed by rotating a bone. What survives is the set of
top-down cheats - vertical bob, a scale pulse, and a handful of SWAPPED foot
drawings instead of a rotated ankle - so the parts list is different from east:

  * legs are one piece each (a knee bend is invisible from the front);
  * each boot is cut once and then re-sampled into three drawn positions
    (planted, lifted, forward) that the rig swaps between;
  * both arms exist, because the painting draws both.

Source : art/game-ready-sprites-v1/frames/fool/directions/south.png
Output : art/spike/fool-cutout-south/<part>.png + parts.json

Crop space is the source's alpha bbox (145, 17)-(329, 452): 184 x 435, with the
hair at y=8 and the boot soles at y=435. The rig origin is the ground point
(92, 433), midway between the two ankles.

Run:  python3 godot/tools/spike/segment_fool_south.py
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from spike_cut import Cutter  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(
    GODOT, "art", "game-ready-sprites-v1", "frames", "fool", "directions", "south.png"
)
OUT = os.path.join(GODOT, "art", "spike", "fool-cutout-south")

CROP = (145, 17, 329, 452)
ORIGIN = (92.0, 433.0)

PIVOTS = {
    "head": (100.0, 124.0),  # base of the neck
    "torso": (100.0, 140.0),  # shoulder line
    "arm_left": (62.0, 144.0),  # the arm holding the bindle
    "arm_right": (150.0, 144.0),  # the free arm
    "leg_left": (66.0, 284.0),  # hip
    "leg_right": (123.0, 284.0),
    "foot_left": (54.0, 399.0),  # ankle
    "foot_right": (131.0, 399.0),
    "stick": (78.0, 168.0),  # the grip
    "bag": (40.0, 74.0),  # the knot
}

## The three drawn foot positions the rig swaps between. Scales are about the
## ankle: a foot swung towards the camera reads as shorter and a little wider
## (you see more sole); a foot planted forward reads as slightly larger.
FOOT_VARIANTS = {
    "lift": (1.04, 0.70),
    "fwd": (1.07, 1.07),
}


def main() -> None:
    cut = Cutter(SRC, CROP, ORIGIN, OUT)
    alpha, xx, yy = cut.alpha, cut.xx, cut.yy

    # --- head --------------------------------------------------------------
    head = alpha & cut.poly([
        (44, 0), (156, 0), (156, 70), (150, 100), (138, 120),
        (112, 128), (84, 126), (62, 112), (48, 80), (44, 34),
    ])

    # --- bindle sack, and the stick it hangs from --------------------------
    bag = alpha & ~head & cut.poly([
        (0, 48), (30, 46), (48, 66), (56, 100), (52, 140),
        (38, 172), (14, 182), (0, 168),
    ])
    stick = alpha & ~head & ~bag & cut.poly([
        (36, 26), (58, 24), (100, 176), (92, 196), (74, 196), (36, 44),
    ])

    # --- arms ---------------------------------------------------------------
    # Left: sleeve plus the fist on the stick. It barely moves - it is holding
    # the bindle - so it comes out as one rigid piece.
    arm_left = alpha & ~head & ~bag & ~stick & cut.poly([
        (30, 136), (62, 132), (84, 142), (96, 166), (92, 194),
        (70, 206), (44, 202), (26, 178), (24, 152),
    ])
    # Right: the free arm, shoulder to hand, one piece. A south-facing arm
    # swing is fore-aft, which is towards the camera: it is carried by a
    # vertical slide and a scale pulse, not by an elbow.
    arm_right = alpha & ~head & cut.poly([
        (134, 134), (162, 132), (182, 150), (182, 210),
        (176, 262), (172, 292), (146, 292), (140, 250), (132, 190),
    ])

    # --- legs ---------------------------------------------------------------
    # The painting leaves a real alpha gap between the legs here, so no seam
    # has to be invented: x < 96 is the left leg, x > 96 the right.
    leg_left = alpha & (yy >= 276) & (yy <= 402) & (xx < 96)
    leg_right = alpha & (yy >= 276) & (yy <= 402) & (xx >= 96)
    foot_left = alpha & (yy >= 396) & (xx < 96)
    foot_right = alpha & (yy >= 396) & (xx >= 96)

    # --- torso --------------------------------------------------------------
    torso_keep = (
        alpha & (yy >= 118) & (yy <= 296)
        & ~head & ~bag & ~stick & ~arm_left & ~arm_right
    )
    torso_all = alpha & (yy >= 118) & (yy <= 296) & ~head & ~bag
    hole = torso_all & ~torso_keep
    filled = cut.fill_holes(torso_keep, hole)
    torso = torso_keep | hole
    filled[..., 3] = 0
    filled[..., 3] = (torso * 255).astype(filled.dtype)

    cut.save_part("head", cut.rgba, head, PIVOTS["head"])
    cut.save_part("torso", filled, torso, PIVOTS["torso"])
    cut.save_part("arm_left", cut.rgba, arm_left, PIVOTS["arm_left"])
    cut.save_part("arm_right", cut.rgba, arm_right, PIVOTS["arm_right"])
    cut.save_part("leg_left", cut.rgba, leg_left, PIVOTS["leg_left"])
    cut.save_part("leg_right", cut.rgba, leg_right, PIVOTS["leg_right"])
    cut.save_part("foot_left", cut.rgba, foot_left, PIVOTS["foot_left"])
    cut.save_part("foot_right", cut.rgba, foot_right, PIVOTS["foot_right"])
    cut.save_part("bag", cut.rgba, bag, PIVOTS["bag"])
    cut.save_part("stick", cut.rgba, stick, PIVOTS["stick"])

    for side in ["left", "right"]:
        for name, (sx, sy) in FOOT_VARIANTS.items():
            cut.save_scaled_variant("foot_%s" % side, "foot_%s_%s" % (side, name), sx, sy)

    cut.write(
        "spike-quality south cutout; three swapped foot drawings per side, "
        "see tools/spike/segment_fool_south.py"
    )


if __name__ == "__main__":
    main()
