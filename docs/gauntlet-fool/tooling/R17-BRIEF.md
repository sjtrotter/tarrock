# Round 17 — HEAD POLISH (lead brief)

Lead, 2026-08-04. Director-ordered round (feedback 2026-08-03): the retopo
head must gain (1) NOSE PRESENCE — it currently "reads as lacking a nose";
(2) a stronger LIP/MOUTH read; (3) a better eye APERTURE shape (taller/
rounder toward the drawn almond). Optional item (4): +3–4 mm calf-top outer
width on the body — ONLY if director issue #6 rules "fix" (poll before
building it; skip cleanly if unruled).

Source: chain `Fool-v2-020.blend` (37 MB — may be opened as main file, but
NEVER saved over; candidates save as `Fool-v2-021a+` in
`/home/betty/tarrock-gauntlet-work/fool2-r17/`). Objects: Fool_HeadRetopo
(2,058 v), Fool_BodyRetopo (4,599 v), Fool_Eye_L/R (untouchable), hidden
Fool_SculptBase (reference only).

## Lead rulings
- These are DELIBERATE divergences from the sculpt toward the DRAWN sheets —
  the sculpt's nose was itself too soft (director confirmed). Governing
  references: the v7 sheet's head views + tooling/head_sheet.json +
  head_stations_sheet.json (drawn-face landmark tables from R14), and
  ~/Downloads/Fool-Orthographic-A-Pose.png head crop for the character read.
- Topology edits ALLOWED on Fool_HeadRetopo (R15's own report: the nose
  needs denser midline x-grading — two columns per side is why it reads as
  a ridge). Keep: quad share ≥95%, no new poles near mouth corners/canthi,
  lid–globe clearance ≥1.3 mm at the visible rim, hidden rims occluded, no
  NEW self-intersections beyond the known 22 occluded lid-band pairs, neck
  ring EXACTLY unchanged (72 v — the body seam depends on it, gate
  ≤0.01 mm), eyes byte-untouched, head ≤ ~4.8k tris.
- Body untouched except the conditional calf item; if built, silhouette
  gate everywhere else unchanged.
- The bar: the head-crop render beside the sheet reads as the same character
  — nose visible in front AND side/three-quarter silhouette, one crisp
  expressive mouth, open almond eyes. Blank spheres are fine (irises come
  at materials; the STATUS caveat covers it).

## Phases (regime: Codex builder first; Opus only after 2 documented fails)
- Build (Codex): edit Fool_HeadRetopo per above; MANDATORY eyes-on renders
  every cycle (tooling/head_render.py framing + tooling/render_wire.py for
  wires — the round rig's old wire mode is a known fake); verify with
  fool2-r16/verify_body.py pattern where applicable + a head-gate script
  (neck-ring unchanged, clearances, self-intersections, symmetry).
- Close: lead validation + Codex blind judge (head crops vs sheet, front +
  three-quarter + side, shaded and wire). STATUS/ROUND-STATE push.
