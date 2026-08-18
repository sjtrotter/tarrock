extends TarrockTest

## The command wheel as a gesture: hold, aim, release.
##
## `docs/design/combat.md` §Pip gives Pip "a radial command wheel" and stops there, so
## the gesture is the round's decision and this file is where it is pinned:
##
##   * hold `pip_wheel` and the wheel opens;
##   * the move vector lights a sector - FETCH up-left, HARRY up-right, SEEK down;
##   * release confirms the lit sector;
##   * a release with the stick centred repeats the last command used.
##
## Nothing here touches `Input`, the tree or a clock: `PipWheel` is handed booleans and
## vectors, which is exactly what `PipCompanion` hands it every physics frame.

const RULES_PATH := "res://data/pip/pip_rules.tres"

## One physics frame at 60 Hz.
const FRAME := 1.0 / 60.0

var _rules: PipRules = null


func before_each() -> void:
	_rules = load(RULES_PATH) as PipRules


# --- The three sectors ----------------------------------------------------------


func test_the_sectors_are_the_documented_three() -> void:
	var wheel := _wheel()
	assert_eq(wheel.sector_for(Vector2(-1, -1)), PipCommand.Id.FETCH, "up-left is Fetch")
	assert_eq(wheel.sector_for(Vector2(1, -1)), PipCommand.Id.HARRY, "up-right is Harry")
	assert_eq(wheel.sector_for(Vector2(0, 1)), PipCommand.Id.SEEK, "down is Seek")


func test_the_boundaries_fall_where_the_bisectors_are() -> void:
	# Sectors are decided by "nearest centre", so the boundaries are the three
	# bisectors: straight up (270 degrees in screen space, where +y is down) between
	# Fetch and Harry, and the two shallow down-diagonals between each of them and
	# Seek. A hair either side of a boundary has to answer differently, or the sectors
	# are not really sectors.
	var wheel := _wheel()
	assert_eq(_at(wheel, 157.5 + 5.0), PipCommand.Id.FETCH, "just above the left bisector: Fetch")
	assert_eq(_at(wheel, 157.5 - 5.0), PipCommand.Id.SEEK, "just below it: Seek")
	assert_eq(_at(wheel, 22.5 - 5.0), PipCommand.Id.HARRY, "just above the right bisector: Harry")
	assert_eq(_at(wheel, 22.5 + 5.0), PipCommand.Id.SEEK, "just below it: Seek")
	assert_eq(_at(wheel, 270.0 - 5.0), PipCommand.Id.FETCH, "just left of straight up: Fetch")
	assert_eq(_at(wheel, 270.0 + 5.0), PipCommand.Id.HARRY, "just right of it: Harry")


## The sector a full-strength aim at `degrees` (screen space, +y down) lights.
func _at(wheel: PipWheel, degrees: float) -> int:
	return wheel.sector_for(Vector2.RIGHT.rotated(deg_to_rad(degrees)))


func test_straight_up_is_deterministic() -> void:
	# Fetch and Harry are equidistant from straight up. A wheel that answered whichever
	# way the iteration happened to run would be a wheel the player cannot learn, so the
	# tie is settled once, in favour of the first command in the doc's table.
	var wheel := _wheel()
	assert_eq(wheel.sector_for(Vector2(0, -1)), PipCommand.Id.FETCH)
	assert_eq(wheel.sector_for(Vector2(0, -1)), PipCommand.Id.FETCH, "and answers the same twice")


func test_the_dead_zone_lights_nothing() -> void:
	var wheel := _wheel()
	var inside := _rules.wheel_dead_zone * 0.5
	assert_eq(wheel.sector_for(Vector2(0, inside)), PipCommand.NONE, "a resting stick aims nothing")
	assert_eq(wheel.sector_for(Vector2.ZERO), PipCommand.NONE)
	assert_ne(
		wheel.sector_for(Vector2(0, _rules.wheel_dead_zone + 0.01)),
		PipCommand.NONE,
		"and just outside it, a sector lights"
	)


func test_the_dead_zone_is_clamped_to_the_rules_bounds() -> void:
	var wide := PipWheel.new(9.0)
	assert_almost_eq(wide.dead_zone(), PipRules.MAX_WHEEL_DEAD_ZONE, 0.0001)
	var narrow := PipWheel.new(-1.0)
	assert_almost_eq(narrow.dead_zone(), PipRules.MIN_WHEEL_DEAD_ZONE, 0.0001)


# --- The gesture ------------------------------------------------------------------


func test_holding_opens_the_wheel_and_confirms_nothing() -> void:
	var wheel := _wheel()
	assert_false(wheel.is_open(), "a wheel starts shut")
	for _frame: int in 10:
		assert_eq(wheel.update(true, Vector2(0, 1), FRAME), PipCommand.NONE, "holding confirms nothing")
	assert_true(wheel.is_open(), "but it is open")
	assert_eq(wheel.highlighted(), PipCommand.Id.SEEK, "with the aimed sector lit")
	assert_almost_eq(wheel.held_seconds(), FRAME * 10.0, 0.0001, "and a hold time for the UI")


func test_release_confirms_the_lit_sector() -> void:
	var wheel := _wheel()
	wheel.update(true, Vector2(1, -1), FRAME)
	assert_eq(wheel.update(false, Vector2(1, -1), FRAME), PipCommand.Id.HARRY, "the release commits")
	assert_false(wheel.is_open(), "and shuts the wheel")
	assert_eq(wheel.highlighted(), PipCommand.NONE)
	assert_almost_eq(wheel.held_seconds(), 0.0, 0.0001)


func test_the_last_aim_before_the_release_is_the_one_that_counts() -> void:
	var wheel := _wheel()
	wheel.update(true, Vector2(1, -1), FRAME)
	wheel.update(true, Vector2(-1, -1), FRAME)
	assert_eq(
		wheel.update(false, Vector2(-1, -1), FRAME),
		PipCommand.Id.FETCH,
		"a player who changes their mind mid-hold gets the sector they ended on"
	)


func test_a_tap_with_no_direction_repeats_the_last_command() -> void:
	var wheel := _wheel()
	wheel.update(true, Vector2(0, 1), FRAME)
	assert_eq(wheel.update(false, Vector2(0, 1), FRAME), PipCommand.Id.SEEK)
	# Now the tap: held and released with the stick at rest.
	wheel.update(true, Vector2.ZERO, FRAME)
	assert_eq(wheel.update(false, Vector2.ZERO, FRAME), PipCommand.Id.SEEK, "the tap repeats Seek")
	assert_eq(wheel.last_used(), PipCommand.Id.SEEK)


func test_a_tap_before_anything_was_ever_used_confirms_nothing() -> void:
	var wheel := _wheel()
	wheel.update(true, Vector2.ZERO, FRAME)
	assert_eq(
		wheel.update(false, Vector2.ZERO, FRAME),
		PipCommand.NONE,
		"an empty wheel does not guess a command for the player"
	)
	assert_eq(wheel.last_used(), PipCommand.NONE)


func test_a_release_with_the_wheel_shut_confirms_nothing() -> void:
	var wheel := _wheel()
	assert_eq(wheel.update(false, Vector2(0, 1), FRAME), PipCommand.NONE, "no hold, no command")


func test_cancel_drops_a_gesture_half_made() -> void:
	var wheel := _wheel()
	wheel.update(true, Vector2(0, 1), FRAME)
	wheel.cancel()
	assert_false(wheel.is_open())
	assert_eq(
		wheel.update(false, Vector2(0, 1), FRAME),
		PipCommand.NONE,
		"a cancelled wheel confirms nothing when the button comes up"
	)


func test_reopening_restarts_the_hold_clock() -> void:
	var wheel := _wheel()
	for _frame: int in 5:
		wheel.update(true, Vector2(0, 1), FRAME)
	wheel.update(false, Vector2(0, 1), FRAME)
	wheel.update(true, Vector2(0, 1), FRAME)
	assert_almost_eq(wheel.held_seconds(), FRAME, 0.0001, "the second hold starts from zero")


# --- What the UI round will read ---------------------------------------------------


func test_the_view_reports_the_wheel_and_the_availability() -> void:
	var wheel := _wheel()
	var service := PipService.new(_rules)
	var view := PipWheelView.new()
	wheel.update(true, Vector2(-1, -1), FRAME)
	view.refresh(wheel, service)
	assert_true(view.is_open(), "the wheel is up")
	assert_eq(view.highlighted(), PipCommand.Id.FETCH, "with Fetch lit")
	for command: int in PipCommand.ALL:
		assert_true(view.is_available(command), "and every command available at Pip's heel")
	service.on_pip_health_zero(Vector2.ZERO)
	view.refresh(wheel, service)
	for command: int in PipCommand.ALL:
		assert_false(view.is_available(command), "nothing reaches a Pip who is shaking it off")
	assert_false(view.is_available(PipCommand.NONE), "and nothing is available that is not a command")


func _wheel() -> PipWheel:
	if _rules == null:
		fail("the Pip rules did not load")
		return PipWheel.new(PipRules.MIN_WHEEL_DEAD_ZONE)
	return PipWheel.new(_rules.wheel_dead_zone)
