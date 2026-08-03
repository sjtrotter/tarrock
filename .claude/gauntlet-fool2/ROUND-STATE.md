# Gauntlet v2 — ROUND STATE

Run started: 2026-08-02. Lead: Fable (this file is the resume point).

## Standing decisions (lead rulings, recorded per charter)

- **Fresh conventions (deliberate break from the v1 file):** 1 Blender unit = 1 m;
  character FACES −Y (Blender front ortho / Numpad 1 = character front) so the FBX→Unity
  trip needs no rotation surgery; mirror/symmetry axis = X; feet soles at Z = 0.
  Bald crown target ≈ 1.72 m (A-pose scale guide 1.75 m is to hair; memory note: bald
  = hair − 3–4 cm).
- **Blockout cubes: SUBSURF viewport level 3** (charter overrides pipeline doc's level 2).
- **Saves are programmatic** to the numbered chain (charter requirement overrides the old
  "director saves manually" convention, which belonged to the director's own session).
- **Blender lane:** GUI MCP socket (GUI was on an unsaved default startup scene — verified
  empty before takeover). Blender 5.2.0 LTS. Exactly one Blender-driving agent at a time.
- **Builder/critic tiers:** Opus builders for geometry; critics = fresh-context Opus
  (for Sonnet-built pieces) or Fable-lead + Codex CLI cross-model blind judge (for
  Opus-built pieces). Codex at every stage-close A/B.
- Renders + critique material live in the session scratchpad:
  `/tmp/claude-1000/-home-betty-Projects-tarrock/7cce5e4f-011d-4c4e-83f9-09af7152fd70/scratchpad/`

## Chain

- Fool-v2-001.blend = scene setup + calibrated reference empties (DONE)
- Fool-v2-002.blend = body blockout (DONE)

## Calibration facts (Round 1, verified sub-pixel)

- S = 0.00201523 m/px; front anchor sheet px (452, 932) → world (X0, Z0); side anchor
  px (966, 932) → world (Y0, Z0). Blender FRONT ortho = front figure; RIGHT ortho =
  side profile. Empties: REF_Front, REF_Side.
- Drawn chin (row 212) used over chin guideline (row 228.5); Z anchored to drawn ink.
- Inter-thigh gap 16.8 mm → Step-3 voxel size must be < ~8 mm (our units) or crotch webs.

## Rounds

- **Round 1:** setup + calibration + body blockout → PASS (Fool-v2-001/002).
- **Round 2:** neck + arm + hand blockout, attach → SEND BACK (elbow tube; 003/004).
- **Round 3:** arm fixes → 4/5 FIXED; hand ledge regression + shoulder plan pinch → SEND BACK (005).
- **Round 4:** pre-merge fixes (finger ledge, plan pinch, groin V, soles; cranium
  premise refuted) → SEND BACK pre-flight only (006).
- **Round 5:** thigh inner-line fix (slot 16.8→26.2 mm), full certification, THE MERGE:
  Fool_SculptBase 87,615 verts @ 5 mm voxel, 1 component / 0 holes / 0 non-manifold,
  landmark drift ≤0.33 mm; Blocking_Backup (16 cages) + Hand_Shells (6 applied shells)
  + preremesh duplicate all kept in-file (007/008).

## Standing lead rulings (accumulated)

- Inguinal "V" above the crotch = interior crease line art → sculpt stage, not blockout.
- Ears: cranium sits on the drawn SKULL line; ears are sculpt-stage additions.
- Front T-pose figure governs MASS/silhouette; cutouts govern shape/landmarks (sheet
  scale defect between the two is logged, ±25%).
- HAND MERGE PLAN (Round 5 ruling): inter-finger gaps measured 0.19–0.58 mm — fine
  voxel pass impossible. Instead: spread digits at shell level to ≥4 mm min separation
  (small root rotations, rig-friendly standard), hand-only voxel remesh (trial 2.0 /
  1.5 mm), then EXACT boolean union onto Fool_SculptBase at the 25 mm wrist overlap.

## Carried to sculpt (accumulated, from critics + builders)

- Inner leg line ~5 mm too thick below z≈0.70 (thigh AND calf).
- Trapezius/acromion: 10.4 mm low at two stations (steep-slope blip; additive fix).
- Ankle "boot-cuff" step at calf/foot weld; faint.
- Face: featureless mask, brow plane +9 mm proud, nose −17 mm, ears absent.
- Crown +4–5 mm proud at z≈1.708 (slightly square top taper).
- Jaw pan flat-bottomed; head/jaw band artifact visible in 3/4 render.

## Progress page (DIRECTOR CHANGE 2026-08-02)

- Artifact abandoned per updated charter (none was ever published — change arrived
  before Round 1 close). Live page = `.claude/gauntlet-fool2/STATUS.md` + small PNGs in
  `.claude/gauntlet-fool2/renders/`, committed + pushed to origin/master (`docs:`
  commits) at every round close. GitHub path: https://github.com/sjtrotter/tarrock/blob/master/.claude/gauntlet-fool2/STATUS.md

## Blockers / TBD

- none yet
