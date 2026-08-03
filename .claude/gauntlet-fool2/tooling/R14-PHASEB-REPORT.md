# R14 Phase B — head sculpt (Opus builder)

**Final candidate: `Fool-v2-017e.blend`** (workdir root). Chain: 017 skull →
017b deband → 017c face/eyes/nose/mouth → 017d ears → **017e** finish + gates.
Machine-readable gates: `r14-phaseb-validation.json`. Renders: `renders/`
(`r14base` = BEFORE, `r14c1`/`r14c1b`/`r14c2`/`r14c3` per cycle, `r14final`).

## THE ROUND'S KEY CORRECTION — eyeball centre Y

Phase A's `eyeball_spec.json` put the eye centre at **Y = -48.6 mm**, derived by
reading the side view's OUTER PROFILE at the pupil row and calling it the cornea.
At that row the outer profile is the **midline nose-root**, not the eye. Two
independent measurements say otherwise:
1. The v7 sheet carries a **third registration circle on the SIDE view** (rows
   34-66, cols 930-962), which Phase A never used -> centre **Y = -40.30 mm**.
2. A 35 mm sphere fitted to the drawn canthi (medial X 24.2 -> Y -69.1; lateral
   X 70.5 -> Y -41.1, off the side-view ink) -> **Y = -41.0 mm**.

I used **Y = -40.30**. This matters: the brief's consequence of the old number --
"the drawn cornea sits ~9.2 mm PROUD of 016's blank face, the brow/cheek grows
forward to meet it" -- would have built a **bug-eyed face**. With the corrected
centre the globe sits **1.8 mm** proud and the real job is a *lateral* broadening
of the face plane (016's face falls from -74.4 mm at X=43 to -47.7 mm at X=70.5,
so the globe's outer edge protruded through the temple). X = +-43, Z = 1.571 and
r = 35 mm are as briefed. (The sheet's circles measure r ~ 32 mm; brief wins.)

I also re-measured the nose from the ink: Phase A put tip/base at Z 1.5134/1.5074;
my sub-pixel side scan puts the **tip at Z 1.5346, 17.7 mm proud**, base Z 1.5135.
Phase A had flagged the nose LOW confidence, so I judged against the ink as told.

## Gates (measured on the SAVED `Fool-v2-017e.blend`)

| Gate | Required | Measured | |
|---|---|---|---|
| Freeze below z 1.30 | <= 0.1 mm | **0.000000 mm**, 714 841 verts, count-identical | PASS |
| z 1.30-1.45 vs 016 | <= 3 mm + manubrium | max 13.96 mm -- **entirely** the manubrium field; outside its support **0.0001 mm** | PASS |
| z >= 1.47 drawn contours | +-3 mm | z 1.470-1.700: x_half max **2.33**, y_front max **1.99**, y_back max **1.92 mm** | PASS |
| Crown Z | 1.717 +- 1 mm | **1.717010 m** | PASS |
| Webbing probes | 160/160 | **160/160** | PASS |
| Body one closed manifold | required | 1 010 144 v / 1 010 036 f, **0 non-manifold, 0 boundary, Euler = 2** | PASS |
| Eyeballs two closed spheres | required | 1986 v each, 0 boundary, 0 non-manifold, r = 35.000 mm, origins exactly at centres, smooth-shaded, **not joined** | PASS |
| Socket clears globe | ~2 mm radial | all 5 aperture probes inside the globe; **min clearance 0.84 mm** | PARTIAL |
| In-file backups | intact | 13 pre-existing + new `_prehead`, `_preface`, `_preears` | PASS |

Apex exception: at z >= 1.705 the contour is 2.8-7.7 mm (x_half) / up to 18.2 mm
(y_back at 1.715) *inside* the drawn line -- the correction is tapered off above
z 1.696 to protect crown-Z, and the drawn target within 2.5 mm of the apex is a
single-pixel row scan. Reported, not hidden.

## What was built, per scope item

1. **Skull primary forms** -- analytic anisotropic per-slice scale r -> r*K(z,phi);
   K from three Gaussian-smooth (sigma 8 mm) ratio curves against sub-pixel drawn
   contours with exact cos^2/sin^2 cardinal blending, so K is C-inf. Cranium +3-4,
   crown dome +5-9, forehead +4 mm; occipital, jaw taper, chin, neck. Freeze
   transition by a **tanh amplitude envelope**, not a weight ramp. **Manubrium
   (R9 debt): measured 15.2 mm proud at z 1.37, corrected to the drawn neck
   profile** (max pull-back 15.04 mm, |x| < 80 mm, front-facing only).
2. **Eyes** -- open sockets; aperture = drawn almond (48.2 x 34.4 mm at X +-47.4,
   Z 1.5689, superellipse p 1.4); globe-following bed with a long lateral blend;
   lid rims (upper 1.8x lower). `Fool_Eye_L`/`Fool_Eye_R` as specified.
3. **Nose** -- ridge/tip/wings from my ink scan; peak 17.7 mm at Z 1.5346, rounded
   section, a hint of nostril crease, no interior drilling.
4. **Ears** -- additive (016 had none): closed tapered lens (160x80), EXACT boolean
   union, concha scoop 7.5 mm, soft helix rim 2.2 mm. |X| 113.4 mm vs drawn 116;
   Z 1.513-1.594, Y +28...+80 as measured.
5. **Mouth** -- one soft lip mass with a single split (gentle upturned smile,
   +-32.5 mm at Z 1.4953). Philtrum absent, as permitted.

## Per-cycle look-log (rendered, then LOOKED, every cycle)

- **c1 v1-v2** worse banding than base -> (a) drawn targets were pixel staircases
  (2.015 mm treads) that I resampled onto, (b) my ripple-erase was subtracting the
  raw grid's own sampling noise. Fixed: sub-pixel extraction + analytic scale.
- **c1 v3** two new bulges -> instrumenting the ratio curves showed silhouette
  extremes binned at 1.25 mm, finer than the mesh's 1.5 mm voxel z-layering, so
  sparse bins under-reported by up to 9 mm. 2.5 mm bins + min population: +-0.9 mm.
- **c1 v4-v5** new creases at chin/apex -> tanh envelope + wider apex taper.
  Taubin moved only 0.045 mm, proving the bands are 5-15 mm form ripple, not
  vertex noise. Removed the vertex-binned `d_ring` term (layering aliased it into
  3-6 mm noise, ~36 deg of slope swing).
- **DECISIVE** ray-cast profile of **016 itself**: p95 0.521 / max 1.446 mm vs the
  candidate's 0.352 / 0.761. **Bands are inherited; my candidate is smoother.**
  They read louder only because the reshaped face is flatter. Stopped chasing.
- **c1b** ray-cast deband, one pass at gain 1.6 (band-pass peak gain ~0.64);
  iterating diverged at the taper edges (4.8 mm correction for a 0.3 mm defect).
- **c2 v1** eyes read as *goggles* -> 88x68 mm bed cratered 12 mm, 2.2 mm lid, and
  my own z-mask edge at 1.485 cut a line across the lower face. Mask deleted.
- **c2 v2-v5** then a round ball (aperture falloff opened only 72% of the almond),
  then a raised *blister* (bed outer blend 7 mm for a 14 mm rise). Blend widened to
  ~25 mm, medial carve deepened; all five aperture probes then clear the globe.
- **c3-c5** ears right but faceted -> lens 72x36 -> 160x80 (~1.0 mm faces); Taubin
  on the ear region (0.227 mm); all gates then measured.

## Honest self-verdict, per scope item

- **Skull forms -- GOOD.** Contours within +-2.33 mm over z 1.47-1.70, egg cranium,
  domed crown, real chin and jaw taper, occipital right. Manubrium debt closed.
- **Eyes -- ACCEPTABLE, not the sheet's eye.** Rig-ready and geometrically correct
  (globe seated, socket clears, spheres separate). But it reads as *a ball in a
  socket*, not the drawn **big almond with a heavy upper-lid line**. The medial
  canthus has no lid edge at all -- the globe fades into the face there. **I could
  not make the eye read as the sheet's eye.**
- **Nose -- ACCEPTABLE.** Right place and projection; reads as a small pointed
  nose. In profile it is sharper and more beak-like than the storybook ink.
- **Ears -- ACCEPTABLE.** Right position, extent and mass; concha reads. Faint
  concentric rings from the UV-sphere lens survive in the concha hollow.
- **Mouth -- WEAKEST ITEM.** Present and correctly placed, but shallow; it reads
  as a scored line more than lips.
- **Presence -- PARTIAL.** Unmistakably a face now, primary forms right. The
  **inherited horizontal banding across the mid-face (z ~ 1.516 strongest) is the
  biggest remaining presence problem**, and it is a 016 chain defect, not this
  round's (016 p95 0.521 mm vs candidate 0.352). Killing it properly needs a
  deband that PREDATES the features (a chain-level pass on 016); I did not run one
  after the features went in because the 3-15 mm band-pass window overlaps the lid
  rims and the mouth split and would have eaten them.

## Deviations from the brief

- Eyeball centre **Y = -40.30 mm**, not the briefed -48.632 mm (evidence above).
- Chin ~4.6 mm shy of the drawn line at z 1.455: the drawn chin bottom (1.451) sits
  1 mm above the frozen band and forcing it produced a measured 2.56 mm crease at
  z 1.4605. I chose the compliant smooth chin.
- x_half at z 1.455-1.465 is 5-8 mm inside the drawn *front* contour, which below
  z ~ 1.48 is the **neck**, not the jaw -- not a head target, correction disabled.
- Render-RMS scalars not used as gates (retired by the brief); all gates are
  geometry-space plus the mandatory eyes-on loop above.
- Blender lane: headless only, one process at a time, governor checked before
  every run; the GUI and port 9876 were never touched.

---

# Cycle 2 -- face-read fixes (second Opus builder)

**Final candidate: `Fool-v2-017h.blend`.** Chain: `017e` -> **`017f`** (mass /
bands, restores the body from cycle 1's in-file `_preface`) -> **`017g`**
(eyes / brows / nose / mouth) -> **`017h`** (ears + gates). Machine-readable
gates: `r14-phaseb-validation.json` (cycle 1's numbers preserved under
`cycle1_archived`); a standalone copy is `r14-phaseb2-validation.json`.
Renders: `renders/r14c5-*` (mass, featureless), `r14c6-*` (features),
`r14c7-*` (ears), **`r14v2final-*`** (final, 4 views x 2 lights).
Scripts: `scripts/m1_mass.py`, `m2_features.py`, `m3_ears.py`, `m4_gates.py`,
`r14c2lib.py`, plus the diagnostics `dbg_probe.py` / `dbg_debandonly.py` and
the machine-protocol wrapper `gov.sh`.

## Method: I restarted the face from the featureless skull

TASK-B2 fix 6 says the band work has to happen BEFORE the fine feature lines are
re-cut. The cleanest way to obey that was to restore `Fool_SculptBase` from
cycle 1's own in-file `Fool_SculptBase_preface` (post-skull, post-deband, no
features) and rebuild the face on top. Cycle 1's finished head is preserved
in-file as `Fool_SculptBase_c1feat`; nothing was lost.

## THE ROUND'S KEY FINDING -- what the bands actually were

Cycle 1 measured the bands (016 p95 0.521 mm) and concluded they are inherited.
That is right, but the filter was at the wrong scale and, more importantly, the
band was being **put back after it was removed**. Measured, in this order:

1. A sigma_z 9 mm smooth-shell reprojection removed ~40% of them. A sigma 6 mm
   coordinate low-pass that moved **1.8 mm p95** removed almost none. A sigma
   **15 mm** low-pass that moved **7.2 mm p95** removed almost none. No Gaussian
   can move 7 mm of material and leave a crisp line -- so the bands could not be
   surviving the filter.
2. **Isolation render** (`dbg_debandonly.py`, `scratchpad/lponly.blend`):
   low-pass ALONE gives a clean skull. Low-pass + contour lock gives a banded
   one. The lock was the source.
3. Why: the lock scales r by target/measured per z. The measured side is a
   per-2.5 mm-slab EXTREME and the drawn side is a **2.015 mm pixel staircase**;
   ~0.5% of ratio ripple on a 90 mm radius is ~0.45 mm of surface ripple at
   exactly the observed 10-25 mm scale. Gaussian-smoothing the curves at sigma
   8 mm, then 20 mm, was not enough -- a degree-8 polynomial over 245 mm can
   still express ~30 mm structure, i.e. a band.
4. Fix: the lock now writes its ratio as a **degree-4 polynomial** (finest
   expressible structure ~60 mm), so it is structurally incapable of writing a
   band. Order: heavy low-pass -> lock -> light low-pass -> two closing lock
   passes. Filtering LAST was tried and rejected: it costs 6 mm of contour
   (sigma^2/2R badly underestimates the shrink at the chin).

**Second finding, for the lead.** The ear renders **perfectly clean in the
Workbench studio pass and striped in the EEVEE sun rake, from identical
geometry** (compare `r14v2final-side-studio.png` with `-side-rake.png`). A
component of what cycle 1 and the blind judge read as banding is shadow-map
acne in the rake setup, not the mesh. The jaw band at z ~ 1.485 is real -- it
shows in both engines and in 016 -- but the fine striations are not.

## Gates (measured on the SAVED `Fool-v2-017h.blend`)

| Gate | Required | Measured | |
|---|---|---|---|
| Freeze below z 1.30 | <= 0.1 mm | **0.000000 mm**, 714 841 v, count-identical | PASS |
| z 1.30-1.45 vs 016 | <= 3 mm + manubrium | max 14.00 mm, **entirely** the inherited manubrium field; outside its support max **1.63 mm**, p95 0.00 | PASS |
| z >= 1.47 drawn contours | +-3 mm | x_half max **1.01** (p95 0.92), y_front max **1.71** (p95 1.40), y_back max **1.48** mm | PASS |
| Crown Z | 1.717 +- 1 mm | **1.716964 m** | PASS |
| Webbing probes | 160/160 | **160/160** | PASS |
| Body one closed manifold | required | 1 012 055 v / 1 011 872 f, **0 non-manifold, 0 boundary, Euler = 2** | PASS |
| Eyeballs two closed spheres | required | 1986 v each, 0 boundary/non-manifold, r = 35.000 mm, origins exactly (+-0.043, -0.0403, 1.571), smooth, **not joined** | PASS |
| Socket rim clears globe | ~2 mm radial | **+1.09 mm** (cycle 1: +0.84) -- improved, still short of 2 mm | PARTIAL |
| All aperture probes show globe | required | **5/5 visible** (dist 31.4-34.8 mm) | PASS |
| In-file backups | intact | 31, incl. `_prehead`, `_preface`, `_preears`, `_c1feat`, `_c2preface`, `_c2preears` | PASS |

Contour accuracy improved on every axis against cycle 1 (2.33 / 1.99 / 1.92 mm).

## Per-cycle look-log (rendered, then LOOKED, every cycle)

- **c5 v1** sigma 4 mm shell deband + open-loop chin -> bands unchanged, chin
  still 3.7 mm shy. The chin loop delivers only ~55% of commanded amplitude
  (envelope + lateral falloff + diffusion each take a share) -- which is exactly
  how cycle 1 ended 4.6 mm shy. Made it **closed-loop**.
- **c5 v2** chin overshot 2.5 mm: I had smoothed the MEASURED front line across
  the chin's bottom edge, biasing it backwards. Reverted to a raw measurement.
- **c5 v3-v6** the band hunt above; ended with degree-4 lock + two-stage
  low-pass. Cranium and mid-face read clean; the inherited jaw band at z ~ 1.485
  survives, softened.
- **c6 v1** features exploded to 177 mm: the eye fields are functions of (x, z)
  only, so they also selected the matching patch on the BACK of the skull. Added
  a hard positional Y gate.
- **c6 v2** nose read as a rectangular block -- `falloff(X/W, 0.45, 1.10)` is a
  PLATEAU, which the brief forbids. Also two full-width horizontal creases above
  and below it: `np.interp` with `left=right=0` is continuous in value but not in
  SLOPE. Replaced by an analytic raised cosine.
- **c6 v3** eye opened only on its lateral half. Instrumented it: the nose-root
  guard was reaching x = 21 mm, across the aperture's medial third, and the tanh
  cap was 14 mm where the medial socket needs 18. Both fixed.
- **c6 v4** the eye still read weakly -- in a single-material clay render the
  globe and the face are the same grey, so the eye is read **entirely from the
  lid edge**. Added a lash groove inside the upper aperture for the lid to cast
  onto, and raised the rim to 4.6 mm.
- **c7** ears as a thin hinged plate with the sphere's pole axis mapped to Y;
  clean union, no concentric rings, |X| 115.9 mm at z 1.5535.

## Honest self-verdict, per fix item

1. **Primary mass -- GOOD, the round's clearest win.** The muzzle is gone; the
   cheeks taper continuously into a real chin; the chin/neck junction no longer
   steps. Chin at z 1.4550 reaches **-74.98 mm against the drawn -76.78** --
   1.8 mm shy, where cycle 1 was 4.6 mm shy, and the remainder is held back by
   the gate guard (2.36 mm max motion below z 1.45), not by a crease. The
   midline S-profile sits on the drawn ink within 0.07 mm from z 1.465 to 1.530.
2. **Eyes -- IMPROVED, still not the sheet's eye.** Aperture 51 x 33 mm against
   cycle 1's 48 x 34, floor raised to reduce exposed lower globe, medial canthus
   now has a lid edge, upper lid is 4.6 mm proud against 1.6 below, globe visible
   at all five probes, rim clearance up to 1.09 mm. It now reads as an almond
   with a heavy upper lid rather than a bare ball. But **it is still smaller and
   rounder than the drawn eye**, and the lower-lid crescent is heavier than the
   ink. I did not get the wide, near-horizontal upper-lid graphic to dominate.
3. **Nose -- GOOD.** The triangular spike is gone: bridge shortened 49 -> 31 mm,
   blade rounded, ~17 mm projection kept, tapers into the brow plane. Reads as a
   small softly-upturned wedge in both views. The two crease lines it used to
   throw across the face are gone.
4. **Mouth -- STILL THE WEAKEST ITEM.** Widened to the drawn 64 mm+ with real lip
   volume (2.7 mm) over a 1.5 mm split, and it is no longer a scored slit. But in
   the rake it still reads as more than one line, because the inherited jaw band
   sits ~10 mm below it and the two read together. **I could not make the mouth
   read as one clean pair of lips.**
5. **Ears -- GOOD.** Rebuilt as a thin hinged flap (11 mm core, tapering to the
   rim) instead of cycle 1's 60 mm lens; one helix ridge and one concha scoop;
   the UV pole moved to the ear's front/back tips so the concentric rings cycle 1
   noted **cannot** occur. Extent held: |X| 115.9 mm at z 1.5535. Clean in the
   studio pass.
6. **Bands -> planes -- PARTIAL.** The cranium and mid-face bands are gone in
   both lights. The **jaw band at z ~ 1.485 remains** in both lights; it is the
   inherited r12 artifact, it sits where my filter has to hand over to the
   1.30-1.45 gate, and removing it needs a chain-level pass on 016 rather than a
   head-local one. I did not add decorative cheek/temple planes: the first
   attempt rendered as visible ellipse rings and I removed it.

**Presence -- self-judged.** In the studio pass this now reads as the sheet's
character: egg cranium, thin arched brows, almond eyes with a heavy upper lid,
a small upturned nose, a gentle-smile mouth, a narrow jaw to a rounded chin,
and modest storybook ears. In the rake pass the jaw band and the shadow-map
striations still cost it. I would score it clearly above cycle 1 but not yet
finished.

## Deviations / notes

- Body vert count is now 1 012 055 (was 1 010 144): different ear geometry.
- The ear boolean re-indexes the mesh, so the z 1.30-1.45 comparison against 016
  is an order-free BVH closest-point distance, not a vertex-index diff.
- Socket clearance is 1.09 mm, not the suggested 2 mm. The body inside the
  aperture sits at 31.4-34.8 mm from the eye centre -- permanently inside an
  opaque globe, which is the normal game-rig arrangement, but it is not 2 mm of
  radial air and I am not calling it a pass.
- Blender lane: headless only, one process at a time, `scripts/gov.sh` run
  before every invocation; the GUI and port 9876 were never touched; nothing
  outside the workdir was written.
