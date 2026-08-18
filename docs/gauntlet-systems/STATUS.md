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

## Round 2 — WorldState service + docs-generated `WS_*` definitions (CLOSED 2026-08-18)

**Shipped (`af9772f`):** `WorldStateService` — the only mutation path for flags, Renown,
acts, the Fool's Reading, the Hermit answer, named-NPC memory, quest state; typed
signals; fire-once; **no un-fire method** (an exact public-surface test now lists the 21
public methods — adding one is a reviewed edit); branch flags never enter the Reading nor
count toward acts; act thresholds and the Renown ladder come from data (a literal-based
implementation fails the tests); `restore_snapshot` is all-or-nothing and only valid on a
pristine service (a load is not a reset), and emits nothing. `gen_definitions.py` turns
`world.md` §World-state matrix into 25 `.tres` (21 unbindings + 4 derived branch flags),
a catalog, act thresholds, `progression.md`'s Renown ladder, and `WorldStateIds`
constants; `--check` = the drift test (changed / stale / missing). Quest-frontmatter
sweep: 25 distinct `WS_*` ids referenced across the quest docs, 0 unknown.

**Proof:** `UNIT TESTS: 139 passed` (96 new), `RUN_ALL: 8 suites passed`,
`gen_definitions --check: 29 generated files match docs/`. Critic mutations all caught:
duplicate `fire` returning true; literal 7/15 act thresholds; branch flags leaking into
the Reading; a one-character edit to a generated `.tres`; a `reset()` method; a
`forget()` method under an unlisted name (this one PASSED before the fix — the exact
public-surface test now catches it); a live-service restore (was a silent reset path —
now refused); a Reading that disagrees with the flags (was accepted — now refused).

**Debt / owed:** Renown tier thresholds `[0,10,25,50,100]` are placeholders — canon names
five tiers, sets no numbers (director/tuning); branch-group exactly-one is round 4's
contract (quest runner); `set_quest_state` is open by convention (GDScript has no friend
access); snapshot versioning is round 3's job (the save gates versions before restore).

**Director asks:** none new. (Renown thresholds will need numbers eventually — not
blocking anything yet.)

## Round 3 — Save system (CLOSED 2026-08-18)

**Shipped (`958b7bd`):** `SaveModel` (schema v1, IDs and plain values only),
`SaveSchema` (the production migration table — empty at v1 and structurally tested: bump
the version without a step and a test fails), `SaveMigrations` (explicit chain; a missing
intermediate step is a hard failure; a save newer than the build is refused),
`SaveService` (capture/apply over the WorldState snapshot — apply only into a pristine
world, all-or-nothing; atomic write via temp+rename **with a byte-length check** so a
short write never replaces the last good save; garbage never crashes a read; slots
listed only if the service could have written them), `DifficultyMode` in core; fixtures
with an honest placeholder README.

**Proof:** 82 save tests; `RUN_ALL` green at hand-off. Critic mutations caught: missing
migration step made best-effort (4 tests), newer-than-build refusal dropped, schema bump
without a step, crash-prone parse path (caught by the runner's engine-error grep + a
signal assertion). Not caught before the fix and now caught: **removing temp+rename
entirely** (the previous save is now proven to survive a blocked write byte-for-byte),
`slot_007`/`slot_-1` decoys in `list_slots`. Also fixed: playtime now baselines the clock
on load (title-screen time no longer saved), whole-number version check exact.

**Debt / owed:** how the game constructs fresh services for a load from the title screen
is the Regions round's job (persistent layer); the two 4.7 facts every later round must
know — JSON numbers come back as floats, and `Dictionary ==` is type-strict — are in
`godot/systems/save/README.md`.

## Round 4 — Quests (open 2026-08-18)

**Goal:** `QuestDefinition` metadata generated from quest frontmatter (91 quests),
hand-authored `QuestGraph` state machines, `QuestService` runner (events → transitions;
fires only at completion; branch groups exactly-one), MQ00 wired into the Cliff scene
through `Interactable` triggers. _In progress._
