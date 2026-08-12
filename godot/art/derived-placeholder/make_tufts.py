"""Derive PLACEHOLDER tall-grass tuft sprites from the existing meadow art palette.

Explicitly a placeholder: real painted tufts are on the ART-REQUESTS list.
Palette + texture grain are sampled from meadow-*.png so the tufts sit in the
same colour world as the ground they grow out of.
"""
import numpy as np
from PIL import Image
import os

SRC = "/home/betty/Projects/tarrock/godot/art/game-ready-sprites-v1/frames/environment/terrain"
OUT = "/home/betty/Projects/tarrock/godot/art/derived-placeholder"
os.makedirs(OUT, exist_ok=True)

W, H = 192, 256
BASE_Y = 250.0
SS = 3  # supersample

# --- palette sampled from the meadow tiles -----------------------------------
pix = []
for i in range(4):
    a = np.array(Image.open(f"{SRC}/meadow-{i}.png").convert("RGBA"))
    op = a.reshape(-1, 4)
    op = op[op[:, 3] > 250][:, :3].astype(float)
    pix.append(op)
pix = np.concatenate(pix)
# green-dominant subset = the blades rather than the stones/flowers
green = pix[(pix[:, 1] >= pix[:, 2] + 20) & (pix[:, 1] >= pix[:, 0] - 10)]
lum = green.mean(axis=1)
DARK = np.percentile(green[lum < np.percentile(lum, 35)], 50, axis=0)
MID = np.percentile(green, 55, axis=0)
LIGHT = np.percentile(green[lum > np.percentile(lum, 80)], 60, axis=0)
print("palette dark", DARK.round(0), "mid", MID.round(0), "light", LIGHT.round(0))


def blade(rgb, alpha, rng, base_x, height, lean_px, width, hue_shift):
    steps = int(height * SS * 1.4)
    for s in range(steps):
        t = s / float(steps - 1)
        x = base_x + lean_px * (t ** 1.7) + rng.normal(0, 0.25)
        y = BASE_Y - height * t
        w = max(0.6, width * (1.0 - 0.92 * t))
        # colour: dark at the root, light at the tip
        c = (DARK * 0.62) * (1.0 - t) + (LIGHT * 1.32) * t
        c = np.clip(c * (0.78 + 0.44 * hue_shift), 0, 255)
        _disc(rgb, alpha, x * SS, y * SS, w * SS, c)


def _disc(rgb, alpha, cx, cy, r, colour):
    x0, x1 = int(cx - r - 1), int(cx + r + 2)
    y0, y1 = int(cy - r - 1), int(cy + r + 2)
    x0, y0 = max(x0, 0), max(y0, 0)
    x1, y1 = min(x1, W * SS), min(y1, H * SS)
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    m = d <= r
    if not m.any():
        return
    sub_a = alpha[y0:y1, x0:x1]
    sub_c = rgb[y0:y1, x0:x1]
    sub_c[m] = colour
    sub_a[m] = 1.0


def make_tuft(seed, blades, lean_px, scale_h):
    rng = np.random.default_rng(seed)
    rgb = np.zeros((H * SS, W * SS, 3))
    alpha = np.zeros((H * SS, W * SS))

    # soft root shadow: a feathered ellipse where the tuft meets the ground
    yy, xx = np.mgrid[0:H * SS, 0:W * SS]
    rx, ry = 52.0 * SS * scale_h, 13.0 * SS
    d = np.sqrt(((xx - 96 * SS) / rx) ** 2 + ((yy - (BASE_Y - 4) * SS) / ry) ** 2)
    shadow = np.clip(1.0 - d, 0.0, 1.0) ** 0.7
    alpha = np.maximum(alpha, shadow * 0.72)
    rgb[shadow > 0] = DARK * 0.62

    order = sorted(
        (rng.uniform(0.32, 1.0) ** 0.72 * 210 * scale_h for _ in range(blades)),
        reverse=True,
    )
    for h in order:
        bx = 96 + rng.normal(0, 20)
        lean = lean_px * rng.uniform(-0.45, 1.45) * (h / 210.0)
        blade(rgb, alpha, rng, bx, h, lean, rng.uniform(4.0, 9.0), rng.random())

    img = np.dstack([rgb, alpha * 255.0]).astype(np.uint8)
    im = Image.fromarray(img, "RGBA").resize((W, H), Image.LANCZOS)
    return im


# (name, seed, blade count, lean px, height scale) - explicit seeds so the
# placeholder regenerates byte-identically.
VARIANTS = [
    ("tall-grass-tuft-0", 7401, 46, 26.0, 1.0),
    ("tall-grass-tuft-1", 7402, 34, 21.0, 0.82),
    ("tall-grass-tuft-2", 7403, 58, 31.0, 1.12),
]
for name, seed, blades, lean, sh in VARIANTS:
    im = make_tuft(seed, blades, lean, sh)
    im.save(f"{OUT}/{name}.png")
    a = np.array(im)[:, :, 3]
    ys, xs = np.nonzero(a > 24)
    print(name, im.size, "bbox", xs.min(), ys.min(), xs.max(), ys.max())

# contact sheet on a grass-coloured ground for review
sheet = Image.new("RGBA", (W * 3, H), tuple(int(v) for v in MID) + (255,))
for i, (name, *_rest) in enumerate(VARIANTS):
    sheet.alpha_composite(Image.open(f"{OUT}/{name}.png"), (i * W, 0))
sheet.save("/tmp/claude-1000/-home-betty-Projects-tarrock/c09ffe84-7f03-4059-a66b-6f3d9ae6015d/scratchpad/tufts-sheet.png")
print("sheet written")
