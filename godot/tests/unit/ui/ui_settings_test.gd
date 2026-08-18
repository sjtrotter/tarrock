extends TarrockTest

## The settings file: what it keeps, that it keeps it, and where it pushes it.
##
## `docs/design/technical.md` §Open questions (TBD) — Godot 2D asked where rebinds are
## stored, save file or settings file. This round answered SETTINGS FILE, and this suite
## is that answer held to: a written file read back by a second object, bindings that
## reach the live `InputMap`, and options that reach the services that own them.
##
## Nothing here touches `user://settings.cfg`: a test that wrote the player's own
## settings would be one crash away from standing on them.

const SCRATCH := "user://test_ui_settings/settings.cfg"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## A key nothing is bound to by default, so a rebinding test cannot pass by accident.
const REBIND_KEYCODE := KEY_F9

var _settings: UiSettings = null
var _bindings_before: Array[InputEvent] = []


func before_each() -> void:
	_settings = UiSettings.new(SCRATCH)
	_bindings_before = InputMap.action_get_events(InputActions.DODGE)


func after_each() -> void:
	# Whatever a test did to the InputMap is undone: an action left rebound would be
	# rebound for every suite that ran afterwards. `rose` is put back from the project
	# settings, which is where its two bindings are authored.
	InputMap.action_erase_events(InputActions.DODGE)
	for event: InputEvent in _bindings_before:
		InputMap.action_add_event(InputActions.DODGE, event)
	InputMap.load_from_project_settings()
	UiSettings.settings_path_override = ""
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(SCRATCH)
	var directory := SCRATCH.get_base_dir()
	if DirAccess.dir_exists_absolute(directory):
		DirAccess.remove_absolute(directory)


func test_a_first_run_gets_the_documented_defaults() -> void:
	assert_false(_settings.load_file(), "there is no file yet, and that is not an error")
	assert_almost_eq(_settings.text_scale, 1.0)
	assert_true(_settings.screen_shake)
	assert_true(_settings.screen_flash)
	# `art-audio.md` UI/UX pillars: "a quest marker is a setting, not a default".
	assert_false(_settings.quest_markers, "the quest marker ships OFF")
	assert_eq(_settings.difficulty_mode, DifficultyMode.DEFAULT)
	assert_almost_eq(_settings.perfect_window_bonus_seconds, 0.0)
	assert_eq(_settings.hold_mode(InputActions.BLOCK_STEP), HoldOrToggle.Mode.HOLD)


func test_every_option_survives_a_write_and_a_read_by_another_object() -> void:
	_settings.text_scale = 1.5
	_settings.screen_shake = false
	_settings.screen_flash = false
	_settings.quest_markers = true
	_settings.difficulty_mode = DifficultyMode.Id.TRIAL
	_settings.perfect_window_bonus_seconds = 0.06
	_settings.set_hold_mode(InputActions.FOCUS, HoldOrToggle.Mode.TOGGLE)
	assert_true(_settings.save_file(), "the file landed on disk")

	var reopened := UiSettings.new(SCRATCH)
	assert_true(reopened.load_file())
	assert_almost_eq(reopened.text_scale, 1.5)
	assert_false(reopened.screen_shake)
	assert_false(reopened.screen_flash)
	assert_true(reopened.quest_markers)
	assert_eq(reopened.difficulty_mode, DifficultyMode.Id.TRIAL)
	assert_almost_eq(reopened.perfect_window_bonus_seconds, 0.06)
	assert_eq(reopened.hold_mode(InputActions.FOCUS), HoldOrToggle.Mode.TOGGLE)


func test_a_text_scale_outside_the_readable_range_is_clamped_on_the_way_in() -> void:
	_settings.text_scale = 12.0
	_settings.save_file()
	var reopened := UiSettings.new(SCRATCH)
	reopened.load_file()
	assert_almost_eq(reopened.text_scale, UiSettings.MAX_TEXT_SCALE)


func test_a_rebind_reaches_the_input_map_at_once_and_survives_the_file() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = REBIND_KEYCODE
	assert_true(_settings.rebind(InputActions.DODGE, event))
	assert_true(
		InputMap.action_has_event(InputActions.DODGE, event),
		"a rebind that only wrote a file would leave the player pressing the old key"
	)
	assert_true(_settings.save_file())

	# Put the default back, then prove the file alone can restore the rebind.
	InputMap.action_erase_events(InputActions.DODGE)
	for old: InputEvent in _bindings_before:
		InputMap.action_add_event(InputActions.DODGE, old)
	assert_false(InputMap.action_has_event(InputActions.DODGE, event))

	var reopened := UiSettings.new(SCRATCH)
	assert_true(reopened.load_file())
	assert_eq(reopened.apply_bindings(), 1)
	assert_true(InputMap.action_has_event(InputActions.DODGE, event))


func test_a_keyboard_rebind_keeps_the_pad_binding_and_the_file_keeps_both() -> void:
	# Every action in `project.godot` is bound twice - a key and a pad button - and a
	# player rebinding on the keyboard has said nothing about the controller. The old
	# `rebind()` erased every event, which unbound the pad silently.
	var pad_before := _events_of_class(InputActions.PIP_WHEEL, false)
	assert_true(pad_before.size() > 0, "`pip_wheel` ships with a pad binding")
	var event := InputEventKey.new()
	event.physical_keycode = REBIND_KEYCODE
	assert_true(_settings.rebind(InputActions.PIP_WHEEL, event))
	assert_true(InputMap.action_has_event(InputActions.PIP_WHEEL, event))
	for button: InputEvent in pad_before:
		assert_true(
			InputMap.action_has_event(InputActions.PIP_WHEEL, button),
			"the pad button survived a keyboard rebind"
		)
	assert_eq(_events_of_class(InputActions.PIP_WHEEL, true).size(), 1, "one key, the new one")

	# Both halves are remembered, so a reload puts both back.
	assert_eq(_settings.bindings[InputActions.PIP_WHEEL].size(), 1 + pad_before.size())
	assert_true(_settings.save_file())
	InputMap.load_from_project_settings()
	assert_false(InputMap.action_has_event(InputActions.PIP_WHEEL, event))

	var reopened := UiSettings.new(SCRATCH)
	assert_true(reopened.load_file())
	assert_eq(reopened.apply_bindings(), 1)
	assert_true(InputMap.action_has_event(InputActions.PIP_WHEEL, event), "the key came back")
	for button: InputEvent in pad_before:
		assert_true(
			InputMap.action_has_event(InputActions.PIP_WHEEL, button), "and so did the pad button"
		)


func test_a_pad_rebind_replaces_the_pad_binding_and_not_the_key() -> void:
	var key_before := _events_of_class(InputActions.PIP_WHEEL, true)
	assert_true(key_before.size() > 0, "`pip_wheel` ships with a key")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_RIGHT_SHOULDER
	assert_true(_settings.rebind(InputActions.PIP_WHEEL, button))
	assert_true(InputMap.action_has_event(InputActions.PIP_WHEEL, button))
	for key: InputEvent in key_before:
		assert_true(
			InputMap.action_has_event(InputActions.PIP_WHEEL, key), "the keyboard was not touched"
		)
	assert_eq(_events_of_class(InputActions.PIP_WHEEL, false).size(), 1, "one pad event, the new one")


func test_something_changed_is_announced_so_the_shell_can_push_it_again() -> void:
	# The shell holds this object and pushes it into services and HUD nodes; without
	# this signal a toggle flipped mid-play reached the file and nothing else.
	watch_signal(_settings, &"changed")
	_settings.set_hold_mode(InputActions.FOCUS, HoldOrToggle.Mode.TOGGLE)
	assert_signal_emitted(_settings, &"changed", 1)
	var event := InputEventKey.new()
	event.physical_keycode = REBIND_KEYCODE
	_settings.rebind(InputActions.DODGE, event)
	assert_signal_emitted(_settings, &"changed", 2)
	_settings.reset()
	assert_signal_emitted(_settings, &"changed", 3)


func test_reset_puts_every_field_back_in_place_without_replacing_the_object() -> void:
	_settings.text_scale = 1.9
	_settings.screen_shake = false
	_settings.screen_flash = false
	_settings.quest_markers = true
	_settings.difficulty_mode = DifficultyMode.Id.TRIAL
	_settings.perfect_window_bonus_seconds = 0.08
	_settings.set_hold_mode(InputActions.SPRINT, HoldOrToggle.Mode.TOGGLE)
	var event := InputEventKey.new()
	event.physical_keycode = REBIND_KEYCODE
	_settings.rebind(InputActions.DODGE, event)

	_settings.reset()
	assert_almost_eq(_settings.text_scale, UiSettings.DEFAULT_TEXT_SCALE)
	assert_true(_settings.screen_shake)
	assert_true(_settings.screen_flash)
	assert_false(_settings.quest_markers)
	assert_eq(_settings.difficulty_mode, DifficultyMode.DEFAULT)
	assert_almost_eq(_settings.perfect_window_bonus_seconds, 0.0)
	assert_eq(_settings.hold_modes.size(), 0)
	assert_eq(_settings.bindings.size(), 0)
	assert_eq(_settings.path(), SCRATCH, "the same object, still pointed at the same file")


func test_the_shell_boots_against_the_override_when_a_test_asks_for_one() -> void:
	# `res://tests/ui_test.gd` boots a real persistent layer, which builds a real
	# `UiShell`, which loads settings. Without this it would read - and, the moment
	# anything saved, write - the settings of whoever is at this keyboard.
	assert_eq(UiSettings.settings_path_override, "", "nothing leaked in from another suite")
	assert_eq(UiSettings.for_boot().path(), UiSettings.DEFAULT_PATH)
	UiSettings.settings_path_override = SCRATCH
	assert_eq(UiSettings.for_boot().path(), SCRATCH)
	UiSettings.settings_path_override = ""
	assert_eq(UiSettings.for_boot().path(), UiSettings.DEFAULT_PATH)


func test_a_rebind_of_an_action_that_does_not_exist_changes_nothing() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = REBIND_KEYCODE
	assert_false(_settings.rebind(&"not_an_action", event))
	assert_false(_settings.rebind(InputActions.DODGE, null))
	assert_eq(_settings.bindings.size(), 0)


func test_the_settings_push_into_the_services_that_own_them() -> void:
	var combat := _build_combat()
	_settings.perfect_window_bonus_seconds = 0.05
	_settings.difficulty_mode = DifficultyMode.Id.STORY
	_settings.apply_to(combat, null)
	assert_almost_eq(combat.perfect_window_bonus_seconds(), 0.05)
	assert_eq(combat.difficulty(), DifficultyMode.Id.STORY)
	# `combat.md` §Accessibility: the slider is "independent of difficulty mode", so
	# the window it produces is the tuned one plus the bonus, whatever the mode is.
	assert_true(combat.perfect_window_seconds() > 0.0)


func test_applying_with_nothing_attached_is_a_no_op_rather_than_an_error() -> void:
	_settings.apply_to(null, null)
	assert_eq(_settings.path(), SCRATCH)


## The events of one device class bound to an action: the keys, or the pad's.
func _events_of_class(action_name: StringName, keys: bool) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action_name):
		var is_key := event is InputEventKey
		if is_key == keys:
			events.append(event)
	return events


func _build_combat() -> CombatService:
	var rules := (load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules
	var spread_rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	var world_state := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var fortune := FortuneService.new(spread_rules)
	var spread := PocketSpreadService.new(
		world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, spread_rules, fortune
	)
	var rose := WhiteRoseService.new(world_state, spread_rules)
	return CombatService.new(rules, fortune, spread, rose, GameClock.new())
