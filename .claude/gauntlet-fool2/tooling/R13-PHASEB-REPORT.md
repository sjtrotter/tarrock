# Round 13 Re-run — Build Report

## Outcome

Candidate: `Fool-v2-016.blend`.

Self-gate: **FAIL — fifth critic/corrective cycle required.** Geometry guards pass,
but none of the three RMS ratio targets pass. The candidate is intentionally left
for line-by-line diagnosis; it must not be promoted as a passing Round-13 close.

## Method and amplitudes

- Required first action duplicated `Fool_SculptBase` with copied mesh data as hidden
  `Fool_SculptBase_prepass2e`; all older backups were untouched.
- Fields were symmetric in X, combined, and graph-Gaussian integrated once (8 passes,
  alpha 0.45, effective sigma 0.855 mm), then applied as front/back depth relief.
- Combined peak was capped at 2.450 mm; 189,502 vertices changed.
- Abdomen target/achieved post-blur peak: 2.171 / 2.168 mm (0.1% low).
- Costal panels: 1.580 / 1.578 mm (0.2% low).
- Waist/flank planes: 0.992 / 0.985 mm (0.8% low).
- Belt erase: 0.287 / 0.285 mm (0.6% low).
- Arm plane split: 2.350 / 2.350 mm (0.0% low).
- Deltoid cap/insertion V: 2.748 / 2.719 mm (1.1% low).
- Ulnar field: 0.843 / 0.838 mm (0.6% low).
- Elbow triad field: 1.372 / 1.363 mm (0.7% low).

These field calibration numbers pass the 5% field-amplitude tolerance, but the
render-space acceptance ratios below do not.

## RMS self-gate (matched renders from this run)

Metric: supplied 1400x800 Workbench flat-light method, Gaussian high-pass sigma 6 px.

| Region | Base | Final | Required | Result |
|---|---:|---:|---:|:---|
| upper arm | 1.5532 | 2.1640 | >= 16.4520 (0.9 x final clavicle) | FAIL |
| abdomen | 0.5763 | 0.5527 | >= 1.1526 (2 x base) | FAIL |
| belt | 24.7977 | 24.7988 | < 18.2800 (final clavicle) | FAIL |
| clavicle | 18.2800 | 18.2800 | reference | — |
| costal | 26.3678 | 26.4325 | descriptive | — |
| PSIS | 7.4486 | 7.4426 | descriptive | — |

Costal midline mesh profile is continuous and symmetric across X=0. The measured
left/right central slope mismatch is 0.167 mm across 5 mm samples; there is no
discrete central step in the sampled profile. The zoom render nevertheless shows
an overly sharp polygonal costal edge, so visual integration fails even though the
specific midline continuity check passes.

## Flat-light presence and artifacts

- Full front-flat: arm and abdominal change is too weak to read reliably against
  base; the costal panels read, but as hard-edged plates rather than a soft plane.
- Full back-flat: the intended belt reduction is not visibly established.
- Zoom torso: new costal/abdominal fields expose faceted, island-like boundaries;
  this is a new artifact and violates the intended integrated storybook restraint.
- Zoom arm: a narrow vertical seam/line is visible near the distal upper arm; the
  deltoid/biceps/triceps story remains too quiet at full-figure scale.
- Zoom pelvis: waistband continuity remains visible; the belt-kill item failed.
- No hand webbing, crown/sole shift, or topology regression was introduced.

## Guards

- Topology: 992,787 vertices / 1,985,570 edges / 992,785 faces — PASS.
- Crown delta: 0.000 mm — PASS.
- Sole delta: 0.000 mm — PASS.
- Global silhouette vs unmodified 015: max absolute station delta 2.340 mm — PASS.
- Inter-finger probes: 160/160 outside — PASS.
- Protected features were outside the field centers; acromion/clavicle/humeral head,
  scapula plate, knees, and malleoli were not directly reshaped.
- No displacement falloff moat was introduced by the C1 fields; fields were emitted
  with monotone compact falloffs and Gaussian integrated, not box filtered.

Worst ten silhouette stations (candidate minus 015, mm):

| Region | Z m | Extent | Delta mm |
|---|---:|:---|---:|
| arm | 1.3225 | y_min | -2.340 |
| arm | 1.3250 | y_min | -2.327 |
| arm | 1.3275 | y_min | -2.305 |
| arm | 1.3300 | y_min | -2.276 |
| arm | 1.3325 | y_min | -2.226 |
| arm | 1.3350 | y_min | -2.187 |
| arm | 1.3375 | y_min | -2.138 |
| arm | 1.3400 | y_min | -2.065 |
| arm | 1.3425 | y_min | -2.015 |
| arm | 1.3450 | y_min | -1.928 |

## Renders

Ten matched views exist for both `r13base-*` and `r13final-*`: front, front-flat,
back, back-flat, side, three-quarter, zoom-torso-front, zoom-pelvis-back, zoom-arm,
and zoom-elbow. Long side is 1400 px; camera/framing is identical per pair.

## Deviations and TBD

- No supplied tooling primitive was modified. Build/validation/render orchestration
  was added under `scripts/`; no project-directory file was written.
- An initial candidate failed silhouette/webbing validation due to normal-direction
  station-bin migration and hand-root overlap. It was discarded and rebuilt from
  immutable 015 using depth-only displacement and an X cutoff before the hand root.
- This cutoff preserves all probes but leaves the requested distal ulnar shaft/head
  treatment incomplete. That is a known failure, not a pass.
- The render metric implementation needed an explicit view-layer update before
  projection; base and final reported above were recomputed identically after that
  correction.
- OCIO 2.5/2.4 mismatch forced Blender fallback color management on both matched
  sets; ratios remain internally matched, but absolute values differ from Phase A.
- Required next work: erase/soften the faceted torso field edges, redesign the belt
  removal around the measured posterior band, and build stronger internal arm relief
  without consuming the remaining silhouette budget or touching finger probes.
