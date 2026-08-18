extends TarrockTest

## The composition root and the first service it owns.
##
## The point of the pattern is that `GameClock` needs no tree: most of these tests
## build it bare. The last few touch the autoload - to prove it is wired and holding
## a live clock, and to pin the ruling that in-game time is WORLD time and scales
## with `Engine.time_scale` (see `GameClock`'s class doc).


func after_each() -> void:
	# The time-scale test mutates a global. Anything left at 0.5 would quietly halve
	# every later test's idea of a second.
	Engine.time_scale = 1.0


func test_clock_starts_at_zero() -> void:
	var clock := GameClock.new()
	assert_almost_eq(clock.elapsed_seconds, 0.0)
	assert_eq(clock.whole_seconds(), 0)
	assert_false(clock.paused, "a new clock is running")


func test_advance_accumulates() -> void:
	var clock := GameClock.new()
	clock.advance(0.25)
	clock.advance(0.5)
	assert_almost_eq(clock.elapsed_seconds, 0.75)


func test_paused_clock_does_not_advance() -> void:
	var clock := GameClock.new()
	clock.advance(1.5)
	clock.paused = true
	clock.advance(10.0)
	assert_almost_eq(clock.elapsed_seconds, 1.5, 0.0001, "no time passes while paused")
	clock.paused = false
	clock.advance(0.5)
	assert_almost_eq(clock.elapsed_seconds, 2.0, 0.0001, "unpausing resumes where it stopped")


func test_negative_delta_is_ignored() -> void:
	var clock := GameClock.new()
	clock.advance(1.0)
	clock.advance(-5.0)
	assert_almost_eq(clock.elapsed_seconds, 1.0, 0.0001, "in-game time never runs backwards")


func test_second_ticked_fires_once_per_whole_second() -> void:
	var clock := GameClock.new()
	watch_signal(clock, &"second_ticked")
	for _index: int in 30:
		clock.advance(0.1)
	assert_signal_emitted(clock, &"second_ticked", 3, "three seconds of 0.1s steps -> three ticks")
	assert_eq(signal_arguments(clock, &"second_ticked", 2), [3], "the tick carries the new total")


func test_a_big_delta_emits_every_second_it_crossed() -> void:
	var clock := GameClock.new()
	watch_signal(clock, &"second_ticked")
	clock.advance(4.2)
	assert_signal_emitted(clock, &"second_ticked", 4, "a long frame must not swallow ticks")
	assert_eq(clock.whole_seconds(), 4)


func test_reset_returns_to_zero() -> void:
	var clock := GameClock.new()
	clock.advance(9.0)
	clock.reset()
	assert_almost_eq(clock.elapsed_seconds, 0.0)
	assert_eq(clock.whole_seconds(), 0)
	watch_signal(clock, &"second_ticked")
	clock.advance(1.0)
	assert_signal_emitted(clock, &"second_ticked", 1, "ticking restarts from 1 after a reset")


func test_services_autoload_is_registered_and_owns_the_clock() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	assert_eq(services.get_script().resource_path, "res://systems/core/services.gd")
	var clock: GameClock = services.get("clock")
	assert_not_null(clock, "Services constructed its GameClock in _ready")


func test_services_is_the_only_autoload() -> void:
	# One composition root, by design. If a round adds a second autoload, this
	# test is where the argument has to be won.
	var names := PackedStringArray()
	for child: Node in tree().root.get_children():
		if child == tree().current_scene:
			continue
		names.append(child.name)
	assert_has(names, "Services")
	assert_eq(names.size(), 1, "exactly one autoload; got %s" % str(names))


func test_the_composition_root_feeds_its_delta_straight_to_the_clock() -> void:
	# `Services._process` does no arithmetic on the delta: whatever the engine hands
	# it - already scaled by `Engine.time_scale` - is what in-game time advances by.
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var clock: GameClock = services.get("clock")
	if not assert_not_null(clock, "Services constructed its GameClock in _ready"):
		return
	var before := clock.elapsed_seconds
	services.call("_process", 0.5)
	assert_almost_eq(
		clock.elapsed_seconds - before, 0.5, 0.0001, "the process delta reaches the clock intact"
	)


func test_the_autoload_forwards_the_scaled_process_delta_to_the_clock() -> void:
	# The ruling: the clock is world time. Slow-motion (the Fool's Chance) slows the
	# world, schedules included, because `Services._process` hands the engine's
	# already-scaled delta straight to the clock. Godot's own scaling of `delta` by
	# `Engine.time_scale` is the engine's contract, not ours; measuring it against the
	# wall clock in a headless run proved flaky (frame pacing is nobody's promise), so
	# this test pins the part that is ours: the forwarding, with an exact delta.
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var clock: GameClock = services.get("clock")
	if not assert_not_null(clock, "Services constructed its GameClock in _ready"):
		return
	var before := clock.elapsed_seconds
	services.call("_process", 0.25)
	assert_almost_eq(clock.elapsed_seconds - before, 0.25, 0.000001, "one process call adds exactly its delta")
	clock.paused = true
	services.call("_process", 0.25)
	assert_almost_eq(clock.elapsed_seconds - before, 0.25, 0.000001, "a paused clock ignores the delta")
	clock.paused = false
	assert_true(clock.elapsed_seconds > 0.0, "the autoload is advancing the clock every frame")
