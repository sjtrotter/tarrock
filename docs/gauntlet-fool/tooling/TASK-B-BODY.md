# TASK B — R16 body retopo build (Opus builder)

You are the Phase-B builder for Round 16 of the Tarrock Fool gauntlet: retopologize
the body of `Fool_SculptBase` into a clean, rig-ready, quad-dominant game mesh
`Fool_BodyRetopo` that bonds vertex-exact to the existing head retopo. Judgment
work — chart layout and loop placement are yours. Workdir (work ONLY here):
`/home/betty/tarrock-gauntlet-work/fool2-r16/`.

READ FIRST (in order):
1. `/home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R16-BRIEF.md`
   — the round brief; its lead rulings bind you (method, budget, gates).
2. `/home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R16-PHASEA-REPORT.md`
   — Phase-A findings (neck ring at Z=1442 centroid Y=+21.104 mm, digit
   clearances down to 1.657 mm, single-mass feet, crotch apex Z=825 mm).
3. `/home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R15-PHASEB-REPORT.md`
   — the head builder's method (graded charts, (chart,i,j) bookkeeping,
   combinatorial rectangles, ray-fit + relax/snap). REUSE this approach; its
   scripts are at `/home/betty/tarrock-gauntlet-work/fool2-r15/scriptsB/`
   (blib.py etc. — read for patterns, adapt freely).
4. Workdir data: `body_axes.json` (section outlines + digit axes),
   `neck_ring.json` (ordered 72-v target ring), `inventory.json`,
   `verify_body.py` (the round's independent gate instrument — run it, don't
   reimplement it), `render_body.py` (candidate render rig).

## Source access (CRITICAL, discovered in Phase A)

This Blender 5.2 build TERMINATES when the 916 MB chain file
`/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-019.blend`
is opened as the main file. Instead APPEND the datablocks you need
(`Fool_SculptBase`, `Fool_HeadRetopo`, `Fool_Eye_L`, `Fool_Eye_R`) from it as
a library into a fresh scene (see `extract_body.py` in the workdir for the
working pattern). The chain file is READ-ONLY — never write it, never
save_mainfile over it. Nothing outside the workdir is writable.

## Deliverable

`Fool-v2-020a.blend` (b, c… for internal iterations; the LAST candidate is
what the lead validates) in the workdir, containing: `Fool_BodyRetopo` (the
new body), `Fool_HeadRetopo`, `Fool_Eye_L/R` (all three untouched — verify
byte-count/vert-count unchanged), and `Fool_SculptBase` (kept for
validation; may be hidden). Body and head stay SEPARATE objects this round —
the bond is positional (vertex-exact ring), the actual join happens at
rigging. Plus `REPORT-B-BODY.md` + renders + your final
`verify_body.py` output JSON (`r16-b-validation.json`).

## Binding constraints (from the brief — failures are send-backs)

- Authored graded charts; Shrinkwrap only as a local fitting aid and any
  wrap step must immediately pass the full instrument suite (verify_body.py).
- Budget: body 8–16k tris.
- Neck: body's top boundary = 72 verts, each ≤0.01 mm from the head ring's
  ordered positions (ring centroid Y=+21.104 mm — not centered on Y=0).
  Density-reduction rings BELOW the seam, not at it.
- Hands: five digits, each individually enclosed; knuckle support loops at
  every hinge; webs stay OPEN (measured clearances: index–middle 2.902,
  middle–ring 2.079, ring–pinky 1.657 mm — the webbing probe gate must pass).
- Feet: single fused toe-mass exactly as sculpted; sole planar at Z=0.
- ≥3 ring loops through each of: shoulder, elbow, knee, hip crease; wrist +
  ankle rings; regular torso loops. NO pole within 15 mm of a bend crease
  (armpit, elbow pit, knee back, groin, finger hinges).
- Deviation vs sculpt ≤1.5 mm RMS / ≤3 mm max EXCLUDING named divergences
  you own (armpit/crotch simplification, inter-finger cleanup, seam
  blending) — name, measure, and render each one in the report.
- Quad share ≥95%; X-mirror exact (build half + mirror is the sane path;
  note the neck ring itself is X-symmetric — confirm before assuming);
  cleanly bounded: ONE boundary loop (the neck ring), 0 non-manifold,
  0 self-intersections (or occluded/named like R15's lid band), 0 inverted
  faces outside named divergences.

## Method requirements

- EYES-ON every internal cycle: run `render_body.py` on the candidate and
  actually look at the wire-over-shaded renders before iterating. The run's
  paid-for law: geometry-space numbers + mandatory builder eyes-on; scalar
  gates alone are blind.
- Run `verify_body.py` on every saved candidate; the final candidate's JSON
  goes in the report. If an instrument looks wrong, say so in the report —
  do not silently patch it (note what you'd change).
- The sculpt is stylized-simple (storybook): loop flow should serve
  DEFORMATION first, surface detail second. Do not invent anatomy the
  sculpt doesn't have.

## Machine protocol (mandatory)

Every Blender run goes through `./gov.sh` (governor PAUSE poll, loadavg,
thermal, single-Blender refusal). ONE Blender process at a time, sequential.
No GUI. Headless `blender --background --python` only (empty/fresh scene +
library append; NOT the chain as main file). Honest partials beat overreach:
if a gate cannot be met, deliver the best candidate, state plainly what
fails and why.
