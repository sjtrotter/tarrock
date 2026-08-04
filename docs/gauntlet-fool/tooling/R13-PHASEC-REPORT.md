# Round 13 Re-run — Phase C Corrective Report

## Outcome

Candidate: `Fool-v2-016b.blend`.

Self-gate: **FAIL.** Geometry guards pass, but gates (a), (b), and (c) fail.
The file is retained as the required corrective output, not as a promotable close.

## Corrective measurements

- The round's own delta (`016 - Fool_SculptBase_prepass2e`) was graph-diffused
  for 704 passes at alpha 0.45: achieved effective sigma **8.018 mm**.
- Requested / measured post-correction regional peak: abdomen 2.17 / 3.041 mm
  (FAIL, +40.1%); costal 1.58 / 2.336 mm (FAIL, +47.9%); waist 0.99 /
  0.742 mm (FAIL, -25.1%). Overlapping re-gain masks caused the overshoot.
- Posterior surface baseline radius: 18 mm. The band-wide 95th-percentile ridge
  estimator measured 0.000 mm, inconsistent with local positive residuals; the
  applied 82% local-residual correction peaked at 0.507 mm. Thus a defensible
  measured-vs-removed percentage is unavailable (FAIL), and the band remains.
- Arm plane/ulnar/elbow field scale: 1.70x. The distal cutoff was replaced by a
  C1 taper from x=0.55 to 0.65 m (100 mm). Added negative depth was suppressed
  70% over z=1.305–1.365 m to protect the tight silhouette stations.
- The source delta peak was 2.450 mm; fixed delta peak is 3.093 mm per vertex,
  while the station-based silhouette gate remains within 3 mm.

## Revised two-band RMS (8-bit luminance RMS)

| Set | Region | HP sigma-6 | MID sigma-6–40 |
|---|---|---:|---:|
| base 015 | arm | 0.3134 | 17.3310 |
| final 016 | arm | 0.3134 | 17.2612 |
| fixed 016b | arm | 0.3134 | 17.3309 |
| base 015 | abdomen | 0.6285 | 23.9557 |
| final 016 | abdomen | 0.6310 | 23.9748 |
| fixed 016b | abdomen | 0.6313 | 23.9504 |
| base 015 | costal | 22.7017 | 32.9801 |
| final 016 | costal | 22.7004 | 32.9892 |
| fixed 016b | costal | 22.7283 | 32.9475 |
| base 015 | clavicle | 6.5189 | 18.1777 |
| final 016 | clavicle | 6.5293 | 18.4039 |
| fixed 016b | clavicle | 6.5350 | 18.3453 |
| base 015 | PSIS | 6.2591 | 31.7355 |
| final 016 | PSIS | 6.2591 | 31.7353 |
| fixed 016b | PSIS | 6.2591 | 31.7350 |
| base 015 | belt | 8.1102 | 42.4309 |
| final 016 | belt | 8.1102 | 42.4299 |
| fixed 016b | belt | 8.1102 | 42.4275 |

`tooling/rms_metric2.py` computes every set identically; full data is in
`r13_rms2.json`. The revised MID masks contain substantial pre-existing form,
so the requested ratios are not approached by either candidate.

## Gates

- (a) **FAIL.** Belt HP 8.1102 is greater than clavicle HP 6.5350. Back-flat
  A/B and pelvis zoom retain a faint continuous horizontal band.
- (b) **FAIL.** Fixed/base MID ratios are abdomen 1.000, costal 0.999, waist
  not separately masked by the six-region metric. The torso zoom still shows
  hard, faceted costal/abdominal plate boundaries and flank islands.
- (c) **FAIL.** Arm MID ratio is 1.000, not 2x. The arm remains quiet at full
  figure and a narrow vertical transition is still visible in zoom-arm.
- (d) **PASS for rerun guards.** Topology 992,787 / 1,985,570 / 992,785;
  crown and sole delta 0.000 mm; global station silhouette max 2.371 mm;
  webbing 160/160; costal central slope mismatch 0.206 mm with a continuous,
  symmetric sampled profile. C1/Gaussian fields introduced no explicit moat,
  although the visible plate edges are an integration failure.

## Worst ten silhouette stations vs 015

| Region | Z m | Extent | Delta mm |
|---|---:|---|---:|
| arm | 1.3400 | y_min | +2.371 |
| arm | 1.3425 | y_min | +2.370 |
| arm | 1.3450 | y_min | +2.349 |
| arm | 1.3375 | y_min | +2.345 |
| arm | 1.3350 | y_min | +2.323 |
| arm | 1.3475 | y_min | +2.318 |
| arm | 1.3325 | y_min | +2.298 |
| arm | 1.3300 | y_min | +2.263 |
| arm | 1.3275 | y_min | +2.243 |
| arm | 1.3250 | y_min | +2.225 |

## Artifacts and deviations

- Harsh finding: 8 mm diffusion did not remove the torso's visible polygonal
  boundaries after spatial re-gain; overlap amplified them again.
- The back band is reduced only subtly and is not dead at the spine.
- Arm silhouette sign reversed relative to Phase B at the tight stations, but
  remains within budget; relief did not register in the prescribed metric.
- Belt measurement did not yield the expected multi-mm residual; reporting it
  as a successful 70–90% removal would be false.
- OCIO 2.5/2.4 mismatch again forced Blender fallback color management, matched
  across the already-rendered base/final and new fixed images.
