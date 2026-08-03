# Round 15 — Phase A2: donor registration + shrinkwrap bulk (Codex, headless lane)

Mechanical phase: NO face-loop judgment — projection + instrumentation only.
Binding: `R15-BRIEF.md` (same dir). Read `/home/betty/tarrock-gauntlet-work/fool2-r15/DONOR-REPORT.md`
first. Work ONLY under `/home/betty/tarrock-gauntlet-work/fool2-r15/`.
Chain source (SACRED, read-only): `/home/betty/Projects/tarrock/docs/design/3d-models-inwork/Fool-v2-018.blend`
(body `Fool_SculptBase`; eyes Fool_Eye_L/R separate — leave untouched).
Donor: `fool2-r15/donor/donor_skin_only.blend` (3,070 v, faces −Y already).

You own the ONLY Blender lane: `blender --background --python`, one process at
a time, never the GUI, never port 9876. Before EVERY run:
`cat /tmp/tarrock-governor/slots` (PAUSE → poll 15 s), loadavg < 6, max
thermal zone < 90000.

## Steps (all scripted, re-runnable, printing real numbers)
1. **Head extraction:** from the donor skin, keep head + neck; cut at a clean
   ring below the jaw/neck junction; record the seam loop (this is the
   proposed neck seam — the lead accepts or moves it later). Delete shoulders.
2. **Registration:** land the donor head on the sculpt's head frame:
   midline X = 0; per-axis affine scale + translate so that: eye centres at
   Z 1.571 and |X| 43 mm; chin bottom Z 1.451; crown Z 1.717; back of skull
   and brow front to the sculpt's Y extents at their rows (measure the sculpt
   with a ray/section probe, do not eyeball). Record the exact transform in
   the report. Donor eye-socket centres must land on (±43, −40.3, 1571) mm.
3. **Bulk projection:** Shrinkwrap the registered donor onto `Fool_SculptBase`
   (two-stage: nearest-surface, then project-along-normal refinement, with a
   corrective smooth between). MASK OUT the eyelid rings and mouth rings
   (they collapse into the sculpt's crude features and get rebuilt in Phase
   B): freeze those vertex groups after stage 1. Define the masks by the
   donor's own topology (the concentric ring neighborhoods you can select
   programmatically), record the group names.
4. **Exact X symmetry:** snap post-wrap positions to their mirrored average;
   report max asymmetry before/after.
5. **Instrumentation (deliver as scripts + JSON):**
   - deviation of wrapped head vs sculpt surface: RMS + max + p95 (mm) over
     unmasked vertices; per-region (cranium / face / jaw / neck);
   - quad %, non-quad list; pole census (valence ≠ 4) within 2 rings of the
     eye and mouth masks;
   - plan-section overlay at the five R14 heights (seclib/w0_sections pattern:
     sculpt outline vs wrapped-donor outline per height, PNG per section);
   - wireframe-over-shaded renders, front + side + three-quarter (reuse
     head_render.py framing).
6. **Save:** `Fool-v2-019a.blend` in the workdir: wrapped head object named
   `Fool_HeadRetopo_draft`, plus the untouched chain objects (link or append —
   state which; the chain FILE is never written). `REPORT-A2.md` (≤100 lines)
   + `r15-a2-validation.json` with every number above.

## Honesty rules
Real numbers from real runs only; a masked-region collapse, a registration
that will not converge, or a projection artifact is a REPORTED finding, not a
silent fix. The lead validates before Phase B.

## RE-RUN NOTE (lead, post-amendment)
A previous A2 run executed against the superseded chain head (017h) and was
killed at lead level; its outputs were moved to `a2-dryrun-017h/`. Treat them
as a method reference only — every number must be re-produced against chain
`Fool-v2-018.blend` (the amended cycle-3 head: wedge face, one-line mouth,
thinner ears). Additional Phase-B context you must record for the report: the
lead's eye ruling — globe stays r=35 mm; the retopo's orbital region builds
OUT to the drawn width at eye rows; and the z≈1.51 sculpt line is a remesh
terrace your retopo surface should simply not reproduce.
