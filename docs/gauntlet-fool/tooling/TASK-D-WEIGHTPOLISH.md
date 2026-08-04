# TASK — R18 Phase D: weight polish (Codex; blind-judge critique attached)

The rig's mechanics are green but a fresh blind judge scored deformation
4/10 and named production blockers. His full critique, verbatim, is your
target list:

> Biggest gap: the hand/finger rig. Curled fingers collapse into angular
> hooks, intersect or stack through one another, and lose believable
> knuckle/palm volume. The thumb's opposition produces a pinched,
> detached-looking base instead of rotating through the thenar area.
> Cleaner joint placement and redistributed weights could improve them
> substantially without adding geometry. Must fix: (1) finger joint axes/
> spacing/weights to prevent self-intersection and hinge collapse;
> (2) thumb base/opposition; (3) shoulder/armpit weighting — at 80 the
> shoulder becomes a hard squared shell while the armpit caves into a deep
> notch; upper arm should inherit more clavicle/torso influence with
> smoother volume transfer; (4) elbow 90 has a sharp tubular corner and
> inner-elbow pinching. Neck is reasonable; neck-to-torso seam scalloped.

Base: Fool-v2-023j.blend (do NOT touch geometry — weights and, for fingers
only if needed, bone roll/axis adjustments; NO bone position changes
outside fingers, NO topology changes). Candidates Fool-v2-023k+.
Standing rules: workdir only, ./gov.sh, one Blender, one file per
invocation, whitelist renders, honest report.

## The work

1. NEW INSTRUMENT FIRST — posed self-intersection: count BVH face-pair
   self-intersections of the EVALUATED (posed) mesh for each battery pose
   (rest count is 0). Record the baseline for: fingers 60x3, thumb own-axis
   60x3, a80, elbow90, knee90, hip45, neck-turn. These counts and the
   renders are your before/after evidence.
2. SMOOTH HINGE TRANSITIONS: today's digit weights are hard per-phalange
   (1/d^4, two bones) — near-rigid segments meeting at sharp hinges.
   Redistribute so each hinge blends across its flanking rings (classic
   50/50 at the hinge ring falling to 100/0 one ring out; tune by eye).
   Same treatment at wrist. Target: curls read as bending flesh, volume
   at knuckles, and posed self-intersections at fingers 60x3 go to ~0.
3. THUMB/THENAR: blend Thumb.01 influence smoothly through the thenar
   mound (currently Hand 72-90%) so opposition rotates the ball with the
   thumb instead of tearing away from it. Judge target: no pinched
   detached base in the thumb-curl render.
4. SHOULDER/ARMPIT: at 80 lower, soften the squared deltoid shell and the
   armpit notch — give upper-deltoid verts partial Shoulder/Chest
   influence with a smooth gradient (the armhole ring area-loss at
   |x|=0.225 may INCREASE modestly if the visual improves; report it,
   the render is the gate).
5. ELBOW: smooth UpperArm/LowerArm transition across the 5 bend rings;
   soften the outer corner, reduce inner-crease pinch (judge: "usable
   only marginally").
6. Iterate build → pose → render → LOOK; save iterations as new letters.

## Gates (report all)

- Geometry/topology sha unchanged; rest identity ≤ 0.001 mm; mirror
  weight symmetry (L/R weight maps mirror within 1e-4); zero-weight
  verts 0; max 4 influences; normalized.
- Smear guard 0 AND rigid-lag guard ≤ 30 mm in every pose.
- Posed self-intersections: fingers pose reduced to ≤ 4 pairs (from
  whatever baseline you measure), no pose worse than its baseline.
- Eyes/head/neck-seam statics untouched.

## Deliverables

Fool-v2-023X.blend final, weightpolish-validation.json (baselines +
finals for every gate), REPORT-D-WEIGHTS.md (honest, per-target verdict
vs the judge's four fixes), renders-k/: full battery (a45/a80 front+zoom,
fingers top/palm-tq/front, thumb-curl both, elbow90, knee90, hip45,
neck set, rest T-pose front/back) — every render eyeballed.
