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

---

## Enemies (round 8 of the systems gauntlet) — the Blanks

Everything below is a **gap found while building `systems/enemies/`** — the Blanks, the
encounters and the two other enemy families. The systems half is finished and tested;
each item here is a place where the game is running on a stopgap and says so in code.
Canon is [`docs/design/combat.md`](../../docs/design/combat.md) §Enemies: the Blanks,
§Encounter philosophy and §Other enemy families; the gap list these expand is the table
in [`godot/systems/enemies/README.md`](../systems/enemies/README.md) §Art requests.

The **Global acceptance criteria** above apply, with the anchor rule read against this
family's own cells rather than the Fool's (see the per-item numbers).

Existing pack, and the one Blank that ships:

- Directions: `game-ready-sprites-v1/atlases/blank-sword-two-directions.png` —
  **1536×1024**, 4×2 grid of **384×512** cells, order `south, southwest, west,
  northwest, north, northeast, east, southeast`; sliced to
  `frames/blank_sword_two/directions/<direction>.png`.
- Actions: `game-ready-sprites-v1/atlases/blank-sword-two-actions.png` — **1280×1280**,
  4×4 grid of **320×320** cells, row-major, rows `walk` (4 frames, 7 fps, loop),
  `attack` (4, 9 fps), `hit` (4, 8 fps), `defeat` (4, 7 fps); sliced to
  `frames/blank_sword_two/actions/<row>-<n>.png`. **South-east facing only.**
- `manifest.json` is authoritative for the pack format; add a row/character there for
  anything new.

`combat.md`: "One base art and animation family carries every suit and rank." So every
item below is **one body** re-dressed, never a new character — the systems side already
assumes it (`BlankSprites` is one animation table for all 52 Blank definitions).

Pivots for anything delivered: measure them with
`python3 godot/tools/measure_sprite_pivots.py --family <name>` and paste the tables it
prints, exactly as `blank_sprites.gd` did. Do not eyeball an offset.

### (g) Cups, Wands and Coins Blank sheets — a stopgap is shipping today

Reference identity, framing, scale: `game-ready-sprites-v1/frames/blank_sword_two/directions/*.png`
Reference action style: `game-ready-sprites-v1/frames/blank_sword_two/actions/*.png`

Today all four suits are the Swords sheet **tinted** from `EnemyRules.suit_tints`
(`data/enemies/enemy_rules.tres`), which is named in that resource's own notes as a
stopgap. Three suits are missing.

- One direction sheet per suit — **1536×1024**, 4×2 grid of **384×512** cells, same
  eight-facing order as the Swords sheet
  → `game-ready-sprites-v1/atlases/blank-<suit>-two-directions.png`, sliced to
  `frames/blank_<suit>_two/directions/<direction>.png`, suit ∈ `cups`, `wands`, `coins`.
- One action sheet per suit — **1280×1280**, 4×4 of **320×320**, rows in the same order
  and at the same fps as the Swords sheet (`walk` 7, `attack` 9, `hit` 8, `defeat` 7)
  → `game-ready-sprites-v1/atlases/blank-<suit>-two-actions.png`, sliced to
  `frames/blank_<suit>_two/actions/<row>-<n>.png`.
- **Same body, same blank oval face, same tabard.** What changes is the implement and
  one suit mark: Cups a lobbed vessel (the throw is what the attack row shows), Wands a
  polearm (the reach must read — it out-reaches every other melee suit in the rules),
  Coins a heavy shield carried high and forward.
- The Coins attack row must show the **shield dropping** as the swing goes out: the
  system really lowers it for the attack and its recovery, and that window is the
  answer the player is offered (`combat.md`: "built to be broken through rather than
  out-traded").
- Anchors, per cell: lowest opaque pixel and centroid consistent within ±4 px / ±6 px
  across a row, as for the Fool. Figure height to match the Swords sheet's (direction
  cells average 456 px of opaque bbox; action cells 274 px on the walk row) so the
  measured scales in `blank_sprites.gd` stay comparable.
- Acceptance: the four suits must be tellable apart in a single frame **with tinting
  turned off**. That is the test — the tint goes away the day these land.

### (h) The printed number on the tabard

`combat.md`: "the printed number on the Blank's back is a simple visual tell of
toughness — a Two folds fast, a Ten is a real fight." Nothing draws it. The rules
already make the number mean something (`rank_health_base` + `rank_health_per_pip`), so
this is the only place a player can read it.

- Deliver as a **separate overlay sheet**, not baked into the body: one 4×4 grid of
  **320×320** cells → `game-ready-sprites-v1/atlases/blank-numbers.png`, cells `2`…`10`
  in order, then `P`, `Kn`, `Q`, `K` for the court, then one empty cell.
- Painted as cloth on the tabard — inked numeral, slight weave distortion, no flat
  vector glyph — for the south-east facing first; the same overlay is reused on the
  other facings as (j) lands.
- Legibility is the acceptance test: readable at the game's rendered size (a Blank
  stands ~122 px tall on screen) at 100% zoom, not only at 1:1 on the sheet.

### (i) Page, Knight, Queen and King silhouettes

`combat.md`'s Role table, as four bodies on the one family:

| Rank | Must read as | Systems fact it has to match |
|---|---|---|
| Page | A scout: light, unarmoured, already running | It is the fastest thing in the roster and **never attacks** — no attack row is used, so do not draw one |
| Knight | A duelist: the rank where suit identity is sharpest | It telegraphs fastest of the court |
| Queen | A commander: still, upright, holding ground | She buffs allies and **summons nothing** — no conjuring pose |
| King | A set piece: bigger, heavier, deliberately slow | Tougher than any pip rank; its telegraph is the longest |

- One direction sheet per rank, format exactly as (g)
  → `game-ready-sprites-v1/atlases/blank-court-<rank>-directions.png`, sliced to
  `frames/blank_court_<rank>/directions/<direction>.png`.
- Action rows for the Knight, Queen and King as (g); the Page needs `walk`, `hit` and
  `defeat` only, plus the flee-specific note below.
- The Page's `walk` row is really a **run** — it is the rank's whole behaviour
  (`flees to alert others rather than engaging directly`), and it plays at the Page's
  higher move speed, so the stride has to carry it.
- The Queen wants an aura tell the ally can see: a held stance plus a ground ring or
  banner glow is fine as a separate 4-frame looping overlay
  → `frames/blank_court_queen/actions/aura-<n>.png`, 320×320, 6 fps, loop.

### (j) The seven other action facings

Same gap the Fool has in (a), on the Blank family: action rows exist for **south-east
only**, so seven facings fall back to a static frame while walking.

- Per facing, one action sheet: **1280×1280**, 4×4 of **320×320**, rows `walk`,
  `attack`, `hit`, `defeat` in that order
  → `game-ready-sprites-v1/atlases/blank-<family>-actions-<direction>.png`, sliced to
  `frames/<family>/actions/<row>-<direction>-<n>.png`.
- Directions: `south`, `southwest`, `west`, `northwest`, `north`, `northeast`, `east`.
- Motion amplitude on the walk row: mean absolute pixel delta between consecutive
  frames ≥ 18, and frames 0 and 2 mirrored-stride poses — the same rule (a) states, for
  the same reason.
- Priority order if this is split across sessions: `south`, `southwest`, `east`,
  `west`, then the three northern facings (the Fool fights downhill toward the camera
  far more often than away from it).

### (k) A telegraph pose, `Stagger_Loop` and `Stagger_Recover`

`combat.md` §Encounter philosophy: "Readable telegraphs everywhere, mooks and bosses
alike — an enemy that hits without a tell is a bug, not a difficulty knob." The system
enforces it (`BlankBrain` cannot reach `ATTACK` except through `TELEGRAPH`, and
`EnemyRules.MIN_TELEGRAPH_SECONDS` is a floor under every multiplier) — but today the
attack clip's own first frames stand in for the tell.

- **Telegraph row**, per suit: 4 frames, **320×320**, 8 fps, **not looping**, held on
  the last frame → `frames/<family>/actions/telegraph-<n>.png` plus a
  `telegraph` row in `manifest.json`. The pose must be readable as *this suit's*
  incoming hit at a glance: Coins' wind-up is the slowest and biggest, Swords' the
  quickest and tightest.
- **`Stagger_Loop`**: 2–4 frames, 320×320, 6 fps, **looping** — helpless, off balance,
  no guard. This is the charged heavy's window (`combat.md` §The Bindle: "a brief
  helpless stagger that opens bonus follow-ups"), and it is the one clip that tells the
  player the window is open → `frames/<family>/actions/stagger-<n>.png`.
- **`Stagger_Recover`**: 4 frames, 320×320, 8 fps, not looping — getting the feet back
  → `frames/<family>/actions/stagger-recover-<n>.png`.
- Note for whoever wires it: a staggered **Page** recovers into its run, not into a
  guard — the rank never fights, and `BlankBrain` routes it that way.
- Owed from round 7: `systems/combat/README.md` listed these as "enemy-side states…
  belong to round 8 with the Blanks", which is this item.

### (l) The card fluttering free

`combat.md` §Enemies: "A defeated Blank slumps and fades while the card it bore flutters
free — drifting off to raise a new bearer elsewhere later… a visible,
storybook-melancholy effect." `EnemyService.card_fluttered(definition, from_position)`
fires today and **nothing draws it**. MQ00 stages the pay-off:
[`docs/quests/main/MQ00-the-leap.md`](../../docs/quests/main/MQ00-the-leap.md) — "Past
the ridge line, each drifting card settles onto a new blank-faced figure rising from the
grass."

- One card sprite, face **blank** (that is the whole point of the fiction): **160×224**
  → `game-ready-sprites-v1/frames/effects/blank-card.png`, plus a 4-frame edge-on
  rotation at the same size → `blank-card-turn-<n>.png`, 8 fps, loop.
- A drift cycle is not needed as art — the flight is a curve the code owns — but the
  card must read from both faces and from edge-on, because it turns as it goes.
- Optional and wanted: a 4-frame **settle** (the card touching a new figure), 320×320,
  8 fps, not looping → `frames/effects/card-settle-<n>.png`. MQ00 is the scene that
  needs it.
- Tone check, and it is the acceptance test: mournful, not triumphant. Nothing here is
  a kill — no burst, no shatter, no sting.

### (m) The Cups lob

`Projectile` is a `Hitbox` that travels and **has no sprite at all** today; the flight is
a straight line against the ground plane.

- One thrown vessel: 4-frame tumbling loop, **96×96**, 12 fps, loop
  → `game-ready-sprites-v1/frames/effects/cups-lob-<n>.png`.
- One 4-frame impact, **192×192**, 12 fps, not looping
  → `frames/effects/cups-lob-impact-<n>.png`.
- The **arc is presentation only**: the hit is decided on the ground-plane line, so draw
  a lob that reads as arcing (rise, apex, fall) without the art implying a height the
  hit test does not have. A shadow ellipse that stays on the ground line under the
  vessel is the cheapest way to sell it → `frames/effects/lob-shadow.png`, 64×32.
- Size check: the hit uses `cups_projectile_radius` (48 px today, TBD), so the vessel
  should read at roughly that radius rather than as a thrown pebble.

### (n) Wands' fire — BLOCKED on a design decision, do not draw yet

`combat.md` calls Wands attacks "flame-tagged" and says they "punish standing still",
but no doc says what the flame *does*. `EnemyRules.wands_fire_tag` is carried as data
and nothing reads it. Listed here so it is not mistaken for an oversight: the VFX
request follows the hazard rule, and the hazard rule is a design decision, not an art
one.

---

## Fool combat animation states (round 7)

The moveset built in round 7 (`systems/combat/`) is complete and runs headlessly;
**nothing is wired to a clip yet** — `scripts/player.gd`'s animator keeps doing what it
already does (eight facings, one walk cycle) and `FoolCombat` only tells the body which
way to face. Wiring one clip per state is a one-function change the day the art lands.
This list is transcribed from
[`godot/systems/combat/README.md`](../systems/combat/README.md) §Art requests so it sits
with the rest of the art hand-over; that README stays the owning doc.

Format for every row below, unless it says otherwise: **1280×1280** action sheet, 4×4
grid of **320×320** cells, four frames per row, sliced to
`game-ready-sprites-v1/frames/fool/actions/<clip>-<direction>-<n>.png`, with the anchor
discipline in the Global acceptance criteria. Existing style anchor:
`frames/fool/actions/walk-0.png` … `walk-3.png`.

| State | Clip | Facings | Loops | Notes from canon |
|---|---|---|---|---|
| `LIGHT_1` | `Bindle_Light_1` | 8 | no | Windup / active / recovery must be readable as three beats — `combat.md` §Philosophy. |
| `LIGHT_2` | `Bindle_Light_2` | 8 | no | Reads as a continuation, not a repeat. |
| `LIGHT_3` | `Bindle_Light_3` | 8 | no | The longest recovery in the string: this is where the commitment is felt. |
| `HEAVY` | `Bindle_Heavy_Sweep` | 8 | no | "the bundle end drags through the strike, hitting everything in an arc". |
| `CHARGING` | `Bindle_Charge_Hold` | 8 | **yes** | A held ready pose; needs an obvious "full" tell at `charge_seconds`. |
| `CHARGED_HEAVY` | `Bindle_Launcher` | 8 | no | The stagger launcher — the target is lifted off its feet. |
| `RUNNING_ATTACK` | `Bindle_Lunge` | 8 | no | A forward lunge that closes distance and interrupts. |
| `DODGE_ROLL` | `Dodge_Roll` | 8 | no | The travel dodge, and the Focus forward/neutral dodge. |
| `SIDE_HOP` | `Focus_Side_Hop` | 8 (or L/R × 8 strafe) | no | The Focus left/right strafing hop. |
| `BACKFLIP` | `Grand_Backflip` | 8 | no | "high, deliberately *majestic*… finished with an emphatic landing". Theater as much as evasion. |
| `BLOCK_STEP` | `Block_Step` | 8 | no | A hop-guard, not a shield: the Bindle is held two-handed. |
| `IDLE` in Focus | `Focus_Ready` | 8 | **yes** | The "readable ready-crouch" Focus drops the Fool into. |
| walking in Focus | `Focus_Strafe` | 8 | **yes** | 8-direction strafing that keeps the Fool facing the lock. |
| — (hit reaction) | `Hit_React` | 8 | no | Played on `Combatant.damaged`; short, never a stagger. |
| — (defeat) | `Defeat_Collapse` | 1–8 | no | `combat.md` §Defeat: "stumbles, goes to one knee, and folds down". No ragdoll, no death sting. |
| — (waking) | `Defeat_Rise` | 1–8 | no | The wake-up rise at the Waystation, also named in §Defeat. |
| — (healing) | `Rose_Petal_Heal` | 8 | no | One petal, one fast heal, on a dedicated button (`progression.md`). |
| — (Fool's Chance) | `Fools_Chance_Flourish` | — | no | OPTIONAL: a one-off flourish or VFX on the trigger. The screen-flash/shake toggles for it are the UI round's. |

Priority, if this is split across sessions: `LIGHT_1`–`LIGHT_3` and `DODGE_ROLL` first
(they are what a player does every fight), then `Hit_React`, then the Focus set, then
the rest.
