#!/usr/bin/env python3
"""Cut the Fool's EAST facing still into cutout-rig parts (animation spike A).

Not production art. This is deliberately rough: the spike judges MOTION, not
craft, so the masks are hand-authored boxes and colour rules read off the
painting, and the one real occlusion (the tunic behind the near arm and the
bindle stick) is filled with a nearest-opaque-pixel smear.

Source : art/game-ready-sprites-v1/frames/fool/directions/east.png
Output : art/spike/fool-cutout/<part>.png + parts.json

All coordinates in this file are "crop space": the source's alpha bounding box
(42, 22)-(213, 456), i.e. a 171 x 434 image with the hair at y=4 and the
planted boot at y=434. The rig origin is the ground point (80, 431) - mid-way between the two ankles.

Run:  python3 godot/tools/spike/segment_fool_east.py
"""

from __future__ import annotations

import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(
    GODOT, "art", "game-ready-sprites-v1", "frames", "fool", "directions", "east.png"
)
OUT = os.path.join(GODOT, "art", "spike", "fool-cutout")

CROP = (42, 22, 213, 456)  # the source alpha bbox
W, H = CROP[2] - CROP[0], CROP[3] - CROP[1]  # 171 x 434

# The rig origin: ground level, under the body's centre line.
ORIGIN = (80.0, 431.0)

# The bindle stick, as a straight segment. The painting draws it in three
# pieces that do not line up (a generative-art defect, see the report); this
# line is fitted through the two pieces that agree - the chest band and the
# wooden tip below the fist - and the stick is re-synthesised along it.
STICK_A = (58.0, 62.0)
STICK_B = (170.0, 222.0)
STICK_HALF_WIDTH = 6.5

# Joint pivots, read off the painting (see report for the landmark zooms).
PIVOTS = {
    "head": (103.0, 96.0),
    "torso": (98.0, 120.0),  # chest / shoulder line
    "arm_upper": (90.0, 122.0),  # shoulder
    "arm_lower": (102.0, 206.0),  # elbow
    "leg_far_thigh": (62.0, 262.0),  # far hip
    "leg_far_shin": (64.0, 333.0),  # far knee (nudged forward: the IK solves knee-forward)
    "leg_near_thigh": (98.0, 262.0),  # near hip
    "leg_near_shin": (104.0, 333.0),  # near knee (nudged forward, ditto)
    "leg_far_foot": (58.0, 400.0),  # far ankle
    "leg_near_foot": (100.0, 400.0),  # near ankle
    "stick": (133.0, 160.0),  # the grip, in the near fist
    "bag": (58.0, 66.0),  # the knot, where the sack meets the stick
}


def load_crop() -> np.ndarray:
    im = Image.open(SRC).convert("RGBA").crop(CROP)
    return np.array(im).astype(np.int16)


def grids() -> tuple[np.ndarray, np.ndarray]:
    yy, xx = np.mgrid[0:H, 0:W]
    return xx, yy


def dist_to_stick(xx: np.ndarray, yy: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Perpendicular distance to the stick segment, and the along-axis t."""
    ax, ay = STICK_A
    bx, by = STICK_B
    dx, dy = bx - ax, by - ay
    length2 = dx * dx + dy * dy
    t = ((xx - ax) * dx + (yy - ay) * dy) / length2
    t = np.clip(t, 0.0, 1.0)
    px, py = ax + t * dx, ay + t * dy
    return np.hypot(xx - px, yy - py), t


def poly(points: list[tuple[float, float]]) -> np.ndarray:
    """Rasterise a hand-authored polygon in crop space."""
    stencil = Image.new("L", (W, H), 0)
    ImageDraw.Draw(stencil).polygon(points, fill=255)
    return np.array(stencil) > 127


def ellipse(cx: float, cy: float, rx: float, ry: float) -> np.ndarray:
    stencil = Image.new("L", (W, H), 0)
    ImageDraw.Draw(stencil).ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    return np.array(stencil) > 127


def grow(mask: np.ndarray, steps: int, limit: np.ndarray) -> np.ndarray:
    out = mask.copy()
    for _ in range(steps):
        grown = out.copy()
        grown[1:, :] |= out[:-1, :]
        grown[:-1, :] |= out[1:, :]
        grown[:, 1:] |= out[:, :-1]
        grown[:, :-1] |= out[:, 1:]
        out = grown & limit
    return out


def fill_holes(rgba: np.ndarray, keep: np.ndarray, hole: np.ndarray) -> np.ndarray:
    """Row-wise nearest-known-pixel fill, then a soft blur over the patch.

    Averaging four-neighbours (the obvious approach) drags the black ink
    outlines into the patch and turns the tunic into a bruise. Copying the
    nearest *real* pixel along the row keeps the cloth colour, at the cost of
    horizontal streaks - which is fine: the patch lives behind the near arm.
    """
    out = rgba.copy()
    todo = hole & ~keep
    # Never source the fill from the black ink outlines - that is what turns a
    # patched tunic into a bruise. Cloth only.
    luma = (rgba[..., 0] * 2 + rgba[..., 1] * 3 + rgba[..., 2]) // 6
    source = keep & (luma > 70)
    for y in range(H):
        known_x = np.nonzero(source[y])[0]
        if len(known_x) == 0:
            continue
        for x in np.nonzero(todo[y])[0]:
            nearest = known_x[np.argmin(np.abs(known_x - x))]
            out[y, x] = out[y, nearest]
    patch = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA").filter(
        ImageFilter.GaussianBlur(3.5)
    )
    blurred = np.array(patch).astype(np.int16)
    out[todo] = blurred[todo]
    return out


def synth_stick(rgba: np.ndarray, dist: np.ndarray, t: np.ndarray) -> np.ndarray:
    """Re-paint the stick as a straight bar using a cross-section sampled from
    the one unambiguous piece of it: the wooden tip below the fist."""
    # Sample the tip: t in [0.82, 0.97], binned by signed perpendicular offset.
    ax, ay = STICK_A
    bx, by = STICK_B
    dx, dy = bx - ax, by - ay
    length = math.hypot(dx, dy)
    nx, ny = -dy / length, dx / length  # unit normal
    xx, yy = grids()
    signed = (xx - ax) * nx + (yy - ay) * ny
    sample = (t > 0.82) & (t < 0.97) & (np.abs(signed) <= STICK_HALF_WIDTH) & (rgba[..., 3] > 8)

    profile = np.zeros((2 * int(STICK_HALF_WIDTH) + 3, 4), dtype=np.float32)
    counts = np.zeros(profile.shape[0], dtype=np.float32)
    idx = np.round(signed + STICK_HALF_WIDTH + 1).astype(int)
    valid = sample & (idx >= 0) & (idx < profile.shape[0])
    for i, px in zip(idx[valid], rgba[valid]):
        profile[i] += px
        counts[i] += 1
    for i in range(profile.shape[0]):
        if counts[i] > 0:
            profile[i] /= counts[i]
        else:  # ends of the profile: the dark outline
            profile[i] = np.array([52, 34, 22, 255], dtype=np.float32)

    band = np.zeros((H, W, 4), dtype=np.int16)
    inside = (np.abs(signed) <= STICK_HALF_WIDTH + 1.0) & (t > 0.0) & (t < 1.0)
    bi = np.clip(np.round(signed + STICK_HALF_WIDTH + 1).astype(int), 0, profile.shape[0] - 1)
    band[inside] = profile[bi[inside]].astype(np.int16)
    band[..., 3] = np.where(inside, 255, 0)
    return band


INK = np.array([46, 30, 20, 255], dtype=np.float32)


def ink_cut_edge(rgba: np.ndarray, mask: np.ndarray, side: str, width: int = 2) -> np.ndarray:
    """Darken the `width` columns along a sliced edge so it reads as a contour."""
    out = rgba.copy()
    stroke = np.zeros_like(mask)
    for row in range(H):
        cols = np.nonzero(mask[row])[0]
        if len(cols) == 0:
            continue
        if side == "left":
            stroke[row, cols[0]:cols[0] + width] = True
        else:
            stroke[row, max(cols[-1] - width + 1, 0):cols[-1] + 1] = True
    blend = 0.7
    out[stroke] = (out[stroke] * (1.0 - blend) + INK * blend).astype(np.int16)
    return out


def save_part(name: str, rgba: np.ndarray, mask: np.ndarray, parts: dict) -> None:
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        raise SystemExit("empty mask for part " + name)
    x0, x1 = int(xs.min()), int(xs.max()) + 1
    y0, y1 = int(ys.min()), int(ys.max()) + 1
    sub = rgba[y0:y1, x0:x1].copy()
    sub[~mask[y0:y1, x0:x1]] = 0
    im = Image.fromarray(sub.astype(np.uint8), "RGBA")
    im.save(os.path.join(OUT, name + ".png"))
    pivot = PIVOTS.get(name, (float(x0 + (x1 - x0) / 2.0), float(y0)))
    parts[name] = {
        "file": name + ".png",
        "size": [x1 - x0, y1 - y0],
        "origin": [x0, y0],  # top-left of the part in crop space
        "pivot": [pivot[0], pivot[1]],  # the joint, in crop space
        # Sprite2D.offset when the node sits on the pivot (centered = false).
        "offset": [x0 - pivot[0], y0 - pivot[1]],
        # Node position in rig space (origin = the ground point).
        "rig_position": [pivot[0] - ORIGIN[0], pivot[1] - ORIGIN[1]],
    }


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    rgba = load_crop()
    alpha = rgba[..., 3] > 8
    xx, yy = grids()
    dist, t = dist_to_stick(xx, yy)

    # Colour rules read off the painting are unreliable here (the "cream"
    # sleeve is actually warm beige, b~149, and collides with the gold trim),
    # so every part boundary below is a hand-authored polygon over the alpha.

    # --- head -----------------------------------------------------------
    head = alpha & poly([
        (40, 0), (145, 0), (145, 70), (138, 88), (120, 98),
        (96, 98), (72, 96), (60, 88), (52, 60), (44, 26),
    ])

    # --- bindle sack (with the tie stub the painting draws above it) ------
    bag = alpha & ~head & poly([
        (0, 32), (44, 32), (58, 58), (66, 92), (64, 132),
        (54, 172), (30, 192), (4, 186), (0, 118),
    ])

    # --- near arm: beige sleeve (an ellipse), then leather cuff + fist -----
    arm_upper = grow(alpha & ellipse(89, 160, 28, 47), 2, alpha & (yy >= 110) & (yy <= 210))
    arm_lower = alpha & poly([
        (103, 192), (99, 178), (106, 158), (118, 136), (134, 130),
        (150, 137), (157, 155), (150, 175), (136, 190), (118, 196),
    ])

    # --- legs -------------------------------------------------------------
    # Two masters, not one. The painting shows both legs touching, so there is
    # no alpha boundary to cut on: each leg is sliced along the drawn seam and
    # keeps its *outer* contour (the far leg's heel, the near leg's toe). The
    # sliced inner edge is then inked, so a straight cut reads as a contour
    # line instead of a knife mark once the legs swing apart.
    seam = np.interp(yy, [258, 274, 340, 398, 404, 434], [80, 73, 70, 72, 95, 98])
    leg_far = alpha & (xx <= seam)
    leg_near = alpha & (xx > seam)
    leg_far_thigh = leg_far & (yy >= 258) & (yy <= 336)
    leg_far_shin = leg_far & (yy >= 330) & (yy <= 400)
    leg_far_foot = leg_far & (yy >= 396) & (yy <= 432)
    leg_near_thigh = leg_near & (yy >= 258) & (yy <= 336)
    leg_near_shin = leg_near & (yy >= 330) & (yy <= 400)
    leg_near_foot = leg_near & (yy >= 396) & (yy <= 434)

    # --- torso ------------------------------------------------------------
    # The near arm and the stick band both come out, leaving one contiguous
    # hole down the chest. It is patched rather than left transparent because
    # the arm swings a few degrees over it.
    stick_hole = (dist <= 9.0) & (yy >= 96) & (yy <= 232)
    torso_keep = (
        alpha & (yy >= 84) & (yy <= 278)
        & ~head & ~bag & ~arm_upper & ~arm_lower & ~stick_hole
    )
    torso_all = alpha & (yy >= 84) & (yy <= 278) & ~head & ~bag
    hole = torso_all & ~torso_keep
    filled = fill_holes(rgba, torso_keep, hole)
    torso = torso_keep | hole
    filled[..., 3] = np.where(torso, 255, 0)

    # --- stick -------------------------------------------------------------
    band = synth_stick(rgba, dist, t)
    stick = band[..., 3] > 0

    parts: dict = {}
    save_part("head", rgba, head, parts)
    save_part("torso", filled, torso, parts)
    save_part("arm_upper", rgba, arm_upper, parts)
    save_part("arm_lower", rgba, arm_lower, parts)
    inked_far = ink_cut_edge(rgba, leg_far, "right")
    inked_near = ink_cut_edge(rgba, leg_near, "left")
    save_part("leg_far_thigh", inked_far, leg_far_thigh, parts)
    save_part("leg_far_shin", inked_far, leg_far_shin, parts)
    save_part("leg_far_foot", inked_far, leg_far_foot, parts)
    save_part("leg_near_thigh", inked_near, leg_near_thigh, parts)
    save_part("leg_near_shin", inked_near, leg_near_shin, parts)
    save_part("leg_near_foot", inked_near, leg_near_foot, parts)
    save_part("bag", rgba, bag, parts)
    save_part("stick", band, stick, parts)

    meta = {
        "source": "art/game-ready-sprites-v1/frames/fool/directions/east.png",
        "crop": list(CROP),
        "crop_size": [W, H],
        "origin": list(ORIGIN),
        "figure_height_px": 434,
        "note": "spike-quality cutout parts; see docs in tools/spike/segment_fool_east.py",
        "parts": parts,
    }
    with open(os.path.join(OUT, "parts.json"), "w") as handle:
        json.dump(meta, handle, indent=2)
    for name, part in parts.items():
        print("%-11s size=%-9s origin=%-10s pivot=%s" % (
            name, tuple(part["size"]), tuple(part["origin"]), tuple(part["pivot"])
        ))


if __name__ == "__main__":
    main()
