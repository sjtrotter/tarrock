# Round 14 — Phase B cycle 3: the face is a WEDGE, not a mask (Opus builder)

Two cycles delivered structure (017e, 017h) but the blind judge is flat at 4/10
with the SAME first order both times: the lower face reads massive. Cycle 2's
gates all PASSED while the read FAILED — understand why before building:

**THE DIAGNOSIS (lead, from the cycle-2 evidence).** The station gates measure
per-z EXTREMES: the midline side-profile matches the ink (y_front ≤ 1.71 mm)
and the outer front contour matches (x_half ≤ 1.01 mm) — yet the judge sees a
"deep rectangular muzzle". Both are true: OFF-midline, the cheeks and jaw stay
almost as far forward (−Y) as the midline, so the face is a flat-fronted slab
whose corners the extremes never see. The drawn character's face is a light
WEDGE suspended under a broad cranium: in a HORIZONTAL cross-section at mouth
height the drawn face is a narrow egg (pointed toward −Y), while the mesh is a
squircle. The station instrument is blind to this by construction. Your new
mandatory instrument: **plan-view sections** — cut horizontal sections at
z = 1.46, 1.49, 1.52, 1.55, 1.58, plot/print the (x, y) outline of each
(matplotlib or ASCII, your choice), and drive the cheek/jaw Y-field until each
section reads as the drawn wedge. Sections + renders every cycle; the extremes
gates remain as GUARDS only, not targets.

Everything in R14-BRIEF.md, TASK-B-HEAD.md, TASK-B2-HEAD.md remains binding
(workdir `/home/betty/tarrock-gauntlet-work/fool2-r14/`, one headless Blender
lane, governor protocol, eyes-on every cycle, freeze/contour/webbing/crown/
manifold/eyeball gates). Read REPORT-B-HEAD.md fully — both prior builders'
look-logs and their two instrument findings (contour-lock band re-injection →
use the degree-4 polynomial lock, never per-slab extremes; EEVEE rake shadow
acne — do not chase stripes Workbench does not show).

START FROM `Fool-v2-017h.blend`; candidates `Fool-v2-017i.blend` onward.

## The work, priority order

1. **LIGHTEN THE LOWER FACE (the judge's twice-repeated first order).** Using
   plan sections: recess the cheek/jaw Y-field off-midline so each section
   tapers into a wedge; shorten the chin vertically and taper it to a soft
   point (keep the midline profile on the ink — it already is); reduce the
   forward/deep mass around the mouth. In profile the jaw depth (chin to
   jaw-corner) must lighten; the sheet's jaw underside line rises steeply.
   Kill the surviving z ≈ 1.485 jaw band while reshaping this exact region —
   do not smooth it, REPLACE it with the new form (R13 law).

2. **EYES — the drawn graphic, not a rimmed socket.** Current read: pinched,
   drooping, deeply hooded goggle rims ("tired/mournful"); side view shows a
   protruding lid-stack. Target: large OPEN oval/almond aperture; ONE bold
   upper-lid overhang is the only strong line; lower lid minimal (the sheet
   even shows a sliver of lower sclera — the eye is open, not hooded); flatten
   the raised ring around the socket to near zero; the globe reads because it
   is visible, not because a rim advertises it. Restore the brows as thin,
   sharp, visible arcs (they faded in cycle 2). Eyeballs/rig gates unchanged.

3. **MOUTH — one crisp line.** Delete the layered parallel-bar read: a single
   clean, gently smiling mouth line ~64 mm wide, faint lip volume above/below
   (1–2 mm class), surrounding plane quiet.

4. **NOSE — smaller and shallower still.** "Tiny, shallow, graphically
   indicated": shorten, soften the tip bulb, let it die into the face with no
   surrounding moat.

5. **EARS — thin the pads.** Silhouette extent may stay (drawn ink reaches
   |X| ≈ 115) but the MASS must drop: thinner flap, less depth (Y-extent),
   slightly higher visual weight; simple helix + concha only.

## Verification loop (every cycle, no exceptions)
plan sections (5 heights) → head_render.py studio+rake → LOOK, compare against
your own sheet crops → name the gap → next field. Judge your end state against
the drawing like a rival would; if a fix stops moving the read, say so and stop.

## Deliverables
Final candidate letter; per-cycle renders (tag r14c8+, final tag r14v3final);
section plots/prints for the final; "Cycle 3" section appended to
REPORT-B-HEAD.md (look-log, gates from the saved file, honest per-item
verdict); updated r14-phaseb-validation.json. A false pass costs a full round.
