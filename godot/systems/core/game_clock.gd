class_name GameClock
extends RefCounted

## Elapsed in-game time, in seconds, advanced by whoever owns it.
##
## The first real service, and the pattern every later one follows: a plain
## `RefCounted` with no tree, no `get_node`, no autoload lookups, constructed and
## driven by the composition root (`res://systems/core/services.gd`) and
## constructible bare in a test. It reports through a typed signal rather than
## letting anything poll it.
##
## Time does not pass while `paused` is true - menus, dialogue, and the Pocket
## Spread all stop the clock, so "in-game seconds" means seconds of play.
##
## THIS IS WORLD TIME, AND IT IS SCALED BY `Engine.time_scale` ON PURPOSE. The
## composition root feeds it the process delta, which the engine has already scaled,
## so a slow-motion effect (the Fool's Chance) slows the world it happens in:
## schedules, timed doors and anything else driven off `second_ticked` stretch with
## it, exactly as the player sees the world stretch. It is therefore NOT a stopwatch
## for real seconds played - a system that needs true wall-clock time (a play-time
## counter, a benchmark) must read `Time.get_ticks_usec()` itself and not this clock.

## Fired once per whole in-game second crossed, with the new total.
signal second_ticked(total: int)

## In-game seconds elapsed, fractional.
var elapsed_seconds: float = 0.0

## While true, `advance` does nothing.
var paused: bool = false

var _last_whole_second: int = 0


## Advance the clock by `delta` seconds of world time. The caller decides what a
## second means: `Services` passes the engine's process delta, so `Engine.time_scale`
## has already been applied by the time it arrives here (see the class doc). Negative
## deltas are ignored: time in Tarrock only ever goes forward, same rule as a `WS_*`
## flag.
func advance(delta: float) -> void:
	if paused or delta <= 0.0:
		return
	elapsed_seconds += delta
	var whole := int(elapsed_seconds)
	while _last_whole_second < whole:
		_last_whole_second += 1
		second_ticked.emit(_last_whole_second)


## Whole in-game seconds elapsed.
func whole_seconds() -> int:
	return _last_whole_second


## Back to zero. Used when a save is loaded, never during play.
func reset() -> void:
	elapsed_seconds = 0.0
	_last_whole_second = 0
