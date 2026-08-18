extends TarrockTest

## The Bindle, frame by explicit frame.
##
## `docs/design/combat.md` §The Bindle, §Focus and §Defense are the canon under test:
## a three-hit light string that chains only inside its window, a heavy, a charged
## heavy that is the stagger launcher, a running attack that needs a run, the four
## directional dodges Focus turns one button into, and a hop-guard with no
## counter-window.
##
## **Every delta in this file is fed by hand.** Nothing here reads a clock, waits a
## frame, or looks at `Engine.time_scale`; a state machine tested against the wall
## clock is a test that fails on a busy machine and passes on a quiet one. The
## controller is pure precisely so this can be arithmetic.
##
## The timings themselves are `CombatRules`', read out of the resource rather than
## retyped, so retuning a number in the `.tres` retunes the test with it - the
## assertions are about the SHAPE (windup, then active, then recovery, of exactly the
## authored lengths), which is the part `combat.md` fixes.

const RULES_PATH := "res://data/combat/combat_rules.tres"

## A frame short enough to land inside any phase in the table.
const TINY := 0.01

var _rules: CombatRules = null
var _controller: MovesetController = null
var _blank: CombatInput = null


func before_each() -> void:
	_rules = (load(RULES_PATH) as CombatRules).duplicate() as CombatRules
	_controller = MovesetController.new(_rules)
	_blank = CombatInput.new()


# --- The light string --------------------------------------------------------


func test_the_light_string_is_three_hits_with_the_authored_timings() -> void:
	_press_light()
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "the first press opens the string")
	assert_eq(_controller.combo_index(), 1)
	for index: int in CombatRules.LIGHT_STRING_HITS:
		var state: MovesetController.State = _controller.state()
		assert_eq(_controller.phase(), MovesetController.Phase.WINDUP, "hit %d telegraphs" % (index + 1))
		_advance(_rules.light_windup(index))
		assert_eq(_controller.phase(), MovesetController.Phase.ACTIVE, "hit %d swings" % (index + 1))
		assert_eq(_controller.state(), state, "and it is still the same hit")
		var spec := _controller.active_hit()
		if assert_not_null(spec, "an active light hit has a spec"):
			assert_eq(spec.damage, _rules.light_damage_at(index), "with the authored damage")
			assert_eq(spec.kind, HitSpec.Kind.LIGHT)
		_advance(_rules.light_active(index))
		assert_eq(_controller.phase(), MovesetController.Phase.RECOVERY, "hit %d recovers" % (index + 1))
		assert_null(_controller.active_hit(), "and the window is shut")
		if index < CombatRules.LIGHT_STRING_HITS - 1:
			_press_light()
			assert_eq(_controller.combo_index(), index + 2, "the string chains to the next hit")
	_advance(_rules.light_recovery(CombatRules.LIGHT_STRING_HITS - 1))
	assert_eq(_controller.state(), MovesetController.State.IDLE, "and the string ends standing")


func test_a_fourth_light_press_starts_a_new_string() -> void:
	_run_whole_light_string()
	_press_light()
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "no fourth hit exists")
	assert_eq(_controller.combo_index(), 1, "the string starts over")


func test_the_string_resets_once_the_combo_window_has_passed() -> void:
	_press_light()
	_advance(_rules.light_windup(0) + _rules.light_active(0) + _rules.light_recovery(0))
	assert_eq(_controller.state(), MovesetController.State.IDLE)
	_advance(_rules.light_combo_window_seconds)
	assert_eq(_controller.combo_index(), MovesetController.NO_COMBO, "the window closed")
	_press_light()
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "so the next press is hit one again")


func test_the_string_survives_the_gap_between_recovery_and_the_next_press() -> void:
	# The window is armed when the hit STARTS and counts down through the whole of it,
	# so a press just after a short recovery ends still continues the string.
	_press_light()
	_advance(_rules.light_windup(0) + _rules.light_active(0) + _rules.light_recovery(0))
	assert_eq(_controller.state(), MovesetController.State.IDLE)
	_press_light()
	assert_eq(_controller.state(), MovesetController.State.LIGHT_2, "the string continued")


func test_a_light_press_during_a_windup_is_ignored() -> void:
	_press_light()
	_advance(_rules.light_windup(0) * 0.5)
	_press_light()
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "mashing does not re-open hit one")
	assert_eq(_controller.combo_index(), 1)


# --- The heavy and the launcher ----------------------------------------------


func test_the_heavy_sweeps_wide() -> void:
	_press_heavy_and_release()
	assert_eq(_controller.state(), MovesetController.State.HEAVY, "a tap is the plain heavy")
	_advance(_rules.heavy_windup_seconds)
	var spec := _controller.active_hit()
	if not assert_not_null(spec):
		return
	assert_eq(spec.kind, HitSpec.Kind.HEAVY)
	assert_eq(spec.damage, _rules.heavy_damage)
	assert_almost_eq(spec.arc_degrees, _rules.heavy_arc_degrees)
	assert_true(spec.arc_degrees > _rules.light_arc_degrees, "combat.md: the heavy is the crowd answer")
	assert_false(spec.applies_stagger, "only the CHARGED heavy is the launcher")


func test_holding_the_heavy_charges_it_into_the_stagger_launcher() -> void:
	watch_signal(_controller, &"charge_started")
	watch_signal(_controller, &"charge_released")
	var held := CombatInput.new()
	held.heavy_pressed = true
	held.heavy_held = true
	_controller.update(held, TINY)
	assert_eq(_controller.state(), MovesetController.State.CHARGING)
	assert_signal_emitted(_controller, &"charge_started", 1)
	held.heavy_pressed = false
	_controller.update(held, _rules.charge_seconds)
	assert_true(_controller.is_fully_charged(), "the charge is full")
	var release := CombatInput.new()
	release.heavy_released = true
	_controller.update(release, TINY)
	assert_eq(_controller.state(), MovesetController.State.CHARGED_HEAVY)
	assert_eq(signal_arguments(_controller, &"charge_released", 0), [true])
	_advance(_rules.charged_heavy_windup_seconds)
	var spec := _controller.active_hit()
	if not assert_not_null(spec):
		return
	assert_eq(spec.kind, HitSpec.Kind.CHARGED_HEAVY)
	assert_true(spec.applies_stagger, "combat.md: the release is the stagger launcher")
	assert_almost_eq(spec.stagger_seconds, _rules.stagger_seconds)
	assert_almost_eq(spec.bonus_vs_staggered, _rules.stagger_bonus_multiplier)


func test_releasing_the_heavy_early_is_a_plain_heavy() -> void:
	watch_signal(_controller, &"charge_released")
	var held := CombatInput.new()
	held.heavy_pressed = true
	held.heavy_held = true
	_controller.update(held, TINY)
	held.heavy_pressed = false
	_controller.update(held, _rules.charge_seconds * 0.5)
	assert_false(_controller.is_fully_charged())
	var release := CombatInput.new()
	release.heavy_released = true
	_controller.update(release, TINY)
	assert_eq(_controller.state(), MovesetController.State.HEAVY, "half a charge is not the launcher")
	assert_eq(signal_arguments(_controller, &"charge_released", 0), [false])


# --- The running attack ------------------------------------------------------


func test_the_running_attack_needs_a_run() -> void:
	var walking := CombatInput.new()
	walking.light_pressed = true
	walking.run_speed_fraction = _rules.running_attack_min_speed_fraction - 0.05
	_controller.update(walking, TINY)
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "walking gives the light string")


func test_attacking_out_of_a_run_is_the_lunge() -> void:
	var running := CombatInput.new()
	running.light_pressed = true
	running.run_speed_fraction = 1.0
	_controller.update(running, TINY)
	assert_eq(_controller.state(), MovesetController.State.RUNNING_ATTACK)
	_advance(_rules.running_attack_windup_seconds)
	var spec := _controller.active_hit()
	if not assert_not_null(spec):
		return
	assert_eq(spec.shape, HitSpec.Shape.BOX, "a lunge is a line, not a sweep")
	assert_eq(spec.kind, HitSpec.Kind.RUNNING_ATTACK)


func test_the_lunge_carries_the_fool_its_authored_distance() -> void:
	var running := CombatInput.new()
	running.light_pressed = true
	running.run_speed_fraction = 1.0
	_controller.set_facing(Vector2.RIGHT)
	_controller.update(running, TINY)
	var travelled := _controller.frame_displacement()
	for _index: int in 200:
		_controller.update(_blank, TINY)
		travelled += _controller.frame_displacement()
	assert_almost_eq(
		travelled.length(), _rules.running_attack_lunge_distance, 1.0, "the lunge closes its distance"
	)


# --- Dodges ------------------------------------------------------------------


func test_the_iframe_window_is_exactly_the_authored_one() -> void:
	_press_dodge(Vector2.ZERO, false)
	assert_false(_controller.is_invulnerable(), "a dodge starts vulnerable")
	_advance(_rules.dodge_iframe_start_seconds)
	assert_true(_controller.is_invulnerable(), "i-frames open at iframe_start")
	_advance((_rules.dodge_iframe_end_seconds - _rules.dodge_iframe_start_seconds) - 0.001)
	assert_true(_controller.is_invulnerable(), "and stay up right up to iframe_end")
	_advance(0.002)
	assert_false(_controller.is_invulnerable(), "the window is half-open: [start, end)")


func test_a_dodge_carries_the_fool_its_authored_distance() -> void:
	_controller.set_facing(Vector2.RIGHT)
	_press_dodge(Vector2.RIGHT, false)
	var travelled := _controller.frame_displacement()
	for _index: int in 200:
		_controller.update(_blank, TINY)
		travelled += _controller.frame_displacement()
	assert_almost_eq(travelled.length(), _rules.dodge_roll_distance, 1.0)
	assert_true(travelled.x > 0.0, "and it goes where it was aimed")


func test_out_of_focus_every_direction_is_the_plain_roll() -> void:
	for direction: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		_controller.reset()
		_controller.set_facing(Vector2.RIGHT)
		_press_dodge(direction, false)
		assert_eq(
			_controller.state(),
			MovesetController.State.DODGE_ROLL,
			"combat.md: out of Focus the dodge is a travel roll and nothing more"
		)


func test_in_focus_the_dodge_is_directional() -> void:
	_controller.set_facing(Vector2.RIGHT)
	var expected := {
		"forward": [Vector2.RIGHT, MovesetController.State.DODGE_ROLL],
		"neutral": [Vector2.ZERO, MovesetController.State.DODGE_ROLL],
		"left": [Vector2.UP, MovesetController.State.SIDE_HOP],
		"right": [Vector2.DOWN, MovesetController.State.SIDE_HOP],
		"back": [Vector2.LEFT, MovesetController.State.BACKFLIP],
	}
	for label: String in expected:
		var row: Array = expected[label]
		_controller.reset()
		_controller.set_facing(Vector2.RIGHT)
		_press_dodge(row[0], true)
		assert_eq(_controller.state(), row[1], "the %s dodge in Focus" % label)


func test_the_backflip_carries_the_fool_one_and_a_half_body_widths() -> void:
	_controller.set_facing(Vector2.RIGHT)
	_press_dodge(Vector2.LEFT, true)
	assert_eq(_controller.state(), MovesetController.State.BACKFLIP)
	var travelled := _controller.frame_displacement()
	for _index: int in 200:
		_controller.update(_blank, TINY)
		travelled += _controller.frame_displacement()
	assert_almost_eq(
		travelled.length(),
		_rules.body_width * CombatRules.BACKFLIP_BODY_WIDTHS,
		1.0,
		"combat.md: roughly 1.5 body-widths back"
	)


func test_every_dodge_shares_the_rolls_iframes() -> void:
	for pair: Array in [
		[Vector2.UP, MovesetController.State.SIDE_HOP],
		[Vector2.LEFT, MovesetController.State.BACKFLIP],
	]:
		_controller.reset()
		_controller.set_facing(Vector2.RIGHT)
		_press_dodge(pair[0], true)
		assert_eq(_controller.state(), pair[1])
		_advance(_rules.dodge_iframe_start_seconds)
		assert_true(_controller.is_invulnerable(), "combat.md: all of them share the roll's rules")


func test_the_perfect_window_is_measured_from_the_moment_iframes_open() -> void:
	# The window has to be usable for its whole authored length. Measured from the
	# dodge's first frame it would spend `dodge_iframe_start_seconds` of itself on
	# frames where the Fool is not invulnerable at all and the hit simply lands, so a
	# 0.12 s window would be a 0.06 s band - and less on Trial.
	assert_false(_controller.perfect_dodge_started_within(1.0), "no dodge has happened yet")
	_press_dodge(Vector2.ZERO, false)
	_advance(_rules.dodge_iframe_start_seconds)
	assert_true(_controller.is_invulnerable(), "i-frames are open, so a hit now can be answered")
	assert_true(
		_controller.perfect_dodge_started_within(0.001),
		"and the window starts counting from here, not from the dodge's first frame"
	)
	_advance(0.05)
	assert_true(_controller.perfect_dodge_started_within(0.06), "0.05s of i-frames is inside 0.06s")
	assert_false(_controller.perfect_dodge_started_within(0.04), "and outside 0.04s")


func test_the_whole_authored_window_is_usable_on_every_difficulty() -> void:
	# The band between i-frames opening and the perfect window closing, which is what
	# a player actually has to hit. It must be the authored window, undiminished.
	for multiplier: float in [
		_rules.timing_window_multiplier_story,
		_rules.timing_window_multiplier_journey,
		_rules.timing_window_multiplier_trial,
	]:
		var window := _rules.perfect_window_seconds * multiplier
		_controller.reset()
		_press_dodge(Vector2.ZERO, false)
		_advance(_rules.dodge_iframe_start_seconds + window - 0.001)
		assert_true(
			_controller.perfect_dodge_started_within(window),
			"the last instant of a %.3f s window is still perfect" % window
		)
		_advance(0.002)
		assert_false(_controller.perfect_dodge_started_within(window), "and the one after is not")


# --- Block-step --------------------------------------------------------------


func test_the_block_step_guards_then_commits() -> void:
	_press_block()
	assert_eq(_controller.state(), MovesetController.State.BLOCK_STEP)
	assert_true(_controller.is_blocking(), "the guard is up immediately")
	assert_false(_controller.is_invulnerable(), "combat.md: absorbing is not evading")
	_advance(_rules.block_step_guard_seconds)
	assert_false(_controller.is_blocking(), "and it is not up for the whole hop")
	assert_eq(_controller.state(), MovesetController.State.BLOCK_STEP, "which is the commitment")
	_advance(_rules.block_step_seconds - _rules.block_step_guard_seconds)
	assert_eq(_controller.state(), MovesetController.State.IDLE)


func test_the_guard_absorbs_one_hit_and_no_more() -> void:
	# combat.md §Defense: the hop-guard "absorbs a hit and repositions". One hit. The
	# defence side spends it the moment a hit comes back BLOCKED; the Fool stays
	# committed to the rest of the hop with nothing left to absorb the next swing.
	_press_block()
	assert_true(_controller.is_blocking(), "the guard is up")
	assert_false(_controller.is_guard_spent())
	_controller.consume_guard()
	assert_true(_controller.is_guard_spent())
	assert_false(_controller.is_blocking(), "and it does not eat a second hit")
	assert_eq(
		_controller.state(),
		MovesetController.State.BLOCK_STEP,
		"the commitment is still owed: a spent guard does not free the Fool"
	)


func test_a_spent_guard_is_back_up_for_the_next_block_step() -> void:
	_press_block()
	_controller.consume_guard()
	_advance(_rules.block_step_seconds)
	assert_eq(_controller.state(), MovesetController.State.IDLE)
	_press_block()
	assert_true(_controller.is_blocking(), "a new hop is a new guard")
	assert_false(_controller.is_guard_spent())


func test_a_guard_cannot_be_spent_outside_a_block_step() -> void:
	_controller.consume_guard()
	assert_false(_controller.is_guard_spent(), "nothing to spend while standing")
	_press_block()
	assert_true(_controller.is_blocking(), "so the next hop still guards")


func test_the_block_step_repositions() -> void:
	_controller.set_facing(Vector2.RIGHT)
	_press_block()
	var travelled := _controller.frame_displacement()
	for _index: int in 200:
		_controller.update(_blank, TINY)
		travelled += _controller.frame_displacement()
	assert_almost_eq(travelled.length(), _rules.block_step_reposition_distance, 1.0)
	assert_true(travelled.x < 0.0, "the hop goes backwards, away from what it just ate")


func test_a_heavy_release_out_of_nowhere_swings_nothing() -> void:
	# The phantom heavy: a release whose press this controller never took up (pressed
	# during a recovery, let go once the Fool was free) must not swing. The only route
	# to a heavy is a charge that was really started.
	var release := CombatInput.new()
	release.heavy_released = true
	_controller.update(release, TINY)
	assert_eq(_controller.state(), MovesetController.State.IDLE, "no charge, no swing")
	_advance(_rules.heavy_windup_seconds)
	assert_null(_controller.active_hit(), "and nothing came out a frame later either")


func test_a_press_this_controller_never_saw_cannot_swing_on_its_release() -> void:
	# The path that produced the phantom: the press lands mid-recovery, where nothing
	# is accepted, and the release arrives once the Fool is standing.
	_press_light()
	_advance(_rules.light_windup(0) + _rules.light_active(0))
	assert_eq(_controller.phase(), MovesetController.Phase.RECOVERY)
	var press := CombatInput.new()
	press.heavy_pressed = true
	press.heavy_held = true
	_controller.update(press, TINY)
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "the press is refused")
	_advance(_rules.light_recovery(0))
	assert_eq(_controller.state(), MovesetController.State.IDLE)
	var release := CombatInput.new()
	release.heavy_released = true
	_controller.update(release, TINY)
	assert_eq(_controller.state(), MovesetController.State.IDLE, "and the release swings nothing")


func test_a_one_frame_tap_of_the_heavy_still_owes_its_swing() -> void:
	# What the phantom guard must NOT cost: a tap so short the press and the release
	# land in consecutive frames is still a heavy.
	_press_heavy_and_release()
	assert_eq(_controller.state(), MovesetController.State.HEAVY, "the tap swings")


# --- Commitment --------------------------------------------------------------


func test_an_attack_locks_movement_and_frees_it_in_recovery() -> void:
	assert_almost_eq(_controller.movement_multiplier(), 1.0, 0.0001, "a standing Fool is free")
	_press_light()
	assert_almost_eq(_controller.movement_multiplier(), _rules.attack_movement_multiplier)
	_advance(_rules.light_windup(0))
	assert_almost_eq(_controller.movement_multiplier(), _rules.attack_movement_multiplier)
	_advance(_rules.light_active(0))
	assert_almost_eq(
		_controller.movement_multiplier(),
		_rules.recovery_movement_multiplier,
		0.0001,
		"combat.md asks for recovery the player can feel, not a freeze"
	)


func test_nothing_cancels_out_of_a_recovery() -> void:
	_press_light()
	_advance(_rules.light_windup(0) + _rules.light_active(0))
	assert_eq(_controller.phase(), MovesetController.Phase.RECOVERY)
	_press_dodge(Vector2.RIGHT, false)
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "the dodge is refused mid-recovery")
	_press_block()
	assert_eq(_controller.state(), MovesetController.State.LIGHT_1, "and so is the guard")


func test_charging_slows_but_does_not_stop_the_fool() -> void:
	var held := CombatInput.new()
	held.heavy_pressed = true
	held.heavy_held = true
	_controller.update(held, TINY)
	assert_almost_eq(_controller.movement_multiplier(), _rules.charge_movement_multiplier)


# --- Allocation --------------------------------------------------------------


func test_a_hit_window_hands_back_the_same_spec_every_frame() -> void:
	# The guardrail from technical.md: nothing in the combat loop allocates. If a
	# spec were built per frame these would be different objects.
	_press_light()
	_advance(_rules.light_windup(0))
	var first := _controller.active_hit()
	_advance(TINY)
	var second := _controller.active_hit()
	assert_true(first == second, "the spec is allocated once, in _init")
	assert_true(
		first == _controller.active_hit(), "and asking twice in one frame does not build a third"
	)


func test_the_specs_are_the_same_across_two_swings_of_the_same_move() -> void:
	_press_light()
	_advance(_rules.light_windup(0))
	var first := _controller.active_hit()
	_controller.reset()
	_advance(_rules.light_combo_window_seconds)
	_press_light()
	_advance(_rules.light_windup(0))
	assert_true(first == _controller.active_hit(), "one spec per move, for the whole run")


# --- Facing and Focus --------------------------------------------------------


func test_focus_turns_the_fool_toward_the_target() -> void:
	_controller.set_facing(Vector2.RIGHT)
	assert_eq(_controller.strafe_facing(), Vector2.RIGHT)
	_controller.set_focus_target_dir(Vector2.UP)
	assert_true(_controller.has_focus_target())
	assert_eq(_controller.strafe_facing(), Vector2.UP, "combat.md: the Fool keeps facing the target")
	_controller.clear_focus_target()
	assert_eq(_controller.strafe_facing(), Vector2.RIGHT, "and turns back when the lock goes")


func test_a_long_frame_still_opens_and_shuts_the_hit_window() -> void:
	# A frame longer than a whole swing must not swallow the hit: both signals fire.
	watch_signal(_controller, &"hit_window_opened")
	watch_signal(_controller, &"hit_window_closed")
	_press_light()
	_advance(_rules.light_windup(0) + _rules.light_active(0) + _rules.light_recovery(0))
	assert_signal_emitted(_controller, &"hit_window_opened", 1)
	assert_signal_emitted(_controller, &"hit_window_closed", 1)
	assert_eq(_controller.state(), MovesetController.State.IDLE)


# --- Helpers -----------------------------------------------------------------


## One frame of nothing, `seconds` long.
func _advance(seconds: float) -> void:
	_controller.update(_blank, seconds)


## Press light on a frame of no consequence.
func _press_light() -> void:
	var input := CombatInput.new()
	input.light_pressed = true
	_controller.update(input, TINY)


## Tap the heavy: pressed and released inside one frame.
func _press_heavy_and_release() -> void:
	var input := CombatInput.new()
	input.heavy_pressed = true
	input.heavy_held = true
	_controller.update(input, TINY)
	var release := CombatInput.new()
	release.heavy_released = true
	_controller.update(release, TINY)


## Press dodge, moving this way, in or out of Focus.
func _press_dodge(direction: Vector2, in_focus: bool) -> void:
	var input := CombatInput.new()
	input.dodge_pressed = true
	input.move = direction
	input.focus_held = in_focus
	_controller.update(input, TINY)


## Press block-step.
func _press_block() -> void:
	var input := CombatInput.new()
	input.block_pressed = true
	_controller.update(input, TINY)


## Play the whole three-hit string out to standing.
func _run_whole_light_string() -> void:
	for index: int in CombatRules.LIGHT_STRING_HITS:
		_press_light()
		_advance(_rules.light_windup(index) + _rules.light_active(index))
	_advance(_rules.light_recovery(CombatRules.LIGHT_STRING_HITS - 1))
