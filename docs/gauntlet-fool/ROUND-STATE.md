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
  tables, probe sets) lives under `docs/gauntlet-fool/tooling/` in the repo, kept
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

## ROUND 14 AMENDMENT (2026-08-03, ~1 h after closure): cycle 3 was ALIVE

- The "cycle 3 died" call above was WRONG: the builder's session survived the
  lead's stop and completed later. 017i was an internal save mid-wedge (the
  destroyed face was its un-refined first pass — the on-sight rejection was
  still correct for that file). Final delivery: **Fool-v2-017k.blend**
  (017i wedge → 017j features → 017k ears).
- Lead validation + blind judge re-run: gates all green and ≥ 017h on every
  axis (freeze 0.000, contours ≤1.85, crown 1.716964, webbing 160/160,
  watertight Euler 2, socket clearance 1.28 best-of-run); plan-section
  exponent p 2.05→1.41 (muzzle objectively fixed); mouth one crisp 64 mm
  line; nose 9.5 mm; ears thinned. Blind score **4/10 — flat for the third
  time** → the 037a326 closure stands; only the carrier changes.
- **CHAIN AMENDED: Fool-v2-018.blend = workdir Fool-v2-017k.blend.**
  (Chain Fool-v2-017.blend = 017h remains as the record of the first
  promotion; retopo candidates renumber to 019a+.)
- New paid-for lessons: C1 smoothstep envelopes WRITE bands at head scale
  (6A/W² vs head curvature) — use C∞ envelopes on faces; the z≈1.51 line is
  a voxel-remesh terrace in inherited topology (curvature already 3/m vs 016's
  20/m; tangential relaxation moves 0.018 mm) — only retopo/finer remesh can
  kill it. PROCESS: never declare a background builder dead without checking
  for its transcript/liveness; 017i taught that an unvalidated mid-save is
  not the builder's verdict.
- **LEAD RULING — eye globe-vs-face conflict (builder escalation):** globe
  stays r = 35 mm at the ratified centres (the rig-ready director ruling and
  aperture width depend on it). Resolution = option (c): build the ORBITAL
  REGION forward/outward to the drawn front width at eye rows (sheet cranium
  half-width ≈ 93 mm at row 126 — the drawing IS broad at eye height; the
  wedge applies below the cheekbone only). Owned by R15 Phase B (lid loops +
  orbital fill in the retopo), not another sculpt cycle.
- **GUI:** director CLOSED the Blender GUI mid-round; the post-promotion GUI
  reload is retired until further notice — STATUS.md renders are the viewing
  channel; we may open Blender ourselves if a step genuinely needs it (say so
  in the report first).
- R15 = head retopo (pipeline order). The face edge loops built there own the
  eye/mouth read debts; materials own iris/lash graphics.

## Progress page (DIRECTOR CHANGE 2026-08-02)

- Artifact abandoned per updated charter (none was ever published — change arrived
  before Round 1 close). Live page = `docs/gauntlet-fool/STATUS.md` + small PNGs in
  `docs/gauntlet-fool/renders/`, committed + pushed to origin/master (`docs:`
  commits) at every round close. GitHub path: https://github.com/sjtrotter/tarrock/blob/master/docs/gauntlet-fool/STATUS.md

## Blockers / TBD

- none yet

## ROUND 15 CLOSED (2026-08-03): head retopo → chain Fool-v2-019.blend

- Chain = workdir Fool-v2-019b.blend (object Fool_HeadRetopo): 2,058 v /
  3,970 tris, 99.80% quad, dev RMS 0.182 / max 0.976 mm excl. 3 named
  divergences (orbital ruling, ears, mouth); neck seam z=1.442 (72 v);
  eyes untouched/separate; chain 018 untouched.
- INSTRUMENT LESSON (paid for): vertex-only RMS cannot see folded faces —
  A2's shrinkwrap scaffold measured 0.36 mm while 24.8% of faces were
  inverted with 3,510 self-intersections (face-centroid RMS 7.12 / max
  62.6 mm). Any future wrap gate must include normal-inversion count,
  self-intersection pairs, and face-centroid deviation. Codex A2 report was
  honest on its own numbers; the numbers were the wrong instrument.
- Blind: likeness 6/10 / topology 7/10 (first movement; bare-globe caveat).
- Debts → later rounds: aperture taller/rounder wanted; nose soft; lower lid
  minimal; 22 hidden lid-band self-intersections (occluded); mouth-corner
  density deformation check at rigging; iris/pupil at materials.
- R16 = body retopo (reuse authored/graded approach + donor lessons; same
  gates + the new wrap instruments). Then rigging, hair, clothes, materials,
  Unity FBX gate.

## DIRECTOR FEEDBACK (2026-08-03, viewing head renders — mid-R16)

- **ELEVATED DEBTS (no longer cosmetic):** (1) the head reads as LACKING A
  NOSE — the R15 "soft nose" debt is confirmed unacceptable at bar; the nose
  needs genuine presence; (2) the lips/mouth read is insufficient; (3) the
  aperture-shape debt rides with them.
- **Standing approach RE-CONFIRMED + donor ban:** separate UV-painted sphere
  eyeballs in dug-out sockets with built-out eyelids; authored topology
  confirmed; **CC0/donor asset downloads are REJECTED — no donor assets ever
  again** (supersedes any donor language in R15 research/briefs).
- **LEAD SCHEDULING RULING: R17 = head-polish pass** on the retopo mesh
  (nose presence, lip read, aperture shape) — cheapest before rigging binds
  weights to topology; rigging becomes R18. The head is not declared final
  until this pass lands.
- STATUS render protocol: renders showing the bare sphere eyes carry the
  caveat "eyes are blank spheres until the materials stage paints
  iris/pupil" so the read isn't mistaken for a defect.

## REGIME TIGHTENED (director order 2026-08-04 — charter §Usage economy re-read)

- Claude at 70% weekly: sub-agents ALMOST EXCLUSIVELY Codex now — builders,
  iterators, blind judges, AND critics. Claude only for the lead's own short
  planning/validation turns; Opus escalation only after Codex fails a
  judgment-heavy piece TWICE and it blocks the round, justified here first.
- **Grandfather note:** the R16 Phase-B Opus builder was launched before this
  order; killing it mid-build would waste the spend already made, so it runs
  to completion. Everything downstream in R16 (critique, blind judge, fix
  cycles) and all later rounds follow the tightened rule.
- **Carried-twice rule adopted** (charter §Director channel): any debt carried
  forward more than twice gets its own PLAIN-ENGLISH GitHub issue.
- **Audit (2026-08-04):** belt + front garment-class line — already
  adjudicated by director ruling on issue #2 (debt, re-judged at dressed
  gates), not stuck, no new issue. Arm relief (carried since r12, 3 failed
  attempts) → **issue #5**. Calf-top outer edge 3–4 mm narrow (unowned since
  ~r9) → **issue #6**. Pass-3 creases = scheduled deferral, not stuck.
  Lid-band self-intersections + mouth-corner check = carried once each.
  Nose/lips/aperture = covered by 2026-08-03 director feedback + scheduled
  R17. Poll #5/#6 at ≥5 min intervals; keep working meanwhile.

## ROUND 16 (OPEN, 2026-08-03, 4th lead): body retopo

- Brief: tooling/R16-BRIEF.md; Phase A = Codex (tooling/TASK-A-BODY.md,
  workdir `/home/betty/tarrock-gauntlet-work/fool2-r16/`); Phase B = Opus
  (escalation lesson applied at kickoff, as R14/R15).
- Lead rulings: AUTHORED graded charts (no shrinkwrap final surface); body
  budget 8–16k tris (naked figure ≤ 20k with the 3,970-tri head); neck seam
  bonds VERTEX-EXACT (≤0.01 mm) to the head's 72-v ring, reduction rings
  below the seam only; full five-finger hands, knuckle loops, webbing probes;
  feet single-mass pending Phase-A toe verification; ≥3 loops per bend joint,
  no pole within 15 mm of a bend crease; deviation ≤1.5 RMS / ≤3 max mm excl.
  named divergences; FULL instrument suite (vertex + face-centroid deviation,
  inversions, self-intersections, mirror) at every fit gate.
- **Charter milestone adopted:** at R16 close the promoted naked figure is
  also saved as `docs/design/3d-models-inwork/YoungAdultMale-base.blend`
  (the charter's "clean generic young-adult man" save point, fulfilled at
  retopo; uncommitted like all blends). No prior round did this.
- Workdir note: bare `r16/` in the work root belongs to the OTHER gauntlet
  session — ours is `fool2-r16/` per the standing namespacing rule.
- **Phase A (Codex) VALIDATED** (2026-08-03 ~18:40): inventory (sculpt
  1,012,034 v watertight Euler 2), neck ring exported (72 v, planar
  Z=1442.000, centroid Y=+21.104 mm — NOT centered on Y=0), body_axes.json
  (torso/leg 20 mm + arm 15 mm sections, 5 digit axes), verify_body.py +
  render_body.py instruments selftested against Fool_HeadRetopo with numbers
  cross-checking R15 ground truth (mirror 2@0.067 mm, boundary 148,
  self-int 27 vs 22 explained by stricter edge-adjacency). Findings: digit
  clearances index–middle 2.902 / middle–ring 2.079 / ring–pinky 1.657 mm
  (below the nominal 4 mm — webs must stay open); feet = single toe-less
  mass; crotch apex Z=825 mm. Minor: a-foot-top.png is actually a front
  view (point-cloud evidence stands). **CRITICAL ENV FINDING: this Blender
  build terminates opening the 916 MB chain as main file — append
  datablocks as a library instead** (extract_body.py has the pattern).
  Instruments + report promoted to tooling/ (R16-PHASEA-REPORT.md).
- **RUN DIR MOVED (director change, commit 402ea6f, mid-R16):** canonical
  location is now `docs/gauntlet-fool/` (`.claude/` is fully gitignored;
  the MQ00 gauntlet lives beside it at `docs/gauntlet/`). A symlink at
  `.claude/gauntlet-fool2 → ../docs/gauntlet-fool` keeps old absolute paths
  in already-issued briefs/scripts working (the in-flight R16 Phase-B brief
  resolves through it — verified). All new writing uses the new path.
  Viewing URL: https://github.com/sjtrotter/tarrock/blob/master/docs/gauntlet-fool/STATUS.md
- **Phase B (Opus builder) LAUNCHED** with tooling/TASK-B-BODY.md:
  authored charts per R15 method, candidates Fool-v2-020a+ in fool2-r16/,
  head/eyes untouched, body-head bond positional this round (join at
  rigging), full instrument suite + eyes-on law binding.

## ROUND 16 CLOSED (2026-08-04): body retopo → chain Fool-v2-020.blend

- **Chain = workdir Fool-v2-020g.blend promoted as Fool-v2-020.blend.**
  Fool_BodyRetopo 4,599 v / 9,124 tris / 100.0% quads; deviation 0.160 RMS /
  1.06 max mm outside the ONE named divergence (hand); neck seam 0.0007 mm
  onto the head's 72-v ring; 0 self-intersections; mirror exact 0; sole
  z=0 exact; loop spec met (shoulder 4 / elbow 5 / knee 5 / hip 5 / wrist 4 /
  ankle 3+1, finger hinges 6 stations); 186 poles all accounted, none within
  15 mm of a crease. Lead re-ran verify_body.py independently on the saved
  file — every number reproduced. Report: tooling/R16-PHASEB-REPORT.md.
- **YoungAdultMale-base.blend milestone SAVED** (charter §base mesh) from the
  same candidate (contains hidden sculpt as reference; uncommitted).
- **THE ROUND'S FINDING: the sculpt's four fingers are FUSED** (continuous
  palmar sheet to x≈770; Phase A's 2.9/2.1/1.7 mm clearances measured the
  HandShell_* helpers, not the surface). Builder hollowed the mitten into
  five real digits — the named divergence (digit 4.64 RMS / 18.1 max), and
  the correct rig-ready outcome. R6/R9 webbing probes were shell-derived
  too; treat historical webbing numbers with suspicion.
- **Codex blind: likeness 5/10, topology 6/10.** (A)-gap = "generic base
  body traced to landmarks" — the r12/r13 presence complaint inherited
  through a faithful retopo; stays under the issue-#2 ruling (re-judge
  dressed; arms = issue #5). (B)-gap = shoulder/armhole deformation risk —
  matches builder's own list; ADJUDICATED AT RIGGING via arm-lower pose
  test before weight painting counts as done.
- **Instrument lessons (paid for, run's law):** (1) show_wire/show_all_edges
  do NOTHING in background renders — every "wire" png from render_body.py
  was a shaded duplicate; real rig = tooling/render_wire.py (Wireframe
  modifier shell); all wireframe judging uses it now. (2) thumb–index
  webbing probes at u≥0.5 are geometrically unpassable (corridor ~79° off
  the digit's lateral axis) — skip pairs whose corridor is within ~30° of
  either axis. (3) bmesh non_manifold counts boundary edges — subtract
  is_boundary. (4) matrix_world is stale right after libraries.load until
  depsgraph update (Phase A's eye bbox was wrong; true eye locs ±43/−40.3/
  1571 confirmed). (5) Phase A's bend_crease points were synthetic and off
  the surface — builder met the real pole rule independently.
- **Debts → later rounds:** shoulder/armhole deformation risk (rigging pose
  test); neck ribbed-collar density read (head's 72-v ring; revisit only if
  it shows in dressed renders); blocky 8-sided digit bases; toe-cap quad
  spend; presence/"mannequin" class unchanged under issue-#2 umbrella.
- Regime note: Phase B was the grandfathered Opus builder; critique/judging
  this round were lead + Codex only, per the tightened order.
- R17 = head polish (director-elevated: nose presence, lip read, aperture;
  + calf width if issue #6 rules fix). R18 = rigging. Issues #5/#6 still
  awaiting director comment at close time.

## DIRECTOR RULING — issue #5 (2026-08-04, applied + closed)

- **Arms accepted AS-IS**: "remember it's a young adult male. we shouldn't
  try to make him muscle-bound... it can be re-addressed later if an issue
  arises." The arm-relief debt (carried since r12, 3 failed attempts) is
  RETIRED from the ledger — no further arm-presence work; revisit only if a
  later whole-figure/dressed review surfaces a real problem. Also a style
  datum for all future presence work: restraint over musculature.
- Issue #6 (calf width) still open, no comment yet.

## DIRECTOR RULING — issue #6 (2026-08-04, applied + closed)

- **Calves accepted AS-IS**; debt retired; the conditional calf edit is
  DROPPED from R17 entirely.
- **STANDING STYLE DATUM (quoted):** "the model doesn't necessarily need to
  look *EXACTLY* like the reference; in fact, it probably won't match
  exactly... Too much 'trying' to make it look exact may deform it more
  anyway." Interpretation for the run: the sheets govern the CHARACTER READ,
  not a millimetre contract — existing gates stay as internal discipline,
  but no more rounds spent chasing small sheet deltas for their own sake.
  (Pairs with the #5 restraint ruling.)

## ROUND 17 (OPEN, 2026-08-04): head polish — cycle log

- Cycle 1 (Codex, 021c): gates green (neck ring 0.000, eyes/body untouched,
  symmetry, 99.8% quads; "new self-intersection" adjudicated as detector
  noise — standard instrument: 27 pairs chain AND candidate, identical
  sites). Nose now EXISTS front+side (was −0.6 mm, now +11.6 mm projection)
  but blunt; mouth puffier not crisper; aperture still roundish/ragged.
  Blind 4/10. = Codex fail #1 on the face-read piece.
- Cycle 2 (Codex, PID 312954, launched w/ judge critique verbatim): narrow/
  soften nose keeping projection; one clean smile line; true almond
  apertures w/ smooth rim curves. If it misses → Codex fail #2 → Opus
  escalation becomes justified per the tightened regime.
- Cycle 2 RESULT (021f): all hard gates green (neck 0.000, eyes/body
  untouched, 27/27 intersections, lid clearance 1.55 mm, nose 11.98 mm,
  quads 99.8%). Lead eyes-on: real improvement (calmer mouth, smoother
  almond rims, softer nose). Blind judge: **4/10 again** — nose "blunt
  triangular wedge" (size now plausible), mouth "stacked, protruding lip
  geometry" not one line, eyes "inserted spheres... incomplete apertures";
  biggest gap = eye-and-lid CONSTRUCTION. **= Codex fail #2 on the
  face-read piece.**
- **OPUS ESCALATION JUSTIFIED (charter clause, recorded before launch):**
  the piece (face read: lid construction / mouth line / nose softening) is
  judgment-heavy sculptural design; Codex produced two gate-green but
  blind-flat cycles (4/10, 4/10) with consistent critiques; the round is
  director-ordered ("must land before the head is declared final") so the
  piece blocks it. One tightly-scoped Opus cycle on 021f, both blind
  critiques verbatim as targets; same hard gates.

## ROUND 17 CLOSED (2026-08-04): head polish → chain Fool-v2-021.blend

- **Chain = workdir Fool-v2-021n.blend (Opus escalation) promoted.** Gates
  (lead re-verified independently): neck ring 0.000, eyes/body untouched,
  symmetry inherited exactly, 2,134 v / 4,122 tri-eq / 99.81% quads, lid
  clearance 1.45 mm, self-intersections **0** (chain was 27), nose 11.68 mm.
- Delivered vs the director's three targets: NOSE exists (all three blind
  runs confirm, "plausibly sized"); LID CONSTRUCTION won — extruded lid
  margin w/ 2.4 mm overhang, analytic almond 46.0×32.3 vs drawn 46.3×34.3,
  judge flipped eyes from "biggest gap" ×2 to "strongest point"; MOUTH one
  analytic seam by construction but still the judge's biggest gap ("soft
  swollen slit") — the honest miss.
- **Blind 4/10 — fourth consecutive flat 4 on gray/bald/blank-eyed heads.**
  Lead closure reasoning (R14 precedent + 80–90% clause): the gray medium is
  saturated; critique content moved decisively while the scalar didn't;
  irises/brows/hair arrive at materials. Closed on the run's best face.
- **INSTRUMENT LESSON (paid for): verify_body.py double-library-load renames
  the candidate to .001 and silently measures the CHAIN** — cycle-2's
  "27 = baseline" was an artifact (true series 27 → 8 → 0). Fixed pattern:
  one head per invocation (verify_head_esc.py, promoted to tooling). Any
  instrument that loads same-named objects from two files must be assumed
  broken until proven otherwise.
- **Debts → later rounds:** mouth/lower-face read (corner facet cluster
  needs corner retopo — schedule with blend-shape/materials work); nose
  blunter than sheet; ears simplified flaps (R15); neck density collar;
  judge's secondary notes (cranium dominance, angular chin) parked under the
  #6 "read, not exactness" ruling for the dressed re-judge.
- Escalation postmortem: clause worked as designed — 2 documented Codex
  fails, justified pre-launch, one Opus cycle delivered the two hardest
  targets. Usage: this was the round's only Claude sub-agent.

## DIRECTOR DEFECT REPORT (2026-08-04, mid-R17) — finger curl on chain 020

- From the TOP view, the INDEX and PINKIE digits CURL INWARD on
  Fool_BodyRetopo — must not happen; T-pose digits are straight/fanned per
  the sheet. Likely inherited from the fused-finger carve-out (the digit
  axes were estimated from shells while the true surface was fused).
- **RIG-BLOCKING (director order): fingers must be straightened BEFORE any
  skinning weights land.** Scheduled as **R18 Phase 0** (Codex, mechanical:
  rotate/straighten each digit tube about its root per the sheet's fan
  angles, re-verify webbing/gaps/mirror, top-view render evidence) ahead of
  armature work. Logged as a debt on chain 020 until then.

## R18 PHASE 0 CLOSED (2026-08-04): fingers straightened → chain Fool-v2-022.blend

- **Chain = workdir Fool-v2-022c.blend promoted.** Rigid per-ring
  straightening, all 5 digits both hands. Gates (lead re-ran validate_one.py
  independently on the saved file — every number matched): straightness
  worst 0.0004 mm; inter-digit clearances INCREASED 1.19–2.64 mm; mirror
  0.000000; topology sha unchanged (4,599 v / 4,562 q / 0 n-gons);
  self-intersections 0; head/eyes/neck-seam/sole untouched. Top-view
  eyes-on: before = index+pinkie hooked inward, thumb hugging palm; after =
  five straight fanned separated digits per the sheet. Director defect
  RESOLVED. Evidence renders pushed (r18p0-hand-before/after.png).

## ROUND 18 PROPER (OPEN, 2026-08-04, 5th lead): rigging

- Handoff recommendations ADOPTED as lead rulings (tooling/R18-BRIEF.md):
  custom deform-only armature authored programmatically (no Rigify), 53-bone
  Unity-Humanoid-compatible set with Blender .L/.R suffixes + Eye.L/R bones
  (globes bone-parented, never skinned); head-body join via 72-pair
  merge-by-distance → `Fool_Mesh`; auto-weights + cleanup; pose battery =
  the round gate (shoulder −45°/−80° adjudicates the R16 armhole debt;
  finger 60° hinges; eye aim ±20°; neck; elbow/knee/hip).
- Phase A (Codex): fool2-r18/TASK-A-RIG.md — join + armature + bind + full
  battery, candidates Fool-v2-023a+. Promotion target Fool-v2-023.blend.
- **Phase A result (lead-adjudicated 2026-08-04): structure GOOD, finish
  CORRUPTED.** Join exact (6,661 v, boundary drop 144 accounted, 0 self-int,
  rest identity 0.000), 53-bone rig symmetric/identity-transform, eye bones
  on globe centers, children of Head, deform=False, globes bone-parented.
  Builder stopped honestly at the finger gate — but its final weight "fix"
  (023d) applied R16 BODY vertex indices to the reindexed joined mesh:
  ~394 head/neck verts got finger-bone weights (thumb range landed on the
  neck seam), producing 440–1000 mm streak wings in the pose renders that
  the builder's "all renders reviewed" claim missed, and tearing the collar.
  023d DISCARDED; cycle 2 rebases on 023c (pre-corruption, gates green).
- **Defects found by lead instruments:** (1) shoulder ring at |x|=0.289
  measured the rigid arm (0.6–1.1% loss); TRUE armhole ring |x|=0.225 loses
  10.0%@45° / 18.3%@80° — eyes-on verdict deferred to clean renders;
  (2) Eye.L bone/globe on −X while body .L=+X (Foot.L +0.135) — Unity
  Humanoid would cross-map eyes vs hands. Lead ruling: swap bone AND globe
  names so .L = character's left = +X everywhere (R14 globe naming was
  screen-side, not anatomical).
- **Paid-for lessons (rig round):** (a) any vertex-index table dies at a
  topology-changing operation — after a join/merge, index-based tooling must
  be re-derived geometrically (same family as R17's rename trap);
  (b) pose-battery renders must whitelist visible objects, never blacklist
  (builder hid only backup_*; helpers were innocent this time but the law
  stands); (c) a smear guard (per-vertex displacement bounded by chord of
  distance-to-joint) is now a mandatory battery gate — automate what eyes
  keep missing; (d) eye-clearance-under-rotation is a phantom instrument:
  a true sphere rotating about its center is surface-invariant (globes
  measured spherical to ±0.0001 mm; static socket min gap 0.046 mm is the
  real number, safe by invariance).
- Phase B (Codex, cycle 2 on the finger piece — fail #1 recorded above):
  fool2-r18/TASK-B-RIGFIX.md — rebase 023c, geometric digit sets, eye swap,
  corrected battery + smear guard. A second finger miss = Opus escalation
  per the tightened regime.
- **Phase B stopped honestly at the lead's sanity gate — and completed the
  diagnosis: the 30 phalange bones were placed from R16 body_axes digit
  stations, captured BEFORE Phase 0 straightened the digits.** Bones follow
  the old curled axes; tubes moved out from under them (thumb tube to
  y=−123.8 mm vs bones ending −92.8). Also explains 023c's crumpled fist —
  curling out-of-tube bones deforms garbage. NOT counted as a finger fail:
  the stop was the gate working. Phase B2 (TASK-B2-RIGFIX.md) authorized:
  reposition phalange bones onto ring-centroid axes from backup_BodyRetopo
  (R16 indices still valid THERE), mirror-exact, then the full TASK-B
  sequence. Paid-for lesson: bone placement data must postdate every
  geometry edit — Phase 0 invalidated the R16 digit axes for RIGGING too,
  not just for weights.

## R18 PHASE B2 + LEAD PATCH (2026-08-04): rig repair LANDED — 023f

- **Phase B2 (Codex) delivered:** 30 phalange bones repositioned onto the
  straightened tube axes (mirror-exact, digit sets now connected: 49/77/74/
  74/76 per side), eye sides swapped per ruling, smear guard 0 in all poses,
  statics green, TRUE armhole loss 9.98%@45° / 18.26%@80°. Honest stop at
  the fist gate ("open hook, fingertips miss palm, thumb splayed").
- **Lead adjudication of the stop:** deformation QUALITY passes (volume
  held, no web tearing, knuckles read) — the open hook is the 60°×3 pose
  spec itself (a real fist needs more MCP), and the thumb splay is a pose-
  axis artifact (thumb hinge is diagonal, battery curls about world Y).
  NOT a Codex fail; gate met as specified by the handoff.
- **New defect found by lead eyes-on that every instrument missed:** at
  a80 the hands stretched into ~0.5 m "blades" — 10 palm verts PER SIDE had
  EMPTY vertex groups (B2's bleed-removal stripped finger weights from
  verts whose auto-weights were exclusively old-finger-bone; they anchored
  at rest). The smear guard is blind to UNDER-motion. Lead applied the
  fully-determined 20-vert patch directly (nearest hand-chain bone, 1.0,
  mirror-consistent) + full re-validation in one invocation — logged as a
  deliberate regime deviation: a Codex round-trip for a determined 20-vert
  fix costs more than it saves. Result 023f: orphans 0, a80 hand lag
  579 → 1.67 mm, statics green, rest identity 0.0002 mm.
- **SHOULDER POSE TEST — the R16 armhole debt is ADJUDICATED: PASS** (lead
  eyes-on clean renders at 45°/80°: continuous deltoid/armhole, armpit
  reads as compression not collapse; 18.3% ring-area loss does not manifest
  visually). Residual notes: angular low-poly elbow profile, neck seam
  density collar — dressed-stage re-judge debts as before.
- **New instrument law: every pose battery needs BOTH guards — smear
  (over-motion) AND rigid-lag (under-motion: verts in a rigidly-rotating
  region must track the rigid transform within ~30 mm).** Zero-weight-vert
  check runs AFTER every weight edit, not just after binding.

## R18 PHASE C ACCEPTED + BLIND JUDGE + PHASE D (2026-08-04)

- **Phase C (thumb/thenar, Codex) ACCEPTED — 023j.** Move-verts-only held:
  topology sha unchanged, mirror residual identical, outside-hand movement
  0.000, straightness ≤0.0004 mm, thumb–index clearance 11.45 mm, thumb
  bones repositioned onto the edited tube (22.2 mm shift), thenar owned
  Hand 72–90% w/ Thumb.01 blend, zero-weights 0, lag guard 0.0009 mm.
  Lead eyes-on: base reads full, restrained thenar ball, real opposition
  in thumb-curl. Director thumb defect RESOLVED pending dressed re-judge.
- **Blind judge (Codex, fresh, rig rubric): 4/10.** Named blockers:
  finger curls intersect/stack w/ sharp hinges; thumb opposition doesn't
  carry the thenar; shoulder at 80° = squared shell + caved armpit (wants
  clavicle/torso blend); elbow inner pinch "marginally usable". Judge's
  own assessment: fixable by weight redistribution WITHOUT geometry.
- **Phase D launched (TASK-D-WEIGHTPOLISH.md):** the run's first true
  weight-polish pass (hard per-phalange assignments were never smoothed) —
  hinge-ring blending, thenar/thumb blend, deltoid/armpit gradient, elbow
  softening. NEW INSTRUMENT: posed self-intersection counts per battery
  pose (before/after). Judge fail #1 recorded against the weight-polish
  piece if D misses.

## ROUND 18 CLOSED (2026-08-04): rigging → chain Fool-v2-023.blend

- **Chain = workdir Fool-v2-023m.blend promoted** (lead verified the copied
  chain file independently: 6,661 v / 53 bones / 0 zero-weight / Eye.L +X /
  rig identity). Full lineage: 023a-d Phase A (structure good, weight fix
  corrupted), 023e Phase B2 (bones repositioned, eye swap), 023f lead
  orphan patch, 023j Phase C (thumb/thenar), 023m Phase D (weight polish;
  023k/l rejected by the builder's own posed-intersection instrument).
- **Phase D results:** shoulder armhole loss 18.26→6.08%@80° w/ visibly
  rounder deltoid; hinge blending smoothed fingers/elbow; thenar carries
  in opposition; posed self-intersections 0 in every battery pose (and the
  0-baseline proved the judge's "intersections" were visual stacking);
  head/eye/neck weights sha-identical; mirror weight symmetry 5e-6.
- **Re-judge: 5/10 (from 4/10), biggest gap migrated hands→shoulder read.**
  Closed under the 80–90% clause + director restraint rulings: remaining
  complaints are density-bound (boxy elbow, angular digits — R16 budget),
  instrument-contested (claimed intersections measure 0), or dressed-stage
  (armpit crease — clothing covers; neck collar). Handoff gates (no
  shoulder collapse, no finger tearing) PASS by instruments + lead eyes-on.
- **Debts → dressed re-judge:** armpit crease at extreme arm-lower; boxy
  elbow; angular digit read; neck seam density collar. Judge's neck-nod
  axis remark checked: battery math is correct (−30° about X tips forward).
- Tooling promoted to repo tooling/: all five TASK briefs, four reports,
  validation JSONs, pose_battery.py, repair_r18b2.py, lead instruments
  (lead_check_rig / lead_diag_smear / lead_patch_023f).
- R19 = HAIR + compliant ear rebuild (audit below). Then clothes &
  accessories, materials (irises/brows — blind-score ceiling lifts),
  Unity FBX gate ends the run.

## EAR AUDIT (2026-08-04, director ruling re-affirmed in charter): VIOLATION

- Evidence renders fool2-r18/renders-f/ear-side-L.png / ear-tq-back.png /
  ear-front.png: the current ears are shallow relief discs sculpted/carved
  into the head side (R14 sculpt → R15 "simplified flap" retopo) — exactly
  the v1 failure mode the standing ruling bans (ears must be NEW mirrored
  cube geometry shaped to the ear's outer dimensions, refined, JOINED).
- **Scheduled: compliant ear rebuild in the HAIR round** (hair coverage
  determines exposure; builds together). Gates when it runs: separate
  mirrored construction, joined watertight, head silhouette elsewhere
  untouched, re-skin ear region to Head bone, straightness/mirror/self-int
  instruments.

## DIRECTOR DEFECT REPORT (2026-08-04, mid-R18) — thumb base / thenar eminence

- The THUMB is too thin at its base and lacks the thenar 'ball' at the root
  (palm-side mass). Geometry defect, not weights; matters for the read AND
  for rigging (thumb opposition collapses flat without the mass).
- **Lead scheduling ruling: R18 Phase C** — bounded hand-geometry touch-up
  (thumb-base girth + thenar eminence mound, both hands mirror-exact) runs
  AFTER Phase B2 lands its bone/weight repair and BEFORE weight polish
  counts as final: B2's bone-placement + digit-weight machinery is
  geometric/index-free, so re-running it on the edited mesh is cheap now,
  costly later. Straightened-finger gates (straightness, clearances,
  mirror 0, no self-intersections) apply to the edit; thumb bones and
  digit weights re-derived after the edit; thumb battery re-run.

## ROUND 19 (OPEN, 2026-08-04, 5th lead): hair + compliant ear rebuild

- Brief: tooling/R19-BRIEF.md. Rulings: ears FIRST then hair; ears JOIN
  Fool_Mesh (weld/bridge, re-skin 1.0 Head, old relief discs smoothed
  away); hair = SEPARATE object Fool_Hair on the Head bone; bald crown
  1.716964 FROZEN, hair adds ~3–4 cm; chunky storybook masses per the
  charter mix; candidates Fool-v2-024a+ in fool2-r19/.
- Phase A (Codex, TASK-A-EARS.md): first launch was BLOCKED READ-ONLY —
  **paid-for lesson: the Codex workspace-write sandbox needs the workdir
  to be a git repo; fool2-r18 had .git, fresh workdirs don't — `git init`
  the workdir before the first Codex launch.** Relaunched after git init
  (PID 393067). Its read-only audit already measured the drawn ear:
  height 108.8 mm, side depth 52.4 mm, z 1.483–1.592.

## R19 PHASE A CYCLE LOG (6th lead, 2026-08-03/04)

- Attempt 2 (PID 393067) exited with NO candidate: launch omitted
  `-s workspace-write`, so the whole session ran read-only (git init alone
  is not the fix — **paid-for lesson: Codex needs BOTH the workdir git
  repo AND the `-s workspace-write` flag; check the log header's
  `sandbox:` line before trusting a launch**). Not a builder fail. Its
  read-only audit measured the ear envelope — later found WRONG (below).
- Attempt 3 (workspace-write) delivered 024a with an HONEST STOP: hard
  gates green (freeze 0.000 outside ear set, mirror exact, boundary 76,
  re-skin 1.0 Head, zero-weights 0, +194 v/+246 f) but self-judged the
  read failed. Lead eyes-on CONFIRMS: flat concentric discs/paddles,
  no helix/lobe, and ~2x oversized. **Codex fail #1 on the ear piece.**
- **LEAD MEASUREMENT CORRECTION (authoritative):** the audited "108.823 mm
  ear height" double-counted jaw/shadow ink. Native-sheet re-measure
  (cross-check: eye row converts to z 1.5749 vs known 1.571): drawn ear
  height ~57 mm, z 1.535–1.592; side depth ~35–40 mm; front protrusion
  ~15–20 mm beyond skull side. Recorded for all future ear/hair work.
- Cycle 2 launched (log codex-r19a4.log): rebuild from chain 023 to the
  corrected envelope, C-shell form directives (rim/hollow/lobe, no radial
  fan topology), exact tri–tri self-intersection proof required,
  sheet-crop A/B gate. Candidates 024b+.

- Cycle 2 RESULT (024b, honest STOP): structural gates ALL green (exact
  ear-region tri–tri intersections 0, mirror 0.000, freeze 0, boundary 76,
  zero-weights 0, envelope ~58 mm conformant; one PRE-EXISTING exact
  intersection pair disclosed in untouched source body geometry — carried,
  must not grow). Lead eyes-on + sheet A/B: form FAILED again — reads as a
  round grommet/plug (flat-faced disc + rim ring) proud of a moat/crater
  at the root; no C-shape, no lobe taper, no backward tilt. **Codex fail
  #2 on the ear-form piece.**
- **OPUS ESCALATION JUSTIFIED (charter clause, recorded before launch):**
  ear FORM is judgment-heavy sculptural design; Codex produced two
  gate-green but form-fail candidates (paddle-disc, then grommet-plug)
  with consistent self-and-lead critiques; ears block Phase B hair
  (coverage decisions need real ears) so the piece blocks the round. One
  tightly-scoped Opus cycle from chain 023, both critiques verbatim,
  eyes-on iteration mandate (R13-D precedent), same hard gates.
  Brief: fool2-r19/TASK-A3-EARS-OPUS.md, candidates 024c+.

- Cycle 3 (OPUS, 024c) — FORM BREAKTHROUGH: side view reads as the drawn
  ear (C-silhouette, rolled helix, hollow, lobe, tilt 10.4°; join
  invisible; all structural gates green, freeze 0 verts moved, 286
  tris/ear, +46 v). Builder flagged two lead items, both upheld:
  (1) head half-width is 91.5 mm (lead's 98 was stale — builder's number
  adopted); (2) **lead envelope correction #2: the 57 mm ear height was an
  UNDER-measure** (lead stopped at the tragus notch, missing the lobe's
  extent) — drawn ear ≈ 31–33% of head height ≈ 78–82 mm, z ≈ 1.512–1.592
  (top anchored). Builder correctly refused to resize on its own
  authority. Front view reads as a pointy wedge, not the sheet's rounded
  almond — structural to a fully-flush relief-style shell.
- **LEAD RULING — free helix edge:** a JOINED ear whose upper/back helix
  rim stands slightly off the skull (real gap behind the rim) is
  COMPLIANT with the director's separate-geometry ruling: the ban is on
  carved/relief ears and the failures were free-standing DISCS; a
  dimensional ear rooted at the head with a free rim is the standard
  construction. Authorized for cycle 4.
- Cycle 4 (same Opus agent, resumed): scale to the corrected envelope
  (~80 mm, proportional depth/protrusion, top anchored ~1.592), round
  the front-view read via the free-helix allowance, re-run all gates +
  A/B. Candidates 024d+.

## R19 PHASE A CLOSED (2026-08-04): ears → chain Fool-v2-024.blend

- **Chain = workdir Fool-v2-024d.blend (Opus cycle 4) promoted**
  (sha-verified copy). Free-rim closed-shell construction on the hole
  left by deleting the relief discs (216 verts deleted, +202 v/+280 f,
  442 tris/ear, min shell clearance 2.93 mm): freeze 0 verts moved,
  mirror 0.000, exact tri–tri new 0 (pre-existing pair 9028/9031 carried
  not grown), boundary 76, re-skin 1.0 Head, zero-weights 0, rest hash
  identical, pose sanity clean. Envelope all-pass (height 79.12 mm, top
  1.5918, depth 50.02, protrusion 24.44, tilt 10.42°); A/B ratio 30.8%
  vs sheet 30.3% (ear/head), 1.238 vs 1.239 (outer/half-width).
  Director separate-geometry ear ruling EXECUTED — relief ears dead.
- Lead eyes-on: side read = the drawn ear (helix/concha/lobe, slightly
  fuller than ink); front = rounded almond, slightly craggy silhouette.
- **Blind judge 5/10** (size/placement/style "broadly close"): named gaps
  all map to owned classes — top notch + upper-root seam = the
  PRE-EXISTING HEAD FOLD above the ear (verts 5223/5241, ~11 mm apart in
  x; cycle 3+4 both disclosed; ear ramps across it); "more protruding
  than drawn" = instrument-contested (measured ratios match the sheet);
  faceted lower edge = density-bound. Promoted per R14/R17 precedent +
  the #6 "read, not exactness" ruling.
- **DEBT (hair-conditioned): the head fold above/behind the ear** —
  bright flap edge in neck-45/side angles. If Phase B hair covers the
  strip, debt retires at the dressed re-judge; if not, a dedicated
  fold-repair task runs (builder rec: repair fold, rebuild ear top on
  the repaired head — build_ear_d.py is parametric and re-runnable).
- Builder's REPORT-A4-EARS.md was harness-blocked from disk both at
  builder and lead level; full verbatim content lives in the lead
  transcript + this summary; machine record = ear-validation-d.json +
  build_ear_d.py + renders-a4/ (16 d-* + 88 iteration renders).
- Paid-for lessons: (1) lead measurements are not exempt from the
  instrument rule — the 57 mm ear envelope under-measure cost one full
  Opus cycle; cross-check ratios (feature/head-height) before issuing
  envelopes. (2) codex `-i` images require the prompt BEFORE the -i
  flags or stdin-read hangs. (3) Claude subagent harness blocks .md
  report writes — builders must return report text in their final
  message; lead records it in ROUND-STATE.

## R19 PHASE B (hair) — cycle log

- Cycle 1 (Codex, 025b): hard gates GREEN (hair top 1.7520, crown
  +35.0 mm, 1,280 tris, Fool_Mesh freeze 0.000 + sha unchanged, rig
  untouched, rigid Head binding, no scalp gaps, FOLD COVERED with ears
  exposed — the Phase-A debt's coverage condition is met by this design).
  FORM send-back (lead eyes-on vs A-pose sheet): uniform vertical
  teardrop petals hanging to eye level (leaf-hood read), side petals
  curtaining ears, spiky nape, same-size clumps meeting at crease seams —
  the sheet draws shaggy laterally-swept layered shingles with outward
  flicks, fringe above the eyebrows. **Codex fail #1 on the hair-form
  piece.**
- Cycle 2 launched (codex-r19b2.log, candidates 025c+): flow-direction /
  shingle-layering / size-variety / ear-exposure / nape-flick directives;
  keep all green gates. A second form miss = Opus escalation per regime.

- Cycle 2 RESULT (025c): gates green again (hair top 1.75692, freeze
  0.000/sha unchanged, 1,920 tris, rigid binding, 3 documented look
  cycles) but form FAILED opposite-wise: boulder-pile cap PERCHED on the
  crown — hairline too high (bare temples/forehead), hair floating above
  the ears (fold strip re-exposed), occiput bare; no directional sweep
  visible. Cycle 1 = drooping petals, cycle 2 = perched boulders.
  **Codex fail #2 on the hair-form piece.**
- **OPUS ESCALATION JUSTIFIED (charter clause, recorded before launch):**
  hair form is judgment-heavy sculptural design (same class as the ear
  escalation, which delivered); Codex produced two gate-green form-fail
  candidates with opposite failure modes; hair blocks R19 close. One
  Opus cycle, both critiques verbatim, coverage-envelope mandate
  (builder-measured from the sheet with ratio cross-checks — mm envelopes
  from the lead are banned after the ear under-measure lesson), eyes-on
  iteration. Brief: fool2-r19/TASK-B3-HAIR-OPUS.md, candidates 025d+.

## ROUND 19 CLOSED (2026-08-04, 6th lead): ears + hair → chain Fool-v2-025.blend

- **Phase B cycle 3 (OPUS, 025d) promoted as chain Fool-v2-025.blend**
  (sha-verified). Fool_Hair = skull-hugging under-cap (16x5, ray-cast to
  scalp) + 49 overlapping shingle clumps in 3 tiers; 2,466 tris / 1,333 v /
  0 non-manifold; hair top 1750.05 mm; armature-modifier binding all-1.0
  Head; Fool_Mesh freeze 0.000 + sha unchanged; rig/eyes untouched;
  17 look cycles; deterministic build (found+fixed per-process hash()
  jitter — check earlier cycles' scripts for the same trap if re-run).
- Builder self-measured the sheet envelope ear-anchored (3.596 mm/px,
  eye-line cross-check 0.8 mm); ratio table in hair-validation-d.json.
  Lead adjudications: EARS STAY EXPOSED (drawn A-pose front hides them;
  v7 front shows them; director ear investment + #6 read-ruling win —
  11–29% width shortfall below ear line accepted); NO stray wisps
  (alpha-card = materials stage); ear_box_verts=79 is proximity, not
  intersection.
- **FOLD DEBT RETIRED**: hair covers the fold strip at all standard
  angles + poses (d-fold.png evidence) — the Phase-A condition met.
- Blind judge: hair 5/10, ears 6/10. Gap classes: materials-bound
  (feathery/tapered/airy), density-bound (faceted plates), one real
  carry: back mass swollen + residual rosette (no ref governs the back;
  costume hood partly covers). Closed per 80–90% + restraint rulings.
- **Debts → dressed re-judge:** hair back-mass/rosette; faceted plate
  read; wisps question at materials. (Plus standing pre-R19 debts.)
- STATUS.md Round-19 section + 8 renders pushed at close.
- **R20 = clothes & accessories** (A-pose sheet + clothing-layers sheet
  govern; hood note: covers part of back hair). Then materials, then
  Unity FBX gate ends the run.

## ROUND 20 (OPEN, 2026-08-04, 6th lead): clothes & accessories

- Brief: tooling/R20-BRIEF.md. Workdir fool2-r20/ (git-init'd). Launch
  law reaffirmed twice this round: `-s workspace-write` AND explicit
  `< /dev/null` on codex exec (first launch hung reading stdin and was
  killed; second attempt without </dev/null worked but treat the
  redirect as mandatory).
- **Phase A (Codex) VALIDATED:** clothing-inventory.json +
  CLOTHING-INVENTORY-REPORT.txt in fool2-r20/. Calibration law held
  (ear anchor 0.0 mm, eye line 0.8 mm; single full-figure pixel scale
  proven impossible — mesh-landmark ratios only). 8 garments skin-out
  (undershirt, pants, tunic, hood/cowl, harness, waist belt, bracers,
  boots) + accessories (rose, satchel, pouches, bindle, tankard),
  ratio-anchored envelopes, verbatim material text captured for the
  materials stage, ~16,300-tri budget, per-piece gates + battery-pose
  stress map.
- **LEAD TBD ADJUDICATIONS (construction/scheduling — no director
  needed):** (1) ONE hood shell — Hood & Cowl piece owns it, tunic
  built hoodless; (2) layer numbers = category order, anatomical
  nesting governs; (3) A-pose sheet precedence: ONE large left-hip
  satchel + only the pouches visible on the dressed sheet; (4) TANKARD
  OMITTED this round (not equipped on governing sheet; modular-gear
  candidate later); (5) bindle: behind-right-shoulder routing per
  inventory read, builder verifies eyes-on vs dressed back view;
  (6) tunic: split front panels / continuous back as drawn, center tan
  = pants; (7) colors + illegible swatch heading → materials stage.
- **Build fan-out (serialized, ONE Blender lane, Codex-first,
  escalation budgeted for tunic + hood/cowl):**
  B1 undershirt+pants → B2 tunic → B3 hood/cowl → B4 boots+bracers
  (own ref sheets!) → B5 harness+belt → B6 rose+satchel+pouches+bindle.
  Candidates Fool-v2-026a+; chain steps at lead's call per validated
  group. Gates per piece (from Phase A + brief): body/hair/rig freeze
  0.000+sha, rest AND posed no-poke-through (mapped battery poses),
  posed self-int, zero-weight + >4-influence + rigid-lag guards,
  silhouette A/B vs A-pose sheet.

## R20 B1 CYCLE LOG (7th lead, 2026-08-04)

- Cycle 1 (Codex, 026a): honest self-fail. Hard gates mostly green
  (freeze 0.000+sha, budgets 1,323/1,400 each, zero-weights 0, pose
  poke-through 0) but >4-influence fail (70+9 verts — capped BEFORE
  decimate, which re-interpolated), posed self-int "not numerically
  established", and form fail: shirt = skin-tight shell (no collar, no
  rolled cuffs, sleeves too long), pants = leggings. Lead eyes-on
  concurs. **Codex fail #1 on the base-layer form piece.**
- Cycle 2 (Codex, 026g): BOTH hard-gate fixes landed (0 verts over 4;
  exact tri–tri per pose established, 0 everywhere: garment-body,
  shirt-pants, self non-adjacent; one pre-existing body pair carried
  not grown). Form FAIL again, builder-honest + lead-confirmed worse
  in places: "collar" = detached floating bar in front of the neck +
  a drawn-on chest crease; cuffs = faceted mid-forearm rings; pants
  seat baggier but one smooth balloon — no gathered lower-leg tuck.
  **Codex fail #2 on the base-layer form piece.**
- **OPUS ESCALATION JUSTIFIED (charter clause, recorded before
  launch):** base-layer FORM (collar/cuff read, gathered-tuck drape) is
  judgment-heavy sculptural design; Codex produced two gate-green
  form-fail cycles with consistent critiques (the known
  greens-gates-misses-form pattern); B1 is the bottom layer every other
  garment stacks on, so it blocks the round. One tightly-scoped Opus
  cycle from 026g (its green gate machinery reusable), both critiques
  verbatim, eyes-on iteration mandate (R13-D/R19 precedent), same hard
  gates. Brief: fool2-r20/TASK-B1C3-BASELAYER-OPUS.md, candidates
  Fool-v2-026h+.

## DIRECTOR HALT (2026-08-04, mid-R20 — run SUSPENDED)

- **Director judgment on the face (elevated, supersedes prior face
  closures): NOT GOOD ENOUGH — eyes too far apart, no brow ridge, head
  too skinny.** The director is HAND-MODIFYING the base mesh in the GUI
  before any dressing continues; the run resumes from whatever mesh the
  director hands back. The R14/R17 face closures and their 4/10-ceiling
  reasoning are re-opened by this ruling; face-likeness debts are now
  director-elevated.
- Halt sequence executed by 7th lead: B2 tunic NOT launched (brief
  staged at fool2-r20/TASK-B2-TUNIC.md, unused); the in-flight B1
  cycle-3 Opus escalation builder was ordered to stop (no headless
  Blender process was live at halt; any candidate it saved is
  ABANDONED work); Blender lane surrendered to the director's GUI
  session (chain Fool-v2-025 loaded for them by the coordinator).
- **B1 state at halt (for the resume):** cycle 2 (026g) has ALL hard
  gates green — the influence-cap ordering fix and the exact tri–tri
  posed self-intersection instrument are proven and reusable
  (build_b1.py) — but form failed twice (cycle log above); the Opus
  cycle-3 form pass was mid-flight and unvalidated. NOTHING from B1 is
  promoted; chain head remains **Fool-v2-025.blend**.
- **Resume implications:** a director-modified base mesh likely changes
  head/face geometry → re-verify before reuse: weight transfer sources,
  ear/hair fit (Fool_Hair ray-cast to scalp), eye-globe placement vs
  new sockets, freeze-hash baselines (all sha tables reset), and the
  B1 garments must be refit (they were built against the old body).
  Treat every envelope/measurement anchored to head landmarks
  (3.596 mm/px ear calibration etc.) as suspect until re-measured.

## R19 HANDOFF (5th lead at context ceiling — ear build IN FLIGHT)

Successor: charter + this file + STATUS are the resume point.
- **Chain head: Fool-v2-023.blend** (joined mesh 6,661 v, 53-bone rig,
  skinned, pose-tested, thumb/thenar edit in). R18 closed and pushed
  (e97f17a). Workdir fool2-r18/ retains all candidates/instruments;
  fool2-r19/ is live.
- **IN FLIGHT at handoff: R19 Phase A ear rebuild, Codex PID 393067**,
  log fool2-r19/codex-r19a2.log. On completion VALIDATE per TASK-A-EARS
  gates (freeze guard outside ear regions, join manifold + 0 self-int,
  mirror, re-skin, neck-pose sanity, eyes-on: ears read dimensional, not
  discs; the task's STOP clause re separate-object ears needs a director
  check if triggered). Check builder liveness before declaring it dead.
- **Then Phase B hair** (write TASK-B-HAIR from R19-BRIEF ruling 3):
  blockout vs the A-pose sheet silhouette (both views), separate
  Fool_Hair, Head-bone binding, blind judge head A/B at close (ears+hair
  together lift the head read; irises/brows still materials-stage).
- Chain: promote ears as Fool-v2-024, hair as Fool-v2-025 (or one step if
  A+B validate together). STATUS + renders push at close as ever.
- Remaining after R19: clothes & accessories, materials (irises/pupils/
  brows — the gray-medium blind-score ceiling lifts there), Unity FBX
  gate ends the run (faces −Y and 1u=1m were chosen for this; verify by
  FBX inspection, no Unity editor).
- Instrument laws now standing (see R18 sections): whitelist renders;
  smear + rigid-lag + posed-self-intersection guards in every battery;
  geometric (never index-based) vertex sets after ANY topology change;
  zero-weight check after every weight edit; git-init new Codex workdirs.
- Open director items: none pending (thumb resolved in R18; ear ruling
  being executed; issues #2/#5/#6 closed).

## R18 HANDOFF (4th lead retiring at token ceiling — rigging round NOT started)

Successor: charter + this file + STATUS are the resume point, as ever.
Verified state at handoff: chain head = **Fool-v2-022.blend** (polished head
2,134 v + straightened body 4,599 v + eyes, all separate objects, seam
vertex-exact); no background processes (Phase-0 Codex exited; governor PID
8207 runs machine-wide); Blender lane FREE; GUI closed, renders remain the
director's channel; Claude near-exclusively reserved (Codex default,
escalation clause per charter — it fired once in R17 and worked).

The rigging round as I would run it (recommendations, not rulings):
- **Research first (Codex): Rigify-vs-custom for a Unity URP Humanoid
  target.** My lean: a CUSTOM deform-only armature authored
  programmatically — it fits the run's authored-and-instrumented method,
  avoids Rigify's control-rig export mess, and the Unity Humanoid bone set
  is small: hips/spine/chest/neck/head, shoulder+upper+lower arm+hand ×2,
  3-bone fingers ×5 ×2, upper+lower leg+foot+toe ×2. PLUS eye bones
  (director ruling: eyes rotate on their own bones — parent the globe
  objects, do not skin them). Head-body JOIN at skinning time (R16 ruling):
  merge-by-distance the 72 seam pairs, verify watertight + 0 non-manifold,
  re-run the standard instruments after the join.
- **Shoulder pose test — the gate that adjudicates the R16 debt (blind
  judge + builder both flagged it):** pose upper arm at −45° and −80°
  (lowered), render front/back/three-quarter; FAIL = visible collapse/pinch
  at armhole/deltoid; measure deltoid-ring cross-section area loss. If it
  pinches, targeted armhole rework happens BEFORE weights count as done.
- **Finger hinge test:** curl each digit 60° at each hinge; no collapse,
  no web tearing; knuckle loops are in place for this (R16 loop spec).
- Weights: auto-weights + targeted cleanup is fine at this budget; judge
  by pose-test renders (geometry-space + eyes-on, per the run's law).
- FBX/Unity gate at the end of rigging or as its own round: faces −Y and
  1 u = 1 m were chosen exactly for this trip; verify by FBX inspection,
  not the Unity editor (charter).
- Carried debts live in the R16/R17 close sections above; mouth/lower-face
  corner retopo is scheduled with blend-shape/materials work, NOT rigging.
- Workdir fool2-r18/ has gov.sh, validate_one.py (single-file instrument —
  respect the double-library-load rename trap), body_axes/neck_ring links,
  and the Phase-0 scripts. Remaining stages after rigging: hair, clothes &
  accessories, materials (irises/pupils + the STATUS blank-eye caveat
  retires there), Unity FBX gate ends the run.
