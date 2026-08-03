# Round 13 Phase A — Tooling Reconstruction

## Built

- `tooling/fieldlib.py`: C1 radial and asymmetric teardrop falloffs; C1 facing;
  conservative graph heat/Gaussian blur with effective sigma; calibrated amplitude
  loop; interpolated `(z,phi)` terrace repair with Z-only Gaussian; Gaussian residual
  erase; silhouette stations; moat profiles; per-region displacement statistics;
  symmetric field emission.
- `tooling/selftest.py`: immutable, in-memory tests against 015.
- `tooling/stations_base.json`: unmodified-015 stations at 2.5 mm Z spacing, split
  into torso/arm/leg by documented geometric masks.
- `tooling/extract_stations.py` and `tooling/sheet_stations.json`: calibrated sheet
  extraction after linear interpolation across detected blue guide bands.
- `tooling/probes_build.py` and `tooling/webbing_probes.json`: opposing-surface
  midpoint probes with BVH closest-point/outward-normal classification.
- `tooling/rms_metric.py` and `tooling/rms_base.json`: repeatable Workbench flat-light
  render and projected-anchor regional high-pass RMS metric.
- `renders/r13base-front-flat.png`, `renders/r13base-back-flat.png`.

## Selftest on Fool-v2-015.blend

- Vertices / edges: 992,787 / 1,985,570.
- Source position SHA-256 before and after:
  `56211378902e266419bedc51bba249c1c2c7aa74a6357ffe3bcfec84a21b3a17`;
  identical: **true**.
- C1 cutoff inward numerical gradients at epsilon/r = 1e-2..1e-5:
  0.298000, 0.029980, 0.0029998, 0.000299998; tends to zero.
- Teardrop tight/tail weights: 0.104000 / 0.740741; ratio 7.12251.
- Graph blur: 3 iterations, alpha 0.4, effective sigma 0.493476 mm;
  scalar mean/centroid shift 5.86e-17.
- Amplitude loop target peak 2.000 mm: round 1 13.4915 mm, round 2
  2.00000 mm; error 0.0000%, converged.
- Synthetic terrace step metric: 3.11610e-5 to 0 (100% reduction).
- Silhouette sanity: sole Z 0.000004999 m, crown Z 1.71699798 m,
  shoulder-region torso half-width 0.249999 m (about 6 mm above the 0.244 m
  expectation because the simple x=0.25 m anatomical split caps the welded junction).

## Sheet spot checks (mesh minus drawn)

| Z m | region | mesh mm | sheet mm | delta mm |
|---:|:---|---:|---:|---:|
|0.100|leg|177.98|185.40|-7.42|
|0.300|leg|180.69|187.42|-6.73|
|0.500|leg|169.13|173.31|-4.18|
|0.700|leg|180.19|185.40|-5.21|
|0.900|leg|165.51|169.28|-3.77|
|1.050|torso|137.63|141.07|-3.44|
|1.180|torso|155.29|157.19|-1.90|
|1.260|torso|179.66|179.36|+0.30|
|1.420|torso|69.09|68.52|+0.57|
|1.620|torso|91.78|94.72|-2.93|

Agreement is not tuned: upper-leg stations differ 4–7 mm, while most torso and
upper-body clean stations are within about 3.5 mm. Detected repaired guide rows:
78, 144, 158–159, 185–186, 228–229, 276–277, 301–302, 400–401, 514–515,
659, 824–825, 929–930.

## Webbing gate

- Learned left-hand digit Y centers (m): -0.047737, -0.021495, -0.002022,
  0.017577, 0.036752.
- 4 adjacent pairs, 20 shared-span stations per pair per hand: 160 probes total.
- Unmodified 015 outside count: **160/160; PASS**.
- Stored clearance and exact method parameters with every point.

## Flat-light RMS gate

- Workbench, 1400x800, R5_CAM orthographic scale 3.20, `paint.sl`, single gray,
  shadows on, cavity/specular off; Gaussian high-pass sigma 6 px.
- Masks are ellipses projected from the recorded 3D anchors, not hand-drawn boxes.
- Base 015 RMS (8-bit luminance units): upper arm 0.3134; abdomen 0.6269;
  PSIS 6.2590; clavicle 6.5189; belt 8.1074; costal 22.6937.
- Ordering: upper arm < abdomen < PSIS < clavicle < belt < costal: **PASS**.

## Deviations / TBD

- No sculpt candidate was produced and no blend file was saved.
- The station mask's welded shoulder split yields 0.250 m rather than 0.244 m;
  Phase B should compare identical region labels/masks, not reinterpret stations.
- Sheet agreement is honestly outside 3 mm at several leg stations; this sheet table
  remains reference/record only as directed. `stations_base.json` is the guard.
- One probe rerun was mistakenly launched after a readout of 92,000 thermal units;
  it was interrupted immediately after scene load, before the probe script ran.
  All completed Blender gates used pre-run maxima below 90,000.
- Blender emitted an OpenColorIO version mismatch and used fallback color management;
  the saved render and metric are internally identical/repeatable on this installation.
