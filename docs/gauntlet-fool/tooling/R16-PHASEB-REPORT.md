# R16 Phase B — body retopo (Opus builder report, transcribed by lead)

**Final candidate:** `Fool-v2-020g.blend` (workdir fool2-r16), object
`Fool_BodyRetopo` (a…f = internal iterations). Validation:
`r16-b-validation.json` (verify_body.py re-run on the SAVED g). Renders:
`renders-b/g-*.png` (23 REAL wire-over-shaded from scriptsB/render_wire.py +
19 from the round rig). Chain untouched (mtime/size verified; libraries.load
only — never opened as a main file).

## Headline gates (from the saved file)
- Deviation EXCLUDING the named divergence: **0.160 mm RMS / p95 0.391 /
  max 1.063 mm** (3,911 v) — PASS. Whole mesh: 1.847 RMS / max 18.14 mm;
  face-centroid 2.231 RMS / max 24.33 mm.
- Quad share **100.0%** (4,562 quads, 0 tris, 0 n-gons). **9,124 tris**
  (4,599 v) — inside the 8–16k budget.
- Neck seam **0.00069 mm** max over the 72 ordered head-ring positions.
- Webbing probes **28/32**; all 4 failures thumb–index at u ≥ 0.5
  (instrument geometry — see findings).
- Self-intersections **0**. Mirror residual **0.000000** (0 offenders).
- Boundary 72 edges = ONE loop (the neck seam); non_manifold count 72 =
  those same boundary edges (bmesh quirk) — 0 real non-manifold.
- Poles **186**, all accounted (72 neck boundary + 36 reduction band + 40
  digit-tip caps + 12 palm split + 8 armhole + 8 thumb-hole + 8 toe-cap
  corners + 2 pants junction); **0 within 15 mm of any crease** (nearest
  16.99 mm). Sole 144 v at exact z=0. Inverted normals 129 — all inside the
  digit/thumb divergence, zero elsewhere.

## The one named divergence — the hand (forced, not stylistic)
Probing the sculpt directly: **the four fingers are FUSED.** The palmar
surface is one continuous sheet across all four digits at x = 700/715/730/
745 mm; first real gaps at x ≈ 770. At the ring finger's u=0.14 station the
axis sits 16.6 mm inside solid material. Phase A's clearances (2.90/2.08/
1.66 mm) came from the HandShell_* boolean helpers, not the merged surface —
true clearance there is ZERO. The open-web ruling therefore required
hollowing a mitten into separate digits: digit 4.636 RMS / 18.141 max
(584 v), thumb 4.342 / 11.868 (98 v), web 14.050 / 16.971 (6 v). The
pre-authorized armpit/crotch simplifications were NOT needed (crotch chain
0.003 mm, torso 0.058, neck 0.114, arm 0.160, leg 0.182, foot 0.232, palm
0.020, toe cap 0.053).

## Honest non-passes / weaknesses
1. Raw whole-mesh deviation (1.85 RMS / 18.1 max) outside the gate; only the
   excluded-divergence figures pass.
2. 4 thumb–index webbing probes fail (argued unpassable by any five-fingered
   hand — corridor near-collinear with the digit axes).
3. One coarse quad band at the shoulder (70–80 mm cells vs ~25 mm elsewhere)
   where the armhole ring (x=192) meets the chest column.
4. Neck reads as a ribbed collar — 72 v around 330 mm = 4.6 mm cells vs 8 mm
   rows; deviation 0.114 mm — a density read inherited from the head's ring.
5. Digit bases blocky (8-sided, ~24×18 mm knuckle sections).
6. One hard facet at trapezius→deltoid (no room for another torso row below
   armhole top z=1402.7).
7. Toe cap spends 40 quads on a blunt fused toe.
8. Deformation untested — loop spec met by construction/ring counts only.

## Instrument findings (into the run's law)
1. **render_body.py wire renders are NOT wireframes** — show_wire/
   show_all_edges are viewport-overlay flags; background renders ignore
   them; every `*-wire.png` is byte-identical to its shaded PNG. Real rig:
   `scriptsB/render_wire.py` (Wireframe-modifier shell, 23 views). Blind
   judging must use the g-*.png set.
2. **Thumb–index probes at u ≥ 0.5 are unpassable by any five-fingered
   hand** — corridor 79° off the index's lateral axis; trimmed far endpoint
   3.26 mm from the index's own axis line. Fix: skip pairs whose corridor is
   within ~30° of either digit axis, or trim by trim/|dir·e_lateral|. The
   three real web pairs pass all 24 probes.
3. **non_manifold_edge_count counts boundary edges** (bmesh is_manifold
   False for 1-face edges). Fix: `not e.is_manifold and not e.is_boundary`.
4. **Phase A inventory bbox for Fool_Eye_L/R is wrong** (matrix_world read
   before depsgraph update after libraries.load → world origin). True
   locations (±43.0, −40.3, 1571.0) mm, matching R15. Do not build the
   YoungAdultMale-base milestone on the inventory figure.
5. Phase A's recorded bend_creases are synthetic (armpit/elbow-pit points
   70–100 mm off the surface; knee-back ~44 mm inside the calf) — the pole
   gate as instrumented is easier than it reads. Real requirement met
   independently: no pole on elbow, knee, armpit, or groin; leg runs 26 v
   hip→toe with no reduction ring.

## Method (authored charts; NO Shrinkwrap anywhere)
Half body (+X), explicit (chart,i,j) slot keys, mirrored by exact coordinate
negation (midline shared) — mirror residual 0 by construction. Ray-fit to
Fool_SculptBase + 3-pass Laplacian relax (λ 0.30) + find_nearest re-snap
(12 mm cap) on ray-fitted rings only; authored seams pinned.
- Neck: head's 72-v ring verbatim (X-symmetric, residual 0), one 72-v row at
  z 1434, then a 2:1 reduction band to the 36-v torso ring at z 1424.
- Torso: 27 rings × 36 columns, z 1424…872.
- Armhole: 6×4 combinatorial rectangle removed; 20-v boundary = planar YZ
  deltoid section at x=192; exactly 4 valence-5 poles at its corners.
- Arm: 21 rings × 20, x 230…718, bridged 1:1, orientation fixed by
  construction.
- Hand: palm's distal 20-v ring splits into four 8-sided digit tubes through
  three shared web vertices (pants junction generalized to four legs; 6
  valence-6 poles/hand, all ≥17 mm from hinges). Thumb: separate 8-sided
  tube swept along a cubic with rotation-minimizing frame seeded from the
  hole's own vertex angles. Tips: 2×2 grid caps.
- Leg: pants junction (19-v hip arc + 7-v resampled crotch chain = 26-v leg
  ring; exactly 2 valence-6 poles, 104/94 mm from the groin crease), 24
  rings z 820…164.
- Foot: 90° circular bend (R=130), 11+2 rings, 8×5 toe-cap grid; sole
  snapped to z=0.
- Loop spec all met: shoulder 4 / elbow 5 / knee 5 / hip 5 / wrist 4 /
  ankle 3+1; finger hinges bracketed at 6 u-stations; torso 27 regular rings.

## Files
Fool-v2-020g.blend (37 MB: Fool_SculptBase hidden, Fool_HeadRetopo,
Fool_Eye_L/R at ±43/−40.3/1571, Fool_BodyRetopo), r16-b-validation.json,
r16-b-devreport.json, Fool-v2-020g-regions.json, renders-b/,
scriptsB/{blib16,build_body,render_wire,dev_report,probe_hand}.py.
