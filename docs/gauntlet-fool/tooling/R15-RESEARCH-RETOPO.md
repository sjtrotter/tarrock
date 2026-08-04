# R15 Research — Head Retopology Best Practice (2024–2026), Blender 5.x

Scope: answer the R15-BRIEF-DRAFT TBDs for retopologizing the Fool head sculpt
(`Fool-v2-017h.blend`, ~1.01M-vert watertight `Fool_SculptBase`, stylized-simple
face, separate eyeball spheres) into a rig-ready mesh for PC+mobile Unity URP.
No Blender/mesh work was done here — this is a literature/tool survey.

## 1. Method comparison for this case

| Method | Tools (Blender 5.x status) | Price/License | Fit for us |
|---|---|---|---|
| **Manual poly-build** | Blender native Poly Build tool (free, built-in, works on 5.x). **PolyQuilt** (free/open, historically THE standout free manual retopo addon) — broken on Blender 5.0 (`bgl` module removed; "No module named 'bgl'" reported working on 4.5, failing on 5.0) [github.com/Dangry98/PolyQuilt-for-Blender-4.0/issues/32], with unofficial community forks targeting 5.0 (`github.com/nyko4000/PolyQuilt-for-Blender-5.0`, unverified maturity) and an official Extensions-platform fork listed for "4.2+" (unclear if patched for 5.x — UNVERIFIED). | Free | Best judgment-per-vertex control for the eye/mouth loop placement that R14 flagged as the unresolved "reads weak" problem. Highest labor cost. |
| **Template-head wrap/shrinkwrap** | Blender's own Shrinkwrap modifier (free, native, always works) driving a clean donor topology onto the sculpt; **Wrap4Blender** (Superhive, "Wrap for Blender," ~commercial addon, positions itself as a cheaper alternative to R3DS Wrap, does feature-point matching for eye corners/lip line) [superhivemarket.com/products/wrap4blender] — price/exact Blender-5.x support UNVERIFIED (product page 403'd to fetch); **R3DS Wrap4D/Wrap Indie/Pro** (industry standard for scan wrapping, per-seat/subscription, described by third parties as "very expensive," subscription-first) — not a Blender addon, standalone app with OBJ round-trip, definite overkill/cost for this project. | Wrap4Blender: paid, one-time (Superhive norm), exact figure unverified. R3DS: paid, subscription-heavy, NOT free for commercial. | Fastest path to a rig-correct topology IF a good CC0/commercial-safe donor head exists (see §2) and its proportions are close enough that shrinkwrap projection doesn't collapse the eyelid/lip loops. Native Shrinkwrap is free and sufficient if we own/build the donor. |
| **Auto-quad remesh** | **Quad Remesher** (Exoside) — Blender 3.0+ compatible, industry-standard for turning a scan/sculpt into flow-aligned quads in seconds; **perpetual $79**, Pro tier $139.90 perpetual or $22.99/3mo, per-user Gumroad-tied license, minor updates free, major upgrades paid [exoside.com/quadremesher/quadremesher-buy]. Blender-native **QuadriFlow** (free, built-in Remesh modifier option) and **Voxel Remesh** (free, built-in) — both explicitly NOT recommended for a mesh that will be deformed/animated; QuadriFlow's flow doesn't reliably respect facial loops, Voxel Remesh is blocky [multiple sources incl. superrendersfarm.com, artisticrender.com]. | Quad Remesher $79 perpetual; QuadriFlow/Voxel free | Auto tools alone will NOT place correct eye/mouth rings — every source surveyed agrees manual clean-up on the face is required regardless of which auto-remesh seeds it. Useful only as a fast first-pass seed for the head-adjacent scalp/neck/body, not as the final face solution. |
| **Hybrid (recommended shape)** | Quad Remesher or Shrinkwrap-onto-donor for scalp/neck/cranium bulk, **then** manual loop surgery (Poly Build, or PolyQuilt if the 5.x fork proves stable) on eyes/mouth/jaw specifically. This is the consistent recommendation across every 2026 Blender-retopology guide surveyed [strayspark.studio, savedpixel.com]. | Mixed | **Recommended for this case.** |

**Bottom line on method**: no single 2024–2026 source claims a fully-automatic
tool solves stylized face loops correctly; the field consensus (StraySpark,
SavedPixel, SuperRenders, multiple Polycount threads) is auto/wrap for bulk +
manual for the ring topology around eyes and mouth. Given R14's own honest
verdict that the eye and mouth "read" is still the weak point and is a
*placement/judgment* problem, not a geometry-fitting problem, manual control
over those rings specifically should not be delegated to an auto-remesher.

**PolyQuilt Blender-5.x risk is real and must be gated at kickoff**: confirm
which fork (if any) actually loads before committing the build phase to it;
fallback is Blender's native Poly Build tool (slower, always works, zero
license risk) — this satisfies the brief's "fallback if an addon fails on
Blender 5.2" requirement.

## 2. Template head sources (commercial-game-safe license)

| Source | License | Fit |
|---|---|---|
| **thebasemesh.com** | Explicit **CC0** ("100% Free. CC0 License," public domain, no restriction) [thebasemesh.com]. Clean topology, UV-unwrapped, real-world scale, per site claims. | Best-verified license of the options found. Must still visually confirm it has a head/face mesh with proper animation loops (site's model library wasn't inspected in this pass — **VERIFY the specific head asset's loop quality before committing**, CC0 covers legal use but not topology quality). |
| **Meshy.ai pre-made assets** | Stated CC0, royalty-free, no attribution [meshy.ai/tags/head]. | Plausible fallback; AI-marketplace provenance of "pre-made" (non-generated) assets not independently confirmed — mark UNVERIFIED on whether these are hand-modeled with correct edge flow vs. auto-generated. |
| **itch.io "3d low poly head" (zakariya-el-onsri)** | Claimed CC0, "free for personal and commercial use, no attribution" [zakariya-el-onsri.itch.io]. Quad-based, UV-unwrapped, ships .blend. | Small single-author asset — usable but verify quad flow around eyes/mouth by inspection before adopting. |
| **Reallusion CC Base (Character Creator)** | Free rigged base meshes, "uniform quad topology... ideal for real-time animation." License terms are Reallusion's own EULA, NOT CC0 — **UNVERIFIED whether their free CC Base license permits use as a derivative template inside a commercial non-CC4 game asset**; historically Reallusion's free assets carry ecosystem-lock clauses. Flag as risky without reading the actual EULA. | Do not use without a lawyer-grade EULA read. |
| **3dscanstore free base mesh** | Explicitly **requires contacting 3dscanstore for commercial-use permission** even for the "free" download [3dscanstore.com/terms-and-conditions-licensing]. NOT free-and-clear for a commercial game. | Reject unless director wants to pursue a paid commercial license from them specifically. |
| **R3DS/Faceform sample templates** | Bundled with paid Wrap software; licensing tied to Wrap's own EULA, not standalone-redistributable. | Not applicable unless we buy Wrap. |

**Recommendation**: thebasemesh.com CC0 head (or the itch.io CC0 head as a
second opinion) as the wrap donor if the hybrid/wrap route is chosen; treat
Reallusion and 3dscanstore as **not commercially clear** without further
licensing work.

## 3. Loop spec for a stylized game face

- **Eye ring**: minimum one continuous quad ring fully encircling each eye
  (orbicularis-oculi loop); stylized/enlarged eyes want this ring denser, not
  sparser, because the aperture is the highest-deformation, highest-scrutiny
  area of a stylized face [vsquad.art, thundercloud-studio.com]. For our
  almond aperture with a heavy upper-lid read (R14's stated unmet goal), the
  upper lid specifically needs its own dedicated edge distinct from the ring,
  so the lid edge can be its own animatable loop.
- **Mouth ring**: multiple concentric rings from the lip line outward toward
  nose/cheek (orbicularis-oris pattern); **at least 2 loops must exit each
  mouth corner** or the corner reads as a cut/pinch under deformation
  [vsquad.art]. This directly targets R14's "mouth reads as a scored line"
  debt — the fix is topological (real lip-loop rings), not just a sculptural
  deepening, matching what cycle 2 already found (lip volume increased but
  loop structure wasn't the retopo's job yet).
- **Jaw/mask loops**: a loop tracing the jawline supports jaw-open animation;
  this is the natural place to finally retire the R14-inherited jaw band
  artifact at z≈1.485 by *replacing* it with an intentional edge rather than
  sculptural noise — the brief already flags this correctly.
- **Poly share**: sources agree stylized mobile faces can run 200–500 tris
  for the face alone at the low end vs. 5,000–15,000 for AAA PC [e.g.
  thundercloud-studio.com]; no source gave a precise head-vs-body PERCENTAGE
  of a 25–40k tri character — **UNVERIFIED as a hard number**. Working
  estimate only: **~15–25% of total tris for the head**, inferred from the
  low end of quoted face-only counts, not a cited fraction — treat as a
  planning number, not canon.
- **Nose/ear simplification for mobile**: no numeric norm found; general
  guidance is to push fine nasal-wing/helix detail into normal maps and keep
  base forms as smooth low-poly volumes, consistent with R14's already-
  simplified sculpt (UNVERIFIED as a cited rule, common-practice only).

## 4. Gates retopo quality is judged by, in practice

- **Pole placement rule** (cited consistently): poles (5+/3-valence vertices)
  must sit in flat, low-deformation areas — explicitly NOT at mouth corners,
  NOT at inner eye corners, NOT at joints, because poles there cause pinching
  and shading artifacts under deformation [nastyrodent.com, tripo3d.ai,
  cgcookie.com "star junctions" thread].
- **Review gate**: the standard studio pattern is a low-poly review by an
  art lead BEFORE UV unwrap — catching topology errors here is cheap, catching
  them after baking is expensive [tripo3d.ai retopology pipeline article].
- **Quad-dominance**: every source treats quad (or quad-dominant with
  triangles only in flat/hidden areas) as the baseline expectation for an
  animatable face; this matches the brief's existing "quad-only or
  quad-dominant" draft gate.
- **Numeric surface-deviation tolerance (mm) vs. the source sculpt**: **no
  source surveyed gives a published industry numeric tolerance**
  (e.g., "≤0.5mm") — appears project/tool-specific. **UNVERIFIED / not
  found** — recommend the lead set this from our own precedent instead: R14's
  gates already run at the 1–3mm scale against drawn contours for a 245mm-wide
  head, so a retopo-vs-sculpt gate of **0.5–2mm** (tighter near eye/mouth,
  looser on the cranium) is internally consistent, not an external citation.

## 5. Recommended plan

- **Method**: hybrid. Use Blender's native Shrinkwrap (free, always works)
  to project a CC0 donor head (thebasemesh.com, verify loop quality first) or
  a from-scratch Poly-Build cage onto `Fool_SculptBase`'s head region for bulk
  cranium/cheek/neck coverage; then hand-place dedicated eye-ring, upper-lid,
  mouth-ring, and jaw loops manually to close R14's outstanding eye/mouth
  debts. Do not rely on Quad Remesher or QuadriFlow for the face itself —
  every source agrees auto-remesh doesn't reliably respect facial loop flow;
  it is optional as a fast scalp/neck bulk-fill seed only.
- **Tools to install**: Blender 5.2 native Poly Build + Shrinkwrap (zero
  risk, no install). Attempt PolyQuilt only as an optional productivity
  layer, with a hard go/no-go check at kickoff ("does it load on our
  Blender 5.2 without the bgl error") — fallback is native Poly Build,
  per the brief's own fallback requirement. Do NOT purchase Quad Remesher or
  Wrap4Blender for this round; neither is load-bearing for the recommended
  method, and both have unresolved license/version verification gaps above.
- **Phase split**: Mechanical/Codex-safe — donor import, Shrinkwrap setup,
  bulk cranium/neck/scalp coverage, symmetry (X-mirror) enforcement, gate
  measurement scripting (deviation/quad-%/manifold checks), UV layout if in
  scope. Judgment/Opus — placement of the eye ring + upper-lid edge, mouth
  ring + corner loops, jaw loop, and any point where a loop must be nudged to
  read correctly in render (this is exactly the class of work R14 flagged as
  "I could not make it read as the sheet's X" — apply the R13 escalation
  lesson and route it to Opus from the start rather than discovering the
  need mid-round).
- **Body retopo reuse (R16+)**: the same hybrid method should carry over —
  Shrinkwrap/manual-bulk for torso/limb coverage, manual loop placement
  reserved for the small number of high-deformation zones (shoulder girdle,
  elbow/knee, hip). The donor-head licensing work done this round (CC0
  source vetted) should extend to sourcing a matching CC0 body base mesh from
  the same trusted source (thebasemesh.com) rather than re-researching
  licenses from scratch.

## What could not be verified (flagged honestly)

- Exact current price/EULA text of Wrap4Blender (product page returned
  HTTP 403 to fetch).
- Whether the official PolyQuilt Extensions-platform fork is actually fixed
  for Blender 5.2 as of this writing, vs. only community forks.
- Any published numeric retopo-vs-sculpt deviation tolerance (mm) as an
  industry standard — none found; recommend deriving from this project's own
  R14 precedent instead.
- Precise head-share percentage of a 25–40k tri budget — no source states
  this as a fraction; the 15–25% figure above is an inference, not a citation.
- thebasemesh.com's actual head-asset topology quality (site confirms CC0
  license and "clean topology" generally, but the specific head model's loop
  layout was not inspected).
