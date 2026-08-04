# R15 Phase B — head retopo (Opus builder)

**Final candidate: `Fool-v2-019b.blend`** (workdir), object `Fool_HeadRetopo`.
Gates: `r15-b-validation.json`. Renders `renders-b/b7-*`, sections
`sections-b/b7-*`, scripts `scriptsB/`. Chain `Fool-v2-018.blend` opened
read-only, never written (mtime unchanged).

## THE ROUND'S KEY CORRECTION — the A2 scaffold is not repairable
A2 reported vertex RMS 0.36 mm. Measured before touching it (`b0-diag.json`,
`renders-b/b0-*`):

| A2 `Fool_HeadRetopo_draft` | measured |
|---|---|
| face-centroid deviation vs sculpt | **RMS 7.12 / p95 12.0 / max 62.6 mm** |
| faces with normals inverted vs sculpt | **650 / 2616 (24.8%)** — 154/412 in the face |
| self-intersecting face pairs | **3510** |
| degenerate / sliver faces | 8 / 302; one zero-length edge; longest 174 mm |
| eye globes covered by the retopo | **54%** |

**Why the A2 number missed it:** nearest-surface Shrinkwrap pins every *vertex*
to the target, so vertex-only deviation is ~0 *by construction* even when the
faces between them fold, overlap and invert — a vertex-only RMS is structurally
incapable of seeing this. I instrument three things from here on and recommend
the run do the same: vertex deviation (gate-comparable), **face-centroid
deviation**, and **inverted-normal + self-intersection counts**. The face was
shredded, not rough; nothing was repairable. I took the brief's own sanctioned
path ("if both fail inspection, the loops are built manually on a Shrinkwrap'd
grid — report, don't stall").

## Method (what replaced it)
Graded cube-sphere with explicit **(chart, i, j)** bookkeeping -> ray-fit from a
per-height spine + relax/snap -> feature footprints cut as **true combinatorial
rectangles** -> rebuilt as concentric rings, one-to-one bridged. Row spacing is
solved by iterated inversion so rows land on the drawn feature heights. The
front/side chart seam is a regular grid line, so the orbital rectangle spans it
and stays a rectangle — each hole costs exactly **four valence-5 poles at its
far corners, none near the aperture**.

## Gates (measured on the SAVED `Fool-v2-019b.blend`)
| Gate | Required | Measured | |
|---|---|---|---|
| Deviation vs sculpt, excl. named divergences | <=1.5 RMS / <=3 max | **0.182 RMS, p95 0.423, max 0.976 mm** (1079 v) | PASS |
| Quad-dominant | >=95% | **99.80%** (1983 quads, 4 tris, 0 n-gons) | PASS |
| X symmetry | exact | 2056/2058 verts exact; 2 near-midline mouth verts 0.067 mm off | PASS |
| Full eye / mouth encirclement | required | eye 4 rings x 38 v; mouth 3 rings x 32 v + 30-v seam | PASS |
| >=2 loops exiting each mouth corner | required | **2** (corner is a regular valence-4 vertex) | PASS |
| No poles at mouth corners / inner canthi | required | nearest pole **21.6 mm** away; 0 within 10 mm | PASS |
| Lid rim clears the globe | ~1.3 mm | **1.50 mm** at the visible lid edge; 0 verts inside either globe | PASS |
| Cleanly bounded | required | 148 boundary edges = neck 72 + 2 hidden eye rims (38 ea); **0 non-manifold** | PASS |
| Inverted faces, excl. divergences | 0 | **0** | PASS |
| Eyes stay separate | required | `Fool_Eye_L/R` untouched, 1986 v each, r 35.000 mm | PASS |
| Tri count | 4–8k working est. | **3970** (2058 v / 1987 f) | 30 UNDER |

Poles **32** = 4 shell corners + 4 per feature hole (2 eyes, 1 mouth, 2 ears)
+ 4 per concha Coons cap; all >=21.6 mm from any forbidden site.

## Deliberate divergences (each named, measured, rendered)

1. **Orbital + lids — RMS 1.82, p95 4.60, max 5.11 mm** (436 v). The lead's
   recorded ruling: the orbital builds forward/outward to the drawn front width
   at eye rows. The lid rings therefore clear the r=35 mm globes rather than
   diving into the sculpt's socket bed. Aperture built to the drawn extents
   exactly: **x 22.0…79.0, z 1545.3…1589.8** (both sides identical).
   Rendered: `b7-final-face-closeup.png`, `b7-sub-three-quarter.png`,
   `sections-b/b7-z1.580.png` (cyan bridges the red socket dips).
2. **Ear simplification — RMS 4.38, p95 11.40, max 21.37 mm** (426 v). Brief:
   helix + concha only. The sculpt's thin fused flap becomes an elliptical helix
   rim (silhouette **|x| 116.7 mm** vs the sculpt's 114.65) over a concha bowl,
   rim rise tapered front->back so the widest point sits at y ~ +72 mm as the
   sculpt does. Rendered: `b7-final-side.png`, `b7-sub-three-quarter.png`.
3. **Mouth rings — RMS 0.69, max 3.79 mm** (117 v). The R14 debt: one crisp
   gentle-smile line, seam **63.7 mm wide at z 1493.5**, real lip volume
   (vermilion proud 1.3 mm over a recessed 2.6 mm seam). `b7-sub-face-closeup.png`.
## Per-defect verdict
1. **Eye apertures — GOOD.** Open almonds on the drawn extents; proud upper-lid
   edge (1.7 mm) with the fold above it (2.2 mm); restrained lower lid; hidden
   rims rolled 0.30 rad back around the globes so the sockets close around them.
   Canthi regular (no poles).
2. **Mouth ring — GOOD, the clearest win over R14.** Concentric rings, two
   loops out of each corner, corners regular valence-4. It reads as one clean
   pair of lips in the subdivision preview — R14 could not get this.
3. **Ear region — ACCEPTABLE.** Simple helix + concha, symmetric, watertight,
   silhouette on the sculpt's. From three-quarter it reads as an ear; from
   straight-on side it is frankly a rim-and-bowl, not an ear with an antihelix.
4. **Max-deviation sites — CLOSED.** A2's 9.95 mm cranium / 6.19 mm face
   outliers do not exist here: max 0.976 mm outside named divergences. The
   z ~ 1.51 sculpt terrace is **not** reproduced — smooth topology runs through
   it (`sections-b/b7-z1.520.png`, `b7-final-side.png`).
5. **Neck seam — PROPOSED.** Planar ring at **z = 1.442 m**, 72 v, circumference
   332.7 mm, flat to 3e-5 mm; above the shoulder flare (z 1.42 catches
   trapezius). 72 v is denser than the face cells — a later body retopo may want
   a reduction ring; lead's call.
6. **Pole hygiene — GOOD.** 32 poles, all structural, none within 21.6 mm of a
   mouth corner or inner canthus.

## What would not read well / honest misses
- **22 self-intersecting face pairs, all in the orbital/lid band** where the lid
  edge rolls back to the hidden rim around the globe. Behind an opaque globe and
  invisible, but real; I am not calling them clean.
- **The nose is soft.** Not one of my six owned defects, and the sculpt's nose
  is gentle — but at ~10 mm cells with two grid columns either side of the
  midline it reads as a low ridge, not a tip with wings. Denser midline
  x-grading would fix it; I did not spend the round there.
- **3970 tris is 30 under the 4–8k working estimate.** The base spends 5/6 of
  its faces off the face chart; centring the budget wants a denser front chart,
  not padding elsewhere.
- **The lower lid is near-absent** in the front view. That is the brief ("lower
  lid restrained") but it sits at the edge of reading as no lower lid at all.
- The hidden inner rim sits **0.8 mm** off the globe, below the 1.3 mm guide —
  deliberate (it must hug the globe to stay occluded) and rotation is unaffected
  (a sphere spun about its centre sweeps no new volume), but it is not 1.3 mm.
- **Two mouth-region vertices sit 0.067 mm off the midline plane**; everything
  else is exact by construction.

## Protocol
Headless `blender --background` only; GUI never launched, port 9876 never
touched; one Blender at a time; `scriptsB/gov.sh` (slots -> PAUSE poll,
loadavg < 6, temp < 90 C, refuses a second Blender) before every invocation;
nothing written outside the workdir; the chain file was opened and saved-as
elsewhere, never written.
