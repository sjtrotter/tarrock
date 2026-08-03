# Round 14 — Phase B cycle 2: face-read fixes (Opus builder, headless Blender lane)

Cycle 1 (a different builder; its session is gone but its record is complete)
delivered `Fool-v2-017e.blend` — all hard gates green, strong skull structure,
but the head does not yet READ as the sheet's character: lead validation +
Codex blind judge scored 4/10. You fix the read. Everything in `R14-BRIEF.md`
and `TASK-B-HEAD.md` (same dir) remains binding — read them first, then IN THE
WORKDIR `/home/betty/tarrock-gauntlet-work/fool2-r14/`:
- `REPORT-B-HEAD.md` — cycle 1's mechanisms, corrections, and look-log. LEAD
  RATIFICATIONS from it: eyeball centre Y = −40.30 mm (Phase A's −48.6 was the
  nose-root, not the cornea — verified against the side view's third
  registration circle); the nose re-measure (tip Z 1.5346, 17.7 mm proud);
  the band-inheritance measurement (016 p95 0.521 mm vs candidate 0.352 mm).
- `scripts/` — cycle 1's working library (`r14lib.py`, `c1_skull.py` …
  `c5_band_gate.py`) and `head_render.py`. Reuse; don't rebuild from zero.
- `r14-phaseb-validation.json` — the gate numbers you must not regress.

START FROM `Fool-v2-017e.blend` (workdir root). Candidates `Fool-v2-017f.blend`
onward. Never touch the project repo, `docs/`, the sibling `../r14/`, the GUI,
or port 9876. One headless Blender at a time; governor slots before every run
(PAUSE = poll 15 s); loadavg < 6; pkg temp < 90 °C. Eyes-on after EVERY cycle
with `head_render.py` (tags r14c5, c6, …); compare against your own sheet
crops AND `renders/r14final-*` (cycle 1's end state).

## The fixes, priority order (merged lead + blind-judge critique)

1. **PRIMARY MASS FIRST** (judge's first order): the lower face reads as a
   broad MUZZLE with shelf seams and a square jaw. Pull the mouth/chin region
   inward; taper the cheeks continuously into a smaller, forward-pointing
   chin; build the clean forehead–nose–lip–chin S-profile from the side ink.
   Chin must reach the drawn line (cycle 1 stopped 4.6 mm shy at z 1.455 to
   avoid a 2.56 mm crease at z 1.4605 — reprofile the APPROACH into the frozen
   band instead of stopping short; the drawn chin bottom (Z 1.451) is above
   the z 1.30 freeze). Kill the abrupt chin/neck junction.

2. **EYES:** the drawn eye is a wide almond whose heavy, near-horizontal
   UPPER-LID edge is the dominant graphic; lower lid restrained. Cycle 1 reads
   as bare balls in deep sockets ("sleepy, assembled from pieces"). Bring the
   lids forward/down to hug the globes; make the upper-lid edge the strong
   line; add the missing medial-canthus lid edge; reduce exposed globe below
   centre; shallow the dark socket ring. Keep spheres, centres (±43, −40.30,
   1571 mm), rotation clearance, and separateness rig-valid.

3. **NOSE:** shrink and soften into the sheet's tiny, softly upturned wedge.
   Shorten the bridge; round the front-view blade (it reads as a triangular
   spike); small simple wings; keep ~17.7 mm projection but taper it gently
   into the brow plane.

4. **MOUTH:** wider (drawn ~64 mm at Z 1.495); cleaner lip split with the
   gentle smile; slight upper/lower lip volume so it reads as lips, not a
   scored slit; de-swell the surrounding plane (part of fix 1).

5. **EARS:** extent is measured-correct (flare to |X| ≈ 115 mm) but the mass
   is bulky, round, pasted-on. Thin them; refine the silhouette toward the
   drawn ear; ONE graphic helix ridge + concha scoop (simple); remove the
   concentric UV-lens rings cycle 1 noted in the concha.

6. **BANDS → PLANES:** the mid-face horizontal band (z ≈ 1.516 strongest) and
   cheek/jaw shelf seams still READ in both lights even though inherited —
   R13 law: curvature concentrations. Replace them with a few intentional
   cheek/brow/jaw planes. Cycle 1's conflict (3–15 mm deband window eats lid
   rims/mouth) is resolved by ORDER: deband/reprofile the mask regions BEFORE
   re-cutting the fine feature lines this cycle, or mask the features out.
   End state: no horizontal band reads in studio or rake.

## Gates — identical to TASK-B-HEAD.md, measured on the SAVED final file
Freeze below z 1.30 exact (≤0.1 mm); z 1.30–1.45 within cycle-1's manubrium
envelope (no new excursions beyond ±3 mm vs 016 outside it — the drawn neck
profile holds); drawn contours z ≥ 1.47 within ±3 mm; crown 1.717 ± 1 mm;
webbing 160/160; body ONE watertight manifold; eyeballs two separate closed
spheres; backups (incl. `Fool_SculptBase_prehead`) intact.

## Deliverables
Final candidate (state the letter); per-cycle renders; extend
`REPORT-B-HEAD.md` with a "Cycle 2" section (same discipline: look-log, gates
from the saved file, honest per-item verdict, what would not read well);
updated `r14-phaseb-validation.json`. A false pass costs a full round.
