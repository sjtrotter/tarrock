# Art requests — the Cliff (2D prototype)

Executable generation briefs for the director's Codex art session. Everything here is
a **gap found while building `scenes/the_cliff.tscn`**; each item says exactly what to
produce, where to put it, and what it will be checked against.

Existing pack: `game-ready-sprites-v1/` (`manifest.json` is authoritative for format).
Style anchors are always *existing files by path* — match them, do not reinterpret.

## Harness note — Codex can generate images

Probed 2026-08-11: `codex exec` reports `IMAGEGEN: YES image_gen.imagegen` and it is
real. Sample output (one north-west Fool walk cycle) is committed at
`codex-probe/` — 1280×320 sheet plus four 320×320 slices, correct dimensions, straight
alpha, transparent background, character identity close to reference.

**The sample is NOT accepted and is NOT wired into the game.** Verdict: usable
identity and style, but the cycle's motion amplitude is roughly half the existing
south-east cycle's (mean frame-to-frame delta 7.7 vs 24.7) and frames 3→0 are nearly
duplicates, so it reads as a shuffle rather than a walk. Requests below state motion
amplitude explicitly to fix that.

## Global acceptance criteria (all items)

1. PNG RGBA, **straight alpha**, fully transparent background — no chroma key, no
   matte, no checkerboard.
2. Exact pixel dimensions as stated. Sheets must slice cleanly on the stated grid.
3. **Anchor discipline** — this is the one that keeps breaking. For every character
   frame in a cycle:
   - lowest opaque pixel (the planted foot) at cell y = **306 ± 4**;
   - alpha centroid x at cell x = **160 ± 6** (the existing south-east Fool cycle
     drifts 56 px across four frames and has to be corrected in code — do not repeat
     it);
   - figure height (opaque bbox) **285–300 px** for the Fool, **205–220 px** for Pip.
4. Deliver both the sheet **and** the sliced frames, at the paths given.
5. Verify before reporting: open each file, assert dimensions, assert alpha is not
   all-opaque, print the per-frame opaque bbox.

---

## (a) Fool walk cycles — remaining 7 directions

Reference identity + facing: `game-ready-sprites-v1/frames/fool/directions/<direction>.png`
Reference style, framing, scale, motion: `game-ready-sprites-v1/frames/fool/actions/walk-0.png` … `walk-3.png`

- Directions: `south`, `southwest`, `west`, `northwest`, `north`, `northeast`, `east`
  (south-east already exists).
- One sheet per direction: **1280×320**, four **320×320** cells in a single row.
- Frame order: contact → passing → contact (opposite leg) → passing. Frames 0 and 2
  must be mirrored-stride poses, not near-duplicates.
- Motion amplitude: mean absolute pixel delta between consecutive frames ≥ 18 (the
  existing south-east cycle averages 24.7).
- Sheets → `game-ready-sprites-v1/atlases/fool-walk-<direction>.png`
- Frames → `game-ready-sprites-v1/frames/fool/actions/walk-<direction>-0.png` … `-3.png`
- Playback will be 8 fps, looping (matches `manifest.json` → `characters.fool.rows[walk]`).

## (b) Pip cycles — at least 4 directions

Reference identity + facing: `game-ready-sprites-v1/frames/pip/directions/<direction>.png`
Reference style/scale/motion: `game-ready-sprites-v1/frames/pip/actions/trot-0.png` … `trot-3.png`
and `idle-0.png` … `idle-3.png`

- Directions, in priority order: `south`, `west`, `north`, `east` (south-east exists).
- Two cycles per direction: **trot** (10 fps, loop) and **idle** (4 fps, loop).
- One sheet per cycle: **1280×320**, four **320×320** cells in a single row.
- Sheets → `game-ready-sprites-v1/atlases/pip-<cycle>-<direction>.png`
- Frames → `game-ready-sprites-v1/frames/pip/actions/<cycle>-<direction>-0.png` … `-3.png`
- Pip's idle must be an *in-place* cycle (breath/ear flick). The existing south-east
  idle translates across the cell — do not copy that behaviour.

## (c) Tall-grass tufts — replaces a placeholder in use today

Currently faked: `derived-placeholder/tall-grass-tuft-{0,1,2}.png`, generated from the
meadow palette. Real art replaces them 1:1.

- One sheet: **1280×1280**, 4×4 grid of **320×320** cells
  → `game-ready-sprites-v1/atlases/cliff-tallgrass.png`
- Row 0: **4 upright tuft variants** — short/sparse, medium, tall/full, mixed with
  seed heads. Row 1 (optional but wanted): the same 4 tufts **leaned ~25° to the
  right**, for a cheap swap under heavy displacement.
- Root pixel (the pivot the blades rotate about) at cell **(160, 300)** in every cell;
  blades may reach up to y = 40. Nothing painted below y = 302.
- Include a soft contact shadow at the root so the tuft sits *in* the ground.
- Style/palette anchor: `game-ready-sprites-v1/frames/environment/terrain/meadow-1.png`
  and `meadow-3.png`. Same brush language, same three-quarter viewing angle — these
  stand up out of ground that is painted from above at an angle, so blades foreshorten.
- Frames → `game-ready-sprites-v1/frames/environment/terrain/tall-grass-<n>.png` and
  `tall-grass-leaned-<n>.png`, n = 0…3.
- Note for whoever wires it: `scripts/grass_field.gd` `TUFT_ANCHOR` must be
  re-measured when the cell size changes from the placeholder's 192×256.

## (d) Terrain variety — gaps found composing the island

The pack's 16 terrain tiles cover meadow, path and cliff. These are the tiles the
composition wanted and could not have. Same format as the existing terrain atlas:
**1280×1280**, 4×4 grid of **320×320** cells, organic blob silhouettes, style anchor
`game-ready-sprites-v1/atlases/cliff-terrain.png`.

New sheet → `game-ready-sprites-v1/atlases/cliff-terrain-2.png`, cells in this order:

| Cell | Tile | Why |
|---|---|---|
| 0–1 | `bare-earth-0/1` | Trodden dirt with **no dug pit**. Today the only bare ground is `detail-disturbed-earth`, whose pit repeats visibly wherever worn ground is wanted. |
| 2–3 | `scree-0/1` | Loose rock field, denser than `detail-stones`, for the wind-scoured rim. |
| 4–5 | `meadow-dry-0/1` | Bleached, thin, wind-burnt grass. Currently faked by tinting `meadow-*` toward straw. |
| 6–7 | `meadow-dead-0/1` | Grey-brown dead grass for the dead tree's shade. Currently faked with a grey modulate. |
| 8–10 | `edge-grass-to-dirt`, `edge-grass-to-rock`, `edge-grass-to-scree` | Transition blobs. Nothing in the pack blends one ground type into another; zones currently butt up against each other. |
| 11 | `path-end-cap` | The path stops dead at the leap point and at the spawn. |
| 12 | `path-tee` | Only horizontal/vertical/bend/crossroads exist. |
| 13–15 | `meadow-4/5/6` | Three more meadow variants. Four blobs across ~565 placed tiles is visibly repetitive at any zoom-out. |

Also wanted, separately (different format):

- **A seamless, tileable grass fill**, 512×512, wrapping on all four edges
  → `game-ready-sprites-v1/atlases/meadow-tileable.png`. The island's base layer is
  currently a flat colour under blob art; a real fill would let the blobs be detail
  instead of load-bearing coverage.

## (e) Cliff rim facings — known gap

Today `cliff-north.png` is reused for the **south** rim (a north-facing rock wall drawn
on the island's southern edge) and `cliff-east.png` is mirrored for the **west** rim.
`cliff-outside-corner.png` and `cliff-inside-corner.png` are unused because their
facing is ambiguous.

- One sheet: **1280×1280**, 4×4 grid of **320×320** cells
  → `game-ready-sprites-v1/atlases/cliff-rim.png`
- Style anchor: `game-ready-sprites-v1/frames/environment/terrain/cliff-north.png`
  (grass cap on top, columnar basalt face below).
- Cells:

| Cell | Tile | Notes |
|---|---|---|
| 0 | `cliff-south` | Viewer sees the grass cap and only a sliver of face — the far edge of the island. |
| 1 | `cliff-west` | Face lit from the opposite side to `cliff-east`, not a mirror of it. |
| 2 | `cliff-southeast` / 3 `cliff-southwest` | Diagonal runs; the island polygon is a 19-gon and most edges are diagonal. |
| 4–7 | `corner-outside-{ne,se,sw,nw}` | Explicit facings, so corners stop being unusable. |
| 8–11 | `corner-inside-{ne,se,sw,nw}` | As above. |
| 12–15 | `cliff-north-var-{0,1}`, `cliff-east-var-{0,1}` | Variants; the rim ring currently repeats one tile ~90 times. |

- Every rim tile: grass cap opaque along the top edge so it seals against the ground
  layer, rock face may fade to transparent at the bottom.

---

## (f) Fool rig cutout parts — status

`feat/anim-spike` shipped a Skeleton2D cutout rig built from parts SLICED out of the
painted stills (`tools/spike/segment_fool_east.py`, `segment_fool_south.py`) — quick
enough to test the rigging idea, too crude to judge on art quality (a fake far arm
tinted from the near arm's silhouette, no far leg art, hard cut-line seams at the
knee). `feat/anim-parts` replaces those with PURPOSE-DRAWN parts generated and iterated
against the reference stills via Codex, then integrated back into the rig.

**Done — rigged and shipping in the spike:**

- **east** (profile, 15→14-bone rig) — `art/spike/fool-cutout/parts.json`. Purpose-drawn
  far arm (`arm_far_upper`/`arm_far_lower`, was faked in the spike) with real
  counter-swing animation; near/far knee-cap overlay pieces
  (`knee_cap_near`/`knee_cap_far`) hide the thigh/shin seam; shin+boot fused into one
  rigid part (the separate ankle-roll bone from the spike is gone — a named
  simplification, see the anim-parts report). 2 Codex rounds (round 1 had a torso
  armhole rendering as a dark void instead of cream undershirt fabric; fixed with a
  targeted single-cell re-prompt).
- **south** (front, 13→19-bone rig) — `art/spike/fool-cutout-south/parts.json`. Legs and
  arms are now two bones each (thigh/shin, upper/lower) instead of one fused image, plus
  knee-cap overlays and the existing 3-position boot swap library
  (`foot_<side>`/`foot_<side>_lift`/`foot_<side>_fwd`) re-pointed at new art. 2 Codex
  rounds (round 1 had an unwanted diagonal bandolier strap across the tunic not present
  in the reference; fixed with a targeted single-cell re-prompt).
- Both facings pass `tests/spike_rig_test.gd` and re-captured GIF evidence
  (`tools/spike/capture_spike.gd` layouts `rig_walk`, `rig_idle`, `rig_south_walk`,
  `rig_south_idle`, `rig_walk_gamesize`, `rig_south_gamesize`, `facings`) with no cut-line
  artifacts, no knee bulge, and a real far arm.
- **Placement is baked, not inferred.** The rig-ready art under
  `art/spike/fool-cutout{,-south}/` is generated from the untouched Codex drawings in
  `art/spike/fool-cutout-src/<facing>/` by `tools/spike/build_cutout_parts.py`, which
  carries the measured per-part transform onto the direction still. Edit placement
  there and re-run it; do NOT re-run `tools/spike/segment_fool_{east,south}.py`, which
  still writes the original hand-sliced spike art into the same folders. A rest-pose
  silhouette-IoU gate in `tests/spike_rig_test.gd` (>= 0.88 against the still, currently
  0.944 east / 0.919 south) fails if any attachment moves.
- The `art/fool-parts-v1/{east,south}/` copies of these two facings are the earlier,
  wrongly-rescaled export and their `manifest.json` pivots are unreliable; the rigs no
  longer read them. Treat `fool-cutout-src/` as the source of truth for east and south.

**Done — production stock, not yet rigged:**

- **southeast**, **northeast**, **north** part sheets, 1 Codex round each (no re-prompt
  needed — the armhole/strap lessons from east and south round 1 carried forward and
  the first attempt passed clean review) → `art/fool-parts-v1/<facing>/*.png` +
  `art/fool-parts-v1/manifest.json` (part → file, pivot, z-order, facing). southeast/
  northeast follow the east profile's 14-part list (near/far arm + leg + knee caps,
  stick, bag); north follows south's 20-part list (left/right arm + leg + knee caps,
  stick, bag, 3-position boot swap library) since it is a symmetric bilateral view like
  south, just from behind. Pivots for these three are ESTIMATED (borrowed fraction from
  the sibling rigged facing's equivalent joint) — verify by eye before wiring a rig to
  them, per the note in `manifest.json`.

**Still missing:**

- **west**, **northwest**, **southwest** part sheets — not generated this round.
  Mirroring east/southeast/northeast horizontally is the cheap path (the reference
  stills themselves look like true mirrors — worth confirming before assuming the art
  can be flipped rather than redrawn) rather than a fresh Codex pass.
- Rigs for southeast/northeast/north: no Skeleton2D built yet, no walk/idle animation
  authored, no GIF evidence. The east and south rigs are the director's decision
  evidence for whether the cutout approach ships at all; the diagonal and back facings
  were explicitly loop-only production stock for this round, gated on that decision.
- The knee-cap pieces on `north` read visually flatter/more geometric (a plain rounded
  puck) than the ones on east/south/southeast/northeast (fabric folds, shading) — a
  minor style-consistency gap worth a touch-up pass before `north` ships.

---

## Open naming decision

The existing south-east cycles are named without a direction
(`frames/fool/actions/walk-0.png`, `frames/pip/actions/trot-0.png`). New directions use
`walk-<direction>-<n>.png`. When (a) and (b) land, the south-east sets should be
renamed to match (`walk-southeast-0.png`, …) — a one-line change to the tables in
`scripts/player.gd` and `scripts/pip_follower.gd`. Director's call whether to rename.
