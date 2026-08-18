extends TarrockTest

## Focus's lock-on: who it picks, and why it always picks the same one.
##
## `docs/design/combat.md` §Focus: holding the stance "locks onto a target when
## enemies are present". §Philosophy adds that lock-on is "available but optional",
## which is why nothing here ever acquires on its own.
##
## The property worth a test more than any single choice is DETERMINISM: the same
## candidates from the same place must give the same target every time, or a player
## cannot learn what the button does.

## Far enough that the cone weighting decides, near enough that everything is in range.
const RANGE := 500.0
const CONE_WEIGHT := 1.0

var _targeting: FocusTargeting = null
var _nodes: Array[Node2D] = []


func before_each() -> void:
	_targeting = FocusTargeting.new(RANGE, CONE_WEIGHT)
	_nodes = []


func after_each() -> void:
	for node: Node2D in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes = []


func test_nothing_is_locked_until_something_is_acquired() -> void:
	assert_null(_targeting.target())
	assert_false(_targeting.has_target())
	assert_eq(_targeting.candidate_count(), 0)


func test_focus_locks_the_nearest_candidate() -> void:
	var far := _candidate(Vector2(300, 0))
	var near := _candidate(Vector2(100, 0))
	_targeting.set_candidates(_list([far, near]))
	watch_signal(_targeting, &"target_acquired")
	assert_eq(_targeting.acquire(Vector2.ZERO, Vector2.RIGHT), near)
	assert_signal_emitted(_targeting, &"target_acquired", 1)


func test_focus_prefers_what_the_fool_is_already_facing() -> void:
	# 150 straight ahead beats 120 behind: the cone discount is what stops the lock
	# snapping to something the Fool has their back to.
	var ahead := _candidate(Vector2(150, 0))
	var behind := _candidate(Vector2(-120, 0))
	_targeting.set_candidates(_list([behind, ahead]))
	assert_eq(_targeting.acquire(Vector2.ZERO, Vector2.RIGHT), ahead)


func test_a_candidate_out_of_range_cannot_be_locked() -> void:
	var distant := _candidate(Vector2(RANGE + 10.0, 0))
	_targeting.set_candidates(_list([distant]))
	assert_null(_targeting.acquire(Vector2.ZERO, Vector2.RIGHT))
	assert_false(_targeting.has_target())


func test_acquiring_is_deterministic() -> void:
	var first := _candidate(Vector2(200, 0))
	var second := _candidate(Vector2(200, 0))
	_targeting.set_candidates(_list([first, second]))
	for _index: int in 5:
		_targeting.release()
		assert_eq(
			_targeting.acquire(Vector2.ZERO, Vector2.RIGHT),
			first,
			"an exact tie goes to the order the caller supplied, every single time"
		)


func test_cycling_walks_the_candidates_and_comes_back() -> void:
	var near := _candidate(Vector2(100, 0))
	var far := _candidate(Vector2(300, 0))
	_targeting.set_candidates(_list([near, far]))
	assert_eq(_targeting.acquire(Vector2.ZERO, Vector2.RIGHT), near)
	assert_eq(_targeting.cycle(Vector2.ZERO, Vector2.RIGHT), far)
	assert_eq(_targeting.cycle(Vector2.ZERO, Vector2.RIGHT), near, "and round again")


func test_cycling_with_one_candidate_stays_put() -> void:
	var only := _candidate(Vector2(100, 0))
	_targeting.set_candidates(_list([only]))
	_targeting.acquire(Vector2.ZERO, Vector2.RIGHT)
	assert_eq(_targeting.cycle(Vector2.ZERO, Vector2.RIGHT), only, "there is nowhere else to go")


func test_releasing_announces_itself_once() -> void:
	var only := _candidate(Vector2(100, 0))
	_targeting.set_candidates(_list([only]))
	_targeting.acquire(Vector2.ZERO, Vector2.RIGHT)
	watch_signal(_targeting, &"target_released")
	_targeting.release()
	_targeting.release()
	assert_signal_emitted(_targeting, &"target_released", 1, "releasing nothing is not an event")
	assert_false(_targeting.has_target())


func test_a_target_dropped_from_the_candidates_is_released() -> void:
	var only := _candidate(Vector2(100, 0))
	_targeting.set_candidates(_list([only]))
	_targeting.acquire(Vector2.ZERO, Vector2.RIGHT)
	_targeting.set_candidates(_list([]))
	assert_false(_targeting.has_target(), "an enemy that left the fight cannot stay locked")


func test_the_direction_to_the_target_is_what_the_moveset_is_told() -> void:
	var above := _candidate(Vector2(0, -200))
	_targeting.set_candidates(_list([above]))
	_targeting.acquire(Vector2.ZERO, Vector2.RIGHT)
	var direction := _targeting.direction_to_target(Vector2.ZERO)
	assert_almost_eq(direction.x, 0.0, 0.001)
	assert_almost_eq(direction.y, -1.0, 0.001)
	_targeting.release()
	assert_eq(_targeting.direction_to_target(Vector2.ZERO), Vector2.ZERO)


func test_a_freed_candidate_never_crashes_the_lock() -> void:
	var doomed := _candidate(Vector2(100, 0))
	_targeting.set_candidates(_list([doomed]))
	_targeting.acquire(Vector2.ZERO, Vector2.RIGHT)
	_nodes.erase(doomed)
	doomed.free()
	assert_null(_targeting.target(), "a target that stopped existing reads as no target")
	assert_eq(_targeting.direction_to_target(Vector2.ZERO), Vector2.ZERO)


## An `Array[Node2D]` from a plain literal: `set_candidates` is typed, and GDScript
## does not widen an untyped array into a typed one at a call boundary.
func _list(values: Array) -> Array[Node2D]:
	var typed: Array[Node2D] = []
	for value: Variant in values:
		typed.append(value as Node2D)
	return typed


## A candidate at a position, tracked for freeing.
func _candidate(position: Vector2) -> Node2D:
	var node := Node2D.new()
	node.position = position
	_nodes.append(node)
	return node
