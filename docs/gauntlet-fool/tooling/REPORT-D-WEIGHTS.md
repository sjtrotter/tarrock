# R18 Phase D — Weight Polish Report

**Final: `Fool-v2-023m.blend` — PASS WITH VISUAL LIMITATIONS.** Geometry and bone positions are unchanged. The final contains weight edits only.

## Outcome against the blind judge

| Target | Verdict | Evidence / honest visual assessment |
|---|---|---|
| Finger hinges, spacing, self-intersection | Partial visual improvement; numeric gate passes | A restrained 20% redistribution toward cross-ring hinge blends slightly rounds the transitions without destabilizing the sparse tubes. Evaluated BVH pairs remain 0 (required ≤4). The fingers still read as angular hooks at 60°×3 and knuckle volume remains limited by the low ring count; this is not a production-quality hand fix. No bone-axis edits were made because the accepted axes are straight/symmetric and the aggressive weight trial made deformation worse. |
| Thumb base / opposition | Improved but still angular | Thumb.01 participation was increased smoothly across 16 thenar vertices per side while the collision-free thumb tube weights were retained. The ball now follows opposition more than in 023j and remains connected, but the base is visibly faceted and the pose is still stylized rather than anatomical. Thumb-pose BVH pairs: 0 → 0. |
| Shoulder / armpit at 80° | Clear improvement | 80 upper-deltoid vertices per side received a smooth UpperArm-to-Shoulder/Chest gradient. The squared cap and deep notch are softened in the zoom. At `|x|=0.225`, area loss increased to 6.078%, explicitly allowed when the render improves; the outer `|x|=0.289` ring loses 0.343%. |
| Elbow 90° | Modest improvement | A restrained 25% five-ring UpperArm/LowerArm blend softens the abrupt outer corner without the bulge produced by rejected 023k. The inner crease is less abrupt but remains visibly sharp; it is serviceable, not fully solved. BVH pairs: 0 → 0. |

The wrist received the same restrained transition treatment. Knee, hip, eyes, head, and neck were not targeted. The inherited scalloped neck seam is unchanged.

## Gate results

| Gate | Result |
|---|---:|
| Geometry/topology SHA unchanged | PASS — identical `89808c…0fee` |
| Rest identity ≤0.001 mm | PASS — 0.000136 mm |
| Distinct L/R weight-pair mirror error ≤1e-4 | PASS — 0.0000053 |
| Zero-weight vertices | PASS — 0 |
| Maximum influences | PASS — 4 |
| Normalization maximum error | PASS — 0.000000045 |
| Smear guard | PASS — 0 flagged |
| A80 distal rigid lag ≤30 mm | PASS — 0.000852 mm |
| Fingers 60°×3 intersections ≤4 | PASS — 0 |
| No pose worse than baseline | PASS — every required pose 0 → 0 |
| Head/eyes/neck static weight hash | PASS — unchanged |

The global inherited centerline contains unequal `.L`/`.R` contributions on some vertices that mirror to themselves; the reported mirror gate correctly measures distinct L/R vertex pairs. Those inherited centerline weights were not changed because doing so would violate the static-region constraint.

## Iteration record

- `023k` used full classic blends. It was rejected after render review and BVH measurement: 25 finger-pose, 34 thumb-pose, and 12 elbow-pose pairs, plus an over-soft elbow bulge.
- `023l` restrained the gradients and returned every pose to zero intersections, but its global cleanup touched otherwise static weights.
- `023m` limits cleanup to targeted vertices. It preserves the improved restrained deformation, restores the static hash exactly, and is the final.

## Evidence reviewed

All 17 files in `renders-k/` were opened and reviewed: a45/a80 front and shoulder zooms; fingers top, palm three-quarter, and front; both thumb curls; elbow90, knee90, hip45; neck down/up/turn; and rest T-pose front/back. Only `Fool_Mesh`, `Fool_Eye_L`, and `Fool_Eye_R` were render-enabled.

Machine-readable baseline and final results are in `weightpolish-validation.json`. The raw final validation is retained in `weightpolish-validation-final-raw.json`; the baseline instrument output is `baseline-pose-intersections-j.json`.
