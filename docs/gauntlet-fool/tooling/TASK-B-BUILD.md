# Round 13 RE-RUN — Phase B: the amplitude turn-up build (Codex, headless lane)

Execute the recovered Round-13 builder brief:
/home/betty/Projects/tarrock/.claude/gauntlet-fool2/tooling/R13-BRIEF.md
with the following ADDENDUM, which resolves every [LOST] item and overrides the
brief where they conflict. Read the brief in full first.

## Addendum — lead rulings and reconstructed tooling (2026-08-03)

1. WORKDIR: /home/betty/tarrock-gauntlet-work/r13/ — scripts to scripts/,
   renders to renders/, candidate `Fool-v2-016.blend` and REPORT.md to the
   workdir root. The project dir is read-only to you; the lead promotes.
2. TOOLING (reconstructed, validated by the lead — USE these, do not rewrite
   from scratch; extend only if a needed primitive is missing, and record any
   extension in the report): everything under
   /home/betty/tarrock-gauntlet-work/r13/tooling/
   - fieldlib.py — falloffs (C1, teardrop/aradius), facing weights, graph blur,
     calibrated-amplitude loop, terrace_fix, erase, measures. Selftest passed.
   - stations_base.json — silhouette station table of unmodified 015.
   - webbing_probes.json — inter-finger probe set; 015 passes 100%.
   - rms_metric.py — flat-light RMS relief metric + region masks; its regional
     ordering on 015 reproduces the dead critic's map.
   - sheet_stations.json — drawn-sheet extraction, reference only.
3. SILHOUETTE GUARD (lead ruling, replaces the brief's re-derivation clause):
   015's silhouette is twice-certified vs the sheet. Your guard is
   |candidate − 015| ≤ 3 mm at EVERY station of stations_base.json (all regions,
   not only touched ones — cheap to run, run it globally). Print the worst 10
   stations. sheet_stations.json is a cross-check record, not the gate.
4. RMS TARGETS AS RATIOS (lead ruling): all self-gate RMS targets are evaluated
   with rms_metric.py on renders from THIS run (identical settings base vs
   final; the Phase-A base renders in renders/ may be reused as the base if
   settings match exactly, else re-render both). Targets restated in
   ratio form: arm_final ≥ 0.9 × clavicle_final; abdomen_final ≥ 2 ×
   abdomen_base; belt_final < clavicle_final; costal midline kink gone
   (arch profile continuous across x=0 — measure on the mesh, not the render).
5. The brief's r11lib/r12build "rebuild the fields from r12build.py" wording:
   those files are gone. Rebuild the FIELDS from the brief's own descriptions
   (§The four items) using fieldlib.py primitives. The shapes are already ON
   the mesh at ~1/3 amplitude — prefer measuring the existing relief (erase /
   residual tools) to locate each form, then amplify in place; sculpt fresh
   fields only where a form is genuinely absent (deltoid insertion V, ulnar
   line on the arms — the quietest region).
6. Backup object name stays `Fool_SculptBase_prepass2e` (first action, per the
   brief). Topology/crown/sole/webbing/moat/banding guards all as the brief
   states, with webbing evaluated via webbing_probes.json.
7. Machine protocol exactly as the brief states (governor slots file, loadavg,
   thermals, one blender process, sequential).
8. HONESTY: the previous run of this round died unvalidated; yours will be
   validated line by line. Report failures as failures.
