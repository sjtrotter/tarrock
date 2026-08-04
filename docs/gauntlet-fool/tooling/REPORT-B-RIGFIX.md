# R18 Phase B2 rig-fix report

**Status: FAIL / stopped at the required fist visual gate.** `Fool-v2-023e.blend` is saved in rest pose. The phalange reposition, eye swap, targeted weight repair, static checks, corrected measurements, render whitelist, and smear battery completed successfully. The 60°×3 curl is mechanically clean but does not read as a closed stylized fist, so no topology or further joint-layout work was attempted.

## Bone reposition and geometric sets

All 30 phalanges were repositioned from the straightened ring-centroid polylines on `backup_BodyRetopo`. For each digit the stations are root, 40% arc length, 70%, and tip; `.R` endpoints are exact world-X negations of `.L`. Every sampled bone segment lies within 0.000252 mm of its tube-centroid polyline. Parenting remains `01→Hand`, `02→01`, `03→02`; names and deform flags are retained.

| Digit | Left | Right | Components / bbox |
|---|---:|---:|---|
| Thumb | 49 | 49 | one each; inside |
| Index | 77 | 77 | one each; inside |
| Middle | 74 | 74 | one each; inside |
| Ring | 74 | 74 | one each; inside |
| Pinky | 76 | 76 | one each; inside |

The 15 mm predicate was not relaxed. The thumb count is topology-exact: its supplied ground truth is six 8-vertex rings plus one tip, or 49 vertices. Full old→new head/tail coordinates, per-bone fit, set bounds, and hand bounds are in `rig-validation-e.json`.

## Repairs and validation

- Eye anatomy is corrected: `Eye.L` and `Fool_Eye_L` are at +X, `Eye.R` and its globe at −X. Each globe remains centered on and parented to its same-position, non-deform eye bone.
- Finger-chain bleed was removed only outside the correct geometric tube for that digit. Tube vertices use the two nearest new phalanges with normalized `1/d^4` weights and a 50/50 Hand blend within 5 mm of the root. Palm, web, and other non-digit automatic weights were retained.
- Rendering used a strict whitelist: `Fool_Mesh`, `Fool_Eye_L`, and `Fool_Eye_R` only.
- Smear guard flagged 0 vertices in all 13 pose cases.
- Static gates pass: 6,661 vertices, 0 self-intersection pairs, 0 interior non-manifold edges, 76 boundary edges with the neck seam bonded, 0.000239 mm numerical rest deviation (0.000 mm at required precision), 0.000 mm L/R bone endpoint residual, 53 bones, identity rig transform, and unchanged sole z=0.

## Pose verdicts

The corrected x=0.225 armhole ring loses 9.98% area at 45° and 18.26% at 80°. The deltoid remains continuous, but the inner armhole visibly pinches and flattens at 80°; the older x=0.289 rigid-arm secondary reads only 0.59% and 1.10% loss and is not representative of the socket.

The finger curl no longer crumples or produces smear bars. Tubes follow the phalanges cleanly and the web does not tear. It nevertheless **fails the fist gate**: the fingers form an open hook, fingertips remain away from the palm, the thumb is splayed, and the silhouette lacks closed-knuckle volume. Required worst-area close-ups are `renders-e/fingers-top.png`, `renders-e/fingers-palm-tq.png`, and `renders-e/fingers-front.png`. Per instruction, this is the stop point; changing curl semantics, thumb articulation, joint layout, or topology is a lead decision.

Eye clearances remain positive (minimum sampled 0.02596 mm). Neck poses retain a continuous bonded collar. Knee and hip are continuous; the 90° elbow remains the weakest non-hand deformation because its low-poly bend is visibly angular.

## Deliverables

- `Fool-v2-023e.blend` — rest-pose candidate
- `rig-validation-e.json` — complete numeric evidence, including all 30 old→new bone coordinates
- `renders-e/` — 21 whitelist renders, including shoulder and fist close-ups

Open decisions are how to obtain a genuinely closed fist and whether the 18.26% high-angle armhole loss warrants topology or weight-layout work.
