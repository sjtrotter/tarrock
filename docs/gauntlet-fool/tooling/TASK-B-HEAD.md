# Round 14 — Phase B: the head sculpt (Opus builder, headless Blender lane)

You are the escalation-tier builder. The lead's brief `R14-BRIEF.md` (same dir)
is BINDING — read it first, then this file, then:
- ROUND-STATE.md (one dir up) — "Method lessons" sections are paid-for law.
- docs/design/character-modeling-pipeline.md and
  docs/design/character-sculpt-reference.md (§2/§3; HALVE its lengths — old
  0.5 m/unit doc). Research storybook/stylized head technique as needed.
- R14-PHASEA-REPORT.md + head_sheet.json + eyeball_spec.json +
  head_stations_sheet.json + stations_016.json (all same dir) — the measured
  facts. Nose rows and jaw corners are LOW confidence: judge those against the
  sheet ink itself, not the numbers.

Source: `/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-016.blend`
(SACRED — never write to the project repo or `docs/`).
Workdir: `/home/betty/tarrock-gauntlet-work/fool2-r14/` ONLY (candidates
`Fool-v2-017.blend`, `017b`, … at workdir root; renders under `renders/`;
scripts under `scripts/`). The sibling `../r14/` belongs to ANOTHER run — never
touch it. You own the ONLY Blender lane: `blender --background --python`,
one process at a time, never the GUI, never port 9876.

## Machine protocol (director-ordered)
Before EVERY blender run: `cat /tmp/tarrock-governor/slots` — PAUSE means poll
every 15 s until clear. `/proc/loadavg` first value < 6; max thermal zone
< 90 °C (ignore unreadable zones).

## The target (lead's own read of the sheet, binding alongside the numbers)
Egg cranium; thin arched tapering brows; LARGE almond eyes, heavier upper-lid
line; small slightly-upturned nose, pointed tip, simple wings; gentle-smile
mouth per the v7 ink (~64 mm wide at Z 1.495); narrow jaw to a rounded chin
(Z 1.451); modest storybook ears, brow row (Z 1.592) to lobe (Z 1.483),
flaring to |X| ≈ 115 mm (skull wall ≈ 87 mm); slender neck. Style bar: 40%
Fable / 20% Kells / 15% Kena / 10% Dishonored / 10% fairy tales / 5% Ghibli —
stylized-simple WINS; the prior run died of over-detailed "gnarled" features.
Sculpt crops for your eyes: make your own from the sheet (front head ≈ px
370–540 × 60–240; side head ≈ 880–1050 × 60–240; S = 0.00201523 m/px, front
anchor (452,932), side (966,932), Z = (932 − row)·S).

## Build order (priorities; honest partials beat silent overreach)
1. Duplicate `Fool_SculptBase` → hidden in-file backup `Fool_SculptBase_prehead`
   FIRST. Then skull primary forms: cranium/occipital/forehead to the drawn
   contours (head_stations_sheet.json, ±3 mm where the sheet constrains);
   temporal planes; cheekbones; jaw/chin; KILL the horizontal jaw/head band
   (it is a curvature concentration — R13 law: build in slope space, diagnose
   with slope profiles, never height residuals); neck integration; manubrium
   band (z ≥ 1.32, ~15 mm proud, carried from R9).
2. Eyes (director ruling, rig-ready): open sockets with eyelid rims; the
   drawn cornea sits ~9.2 mm PROUD of 016's blank face — the brow/cheek region
   grows forward to meet it, then sockets recess. Eyeballs = separate objects
   `Fool_Eye_L`/`Fool_Eye_R`: UV spheres r = 35 mm, centers
   (±0.043, −0.0486, 1.571), origins AT centers, smooth-shaded, NOT joined.
   Socket clears each sphere ~2 mm radially so it can rotate.
3. Nose per the side-view ink (tip ~20 mm forward of the brow plane at
   Y ≈ −0.0836 region — verify against ink, rows are LOW confidence).
4. Ears per side/front ink; simple storybook form, no helix maze.
5. Mouth: lip band + gentle smile per ink; philtrum = faint hint or absent.

Sockets/nose/ears may use local bmesh/boolean/masked-remesh construction —
fields alone cannot make an ear. Global remesh discouraged (992 k verts); mask
any remesh to the head. Symmetry X EXACT for all head features.

## MANDATORY eyes-on loop (R13 law; render-RMS gates are retired)
After EVERY build cycle: render `scripts/head_render.py` (studio + rake,
tag per cycle), LOOK at the images, name what is wrong, fix, repeat. Compare
against your own sheet crops. Do not proceed on numbers alone. The BEFORE set
is `renders/r14base-*`.

## Gates (report real numbers; never claim an unexecuted gate)
- Below z = 1.30: byte-frozen vs 016 (max |Δ| ≤ 0.1 mm; verify against
  stations_016.json AND a direct vertex-delta check on the below-1.30 set).
- z 1.30–1.45: |Δ vs 016| ≤ 3 mm except the manubrium correction, which must
  still keep the drawn neck profile (head_sheet.json neck rows).
- z ≥ 1.45: drawn contours ±3 mm at constrained rows; ear/nose rows additive.
- Crown Z 1.717 ± 1 mm. Webbing probes 160/160 (tooling/webbing_probes.json).
- Body ONE manifold watertight component after socket cuts; eyeballs two
  separate closed spheres; all in-file backups intact.
- Presence: the head reads as the sheet's character in the RAKE renders —
  self-judge honestly in the report.

## Deliverables
- Candidates `Fool-v2-017*.blend` (final = highest letter; state which).
- Per-cycle renders + a final set (front/side/three-quarter/back, both lights).
- `REPORT-B-HEAD.md` (workdir root, ≤120 lines): what was built per scope item,
  gate numbers from the SAVED final file, per-cycle look-log (one line each:
  what you saw, what you changed), deviations, honest self-verdict per item.
- `r14-phaseb-validation.json`: machine-readable gate numbers.

The lead validates everything against the renders and the sheet; a false pass
costs a full round. Stated plainly: "I could not make X read well" is an
acceptable line in the report — silent overreach is not.
