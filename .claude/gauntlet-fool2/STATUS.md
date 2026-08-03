# Gauntlet v2 — The Fool, from scratch — live status

Builder-vs-critic loop building the Fool's character model in Blender from scratch,
judged against `docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png` (base body)
and `Fool-Orthographic-A-Pose.png` (dressed Fool). Fresh conventions: 1 u = 1 m,
faces −Y, mirror axis X, soles at Z=0, bald crown 1.72 m. Chain: `Fool-v2-###.blend`
(uncommitted, in `docs/design/3d-models-inwork/`).

Workflow: references & blockout → merge & sculpt → head sculpt → head retopo → body
retopo → rigging → hair → clothes & accessories → materials → Unity FBX gate.

| Stage | Status |
|---|---|
| References & blockout | in progress (body done; arms/hands/neck next) |
| Merge & sculpt | — |
| Head sculpt | — |
| Retopo (head, body) | — |
| Rigging | — |
| Hair | — |
| Clothes & accessories | — |
| Materials | — |
| Unity FBX gate | — |

---

## Round 1 — scene setup, calibration, body blockout (2026-08-02)

**Builder (Opus):** fresh scene; v7 sheet calibrated as front/side image empties
(0.00201523 m/px, verified sub-pixel by detecting the sheet's guidelines in a
screenshot). Body blockout: cranium, jaw, chest, pelvis centered; thigh/calf/foot
mirrored across X — 7 blocks, octagonal cages, Subsurf 3, 472 cage verts. All
landmarks within the ¼-head gate (mesh 6.32 head-heights vs sheet 6.39); every joint
interpenetrates ≥ 10 mm on evaluated geometry. Files: `Fool-v2-001` (setup),
`Fool-v2-002` (blockout).

| Front overlay | Side overlay |
|---|---|
| ![front](renders/r1-front.png) | ![side](renders/r1-side.png) |
| ![front head](renders/r1-front-zoom-head.png) | ![side head](renders/r1-side-zoom-head.png) |

**Critic (Opus, fresh context):** **PASS — build arms on it.** Independent
sheet→render mapping (sheet guide rows matched against render rows, residuals < 1 px):
mesh contour within ±2 px (~4 mm) of the drawn contour continuously, both views;
landmark rows all on the guides; L/R symmetry error 0.00 px mean. Named gap — the
blocks are still separate shells (pelvis bottom is a flat plate through which the
thighs pass) — expected at this stage (merge is the voxel-remesh step), but three
findings carry forward: cut a real groin V into the pelvis underside before merge,
flatten the pillowed foot soles, and the arm build must supply the deltoid out to
~0.244 m half-width (chest's 0.200 m is acromion width, intended).

**Round verdict: PASS.** Carry-forward list logged in ROUND-STATE.md. Next: Round 2 —
neck, arms, hands (pipeline Step 2) from the sheet's left-limb cutouts.

---

## Round 2 — neck, left arm + hand blockout, attach (2026-08-02)

**Builder (Opus):** arm chain blocked vertically over the sheet's left-limb cutouts
(registered to BOTH cutout views at once via X=front-cutout / Y=side-cutout centres),
verified there (`Fool-v2-003`), then attached by vertex rotation to the shoulder-socket
locator; neck cylinder fitted to the drawn profile (`Fool-v2-004`). 9 new blocks, 560
cage verts. Arm lengths within 2 mm of the reconciled drawings; shoulder half-width
reaches the drawn deltoid at 0.244 m; all joints ≥ 0.018 m interpenetration.

| Front overlay | Side overlay |
|---|---|
| ![front](renders/r2-front.png) | ![side](renders/r2-side.png) |
| ![3/4](renders/r2-three-quarter.png) | ![hand](renders/r2-front-zoom-hand.png) |

**Critic (Opus, fresh context):** **SEND BACK.** Passing: symmetry (1–2 px), arm span,
wrist/hand reach, neck width and lean, finger simplicity (correctly rejected the fanned
side-cutout envelope). Named gap: **the elbow has no shape** — near-constant 43–46 px
tube where the sheet draws a 52–53 px forearm swell flanking a 42 px elbow neck (mesh
−19 mm at the swell, +8 mm at the neck, mirrored both arms). Secondaries: arm inferior
surface 6–10 mm high into the axilla; shoulder integration is saddle-then-bump (trap
plateau up to 18 mm low, deltoid crown 6 mm proud — must be fixed as ONE edit);
thumb 21 mm long, ~13° abduction, no thenar wedge; finger/palm split finger-short.

**Round verdict: SEND BACK → Round 3 = fix round (elbow profile, axilla, one-edit
shoulder integration, thumb, finger/palm split) + the critic's three verification
demands (arm-root vs socket circle with torso hidden, wrist roll printout, joint-centre
coordinates).**

---

## Round 3 — arm fix round (2026-08-02)

**Builder (Opus):** re-extracted the drawn silhouette (line-centre flood fill), then
ran damped iterative solvers on the cage rings to the drawn targets. Elbow
swell–neck–swell restored (worst station −0.3 mm vs drawn); axilla wedge closed to
0.0 mm; shoulder saddle (−18 mm) → monotone within 3.7 mm; thumb −21 mm with thenar
wedge; finger/palm split 0.877. Verifications: arm root 6.7 mm from the socket-locator
centre (inside, 0.16 r); hand roll 0.52°; forward sweep pinned 4.26° total, living at
the shoulder (4.11°). `Fool-v2-005.blend`.

| Front overlay | Elbow zoom |
|---|---|
| ![front](renders/r3-front.png) | ![elbow](renders/r3-front-zoom-elbow.png) |
| ![shoulder](renders/r3-front-zoom-shoulder.png) | ![3/4](renders/r3-three-quarter.png) |

**Critic (Opus, fresh context):** 4 of 5 findings FIXED on the renders (elbow, axilla,
shoulder silhouette, thumb); the split fix REGRESSED the hand — finger block roots
~10 mm low, arriving as a hard dorsal ledge at the knuckle (was a 5.9 mm gradient, now
9.8 mm step). Fresh eyes: arm depth pinched in plan exactly at the shoulder joint
(local min where the deltoid should be widest); cranium modeled to the EAR line
(~28 mm/side wider than the drawn skull) with no ear masses; top render was
perspective, not ortho. **SEND BACK.**

**Lead rulings:** inter-finger 5 mm slots are NOT a blocker (pipeline already merges
hands separately at finer voxel); ears = bring cranium in to the skull line now, ears
come at sculpt; deferral list corrected (hand residual is dorsal).

**Round verdict: SEND BACK → Round 4 = final pre-merge fixes (finger-root ledge,
shoulder plan pinch, cranium width, groin V, foot soles) + honest ortho re-renders.**

---

## Round 4 — pre-merge fixes (2026-08-02)

**Builder (Opus):** finger dorsal ledge closed (12.3 mm step → ≤2.2 mm, seam step now
matches the drawn line's own drop); shoulder plan pinch solved (13-pass ring solver,
depth now monotone, deltoid widest); groin plate rebuilt as converging V/dome with
crotch apex preserved to 0.07 mm; soles planar within 0.74 mm at exactly Z=0. Also
DISPUTED two critic premises with sheet-frame measurements: the cranium was already on
the drawn skull line (+2.7 mm, not +28 mm — the critic had a 300-px frame error) and
the sole "collapse" was a 1.2 mm dome. All renders certified true-ortho.
`Fool-v2-006.blend`.

| Front overlay | True-ortho top |
|---|---|
| ![front](renders/r4-front.png) | ![top](renders/r4-top.png) |
| ![hand](renders/r4-front-zoom-hand.png) | ![crotch](renders/r4-crotch-tq.png) |

**Critic (Opus, fresh context, MERGE GATE):** all five claims verified on the renders;
cranium dispute adjudicated FOR the builder (refuted by an order of magnitude); lead's
inguinal-crease ruling holds; whole-figure fit ±3 mm front, +0.5/+4.5 mm side.
**SEND BACK — pre-flight only, no art changes:** certify solid intersection at finger
roots / arm root / foot / thigh, state voxel sizes against the narrowest slots, and
widen the inter-thigh slot (17 mm vs drawn 26 mm — nudge thighs ~4 mm/side out, which
also improves the drawing match). Corrections logged: trapezius residual is 10.4 mm at
two stations (not ≤3.7); brow plane starts +9 mm proud for the sculpt brief.

**Round verdict: SEND BACK (pre-flight) → Round 5 = thigh nudge + certification
numbers + THE MERGE (pipeline Step 3: backup, apply modifiers, join body, voxel
remesh; hands stay separate for a finer pass).**

---

## Round 5 — pre-flight + THE MERGE (2026-08-02)

**Builder (Opus):** disputed the thigh-translation prescription with sheet-frame
numbers (outer line was already ±2 mm; the error was inner-surface thickness) and
fixed it properly: inner-biased Z-tapered widening, slot 16.8 → 26.2 mm (drawn
24–26 mm), outer contour unchanged to 0.01 mm. Full 15-joint certification passed
(worst: pinky↔palm 16.8 mm vs 10 mm gate). **Merge executed:** 10 body blocks →
`Fool_SculptBase`, voxel 5 mm beat 4 mm on the pipeline's coarser-wins rule —
87,615 verts, 1 component, 0 holes, 0 non-manifold, crotch open at 26 mm, landmark
drift ≤ 0.33 mm; targeted seam-only smooth (armpit 4.8 → 0.9 mm Laplacian). Backup
cages, pre-remesh duplicate, and applied hand shells all preserved in-file.
Discovery: inter-finger gaps are 0.19–0.58 mm — the planned fine-voxel hand pass is
impossible (no voxel separates 0.2 mm). `Fool-v2-007/008.blend`.

| Merged body 3/4 | Front overlay |
|---|---|
| ![3/4](renders/r5-three-quarter.png) | ![front](renders/r5-front.png) |
| ![crotch weld](renders/r5-weld-crotch.png) | ![hand xray](renders/r5-hand-xray-top.png) |

**Lead ruling (hand plan):** spread digits at shell level to ≥4 mm separation
(rig-friendly standard), hand-only voxel remesh (trial 2.0/1.5 mm), then EXACT
boolean union onto the body at the 25 mm wrist overlap.

**Round verdict: MERGE LANDED. Next: Round 6 = hand resolution (spread, fine remesh,
boolean attach) → then the sculpt rounds begin.**

---

## Round 6 — hand resolution: spread, fine remesh, boolean attach (2026-08-02)

**Builder (Opus):** found the root cause of the 0.2 mm gaps — the drawn fingers
CONVERGE (yaw −2.4° to −5.8°), they were never parallel. Fanned the digits 5° per
adjacent pair about their buried roots (index −7°, middle −2°, ring +3°, pinky +8°;
thumb untouched) → all pairs ≥ ~4 mm. Hand-only voxel remesh: 2.0 mm webbed the
Middle|Ring base (rejected, kept as evidence); 1.5 mm clean. EXACT boolean union onto
the body at the 38.7 mm wrist overlap in 1.39 s; 8 sliver faces dissolved; wrist
"boot-cuff" step Taubin-smoothed 2.5 → 1.4 mm at +0.0004% volume. **Full figure now
ONE watertight component: 153,966 verts, 0 boundary, 0 non-manifold, 0/96 webbing
probes.** All pre-states kept as hidden backups. `Fool-v2-009.blend`.

| Spread fan (top ortho) | Wrist boolean seam |
|---|---|
| ![hand](renders/r6-hand-top.png) | ![wrist](renders/r6-wrist-weld.png) |
| ![front](renders/r6-front.png) | ![3/4](renders/r6-three-quarter.png) |

**Round verdict: LANDED (hand visual judgment folds into the sculpt Pass 1 critic).
Next: Round 7 = Sculpt Pass 1 — masses & silhouette + the carried fix list (inner
leg line, trapezius, ankle step, crown, jaw pan).**

---

## Round 7 — Sculpt Pass 1: masses & silhouette (2026-08-02)

**Builder (Opus):** all Tier-1 numpy fields, symmetry exact by construction. Carried
fixes landed with per-station tables: inner leg to ±1.1 mm (was −7.7), shoulder
saddle→acromion-crest structure built, ankle step gone, crown to drawn exactly, jaw
mandible tuck, brow to ±3 mm, palm dome. Pass-1 masses at storybook restraint (pec fan
2.2 mm peak, diagonal glute wedges, ribcage back plane, trochanter dents). Two
paid-for method lessons logged (Gaussian-only profile smoothing; cyl_fair corrugates
oblique surfaces). `Fool-v2-010.blend`.

| Front overlay | 3/4 |
|---|---|
| ![front](renders/r7-overlay-front.png) | ![3/4](renders/r7-three-quarter.png) |
| ![shoulder](renders/r7-zoom-shoulder-tq.png) | ![back](renders/r7-back.png) |

**Critic (Opus, fresh) + Codex blind A/B:** proportion gate COMPREHENSIVELY MET
(front and side contours ±3 mm at every sampled row; symmetry ≤1 px; trapezius
finding closed for good). Codex (blind, 2 runs) independently corroborated the one
real defect class: **banded transitions** — a ruler-straight terrace across the whole
upper back (5 mm height variation over 296 mm), a neck-base collar welt, the deltoid
fenced by grooves, sternal notch/clavicles overdone, crown facet residual.
**SEND BACK — one blending session, not a re-sculpt.**

**Round verdict: SEND BACK → Round 8 = boundary-blending session (back terrace, neck
welt, deltoid fencing, clavicle backing-off ~40%, crown egg).**

---

## Round 8 — boundary blending (2026-08-02)

**Builder (Opus):** proved every defect was Round-7 displacement (pre-sculpt render
was clean), so the fixes smooth Round 7's own delta field rather than the surface —
bounded by construction. Back terrace: straightness metric 317.6 mm → 26.5 mm
straight-run (cleaner than the pre-sculpt reference); neck welt traced to two field
cutoffs meeting, removed; clavicles −40% toward the drawn line; crown fill-only
(apex untouchable by rule). Method lesson logged: map the residual in 2-D before
choosing filter radius. 21,858 verts moved, max 3.65 mm; no station pushed past the
verified ±3 mm. `Fool-v2-011.blend`.

| Back (terrace gone) | Shoulder 3/4 |
|---|---|
| ![back](renders/r8-back.png) | ![shoulder](renders/r8-zoom-shoulder-tq.png) |

**Lead verdict (eyes-on + numbers): ACCEPTED.** Carried forward: deltoid final
integration (still circleable), upper-arm ring banding, jaw/face bands (head-sculpt
round owns the face). Next: Round 9 = Sculpt Pass 2 — remesh to 2.5 mm + bony
landmarks ("this is where the character appears") + carried band cleanup.**

---

## Round 9 — Sculpt Pass 2: remesh + bony landmarks (2026-08-02)

**Builder (Opus):** both prescribed voxel sizes (2.5/2.0 mm) provably WEB the fingers
— landed at 1.5 mm, 992,787 verts, webbing 0/102. Full §3 landmark set as unified
Tier-1 fields (clavicle 6-pt S, knee complex, scapula, malleoli, ulnar head, elbow
triad, knuckle arc, PSIS/ASIS); arm rings + deltoid fence cleaned; silhouette drift
≤1.3 mm. `Fool-v2-012.blend`.

| 3/4 | Knee zoom |
|---|---|
| ![3/4](renders/r9-three-quarter.png) | ![knee](renders/r9-zoom-knee.png) |
| ![clavicle](renders/r9-zoom-clavicle-tq.png) | ![back](renders/r9-back.png) |

**Critic (Opus, fresh) + Codex blind:** **SEND BACK — the harshest verdict of the
run.** The landmarks read as engraved line-work and pin-dots on an unsculpted volume
(scapula = uniform scratches around a flat region; knee = 5–6 circleable dabs; ASIS
"a second pair of nipples"); four terraces survive (both shins, sacrum, abdomen,
head/jaw); Codex blind: "soft adult heavyweight," "mannequin-smooth — narrow and
articulate the ribcage-to-waist transition." Gate ("reads bony in flat light") NOT
met. Method fix ordered: build PLATES and MASSES first (Clay-mass + Flatten), let
lines be the edges of forms; kill terraces by residual removal; flatten the belly so
the chest leads; de-dab knee/ASIS/PSIS/wrist; re-cut the clavicle as a true S.

**Round verdict: SEND BACK → Round 10 = form-first Pass-2 redo.**

---

## Round 10 — form-first Pass-2 redo (2026-08-02)

**Builder (Opus):** new anisotropic terrace tool (radius-grid over (z,φ), Gaussian
along Z only) killed the four terraces; falloff bug (infinite gradient at cutoff —
the source of every "stuck-on bump" halo) fixed at source; scapula rebuilt as a
plate, knee as one mass, clavicle wire removed, thoracic plate + costal arch added;
chest-vs-belly measured 7.7 mm forward (drawn 8.1) at the sampled stations.
`Fool-v2-013.blend`.

| 3/4 | Side belly |
|---|---|
| ![3/4](renders/r10-three-quarter.png) | ![belly](renders/r10-side-belly.png) |
| ![scapula](renders/r10-zoom-scapula.png) | ![clavicle](renders/r10-zoom-clavicle-tq.png) |

**Critic (Opus, fresh) + Codex blind:** **SEND BACK.** Banked as real: scapula plate,
knee one-mass, terrace kill (~3.5/4), clavicle wire removal. But the round was net
SUBTRACTIVE — "softer, not bonier"; Codex verdict word-for-word identical to last
round ("mannequin-smooth", style 3/10); pixel-delta audit shows elbow (0.86%),
pelvis (1.8%), wrist (3.2%) were never redone; new halos at malleolus/ulnar head;
whole-profile check says the belly still leads the chest globally.

**Round verdict: SEND BACK → Round 11 = ADDITIVE structural round: shoulder girdle
(hard acromion corner, clavicle S ending above the plateau, humeral head), sacral
triangle + iliac crest planes, halo removal + ulnar shaft line, elbow triad,
chest-leads-belly globally.**
