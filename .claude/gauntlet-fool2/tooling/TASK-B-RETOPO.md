# Round 15 — Phase B: retopo face loops + surface finish (Opus builder)

Binding: `R15-BRIEF.md` (gates, loop spec, style bar), this file, and in the
workdir `/home/betty/tarrock-gauntlet-work/fool2-r15/`: `REPORT-A2.md` +
`r15-a2-validation.json` (the scaffold's honest state), `DONOR-REPORT.md`.
START FROM `Fool-v2-019a.blend` (object `Fool_HeadRetopo_draft`, 99.35% quad,
X-symmetric, RMS 0.36 mm vs sculpt). Chain source read-only:
`docs/design/3d-models-inwork/Fool-v2-018.blend`. Candidates
`Fool-v2-019b.blend` onward, workdir only. Headless lane only (GUI closed,
no port 9876), one Blender at a time, governor slots before every run
(PAUSE → 15 s), loadavg < 6, temp < 90 °C.

## Owned defects (from A2 + lead rulings)
1. **Eye apertures:** donor lids are CLOSED and frozen at donor positions.
   Rebuild as OPEN almond apertures per the drawn eye (aperture X 22–79 mm,
   Z 1.544–1.590; upper-lid edge is THE dominant line; lower lid restrained);
   lid rims clear the r=35 mm globes at (±43, −40.3, 1571) for rotation
   (≥ ~1.3 mm; sockets close around the globes, eyes stay separate objects).
   **LEAD RULING (recorded):** the ORBITAL region builds forward/outward to
   the drawn front width at eye rows — the drawing is broad at eye height;
   the face wedge applies below the cheekbone. This ruling resolves the
   globe-vs-face conflict the sculpt could not.
2. **Mouth ring:** donor corners are single-exit poles — rebuild with
   concentric rings and ≥2 loops exiting each corner; one crisp gentle-smile
   line ~64 mm at Z 1.495 per the sculpt/sheet.
3. **Ear region:** wrap-stretched. Retopo the sculpt's ears with SIMPLE
   storybook loops (helix + concha only); silhouette |X| ≈ 115.
4. **Max-deviation sites:** cranium 9.95 mm, face 6.19 mm — locate, fix or
   justify (a deliberate divergence must be named + rendered; the z ≈ 1.51
   sculpt terrace must NOT be reproduced — smooth topology through it).
5. **Neck seam:** clean the seam ring drape; propose the final seam loop.
6. **Pole hygiene:** 29 poles within 2 rings of the feature masks — none may
   sit at mouth corners or inner eye corners; census in the report.

## Gates (R15-BRIEF.md, measured on the SAVED final file)
Deviation vs sculpt ≤1.5 mm RMS / ≤3 mm max over the head EXCLUDING named
deliberate divergences (each rendered); quads ≥95%; exact X symmetry; full
eye + mouth encirclement; lid-globe clearance stated; head cleanly bounded at
the neck seam; tri count reported vs the 4–8k working budget.

## Loop (every cycle)
Edit → wireframe-over-shaded renders (front/side/three-quarter, reuse A2
camera framing) + plan sections at the five heights → LOOK → next. The face
must READ as the sheet's character in shaded views — the retopo owns the
R14 eye/mouth read debts; subdivision-preview renders (Subsurf 1) are allowed
and welcome as evidence.

## Deliverables
Final candidate letter; renders; `REPORT-B-RETOPO.md` (≤120 lines: per-defect
verdict, gate numbers, look-log, deliberate divergences, honest misses);
`r15-b-validation.json`. False passes cost a round; honest partials don't.
