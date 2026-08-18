# Tests

## Running them

```bash
bash godot/tests/run_all.sh        # the one command; exit 0 = green
GODOT=/path/to/godot bash godot/tests/run_all.sh
```

It runs three stages and fails the whole command if any of them fails:

1. **lint** — every `.gd` in the project is loaded with `--check-only`. Static typing is
   enforced by the engine (see below), so "loads" and "is fully typed" are the same
   check. The sweep exists for scripts no test loads (`tools/`, `scripts/spike/`), which
   would otherwise rot untyped until someone opened the game.
2. **unit tests** — `res://tests/runner.gd` runs every `res://tests/unit/**/*_test.gd`.
3. **scene tests** — the legacy `res://tests/*_test.gd`, each in its own process.

Two guards wrap every suite in stages 2 and 3:

- **An engine error fails the stage.** A runtime script error — a nonexistent
  method, a null dereference — does not stop GDScript: the engine prints
  `SCRIPT ERROR: …` and carries on, so the test would record no assertion failure
  and be reported as a pass. Each stage is teed to a log, and any line starting
  `ERROR:` / `SCRIPT ERROR:` / `USER ERROR:` fails that stage whatever the exit code
  was. A green tree emits none. Godot `WARNING:` lines are left alone — the spike
  scenes emit some. If a legitimate error line ever appears, fix its cause or argue
  the exception in `run_all.sh`; do not widen the pattern quietly.
- **A hang fails the stage.** Every `godot` invocation runs under `timeout 120`, so
  a wedged scene — or a coroutine test awaiting a signal that never fires — reports
  `--- TIMEOUT after 120s` and a FAIL instead of stalling the run. Without coreutils
  `timeout` the script warns once and runs unbounded.

Single suites, when you are iterating:

```bash
godot --headless --path godot --script tests/runner.gd          # all unit tests
godot --headless --path godot --script tests/cliff_test.gd      # one scene test
godot --headless --path godot --check-only --script scripts/player.gd   # typing only
```

## Writing a unit test

A unit test is a script under `tests/unit/<system>/` named `*_test.gd` that
`extends TarrockTest` (`tests/lib/tarrock_test.gd`). The runner instantiates it once and,
for every method named `test_*`, runs `before_each()` → the method → `after_each()`.

```gdscript
extends TarrockTest

func test_paused_clock_does_not_advance() -> void:
    var clock := GameClock.new()
    clock.paused = true
    clock.advance(10.0)
    assert_almost_eq(clock.elapsed_seconds, 0.0, 0.0001, "no time passes while paused")
```

- Assertions **record and continue**: `assert_*` returns a bool and appends to the
  method's failure list rather than aborting, so one run reports every broken
  expectation in the method. `if not assert_not_null(x): return` where continuing would
  dereference a null.
- Available: `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_null`,
  `assert_not_null`, `assert_almost_eq`, `assert_has`, `fail`, plus
  `watch_signal(source, &"name")` → `assert_signal_emitted(source, &"name", times)` and
  `signal_arguments(source, &"name", index)`.
- **Prefer no tree.** Services are plain `RefCounted`s precisely so a test can build
  them directly. `tree()` gives the live `SceneTree` when a test genuinely needs nodes —
  anything added to `tree().root` must be freed in `after_each()`.
- **A test may await.** `test_*`, `before_each` and `after_each` can be coroutines;
  the runner waits for the whole method to finish before it reads the verdict, so
  assertions after an `await` still count. Await something that is guaranteed to
  fire (`await tree().process_frame`, a signal the code under test emits) — an await
  that never resumes stalls the run until the 120s suite timeout fails it. Both
  halves of this are real: Godot returns a `GDScriptFunctionState` (not a `Signal`)
  from `call()` on a suspending method, and the runner's own `_process` must never
  await, because the engine reads a suspended `_process`'s state object as
  "true — quit now". `runner.gd`'s class doc has the long version.
- The framework itself is covered by `tests/unit/core/tarrock_test_self_test.gd`, which
  proves failing assertions really do fail by running them on a *nested* `TarrockTest`
  and asserting the failure was recorded. That is how you test a red path without
  leaving a red test in the suite.

## The scene tests and the persistent layer

From round 10 the game's `run/main_scene` is `res://scenes/persistent_layer.tscn`, not
a region: the Fool, Pip, the camera and the UI root live there, and `RegionService`
instances one region scene underneath them (`docs/design/technical.md` §Regions and the
persistent layer). A scene test that needs the Fool therefore **instances the layer**
and lets it boot - `Services.new_game()` builds the services, travels to the Cliff and
starts MQ00 - rather than instancing a region by hand:

```gdscript
func _initialize() -> void:
    var packed: PackedScene = load("res://scenes/persistent_layer.tscn")
    _layer = packed.instantiate() as PersistentLayer
    root.add_child(_layer)
```

The region is standing under `_layer.region()` by the second physics frame: the layer
performs a swap when the frame's message queue flushes, deferred because a swap is
usually asked for from inside a physics callback and Godot cannot free a scene full of
`Area2D`s mid-flush. `res://tests/regions_test.gd` walks the whole flow (new game,
leap, rest, load); `cliff_test.gd` plays MQ00 through the Cliff under the layer.

**A test that must point the saves somewhere else takes the boot over.** `_initialize()`
runs *before* the `Services` autoload's own `_ready()` (see the legacy pattern below), so
there is no moment there at which the composition root can be pointed at a scratch save
directory. Set `boot_new_game_on_ready = false` on the layer before adding it, then on
the first physics frame call `Services.set_saves_dir()` and `_layer.new_game()` - which
is what `regions_test.gd` does, because it writes a real file to a real slot and must
never write it into the player's `user://saves`. `cliff_test.gd` still lets the layer
boot itself, so that path stays covered.

**A `SceneTree` script must not name `SaveModel`.** Godot 4.7 leaks that class's
`GDScript` (and `DifficultyMode` with it) at engine exit when the main-loop script
references it - even only through inference, as in `var model := save.capture()` - and
the engine reports it as `ERROR: 2 resources still in use at exit`, which fails the
stage. Nothing else about the test is wrong when this happens. Go through the
composition root instead: `Services.save_game(slot)` / `load_game(slot)` hand back a
bool and keep the model on their side of the fence.

## The proof slice — `tests/playthrough_test.gd`

Every other suite proves one system against a fixture. `playthrough_test.gd` proves the
**seams between them**, which is the one thing no per-system suite can: it plays MQ00
from the black screen to a purchase in the Prestige and back out of a save file, in one
process, and asserts every beat by name. Boot → the Querent's waking line → the Bindle →
Pip's Seek at the disturbed earth → the wooden dog's three questions → the dead tree →
the ambush (three Twos, a perfect dodge into Fool's Chance, a petal spent, three cards
fluttered) → the rest at the first Waystation → the four questions at the edge → the leap
→ the Prestige stall → save → rebuild → load → assert the world came back identical.

**It is the regression gate for the slice.** A change that leaves every system's own
tests green and still breaks the game — a beat that stops raising its event, a trigger a
region scene forgets to forward, a save section nobody captures, an input action that
stops reaching a component — fails here and nowhere else. Treat a failure in it as a
broken game, not a broken test: read the phase name it failed in first.

Four things about it are worth knowing before changing it:

- **It drives the game through the InputMap actions**, not through the controllers.
  Presses go out as `InputEventAction`s through `Input.parse_input_event()` (flushed by
  hand), because that reaches both halves of the input surface: the polled one every
  gameplay script reads, and `_unhandled_input`, where `DialogueFrame` and `UiShell`
  listen. `Input.action_press()`, which `combat_test.gd` and `enemies_test.gd` use, only
  reaches the first. Two beats cannot be driven that way and say so in the class doc: a
  dialogue choice row (a `Button`, and `ui_accept` shares a key with `dodge`), and the
  Prestige purchase (the Prestige is a greybox with no shop node in it).
- **The Fool is set down between beats and walks into every one of them.** A teleport is
  only ever to a stand-off *outside* the next trigger; no teleport lands in a trigger, an
  encounter volume, a Waystation circle or on the leap point. Crossing the Cliff on the
  Fool's legs four times would cost most of the suite's time budget and prove nothing the
  walk-ins do not.
- **The coupling it found is fixed, not worked around.** `interact` is on both halves of
  that surface at once: `DialogueFrame` consumes it as an event and calls
  `set_input_as_handled()`, and `player.gd` POLLS it — and handling an event does not
  stop a poll. So advancing the Querent's waking line also acted on whatever prop was in
  reach, which on the Cliff meant the Bindle 184 px away (a 90 px trigger circle and the
  Fool's 96 px sensor) was taken before the tutorial asked for it. The fix is a
  SUSPENSION: while a conversation is on screen or a menu is open, `UiShell` puts the
  Fool's world interaction down (`FoolBody.set_world_interaction_enabled()`), and the
  press that closed the conversation has to come up before the world hears the key again.
  The dialogue frame's event handling is untouched. Phase 1 is the proof — it walks the
  whole opening conversation out standing inside the Bindle's own trigger and asserts the
  Bindle is still lying there — and `tests/unit/ui/shell_test.gd` holds the shell's half.
  Both assertions wait `POLL_FRAMES` after a press, because the poll runs a frame behind
  an event this suite flushed and an assertion made any sooner would prove nothing.
- **Nothing waits on the wall clock.** Every phase is bounded in physics frames and fails
  by name when it overruns, so a stuck walk reports "the fight finished inside its
  1400-frame budget" rather than running into the harness's 120 s timeout, where the
  diagnosis would be "something hung". The run prints a phase→frames timeline at the end;
  the whole playthrough is around 1,330 physics frames.

It uses a scratch saves directory **and** a scratch settings path (`UiSettings.
settings_path_override`), for the reasons `ui_test.gd` and `regions_test.gd` give, and
deletes both when it is done.

## The legacy scene-test pattern

`tests/*_test.gd` predate the unit runner. Each `extends SceneTree`, loads a real scene,
prints its own `PASS:`/`FAIL:` lines and calls `quit(0)` / `quit(1)`. They are the right
shape for "does the Cliff scene actually work", and `run_all.sh` keeps running them, one
process each (each one ends its own tree, so they cannot share one).

**The lesson they encode: nothing physical has happened yet in `_initialize()`.** The
tree has not stepped, `_ready` has not run on the scene, no physics frame has passed, so
positions, collisions and `CharacterBody2D` state are all garbage there. Add the scene in
`_initialize()`, then assert from `_physics_process()` after a couple of frames:

```gdscript
func _physics_process(_delta: float) -> bool:
    _frame += 1
    if _frame < 3:
        return false     # false = keep running
    ...
    quit(0 if _all_passed else 1)
    return true
```

The unit runner obeys the same rule: it runs from `_process()` on the first idle frame,
not from `_initialize()`, so autoloads (`Services`) are `_ready` before any test looks
at them.

## The localization lint

`tests/unit/core/localization_lint_test.gd` is the day-one guard behind standing
decision 6 (no player-facing literal in code or content). It is textual on purpose —
it must fail on a scene nobody can instantiate yet — and it walks three places:

| Where | What fails |
|---|---|
| `.tscn` under `res://scenes` and `res://systems` | `text`, `tooltip_text`, `placeholder_text`, `dialog_text` or `title` on a Control- or Window-derived node holding anything but a `SHOUTING_SNAKE_CASE` key. The property's last path segment is matched, so `popup/item_0/text` (OptionButton) and `item_0/text` (ItemList) are covered. |
| `.gd` under `res://systems` | a string literal of three words or more (two spaces) outside a comment. `&"…"` StringNames, `res://`/`user://` paths and lines calling a diagnostic sink are exempt — `DIAGNOSTIC_CALLS` lists them with a reason each (`print*`, `push_error`, `push_warning`, `assert`, `fail`, `assert_*`, and `errors.append` for `TarrockDefinition.validate()`'s problem list). `OS.alert` is deliberately *not* exempt: it puts text on screen. |
| `.tres` under `res://data` | any property whose value is three words or more. `DOC_ONLY_PROPERTIES` is the one allowlist — `effect_summary`, `notes`, `doc_ref`, `source_ref`, `description_doc`, a region's `summary`, and a Trump's `past_summary` / `present_summary` / `future_summary` / `burden_name` / `burden_summary` — and the const carries the reason each is exempt: they cite or paraphrase the doc a definition came from, for reviewers and drift tests, and are never displayed. |

`res://scripts` is legacy presentation; it joins `SCRIPT_ROOTS` a folder at a time as
rounds migrate it under `res://systems` (PROMPT.md, standing decision 10).

**The lint above reads files, so it cannot see a string a view assigns at run time**, and
every page under `systems/ui/nodes/` builds its Controls in code: `button.text = "Resume"`
has no `.tscn` line to read and no two spaces to trip the sentence heuristic.
`tests/unit/ui/ui_strings_test.gd` closes that hole from the other side — it instantiates
every `res://scenes/ui/*.tscn` with no services at all, lets it build, walks the Control
tree, and fails on any `text` / `tooltip_text` / `placeholder_text` / tab title that is not
empty and not a `SHOUTING_SNAKE_CASE` key with a row in a shipped CSV. The two kinds of
drawn text that cannot be one key — a row formatted out of a key and a number, and a device
label the hardware spells — declare themselves on the control (`UiKeys.COMPOSED_TEXT_META`)
and say which kind they are; the suite performs its own mutation (lettering the pause
menu's Resume row in English) to prove it still fails when it should.

## The typing rule

`project.godot` sets `debug/gdscript/warnings/untyped_declaration=2` — warning treated as
**error**. In Godot 4.7 that covers untyped variables, untyped `for` iterator variables,
untyped function parameters and missing return types, in scripts *and* in lambdas, and it
turns each of them into a parse error, so the script **fails to load**. There is no way to
run untyped code in this project; there is nothing to remember at review time.

What this means in practice:

- `var x: int = 1` and `var x := 1` are both fine (`:=` is a static type, inferred).
- `for entry in some_array:` is not — write `for entry: Array in some_array:`. Use
  `Variant` only where the container is genuinely heterogeneous.
- `func(a, b): return a < b` is not — write `func(a: Variant, b: Variant) -> bool:`.

## Where things live

| Path | What |
|---|---|
| `tests/run_all.sh` | the one command |
| `tests/runner.gd` | discovers and runs the unit tests |
| `tests/lib/tarrock_test.gd` | `TarrockTest` — the base class and its assertions |
| `tests/unit/<system>/*_test.gd` | unit tests, one folder per system |
| `tests/*_test.gd` | legacy scene tests (`extends SceneTree`) |
| `tests/playthrough_test.gd` | the proof slice: MQ00 → the Prestige → a save round trip |
