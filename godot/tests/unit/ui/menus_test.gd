extends TarrockTest

## The pause menu and the settings screen: every option the docs ask for, reaching the
## service that owns it and the file that keeps it.
##
## `docs/design/combat.md` §Accessibility and §Difficulty modes and
## `docs/design/art-audio.md` §Accessibility notes are the checklist; this suite walks
## it. The pause menu is held to one rule of its own: it ASKS. A menu that saved a
## playthrough itself would be a menu holding one (`Services.save_game` is the only
## door), so what is asserted here is the signal, not the file.

const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_screen.tscn"
const THEME_PATH := "res://art/ui/theme.tres"
const SCRATCH := "user://test_ui_menus/settings.cfg"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const FOOL_SCENE_PATH := "res://scenes/fool.tscn"

const SPARE_KEYCODE := KEY_F11

var _pause: PauseMenu = null
var _screen: SettingsScreen = null
var _settings: UiSettings = null
var _combat: CombatService = null
var _fool: Node = null
var _fool_combat: FoolCombat = null
var _bindings_before: Array[InputEvent] = []


func before_each() -> void:
	TranslationServer.set_locale("en")
	_bindings_before = InputMap.action_get_events(InputActions.ROSE)
	_settings = UiSettings.new(SCRATCH)
	_combat = _build_combat()
	_fool = (load(FOOL_SCENE_PATH) as PackedScene).instantiate()
	tree().root.add_child(_fool)
	_fool_combat = _fool.get_node_or_null("FoolCombat") as FoolCombat
	if _fool_combat != null:
		_fool_combat.attach_service(_combat)
	_pause = (load(PAUSE_SCENE) as PackedScene).instantiate() as PauseMenu
	tree().root.add_child(_pause)
	_screen = (load(SETTINGS_SCENE) as PackedScene).instantiate() as SettingsScreen
	tree().root.add_child(_screen)
	_screen.attach(_settings, _combat, _fool_combat, UiScale.new(
		(load(THEME_PATH) as Theme).duplicate(true) as Theme
	))


func after_each() -> void:
	InputMap.action_erase_events(InputActions.ROSE)
	for event: InputEvent in _bindings_before:
		InputMap.action_add_event(InputActions.ROSE, event)
	for node: Node in [_pause, _screen, _fool]:
		if node != null and is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.free()
	_pause = null
	_screen = null
	_fool = null
	_fool_combat = null
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(SCRATCH)
	if DirAccess.dir_exists_absolute(SCRATCH.get_base_dir()):
		DirAccess.remove_absolute(SCRATCH.get_base_dir())


# --- The pause menu ----------------------------------------------------------------


func test_the_pause_menu_asks_rather_than_acts() -> void:
	watch_signal(_pause, &"save_requested")
	watch_signal(_pause, &"load_requested")
	watch_signal(_pause, &"resume_requested")
	_pause.save_row(0).pressed.emit()
	_pause.load_row(0).pressed.emit()
	assert_signal_emitted(_pause, &"save_requested", 1)
	assert_eq(signal_arguments(_pause, &"save_requested", 0), [0])


func test_a_slot_with_nothing_in_it_cannot_be_loaded_and_says_it_is_empty() -> void:
	_pause.attach(_build_save())
	for slot: int in range(PauseMenu.SLOT_COUNT):
		assert_true(_pause.load_row(slot).disabled, "slot %d has nothing in it" % slot)
		assert_has(
			_pause.load_row(slot).text,
			TranslationServer.translate(UiKeys.SAVE_SLOT_EMPTY),
			"an empty slot says so"
		)
		assert_has(
			_pause.load_row(slot).text,
			TranslationServer.translate(UiKeys.SAVE_SLOT_N).format({"n": slot + 1})
		)


# --- The settings ------------------------------------------------------------------


func test_the_screen_offers_a_row_for_every_action_the_docs_list() -> void:
	for action_name: StringName in InputActions.ALL:
		assert_not_null(
			_screen.rebind_button(action_name), "%s can be rebound" % action_name
		)
		assert_eq(_screen.rebind_button(action_name).text, InputGlyphs.keyboard(action_name))


func test_the_screen_offers_hold_or_toggle_for_every_held_input_combat_md_names() -> void:
	# combat.md §Accessibility: block-step, charged heavy, sprint, Focus, the Pip wheel.
	assert_eq(SettingsScreen.HELD_ACTIONS.size(), 5)
	for action_name: StringName in SettingsScreen.HELD_ACTIONS:
		assert_not_null(_screen.hold_button(action_name), "%s has a switch" % action_name)


func test_the_difficulty_reaches_combat_and_the_file() -> void:
	_screen.choose_difficulty(DifficultyMode.Id.TRIAL)
	assert_eq(_combat.difficulty(), DifficultyMode.Id.TRIAL)
	var reopened := UiSettings.new(SCRATCH)
	assert_true(reopened.load_file())
	assert_eq(reopened.difficulty_mode, DifficultyMode.Id.TRIAL)


func test_the_fools_chance_slider_reaches_combat_and_is_independent_of_difficulty() -> void:
	var tuned := _combat.perfect_window_seconds()
	_screen.choose_window_bonus(0.04)
	assert_almost_eq(_combat.perfect_window_bonus_seconds(), 0.04)
	assert_almost_eq(_combat.perfect_window_seconds(), tuned + 0.04)
	var mode := _combat.difficulty()
	assert_eq(mode, DifficultyMode.DEFAULT, "the slider changed no difficulty")


func test_hold_or_toggle_reaches_the_fool() -> void:
	if _fool_combat == null:
		fail("the Fool scene has no FoolCombat")
		return
	assert_eq(_fool_combat.hold_mode(InputActions.BLOCK_STEP), HoldOrToggle.Mode.HOLD)
	_screen.choose_hold_mode(InputActions.BLOCK_STEP, HoldOrToggle.Mode.TOGGLE)
	assert_eq(_fool_combat.hold_mode(InputActions.BLOCK_STEP), HoldOrToggle.Mode.TOGGLE)
	var reopened := UiSettings.new(SCRATCH)
	reopened.load_file()
	assert_eq(reopened.hold_mode(InputActions.BLOCK_STEP), HoldOrToggle.Mode.TOGGLE)


func test_the_text_size_scales_the_theme_and_is_kept() -> void:
	var theme := _screen_theme()
	var before := theme.default_font_size
	_screen.choose_text_scale(1.5)
	assert_true(theme.default_font_size > before)
	var reopened := UiSettings.new(SCRATCH)
	reopened.load_file()
	assert_almost_eq(reopened.text_scale, 1.5)


func test_the_shake_and_flash_toggles_are_kept() -> void:
	_screen.choose_screen_shake(false)
	_screen.choose_screen_flash(false)
	var reopened := UiSettings.new(SCRATCH)
	reopened.load_file()
	assert_false(reopened.screen_shake)
	assert_false(reopened.screen_flash)


func test_the_quest_marker_is_off_until_the_player_asks_for_it() -> void:
	# `art-audio.md` §UI/UX pillars: "a quest marker is a setting, not a default".
	assert_false(_settings.quest_markers)
	_screen.choose_quest_markers(true)
	var reopened := UiSettings.new(SCRATCH)
	reopened.load_file()
	assert_true(reopened.quest_markers)


func test_rebinding_writes_the_input_map_and_the_file() -> void:
	_screen.begin_rebind(InputActions.ROSE)
	assert_eq(_screen.rebinding_action(), InputActions.ROSE)
	var event := InputEventKey.new()
	event.physical_keycode = SPARE_KEYCODE
	event.pressed = true
	assert_true(_screen.rebind_with(event))
	assert_eq(_screen.rebinding_action(), &"", "the screen stopped waiting")
	assert_true(InputMap.action_has_event(InputActions.ROSE, event))
	assert_eq(_screen.rebind_button(InputActions.ROSE).text, OS.get_keycode_string(SPARE_KEYCODE))

	var reopened := UiSettings.new(SCRATCH)
	assert_true(reopened.load_file())
	assert_eq(reopened.apply_bindings(), 1)


func test_a_slot_row_is_the_csvs_own_format_with_the_number_put_into_it() -> void:
	# The row is `UI_SLOT_N` ("Slot {n}") formatted, not the word and the number
	# concatenated: a language that orders them differently says so in the CSV.
	_pause.attach(_build_save())
	assert_eq(TranslationServer.translate(UiKeys.SAVE_SLOT_N), "Slot {n}")
	for slot: int in range(PauseMenu.SLOT_COUNT):
		assert_true(
			_pause.save_row(slot).text.begins_with("Slot %d" % (slot + 1)),
			"slot %d reads '%s', and a player counts from one" % [slot, _pause.save_row(slot).text]
		)
	assert_false(
		_pause.save_row(0).text.contains("{n}"), "the placeholder was filled, not printed"
	)


func test_going_back_to_defaults_puts_the_authored_bindings_back() -> void:
	_screen.begin_rebind(InputActions.ROSE)
	var event := InputEventKey.new()
	event.physical_keycode = SPARE_KEYCODE
	event.pressed = true
	_screen.rebind_with(event)
	assert_true(InputMap.action_has_event(InputActions.ROSE, event))
	_screen.reset_to_defaults()
	assert_false(
		InputMap.action_has_event(InputActions.ROSE, event),
		"defaults means the game's own bindings, not the last thing typed"
	)
	assert_eq(_screen.settings().bindings.size(), 0)


func test_going_back_to_defaults_resets_the_settings_object_everyone_else_holds() -> void:
	# The screen used to REPLACE the settings object, which left the shell - and the
	# services it pushes into - holding the old one: "reset to defaults" reset the
	# screen and nothing else in the game.
	var held := _screen.settings()
	_screen.choose_text_scale(1.75)
	_screen.choose_screen_flash(false)
	_screen.choose_quest_markers(true)
	_screen.choose_difficulty(DifficultyMode.Id.TRIAL)
	_screen.choose_hold_mode(InputActions.SPRINT, HoldOrToggle.Mode.TOGGLE)
	assert_almost_eq(held.text_scale, 1.75)

	_screen.reset_to_defaults()
	assert_eq(_screen.settings(), held, "the same object, reset in place")
	assert_almost_eq(held.text_scale, UiSettings.DEFAULT_TEXT_SCALE)
	assert_true(held.screen_flash)
	assert_false(held.quest_markers)
	assert_eq(held.difficulty_mode, DifficultyMode.DEFAULT)
	assert_eq(held.hold_mode(InputActions.SPRINT), HoldOrToggle.Mode.HOLD)
	assert_eq(held.hold_modes.size(), 0)

	# And the defaults were written, so the next boot reads them back.
	var reopened := UiSettings.new(SCRATCH)
	assert_true(reopened.load_file())
	assert_almost_eq(reopened.text_scale, UiSettings.DEFAULT_TEXT_SCALE)
	assert_true(reopened.screen_flash)


func test_a_rebind_on_the_keyboard_leaves_the_pad_button_alone() -> void:
	# `rose` is bound to R and to a pad button by `project.godot`. Moving the keyboard
	# half must not silently unbind the controller.
	var pad := _pad_events(InputActions.ROSE)
	assert_true(pad.size() > 0, "the action ships with a pad binding to protect")
	_screen.begin_rebind(InputActions.ROSE)
	var event := InputEventKey.new()
	event.physical_keycode = SPARE_KEYCODE
	event.pressed = true
	assert_true(_screen.rebind_with(event))
	assert_true(InputMap.action_has_event(InputActions.ROSE, event), "the new key is bound")
	for button: InputEvent in pad:
		assert_true(
			InputMap.action_has_event(InputActions.ROSE, button),
			"the pad button is still bound"
		)
	assert_eq(_key_events(InputActions.ROSE).size(), 1, "and only one key answers now")


func _pad_events(action_name: StringName) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			events.append(event)
	return events


func _key_events(action_name: StringName) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			events.append(event)
	return events


func _screen_theme() -> Theme:
	return _screen.ui_scale().theme()


func _build_combat() -> CombatService:
	var rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	var world_state := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var fortune := FortuneService.new(rules)
	var spread := PocketSpreadService.new(
		world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, rules, fortune
	)
	return CombatService.new(
		(load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules,
		fortune,
		spread,
		WhiteRoseService.new(world_state, rules),
		GameClock.new()
	)


func _build_save() -> SaveService:
	return SaveService.new(
		WorldStateService.new(
			load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
			load(ACT_THRESHOLDS_PATH) as ActThresholds,
			load(RENOWN_LADDER_PATH) as RenownLadder
		),
		GameClock.new(),
		"user://test_ui_menus_saves"
	)
