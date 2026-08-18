class_name TarrockTest
extends RefCounted

## Base class for every Tarrock unit test.
##
## A unit test is a script under `res://tests/unit/**` named `*_test.gd` that
## `extends TarrockTest`. The runner (`res://tests/runner.gd`) instantiates it once,
## then for every method whose name starts with `test_` runs
## `before_each()` -> `test_x()` -> `after_each()`, reporting one line per method.
##
## Assertions RECORD failures and keep going: a method reports every broken
## expectation in one run rather than only the first. A method is a FAIL if it
## recorded at least one failure. Use `fail()` for a bare failure and `return`
## yourself when continuing would be nonsense (e.g. a null you were about to
## dereference).
##
## Tests build plain `RefCounted` services directly - that is what the composition
## root's design is for (see `res://systems/core/services.gd`). A test that genuinely
## needs the tree uses `tree()` and MUST free anything it added to the root in
## `after_each()`.

## Failure messages recorded by the current test method.
var _failures: PackedStringArray = PackedStringArray()

## Signal watchers created by `watch_signal`, keyed by "<instance_id>:<signal>".
var _watchers: Dictionary = {}


## Runs before every `test_*` method. Override for per-test setup.
func before_each() -> void:
	pass


## Runs after every `test_*` method, pass or fail. Override to free nodes.
func after_each() -> void:
	pass


## The live SceneTree, for the rare test that needs real nodes.
func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Called by the runner before each method; not for tests to call.
func _reset_failures() -> void:
	_failures = PackedStringArray()
	_watchers.clear()


## Failure messages recorded so far by the current method.
func failures() -> PackedStringArray:
	return _failures


## Record a failure with no condition attached.
func fail(message: String) -> void:
	_failures.append(message)


## Assert `condition` is true.
func assert_true(condition: bool, message: String = "") -> bool:
	if condition:
		return true
	fail(_describe(message, "expected true, got false"))
	return false


## Assert `condition` is false.
func assert_false(condition: bool, message: String = "") -> bool:
	if not condition:
		return true
	fail(_describe(message, "expected false, got true"))
	return false


## Assert two values are equal (Variant `==`, so 1 != 1.0 is NOT a trap here:
## GDScript compares numerically across int/float).
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> bool:
	if actual == expected:
		return true
	fail(_describe(message, "expected %s, got %s" % [_show(expected), _show(actual)]))
	return false


## Assert two values differ.
func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> bool:
	if actual != unexpected:
		return true
	fail(_describe(message, "expected a value other than %s" % _show(unexpected)))
	return false


## Assert a value is null.
func assert_null(value: Variant, message: String = "") -> bool:
	if value == null:
		return true
	fail(_describe(message, "expected null, got %s" % _show(value)))
	return false


## Assert a value is not null.
func assert_not_null(value: Variant, message: String = "") -> bool:
	if value != null:
		return true
	fail(_describe(message, "expected a value, got null"))
	return false


## Assert two floats are within `epsilon` of each other.
func assert_almost_eq(
	actual: float, expected: float, epsilon: float = 0.0001, message: String = ""
) -> bool:
	if absf(actual - expected) <= epsilon:
		return true
	fail(
		_describe(
			message, "expected %f +/- %f, got %f (delta %f)" % [
				expected, epsilon, actual, actual - expected
			]
		)
	)
	return false


## Assert an Array/Dictionary/String contains `item` (Dictionary checks keys).
func assert_has(container: Variant, item: Variant, message: String = "") -> bool:
	var found := false
	if container is Dictionary:
		found = (container as Dictionary).has(item)
	elif container is Array:
		found = (container as Array).has(item)
	elif container is String:
		found = (container as String).contains(str(item))
	elif container is PackedStringArray:
		found = (container as PackedStringArray).has(str(item))
	else:
		fail(_describe(message, "assert_has needs an Array, Dictionary, String or PackedStringArray"))
		return false
	if found:
		return true
	fail(_describe(message, "expected %s to contain %s" % [_show(container), _show(item)]))
	return false


## Start recording emissions of `signal_name` on `source`. Call before the code
## under test runs; then assert with `assert_signal_emitted`.
## Signals with more than four arguments are not supported (none in Tarrock are).
func watch_signal(source: Object, signal_name: StringName) -> void:
	var key := _watch_key(source, signal_name)
	if _watchers.has(key):
		return
	if not source.has_signal(signal_name):
		fail("no signal '%s' on %s" % [signal_name, _show(source)])
		return
	var arg_count := _signal_arg_count(source, signal_name)
	var watcher := SignalWatcher.new()
	if not watcher.connect_to(source, signal_name, arg_count):
		fail("cannot watch '%s': %d arguments is more than 4" % [signal_name, arg_count])
		return
	_watchers[key] = watcher


## Assert a watched signal fired. `times` of -1 means "at least once"; any other
## value asserts an exact emission count.
func assert_signal_emitted(
	source: Object, signal_name: StringName, times: int = -1, message: String = ""
) -> bool:
	var key := _watch_key(source, signal_name)
	if not _watchers.has(key):
		fail(_describe(message, "signal '%s' was never watched (call watch_signal first)" % signal_name))
		return false
	var watcher: SignalWatcher = _watchers[key]
	if times < 0:
		if watcher.count > 0:
			return true
		fail(_describe(message, "expected '%s' to be emitted, it never was" % signal_name))
		return false
	if watcher.count == times:
		return true
	fail(
		_describe(
			message, "expected '%s' %d time(s), got %d" % [signal_name, times, watcher.count]
		)
	)
	return false


## The arguments of the n-th emission of a watched signal, or an empty Array.
func signal_arguments(source: Object, signal_name: StringName, index: int = 0) -> Array:
	var key := _watch_key(source, signal_name)
	if not _watchers.has(key):
		return []
	var watcher: SignalWatcher = _watchers[key]
	if index < 0 or index >= watcher.emissions.size():
		return []
	return watcher.emissions[index]


func _watch_key(source: Object, signal_name: StringName) -> String:
	return "%d:%s" % [source.get_instance_id(), signal_name]


func _signal_arg_count(source: Object, signal_name: StringName) -> int:
	for entry: Dictionary in source.get_signal_list():
		if StringName(entry["name"]) == signal_name:
			return (entry["args"] as Array).size()
	return 0


func _describe(message: String, detail: String) -> String:
	if message.is_empty():
		return detail
	return "%s (%s)" % [message, detail]


func _show(value: Variant) -> String:
	if value is String:
		return '"%s"' % value
	return str(value)


## Records emissions of one signal. Godot has no variadic Callable, so there is
## one handler per arity; four covers every signal in the codebase.
class SignalWatcher:
	extends RefCounted

	## How many times the signal fired.
	var count: int = 0

	## One entry per emission, each an Array of that emission's arguments.
	var emissions: Array[Array] = []

	## Connect to `signal_name` on `source`. Returns false if the arity is > 4.
	func connect_to(source: Object, signal_name: StringName, arg_count: int) -> bool:
		match arg_count:
			0:
				source.connect(signal_name, _on_0)
			1:
				source.connect(signal_name, _on_1)
			2:
				source.connect(signal_name, _on_2)
			3:
				source.connect(signal_name, _on_3)
			4:
				source.connect(signal_name, _on_4)
			_:
				return false
		return true

	func _record(args: Array) -> void:
		count += 1
		emissions.append(args)

	func _on_0() -> void:
		_record([])

	func _on_1(a: Variant) -> void:
		_record([a])

	func _on_2(a: Variant, b: Variant) -> void:
		_record([a, b])

	func _on_3(a: Variant, b: Variant, c: Variant) -> void:
		_record([a, b, c])

	func _on_4(a: Variant, b: Variant, c: Variant, d: Variant) -> void:
		_record([a, b, c, d])
