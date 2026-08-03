# Round 15 — HEAD RETOPO (final brief; supersedes R15-BRIEF-DRAFT.md)

Lead, 2026-08-03. Research: R15-RESEARCH-RETOPO.md (same dir) — its findings are
adopted as lead rulings below. Workdir `/home/betty/tarrock-gauntlet-work/fool2-r15/`.
Source: chain `Fool-v2-017.blend` (body `Fool_SculptBase` 1,012,055 v watertight;
`Fool_Eye_L/R` r=35 mm at (±43, −40.3, 1571) mm; 1 u = 1 m, faces −Y, X mirror).

## Lead rulings (logged per charter; industry-standard defaults)
- **Method: hybrid.** Native Shrinkwrap projection of a clean donor head for
  bulk coverage; MANUAL loop placement for eye rings, upper-lid edge, mouth
  rings (≥2 loops exiting each corner), jaw/mask loop. No purchased addons
  this round (Quad Remesher/Wrap4Blender not load-bearing; PolyQuilt broken on
  Blender 5 — native Poly Build is the fallback tool).
- **Donor: thebasemesh.com CC0 head** (license verified CC0 by research);
  fallback: itch.io CC0 low-poly head (zakariya-el-onsri). BOTH subject to
  loop-quality inspection before adoption; save license evidence (page text +
  URL + date) beside the asset. If both fail inspection, the loops are built
  manually on a Shrinkwrap'd grid — report, don't stall.
- **Budget (working estimate, UNVERIFIED industry share):** head 4–8k tris
  within a 25–40k character. Refine at body retopo; do not treat as canon.
- **Gates:** retopo head surface deviation vs sculpt ≤1.5 mm RMS / ≤3 mm max
  (run-precedent derived) over the head region, EXCLUDING deliberate
  divergences the retopo OWNS: the R14 debts (open-almond eye aperture with a
  distinct upper-lid edge, one crisp mouth, off-midline cheek WEDGE per
  seclib/w0_sections plan sections, jaw-band supersession) — each deliberate
  divergence named + rendered in the report. Quad-dominant ≥95%; X-symmetric;
  full eye + mouth encirclement; no poles at mouth corners / inner eye
  corners; eyelid rim clears the eyeball for rotation; head watertight or
  cleanly bounded at an agreed neck seam (builder proposes, lead accepts).
- **Eyes stay separate objects**; sockets in the retopo close around them.
- Style bar unchanged; the sheet's head crops govern the read; renders with
  head_render.py framing + wireframe-over-shaded views are the evidence.

## Phases
- **A1 (Sonnet, network + brief Blender lane):** acquire donor + license
  evidence into `fool2-r15/donor/`; import headless, scale/orient to our
  conventions, wireframe inspection renders of eye/mouth topology; verdict on
  donor loop quality; DONOR-REPORT.md.
- **A2 (Codex, headless lane):** donor→sculpt registration (scale/position to
  the head landmarks), Shrinkwrap bulk projection, symmetry enforcement,
  deviation-gate + quad-stat scripting, baseline reports. No face-loop
  judgment: mechanical projection + instrumentation only.
- **B (Opus, judgment):** face loop work — eye rings/upper-lid edge, mouth
  rings/corners, jaw loop, wedge enforcement via plan sections, pole hygiene;
  eyes-on every cycle (wireframe + shaded, studio + rake).
- **Close:** lead validation + Codex blind judge (shaded read AND wireframe
  screenshot vs the loop spec). STATUS/ROUND-STATE/renders push.

## Protocol (unchanged)
One Blender lane; governor slots before every run (PAUSE → 15 s poll);
loadavg < 6; temp < 90 °C; candidates `Fool-v2-018*.blend` in the workdir;
chain promotion only after lead validation; blends uncommitted; GUI stays
closed (director) — renders are the channel; never touch `../r14`'s sibling
dirs of the other session (`fool2-*` only); honest partials beat overreach.
