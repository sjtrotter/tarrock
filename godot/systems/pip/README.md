# `systems/pip/` — the command wheel, and the dog who cannot die

Built by round 9 of [`docs/gauntlet-systems/PROMPT.md`](../../../docs/gauntlet-systems/PROMPT.md).
Canon: [`docs/design/combat.md`](../../../docs/design/combat.md) §Pip (the radial wheel:
Fetch, Harry, Seek — and "Pip cannot die") and §Defeat step 2 (Pip trots over and licks
the Fool's face), [`docs/design/characters.md`](../../../docs/design/characters.md) §Pip
(never speaks, never explained, never performs concern; the protection rule), and
[`docs/quests/main/MQ00-the-leap.md`](../../../docs/quests/main/MQ00-the-leap.md) §The Old
Campsites, which is the first Seek in the game. **No number is spelled in this folder** —
they all live in [`data/pip/pip_rules.tres`](../../data/pip/pip_rules.tres), and every one
of them is a TBD placeholder the combat-tuning pass owns (that resource's `notes` lists
them by name). Same contract as `systems/combat/` and `systems/enemies/` before it.

## The shape

```
pip_command.gd                   FETCH / HARRY / SEEK, and nothing else exists
definitions/pip_rules.gd         every tuning number, one hand-authored resource
pip_wheel.gd                     the GESTURE - hold, aim, release; pure, no Input
pip_wheel_view.gd                one frame of the wheel, read-only, for round 13
pip_service.gd                   THE MODE - what Pip is doing, and the retreat
nodes/pip_companion.gd           the seam: buttons -> wheel -> service -> Pip's feet
nodes/seekable.gd                something hidden a region authored, for Seek
nodes/fetchable.gd               an item Pip can retrieve, for Fetch
```

`scripts/pip_follower.gd` belongs to this round too, and stays where it is: it owns
**Pip's legs** — the follow, the eight facings, the trot cycle — and round 9 added
`set_follow_suspended()`, `step_toward()` and `hold_still()` so that a command borrows
those legs rather than growing a second set. `PipCompanion` never writes
`global_position` itself.

**Dependency direction.** `PipService`, `PipWheel`, `PipWheelView`, `PipCommand` and
`PipRules` are plain objects with no tree — a headless test builds them directly and
drives them frame by explicit frame. `PipCompanion` is the only thing here that touches
the scene and the only thing that reads `Input`; `Seekable` and `Fetchable` are as thin
as `Interactable` and know what happened to them, never what it means.

## The gesture (a decision, recorded)

`combat.md` gives Pip "a **radial command wheel**" and says nothing about how it is
driven. The round decided, and `PipWheel`'s class doc is the long version:

* hold `pip_wheel` (already in the InputMap since round 1 — **no new action was added**);
* the move vector picks a sector: **Fetch up-left, Harry up-right, Seek down**;
* release confirms the lit sector;
* a release with the stick inside `PipRules.wheel_dead_zone` repeats the last command
  used, so the command you just gave is one tap away.

Sectors are decided by nearest centre, so the boundaries are the bisectors: straight up
divides Fetch from Harry, and two shallow down-diagonals divide each from Seek. The
three are deliberately not equal thirds — the two combat commands sit either side of
"forward", where a thumb already is mid-fight, and the traversal command sits where
nothing else is.

## The rules that are not tuning

* **Pip cannot die.** There is no method here that ends him and no signal that says he
  did: `PipService.on_pip_health_zero()` starts a retreat, a cooldown and a return.
  `tests/unit/pip/pip_no_death_test.gd` reflects over every script in this folder and
  fails on any member name carrying a word for ending, and pins `PipService`'s public
  surface so a new method is a decision taken in review.
* **Scenes find the target; systems never search a scene.** Fetch needs an item, Harry
  an enemy, Seek a hidden thing. `PipCompanion.target_requested` asks, with Pip's
  position and the reach `PipRules` allows; the region answers with
  `provide_target()`. A scene with nothing to offer says nothing and the command is
  refused with `REASON_NO_TARGET` — which is the Cliff's honest answer to Fetch today.
* **Every command is the same three phases**: `OUTBOUND` → `WORKING` → `RETURNING`.
  Fetch's work is nothing (a pickup is a mouthful, not a job); Seek's is the dig; Harry's
  is the pin; the retreat's is the shake-off.
* **A target that stops existing mid-errand aborts it, and never rides a signal out.**
  Enemies go back to their pool, items are consumed by whatever picked them up, regions
  unload. Every signal carrying a target (`seek_found`, `fetch_delivered`,
  `harry_started`) checks `is_instance_valid` first; when it fails, `PipService` emits
  `command_aborted` and walks Pip home, and `command_completed` deliberately never
  arrives. The same path answers a `Fetchable` that would not go in his mouth —
  `PipCompanion` passes the failed pickup on as `report_arrived(false)`.
* **Time is Pip's own body's.** `PipService.tick()` is driven by `PipCompanion`, in that
  node's `_physics_process`, so every timer here is a timer belonging to a Pip who is in
  a scene: a region with no Pip in it runs none of them, the dig and the shake-off stop
  where they were, and `PipService.reset()` is the door back to ordinary life. Nothing
  ticks the service from an autoload, and a service is `detach()`ed from
  `CombatService` when the Pip driving it goes away, so a defeat cannot reach a dog
  nobody is drawing.
* **The defeat beat hangs on the fight, not on the region.** `combat.md` §Defeat is
  invariant across the whole game, so `PipService` listens to `CombatService.fool_defeated`
  itself and a region that forgot to stage it cannot lose the defeat screen.
* **Harry is one hook in `systems/enemies/`, and it is listed below.**

## The Harry hook (round 9's one addition to round 8)

`combat.md` §Pip: Harry "pins or distracts one target enemy, holding its attention and
briefly reducing its aggression toward the Fool". The two halves are split along the
enemy system's own seam, and nothing else in `systems/enemies/` changed:

| Added | Where | What it does |
|---|---|---|
| `BlankBrain.set_distraction(seconds, telegraph_multiplier)`, `clear_distraction()`, `is_distracted()`, `distraction_seconds_left()` | `systems/enemies/blank_brain.gd` | **The aggression half.** Every telegraph is multiplied while it holds, so the Fool has more room in every window the enemy opens. `EnemyRules.MIN_TELEGRAPH_SECONDS` is still the floor. The countdown is a safety net, not the authority — Pip starts and ends a pin. |
| `Blank.set_distraction(by, seconds, telegraph_multiplier)`, `clear_distraction()`, `distraction()` | `systems/enemies/nodes/blank.gd` | **The attention half.** `_fill_perception()` shows the brain the distractor's position where the Fool's would be, so approach, telegraph, swing and disengage all run against the dog. |

`PipCompanion` is what calls them, and casting the harried target to `Blank` is the one
reach this system makes across a boundary — taken here rather than pushed into every
region scene's wiring. The day the Beasts and the Fog-masks get bodies they get the same
hook and this stays one cast wide.

## MQ00: the dig is Pip's now

`docs/quests/main/MQ00-the-leap.md` §The Old Campsites writes the tutorial prompt as
**"call Pip's Seek command"**, so `scenes/the_cliff.tscn`'s `KeepsakeTrigger`
(`Interactable`, interact key) is gone and `World/Seekables/DisturbedEarth` (`Seekable`,
`reward_event = MQ00_KEEPSAKE_FOUND`) stands in its place. `scripts/the_cliff.gd`
forwards its `found` to `QuestService.raise()` exactly as it forwards a prop's, and
answers Pip's `target_requested` with the nearest available `Seekable` — or, past the
standing stones, the nearest Blank still on its feet.

The dig site is authored **not one-shot**, for the reason round 4 authored the trigger
that way: MQ00's graph only answers the keepsake from `BINDLE_TAKEN`, so a Seek called
before the Bindle is taken has to be a dog digging a hole rather than a soft-lock.
`tests/cliff_test.gd` drives both digs.

## Art requests

Pip has one **wired** cycle today — four frames of a south-east trot
(`art/game-ready-sprites-v1/frames/pip/actions/`) plus his eight direction stills — so
every command below currently plays the trot or the static facing. The pack itself also
ships south-east `idle`, `seek` and `dig` rows (`manifest.json`) that
`scripts/pip_follower.gd`'s animation table does not name yet: wiring those three is a
change to that table and nothing else, and it is owed before any of the requests below
are commissioned, because two of them would otherwise be re-ordering art that exists.
`CharacterAnimator` makes that invisible to everything above it, so wiring a clip per
state is a one-function change the day the art lands. These are the gaps; each one is
written up as a briefed request in
[`godot/art/ART-REQUESTS.md`](../../art/ART-REQUESTS.md) §Pip (round 9 of the systems
gauntlet), items (n) to (s), which is where the formats, paths and acceptance criteria
live:

| Beat | What exists now | What is needed |
|---|---|---|
| **The dig** | The trot, then the idle still while he works — though a south-east `dig` row is sitting unwired in the pack | Wire the row that exists, then the back-out it has no frames for: MQ00 §The Old Campsites, "begins to dig with sudden, businesslike enthusiasm, tail a blur", then "backs out of the hole holding something small in his teeth". |
| **The fetch carry** | The trot, with the item drawn at Pip's own position | A trot with something in his mouth. One variant of the existing cycle, and the carried thing needs a mouth anchor to sit on. |
| **The harry pose** | The idle still while the pin holds | A braced, barking hold — Pip planted in front of a Blank, keeping its attention. `characters.md` §Pip is the constraint: he is "alert, game, entirely present", and **never performs concern**, so this is a working dog, not a heroic one. No bark subtitle, ever. |
| **The retreat and the shake-off** | The trot away, then the idle still | A yelp/flinch beat, a run-out, and the shake-off itself — `combat.md` §Pip: "he yelps, retreats out of the fight, shakes it off, and returns". The shake is the whole point: it reads as annoyance rather than injury, which is what makes it not a death. |
| **The lick** | Nothing; `PipCompanion.licked` fires and nothing draws it | `combat.md` §Defeat names the clip: one `LickFace` interaction on Pip's set, over the Fool's `Defeat_Collapse`. "A dog solving a practical problem, exactly as unbothered as ever… It should be allowed to be a little funny every single time." |
| **The other seven facings** | South-east only, for every row in the pack | The remaining facings of whatever cycles land, same grid and anchors as the Fool's request (a). |

Pivots for anything new: measure them with
`python3 godot/tools/measure_sprite_pivots.py --family pip` and paste the tables it
prints. Do not eyeball an offset.

## What this round deliberately did not build

* **The wheel on screen.** `PipWheelView` is the read-only frame a UI binds to —
  highlighted sector, availability, hold time — and drawing it is round 13's, along with
  the CSV rows behind `PipCommand.NAME_KEYS` and MQ00's two tutorial prompts. Nothing
  here puts a word on screen.
* **The other half of Seek.** `combat.md` §Pip gives the command one sentence with two
  readings in it: Pip goes to a hidden thing and digs it out (MQ00's campsite, which is
  what this round built), and Pip "points toward something hidden nearby — a trap, a
  secret, a fog-hidden path", which he does from where he stands and never touches. The
  second is a point-and-hold beat rather than an `OUTBOUND`/`WORKING`/`RETURNING`
  errand, and there is no trap system and no fog region for it to point at, so building
  it now would be inventing both. `Seekable.approach` is the flag that decision will
  land on: it is declared, defaults to the built reading, warns once if a scene authors
  the other, and **nothing reads it**. A Seek is an approach until that round.
* **Anything real to Fetch.** `combat.md` names "a lobbed weapon, a quest object,
  ammunition"; the Bindle has no throw, a Cups lob belongs to its thrower, and there is
  no ammunition in the game. So no shipped scene holds a `Fetchable` yet, and the
  command is proved against a fixture item. The Bindle's inventory — where a "kept"
  wooden dog would go — is an open question in MQ00 and belongs to the progression
  round.
* **Harrying anything but a Blank.** The Beasts and the Fog-masks have one sentence and
  one world-state rule each and no bodies; giving one a distraction rule would be
  inventing enemy canon in Pip's folder.
* **The Mirrormarsh.** `characters.md` §Pip gives Pip exactly one fear, and MQ18 owns
  that beat entirely. Nothing here knows what a region is, and nothing here may refuse a
  command because of where it was given.
* **Pip in the save model.** Which command was last used, and whether he happens to be
  mid-retreat, are frame state rather than world state. If a save is ever taken mid-pin,
  `PipService.reset()` is the door that puts him back at the Fool's heel.
* **A hold/toggle option for the wheel.** `combat.md` §Accessibility lists the held
  inputs that need one — "block-step, charged heavy, sprint" — and `pip_wheel` is not on
  it. `HoldOrToggle` is sitting in `systems/core/` if the doc ever adds it; adding it
  first, in code, would be writing accessibility canon.
