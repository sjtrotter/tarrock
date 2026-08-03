# Round 14 — Phase A: head tooling + measurements (Codex, headless Blender lane)

This phase produces NO sculpt candidate. The chain file is sacred:
`/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-016.blend`
must never be modified or overwritten; the project dir is read-only to you anyway.
Work ONLY in `/home/betty/tarrock-gauntlet-work/fool2-r14/` (scripts to `scripts/`,
renders to `renders/`, data JSON to the workdir root).

You own the ONLY Blender lane: `blender --background <file> --python <script>`
(Blender 5.2, binary `blender`). Never launch the GUI, never touch port 9876.
ONE blender process at a time, sequential.

## Machine protocol (director-ordered, non-negotiable)
Before EVERY blender run: `cat /tmp/tarrock-governor/slots` — if it prints PAUSE,
poll every 15s until it doesn't. Also check `cat /proc/loadavg` (first value < 6)
and max of `/sys/class/thermal/thermal_zone*/temp` (< 90000; ignore unreadable
zones).

## Context (read first)
- /home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R14-BRIEF.md
  (the head-sculpt brief this tooling serves; Phase B executes it)
- /home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/fieldlib.py
  (existing measure code — REUSE its station-table function, do not rewrite)
- /home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/extract_stations.py
  + sheet_stations.json (existing sheet-contour extraction; guide-line repair
  lesson already implemented there)

Scene facts (016): object `Fool_SculptBase`, 992,787 verts, watertight; ortho
camera `R5_CAM`; hidden backups — touch nothing. Conventions: 1 unit = 1 m,
faces −Y, LEFT = +X, soles Z = 0, crown Z ≈ 1.717, symmetry axis X.
Sheet: /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png
(1536×1024). Calibration: S = 0.00201523 m/px; FRONT figure anchor px(452,932) →
world (X0,Z0); SIDE figure anchor px(966,932) → (Y0,Z0); Z = (932 − row)·S.
Known rows: drawn chin row 212 (Z ≈ 1.451); pupil row ≈ 152.5 (Z ≈ 1.571);
pupil columns ±43 mm from front-figure midline; eyeball spec r = 35 mm.

System python3 has PIL + numpy; Blender's python has numpy, NO scipy. Every
script re-runnable non-interactively, printing its numbers.

## Deliverables

### 1. Presence-rig validation (the R13 flat-light debt)
Run `tooling/presence_render.py` on 016 for views `front,three-quarter`.
Verify the studio vs rake PNGs GENUINELY differ: report SHA256s and mean
absolute pixel difference (must be > 2/255). If the script errors (e.g. the
EEVEE engine enum name in Blender 5.2), FIX it — deliver the fixed copy as
`scripts/presence_render.py` and state the diff — do not silently change
the studio variant (it must stay byte-compatible with rms_metric.py settings).

### 2. head_render.py — the Phase-B eyes-on instrument
Same two-variant structure (Workbench studio + EEVEE single 30° rake sun), but
head-framed: aim (0, 0, 1.58), views front / side (camera at +X) / three-quarter
/ back; ortho_scale 0.50; resolution 1100×1400. Also one full-figure front-studio
view for context. Usage identical to presence_render.py (`-- <out> <tag> [views]`).
Render 016 with it (tag `r14base`) — these are the round's BEFORE images.

### 3. head_sheet.json — drawn face landmarks (world mm, both views)
From the sheet's head region (front figure head + side figure head), by PIL
crop + line scans of the DRAWN ink. Measure and record (world coords via the
calibration constants), each with a confidence tag HIGH/LOW:
- brow line row; eye aperture: inner/outer corner columns + top/bottom rows
  (front view); nose: bridge-top row, tip row, base/nostril row; nose tip
  protrusion (side view: most-negative-Y ink at nose rows, minus Y at the brow);
- mouth line row + mouth width (front); chin row (verify ≈212); jaw-corner
  row/col (front + side); ear: top row, lobe row, side-view column range,
  front-view max |x| if drawn; skull back max +Y row range (side); cranium max
  half-width row (front); neck front/back Y at 3 rows between chin and z=1.40.
Print a human-checkable table (px → world). Ambiguous ink = LOW confidence, say
why. Do NOT invent values.

### 4. eyeball_spec.json — the socket/eyeball placement numbers
Given sphere r = 35 mm, center X = ±0.043, Z = 1.571: compute center Y such
that the sphere's front surface sits at the drawn side-view eye/cornea surface
(measure that Y from the side head ink at the pupil row). Also report 016's
CURRENT face surface Y at (x = ±0.043, z = 1.571) from the mesh (the character
faces −Y, so cast a ray from (x, −1, z) toward +Y; report the first hit's Y).
Deliver: recommended center Y, required socket recession depth (sphere front vs
current surface), lateral clearance to the skull side wall at eye Z, and the
midline gap between the two spheres. Flag anything geometrically impossible.

### 5. stations_016.json — the R14 freeze-guard baseline
Full silhouette station table on unmodified 016 (reuse fieldlib measure, 2.5 mm
bins, front |x| extremes + side y min/max, region labels). This is the guard:
Phase B candidates must match 016 EXACTLY below z = 1.30 (report max |Δ|; gate
≤ 0.1 mm) and within ±3 mm for z 1.30–1.45.

### 6. head_stations_sheet.json — drawn head contours (the BUILD TARGET)
From extract_stations.py's method: drawn front half-widths + side y extents for
z ≥ 1.40 only, 2.5 mm bins, guide-line rows repaired. Note rows where ears/nose
ink extends the contour (mark them), since 016 has neither. Spot-check 10 rows
against the sheet by direct crop measurement; report residuals honestly.

### 7. REPORT-HEAD-TOOLING.md (workdir root, ≤120 lines)
What was built; rig-validation numbers (1); the landmark table (3); eyeball
numbers (4); guard baseline summary (5); target-contour spot-check (6);
deviations and TBDs. No fluff.

## Honesty rules
Print real numbers from real runs; never report a gate you did not execute.
If something cannot be measured cleanly, mark it LOW confidence and say why —
the lead validates everything next and a false number costs a full round.
