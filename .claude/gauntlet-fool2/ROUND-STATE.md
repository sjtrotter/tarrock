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

- **Round 1 (closing):** scene setup + calibration + body blockout (pipeline Step 1)
  vs v7 sheet. Builder: Opus — landmarks all within ¼-head, joints ≥10 mm overlap.
  Critic: Opus fresh-context, verdict pending.

## Progress page (DIRECTOR CHANGE 2026-08-02)

- Artifact abandoned per updated charter (none was ever published — change arrived
  before Round 1 close). Live page = `.claude/gauntlet-fool2/STATUS.md` + small PNGs in
  `.claude/gauntlet-fool2/renders/`, committed + pushed to origin/master (`docs:`
  commits) at every round close. GitHub path: https://github.com/sjtrotter/tarrock/blob/master/.claude/gauntlet-fool2/STATUS.md

## Blockers / TBD

- none yet
