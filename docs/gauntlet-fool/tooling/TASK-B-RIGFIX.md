# TASK — R18 Phase B: weight repair + corrected battery (Codex, cycle 2)

The lead diagnosed Phase A's candidate. THE ROOT CAUSE, confirmed: your
`fix_finger_weights.py` applied R16 BODY vertex-index ranges (1991+73*fi,
2283–2331) directly to the joined `Fool_Mesh` — but the join REINDEXED
vertices (head occupies 0..2133; body verts are offset and 72 were merged).
Those stale indices hit ~394 head/neck vertices (the thumb range landed on
the neck seam at z=1442): their real weights were wiped and replaced with
finger-bone weights. Result: the giant X-shaped streaks beside the head in
the a45/a80 renders (neck verts flying 440–1000 mm with the thumb bones),
the bars across the finger renders, AND a torn neck collar. Diagnostics:
`lead-smear.json` (worst offenders + group histogram), `lead_diag_smear.py`
(the instrument), `lead-check.json`. Additionally your shoulder ring at
|x|=0.289 measured the RIGID ARM (trivially passes); the true armhole ring
at |x|=0.225 loses 10.0% at 45° and 18.3% at 80°.

023d is DISCARDED. Base = `Fool-v2-023c.blend` (pre-corruption weights,
identical topology, all static gates green). Workdir rules as before: work
only here, ./gov.sh for every Blender run, ONE Blender, ONE file per
invocation (the double-load rename trap), save candidates Fool-v2-023e+.
Chain and repo are READ-ONLY.

## Fix 1 — eye side naming (lead ruling, apply exactly)

The body convention is `.L` = character's left = +X (Foot.L is at +0.135).
The eye bones are swapped: Eye.L sits at −X. Fix by SWAPPING names so
anatomy is consistent everywhere:
- Bones: Eye.L ↔ Eye.R (after swap, Eye.L head at +0.043).
- Globe objects: Fool_Eye_L ↔ Fool_Eye_R (after swap, Fool_Eye_L at +X).
- Re-point each globe's parent_bone to its same-position bone; globe world
  transforms unchanged (≤0.001 mm) and each globe still rotates about its
  own center. Eye bones stay children of Head, deform=False.

## Fix 2 — finger weights, done right (this is the piece you have failed
once; a second miss escalates it away from you)

On the 023c weight state:
1. Compute the TRUE digit vertex sets GEOMETRICALLY on Fool_Mesh: for every
   vertex, distance to every deform-bone segment; a vertex belongs to digit
   D iff its nearest bone is one of D's phalanges AND that distance is
   < 15 mm AND the vertex lies inside the hand region (derive a bbox from
   Hand + phalange bone endpoints + 25 mm margin). Sanity: per digit expect
   ~70–80 verts forming a connected tube; REPORT the counts and the bbox of
   each set; if a set contains any vertex outside the hand bbox, STOP —
   your set is wrong.
2. Remove finger-bone weights ONLY from verts outside the digit sets that
   carry them (auto-weight bleed), renormalize those verts.
3. Within each digit set, apply the phalange scheme (two nearest phalanges,
   1/d^4, normalized — your 023d scheme, correct verts this time). Blend
   smoothly at the digit root: verts within 5 mm of the root ring blend
   50/50 with their prior Hand-bone weights.
4. Palm/web verts (not in digit sets) keep 023c auto weights.

## Fix 3 — battery instrument corrections (permanent)

- Render visibility by WHITELIST: hide_render=True for EVERYTHING except
  Fool_Mesh, the two globes; never blacklist (new law after this round).
- Armhole ring at |x|=0.225 (keep 0.289 as a secondary if you like).
- SMEAR GUARD (mandatory, every pose in the battery): the lead_diag_smear.py
  bound — no vertex may displace more than the chord its distance to the
  rotating joint allows (+20 mm); flagged count must be 0 in EVERY pose.
  This gate exists because your report claimed all renders were reviewed
  while the evidence showed 440 mm streaks — automate what eyes missed.

## Then: full battery re-run on the fixed candidate

All poses from TASK-A-RIG.md step 4 (shoulder 45/80 with front/back/tq +
shoulder zoom, fingers 60°×3 top/palm-tq/front, eyes ±20° (report the
static clearance once — a sphere about its center is invariant), neck
down/up/turn, elbow90/knee90/hip45). Renders to renders-e/. Report the
armhole area losses at 0.225 and describe the armpit/deltoid read honestly.
For the fist: state plainly whether the curl now reads as a clean stylized
fist (knuckle volume, no web tearing, no collapse). If it does not, render
close-ups of the worst area and STOP — hand topology changes are a lead
decision.

## Deliverables

Fool-v2-023e.blend (rest pose; b/c letters if you iterate),
rig-validation-e.json (all gates incl. smear guard counts, digit set counts,
eye swap evidence, armhole numbers), REPORT-B-RIGFIX.md (honest), renders-e/.
Static gates must be re-verified on the final candidate (verts 6661,
self-int 0, rest identity, mirror, sole z=0, neck seam intact).
