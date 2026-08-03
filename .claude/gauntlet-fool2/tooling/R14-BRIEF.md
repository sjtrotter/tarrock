# Round 14 — HEAD SCULPT (final brief; supersedes R14-HEAD-BRIEF-DRAFT.md)

Lead, 2026-08-03. Pass-2 closed by director ruling (issue #2, Option A — belt /
front garment line / arm relief are logged debts). The head-sculpt stage begins.
Chain head: `Fool-v2-016.blend` (992,787 v, watertight, silhouette twice-
certified). Workdir: `/home/betty/tarrock-gauntlet-work/fool2-r14/` (namespaced —
plain `r14/` belongs to the OTHER gauntlet session; never touch it).

## Executor plan (lead decision, R13 escalation lesson applied at kickoff)
- **Phase A (Codex, headless lane):** tooling + measurements — TASK-A-HEAD.md.
- **Phase B (Opus builder, Claude subagent):** the sculpt itself. The head is
  brand-new-feature placement work (nose, ears, sockets, mouth) — exactly the
  class where two Codex failures cost more than one Opus round.
- **Critique:** Fable-lead validation + Codex CLI blind judge at stage close
  (tier rule for Opus-built pieces).

## Phase B scope (priority order; honest partials beat silent overreach)
1. **Skull primary forms:** cranium to the drawn SKULL line (front + side),
   occipital, forehead/brow plane (use Phase A's measured brow numbers, not
   r4's stale "+9 mm"), temporal planes, cheekbone masses, jaw/mandible line,
   chin. Kill the r12 jaw/head horizontal band artifact. Neck integration.
   Manubrium band z ≥ 1.32 ~15 mm proud (carried from R9) — this round owns it.
2. **Eyes (director ruling, rig-ready):** OPEN sockets with eyelid rims;
   separate eyeball objects `Fool_Eye_L` / `Fool_Eye_R` — UV spheres r = 35 mm,
   centers (±0.043, Y from `eyeball_spec.json`, 1.571), origins AT the sphere
   centers (future per-eye bones rotate them), smooth-shaded, NOT joined to the
   body. Sockets must clear the spheres (~2 mm radial suggested) so they can
   rotate.
3. **Nose:** bridge/tip/base per `head_sheet.json`; stylized-simple (a hint of
   nostril, no interior drilling).
4. **Ears:** side-view position/extent per sheet; simple storybook form —
   remember the prior run died of "gnarled and gross" over-detail.
5. **Mouth:** lip band per sheet row/width; philtrum = simple hint or absent.

## Style bar (the blind judge scores this)
40% Fable (original trilogy) / 20% Kells–Wolfwalkers / 15% Kena / 10% Dishonored
/ 10% illustrated fairy tales / 5% Ghibli. Stylized-simple WINS over
anatomical-correct. Big-eye proportions are per the sheet (aperture ≈ 58 mm).
`Fool-Expressions.png` (~/Downloads) is character reference only — the base
head is NEUTRAL. v7 sheet wins all conflicts with older sheets.

## Method constraints (paid-for, binding)
- Read first: `docs/design/character-modeling-pipeline.md`,
  `docs/design/character-sculpt-reference.md` (§2/§3; halve its lengths — that
  doc was written for a 0.5 m/unit file), ROUND-STATE.md "Method lessons".
- Large forms in SLOPE space with bounded curvature (esclib pattern); no
  plateau displacement; C1 falloffs only; Gaussian-only blurs; recalibrate
  sigmas to face scale — do not copy torso constants.
- Features (sockets, nose, ears) may use local bmesh/boolean/masked-remesh
  construction — displacement fields alone cannot make an ear. Global remesh
  discouraged (992k verts); if local remesh is needed, mask it to the head.
- Symmetry X EXACT for all head features (no navel-style asymmetry at this
  style level).
- MANDATORY eyes-on iteration: after every build cycle, render with
  `head_render.py` (studio + rake) and LOOK before proceeding — R13's core
  lesson; render-RMS scalars are retired as gates.
- Save every candidate as a NEW numbered file in the workdir
  (`Fool-v2-017.blend`, `017b`, …). Before sculpting, duplicate
  `Fool_SculptBase` to hidden backup `Fool_SculptBase_prehead` in-file.
  NEVER write to the project repo or the chain in `docs/`.

## Gates (geometry-space + eyes-on; report real numbers)
- FREEZE: below z = 1.30 the mesh matches 016 exactly (max |Δ| ≤ 0.1 mm via
  stations_016.json + vertex-delta check). z 1.30–1.45 (neck/manubrium): ±3 mm
  vs the sheet-certified 016 stations, manubrium correction allowed inside it.
- BUILD TARGET z ≥ 1.45: drawn head contours (`head_stations_sheet.json`)
  within ±3 mm at contour rows the sheet actually constrains; ear/nose rows are
  ADDITIVE (016 has neither — growing to the drawn line is the job).
- Crown Z 1.717 ± 1 mm; webbing probes 160/160; body stays ONE manifold
  watertight component after socket cuts; eyeballs = two separate closed
  spheres; all in-file backups intact.
- Presence: head reads as the sheet's character in the rake renders — builder
  self-judges honestly, lead + Codex judge at close.

## Blender lane / machine protocol
One Blender lane (headless; GUI holds the chain for the director — never save
from it). Governor slots before every batch; PAUSE = poll 15 s. Load < 6,
pkg temp < 90 °C before heavy ops.
