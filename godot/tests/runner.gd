extends SceneTree

## The unit-test runner.
##
##     godot --headless --path godot --script tests/runner.gd
##
## Discovers every `res://tests/unit/**/*_test.gd`, instantiates it (each extends
## `TarrockTest`), and for every `test_*` method runs
## `before_each()` -> the method -> `after_each()`, printing one line per method.
## Exits 0 when every test passed, 1 otherwise.
##
## Tests run on the first idle frame, never from `_initialize()`: at
## `_initialize()` time the tree has not stepped, autoloads are not `_ready`, and
## physics has not run (the legacy scene tests learned this the hard way - see
## `res://tests/README.md`).
##
## A test method may be a coroutine (`await` in its body) - see `_settle`. The run
## then spans several frames, and `_process` must NOT be the thing that waits: a
## suspended GDScript function returns a `GDScriptFunctionState` to its caller, the
## engine reads that truthy Variant as `_process`'s "true - quit now" bool, and the
## run ends mid-suite with exit 0. So `_process` starts the run once, keeps a
## reference to it, and always answers false; the run quits the tree itself when it
## is done.
##
## The runner cannot see a runtime SCRIPT ERROR inside a test (GDScript has no
## catch, and the engine keeps going after one). `res://tests/run_all.sh` is the
## half of the guard that does: it fails any stage whose log contains an engine
## `ERROR:` / `SCRIPT ERROR:` line, so a test that dereferences a null or calls a
## method that does not exist can no longer be reported as a pass.

const UNIT_ROOT := "res://tests/unit"
const TEST_SUFFIX := "_test.gd"

## What `Object.call()` returns in Godot 4.7 when the called method suspends: a
## `GDScriptFunctionState`, NOT a `Signal` (`result is Signal` is false for it).
const COROUTINE_STATE_CLASS := "GDScriptFunctionState"

var _passed: int = 0
var _failed: int = 0

## True from the first idle frame on: the run is started exactly once.
var _started: bool = false

## Whatever `_run_and_report` handed back - a `GDScriptFunctionState` while a
## coroutine test is suspended, null once the run finished. Held so a suspended run
## cannot be collected before the signal it is waiting on arrives.
var _run_state: Variant = null


func _initialize() -> void:
	# Nothing here on purpose. See the class doc.
	pass


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		# Called through `call()` so the function state is a value we can hold; see
		# the class doc for why `_process` must never await.
		_run_state = call("_run_and_report")
	# false = keep ticking. A suspended test needs the frames it is awaiting, and a
	# finished run has already called `quit()`.
	return false


## The whole run, start to verdict. Suspends whenever a test does.
func _run_and_report() -> void:
	await _run_all()
	print("UNIT TESTS: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	var paths := _discover(UNIT_ROOT)
	paths.sort()
	if paths.is_empty():
		push_error("no unit tests found under %s" % UNIT_ROOT)
		_failed += 1
		return
	for path: String in paths:
		await _run_suite(path)


## Every `*_test.gd` under `dir`, recursively.
func _discover(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("cannot open %s" % dir_path)
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child := dir_path.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_discover(child))
		elif entry.ends_with(TEST_SUFFIX):
			found.append(child)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


func _run_suite(path: String) -> void:
	var script: GDScript = load(path) as GDScript
	if script == null:
		print("FAIL %s::<load>: script did not load (parse error?)" % path)
		_failed += 1
		return
	var instance: TarrockTest = script.new() as TarrockTest
	if instance == null:
		print("FAIL %s::<load>: script does not extend TarrockTest" % path)
		_failed += 1
		return

	var methods := _test_methods(instance)
	if methods.is_empty():
		print("FAIL %s::<load>: no test_* methods" % path)
		_failed += 1
		return

	for method: String in methods:
		instance._reset_failures()
		# Everything goes through `call()` so a coroutine hook or test hands back a
		# state object `_settle` can wait on; a plain method just returns its value.
		await _settle(instance.call("before_each"))
		await _settle(instance.call(method))
		await _settle(instance.call("after_each"))
		var failures := instance.failures()
		if failures.is_empty():
			_passed += 1
			print("PASS %s::%s" % [path, method])
		else:
			_failed += 1
			for message: String in failures:
				print("FAIL %s::%s: %s" % [path, method, message])


## Wait for a suspended test, so its assertions run BEFORE the verdict is read.
##
## Godot 4.7: calling a method that contains `await` through `Object.call()`
## returns a `GDScriptFunctionState` object - not a `Signal`, so `result is Signal`
## does not detect it and `await result` on the raw value returns immediately, which
## is exactly how an awaiting test used to be scored on an empty failure list. The
## state's `completed` signal is the thing to await; `is_valid(true)` guards the case
## where the method already ran to completion and the signal will never fire again.
func _settle(result: Variant) -> void:
	var state := result as Object
	if state == null or state.get_class() != COROUTINE_STATE_CLASS:
		return
	if not bool(state.call("is_valid", true)):
		return
	await Signal(state, "completed")


func _test_methods(instance: TarrockTest) -> PackedStringArray:
	var names := PackedStringArray()
	for entry: Dictionary in instance.get_method_list():
		var method_name := String(entry["name"])
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	names.sort()
	return names
