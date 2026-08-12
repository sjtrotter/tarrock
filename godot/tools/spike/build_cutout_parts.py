#!/usr/bin/env python3
"""Bake the purpose-drawn Fool cutout parts into rig-ready art + parts.json.

    python3 godot/tools/spike/build_cutout_parts.py [--check]

Why this file exists
--------------------
The Codex part sheets draw each limb in its own cell, at whatever size fills
the cell, so no two parts share a scale and several are drawn at proportions
the painting does not use. The first attempt at wiring them up derived one
global scale from the torso's width and re-used each OLD sliced part's
"pivot as a fraction of its own bounding box" for the new drawing. Both
assumptions are false, and together they put every attachment in the wrong
place - most visibly the bindle, which ended up worn as a backpack with the
stick buried behind the torso.

So placement is measured, not inferred. For every part this file records the
similarity/affine transform that lands the drawing where the AUTHORITATIVE
still - art/game-ready-sprites-v1/frames/fool/directions/{east,south}.png -
draws it: a scale per axis, a rest rotation, and an anchor point in the part
mapped onto a landmark in the still. Those numbers were measured off the
painting and then refined by maximising silhouette IoU of the whole assembly
against the still (see the rest-pose gate in tests/spike_rig_test.gd).

The transform is baked into the exported PNG, so the rig keeps zero rest
rotations and unit sprite scales and nothing downstream has to know about any
of this.

Input : art/spike/fool-cutout-src/{east,south}/*.png   (Codex art, native size)
Output: art/spike/fool-cutout/*.png + parts.json
        art/spike/fool-cutout-south/*.png + parts.json

--check re-composites the exported parts exactly the way the rig will and
reports the silhouette IoU against the still without writing anything.
"""

from __future__ import annotations

import argparse
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC_ROOT = os.path.join(GODOT, "art", "spike", "fool-cutout-src")
STILLS = os.path.join(GODOT, "art", "game-ready-sprites-v1", "frames", "fool", "directions")

# --- east -------------------------------------------------------------------

EAST_CROP = (42, 22, 213, 456)
EAST_ORIGIN = (80.0, 431.0)

# Trims applied to the source drawing before placement. The Codex boots are
# drawn thigh-high; the painting tucks the trouser into a knee-high boot, so
# the surplus shaft is cut off rather than squashed.
EAST_TRIM = {
    "leg_near_shin_boot": (0, 105, 157, 302),
    "leg_far_shin_boot": (0, 100, 140, 295),
}

# The east torso is drawn with a large gold-trimmed armhole oval. The painting
# has no such hole - the sleeve covers the shoulder - and left in it reads as a
# hole in the Fool's chest, so it is patched with the tunic's own cloth.
# part -> (ellipse centre, ellipse radii, donor rect of clean cloth)
EAST_PATCH = {
    "torso": ((95, 115), (66, 87), (126, 96, 158, 166)),
}

# part -> (sx, sy, rest rotation in degrees CCW, anchor in part px,
#          the crop-space landmark that anchor lands on)
EAST_PLACEMENT = {
    "head_scarf":         (0.4032, 0.4055, 3.0, (102, 1), (78.5, 1.0)),
    "torso":              (0.4980, 0.5955, 1.5, (110, 305), (93.5, 264.0)),
    "arm_near_upper":     (0.5048, 0.4589, 3.0, (51, 2), (97.0, 114.0)),
    "arm_near_lower":     (0.3070, 0.3070, 46.8, (15, 75), (103.0, 203.0)),
    "arm_far_upper":      (0.4000, 0.3600, 0.0, (58, 30), (83.0, 118.0)),
    "arm_far_lower":      (0.2500, 0.2500, 0.0, (35, 20), (90.0, 198.0)),
    "leg_near_thigh":     (0.3161, 0.3035, -6.0, (86, 41), (99.0, 254.0)),
    "leg_near_shin_boot": (0.5280, 0.5500, 0.0, (15, 0), (68.0, 328.0)),
    "leg_far_thigh":      (0.3430, 0.3161, 0.0, (68, 41), (70.0, 254.0)),
    "leg_far_shin_boot":  (0.4892, 0.5200, 0.0, (15, 0), (50.0, 315.0)),
    "knee_cap_near":      (0.5096, 0.5000, 3.0, (37, 39), (96.0, 336.0)),
    "knee_cap_far":       (0.4800, 0.4800, -1.5, (37, 39), (68.0, 317.0)),
    "bindle_bag":         (0.4308, 0.5532, -1.5, (78, 176), (35.0, 130.0)),
    "bindle_stick":       (0.6099, 0.5855, -3.2, (10, 10), (46.0, 44.0)),
}

# Codex part -> the rig's part key (the key the .gd files ask parts.json for).
EAST_KEYS = {
    "head_scarf": "head",
    "torso": "torso",
    "arm_near_upper": "arm_upper",
    "arm_near_lower": "arm_lower",
    "arm_far_upper": "arm_far_upper",
    "arm_far_lower": "arm_far_lower",
    "leg_near_thigh": "leg_near_thigh",
    "leg_near_shin_boot": "leg_near_shin",
    "leg_far_thigh": "leg_far_thigh",
    "leg_far_shin_boot": "leg_far_shin",
    "knee_cap_near": "knee_cap_near",
    "knee_cap_far": "knee_cap_far",
    "bindle_bag": "bag",
    "bindle_stick": "stick",
}

# Joint pivots in crop space, read off the painting. A part's exported offset
# is relative to the pivot of the bone that carries it.
EAST_PIVOTS = {
    "head": (103.0, 100.0),
    "torso": (95.0, 125.0),
    "arm_upper": (89.0, 118.0),
    "arm_lower": (100.0, 203.0),
    "arm_far_upper": (83.0, 116.0),
    "arm_far_lower": (91.0, 198.0),
    "leg_near_thigh": (98.0, 262.0),
    "leg_near_shin": (98.0, 331.0),
    "leg_far_thigh": (66.0, 262.0),
    "leg_far_shin": (66.0, 331.0),
    "knee_cap_near": (98.0, 331.0),
    "knee_cap_far": (66.0, 331.0),
    "stick": (133.0, 160.0),
    "bag": (44.0, 66.0),
}

EAST_ORDER = [
    "bag",
    "knee_cap_far", "leg_far_thigh", "leg_far_shin",
    "arm_far_upper", "arm_far_lower",
    "knee_cap_near", "leg_near_thigh", "leg_near_shin",
    "torso", "arm_upper", "stick", "arm_lower", "head",
]

# --- south ------------------------------------------------------------------

SOUTH_CROP = (145, 17, 329, 452)
SOUTH_ORIGIN = (92.0, 433.0)

# The Codex south names are ANATOMICAL (the Fool's own left/right); the rig's
# are the VIEWER's. arm_right_* - the bent arm with the fist - is therefore the
# rig's ArmLeft, the arm that grips the stick. Mapping these by name (which the
# previous pass did) hands the bindle to the wrong hand and leaves the gripping
# fist closed around nothing on the far side of the body.
SOUTH_SOURCE = {
    "head": "head_scarf",
    "torso": "torso",
    "arm_left_upper": "arm_right_upper",
    "arm_left_lower": "arm_right_lower",
    "arm_right_upper": "arm_left_upper",
    "arm_right_lower": "arm_left_lower",
    "leg_left_thigh": "leg_right_thigh",
    "leg_right_thigh": "leg_left_thigh",
    "knee_cap_left": "knee_cap_right",
    "knee_cap_right": "knee_cap_left",
    "foot_left": "foot_right_planted",
    "foot_left_lift": "foot_right_lift",
    "foot_left_fwd": "foot_right_forward",
    "foot_right": "foot_left_planted",
    "foot_right_lift": "foot_left_lift",
    "foot_right_fwd": "foot_left_forward",
    "bag": "bindle_bag",
    "stick": "bindle_stick",
}

SOUTH_PLACEMENT = {
    "bag":             (0.2676, 0.4277, -7.5, (95.0, 149.5), (30.0, 100.0)),
    "knee_cap_left":   (0.2834, 0.2130, 0.0, (57.5, 67.5), (66.0, 345.0)),
    "leg_left_thigh":  (0.2429, 0.2191, -6.0, (94.0, 157.0), (65.0, 296.0)),
    "foot_left":       (0.3701, 0.4141, -6.0, (63.5, 134.5), (54.5, 380.5)),
    "knee_cap_right":  (0.2982, 0.2162, 0.0, (57.0, 68.0), (120.0, 339.0)),
    "leg_right_thigh": (0.2337, 0.2370, -1.5, (94.5, 157.5), (125.0, 298.0)),
    "foot_right":      (0.3880, 0.3300, 6.0, (62.0, 151.5), (131.5, 376.0)),
    "torso":           (0.4416, 0.5845, -3.0, (140.5, 155.5), (98.0, 198.0)),
    "arm_right_upper": (0.3310, 0.3829, 7.5, (72.5, 152.5), (149.0, 177.0)),
    "arm_right_lower": (0.4059, 0.2457, 7.5, (54.0, 135.0), (168.0, 246.0)),
    "arm_left_upper":  (0.4305, 0.2717, -7.5, (73.5, 132.5), (42.0, 176.0)),
    "stick":           (0.5840, 0.5606, -14.5, (18.5, 160.5), (54.5, 118.5)),
    "arm_left_lower":  (0.2447, 0.3748, 4.5, (119.5, 95.5), (57.0, 196.0)),
    "head":            (0.3665, 0.4356, 7.5, (150.5, 155.5), (89.0, 69.0)),
}

# The swapped boot poses inherit the planted boot's transform and are aligned
# to it by the top of the boot - the end that hangs off the knee and must not
# move when the drawing changes.
SOUTH_BOOT_SWAPS = {
    "foot_left": ["foot_left_lift", "foot_left_fwd"],
    "foot_right": ["foot_right_lift", "foot_right_fwd"],
}

SOUTH_PIVOTS = {
    "head": (100.0, 124.0),
    "torso": (100.0, 140.0),
    "arm_left_upper": (62.0, 144.0),
    "arm_left_lower": (50.0, 190.0),
    "arm_right_upper": (150.0, 144.0),
    "arm_right_lower": (152.0, 214.0),
    "leg_left_thigh": (66.0, 284.0),
    "leg_right_thigh": (123.0, 284.0),
    "knee_cap_left": (66.0, 340.0),
    "knee_cap_right": (123.0, 340.0),
    "foot_left": (60.0, 336.0),
    "foot_right": (127.0, 336.0),
    "stick": (78.0, 168.0),
    "bag": (40.0, 74.0),
}

SOUTH_ORDER = [
    "bag",
    "knee_cap_left", "leg_left_thigh", "foot_left",
    "knee_cap_right", "leg_right_thigh", "foot_right",
    "torso",
    "arm_right_upper", "arm_right_lower",
    "arm_left_upper", "stick", "arm_left_lower",
    "head",
]


# --- baking -----------------------------------------------------------------


def patch_hole(img: Image.Image, centre, radii, donor_box) -> Image.Image:
    """Replace an elliptical region with cloth tiled from elsewhere on the part."""
    a = np.array(img)
    stencil = Image.new("L", img.size, 0)
    ImageDraw.Draw(stencil).ellipse(
        (centre[0] - radii[0], centre[1] - radii[1],
         centre[0] + radii[0], centre[1] + radii[1]), fill=255)
    hole = (np.array(stencil) > 127) & (a[..., 3] > 128)

    dx0, dy0, dx1, dy1 = donor_box
    donor = a[dy0:dy1, dx0:dx1, :3]
    dh, dw = donor.shape[:2]
    ys, xs = np.nonzero(hole)
    ty = (ys - dy0) % (2 * dh)
    ty = np.where(ty < dh, ty, 2 * dh - 1 - ty)
    tx = (xs - dx0) % (2 * dw)
    tx = np.where(tx < dw, tx, 2 * dw - 1 - tx)
    out = a.copy()
    out[ys, xs, :3] = donor[ty, tx]

    img2 = Image.fromarray(out)
    soft = img2.filter(ImageFilter.GaussianBlur(1.6))
    mask = Image.fromarray((hole * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2.0))
    img2 = Image.composite(soft, img2, mask)
    final = np.array(img2)
    final[..., 3] = a[..., 3]
    return Image.fromarray(final)


def bake(img: Image.Image, sx: float, sy: float, angle: float):
    """Scale then rotate, trimmed to the alpha bounds.

    Returns (baked image, f) where f maps a point in the *input* image to its
    pixel position inside the baked one.
    """
    w = max(2, int(round(img.width * sx)))
    h = max(2, int(round(img.height * sy)))
    scaled = img.resize((w, h), Image.LANCZOS)
    rotated = scaled if abs(angle) < 1e-6 else scaled.rotate(
        angle, resample=Image.BICUBIC, expand=True)
    box = rotated.getbbox()
    if box is None:
        raise ValueError("part became empty")
    out = rotated.crop(box)

    rad = math.radians(angle)
    ca, sa = math.cos(rad), math.sin(rad)
    cx, cy = w / 2.0, h / 2.0
    ncx, ncy = rotated.width / 2.0, rotated.height / 2.0

    def f(pt):
        px, py = pt[0] * sx - cx, pt[1] * sy - cy
        return (ncx + ca * px + sa * py - box[0], ncy - sa * px + ca * py - box[1])

    return out, f


def build_facing(name, crop, origin, source_dir, out_dir, placement, pivots,
                 keys=None, trim=None, patch=None, source_map=None, swaps=None,
                 write=True):
    trim = trim or {}
    patch = patch or {}
    keys = keys or {}
    parts = {}
    baked = {}

    def load(part_key, src_stem):
        img = Image.open(os.path.join(source_dir, src_stem + ".png")).convert("RGBA")
        if src_stem in trim:
            img = img.crop(trim[src_stem])
        if src_stem in patch:
            img = patch_hole(img, *patch[src_stem])
        return img

    for src_stem, (sx, sy, angle, anchor, landmark) in placement.items():
        rig_key = keys.get(src_stem, src_stem)
        stem = source_map[src_stem] if source_map else src_stem
        img = load(rig_key, stem)
        out, f = bake(img, sx, sy, angle)
        ax, ay = f(anchor)
        top_left = (landmark[0] - ax, landmark[1] - ay)
        pivot = pivots[rig_key]
        parts[rig_key] = {
            "file": rig_key + ".png",
            "size": [out.width, out.height],
            "offset": [round(top_left[0] - pivot[0], 2), round(top_left[1] - pivot[1], 2)],
            "rig_position": [pivot[0] - origin[0], pivot[1] - origin[1]],
        }
        baked[rig_key] = (out, top_left)
        if write:
            out.save(os.path.join(out_dir, rig_key + ".png"))

    # swapped drawings: same transform, aligned by the top of the boot
    for base, variants in (swaps or {}).items():
        sx, sy, angle, _, _ = placement[base]
        base_img, base_tl = baked[base]
        base_cols = np.nonzero((np.array(base_img)[..., 3] > 96).any(0))[0]
        base_top = base_tl[0] + 0.5 * (base_cols.min() + base_cols.max()), base_tl[1]
        for variant in variants:
            stem = source_map[variant] if source_map else variant
            out, _ = bake(load(variant, stem), sx, sy, angle)
            cols = np.nonzero((np.array(out)[..., 3] > 96).any(0))[0]
            top_left = (base_top[0] - 0.5 * (cols.min() + cols.max()), base_top[1])
            pivot = pivots[base]
            parts[variant] = {
                "file": variant + ".png",
                "size": [out.width, out.height],
                "offset": [round(top_left[0] - pivot[0], 2), round(top_left[1] - pivot[1], 2)],
                "rig_position": [pivot[0] - origin[0], pivot[1] - origin[1]],
            }
            if write:
                out.save(os.path.join(out_dir, variant + ".png"))

    manifest = {
        "source": "art/game-ready-sprites-v1/frames/fool/directions/%s.png" % name,
        "crop": list(crop),
        "crop_size": [crop[2] - crop[0], crop[3] - crop[1]],
        "origin": list(origin),
        "figure_height_px": crop[3] - crop[1],
        "note": ("baked by tools/spike/build_cutout_parts.py - placement measured "
                 "against the still, transform baked into the art, so sprites are "
                 "drawn at unit scale and zero rest rotation"),
        "parts": parts,
    }
    if write:
        with open(os.path.join(out_dir, "parts.json"), "w") as handle:
            json.dump(manifest, handle, indent=2, sort_keys=False)
            handle.write("\n")
    return manifest


def rest_iou(name, crop, origin, out_dir, order):
    """Composite the exported parts the way the rig will, against the still."""
    with open(os.path.join(out_dir, "parts.json")) as handle:
        manifest = json.load(handle)
    size = (crop[2] - crop[0], crop[3] - crop[1])
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    for key in order:
        part = manifest["parts"][key]
        img = Image.open(os.path.join(out_dir, part["file"])).convert("RGBA")
        x = part["rig_position"][0] + origin[0] + part["offset"][0]
        y = part["rig_position"][1] + origin[1] + part["offset"][1]
        canvas.alpha_composite(img, (int(round(x)), int(round(y))))
    still = Image.open(os.path.join(STILLS, name + ".png")).convert("RGBA").crop(crop)
    a = np.array(canvas)[..., 3] > 48
    b = np.array(still)[..., 3] > 48
    return canvas, still, float((a & b).sum()) / max(float((a | b).sum()), 1.0)


def write_proof(canvas, still, iou, path, scale=2):
    """still | rig assembly | red/blue silhouette overlay, at 2x."""
    def tint(img, rgb):
        alpha = Image.fromarray((np.array(img)[..., 3] // 2).astype(np.uint8))
        return Image.merge("RGBA", (*[Image.new("L", img.size, c) for c in rgb], alpha))

    w, h = still.size
    sheet = Image.new("RGBA", (w * 3 + 40, h), (255, 255, 255, 255))
    sheet.alpha_composite(still, (0, 0))
    sheet.alpha_composite(canvas, (w + 20, 0))
    overlay = Image.new("RGBA", still.size, (255, 255, 255, 255))
    overlay.alpha_composite(tint(still, (220, 0, 0)))
    overlay.alpha_composite(tint(canvas, (0, 90, 230)))
    sheet.alpha_composite(overlay, (w * 2 + 40, 0))
    sheet = sheet.resize((sheet.width * scale, sheet.height * scale), Image.LANCZOS)
    draw = ImageDraw.Draw(sheet)
    draw.text((6, 6), "still", fill=(0, 0, 0, 255))
    draw.text((w * scale + 46, 6), "rig rest pose", fill=(0, 0, 0, 255))
    draw.text((w * 2 * scale + 86, 6), "overlay  IoU %.3f" % iou, fill=(0, 0, 0, 255))
    sheet.convert("RGB").save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="report IoU only, write nothing")
    ap.add_argument("--proof", metavar="DIR",
                    help="also write still | assembly | overlay comparison sheets there")
    args = ap.parse_args()
    write = not args.check

    east_out = os.path.join(GODOT, "art", "spike", "fool-cutout")
    south_out = os.path.join(GODOT, "art", "spike", "fool-cutout-south")
    os.makedirs(east_out, exist_ok=True)
    os.makedirs(south_out, exist_ok=True)

    build_facing("east", EAST_CROP, EAST_ORIGIN,
                 os.path.join(SRC_ROOT, "east"), east_out,
                 EAST_PLACEMENT, EAST_PIVOTS, keys=EAST_KEYS,
                 trim=EAST_TRIM, patch=EAST_PATCH, write=write)
    build_facing("south", SOUTH_CROP, SOUTH_ORIGIN,
                 os.path.join(SRC_ROOT, "south"), south_out,
                 SOUTH_PLACEMENT, SOUTH_PIVOTS, source_map=SOUTH_SOURCE,
                 swaps=SOUTH_BOOT_SWAPS, write=write)

    for name, crop, origin, out_dir, order in (
        ("east", EAST_CROP, EAST_ORIGIN, east_out, EAST_ORDER),
        ("south", SOUTH_CROP, SOUTH_ORIGIN, south_out, SOUTH_ORDER),
    ):
        canvas, still, iou = rest_iou(name, crop, origin, out_dir, order)
        print("%-6s rest-pose silhouette IoU vs still: %.4f" % (name, iou))
        if args.proof:
            os.makedirs(args.proof, exist_ok=True)
            write_proof(canvas, still, iou, os.path.join(args.proof, "rest-%s.png" % name))


if __name__ == "__main__":
    main()
