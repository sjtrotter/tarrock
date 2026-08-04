# TASK — R18 Phase C: thumb-base girth + thenar eminence (Codex, geometry)

DIRECTOR DEFECT (logged in ROUND-STATE): on the current body the THUMB is
too thin at its base and there is no thenar eminence — the palm-side 'ball'
at the thumb root. Both the character read and thumb opposition need that
mass. This is a GEOMETRY fix on `Fool_Mesh`, done now because re-deriving
thumb weights is cheap before weight polish.

Base file: /home/betty/tarrock-gauntlet-work/fool2-r18/Fool-v2-023f.blend
(current best: repaired rig, patched weights — treat everything outside the
hand regions as FROZEN). Candidates Fool-v2-023g+ here. Standing rules:
workdir only, ./gov.sh, ONE Blender, one file per invocation, whitelist
renders. References (read them, eyes-on): the hand cutout on
/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png
and ~/Downloads/Fool-Orthographic-Hand-Boot-Ref.png. Style law (director):
restraint — a young-adult storybook hand, not an anatomy chart; the sheets
govern the read, not millimetre exactness.

## The edit (MOVE VERTS ONLY — no topology change; if you conclude a real
cut is unavoidable, STOP and report instead)

Per hand (+X first, then exact mirror by coordinate negation):
1. THUMB BASE GIRTH: thicken the thumb's proximal segment (root ring →
   ~40% of length) radially about its straightened axis — target a base
   that tapers naturally from a fuller root (use the sheet hand cutout;
   the current root is visibly too thin vs its drawn counterpart). Keep
   the ring axis STRAIGHT (Phase-0 gate: ring-center lateral deviation
   < 0.8 mm) and the tip untouched.
2. THENAR EMINENCE: build the palm-side mound between the thumb root and
   the wrist — a soft convex 'ball' rising from the palm surface, peak
   height judged against the ref sheets (typically ~⅓ of palm thickness),
   blended C-smooth into palm and wrist (no ridge lines, no plateau —
   remember the run's curvature lessons: the eye reads the normal).
3. Re-check finger webs: the edit must not close the thumb–index gap —
   minimum thumb–index surface clearance must stay ≥ 2.0 mm and every
   other inter-digit clearance non-decreasing.

## After the edit (rig upkeep, machinery exists in repair_r18b2.py /
lead_patch_023f.py — adapt, do not re-derive from stale data)

4. THUMB BONES: recompute the thumb tube ring centroids FROM THE EDITED
   Fool_Mesh (geometric extraction; backup_BodyRetopo is now stale for the
   thumb — do NOT use it for thumb placement). If the axis/stations moved
   more than 1 mm, reposition Thumb.01–03 accordingly (mirror-exact).
5. THUMB + THENAR WEIGHTS: re-run the geometric digit-set restriction for
   the thumb; thenar verts belong predominantly to Hand with a smooth
   Thumb.01 blend toward the root. After ANY weight edit: zero-weight
   verts must be 0.
6. GATES (all, report numbers): topology sha unchanged (vert/face counts +
   connectivity); mirror residual unchanged; self-intersections 0; verts
   outside the two hand bboxes moved 0.000 mm; straightness per digit
   < 0.8 mm; clearances per (3); rest identity ≤ 0.001 mm; smear guard 0
   in every pose AND rigid-lag guard (a80 both arms: hand-region verts
   track the rigid rotation within 30 mm — pattern in lead_patch_023f.py).
7. BATTERY (renders-g/, whitelist): fingers-top, fingers-palm-tq, a80-front,
   elbow90, PLUS thumb evidence: palm-side close-up of each hand in rest
   pose (thenar visible), top view of the hand, and a thumb-curl pose
   (curl Thumb.01–03 60° about the thumb's OWN bend axis — perpendicular
   to the thumb axis in the palm plane, NOT world Y) showing opposition
   toward the fingers. EYES-ON every render; compare against the sheet
   hand cutout and say honestly whether the thumb now reads full-based
   with a thenar ball.

## Deliverables

Fool-v2-023g.blend (h… if you iterate), thumb-validation-g.json,
REPORT-C-THUMB.md (honest), renders-g/. If the mound cannot be built from
existing verts without visible faceting, render the best attempt, say so,
and stop — density decisions are the lead's.
