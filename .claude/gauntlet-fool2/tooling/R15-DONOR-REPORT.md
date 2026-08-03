# R15 Phase A1 — Donor Head Acquisition + Topology Inspection Report

Phase: A1 (Sonnet). Date: 2026-08-03. Workdir:
`/home/betty/tarrock-gauntlet-work/fool2-r15/`. Governor respected throughout
(single Blender lane, headless only, slots polled before every run; observed
range 1-3 slots / loadavg 1.2-1.7 / thermal max 65°C during this session —
never PAUSE, never a GUI touch, port 9876 untouched).

## 1. What we got

**Primary source (thebasemesh.com) — REJECTED, not a silent substitution.**
The brief's named URL `thebasemesh.com/asset/head` 404s. I did not stop
there: I pulled the site's own complete sitemap
(`dynamic-asset_..._0_5000-sitemap.xml`, all 1254 asset entries) and
independently cross-checked it against the public GitHub mirror
`M3-org/base-meshes` (901 models, cloned and inspected locally). Neither
contains a human head/face asset under any slug. The site's only
"head"-named entries are non-human/hard-surface (`screw-head`,
`headstone-01..05`, `deer-head`, `rattlesnake-head`, `arrowhead` variants,
etc.); the only anatomical item on the whole site is `skull-(no-teeth)`, a
bare bone skull with no eye/mouth soft-tissue topology — unusable as an
eye/mouth-loop donor. Conclusion: thebasemesh.com is a hard-surface/prop/
architectural CC0 library, not a character library. It never had a head
asset; the research doc's recommendation was explicitly unverified
("model library wasn't inspected in this pass") and does not hold up.
Full evidence in `donor/LICENSE-EVIDENCE.md`.

**Fallback used (per the brief's own "if genuinely unobtainable" clause):**
itch.io — **"3D Low Poly Head" by zakariya el onsri**
(https://zakariya-el-onsri.itch.io/3d-low-poly-head). Free, CC0-labeled
("Free for personal and commercial use – no attribution required (CC0)...
please do not offer it for sale" — verbatim, with the one added restriction
noted honestly in the evidence file). Downloaded
`3D Low Poly Head.zip` (34,548,598 bytes) via itch.io's own AJAX
download-token flow (no bypass, no login required — the asset is genuinely
free); saved to `donor/3D-Low-Poly-Head.zip`, extracted to
`donor/extracted/3D Low Poly Head/`.

**Format note (report honestly, not glossed over):** the packaged `.blend`
and its `.blend1` backup are both just Blender's default startup scene
(Cube/Camera/Light) — the actual head geometry is **not** in either blend
file, apparently a packaging mistake by the author. The `.fbx`/`.obj`/`.glb`
exports **do** contain the real model (object name `haed.001`), so the OBJ
was used for import and analysis. This is worth flagging to the director/
Codex phase since anyone re-opening "the donor blend" expecting the head
will hit the same empty-cube surprise.

## 2. The numbers

Imported headless via `blender --background --python` (`wm.obj_import`),
analyzed via `bmesh` (no GUI, no MCP/port-9876 touched).

**Full imported mesh** (head skin + ~545 separate hair-strand/hair-clump
islands, all merged into one OBJ object on export):
- 138,858 verts / 129,463 faces / 268,384 edges
- Quads 97.28% (125,943) · Tris 2.72% (3,520) · Ngons 0%

**Isolated main skin island** (the actual head+neck+shoulder-drape surface;
identified via connected-component/BFS over face adjacency — the single
largest of 546 islands, all others being hair geometry, 650-750 faces for a
few big clumps down to ~6-30 faces for individual strands):
- **3,070 verts / 3,048 faces / quads 99.44% (3,031) / tris 0.56% (17) /
  ngons 0%** — this is the number that matters for retopo-donor purposes.

**Scale/units:** no real-world-scale claim was made anywhere on the itch.io
page (unlike thebasemesh's site-wide claim). Measured bbox of the skin-only
mesh in Blender units: X −1.644..1.642 (width 3.286), Y −2.021..1.462 (depth
3.483, face points −Y — **already matches our own sculpt's `faces −Y`
convention**, confirmed by render: camera on the −Y side sees the face,
camera on +Y side sees the hair bun/back of head), Z −1.965..0.931 (height
2.896). These bounds include the shoulder-drape, not head-alone, so raw
bbox-width is not directly comparable to our sculpt's ~245mm head width —
**scale is mismatched and arbitrary, registration/rescale to our head
landmarks is A2's job as scoped in the brief, not evaluated further here.**

**Full head or bust:** **bust** — head + neck + a stylized draped
garment/collar down to the shoulders (visible clearly in the back-facing
probe render as a wide scalloped hem). Not a plain isolated head. This is
fine for our purposes (shrinkwrap only needs the head+neck region; the
draped-shoulder portion is irrelevant and will be ignored/clipped).

**Boundary loops on the main skin island: exactly 2** (everything else is
closed/watertight):
1. **Mouth** — 25 verts/edges, center ≈ (0, −0.596, −0.126), radius ≈ 0.131.
   This is the mouth cavity of the source's screaming/open-mouth expression
   — a genuine open aperture, not a texture-only mouth.
2. **Shoulder-drape hem** — 32 verts/edges, center ≈ (0, −1.637, −1.161),
   radius ≈ 1.242 — the open bottom rim of the draped garment. Irrelevant
   to head retopo; noted for completeness only.

**Eyes: NOT an open aperture.** The wireframe renders show a clean,
pole-free, concentric quad-ring flow spiraling into each eye socket (this
part of the donor's topology is genuinely good and worth using as a visual
reference) — but bmesh confirms there is **no boundary loop at either eye**;
the socket is a closed, watertight indentation (a sculpted depression), not
a cut hole. There is no separate eyeball mesh exposed through it. This means
the donor cannot hand us a ready-made open eye socket for our separate
`Fool_Eye_L/R` spheres — Phase B will have to cut the depression open and
re-terminate the rim, though the surrounding ring flow feeding into that cut
is already clean and reusable as-is (heuristic scan of the eye-region for
poles found **zero** — the ring quality is real, not just a rendering
illusion).

**Mouth corners — this is the finding that matters most for the gate:**
Directly measured (not eyeballed) via bmesh: both the left corner
(idx 2955, x=−0.106) and right corner (idx 2743, x=+0.106) of the mouth
loop have **total valence 3 = 2 boundary edges + exactly 1 outward edge**.
Sampling additional rim vertices (top/bottom mid-lip) shows the same
pattern: **every vertex around the mouth rim is a valence-3 pole**, i.e.
the entire mouth ring is a single fan of poles, not a multi-loop concentric
structure. This is precisely the defect our own R15 gate rules out by name
("at least 2 loops must exit each mouth corner or the corner reads as a
cut/pinch under deformation" / "no poles at mouth corners") — this donor's
mouth, as shipped, fails that rule at both corners and around the whole
rim. It is visually convincing in a static render (the radiating spokes
read fine as a still image) but is topologically the wrong shape for an
animatable mouth and cannot be used as-is.

**Poles overall:** 107 pole vertices (valence≠4) on the 3,070-vertex skin
mesh outside the mouth rim itself (~3.5%) — a normal, unremarkable
density for a game head; the mouth-rim poles are the one concentrated,
specifically-disqualifying cluster.

## 3. Loop verdict: **USABLE-WITH-FIXES**

- **Bulk cranium/cheek/nose/jaw coverage:** usable. 99.44% quad, low
  incidental pole density, sensible edge flow (visible in both wireframe
  renders), already oriented to our `faces −Y` convention. Good Shrinkwrap
  donor for the A2 mechanical-projection phase.
- **Eye rings:** the surrounding ring flow is clean and pole-free and worth
  keeping as a visual/structural reference, but the socket itself is closed
  — it must be cut open and re-terminated by Phase B (Opus) before an eye
  socket exists at all. Not a donor defect so much as a donor gap; expected,
  matches the brief's manual-eye-ring plan already.
- **Mouth ring: must be rebuilt, not reused.** Every rim vertex including
  both corners is a valence-3 single-exit pole — the exact "reads as a
  cut/pinch" failure mode the gate is designed to catch. Phase B needs to
  add a second concentric loop around the mouth and re-terminate the
  corners with ≥2 clean outward edges each, per the brief's own spec; the
  donor's mouth cannot be shrinkwrapped through unmodified.
- **Jaw/neck seam:** no clean neck-cut boundary exists in the donor (the
  neck flows uninterrupted into the shoulder-drape) — a neck seam will need
  to be authored by the builder as the brief already anticipated
  ("builder proposes, lead accepts"), not inherited from this donor.
- Not a REJECT: the bulk-coverage value (quad-dominant, low pole density,
  correct facing convention, real head+neck geometry to shrinkwrap against)
  clearly outweighs the two named, already-anticipated manual-fix areas.

## 4. Fallback status

Fallback **was used**, and used correctly per the brief's own contingency
clause ("fallback: itch.io CC0 low-poly head... If both fail inspection, the
loops are built manually on a Shrinkwrap'd grid — report, don't stall").
thebasemesh.com was investigated thoroughly (full sitemap + independent
GitHub mirror cross-check, not a quick guess) and confirmed to have no head
asset at all, not merely a bad URL. The itch.io fallback passed inspection
well enough for **USABLE-WITH-FIXES**, so the "build loops from scratch on
a bare Shrinkwrap grid" last-resort path was not needed.

## Files delivered

- `donor/3D-Low-Poly-Head.zip` — original download (34.5 MB), plus
  `donor/extracted/` — unpacked `.blend`/`.blend1`(empty)/`.fbx`/`.obj`/
  `.glb`/textures/renders.
- `donor/LICENSE-EVIDENCE.md` — full license text, source URLs, date,
  thebasemesh rejection evidence.
- `donor/donor_imported.blend` — full OBJ import (head skin + all hair).
- `donor/donor_skin_only.blend` — main skin island isolated (hair removed),
  used for the corner/pole measurements above.
- `donor/donor_face_front_wireframe.png`,
  `donor/donor_face_threequarter_wireframe.png` — required wireframe-over-
  shaded face-region inspection renders (front + three-quarter).
- `donor/donor_mouth_front_wireframe.png` — supplementary close-up used to
  find/verify the mouth-corner pole defect.
- `donor/probe_front_+Y.png`, `probe_back_-Y.png`, `probe_left_+X.png`,
  `probe_right_-X.png` — orientation-finding turntable probes (confirmed
  face points −Y, matching our sculpt convention).
