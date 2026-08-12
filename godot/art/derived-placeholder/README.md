# Derived placeholder art

**Everything in this folder is an explicit placeholder.** It is not authored art and
it is not part of `game-ready-sprites-v1/`. Each file here was derived mechanically
from the sprite pack so a system could be built and seen before the real art exists.
Replace it, do not extend it — the matching requests are in
[`../ART-REQUESTS.md`](../ART-REQUESTS.md).

| File | What it is | Replaced by |
|---|---|---|
| `tall-grass-tuft-0.png` | Placeholder tall-grass tuft, dense | ART-REQUESTS item (c) |
| `tall-grass-tuft-1.png` | Placeholder tall-grass tuft, sparse/short | ART-REQUESTS item (c) |
| `tall-grass-tuft-2.png` | Placeholder tall-grass tuft, tall/full | ART-REQUESTS item (c) |

## Tall-grass tufts

- 192×256 PNG RGBA, straight alpha.
- Root (pivot) at pixel **(96, 250)** — `Sprite2D.offset = Vector2(0, -122)` puts that
  root on the node origin so rotation pivots at the base of the blades. Replacement
  art must keep the same cell size and root pixel, or `grass_field.gd`'s
  `TUFT_ANCHOR` has to be re-measured.
- Blades are drawn with a palette sampled from `meadow-*.png` (opaque, green-dominant
  pixels only) so the placeholder sits in the same colour world as the ground.
- Regenerate with `python3 make_tufts.py` (needs numpy + Pillow). The script is kept
  so the placeholder is reproducible, not because it is a pipeline.
