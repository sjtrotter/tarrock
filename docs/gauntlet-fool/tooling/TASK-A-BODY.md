# TASK A — R16 body retopo: inventory, data extraction, instruments (Codex)

You are the Phase-A executor for Round 16 (body retopo) of the Tarrock Fool
gauntlet. Mechanical work only — no retopo judgment. Work ENTIRELY inside
`/home/betty/tarrock-gauntlet-work/fool2-r16/` (your workdir). The chain file
`/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-019.blend`
is READ-ONLY: open it with `blender --background <file> --python <script>` and
NEVER save over it (no bpy.ops.wm.save_mainfile without a new filepath; you do
not need to save any .blend in this task).

MACHINE PROTOCOL (mandatory): launch every Blender run through `./gov.sh`
(already in the workdir) — it polls the governor (PAUSE → 15 s), checks
loadavg < 6 and temp < 90 C, and refuses a second Blender. One Blender process
at a time, sequential runs only.

Conventions: 1 unit = 1 m, character faces −Y, X is the mirror axis, soles at
Z=0. Report all distances in mm. The figure is in T-pose (arms out along ±X).

## Deliverables (all into the workdir)

1. **inventory.json** — every object in the .blend: name, type, vert/face
   count, bounding box (mm). Confirm `Fool_SculptBase` is watertight (0
   boundary edges, 0 non-manifold) and record its Euler characteristic.
2. **neck_ring.json** — `Fool_HeadRetopo`'s boundary loops. Expect 3: one
   72-v neck ring near z=1.442 m and two 38-v hidden eye rims. For the neck
   ring output the ORDERED loop of vertex coordinates (mm), its centroid,
   mean radius, and z min/max. Error out loudly if the boundary structure
   differs from expectation.
3. **body_axes.json** — per-segment axis polylines + cross-sections of
   `Fool_SculptBase` (sample the sculpt, e.g. via z/x slabs and centroid
   chains):
   - torso: horizontal sections every 20 mm from crotch apex to the neck seam
     z=1.442 (section outline as ~64 resampled points each);
   - each leg: sections every 20 mm from sole to crotch (per-leg centroid
     axis; note the crotch apex z);
   - each arm: the arms run out along ±X — sections in YZ planes every 15 mm
     from the deltoid to the wrist; record the shoulder-crease and wrist x;
   - each hand: identify the 5 digit axes (the digits are fanned in plan);
     per digit: root/tip coordinates, length, mean radius, and 3 sections;
     record the MINIMUM inter-digit clearance per adjacent pair (mm);
   - feet: report whether the sculpt has separate toes or a single foot mass
     (inspect sections at z < 40 mm; render a top view of one foot as
     evidence renders/a-foot-top.png).
4. **verify_body.py** — the round's independent verification instrument,
   adapted from `/home/betty/tarrock-gauntlet-work/fool2-r15/scriptsB/b8_verify.py`
   (read it). Given a candidate .blend path and object name (default
   `Fool_BodyRetopo`) it must measure and write JSON:
   - vertex deviation vs `Fool_SculptBase` (RMS/p95/max mm) AND
     face-centroid deviation (the R15 lesson: vertex-only RMS is blind to
     folded faces);
   - inverted-normal count vs the sculpt (nearest-surface normal dot < 0);
   - self-intersecting face-pair count with sample sites (BVH overlap minus
     adjacency, as b8 does);
   - mirror residual (max mm + offender count);
   - quad/tri/n-gon counts and quad share;
   - boundary-edge count and non-manifold count;
   - neck-seam check: for each of the 72 head neck-ring verts, distance to
     the nearest candidate boundary vert (report max, gate ≤ 0.01 mm);
   - finger-webbing probes: build a probe set from body_axes.json digit
     pairs (midpoints between adjacent digits at 8 stations per pair); a
     probe fails if a ray between the two digit surfaces crosses fused
     geometry — report pass/fail count;
   - pole census: verts with valence ≠ 4 (count + coordinates of any within
     15 mm of the recorded bend creases: armpit, elbow pit, knee back, groin
     crease, finger hinges — creases estimated from body_axes.json).
5. **render_body.py** — headless render rig for candidates: front / back /
   side / three-quarter full-figure plus zooms (hand top, foot, shoulder,
   knee, neck-seam), each in shaded AND wireframe-over-shaded. Reuse the
   framing/light conventions of
   `/home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/presence_render.py`
   and head_render.py (read them). Prove it runs by rendering the SCULPT
   (no candidate exists yet) to renders/a-*.png.
6. **selftest**: run verify_body.py against `Fool_HeadRetopo` itself (it will
   "fail" gates like neck-seam-vs-itself trivially — the point is every
   instrument executes and returns sane numbers; webbing probes may be
   skipped for the head). Save output as selftest-verify.json.
7. **REPORT-A-BODY.md** — what you measured, any surprises (toes? asymmetries?
   digit clearances vs the 4 mm the sculpt was built with), instrument
   validation status, and anything the Phase-B builder must know. Honest
   partials beat overreach: if a sub-item defeats you, say so plainly in the
   report rather than faking a number.

Do NOT modify anything under /home/betty/Projects/tarrock. Do NOT open the
Blender GUI. Sequential Blender runs through ./gov.sh only.
