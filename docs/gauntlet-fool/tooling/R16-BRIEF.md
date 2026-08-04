# Round 16 — BODY RETOPO (lead brief)

Lead (4th), 2026-08-03. Workdir `/home/betty/tarrock-gauntlet-work/fool2-r16/`.
Source: chain `Fool-v2-019.blend`, READ-ONLY — objects `Fool_SculptBase`
(~1.01M v watertight, whole figure incl. sculpted head), `Fool_HeadRetopo`
(2,058 v / 3,970 tris, bounded at neck seam z=1.442 by a 72-v ring + 2 hidden
eye rims), `Fool_Eye_L/R` (r=35 mm, separate), backups. Conventions: 1 u = 1 m,
faces −Y, X mirror, soles at Z=0.

## Lead rulings (logged per charter)

- **Method: AUTHORED graded charts** — the R15 lesson stands (authored
  cube-sphere with (chart,i,j) bookkeeping beat the shrinkwrap scaffold, which
  shredded invisibly). Torso chart + limb tube charts + hand charts, ray-fit
  from per-segment axes, bridged combinatorially. Shrinkwrap is permitted only
  as a local fitting aid and every wrap step is gated by the FULL instrument
  suite (below) — never vertex-RMS alone.
- **Budget (working estimate, not canon):** body 8–16k tris; head is 3,970;
  keep the naked figure ≤ 20k total, leaving room for clothes/hair in the
  25–40k whole-character estimate.
- **Neck seam:** the body terminates in a 72-v ring bonding VERTEX-EXACT to
  `Fool_HeadRetopo`'s neck boundary (position match ≤ 0.01 mm per vertex).
  Density-reduction rings are allowed below the seam (diamond/spiral quads),
  not at it.
- **Hands: full five fingers** (hero/player character), each digit individually
  enclosed, knuckle support loops at every hinge, no webbing (probe-checked).
  Standard game density (6–8 sided digits); thumb gets its own chart.
- **Feet:** the sculpt is expected toe-less (single foot mass) — Phase A
  verifies; retopo matches what the sculpt has. Sole stays planar at Z=0.
- **Deformation loop spec (gate):** ≥3 ring loops through each of shoulder,
  elbow, knee, hip crease; dedicated wrist and ankle rings; regular spine/waist
  loops through the torso; NO pole within 15 mm of a bend crease (armpit,
  elbow pit, knee back, groin crease, finger hinges).
- **Deviation gate:** ≤1.5 mm RMS / ≤3 mm max vs `Fool_SculptBase` over the
  body, EXCLUDING named divergences the retopo owns (armpit and crotch
  simplification, inter-finger cleanup, seam-adjacent blending) — each named,
  measured, rendered in the report.
- **Instrument suite on EVERY fit/wrap gate (R15 paid-for lesson):** vertex
  deviation AND face-centroid deviation AND inverted-normal count AND
  self-intersecting-pair count AND mirror residual. Plus: quad share ≥95%,
  X-symmetry exact, watertight-or-cleanly-bounded, finger webbing probes,
  neck-seam exact-match check.
- **Eyes and chain untouched:** `Fool_Eye_L/R` and `Fool-v2-019.blend` are
  never written. Candidates save as `Fool-v2-020*.blend` in the workdir; lead
  promotes.
- **Charter milestone at close:** after promotion, the retopo'd naked figure
  (head + body + eyes) is ALSO saved as
  `docs/design/3d-models-inwork/YoungAdultMale-base.blend` — the charter's
  "clean generic young-adult man" checkpoint, fulfilled at the retopo stage
  (uncommitted, like all blends).

## Phases

- **A (Codex, mechanical, headless lane):** inventory + data extraction +
  instruments. See TASK-A-BODY.md. Deliverables validated by lead, then
  promoted into tooling/.
- **B (Opus, judgment):** authored body retopo per the rulings above —
  the R13/R15 escalation lesson applied at kickoff (chart layout and joint
  loop placement are judgment work). Eyes-on renders every internal cycle.
- **Close:** lead validation (independent instrument re-run on the SAVED
  candidate) + Codex blind judge (shaded read AND wireframe vs the loop
  spec + sheet). STATUS/ROUND-STATE/renders push; chain promotion to
  `Fool-v2-020.blend`; YoungAdultMale-base.blend milestone save.

## Protocol (unchanged)

Governor slots before every heavy run (PAUSE → 15 s poll); ONE Blender lane
(a Codex Blender run IS the lane); loadavg < 6; temp < 90 °C; GUI stays closed
— renders are the channel; blends uncommitted; honest partials beat overreach;
never touch other sessions' workdirs (`fool2-*` only, plus our legacy `r13`).
