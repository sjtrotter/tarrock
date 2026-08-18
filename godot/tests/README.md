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
| `.tres` under `res://data` | any property whose value is three words or more. `DOC_ONLY_PROPERTIES` is the one allowlist — `effect_summary`, `notes`, `doc_ref`, `source_ref`, `description_doc` — and the const carries the reason each is exempt: they cite or paraphrase the doc a definition came from, for reviewers and drift tests, and are never displayed. |

`res://scripts` is legacy presentation; it joins `SCRIPT_ROOTS` a folder at a time as
rounds migrate it under `res://systems` (PROMPT.md, standing decision 10).

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
