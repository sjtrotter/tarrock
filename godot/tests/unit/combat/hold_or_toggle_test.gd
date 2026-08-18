extends TarrockTest

## The accessibility layer under every held input.
##
## `docs/design/combat.md` §Accessibility asks for "Hold/toggle options for held
## inputs (block-step, charged heavy, sprint)", and the 2D amendment adds Focus. The
## point of proving it here rather than through `FoolCombat` is that the whole of the
## option is one class: if these pass, every held input in the game has the option,
## and no state machine downstream has to know which mode is on.


func test_hold_mode_answers_the_button() -> void:
	var input := HoldOrToggle.new()
	assert_eq(input.mode(), HoldOrToggle.Mode.HOLD, "hold is the default")
	assert_false(input.update(false))
	assert_true(input.update(true), "down is held")
	assert_true(input.update(true), "and stays held while it is down")
	assert_false(input.update(false), "up is released")


func test_toggle_mode_flips_on_each_press() -> void:
	var input := HoldOrToggle.new(HoldOrToggle.Mode.TOGGLE)
	assert_true(input.update(true), "the first press latches it on")
	assert_true(input.update(true), "holding the same press does not flip it back")
	assert_true(input.update(false), "and letting go leaves it on")
	assert_false(input.update(true), "the next press flips it off")
	assert_false(input.update(false))


func test_the_effective_state_is_announced() -> void:
	var input := HoldOrToggle.new(HoldOrToggle.Mode.TOGGLE)
	watch_signal(input, &"changed")
	input.update(true)
	input.update(false)
	input.update(true)
	assert_signal_emitted(input, &"changed", 2, "on and off, once each")
	assert_eq(signal_arguments(input, &"changed", 0), [true])
	assert_eq(signal_arguments(input, &"changed", 1), [false])


func test_switching_mode_releases_a_latched_input() -> void:
	var input := HoldOrToggle.new(HoldOrToggle.Mode.TOGGLE)
	assert_true(input.update(true))
	input.update(false)
	assert_true(input.is_held(), "latched on with no button down")
	input.set_mode(HoldOrToggle.Mode.HOLD)
	assert_false(input.is_held(), "a player who switches modes is not left stuck in Focus")
	assert_false(input.update(false))


func test_reset_drops_the_latch_without_changing_the_mode() -> void:
	var input := HoldOrToggle.new(HoldOrToggle.Mode.TOGGLE)
	input.update(true)
	input.reset()
	assert_false(input.is_held())
	assert_eq(input.mode(), HoldOrToggle.Mode.TOGGLE)
	assert_true(input.update(true), "and it still toggles afterwards")


func test_every_mode_has_a_stable_key() -> void:
	for mode: HoldOrToggle.Mode in HoldOrToggle.ALL_MODES:
		assert_ne(HoldOrToggle.name_key(mode), &"", "a settings file needs a name for each")
	assert_eq(HoldOrToggle.name_key(99 as HoldOrToggle.Mode), &"", "and none for a mode that is not one")
