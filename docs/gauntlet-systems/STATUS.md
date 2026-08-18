# Systems Gauntlet — live status

Charter: [`PROMPT.md`](PROMPT.md). Branch `feat/systems`. Newest round at the top.
Each round closes with: what shipped (paths), how it was proven (test command + result),
what the critic sent back and how it was answered, logged debt, director asks.

## Round 0 — docs first + foundation (CLOSED 2026-08-17)

**Goal:** amend `docs/design/technical.md` with the Godot 2D architecture the run codes
against; land the 2D canon amendment owed since 2026-08-11 (`final-claude-2d.md` §9);
scaffold the Godot project so every later round has a runner, a layout, and a root to
land in.

**Shipped (commits `9cce75d`, `0419873`, `ae41da4` on `feat/systems`):**
- *Canon amendment:* GDD genre line → oblique top-down 2D (ALttP tradition), M4 "both
  endings" → all three, playtime 12–20 h; combat.md rewritten for the 2D grammar
  (stagger launcher replaces the aerial launcher, no jump verb, Focus = lock + 8-way
  strafe, climb-lite dissolves into level design, §Overturn in 2D, new §Open
  questions); arcana.md rules 6/7 + §XII Overturn's top-down reading; world.md
  §Side-view sequences (the canon list of where the view turns to profile) + gate
  wording; GLOSSARY: *stagger launcher*, *side-view sequence*; 2D production notes atop
  the art docs; the `THIRD PERSON GAMEPLAY` slugline → `GAMEPLAY` in TEMPLATE.md + 24
  quest scripts. The three 2D reports are now committed (source two banner-marked
  superseded) so canon links resolve.
- *technical.md:* new "Godot 2D — the shipping architecture" section (Unity body kept
  as historical). This is what every brief from here on points at.
- *Foundation (`godot/`):* `bash godot/tests/run_all.sh` = import → typing lint → unit
  runner → legacy scene tests, per-suite timeout, engine `SCRIPT ERROR`/`ERROR:` lines
  fail the stage; `TarrockTest` + runner with coroutine support; `Services` autoload
  (typed fields, no string locator) + `GameClock` + `InputActions` +
  `TarrockDefinition`; 16 InputMap actions (keyboard by physical keycode + gamepad);
  `untyped_declaration` = parse error project-wide (existing scripts typed, no behavior
  change); translation CSV + a three-place localization lint (`.tscn` in scenes/ and
  systems/, `.gd` in systems/, `.tres` in data/); `player.gd` off `ui_*`.

**Proof:** `RUN_ALL: 8 suites passed, 0 failed` (43 unit tests + 6 scene suites, ~17 s).
Critic mutation checks reproduced by the fix builder: a nonexistent-method test, a null
deref, and an awaiting test all now FAIL the run (before the fix all three passed
silently — the round's biggest catch); untyped `var x = 1` fails the lint stage; scratch
literals in a scene, a system script, and a `.tres` all caught; a ghost InputMap action
and a duplicated binding both caught; a hung suite times out as FAIL.

**Critic → answered:** 6 blocking findings, all fixed this round (runner swallowed
errors; lint narrower than the doc claimed; Overturn 2D reading written into non-owning
docs → moved to arcana.md §XII; world.md ripple; canon linking an untracked report →
reports committed; missing glossary terms). Debt logged: `dodge`=Space / `pause`=Esc
collide with Godot's `ui_accept`/`ui_cancel` defaults (fine until a UI round; revisit
then); `res://scripts` not yet under the literal lint (joins as scripts migrate);
completionist playtime figure left TBD in the GDD (director may want to set it).

**Director asks:** issue #10 (GDScript + Claude lanes) — still open, working assumption
stands. Also for the director's eye, not blocking: the GDD's completionist playtime is
now TBD (was "40+", a 3D-scale figure).

## Round 2 — WorldState service + docs-generated `WS_*` definitions (open 2026-08-17)

**Goal:** `WorldStateService` (flags, Renown, acts, the Reading, Hermit answer, named-NPC
memory, quest state) as the only mutation path; `gen_definitions.py` generating one
`.tres` per world.md matrix row + act thresholds + Renown ladder, with a drift test.
_In progress._
