# R18 BRIEF — rigging proper (5th lead, 2026-08-04)

Phase 0 (finger straightening) closed on chain Fool-v2-022.blend. This brief
covers the rigging round itself, per the 4th lead's handoff (ROUND-STATE §R18
HANDOFF) adopted as lead rulings.

## Lead rulings (recorded before launch)

1. **Custom deform-only armature, authored programmatically** (handoff
   recommendation adopted; no Rigify — avoids control-rig export mess, fits
   the run's authored-and-instrumented method). Deform bones only, no
   constraints, armature object transform = identity.
2. **Bone set (Unity Humanoid-compatible, 53 bones), Blender `.L`/`.R`
   suffixes** (Unity's Humanoid mapper handles them; Blender symmetry tools
   need them):
   - Core: Hips, Spine, Chest, Neck, Head
   - Eyes: Eye.L, Eye.R (bone head AT the globe center ±43/−40.3/1571 mm;
     globes BONE-PARENTED, never skinned — director ruling)
   - Per side: Shoulder, UpperArm, LowerArm, Hand; Thumb.01–03, Index.01–03,
     Middle.01–03, Ring.01–03, Pinky.01–03; UpperLeg, LowerLeg, Foot, Toes
3. **Head-body JOIN at skinning time** (R16 ruling): merge-by-distance the 72
   vertex-exact seam pairs → one mesh `Fool_Mesh` (6,661 v expected);
   originals kept as hidden backups in-file.
4. **Skinning:** automatic weights + cleanup (limit 4 influences, normalize,
   prune <0.001, no cross-limb bleed). Judged by pose-test renders —
   geometry-space numbers + eyes-on, per the run's law.
5. **Pose-test battery is the round's gate.** The shoulder test (−45°, −80°
   arm-lower) ADJUDICATES the R16 shoulder/armhole debt: if it pinches,
   armhole rework happens before weights count as done. Finger 60° hinge
   curls, eye aim ±20°, neck nod/turn, elbow/knee/hip bends complete the
   battery.
6. Naming: candidates `Fool-v2-023a+` in fool2-r18/; promotion target chain
   `Fool-v2-023.blend`. Executor = Codex (tightened regime); Opus only after
   two Codex failures on a round-blocking piece, justified in ROUND-STATE.

## Phases

- **Phase A (Codex):** join + armature + bind + rest-pose gates + full pose
  battery with renders. Task: fool2-r18/TASK-A-RIG.md.
- **Lead validation:** independent instrument re-run on the saved candidate,
  eyes-on all pose renders.
- **Blind judge (Codex, fresh):** pose renders vs sheet; adjudicates the R16
  shoulder debt.
- Fix cycles as needed; promote; STATUS push.

## Debts this round owns / touches

- Shoulder/armhole deformation risk (R16) — adjudicated here.
- Socket clearance 1.09→1.45 mm vs 2 mm suggestion (R14) — eye-aim test
  adjudicates.
- Neck density collar (R16) — neck-bend renders inform, dressed re-judge owns.
- Mouth/lower-face corner retopo stays with blend-shape/materials work, NOT
  here (R17 close).
