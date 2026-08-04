# R18 Phase 0 — straighten curled digits

Status: **PASS**  
Final candidate: `Fool-v2-022c.blend`

## Result

The +X hand's four fingers are straight and monotonically fanned in top view at
−15.0°, −3.3°, +3.3°, and +15.0°. The thumb is straight on its proximal 3D chord,
preserving the palm's local tilt. The −X hand is an exact coordinate-negated copy.

No design sheet was embedded in `Fool-v2-021.blend`. The proximal geometry was
therefore used as the fallback measurement. Its noisy raw centroids made the ring
finger point inward, so the four-finger result was constrained to a monotonic fan
centered on the hand axis. The outer spread was increased only as much as needed to
keep every measured adjacent surface gap at or above the source value.

Each downstream 8-vertex ring was transformed rigidly (one minimal rotation plus
translation, no scaling). Ring centers use the original center-to-center arc-length
spacing. The saved single-precision mesh has a worst measured radius drift of
0.000251 mm and spacing drift of 0.000163 mm.

## Gates

| Gate | Source | Final | Result |
|---|---:|---:|---|
| Vertices / edges / faces | 4599 / 9160 / 4562 | 4599 / 9160 / 4562 | PASS |
| Quads / triangles / n-gons | 4562 / 0 / 0 | 4562 / 0 / 0 | PASS |
| Connectivity SHA-256 | `55dfc5b1…a1d94` | `55dfc5b1…a1d94` | PASS |
| Mirror residual | 0.000000 mm | 0.000000 mm | PASS |
| BVH non-edge-adjacent overlap pairs | 0 | 0 | PASS |
| Sole minimum Z | 0.000000 mm | 0.000000 mm | PASS |
| Changed vertices outside digit region | — | 0 | PASS |

Straightness (maximum ring-center lateral deviation):

| Digit | Top | Front | 0.8 mm gate |
|---|---:|---:|---:|
| Index | 0.000067 mm | 0.000119 mm | PASS |
| Middle | 0.000022 mm | 0.000119 mm | PASS |
| Ring | 0.000018 mm | 0.000391 mm | PASS |
| Pinkie | 0.000104 mm | 0.000422 mm | PASS |
| Thumb | 0.000059 mm | 0.000214 mm | PASS |

Adjacent clearance was measured bidirectionally from each tube's vertices to the
opposing tube surface:

| Pair | Source | Final | Delta |
|---|---:|---:|---:|
| Index–middle | 5.252744 mm | 6.439315 mm | +1.186571 mm |
| Middle–ring | 4.506611 mm | 7.141844 mm | +2.635233 mm |
| Ring–pinkie | 4.035857 mm | 5.240645 mm | +1.204788 mm |

The 682 changed body vertices are exactly the five digit tubes and tips on both
hands. All other body vertices are bit-identical. `Fool_HeadRetopo`, both eyes, and
`Fool_SculptBase` have 0.000000 mm maximum vertex delta and unchanged connectivity;
therefore neck seam, wrists/palms, feet, sole, and sculpt deviation outside the
digit region are unchanged.

Self-intersection used `BVHTree.FromBMesh` self-overlap with edge-adjacent face pairs
removed. Source and candidate were loaded in separate Blender invocations, avoiding
the documented duplicate-library-name trap.

## Evidence and eyes-on review

- [Before — top wire](renders/before-hand-top.png)
- [After — top wire](renders/after-hand-top.png)
- [Before — front wire](renders/before-hand-front.png)
- [After — front wire](renders/after-hand-front.png)

Eyes-on review completed at native 900×900 resolution. The after top render clearly
shows straight, fanned, separated fingers and a straight thumb. The front render
shows straight longitudinal ring runs without the prior distal curl. Root junctions
remain connected and no visible tube collapse or scaling is present.

## Candidate history

- `022a`: rejected; all adjacent gaps decreased and six thumb-bridge BVH overlaps
  were introduced.
- `022b`: rejected; outer gaps remained below baseline and one thumb-bridge BVH
  overlap remained.
- `022c`: passes every required gate.

Machine-readable result: `p0-validation.json`.
