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

## Round 6 — Trumps, the Pocket Spread, Fortune, the White Rose (CLOSED 2026-08-18)

**Shipped (`12fd51c`, plus `cfdab91` docs):** **20 Trump definitions generated straight
from arcana.md's Trump tables** (name, card number, granting flag, the four doc texts
verbatim — an independent critic parser found zero mismatches) + hand-authored effects
linked when present (the Magician authored first, TBD numbers marked; a data test
enforces that reversed differs from upright beyond cost — the six-expression rule made
structural). `SpreadRules` with canon numbers pinned by a doc-regex drift test (1/3/7,
100, 3/8) and every placeholder named TBD. `PocketSpreadService` (held **derived from
flags** — no stored list, no un-held path; slots unlock from data; one copy; no swapping
in combat; loadouts at Waystations only, revalidated on apply; `cast_present` spends
Fortune or the armed free cast; snapshot fresh-only). `FortuneService` (earn table ×
difficulty; Fortune's Favor overfill with decay; free cast after Fool's Chance).
`WhiteRoseService` (3→8, graftings, one petal one heal, rest, regrowth only in unbound
regions — never the Cliff — and it notices a loaded world). Save carries all three; apply
lands the world first and stops at the first failing section (contract documented).

**Proof:** 530 unit tests (128 new); `RUN_ALL: 8 suites passed`; `--check: 146 files`.
Critic mutations all caught: held ignoring flags (14 tests), Past unlock at 2, same
Trump in two slots, unbounded Favor overfill, Rose regrowing on the Cliff, reversed cost
= upright, apply skipping the spread section, a hand-edited generated Trump. **Blocking
catches fixed:** save `apply()` continued past a failed section (now stops; the
partial-load contract is written down); the Rose could miss its region waking after a
load (restore emits nothing by design — now recomputed).

**Debt / owed / TBD:** per-Trump Present costs (arcana.md sets none — placeholders 30/20);
reversed strengthening numbers for most cards; Trump XVII's "max Fortune −20 while
slotted" needs a modifier stack on Fortune (combat/effects round); Overturn's Present
stays unauthored outside side-view space (canon TBD); "a grafting arrives grown" is a
recorded round-6 decision the director may reverse; `progression.md` now states the
revive-class Future rule that `arcana.md` §XX assigned to it (`cfdab91`).

**Director asks:** issue #11 (health vs petals) still open — round 7 builds to option 1
(health pool + petals as manual heals) as the working assumption, flagged in code.

## Round 7 — Combat (CLOSED 2026-08-18)

**Shipped (`4b83004`; `8d1b004` docs):** `CombatRules` (hand-authored, doc-regex
drift-tested; canon numbers pinned, everything else TBD by name); `MovesetController` — a
pure, headless state machine for the whole Bindle: 3-hit light string with a combo
window, heavy arc, **charged heavy = stagger launcher**, running lunge, Focus directional
dodges (roll / side hop / **the grand backflip**) sharing one i-frame window,
out-of-Focus roll, block-step absorbing exactly one hit, no jump, no cancels;
`FocusTargeting` (lock, live re-acquire, `focus_cycle` action); `HoldOrToggle`
accessibility; Combatant/Hurtbox/Hitbox nodes; `FoolCombat` on the Fool with time
compensation so **the Fool moves at normal speed through the slowed world**;
`CombatService` — perfect window = rules × difficulty + an accessibility bonus
independent of mode; **Fool's Chance** slows the world on a real-seconds timer, arms the
free Present cast, pays Fortune; hits trickle; plain dodges pay nothing; the Rose heals by
a petal; defeat → revive at the Waystation with the Rose regrown. Built to the working
ruling on issue #11 (health pool + petals as manual heals), flagged in code.

**Proof:** 661 unit tests (131 new) + a real-physics arena test: light string hits and
earns, charged heavy staggers and the follow-up pays bonus, block-step absorbs for 0,
early dodge = plain dodge, perfect dodge → time_scale 0.3 → Trump I cast free with the
meter unmoved, Story halves damage, zero health → defeated → revive. Critic mutations all
caught (i-frames covering the whole dodge; any-dodge-perfect; time_scale never restored;
no stagger; block-step taking damage; Story ×1.0; chain without window; bonus scaled by
difficulty; revive not regrowing; attacks not locking movement). **Blocking catches
fixed:** the Fool's body wasn't compensated during slow-mo; a plain dodge paid 2.5× a
hit's Fortune ("dodging early and often" is what Fool's Chance exists not to reward);
the block-step absorbed unlimited hits; the perfect-dodge band was measured from dodge
start (Trial ≈ 24 ms) — now from when i-frames open, with a data-level floor.

**Art requests (for the director's Codex lane):** the Fool animation states listed in
`godot/systems/combat/README.md` (Bindle_Light_1/2/3, Heavy_Sweep, Charge_Hold, Launcher,
Lunge, Dodge_Roll, Focus_Side_Hop, Grand_Backflip, Block_Step, Focus_Ready/Strafe,
Hit_React, Defeat_Collapse/Rise, Rose_Petal_Heal). Nothing is wired to a clip yet.

**Debt / owed:** soft target-assist outside Focus (combat.md §Philosophy) not built; no
input buffer (stated decision); Trump effect execution still owed (cast_present emits);
the defeat presentation (fall, Pip's lick, fade, Querent pool) and the teleport to the last
Waystation belong to rounds 9/10/13.

**Director asks:** issue #11 still open (built to option 1).

## Round 8 — Enemies (CLOSED 2026-08-18)

**Shipped (`2d4576a`):** **52 Blank definitions generated from combat.md's suit and rank
tables** (cells verbatim; no numbers — canon has none; `EnemyRules` is the one tuning place,
every number TBD by name, with a 12-frame telegraph floor both clamped and refused by
validation against the tightest difficulty stack); `BlankBrain` (pure, headless) where suit
shapes behaviour (Cups keeps range and lobs, Swords strings, Wands reach, Coins shield) and
rank shapes role (printed number = toughness, Page flees to alert and never attacks, Knight
elite, Queen buffs allies, King mini-boss); pooled Blank scenes with measured sprite pivots,
`CoinsShield` as a `CombatDefense` subclass (combat contracts untouched), a pooled Cups lob,
`Encounter` as a real gate, defeat = slump + the card flutters free (never a death); Beast/
Fog-mask stubs keyed to `WS_STRENGTH_UNBOUND` / `WS_MOON_UNBOUND`. **The MQ00 ambush is
real:** three Twos (Cups, Swords, Wands) rise between the standing stones; the Querent's
mid-fight line on engage, the cleared line after; reaching it before the dead tree is
latched. Art requests appended to `godot/art/ART-REQUESTS.md` (plus the round-7 Fool
animation states) for the director's Codex lane.

**Proof:** 730 unit tests (69 new) + `enemies_test` (42 checks — the three Twos fall to real
Bindle hits through real hit/hurt boxes; a Blank's telegraphed swing lands on a passive
Fool; a timed dodge against it is DODGED_PERFECT). Critic: 10/10 mutations caught (zero
telegraph refused+clamped; clear-on-enter; instancing per acquire; shield never blocking;
Page never fleeing; inverted rank curve even when validation stays happy; hand-edited
generated data; the Cliff latch removed; card flutter silenced; brain ignoring difficulty).
**Blocking catch fixed:** a *staggered* Page recovered into approach and then attacked —
now the stagger exit routes by role and approach itself refuses a Page.

**Debt / owed:** Wands' "flame-tagged attacks that punish standing still" is carried as
data and read by nothing (no hazard system; deciding it in code would be inventing combat
canon — a doc pass owns it); soft target-assist outside Focus still not built; enemies
have no display names (no doc names a Blank — the UI round decides); the card-flutter
"new bearer rises past the ridge" effect is a signal awaiting art.

**Director asks:** none new.

## Round 9 — Pip (CLOSED 2026-08-18)

**Shipped (`b245449`; `579d31d` docs):** the command wheel as pure input→command logic
(`PipWheel` sectors/dead-zone/hold-release-tap + a read-only view for the UI round),
`PipService` (Fetch / Harry / Seek lifecycles; refusals while out; **zero health → retreat →
cooldown → return, never removed** — no death word anywhere in the folder, proved by
reflection over every script and a pinned public surface; a target freed mid-errand
aborts cleanly), `PipCompanion` on Pip's scene, `Seekable`/`Fetchable` props, Pip as a
Combatant on the Fool's side who can never be mistaken for the Fool; Harry through a
minimal, listed hook in the enemy layer (the Blank's brain sees Pip where the Fool would
be, telegraphs lengthen and never sharpen); the defeat beat (trot over, lick) as a
presentation hook the service raises itself. **MQ00's keepsake now goes through Seek** —
Pip walks in behind the Fool, the reach measured from him. Pip animation requests appended
to `godot/art/ART-REQUESTS.md`; combat.md §Accessibility now names Focus and the Pip wheel
among hold/toggle inputs.

**Proof:** 799 unit tests (69 new) + `pip_test` (real wheel input, real hits: a Blank's swing
puts Pip to zero and he retreats, is never removed, and returns whole). Critic: 8/8
mutations caught (cooldown ignored; hide or free Pip; harry silent; Seek found before
arrival; wheel tie-break; command accepted while out; the dig site one-shot again; Blank
still targeting Pip after the pin). **Blocking catches fixed:** payload signals could carry
a freed target (an engine error the first time a region unloads mid-errand); Seek's
"points toward a trap / secret / fog-hidden path" half was unbuilt and unmarked (now a
TBD flag on `Seekable`, README + rules notes).

**Debt / owed:** nothing real to Fetch yet (lobbed weapons/quest objects/ammunition don't
exist); the wooden dog has nowhere to go (MQ00's Almanack-curio open question); the
Mirrormarsh fear is MQ18's (untouched); the `Blank` cast in `PipCompanion` is the one
cross-system reach (a `Distractable` seam when a second enemy family gets a body).

**Director asks:** none new (issues #10, #11 still open).

## Round 10 — Regions and Waystations (open 2026-08-18)

**Goal:** 22 `RegionDefinition`s generated from world.md §Regions (adjacency hand-authored
from §Layout), the persistent layer (Fool, Pip, camera, UI root above a swapped region
scene), `RegionService` as the only loader (adjacency, hard gates, fast travel gated on
`WS_CHARIOT_UNBOUND`, rest at Waystations, defeat → return to the last Waystation),
new-game and load flows, Cliff → Prestige (greybox stub). _In progress._
