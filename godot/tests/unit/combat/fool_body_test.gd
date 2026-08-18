extends TarrockTest

## The seam between the combat component and the body it drives: the Fool's own time,
## and the sprint latch.
##
## Both are `scripts/player.gd`'s half of `docs/design/combat.md`:
##
##   * §Defense - during Fool's Chance "the Fool moves at normal speed relative to a
##     slowed world". Compensating the MOVESET alone is not that: the dodge would cover
##     its distance at full speed and the walk out of it would crawl. The body scales
##     its own delta by the same factor, through `set_time_compensation()`.
##   * §Accessibility - "hold/toggle options for held inputs (block-step, charged
##     heavy, sprint)". Sprint is read by the body, so its `HoldOrToggle` lives there,
##     and `FoolCombat.set_hold_mode()` is still the one door a settings screen knocks
##     on for all four.
##
## The Focus stance, the service injection and the rest of the component's own
## behaviour are `fool_combat_test.gd`'s; this file is the body's half of the seam.
##
## This suite needs the real Fool scene (the body's animator wants its `Sprite`), so it
## instantiates `scenes/fool.tscn` and frees it again. It drives `move()` by hand with
## explicit deltas rather than waiting for physics frames - the arithmetic is the point,
## and a test that waited on frames would be a test of the engine's frame pacing.

const FOOL_SCENE_PATH := "res://scenes/fool.tscn"

## The delta every hand-driven step uses. Long enough that a pixel of rounding cannot
## decide anything.
const STEP := 0.1

## The delta the animator steps are measured over: long enough at `FoolBody.WALK_FPS`
## for the cycle to have moved several frames, so halving it is visible.
const ANIMATOR_STEP := 0.25

var _fool: FoolBody = null
var _combat: FoolCombat = null


func before_each() -> void:
	var packed: PackedScene = load(FOOL_SCENE_PATH) as PackedScene
	_fool = packed.instantiate() as FoolBody
	tree().root.add_child(_fool)
	_combat = _fool.get_node_or_null("FoolCombat") as FoolCombat


func after_each() -> void:
	if _fool != null and is_instance_valid(_fool):
		_fool.get_parent().remove_child(_fool)
		_fool.free()
	_fool = null
	_combat = null


# --- The Fool's own time --------------------------------------------------------


func test_a_body_runs_on_the_world_s_time_by_default() -> void:
	assert_almost_eq(_fool.time_compensation(), 1.0, 0.0001, "no compensation until asked for")


func test_compensation_scales_the_distance_one_frame_walks() -> void:
	# The engine has already scaled this frame's delta by Engine.time_scale before the
	# body ever sees it. A compensation of 1/time_scale is what puts the walk back at
	# full speed, and this is that arithmetic with the numbers made explicit: half the
	# delta, twice the compensation, the same ground covered.
	var plain := _walked(Vector2.RIGHT, STEP, 1.0)
	var slowed := _walked(Vector2.RIGHT, STEP * 0.5, 1.0)
	assert_almost_eq(slowed, plain * 0.5, 0.5, "half a frame walks half as far, uncompensated")
	var compensated := _walked(Vector2.RIGHT, STEP * 0.5, 2.0)
	assert_almost_eq(
		compensated,
		plain,
		0.5,
		"and a compensated one covers the same ground as a full frame of normal time"
	)


func test_compensation_advances_the_animator_too() -> void:
	# A Fool who walked at normal speed with a walk cycle still playing at 0.3x would
	# moonwalk through the slow motion. The animator gets the same seconds the movement
	# does, which is why both go through one multiplication in `move()`.
	#
	# South-east because it is the one facing whose walk cycle has been drawn; every
	# other one resolves to a static frame that no delta can advance.
	var animator := _fool.animator()
	if not assert_not_null(animator):
		return
	var walk_dir := Vector2(1.0, 1.0)
	_reset_animator()
	_fool.set_time_compensation(1.0)
	_fool.move(walk_dir, ANIMATOR_STEP)
	var plain_frame := animator.current_frame()
	assert_true(plain_frame > 0, "a quarter second of walking is several frames of the cycle")
	_reset_animator()
	_fool.set_time_compensation(1.0)
	_fool.move(walk_dir, ANIMATOR_STEP * 0.5)
	assert_true(
		animator.current_frame() < plain_frame, "half the delta is fewer frames, uncompensated"
	)
	_reset_animator()
	_fool.set_time_compensation(2.0)
	_fool.move(walk_dir, ANIMATOR_STEP * 0.5)
	assert_eq(
		animator.current_frame(),
		plain_frame,
		"and half a frame at twice the compensation is the same frame of the cycle"
	)


func test_compensation_refuses_to_freeze_the_fool() -> void:
	_fool.set_time_compensation(0.0)
	assert_true(_fool.time_compensation() > 0.0, "a compensation of nothing is nobody's intent")
	_fool.set_time_compensation(-4.0)
	assert_true(_fool.time_compensation() > 0.0, "and neither is walking backwards through time")


func test_the_combat_component_drives_the_compensation() -> void:
	# The wiring the body cannot prove on its own: FoolCombat is what sets it, and it
	# is 1.0 whenever there is no Fool's Chance to compensate for. One frame of the
	# component is driven by hand (`_physics_process` called directly) rather than by
	# waiting for the engine, for the same reason every other timing test here does it:
	# a unit test that waited on frame pacing would be testing the engine.
	if not assert_not_null(_combat):
		return
	_fool.set_time_compensation(4.0)
	_combat._physics_process(STEP)
	assert_almost_eq(
		_fool.time_compensation(), 1.0, 0.0001, "no slow motion, no compensation"
	)


# --- Sprint's hold/toggle -------------------------------------------------------


func test_sprint_can_be_put_on_toggle_through_the_combat_component() -> void:
	if not assert_not_null(_combat):
		return
	assert_eq(_fool.sprint_hold_mode(), HoldOrToggle.Mode.HOLD, "hold is the default")
	_combat.set_hold_mode(InputActions.SPRINT, HoldOrToggle.Mode.TOGGLE)
	assert_eq(
		_fool.sprint_hold_mode(),
		HoldOrToggle.Mode.TOGGLE,
		"combat.md §Accessibility lists sprint among the held inputs that need the choice"
	)
	assert_eq(
		_combat.hold_mode(InputActions.SPRINT),
		HoldOrToggle.Mode.TOGGLE,
		"and the component answers for it rather than for Focus"
	)
	_combat.set_hold_mode(InputActions.SPRINT, HoldOrToggle.Mode.HOLD)
	assert_eq(_fool.sprint_hold_mode(), HoldOrToggle.Mode.HOLD, "and back again")


func test_the_other_held_inputs_are_untouched_by_the_sprint_setting() -> void:
	if not assert_not_null(_combat):
		return
	_combat.set_hold_mode(InputActions.SPRINT, HoldOrToggle.Mode.TOGGLE)
	assert_eq(_combat.hold_mode(InputActions.FOCUS), HoldOrToggle.Mode.HOLD)
	assert_eq(_combat.hold_mode(InputActions.BLOCK_STEP), HoldOrToggle.Mode.HOLD)
	assert_eq(_combat.hold_mode(InputActions.ATTACK_HEAVY), HoldOrToggle.Mode.HOLD)


# --- Helpers ---------------------------------------------------------------------


## How far one hand-driven frame walks the Fool, at a given delta and compensation.
func _walked(direction: Vector2, delta: float, compensation: float) -> float:
	_fool.global_position = Vector2.ZERO
	_fool.set_time_compensation(compensation)
	_fool.move(direction, delta)
	return _fool.global_position.length()


## Put the walk cycle back to its first frame, so two runs are compared from the same
## place.
func _reset_animator() -> void:
	var animator := _fool.animator()
	if animator == null:
		return
	animator.set_state(_fool.facing_name(), "idle")
	animator.set_state(_fool.facing_name(), "walk")
