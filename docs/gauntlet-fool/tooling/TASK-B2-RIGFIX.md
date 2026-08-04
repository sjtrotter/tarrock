# TASK — R18 Phase B2: reposition finger bones, then finish TASK-B-RIGFIX (Codex)

Your Phase B stop was CORRECT and the lead confirms the deeper cause: the
phalange bones were placed from R16 `body_axes.json` digit stations — data
captured BEFORE Phase 0 straightened the digits. The bones follow the old
curled axes; the straightened tubes moved out from under them (thumb tube
reaches y=−123.8 mm, bones end at −92.8). That is also why the 023c fist
crumpled: curling bones that sit outside their tubes cannot deform them
cleanly. AUTHORIZATION GRANTED to reposition all 30 phalange bones (15 per
side). Do NOT relax the 15 mm predicate — with correct bones it should pass
as-is.

Base file: still `Fool-v2-023c.blend`. All rules from TASK-B-RIGFIX.md stand
(workdir only, gov.sh, one Blender, one file per invocation, candidates
Fool-v2-023e+, whitelist rendering, smear guard, armhole ring 0.225).

## Bone repositioning (do this FIRST, then the TASK-B fixes in order)

1. Ground truth for the straightened digit axes lives in the SAME file: the
   hidden `backup_BodyRetopo` object is the straightened body with R16
   indexing intact. `validate_one.py` lines 12–21 give every digit's ring
   vertex ids and root-ring ids VALID ON THAT OBJECT (index/middle/ring/
   pinky: 9 rings of 8 from 1991+73*fi, tip s+72; thumb: 6 rings of 8 from
   2283, tip 2331; roots dict). Compute each digit's ring centroids from
   backup_BodyRetopo in world space.
2. Per digit: hinge stations = root centroid (bone 01 head), then place
   01 tail / 02 head-tail / 03 head-tail at the anatomical knuckle stations
   along the ring-centroid polyline — use the ring spacing to pick the two
   interior hinges (proximal ~40% and ~70% of arc length are acceptable if
   no cleaner signal), 03 tail at the tip vertex. Bones must lie INSIDE the
   tube (each head/tail within a few mm of the centroid polyline).
3. Mirror exactly: .R bones = coordinate negation of .L (X only). Keep
   names, parenting (01→Hand, 02→01, 03→02), deform flags, rolls sane and
   mirror-consistent.
4. Verify: every phalange bone's segment-to-tube-centroid max distance
   reported; digit geometric sets from the TASK-B predicate now come out
   ~70–80 verts each, single connected component, inside the hand bbox.
   Report per-digit counts. If a digit still fails, STOP and report.

Then continue exactly per TASK-B-RIGFIX.md: eye swap, weight repair
(restriction on the CORRECT sets), battery re-run with smear guard and
whitelist renders, deliverables (Fool-v2-023e.blend, rig-validation-e.json,
REPORT-B-RIGFIX.md — extend it, renders-e/). Note in the validation JSON
that finger bones moved: include old→new head/tail coordinates per bone.
Rebind is NOT needed globally — automatic weights for non-digit verts were
computed against bones that did not move; digit verts get the phalange
scheme against the NEW bone positions.
