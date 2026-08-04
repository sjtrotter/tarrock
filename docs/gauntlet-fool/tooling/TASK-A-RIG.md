# TASK — R18 Phase A: armature, join, skinning, pose battery (Codex)

Goal: rig the Fool for Unity. Build a custom deform-only armature, join head
to body, bind with cleaned automatic weights, bone-parent the eyes, then run
the full pose-test battery with renders. Honest reporting: if a gate fails
and you cannot fix it without breaking another gate, say so and stop.

Workdir: /home/betty/tarrock-gauntlet-work/fool2-r18/ (work ONLY here).
Source: /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-022.blend
— READ-ONLY chain head. Objects: Fool_HeadRetopo (2,134 v), Fool_BodyRetopo
(4,599 v, straightened digits), Fool_Eye_L / Fool_Eye_R (spheres r=35 mm,
centers (±0.043, −0.0403, 1.571) m, separate, closed). Hidden backups exist —
leave them alone. Units 1 u = 1 m; character FACES −Y; mirror axis X; soles
z=0; crown z=1.717.

Every Blender run through ./gov.sh (governor+thermal gate, headless, ONE
Blender at a time; if it reports PAUSE, poll every 15 s). Load the chain with
bpy.ops.wm.open_mainfile (36 MB — safe). Save candidates as
Fool-v2-023a.blend (b, c… for fix iterations) HERE. Never write to the repo.
Instrument warning (paid for): any script that library-loads same-named
objects from two files silently renames one — load ONE file per Blender
invocation (see validate_one.py).

## Step 1 — JOIN head to body → `Fool_Mesh`

1. Duplicate Fool_HeadRetopo and Fool_BodyRetopo as hidden backups
   (`backup_HeadRetopo`, `backup_BodyRetopo`).
2. Join the originals into one object named `Fool_Mesh`; merge-by-distance
   ONLY the neck-seam vertices (72 pairs, seam at z=1.442, bonded at
   0.0007 mm — tolerance 0.01 mm, restrict the merge to a selection of the
   seam rings so nothing else can collapse).
3. Gates: vertex count exactly 2134+4599−72 = 6,661; connectivity elsewhere
   unchanged; boundary-edge count drops by exactly the two seam rings (count
   boundaries before/after and account for every one); non-manifold
   (excluding true boundaries) = 0; self-intersections = 0 (BVH pattern from
   validate_one.py); mirror residual ≤ the sources'; eyes/soles untouched.

## Step 2 — armature `FoolRig`

Deform-only, no constraints, no control shapes, armature object transform =
identity. Bone set (53), Blender .L/.R suffixes:

- Hips, Spine, Chest, Neck, Head
- Eye.L, Eye.R — bone HEAD exactly at each globe center (±0.043, −0.0403,
  1.571), tail −Y (pointing out the face), length ~35 mm.
- Per side (.L = +X): Shoulder, UpperArm, LowerArm, Hand; Thumb.01/.02/.03,
  Index.01/.02/.03, Middle.01/.02/.03, Ring.01/.02/.03, Pinky.01/.02/.03;
  UpperLeg, LowerLeg, Foot, Toes.

Joint placement: derive centers from the mesh itself — bend-crease loop-ring
centroids (the R16 loop spec put 4 loops at shoulder, 5 elbow, 4 wrist,
5 hip, 5 knee, 3+1 ankle, 6 hinge stations per digit;
fool2-r16/body_axes.json has section/axis data, digit ring vertex ids are in
validate_one.py). Spine chain: Hips head near the femur-head line
(crotch apex z=0.825), Spine at the waist minimum, Chest at the costal
region, Neck head near the z=1.442 seam, Head tail toward the crown. Place
joints at anatomically sensible interior centers (roughly 45–55% into the
volume front-to-back), document every joint coordinate in the validation
JSON. Fingers: hinge joints at the knuckle loop stations along each
straightened digit axis.

Gates: exactly the 53 named bones; L/R heads/tails mirror within 0.01 mm and
rolls mirror-consistent; every limb bone's axis within a few degrees of the
mesh's limb axis; Eye bone heads exact.

## Step 3 — bind + eyes

1. Parent Fool_Mesh to FoolRig with automatic weights. Eye bones must get NO
   skin weights (mark non-deform for the bind or remove their groups after).
2. Cleanup: limit total influences to 4, normalize all, prune weights
   <0.001.
3. Bleed gates: zero-weight vertices = 0; no vertex weighted to a bone on
   the wrong side of the body (test: verts at x>+0.10 m carry no .R limb
   weights and vice versa); no head-region vertex (z>1.50) weighted to
   arm/leg bones; no foot vertex weighted above the knee.
4. Eyes: bone-parent Fool_Eye_L→Eye.L, Fool_Eye_R→Eye.R keeping world
   transform. Gate: globe world positions unchanged (≤0.001 mm); rotating an
   eye bone must rotate its globe about the globe center.
5. Rest-pose identity gate: with all bones at rest, the evaluated Fool_Mesh
   deviates 0.000 mm from the unbound mesh.

## Step 4 — pose battery (each pose from rest; reset after; renders to
renders/ with the names given; look at EVERY render before declaring done)

Render setup: reuse the workbench studio-light pattern from earlier rounds
(fool2-r16 render scripts / tooling render_body.py lineage); shaded, ~1024px,
plus a wireframe (tooling/render_wire.py Wireframe-modifier pattern) where
named. All posing via pose-bone rotations on a COPY of the file state —
saved candidate stays in rest pose.

1. SHOULDER (adjudicates the R16 armhole debt): rotate UpperArm.L and .R
   down in the coronal plane by 45°, then 80°. Renders per angle: front,
   back, three-quarter (a45-front.png … a80-tq.png). Measure: deltoid/armhole
   cross-section ring area in rest vs posed; report % area loss per angle;
   describe any visible collapse/pinch honestly.
2. FINGERS: curl every digit 60° at each of its 3 hinges (both hands).
   Renders: top + palm three-quarter (fingers-top.png, fingers-palm-tq.png).
   Gate: no collapse, no web tearing, knuckle volume holds.
3. EYES: aim both eyes 20° left, right, up, down (four poses). Render face
   close-up each (eyes-left.png …). Measure min lid–globe clearance at each
   extreme; gate: no lid–globe intersection (clearance > 0).
4. NECK: head nod down 30°, up 20°, turn 45° (three poses; neck+head share
   the rotation naturally — rotate Neck 40% / Head 60%). Renders
   (neck-down.png, neck-up.png, neck-turn.png). Watch the z=1.442 seam and
   collar area; report read honestly.
5. LIMBS: elbow 90° curl, knee 90°, hip 45° forward flex (one side is
   enough). Renders (elbow90.png, knee90.png, hip45.png). Gate: bend loops
   hold volume, no collapse.

Weight-fix iterations are allowed (targeted weight edits, NOT topology
changes); save each iteration as a new candidate letter and re-run the
affected battery item. If the SHOULDER test shows real collapse that weight
edits cannot fix, STOP and report — armhole topology rework is a lead
decision, not yours.

## Deliverables

- Final candidate Fool-v2-023X.blend (rest pose, armature + weights + eye
  parenting; poses NOT baked).
- rig-validation.json: all gate numbers, all joint coordinates, weight
  stats, pose measurements.
- REPORT-A-RIG.md: what was done, gate table, pose-battery verdicts (honest
  — name the weakest deformation on the model), open problems.
- renders/ as specified. EYES-ON law applies.
