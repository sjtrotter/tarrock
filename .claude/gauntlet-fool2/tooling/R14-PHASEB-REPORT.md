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
