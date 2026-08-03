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
- **TOOLING PERSISTENCE (standing rule, 2026-08-03, after the reboot loss):** /tmp is
  volatile — irreplaceable run tooling (build/measure libs, briefs, metrics/station
  tables, probe sets) lives under `.claude/gauntlet-fool2/tooling/` in the repo, kept
  current in the same round it is created or changed. Only bulky intermediates
  (renders, logs, throwaway workdirs) may stay in the session scratchpad, and
  anything a future round would need must be promoted before round close.

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

## Rounds 6–9 (compressed)

- **R6:** digits fanned 5°/pair (converged −2.4..−5.8° was the root cause), hand remesh
  1.5 mm (2.0 webbed), EXACT boolean at wrist → ONE watertight figure 153,966 v (009).
- **R7:** Sculpt Pass 1 all Tier-1 numpy; proportions closed ±3 mm both views (critic +
  Codex); banding defect class sent back (010).
- **R8:** banding closed by smoothing R7's own delta field; lead-accepted (011).
- **R9:** Pass-2 remesh — 2.5/2.0 mm WEB THE FINGERS, landed 1.5 mm, 992,787 verts;
  full §3 landmark set at ÷2 doses, restraint held; arm rings + deltoid fence fixed;
  silhouette drift ≤1.3 mm; webbing 0/102 (012).

## Method lessons (paid for — carry into every sculpt brief)

- Gaussian-only profile smoothing (box filters band); map residuals in 2-D before
  choosing filter radius; r=18 mm residual pass is the proven deband tool.
- cyl_fair / nearest-bin corrugates oblique surfaces; ring_fix with σ along axis only.
- Fix defects by smoothing the ROUND'S OWN delta field vs its backup, not the surface.
- Landmarks: accumulate ALL into one scalar field, blur once, displace once; planes as
  a SECOND field after refresh. Widen + taper polyline ends or you get "coat hanger".
- Tier-1 numpy beats brushes for everything tried so far; no Tier-3 stroke needed yet.

## Rounds 10–12 (reconciled 2026-08-03 after session-limit death; chain = Fool-v2-015)

- **R10 (013):** form-first Pass-2 redo. Anisotropic terrace tool (radius grid over
  (z,φ), Gaussian along Z only) killed 4 terraces; falloff moat-bug fixed at source
  (fpow≥1 / C1 smoothstep); scapula plate, knee one-mass. Critic: SEND BACK — net
  subtractive, "mannequin-smooth" (Codex ×2), elbow/pelvis/wrist barely touched.
- **R11 (014):** additive structural round. New r11lib: asymmetric teardrop falloffs
  (aradius), C1 facing, amplitude calibrated against post-blur field. Shoulder girdle
  PASSED and is PROTECTED (acromion corner, clavicle S 2.65 mm, humeral head);
  malleoli "best-executed". Critic: SEND BACK — "structure stops at the collarbones";
  knee frozen by a bad lead guard (byte-identical); Codex style 3→5.
- **R12 (015):** scoped completion. Proved drawn waist was already matched in
  silhouette (defect = shading legibility only); costal arch + waist planes, knee
  three-prominence read, pelvis rebuilt (1 crest / 1 ASIS / 2 PSIS / glute mass),
  chest diagonal erased+rebuilt, seams killed; guards 0.000 mm. Critic: SEND BACK —
  **"amplitude, not placement"**: forms right, ~⅓ contrast needed; iliac-crest BELT
  artifact too loud (RMS 8.94 vs clavicle 6.16); costal midline kink; arms quietest
  region (RMS 2.03). Codex "mannequin-smooth" 4th time, style back to 3.
- Critic's measured RMS map (r12): upper arm 2.03 · abdomen 4.33 · PSIS 5.16 ·
  clavicles 6.16 · belt 8.94 · costal arch 9.74 (reads as scored line).

## DIRECTOR RULING — issue #2 (2026-08-03, applied + closed)

- **Option A as stated: belt logged as debt, Pass-2 CLOSED** on chain head
  Fool-v2-016.blend. The ±3 mm silhouette gate stays as-is (no regional ±7 mm
  opening). Debt register now: posterior belt line (z 1.03–1.10 back), front
  garment-class line (z≈1.264), arm relief. The clothing layers cover the belt
  region in-game; debts re-judged at the whole-figure gates (Pass-3 / dressed).
- **Issue convention (director order, same comment): every future issue body
  links the relevant STATUS.md section directly** for quick reference. Both
  gauntlet sessions share the tracker — sign bodies "Gauntlet v2 lead"; never
  act on rulings addressed to the other session.

## DIRECTOR CHANNEL (order 2026-08-03 — charter §Director channel)

Director-only decisions (canon, unsettled quality-vs-scope, hard blockers): open a
GitHub issue on sjtrotter/tarrock (`gh issue create`) with question + options +
recommendation, @sjtrotter in the BODY. Keep unblocked work moving; poll
`gh issue view <n> --comments` at ≥5 min intervals (light lane, throttle rules).
On ruling: acknowledge on the issue, apply, record here, close. Ordinary judgment
calls stay with the lead.

## REGIME CHANGE (director order 2026-08-03 — charter §Usage economy)

- Codex CLI (`codex exec`) = DEFAULT executor for builder/grunt work, driving
  `blender --background --python` on the latest chain file (headless lane; GUI MCP
  socket unused by agents while Codex holds the lane; GUI must never save).
- Claude agents ONLY for: lead planning/validation, stage-close critique, pieces
  Codex failed twice. Lean briefs, lean narration.

## REBOOT LOSS (2026-08-03 08:53) — lead succession

- Machine reboot destroyed the previous lead's session mid-Round-13. /tmp wiped:
  the r7–r12 scratchpad tooling libs (r10lib/r11lib/r12lib/r12build, station
  tables, webbing probe set), the r13 workdir, and the un-promoted R13 candidate
  016 + its corrective pass are GONE. Chain intact through **Fool-v2-015.blend**
  (992,787 v, watertight, proportions certified) — nothing after 015 survives.
- The R13 builder brief was recovered verbatim into
  `tooling/R13-BRIEF.md` (with [LOST] annotations). **R13 must be RE-RUN**: the
  dead lead's Codex builder self-reported guard passes but the candidate and
  report were never validated and no longer exist — no credit is carried.
- New lead (this session) resumes under the same charter, regime, and gate
  pre-commitment (commit 7fab0ad). Tooling-persistence rule adopted (above).

## ROUND 13 (RE-RUN, closed 2026-08-03): amplitude turn-up — four phases

Pre-committed lead gate (7fab0ad): close Pass-2 if flat-light presence verifies
AND the belt is dead; arm-relief debt loggable. Outcome:

- **Phase A (Codex):** tooling reconstructed + validated (fieldlib, 015 station
  baseline, 160-probe webbing set, RMS metric w/ ordering sanity gate). Promoted
  to tooling/ (commit 1e70c17).
- **Phase B (Codex, honest FAIL):** fields hit mm targets but read as faceted
  plates (integration blur 0.855 mm — 10× too tight); belt erase 0.29 mm =
  nothing; abdomen RMS gate proved structurally unwinnable (plane work REDUCES
  high-pass RMS). Candidate 016 unpromoted.
- **Phase C (Codex, honest FAIL):** re-gain overshoot re-amplified plate edges;
  belt ridge measured p95 = 0.000 mm (not a ridge!); lead's MID-band metric
  swamped by pre-existing curvature (ratios pinned at 1.000). Both render-RMS
  instruments ruled blind at these mask sizes.
- **Phase D (ESCALATION, Opus builder — Codex failed same piece twice):**
  diagnose-first. THE DIAGNOSIS: flat-light bands are curvature concentrations
  (the eye reads the surface NORMAL, not height). The belt = a 44° slope knee
  whose garment read is its HORIZONTALITY (turn centroid varies 6.5 mm spine→
  flank); nothing is proud — B/C erased a phantom. Plate artifacts = plateau
  displacement (translates a panel without rotating its normal; only the rim
  shows). Arm seam inherited from 015 (slope kink at x≈0.40). Built in slope
  space: belt curvature-retarget 9.5 mm (inward carve trick), costal two-panel
  tilt 4.3 mm p-p, flank plane, arm relief 7 mm p-p, seam de-kink. 5 internal
  build→render→LOOK cycles. Torso integration PASS (edge-hardness 0.972 vs
  base 1.515 / Codex 1.940, no plates); belt softened NOT dead; arm still
  quiet; guards all green (silhouette 2.915 mm, webbing 160/160, topology/
  crown/sole exact).
- **STRUCTURAL FINDING:** de-horizontalizing the belt's 44° turn needs ~±7 mm
  differential across the back — the ±3 mm silhouette gate allows less than
  half. The belt CANNOT die inside the current gate. → Director issue #2
  (options: log as debt + close Pass-2 [lead rec] vs open posterior-pelvis
  gate to ±7 mm). Second garment-class line found on the FRONT at z≈1.264.
- **Lead verdict: 016c promoted as chain Fool-v2-016.blend** (strict
  improvement, guards green; workdir 016/016b were unpromoted phase
  candidates). Pass-2 gate CLOSED by director ruling issue #2 (Option A —
  see DIRECTOR RULING section). GUI reloaded to chain head.

## Method lessons (Round 13, paid for)

- Flat-light "bands/plates/seams" are CURVATURE concentrations — the eye reads
  the normal, not height. Diagnose with slope/curvature profiles, never height
  residuals. Plateau displacement (translate panel, don't rotate normal) is the
  plate-artifact generator; build fields in SLOPE space and bound curvature.
- Render-RMS scalar gates at small masks are blind to real work (0.1% moves on
  zoom-visible changes; band-pass swamped by baseline curvature). Gates must be
  geometry-space numbers + mandatory eyes-on render iteration by the builder.
- The "-flat" renders were never actually flat-lit in ANY phase (base-back ==
  base-back-flat byte-identical) — internally consistent A/Bs, but fix the
  flat-light rig in tooling before the next presence gate.
- Escalation clause works: Codex 2× fail → Opus with diagnose-first mandate
  found in one round what four cycles missed.

## Carried forward (R13 additions)

- BELT: slope-knee horizontality at z 1.03–1.10 back — debt-vs-gate ruling
  pending director issue #2. Front garment-class line z≈1.264 rides the same
  ruling. Arm relief: quiet after 3 executor attempts (7 mm p-p registered
  +0.6%) — debt per pre-commitment; note the T-pose horizontal-cylinder
  lighting geometry limits front-view arm reads.
- Flat-light render rig defect: build a true single-directional flat rig in
  tooling (all phases judged on studio-lit "flat" renders).
- Chain mapping: chain Fool-v2-016.blend = workdir Fool-v2-016c.blend (Phase D).
  Workdir 016/016b = failed phase candidates, retained for the record.

## Carried forward

- Face: featureless mask + jaw/head horizontal band; nose absent; ears absent; eye
  sockets + separate eyeball spheres REQUIRED (charter: rig-ready eyes). Head-sculpt
  round owns all of it. Manubrium band z≥1.32 ~15 mm proud → head/neck round.
- Pass-3 creases not done (clavicle hollows, sternal line, deltopectoral, inguinal V +
  ligament, sartorius, glute fold, popliteal, Achilles flanks, wrist creases, lateral
  knee grooves). Consider masked/local work — global remesh finer than 1.5 mm is heavy.
- Knee silhouette: sheet wins (narrower than calf); knobbly read lives inside it.
- Calf-top outer edge 3.3–4.0 mm narrow vs drawn (z 0.40–0.46) — unowned.
- Side z=1.21 station −4.28 mm (sheet's chest/shoulder notch under protected girdle).
- 992k verts: residual passes 10–50 s each; prefer region masks over global ops.
- Backups in-file: prepass2b/c/d (+ e pending R13), presculpt1/2, preremesh, prebool,
  Blocking_Backup, Hand_Shells.

## ROUND 14 (OPEN, 2026-08-03): head sculpt

- Brief: tooling/R14-BRIEF.md (final; draft deleted). Phase A = Codex tooling/
  measurements (tooling/TASK-A-HEAD.md); Phase B = Opus builder (escalation
  lesson applied at kickoff — brand-new-feature placement work); critique =
  Fable-lead + Codex blind at close.
- **WORKDIR NAMESPACING (standing):** `/home/betty/tarrock-gauntlet-work/r14/`
  is the OTHER gauntlet session's (MQ00 scene run — Unity/C# content); round
  dirs collide on bare numbers. This run uses `fool2-rNN/` from now on:
  R14 workdir = `/home/betty/tarrock-gauntlet-work/fool2-r14/`. (`r13/` was
  ours and stays as the record.)
- Eyeball spec (lead-measured from v7 registration circles, grid-crop method):
  sphere r = 35 mm; centers X = ±43 mm (IPD 86 mm), Z = 1.571 m; center Y +
  socket recession computed in Phase A (eyeball_spec.json). Circles' row
  position is spec-only (they float above the crown).
- presence_render.py (studio + rake) was written by the previous lead but
  NEVER RUN — Phase A validates it (closes the R13 flat-light-rig debt).
- Cycle log: A (Codex tooling, validated; eyeball-Y later corrected) → B c1
  (Opus, 017e, gates green, blind 4/10, send-back) → B c2 (Opus, 017h, gates
  green, blind FLAT 4/10 — extremes-gates blind to off-midline cheek mass) →
  B c3 (Opus, wedge plan-section mandate, TASK-B3-HEAD.md).
- **LEAD PRE-COMMITMENT (before seeing cycle-3 results):** if cycle 3 does not
  move the blind score above 4, R14 closes under the charter 80–90% clause on
  the best candidate: eye-read/mouth-read debts go to the head-retopo +
  materials stages (which own face edge loops and the iris/lash graphics the
  gray sculpt cannot show a judge), jaw-band debt logged if it survives. If it
  DOES move, one further cycle is allowed at most before the same closure rule
  applies.
- Instrument findings (paid for, carry): per-z extreme stations are blind to
  off-midline mass — plan-view sections are the anti-muzzle instrument;
  contour locks fit to drawn-ink stations re-inject pixel-tread banding (use
  smooth polynomial locks); EEVEE rake shows shadow-map acne Workbench does
  not — never chase stripes only the rake shows.

## ROUND 14 CLOSED (2026-08-03): head sculpt → chain Fool-v2-017.blend

- **Chain = workdir Fool-v2-017h.blend (cycle 2)**, promoted per the 037a326
  pre-commitment (cycle 3 did not move the blind score above 4). Verified at
  promotion: body 1,012,055 v watertight, freeze below z 1.30 exact 0.000 mm,
  contours ≤1.71 mm vs ±3, crown 1.716964, webbing 160/160, Fool_Eye_L/R at
  (±0.043, −0.0403, 1.571) r=35 mm separate/closed, backups prehead +
  prepass2e + c1feat present.
- WON: skull primary forms; manubrium R9 debt CLOSED; rig-ready eyes
  (director ruling satisfied); nose; chin on the ink; eyeball-Y correction
  (−40.30 not −48.6 — Phase A had measured the nose-root; third registration
  circle + sphere fit agree; ratified).
- **DEBTS (blind 4/10 recorded honestly):** eye read (hooded rims, not the
  drawn open almond); mouth read (layered, not one crisp line); off-midline
  cheek/jaw WEDGE unbuilt (plan-section instrument exists: seclib/w0_sections
  in workdir scripts, promote at R15 kickoff if used); jaw band z≈1.485
  (inherited r12, needs a chain-level pass); socket clearance 1.09 mm vs 2 mm
  suggestion (rigging stage adjudicates); ear mass slightly heavy. Eye/mouth/
  wedge → head-retopo + materials stages.
- Cycle 3 died at ~20 min; its sole candidate 017i rendered as a destroyed
  face (wedge field wiped features) — REJECTED on sight, retained in workdir.
  No-credit rule held: nothing unvalidated advanced.
- **GUI:** director CLOSED the Blender GUI mid-round; the post-promotion GUI
  reload is retired until further notice — STATUS.md renders are the viewing
  channel; we may open Blender ourselves if a step genuinely needs it (say so
  in the report first).
- R15 = head retopo (pipeline order). The face edge loops built there own the
  eye/mouth read debts; materials own iris/lash graphics.

## Progress page (DIRECTOR CHANGE 2026-08-02)

- Artifact abandoned per updated charter (none was ever published — change arrived
  before Round 1 close). Live page = `.claude/gauntlet-fool2/STATUS.md` + small PNGs in
  `.claude/gauntlet-fool2/renders/`, committed + pushed to origin/master (`docs:`
  commits) at every round close. GitHub path: https://github.com/sjtrotter/tarrock/blob/master/.claude/gauntlet-fool2/STATUS.md

## Blockers / TBD

- none yet
