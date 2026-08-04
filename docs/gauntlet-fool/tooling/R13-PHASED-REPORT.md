# Round 13 — Phase D (escalated builder) report

Candidate: `Fool-v2-016c.blend` (built from the 015 vertex state; `Fool_SculptBase_prepass2e`
verified byte-identical to `Fool-v2-015.blend`, SHA256 `56211378…21b3a17`, and untouched in the
output). Renders: `renders/r13esc-*` (ten views, framing identical to `r13base-*`).

## 1. Diagnosis (the round's real deliverable)

**In flat directional light the eye reads the surface NORMAL, not height.** Every artifact the
critics circled — "band", "plate edge", "island", "seam", "scored line" — is a *curvature
concentration*: a fast turn of the normal over a short distance. This explains all three unfixed
items and why Phases B and C could not move them.

**(1) The belt is a slope knee, not a ridge.** On 015's back the sagittal profile y(z) turns from
slope −0.42…−0.49 (sacro-lumbar recession) to +0.29 (thoracolumbar wall): a total turn of
**0.77 rad ≈ 44°**, curvature **+11 to +13 /m sustained over z ≈ 1.03–1.10**. Phase C's r=18 mm
residual p95 = 0.000 mm is *correct*: nothing is proud. **Phases B and C failed because they were
erasing a ridge that does not exist.**

The garment cue is not sharpness — it is **horizontality**. The turn's curvature centroid sits at
z = 1.0645…1.0709 across the *entire* back: it varies by only **6.5 mm** spine-to-flank. Real
lumbosacral anatomy is an arc (sacral triangle turns early and gently; gluteal mass turns lower
and harder behind the crest). A 44° normal swing running dead straight and dead level edge-to-edge
is a waistband.

**(2) The torso "plates" are plateau fields.** 016b's torso delta is single-signed (−3.09…+0.19 mm)
with saturated `c1_falloff` flat tops. A plateau *translates* a panel without *rotating* its
normal: interior contributes zero tone contrast, only the rim changes normal → bright rim around a
dead interior = island/plate. More amplitude only hardens the rim. Confirmed in render space: over
the costal window 016b's local edge energy is **1.940** vs base **1.515** — Codex made the edges
*harder* while adding no plane contrast.

**(3) The arm seam is the same defect on a cylinder — and it is inherited from 015.** Mean radius
r(x) has a slope kink of **0.137** concentrated at x ≈ 0.40 m (upper-arm taper meeting elbow flare).

**(4) New finding — a second garment line on the FRONT** at **z = 1.260–1.268 at every x** (the
pectoral lower border). Same defect class as the belt, previously unlogged.

## 2. What I built

Built from 015 (not 016/016b: their torso delta is the wrong *shape*, and 016b had already spent
arm silhouette budget). All fields analytic in |x| (exact X symmetry), built in **slope space**
(`tooling/esclib.py::slope_profile`) so curvature is bounded by construction, summed once,
graph-Gaussian blurred once (σ = 0.956 mm), applied along smoothed vertex normals.

| Field | Dose | Note |
|---|---|---|
| Belt redistribution (back, z 0.995–1.135) | 9.50 mm field, gain 0.904 | prescribed-curvature retarget, total turn preserved per x |
| Costal two-panel tilt (chevron, rounded apex) | 4.30 mm p-p | crease 45 mm, 92 mrad break; linea alba kept proud |
| Flank / semilunar plane | 1.81 mm | darkens the flank in front view |
| Arm (grooves, deltoid V, brachialis, elbow triad, biceps) | 7.00 mm p-p | all held off the tube's top ridge |
| Arm ring-seam de-kink | 0.571 mm | spreads the r(x) slope turn 20 mm → 55 mm |

**The belt's key move:** the redistribution was first capped at 4.2 mm by the y_max station.
Subtracting the per-z maximum over x converts the outward push into an **inward carve** — the
back-most x becomes the reference and stops capping the dose, while the *relative* differentiation
across the back is preserved. Physically this deepens the spinal furrow and flattens the sacral
triangle: the brief's own prescription. Dose more than doubled, 4.2 → 9.5 mm, at lower station cost.

## 3. Internal iterations (5 build → render → LOOK cycles)

1. Slope-smoothing belt fix + plateau-free torso tilt. **Looked: belt render unchanged** — the
   correction had targeted a noise statistic, not the real 44° turn. Costal crease *doubled*
   (my crease landed 15 mm off the inherited scored line).
2. Detected the arch line from data; belt retargeted by prescribed curvature. **Looked: belt band
   visibly broken up; front scalloped** at the x-station spacing.
3. Lateral Gaussian smoothing of all 2-D correction tables. **Looked: scallops gone, lumps stayed.**
4. Dropped the front de-band; moved the panel tilt off the pectoral shelf. **Looked: lumps
   persisted** → measured, and they are **015's own pectoral structure** revealed by added
   contrast, not mine (§4b).
5. Belt converted to an inward carve, dose raised to 9.5 mm. Final.

## 4. Gates — honest self-assessment

### (a) BELT — DIAGNOSED, PARTIALLY FIXED. **FAILS** the "no continuous band" test.

| | base 015 | 016b (Codex) | **016c** |
|---|---:|---:|---:|
| render band strength (pelvis-back) | 0.2205 | 0.2388 (+8%) | **0.2080 (−5.7%)** |
| turn-line arc across the back | 6.5 mm | — | **9.3 mm (+43%)** |
| band width at the midline | 25.2 mm | — | **30.2 mm (+20%)** |
| band width at abs(x)=0.09–0.12 | 30.7–36.1 mm | — | **24.1–26.5 mm** |

My eyes: the hard tonal step at z ≈ 1.085 in `r13base-zoom-pelvis-back.png` is now a soft, broader
gradient and no longer a clean straight edge. **But a faint continuous horizontal transition is
still there. I do not claim this gate.**

**Structural finding for the lead:** fully de-horizontalizing a 44° turn needs roughly **±7 mm** of
differential displacement across the back. The ±3 mm station budget allows less than half.
**The belt cannot be killed inside the current silhouette gate.** Either open the gate for the
posterior pelvis (z 1.00–1.13 — check whether the drawn sheet even constrains the back there) or
accept the belt as logged debt.

### (b) TORSO — **PASS** on integration, PARTIAL on legibility.
Local edge-hardness (high-pass RMS) — the thing Codex failed twice:

| window | base | 016b | **016c** |
|---|---:|---:|---:|
| costal chevron | 1.515 | 1.940 | **0.972** (−36% vs base, −50% vs Codex) |
| mid abdomen | 0.538 | 1.155 | **0.537** |
| lower abdomen | 1.183 | 0.990 | **0.656** |

No circleable plates, no island rims, no faceting; the scored costal LINE is now a soft plane
break. Full-figure front-flat torso energy: base 7.687 → 016b 7.745 (+0.8%) → **016c 7.884 (+2.6%)**.
A viewer at full figure sees a soft chevron under the chest and a flatter, distinctly separate
belly plane — legible but still quiet. Chest lead 4.76 → 6.98 mm (belly never leads).

**Remaining artifact, honestly:** the pectoral shelf reads lumpy. High-pass RMS there: base
**1.170**, 016c **1.108** — *lower* than base. **The lumps are 015's own and I did not add them**;
raised contrast makes them more noticeable. Needs a band-pass deband, not this round.

### (c) ARM — **FAIL** on relief. Seam improved.
Seam: the vertical line at x ≈ 0.40 is visibly fainter (kink spread 20 → 55 mm). Relief: upper-arm
high-pass RMS base 14.484 → 016b 14.484 → **016c 14.578 (+0.6%)**. That is not "faint", it is
nearly nothing. Deltoid V, biceps/triceps split, ulnar line and elbow triad are present in geometry
at 1.0–3.0 mm but do not register in this view/lighting. **Stated plainly as the brief permits:
full-figure arm presence still underwhelms after honest effort.** Root cause: in the front ortho
view the arm's intermuscular boundaries lie near the tube's silhouette edges, where the station
gate forbids work (top-ridge bin migration cost 12 mm in iteration 1).

### (d) GUARDS — **PASS**, printed from the saved file (`validation-d.json`)
Topology 992,787 v / 1,985,570 e / 992,785 f · crown Δ **0.000 mm** · sole Δ **0.000 mm** ·
silhouette max **2.915 mm** (≤3) · webbing **160/160** · `Fool_SculptBase_prepass2e` present and
byte-identical · all nine backups intact · nothing written to the project repo.

| region | z (m) | extent | Δ mm |
|---|---:|---|---:|
| torso | 1.0200 | y_max | −2.915 |
| torso | 1.0225 | y_max | −2.484 |
| torso | 1.1625 | y_min | +2.469 |
| torso | 1.0175 | y_max | −2.409 |
| torso | 1.0250 | y_max | −2.375 |
| torso | 1.1725 | y_min | +2.369 |
| torso | 1.1700 | y_min | +2.367 |
| torso | 1.1750 | y_min | +2.361 |
| torso | 1.1675 | y_min | +2.356 |
| torso | 1.1775 | y_min | +2.339 |

### (e) RENDERS — **PASS.** Ten `r13esc-*` views, same camera poses/ortho scales as `r13base-*`.
**Defect inherited from Phase A:** `r13_render.py` gives the `-flat` views *identical* settings to
the plain views — `r13base-back.png` and `r13base-back-flat.png` are byte-identical. The "flat
single-direction light" the brief asked for was never rendered, in any phase. I kept the settings
unchanged so the A/B against `r13base-*` stays valid; the lead should fix this before Round 14.

## 5. Overall verdict

**Not a pass.** (b) is won, (a) is diagnosed and materially improved but the band survives, (c)
fails. The round's durable value is the diagnosis: the belt is a slope knee whose defect is
horizontality; plateau fields cannot make plane contrast; and **the belt is unfixable inside the
±3 mm silhouette gate** — a lead decision, not a builder one.

## 6. Artifacts / TBD
- Front garment band at z ≈ 1.264 (§1.4) — detected, deliberately **not** applied (the per-x 1-D
  curvature retarget fights the pectorals' 2-D structure and produced lumps). Logged as debt.
- Pectoral-shelf lumpiness in 015 — needs a band-pass deband S(σ₂)−S(σ₁), not a plain smooth.
- Arm relief in the front ortho view — may need a view/lighting change or a relaxed arm station
  rule rather than more amplitude.
- Tooling worth promoting: `tooling/esclib.py`, `scripts/esc_build2.py`, `scripts/esc_bandmetric.py`.
