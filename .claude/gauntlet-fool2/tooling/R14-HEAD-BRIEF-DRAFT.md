# Round 14 DRAFT — head sculpt (BLOCKED on issue #2 ruling; final brief on unblock)

Lead prep draft, 2026-08-03. The head round unblocks when the Pass-2 gate closes
(director issue #2). This draft collects the decided inputs so the final brief is
an edit, not a research task. TBD markers are genuinely undecided.

## Scope (the head-sculpt stage owns all of it — charter + ROUND-STATE carry-list)
- Cranium/jaw form refinement on the sheet's SKULL line (ears were deferred here).
- Brow plane (r4 note: starts +9 mm proud — re-measure on 016 first), eye sockets
  OPEN + separate rotatable eyeball spheres (director ruling: rig-ready eyes; the
  sheet's eyeball registration circles sit directly above the pupils).
- Nose (absent today), ears (absent today), mouth/lip band, philtrum TBD-simple.
- Jaw/head horizontal band artifact (logged r12) and the neck integration.
- Manubrium band z≥1.32 ~15 mm proud (carried from R9) — this round owns it.

## Method constraints (carry from R13's paid-for lessons)
- Fields in SLOPE space, curvature bounded; no plateau displacement; blur-then-
  re-gain with edge sigma ≥ 8 mm equivalent at face scale TBD (face features are
  smaller — recalibrate, do not copy torso constants).
- Gates: geometry-space numbers + builder eyes-on iteration; presence checked
  with tooling/presence_render.py (studio + rake) — never render-RMS scalars.
- Resolution: 1.5 mm voxel global is already fine for head primary forms; local
  masked remesh TBD if nose/eyelid creases demand it (avoid global remesh at
  992k verts).
- Symmetry X exact; nose/mouth midline features symmetric (navel-style
  symmetry-OFF does NOT apply to the head at this style level).
- Protected: everything below the neck (whole-figure guards re-run regardless).

## References
- docs/design/3d-models-inwork/Fool-Tpose-ModelSheet-v7.png (head rows, front +
  side; calibration constants in ROUND-STATE).
- ~/Downloads/Fool-Expressions.png — CHARACTER reference only; the base head is
  neutral. Fool-Orthographic-A-Pose.png head is older; v7 wins conflicts.
- Sculpt reference §3 does not cover the face — the builder researches storybook
  head technique (Bran Sculpts order: head sculpt precedes head retopo) and the
  charter's style mix (40% Fable / 20% Kells / 15% Kena / 10% Dishonored /
  10% fairy tales / 5% Ghibli; stylized-simple wins).
- Eyeball spec TBD: sphere radius + socket clearance to be measured from the
  sheet's registration circles before the builder starts (lead task).

## Executor plan
- Codex remains default executor UNLESS the round is judged diagnosis-heavy at
  kickoff; the R13 escalation showed diagnose-first Opus pays for itself when
  two Codex attempts stall — do not wait for two failures on *placement* work
  of brand-new features; TBD at kickoff based on issue #2 timing.
- One Blender lane; governor protocol; candidates to the persistent workdir;
  chain file next number at promotion.
