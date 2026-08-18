class_name SettingsScreen
extends Control

## Every option the design docs ask for, in one place, saved to `user://settings.cfg`.
##
## `docs/design/combat.md` §Accessibility asks for full input remapping, hold/toggle
## per held input, a Fool's Chance timing-window slider independent of difficulty, and
## screen-shake and screen-flash toggles; §Difficulty modes gives the three modes;
## `docs/design/art-audio.md` §Accessibility notes asks for scalable text, and §UI/UX
## pillars makes the quest marker "a setting, not a default" - so it is here, and it is
## off.
##
## The screen holds no state of its own: every control writes into `UiSettings`, which
## is the one thing that knows where a setting lives (see its class doc for the
## settings-file-not-save-file ruling this round makes).

## The held inputs `combat.md` §Accessibility names, in the order it names them.
const HELD_ACTIONS: Array[StringName] = [
	InputActions.BLOCK_STEP,
	InputActions.ATTACK_HEAVY,
	InputActions.SPRINT,
	InputActions.FOCUS,
	InputActions.PIP_WHEEL,
]

## How wide the Fool's Chance window slider may open the perfect-dodge beat, in
## seconds added to the tuned window. A placeholder range until the combat-tuning pass
## sets one: `CombatRules` owns the tuned window, not this screen.
const MAX_WINDOW_BONUS_SECONDS := 0.20
const WINDOW_BONUS_STEP := 0.01

var _settings: UiSettings = null
var _combat: CombatService = null
var _fool_combat: FoolCombat = null
var _scale: UiScale = null

var _difficulty: OptionButton = null
var _window: HSlider = null
var _text_scale: HSlider = null
var _shake: CheckButton = null
var _flash: CheckButton = null
var _markers: CheckButton = null
var _hold_buttons: Dictionary = {}
var _rebind_buttons: Dictionary = {}
var _rebinding: StringName = &""
var _rebind_notice: Label = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _rebinding == &"" or not visible:
		return
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	if not event.is_pressed():
		return
	rebind_with(event)
	get_viewport().set_input_as_handled()


## Hand the screen the settings it edits and the services those settings reach.
## Every argument may be null except the settings themselves.
func attach(
	settings: UiSettings,
	combat: CombatService = null,
	fool_combat: FoolCombat = null,
	ui_scale: UiScale = null
) -> void:
	_settings = settings
	_combat = combat
	_fool_combat = fool_combat
	_scale = ui_scale
	refresh()


## The settings being edited, or null.
func settings() -> UiSettings:
	return _settings


## The text-size helper this screen drives, or null.
func ui_scale() -> UiScale:
	return _scale


## The difficulty picker.
func difficulty_button() -> OptionButton:
	return _difficulty


## The Fool's Chance window slider.
func window_slider() -> HSlider:
	return _window


## The text-size slider.
func text_scale_slider() -> HSlider:
	return _text_scale


## The hold-or-toggle switch for one held action, or null.
func hold_button(action_name: StringName) -> CheckButton:
	if not _hold_buttons.has(action_name):
		return null
	return _hold_buttons[action_name] as CheckButton


## The rebinding row for one action, or null.
func rebind_button(action_name: StringName) -> Button:
	if not _rebind_buttons.has(action_name):
		return null
	return _rebind_buttons[action_name] as Button


## The action waiting for a key, or `&""` when nothing is.
func rebinding_action() -> StringName:
	return _rebinding


## Wait for a key for this action. The next key or pad button pressed becomes it.
func begin_rebind(action_name: StringName) -> void:
	_rebinding = action_name
	if _rebind_notice != null:
		_rebind_notice.visible = true


## Bind the action that is waiting to this event, and remember it. True when bound.
func rebind_with(event: InputEvent) -> bool:
	if _rebinding == &"" or _settings == null:
		return false
	var bound := _settings.rebind(_rebinding, event)
	_rebinding = &""
	if _rebind_notice != null:
		_rebind_notice.visible = false
	if bound:
		_settings.save_file()
	refresh()
	return bound


## Choose a difficulty mode. `combat.md` §Difficulty modes.
func choose_difficulty(mode: DifficultyMode.Id) -> void:
	if _settings == null:
		return
	_settings.difficulty_mode = mode
	_apply_and_save()


## Widen (or narrow) the perfect-dodge beat, in seconds added to the tuned window.
func choose_window_bonus(seconds: float) -> void:
	if _settings == null:
		return
	_settings.perfect_window_bonus_seconds = clampf(seconds, 0.0, MAX_WINDOW_BONUS_SECONDS)
	_apply_and_save()


## Put one held input on hold or on toggle.
func choose_hold_mode(action_name: StringName, mode: HoldOrToggle.Mode) -> void:
	if _settings == null:
		return
	_settings.set_hold_mode(action_name, mode)
	_apply_and_save()


## Set the text size, and apply it to the theme at once.
func choose_text_scale(new_scale: float) -> void:
	if _settings == null:
		return
	_settings.text_scale = clampf(new_scale, UiSettings.MIN_TEXT_SCALE, UiSettings.MAX_TEXT_SCALE)
	if _scale != null:
		_scale.apply(_settings.text_scale)
	_apply_and_save()


## Screen shake on or off.
func choose_screen_shake(on: bool) -> void:
	if _settings == null:
		return
	_settings.screen_shake = on
	_apply_and_save()


## Screen flash on or off.
func choose_screen_flash(on: bool) -> void:
	if _settings == null:
		return
	_settings.screen_flash = on
	_apply_and_save()


## The opt-in quest marker on or off.
func choose_quest_markers(on: bool) -> void:
	if _settings == null:
		return
	_settings.quest_markers = on
	_apply_and_save()


## Put every option back where it started, bindings included, and save that.
##
## The InputMap is reloaded from `project.godot`'s own authored bindings, so
## "defaults" means the game's defaults and not the last thing the player typed.
##
## The settings object is reset IN PLACE (`UiSettings.reset()`), never replaced: the
## shell holds the same object and pushes it into the services and the HUD, and a
## screen that quietly swapped it would leave everyone else editing an orphan.
func reset_to_defaults() -> void:
	if _settings == null:
		return
	_settings.reset()
	InputMap.load_from_project_settings()
	if _scale != null:
		_scale.apply(_settings.text_scale)
	_apply_and_save()


## Redraw every control from the settings.
func refresh() -> void:
	if _settings == null:
		return
	if _difficulty != null:
		_difficulty.selected = int(_settings.difficulty_mode)
	if _window != null:
		_window.set_value_no_signal(_settings.perfect_window_bonus_seconds)
	if _text_scale != null:
		_text_scale.set_value_no_signal(_settings.text_scale)
	if _shake != null:
		_shake.set_pressed_no_signal(_settings.screen_shake)
	if _flash != null:
		_flash.set_pressed_no_signal(_settings.screen_flash)
	if _markers != null:
		_markers.set_pressed_no_signal(_settings.quest_markers)
	for action_name: StringName in _hold_buttons:
		var button: CheckButton = _hold_buttons[action_name]
		button.set_pressed_no_signal(_settings.hold_mode(action_name) == HoldOrToggle.Mode.TOGGLE)
	for action_name: StringName in _rebind_buttons:
		var row: Button = _rebind_buttons[action_name]
		row.text = InputGlyphs.keyboard(action_name)


## Push what changed, keep it, and redraw. `notify_changed()` is what reaches the
## things this screen does not hold - the Fool's Chance wash obeying the screen-flash
## toggle, for one - because the shell owns those and listens for it.
func _apply_and_save() -> void:
	if _settings == null:
		return
	_settings.apply_to(_combat, _fool_combat)
	_settings.save_file()
	_settings.notify_changed()
	refresh()


func _build() -> void:
	add_child(UiFrames.panel_frame())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 64)
	margin.add_theme_constant_override(&"margin_right", 64)
	margin.add_theme_constant_override(&"margin_top", 52)
	margin.add_theme_constant_override(&"margin_bottom", 52)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	var title := Label.new()
	title.text = String(UiKeys.SETTINGS_TITLE)
	column.add_child(title)

	column.add_child(_labelled(UiKeys.SETTINGS_DIFFICULTY))
	_difficulty = OptionButton.new()
	for mode: DifficultyMode.Id in DifficultyMode.ALL:
		_difficulty.add_item(String(UiKeys.difficulty(mode)), int(mode))
	_difficulty.item_selected.connect(_on_difficulty_selected)
	column.add_child(_difficulty)

	column.add_child(_labelled(UiKeys.SETTINGS_FOOLS_CHANCE_WINDOW))
	_window = HSlider.new()
	_window.min_value = 0.0
	_window.max_value = MAX_WINDOW_BONUS_SECONDS
	_window.step = WINDOW_BONUS_STEP
	_window.value_changed.connect(choose_window_bonus)
	column.add_child(_window)

	column.add_child(_labelled(UiKeys.SETTINGS_TEXT_SCALE))
	_text_scale = HSlider.new()
	_text_scale.min_value = UiSettings.MIN_TEXT_SCALE
	_text_scale.max_value = UiSettings.MAX_TEXT_SCALE
	_text_scale.step = 0.05
	_text_scale.value_changed.connect(choose_text_scale)
	column.add_child(_text_scale)

	_shake = _switch(column, UiKeys.SETTINGS_SCREEN_SHAKE, choose_screen_shake)
	_flash = _switch(column, UiKeys.SETTINGS_SCREEN_FLASH, choose_screen_flash)
	_markers = _switch(column, UiKeys.SETTINGS_QUEST_MARKERS, choose_quest_markers)

	column.add_child(_labelled(UiKeys.SETTINGS_HOLD_TOGGLE))
	for action_name: StringName in HELD_ACTIONS:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(UiKeys.action(action_name))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var switch := CheckButton.new()
		switch.text = String(UiKeys.HOLD_MODES[HoldOrToggle.Mode.TOGGLE])
		switch.toggled.connect(_on_hold_toggled.bind(action_name))
		row.add_child(switch)
		column.add_child(row)
		_hold_buttons[action_name] = switch

	var reset := Button.new()
	reset.text = String(UiKeys.SETTINGS_RESET_DEFAULTS)
	reset.pressed.connect(reset_to_defaults)
	column.add_child(reset)

	column.add_child(_labelled(UiKeys.SETTINGS_REBIND))
	_rebind_notice = Label.new()
	_rebind_notice.text = String(UiKeys.SETTINGS_REBIND_PRESS)
	_rebind_notice.visible = false
	column.add_child(_rebind_notice)
	for action_name: StringName in InputActions.ALL:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(UiKeys.action(action_name))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var binder := Button.new()
		# What is printed on the key, which no translator owns - see `InputGlyphs`'
		# class doc and `UiKeys.COMPOSED_TEXT_META`.
		UiKeys.mark_composed(binder, UiKeys.COMPOSED_GLYPH)
		binder.text = InputGlyphs.keyboard(action_name)
		binder.pressed.connect(begin_rebind.bind(action_name))
		row.add_child(binder)
		column.add_child(row)
		_rebind_buttons[action_name] = binder


func _labelled(key: StringName) -> Label:
	var label := Label.new()
	label.text = String(key)
	return label


func _switch(column: VBoxContainer, key: StringName, handler: Callable) -> CheckButton:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = String(key)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var switch := CheckButton.new()
	switch.toggled.connect(handler)
	row.add_child(switch)
	column.add_child(row)
	return switch


func _on_difficulty_selected(index: int) -> void:
	if index < 0 or index >= DifficultyMode.ALL.size():
		return
	choose_difficulty(DifficultyMode.ALL[index])


func _on_hold_toggled(pressed: bool, action_name: StringName) -> void:
	choose_hold_mode(
		action_name, HoldOrToggle.Mode.TOGGLE if pressed else HoldOrToggle.Mode.HOLD
	)
