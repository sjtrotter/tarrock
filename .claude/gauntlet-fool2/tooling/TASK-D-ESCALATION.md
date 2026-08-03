# Round 13 — Phase D: escalated builder (Claude Opus), diagnose-first

Codex failed the same three visual items twice (Phase B, Phase C). You are the
escalated builder. You own the ONLY Blender lane: headless
`blender --background <file> --python <script>` (Blender 5.2). Never launch the
GUI, never touch port 9876. Work dir: /home/betty/tarrock-gauntlet-work/r13/
(scripts to scripts/, renders to renders/ as r13esc-*). The project repo is
canon-read-only for you EXCEPT nothing — do not write to the repo at all; the
lead promotes.

## Machine protocol (non-negotiable)
Before EVERY blender run: `cat /tmp/tarrock-governor/slots` (PAUSE → poll 15s);
`cat /proc/loadavg` first value < 6; max /sys/class/thermal/thermal_zone*/temp
< 90000 (skip unreadable zones). ONE blender process at a time.

## Read first (in order)
1. /home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R13-BRIEF.md
   (the round's intent: 4 items, guards, storybook restraint)
2. /home/betty/tarrock-gauntlet-work/r13/REPORT.md and REPORT-C.md (both failures)
3. /home/betty/Projects/tarrock/.claude/gauntlet-fool2/ROUND-STATE.md (method
   lessons — binding) and docs/design/character-sculpt-reference.md (§2, §3;
   its lengths are 0.5 m/unit — halve; this file 1 u = 1 m, faces −Y, LEFT=+X)
4. Renders: r13base-*, r13final-*, r13fix-* (LOOK at them; you can read images)

## Files
- BASE (chain, sacred): /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-015.blend
- Phase B: Fool-v2-016.blend · Phase C: Fool-v2-016b.blend (both contain hidden
  `Fool_SculptBase_prepass2e` = exact 015 vertex state; same topology → per-vertex
  delta fields are directly computable)
- Tooling: tooling/fieldlib.py (validated), stations_base.json (silhouette guard
  baseline), webbing_probes.json, scripts/ (Codex's build/validation orchestration
  — reuse the validation, distrust the build choices)
- OUTPUT: Fool-v2-016c.blend + REPORT-D.md (≤150 lines) + r13esc-* renders
  (same ten views, framing identical to the r13base-* set — the render code in
  scripts/ reproduces it)

## What three critics + two failed passes established
Forms are correctly PLACED at ~1/3 needed amplitude; silhouette must NOT move
>±3 mm per station vs stations_base.json. The three unfixed visual items:
1. TORSO plane contrast (costal two-panel arch, waist/flank planes, belly flat)
   too quiet at full-figure flat light; Codex's versions read as faceted PLATES
   with island edges (integration failure, visible in r13final/r13fix zooms).
2. THE BELT: a continuous horizontal band across the back at z≈1.03–1.08 that
   reads like a garment waistband. NOT a proud ridge (r=18 mm baseline residual
   p95 = 0.000 mm — Phase C measured). Its geometric nature is UNDIAGNOSED.
3. ARM relief (deltoid insertion V, biceps/triceps plane split, ulnar line,
   elbow triad) barely reads; a vertical seam artifact near the hand root in
   016/016b. Arm y_min stations z 1.30–1.36 have only ~0.6 mm silhouette
   budget left — redistribute, don't stack.

## Your mandate
DIAGNOSE FIRST, then build. Required diagnosis step (report it): cross-section
profile plots (numpy, from the mesh) through the belt band (several X stations
across the back) and through the costal/abdomen panels on 015 vs 016b —
identify what geometric signature makes the belt band and the plate edges
visible in flat light (step? normal discontinuity? curvature band?). Then
design the fix for what it actually is.

Build authority (lead-granted):
- Amplitudes: you may go WELL past Codex's doses — abdomen/costal plane
  contrast up to ~4–6 mm post-blur, waist/flank deepening INWARD up to the
  ±3 mm station budget — restraint bounded by the storybook bar ("lean youth,
  no bodybuilder separation"), by the protected regions, and by silhouette.
- You may start from 015, 016, or 016b state (justify the choice).
- Integration standard is VISUAL: iterate build → render → LOOK yourself until
  the zooms show soft integrated transitions (no circleable plates, islands,
  seams). Budget several internal iterations; you hold the lane.
- Chest-leads-belly is protected globally (chest lead ≈ 7.8 mm); belly must
  never lead. PROTECTED features (do not reshape): acromion corner, clavicle S
  + hollow, humeral head, malleoli, knee complex, scapula plate.
- Symmetry in X exact (emit fields at ±x).

## Gates (geometry + eyes, not render-RMS scalars — lead ruling after two
metric failures)
(a) Belt: diagnosed, and the back-flat + pelvis-back zoom renders show NO
    continuous band (your eyes + the lead's; state your honest read).
(b) Torso: plane changes legible at FULL-FIGURE flat front render (compare
    r13base-front-flat.png side by side; state what a viewer sees), zooms show
    integrated soft transitions.
(c) Arm: relief visible in zoom-arm and at full figure ≥ "faint"; seam gone.
    If full-figure arm presence still underwhelms after honest effort, say so —
    the lead may close with logged debt.
(d) Guards, verified in-script with printed numbers: topology unchanged
    (992,787 v); crown/sole Z to 0.01 mm; silhouette |cand−015| ≤ 3 mm at every
    station of stations_base.json (print worst 10); webbing 160/160; hidden
    backups untouched; `Fool_SculptBase_prepass2e` present in the output file.
(e) Renders: full ten-view r13esc-* set, identical framing to r13base-*.

## Report (REPORT-D.md)
Diagnosis findings (the belt's actual nature — this is round-log material),
what you built and why, doses applied, internal iteration count and what each
LOOK cycle changed, gate results (a)–(e) with honest self-assessment, worst-10
station table, artifacts remaining. No false passes — the lead re-validates.
