# Round 13 BUILDER brief — amplitude turn-up (Codex, headless Blender lane)
# [Recovered verbatim from the pre-reboot lead's Codex invocation, 2026-08-03.
#  The r7–r12 scratchpad tooling it references was LOST in the reboot — the new
#  lead must reconstruct or re-derive those libs before re-issuing this brief.]

You are the Round 13 builder for the Tarrock Fool base mesh. You own the ONLY
Blender lane: work exclusively via `blender --background <file> --python <script>`
(Blender 5.2, binary `blender`). Never launch the GUI, never touch port 9876.

## Machine protocol (director-ordered, non-negotiable)
Before EVERY blender run: `cat /tmp/tarrock-governor/slots` — if it prints PAUSE,
poll every 15s until it doesn't. Also check `cat /proc/loadavg` (first value must be
< 6) and the max of `/sys/class/thermal/thermal_zone*/temp` (< 90000). One blender
process at a time, sequential.

## Files
- INPUT (never modify): /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-015.blend
- OUTPUT: Fool-v2-016.blend — save to the Codex WORKDIR (the project dir is
  read-only under the Codex sandbox); the lead validates and promotes it into
  docs/design/3d-models-inwork/. NEVER overwrite 001–015.
- Work dir for scripts/renders/report: (lead fills in per run)
- Prior tooling: r7/ r10/ r11/ r12/ dirs — LOST in the 2026-08-03 reboot.
  Key patterns to reconstruct: r11lib.py (asymmetric "aradius" teardrop falloffs,
  C1 smoothstep facing weights, calibrated-amplitude loop: build field → graph-blur
  → measure → correct gain → repeat until within 5% of target); r12lib.py/r12build.py
  (the exact torso fields being amplified); r10lib.py (terrace_fix, erase);
  r12-final-tables.json (drawn-vs-mesh station tables — re-derive from the sheet
  calibration constants below).
- Method authority: /home/betty/Projects/tarrock/docs/design/character-sculpt-reference.md
  (§3 items 3,4,8,9 + integration preamble). NOTE: that doc's lengths are for an old
  file at 0.5 m/unit — HALVE them. This file: 1 unit = 1 m, character faces −Y,
  LEFT = +X, soles Z=0, crown Z≈1.717. Symmetry: every field must be built
  symmetric in X (emit at ±x).
- Run state / context: /home/betty/Projects/tarrock/.claude/gauntlet-fool2/ROUND-STATE.md

## Scene facts
Object `Fool_SculptBase`: 992,787 verts, watertight, the ONLY object you modify.
FIRST ACTION in your build script: duplicate it (obj.copy()+data.copy()), name
`Fool_SculptBase_prepass2e`, link to scene, hide it. Keep all existing hidden
backups untouched. Camera `R5_CAM` exists (ortho). Reference empties REF_Front /
REF_Side: do not touch.

## Context — why this round exists
Four critic cycles have converged: the forms are correctly PLACED (silhouette
verified against the model sheet twice — you must NOT re-proportion or move any
silhouette station by more than ±3 mm) but at ~1/3 the amplitude needed to read in
flat light. Critic's flat-light RMS relief map of the current file: upper arm 2.03
(quietest region — the biggest "mannequin" contributor), abdomen 4.33, PSIS 5.16,
clavicles 6.16, iliac-crest "belt" 8.94 (artifact — TOO loud), costal arch 9.74
(but reads as a scored LINE, not a plane change).

## The four items
1. TORSO PLANE CONTRAST ×2–3: amplify Round 12's existing fields — costal-arch
   two-panel plane change, waist/flank planes, belly flat plane — same shapes,
   more gain, abdomen especially. Rebuild the fields from r12build.py's definitions
   with higher amplitude targets (calibrate against the post-blur field like r11
   did; land within 5% of target).
2. KILL THE BELT: the iliac crest reads as one continuous garment-waistband line
   edge-to-edge across the back. Break its continuity at the spine (the sacral
   triangle interrupts it), fade it laterally, soften the step below. Keep crest
   fullness near the ASIS. Target: that band's RMS drops below the clavicle level.
3. COSTAL MIDLINE: the arch has a kink/step where it crosses the sternum (visible
   in 3/4). Make the crossing a continuous soft plane change dipping at the
   midline (infrasternal angle).
4. ARM RELIEF up to ≥ clavicle RMS: deltoid insertion V (three origins converging
   to one insertion ~45% down the humerus); biceps-front vs triceps-back plane
   distinction on the extended pronated arm (plane breaks, NOT muscle bulges);
   stronger ulnar shaft line (soft edge between the forearm's two planes, ulnar
   head toward olecranon, visible in top view); elbow triad gain up (medial
   epicondyle dominant, olecranon plane-flattened, lateral a soft dimple).
   Storybook restraint: a lean youth, no bodybuilder separation.

## Guards (verify in-script, print numbers)
- PROTECTED, must not reshape (amplifying arm/torso fields that merely overlap
  them is fine, but their own features stay): acromion corner, clavicle S + hollow,
  humeral head, malleoli, knee complex, scapula plate.
- Silhouette: at every station you touch, mesh-vs-drawn stays within ±3 mm.
  Recompute the drawn line from the sheet if needed:
  sheet = docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png (1536×1024),
  scale S=0.00201523 m/px, front figure anchor px(452,932)→world(X0,Z0), side
  anchor px(966,932)→(Y0,Z0), Z=(932−row)·S. r12's tables already contain most
  stations. [LOST — re-derive from the sheet.]
- Topology unchanged (992,787 v / 1,985,570 e / 992,785 f); crown Z and sole Z
  unchanged to 0.01 mm; inter-finger webbing probes 0/102 (probe set r9/probes.json
  LOST — re-derive: probes between adjacent finger shells); no moats (radial
  profile around each amplified feature decays monotonically — the r11 check).
- No new banding: any 1-D profile table must be Gaussian-smoothed (box filters and
  piecewise-linear knots have both caused visible bands — paid-for lessons).

## Renders (headless: bpy.ops.render.render, engine BLENDER_WORKBENCH, camera
R5_CAM, flat studio lighting, 1400px min on the long side; first render the
UNMODIFIED 015 with identical settings as baselines named r13base-*)
To the workdir renders/: for EACH of base and final: front, front-flat
(full-figure, flat single-direction light), back, back-flat, side, three-quarter,
zoom-torso-front, zoom-pelvis-back, zoom-arm, zoom-elbow. (Zooms: move/clone the
ortho camera; keep framing identical between base and final.)

## Self-gate (honest — this decides whether a 5th critic cycle is needed)
After the final renders, measure and report:
(a) RMS relief map recomputed for: upper arm, abdomen, costal band, belt band,
    clavicle (the reference). Targets: arm ≥ clavicle·0.9; abdomen ≥ 2× its 4.33;
    belt < clavicle; costal midline kink gone (measure the arch profile continuity
    across x=0).
(b) Flat-light presence: describe what is visible at FULL-FIGURE zoom in
    front-flat/back-flat vs the base renders (open and look at the images).
(c) Any new artifact you can see. Be harsh with yourself; the lead validates next.

## Report
Write REPORT.md in the workdir: per-item amplitudes applied (target vs achieved),
the self-gate numbers (a)–(c), silhouette verification table, guard results,
deviations from this brief, TBDs. Keep it under 150 lines.
