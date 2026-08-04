# Round 16 Phase A — Body Retopo Mechanical Report

## Source and extraction status

All Blender work was headless and launched through `./gov.sh`. The source chain was read-only. This Blender 5.2 build terminates command processing when the 916 MB chain is supplied as the main file, so the extraction/verification scripts append selected datablocks from the read-only library instead. Nothing calls `save_mainfile`, and no `.blend` was written.

`inventory.json` contains all 49 source objects. `Fool_SculptBase` has 1,012,034 vertices and 1,011,868 faces; its bounds are X −860.734..860.733 mm, Y −146.502..122.920 mm, Z 0.005..1716.964 mm. It is watertight: zero boundary edges, zero non-manifold edges, Euler characteristic 2.

`Fool_HeadRetopo` has exactly three simple boundary loops with sizes 72, 38, and 38. The ordered 72-vertex neck ring is planar at Z=1442.000 mm, centered at (0.000, 21.104, 1442.000) mm, with mean XY radius 52.166 mm. The extractor raises a runtime error if this structure changes.

## Body guides

`body_axes.json` uses 5 mm-thick vertex slabs and angular radial-envelope resampling. Torso sections are at 20 mm spacing and contain 64 ordered outline samples. Leg sections use the same spacing and arm sections use 15 mm spacing in YZ planes. The mechanically detected crotch apex is Z=825 mm. Recorded arm landmarks are shoulder crease X=±275 mm and wrist X=±690 mm. These are sampling landmarks, not retopology judgments.

The five digit guides come from the purpose-built `HandShell_*` source objects after isolating their +X connected side (each shell object unexpectedly contains both mirrored hands). Measured trimmed axis lengths are thumb 133.376 mm, index 131.671 mm, middle 147.140 mm, ring 133.524 mm, and pinky 120.975 mm. Each has root/tip, mean radius, and three stations in the JSON; the right hand is an explicit X mirror.

Adjacent-pair clearance estimates (matched axis station distance minus the two mean radii) are:

- thumb–index: 48.629 mm
- index–middle: 2.902 mm
- middle–ring: 2.079 mm
- ring–pinky: 1.657 mm

The latter three are below the nominal 4 mm build target. These are conservative axis/radius estimates, not exact closest-triangle distances; Phase B should preserve visibly open webs and rely on the verifier's gap rays as the construction check. Thumb–index is not directly comparable to the other web gaps because of the thumb's fan angle.

Below Z=40 mm the right-foot point cloud is one continuous profile cluster. The sculpt therefore has a single foot mass, not individually separated toes. `renders/a-foot-top.png` is the top-view evidence.

The global X bounds differ by only 0.001 mm, indicating near mirror symmetry at the bounding-box level. I did not claim an exact full-surface sculpt mirror residual because that was not required and would require a million-point nearest-neighbor pass.

## Instrument status

`verify_body.py` accepts candidate blend, object name (default `Fool_BodyRetopo`), and output path. It measures vertex and face-centroid deviations, nearest-sculpt normal inversions, BVH overlap pairs minus edge adjacency, mirror residual, face composition, boundary/non-manifold edges, the 72-point neck seam gate, finger-gap rays, and pole proximity to recorded bend creases.

The self-test on `Fool_HeadRetopo` completed and wrote `selftest-verify.json`: 2,058 vertices, vertex RMS 2.17140 mm, face-centroid RMS 1.98833 mm, 122 inverted vertex normals by nearest-sculpt comparison, 27 non-adjacent BVH overlap pairs, 99.7987% quad share, and an exact 0.000000 mm neck-ring match. Finger webbing is deliberately marked skipped for this head-only test. These are execution-validation numbers, not body acceptance results.

The self-intersection subtraction treats faces sharing an edge as adjacent, matching the R15 instrument. Faces that touch only at a vertex are intentionally still eligible overlap pairs. Candidate gap probes trim a ray between adjacent digit axes by the recorded mean radii; any candidate hit inside that expected open gap fails the probe. This is a deterministic construction probe, not a substitute for visual inspection.

`render_body.py` provides full front/back/side/three-quarter and hand-top/foot/shoulder/knee/neck-seam zooms in shaded and wire-over-shaded modes. For the million-face sculpt proof only, it applies an in-memory 6% render decimation so the governed background job fits the process window; normal retopo candidates below 300k vertices are rendered unmodified. No decimated mesh is saved.

## Phase-B cautions

- Match the head's ordered 72-point ring exactly; the gate is 0.01 mm maximum nearest-boundary distance.
- The neck ring is offset toward +Y (centroid Y=21.104 mm), so do not assume it is centered at world Y=0.
- Preserve open index/middle/ring/pinky webs; the sampled clearances are tighter than 4 mm.
- The feet are intentionally fused toe masses. Do not invent separate toe topology based on generic anatomy.
- Treat the recorded crease points as mechanical pole-exclusion neighborhoods (15 mm), especially armpit, elbow pit, knee back, groin, and finger roots.
- `body_axes.json` sections are slab-derived guides from a dense sculpt, not exact analytic plane/triangle intersections. They are suitable for placement and verification probes but should not be mistaken for retopo prescriptions.
