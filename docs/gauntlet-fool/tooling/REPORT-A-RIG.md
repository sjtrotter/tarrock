# R18 Phase A — Rig Report

**Status: FAIL / stopped at the finger pose gate.** Final evidence candidate: `Fool-v2-023d.blend` (rest pose, poses not baked).

## Work completed

The source head and body were duplicated as hidden local backups, joined as `Fool_Mesh`, and only the 144 selected neck-ring boundary vertices were merged into 72 pairs. A custom 53-bone deform rig was placed from the R16 measured body axes and digit stations. Automatic binding succeeded; weights were then limited to four, normalized, pruned below 0.001, and corrected for side/region bleed. The eyes are bone-parented to their named eye bones with world transforms preserved. The Armature modifier uses preserve-volume deformation after the first shoulder test exposed avoidable volume loss.

## Gate table

| Gate | Result | Evidence |
|---|---:|---|
| Join count | PASS | 6,661 vertices |
| Neck boundary accounting | PASS | 220 → 76 boundary edges; exact drop 144 |
| Interior non-manifold | PASS | 0 |
| Self-intersection | PASS | 0 BVH face pairs |
| Mirror residual | PASS | 0.133144 mm, equal to source head; body source 0 |
| Rig bones / symmetry | PASS | 53 names; L/R endpoints 0.000 mm residual |
| Weight cleanup / bleed | PASS | 0 zero-weight; max 4; all bleed counters 0 |
| Rest identity | PASS | 0.000169 mm numeric maximum, rounds to 0.000 mm |
| Shoulder 45° | PASS | 0.59% ring-area loss |
| Shoulder 80° | PASS with note | 1.10% loss; mild angular armhole pinch remains |
| Fingers 60° × 3 | **FAIL** | Web/digit crumpling and inadequate knuckle volume in both close-ups |
| Eye extremes | PASS by sampled clearance | 0.02596–0.04743 mm minimum unsigned surface distance |
| Neck battery | PASS | Seam bonded and collar continuous, though faceted |
| Elbow/knee/hip | PASS with note | No tearing; elbow is visibly angular |

## Honest pose verdicts

The shoulder volume setting fixed the measurable collapse (023b: 8.08%/24.03%; 023c+: 0.59%/1.10%), though the 80° armhole still pinches slightly. The finger battery is the blocking failure. A targeted 023d repair restricted each R16 digit tube to its matching phalange chain, but the mandated curl still crumples the web and does not hold convincing knuckle volume. Further credible work would require lead approval for hand/web topology or joint-layout changes, so work stopped as instructed.

The weakest deformation overall is the curled hand. The weakest non-hand deformation is the 90° elbow, which holds continuity but bends with a sharp, low-poly profile.

## Open problems

- Finger/web topology or hinge layout must be revisited before Unity hand animation is acceptable.
- The 80° shoulder has mild residual visual pinching despite good area retention.
- The source eye naming is handed opposite the body convention (`Fool_Eye_L` is at X=-43 mm); explicit named parenting was honored and documented.

All 18 required renders were opened and reviewed. Full measurements and every joint coordinate are in `rig-validation.json`.
