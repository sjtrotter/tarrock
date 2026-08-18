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

## Round 4 — Quests (CLOSED 2026-08-18)

**Shipped (`4080e8b`):** `QuestDefinition`/`Catalog`/`Graph`/`State`/`Transition`/
`BranchGroup`; **91 quest definitions generated from the quest docs' frontmatter** (+
catalog, `QuestIds`, `quest_titles.csv`) — region tokens are the side-quest tokens
(`CLIFF`, `PRESTIGE`, …), arcana carried as the card number; a generated definition
links its **hand-authored graph** when `data/quests/graphs/<ID>.tres` exists. `QuestService`:
availability from `WS_*` flags and quest ids; `raise(event)` applies the current state's
matching transition; branch choices recorded set-once through a reviewed
`WorldStateService.set_quest_choice`; **fires and chosen branch flags commit only at
completion**; a quest owing a branch choice refuses to complete without burning its
choice; catalog-order determinism. **MQ00 is the first quest wired**: `Interactable`
triggers at the existing Cliff props (Bindle, disturbed earth, dead tree, Waystation,
edge, leap) forward events to the runner; the Cliff integration test now drives the Fool
physically through WAKING → … → COMPLETE and asserts nothing fires (MQ00 fires nothing).

**Proof:** 297 unit tests (73 new); `RUN_ALL: 8 suites passed`; `--check: 123 generated
files match docs/`. Critic mutations all caught: fires on every transition; branch check
skipped; start twice; transitions ignoring current state; a dropped scene forwarding; a
typo'd trigger event; a hand-edited generated .tres; a graph naming a nonexistent state.
**Blocking catch fixed:** the dig trigger was one-shot and spent itself if the player dug
before taking the Bindle — MQ00 would soft-lock (the order-independence rule); now
regression-tested.

**Debt / owed:** spend one-shot triggers only when a quest consumed the event (needs
`raise()` to report consumption); the ambush beat has no in-scene source until combat
(round 7) — the test raises it; Pip's Seek (round 9) replaces the dig interaction;
`--check-only` doesn't know autoloads, so scenes reach `Services` by path (documented).
Not representable as states: the tutorial-prompt-only beats and all dialogue (round 5).

**Director asks:** none.

## Round 5 — Dialogue (CLOSED 2026-08-18)

**Shipped (`fc80826`):** `DialogueGraph` with LINE / CHOICE (exhaust-all with follow-up
threads that return to the table, or first-pick-commits) / BRANCH (WorldState queries only
— there is nowhere to put a boolean) / EVENT (raised for the quest runner by signal;
dialogue never touches systems) / POOL (Random Lines, seeded) / END, `next_graph_id`
chaining with ring detection; `DialogueService` (return-stack threading for nested
follow-up tables, walk-step guard, transient, typed signals + read-only views for the UI
round); `DialogueStyle` lints **pinned to canon** (≤ 12-word Fool options per narrative.md,
one earnest option per table, every key translates). **MQ00's dialogue as data:** 13
graphs, 46-row `dialogue_mq00.csv` verbatim from the script; the one Querent fourth-wall
wink pinned by test; Pip never speaks (tested). Cliff wiring maps quest states to
conversations; a beat landing mid-conversation is queued, not lost; nothing blocks the
Fool.

**Proof:** 402 unit tests (105 new); `RUN_ALL: 8 suites passed`. Critic mutations all
caught: exhaust-all forgetting a used row (7 tests), a branch ignoring its flag, an event
node going quiet, the word ceiling changed to 20 (a canon-pinned test fails, not just the
lint's constant), a deleted CSV row, a dropped scene start, a self-chaining graph.
**Blocking catch fixed:** the data had dropped the Querent's answer to "What am I?" — the
line that names the Fool *the Excuse*; restored verbatim, and a structural test now
guarantees every table row is answered before the Fool's line plays back.

**Debt / owed:** the four idle BARKS of the Cliff are the NPC round's (nothing beat-driven
triggers them); five authored beats have no trigger yet (opening cut scene → bootstrap;
campsites → a fire-ring trigger; ambush → combat; rest-again → the repeat-rest verb;
leap-before → the leap cut scene); speaker display-name keys live in the MQ00 CSV until a
second quest's dialogue lands; quest-state ids appear as literals in the Cliff's
state→dialogue table (no `QuestStates` const class yet).

**Director asks:** none new (issue #11 — health vs petals — still open, needed by
round 7).

## Round 6 — Trumps, the Pocket Spread, Fortune, the White Rose (open 2026-08-18)

**Goal:** 20 `TrumpDefinition`s generated from arcana.md's Trump tables (+ hand-authored
effects, Magician first), `PocketSpreadService` (held derived from flags; slots unlock at
1/3/7 held; one copy; swap out of combat; loadouts at Waystations), `FortuneService`
(meter, earn table × difficulty, Fortune's Favor overfill, free cast after Fool's Chance),
`WhiteRoseService` (3→8 petals, graftings, regrowth only in unbound regions), all in the
save. _In progress._
