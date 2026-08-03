# Round 13 RE-RUN — Phase C: corrective pass on candidate 016 (Codex, one Blender lane)

You are correcting the Phase-B candidate. Inputs (never modify):
- BASE CHAIN FILE: /home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-015.blend
- PHASE-B CANDIDATE: /home/betty/tarrock-gauntlet-work/r13/Fool-v2-016.blend
  (contains hidden `Fool_SculptBase_prepass2e` = exact 015 state — this gives you
  the round's delta field: delta = current − prepass2e, per-vertex, same topology)
- Phase-B report: /home/betty/tarrock-gauntlet-work/r13/REPORT.md (read it)
- Tooling: /home/betty/tarrock-gauntlet-work/r13/tooling/ (fieldlib.py etc.)
OUTPUT: `Fool-v2-016b.blend` + `REPORT-C.md` in the workdir root; renders as
`r13fix-*` (same ten views, identical framing to the r13base-*/r13final-* sets).

Machine protocol as before (governor slots — CURRENTLY 1, poll if PAUSE; loadavg
< 6; thermal max < 90000; ONE blender process, sequential; never the GUI, never
port 9876). Work only under /home/betty/tarrock-gauntlet-work/r13/.

## Lead diagnosis of Phase B (accepted findings — build on them, don't relitigate)

The forms are correctly placed and the mm amplitudes hit their field targets; the
failures are (1) integration, (2) the belt dose, (3) a metric band mismatch.

1. FACETED PLATE EDGES (torso): your effective blur sigma was 0.855 mm — an order
   of magnitude too tight. Storybook plane transitions need ~8–15 mm of edge
   softness. METHOD (paid-for lesson): operate on the ROUND'S OWN DELTA FIELD —
   delta = mesh − prepass2e. Graph-blur the delta field itself until its edge
   transitions have effective sigma ≥ 8 mm (more iterations / larger alpha-radius,
   report the achieved sigma), then re-gain each region so the post-blur peak
   returns to the Phase-B calibrated target (abdomen 2.17 mm, costal 1.58 mm,
   waist 0.99 mm; ±5%). This kills the plates AND the flank island lumps in one
   move. Do NOT re-place any form.
2. BELT: the 0.287 mm erase was two orders too small against a multi-mm ridge.
   Measure the actual posterior band residual (erase/Gaussian-baseline at
   r ≈ 18 mm — the proven deband radius — over the z ≈ 1.03–1.08 back band),
   then REMOVE 70–90% of that measured ridge: full removal at the spine (the
   sacral triangle interrupts it), fading removal laterally, fullness preserved
   within ~30 mm of the ASIS. Verify in the back-flat render A/B that the
   continuous band is GONE — this is a pre-committed closing gate.
3. ARM SEAM + arm quietness: the vertical seam near the hand-root is your hard
   X cutoff — replace it with a C1 taper to zero over ≥ 40 mm ending at the
   wrist crease (webbing probes must still pass 160/160). Then raise the arm
   plane-split and elbow-triad delta amplitudes by 1.5–2× (delta-field scaling,
   then blur-integrate as in item 1). SILHOUETTE BUDGET WARNING: arm y_min
   stations at z 1.32–1.35 are already at −2.34 mm of the ±3 mm budget — any
   added displacement there must be tangential/redistributed, not stacked
   negative; re-verify those stations explicitly.

## Metric revision (lead ruling — supersedes the Phase-B gate arithmetic)

Sigma-6 high-pass measures ~14 mm texture; plane contrast is low-frequency (your
abdomen RMS DROPPED because flattening removes texture — the old gate was
unwinnable). Extend the metric script (new file tooling/rms_metric2.py, keep the
old one unchanged) to report BOTH bands per region, computed identically on
base(015), final(016), and fixed(016b) renders:
- HP band: luminance − blur(σ6) (as before).
- MID band: blur(σ6) − blur(σ40) (captures ~15–90 mm structure = plane breaks).

REVISED GATES (these decide whether the 5th cycle ends):
(a) BELT DEAD: belt HP RMS < clavicle HP RMS, AND back-flat A/B visibly clean.
(b) TORSO PRESENCE: abdomen+costal+waist MID-band RMS ≥ 1.5× their base(015)
    values, with NO faceted edges in the torso zoom (describe honestly).
(c) ARM: arm MID-band RMS ≥ 2× its base(015) value; seam gone in zoom-arm.
    (If arm still reads quiet at full figure after this, say so — the lead may
    close with arm-relief debt per the standing pre-commitment.)
(d) Costal midline mesh-continuity check still passes; all Phase-B geometry
    guards re-run and pass on 016b (topology, crown/sole, silhouette ±3 mm vs
    015 global, webbing 160/160, no moats).

## Report (REPORT-C.md, ≤120 lines)
Per-item: achieved blur sigma, re-gained peaks, belt ridge measured vs removed,
arm changes, both-band RMS table (base/final/fixed × 6 regions), gate results
(a)–(d), worst-10 silhouette stations, new artifacts seen (be harsh), deviations.
HONESTY: a false pass costs a full round; failures reported as failures are
cheap.
