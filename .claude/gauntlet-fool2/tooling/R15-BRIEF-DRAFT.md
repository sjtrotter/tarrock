# Round 15 DRAFT — head retopo (kickoff pending research phase)

Lead skeleton, 2026-08-03, written at R14 close. Final brief after the research
report lands. Workdir: `/home/betty/tarrock-gauntlet-work/fool2-r15/`.

## Fixed inputs (decided)
- Source: chain `Fool-v2-017.blend` — body `Fool_SculptBase` 1,012,055 v
  watertight; separate `Fool_Eye_L/R` spheres r = 35 mm at (±43, −40.3,
  1571) mm; head region z ≥ ~1.40; conventions 1 u = 1 m, faces −Y, X mirror.
- The retopo mesh OWNS these R14 debts: eye read (open almond aperture, heavy
  upper-lid line — proper eye loops), mouth read (one crisp line — proper lip
  loops), off-midline cheek/jaw wedge (plan-section instrument in tooling:
  seclib.py / w0_sections.py), jaw band z≈1.485 (new topology supersedes it).
- Rig-ready: edge loops must support eyelid + jaw + mouth animation; eyeball
  spheres stay separate (own bones later).
- Style bar unchanged (stylized-simple wins; the sheet's head crops govern).
- LEAD RULING (industry-standard, logged per charter): full-character game
  budget class ~25–40k tris (PC + mobile URP); head share TBD by research.
  Refine, don't treat as canon.

## Research phase decides (TBD until then)
- Method: manual poly-build vs template-head shrinkwrap vs auto (Quad
  Remesher / Blender remesh) vs hybrid; addon installs are charter-allowed.
- Template source if wrap: which clean animation head topology (license!).
- Poly budget split + loop spec (eye rings, mouth rings, jaw line).
- Whether body retopo (R16+) shares the method.

## Process
- Research: background Claude agent (web), report to workdir then tooling.
- Build phases: executor per regime (Codex default for mechanical wrap/bake
  passes; Opus where loop-placement judgment dominates — placement of face
  loops is judgment work, apply the R13 escalation lesson at kickoff).
- Gates draft (finalize at kickoff): silhouette deviation retopo-vs-sculpt
  bounded (value from research); quad-only or quad-dominant; symmetric in X;
  loops present around eyes/mouth; bake-ready UVs OPTIONAL this round (TBD);
  plan-section wedge target enforced during the shrinkwrap polish pass.
