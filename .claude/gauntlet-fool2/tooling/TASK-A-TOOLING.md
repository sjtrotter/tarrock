# Round 13 RE-RUN — Phase A: tooling reconstruction (Codex, headless Blender lane)

You are rebuilding the run tooling that a machine reboot destroyed. This phase
produces NO sculpt candidate. The chain file is sacred:
`/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-015.blend`
must never be modified or overwritten; the project dir is read-only to you anyway.
Work ONLY in `/home/betty/tarrock-gauntlet-work/r13/` (write scripts to
`scripts/` or `tooling/`, renders to `renders/`).

You own the ONLY Blender lane: `blender --background <file> --python <script>`
(Blender 5.2, binary `blender`). Never launch the GUI, never touch port 9876.
ONE blender process at a time, sequential.

## Machine protocol (director-ordered, non-negotiable)
Before EVERY blender run: `cat /tmp/tarrock-governor/slots` — if it prints PAUSE,
poll every 15s until it doesn't. Also check `cat /proc/loadavg` (first value < 6)
and max of `/sys/class/thermal/thermal_zone*/temp` (< 90000; some zones error —
ignore unreadable ones).

## Context (read these first)
- /home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R13-BRIEF.md
  (the build brief this tooling must serve; Phase B executes it)
- /home/betty/Projects/tarrock/.claude/gauntlet-fool2/ROUND-STATE.md
  (method lessons — the "paid for" list is binding)
- /home/betty/Projects/tarrock/docs/design/character-sculpt-reference.md
  (§2 programmatic method, §3 landmark technique; its lengths are for an old
  0.5 m/unit file — HALVE them. This file: 1 unit = 1 m, faces −Y, LEFT = +X,
  soles Z=0, crown Z≈1.717, symmetry axis X)

Scene facts (015): object `Fool_SculptBase`, 992,787 verts / 1,985,570 edges /
992,785 faces, watertight. Ortho camera `R5_CAM` exists. Reference empties
REF_Front / REF_Side exist. Hidden backup objects exist — touch nothing.
Sheet: /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png
(1536×1024). Calibration: S = 0.00201523 m/px; front figure anchor px(452,932) →
world (X0,Z0); side figure anchor px(966,932) → (Y0,Z0); Z = (932 − row)·S.

System python3 has PIL + numpy (use it for image work). Blender's python has
numpy but NO scipy. Every script must be re-runnable non-interactively and print
its numbers.

## Deliverables (all under tooling/ unless noted)

### 1. fieldlib.py — the numpy field toolkit (the heart of Phase B)
Reconstruct the r10/r11/r12 library patterns named in R13-BRIEF.md:
- C1 falloffs only: smoothstep-family with ZERO gradient at the cutoff radius
  (the old moat bug was an infinite-gradient falloff edge; fpow ≥ 1). Provide
  symmetric radial falloff and the asymmetric "aradius" teardrop (tight edge on
  one side of an oriented axis, long tail on the other — bone edge vs shaft tail).
- Facing weights via C1 smoothstep on (normal · direction) — no hard cutoffs.
- Vertex-graph Gaussian blur (iterated neighbor averaging with an effective
  sigma you compute and report; Gaussian-only — box filters band, paid-for).
- Calibrated-amplitude loop: build field → graph-blur → measure achieved
  peak/RMS → correct gain → repeat until within 5% of target.
- terrace_fix: residual removal on a (z,φ) grid, Gaussian along Z ONLY,
  INTERPOLATED lookup (nearest-bin corrugates — paid-for).
- erase: Gaussian-baseline residual removal at a chosen radius (fill/cut gains).
- Measures: (a) silhouette station tables from the mesh — at 2.5 mm Z bins,
  front-view outer |x| extremes and side-view y min/max, split into region
  labels (torso / arm / leg) by simple geometric masks; (b) moat check — radial
  profile around a feature center decays monotonically; (c) per-region vertex
  displacement stats vs a snapshot.
- Every field emitted symmetric in X (emit at ±x).

### 2. Selftest (headless, on 015, saving NOTHING to the repo)
Run fieldlib against a throwaway in-memory copy of the mesh; verify and print:
falloff C1 at cutoff (numerical gradient → 0); teardrop asymmetry ratio; blur
does not shift the mesh centroid; amplitude loop converges within 5% on a test
field; terrace_fix reduces a synthetic terrace's step metric; silhouette measure
sanity: crown Z ≈ 1.717, sole Z ≈ 0, max torso half-width ≈ 0.244 m at shoulder
height. Confirm at exit that Fool_SculptBase vert positions hash identical to
load (you never wrote to it, prove it).

### 3. stations_base.json — the PRIMARY silhouette guard baseline
The full station table (deliverable 1a) measured on unmodified 015.
LEAD RULING: 015's silhouette is twice-certified vs the sheet, so Phase B's
guard is |candidate − 015| ≤ 3 mm per station. This file is that baseline.

### 4. extract_stations.py + sheet_stations.json (reference/record only)
Drawn silhouette from the sheet via the calibration constants: per-row outer
edges of the FRONT figure (x half-widths) and SIDE figure (y extents) in world
mm. PAID-FOR LESSON: drawn guide lines cross the figure — repair by
interpolating figure rows across each guide-line row BEFORE edge extraction.
Report agreement vs stations_base.json at 10 spot stations (expect mostly
within ~3 mm; report honestly, do not tune to agree).

### 5. probes_build.py + webbing_probes.json
Inter-finger webbing probe set, re-derived (original lost). For each adjacent
finger pair (index|middle, middle|ring, ring|pinky, and thumb|index if they
overlap in span): ≥20 stations along the shared span; each probe = the midpoint
between the two opposing finger surfaces at that station; PASS = point is
OUTSIDE the mesh (BVH ray-parity or closest-point normal test). Total ≥80
probes. GATE: unmodified 015 must pass 100% — if any fail, your probe placement
is wrong; fix placement, not the gate. Store points + method params so the
identical evaluation runs on any candidate.

### 6. rms_metric.py — the flat-light RMS relief metric (self-gate backbone)
Headless-render 015 with R5_CAM, engine BLENDER_WORKBENCH, flat single-direction
studio lighting, ≥1400 px long side: front-flat and back-flat → renders/
(r13base-front-flat.png, r13base-back-flat.png; record exact settings in the
script). Metric: RMS of the high-pass luminance residual (Gaussian blur sigma
~6 px baseline; tune if needed) inside region masks for: upper arm, abdomen,
costal band, belt band (iliac crest line across the back), clavicle, PSIS.
Anchor masks by projecting 3D anchor coordinates through the camera (no
hand-drawn pixel boxes).
SANITY GATE (lead ruling): the metric's regional ORDERING on base 015 must
reproduce the dead critic's map — upper arm < abdomen < PSIS < clavicle <
belt ≈ costal (critic values 2.03 / 4.33 / 5.16 / 6.16 / 8.94 / 9.74; your
absolute numbers may differ, the ordering must not). Iterate sigma/masks until
it reproduces, or report honestly why it cannot. Phase B's amplitude targets
will be evaluated as RATIOS within this same metric.

### 7. REPORT-TOOLING.md (workdir root, ≤120 lines)
What was built, selftest numbers, spot-check table (4), probe gate result (5),
metric ordering result (6) with the actual per-region values on 015,
deviations from this task, TBDs. No fluff.

## Honesty rules
Print real numbers from real runs; never report a gate you did not execute.
If something cannot be made to pass, say so in the report — the lead validates
everything next and a false pass costs a full round.
