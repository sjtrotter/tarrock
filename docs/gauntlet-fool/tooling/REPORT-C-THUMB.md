# R18 Phase C — thumb-base girth and thenar eminence

## Result

Selected candidate: `Fool-v2-023j.blend` (built directly from `Fool-v2-023f.blend`).
The edit is vertex movement only. Both hands are exact coordinate-negated edits;
everything outside the two hand boxes is frozen.

The proximal thumb rings were expanded radially by 1.30, 1.25, 1.15, and 1.06,
then left unchanged distally. Ring centroids were preserved and the tip did not
move. A C2-falloff palm-side mound was formed from 16 existing palm vertices per
side with a 10.5 mm peak. The mound excludes the thumb tube, so it does not bend
the straight thumb axis or narrow the web.

Eyes-on against the model-sheet hand cutout and the orthographic hand reference:
the thumb now reads as full-based rather than twig-thin, and the palm has a visible,
restrained thenar ball flowing into the wrist. It remains deliberately simpler than
the photographic anatomy reference and is appropriate for the young-adult
storybook treatment. The existing mesh is broadly low-poly, but the new mound does
not introduce a localized ridge, plateau, or conspicuously worse faceting; its
normal transition reads as one soft mass in the bilateral palm and curl close-ups.

## Rig upkeep

Thumb tube centers were extracted from the edited `Fool_Mesh`, not
`backup_BodyRetopo`. The maximum difference from the incoming thumb-bone stations
was 22.204886 mm, so Thumb.01–03 were repositioned from those edited centers and
mirrored by exact world-X negation. Thumb weights were geometrically restricted to
the tube. Thenar ownership is predominantly Hand (72–90%) with a smooth Thumb.01
root blend (10–28%). Two root carriers exposed by restriction were rebound
symmetrically; final zero-weight count is 0.

## Gates

| Gate | Result |
|---|---:|
| Topology | 6661 verts / 13286 edges / 6625 faces; SHA `7add70d794fb74a9c19bf7a49601222d6d8fc2f512a9729990f904c3063f06ff`, unchanged |
| Mirror residual | 0.133144 mm before; 0.133144 mm after (unchanged) |
| Self-intersections | 0 |
| Outside-hand movement | 0.000000 mm |
| Rest identity | 0.000136 mm |
| Zero-weight vertices | 0 |
| a80 rigid hand lag | 0.000905 mm (30 mm gate) |
| Smear guard | 0 in a80, fingers 60x3, elbow90, and own-axis thumb 60x3 |

Straightness, maximum 3D ring-center deviation:

| Digit | L | R |
|---|---:|---:|
| Thumb | 0.000169 mm | 0.000169 mm |
| Index | 0.000137 mm | 0.000137 mm |
| Middle | 0.000120 mm | 0.000120 mm |
| Ring | 0.000391 mm | 0.000391 mm |
| Pinky | 0.000435 mm | 0.000435 mm |

Clearances:

| Pair | L | R | Assessment |
|---|---:|---:|---|
| Thumb–index | 11.451204 mm | 11.451204 mm | PASS (>= 2 mm) |
| Index–middle | 7.255320 mm | 7.255320 mm | unchanged |
| Middle–ring | 7.698384 mm | 7.698384 mm | unchanged |
| Ring–pinky | 6.894819 mm | 6.894819 mm | unchanged |

## Render battery

`renders-j/` contains the whitelist-only battery: `fingers-top`,
`fingers-palm-tq`, `a80-front`, `elbow90`, bilateral `rest-palm`, bilateral
`hand-top`, and bilateral `thumb-curl`. The curl uses a bend axis constructed in
the palm plane perpendicular to each thumb axis, not world Y. Every image was
reviewed at full resolution. The thumb-index gap stays visibly open, the mound is
bilaterally consistent, and opposition is toward the fingers without smear.

Full machine-readable results are in `thumb-validation-j.json`.
