class_name UiSettings
extends RefCounted

## The player's settings, and the file they live in.
##
## **This answers `docs/design/technical.md` §Open questions (TBD) — Godot 2D,
## "Rebinding UI and the settings save": rebinds and every other option are stored in
## a SETTINGS FILE (`user://settings.cfg`), NOT in the save file.** The reasoning is
## the doc's own SSOT rule read once: a save is a playthrough, and a control binding
## or a text size is a fact about the person at the keyboard, not about the Fool. A
## player who starts a second playthrough keeps their bindings; a player who loads an
## old save does not get their old text size back. The one setting that is genuinely
## both - the difficulty mode - stays where it already is, in the save
## (`SaveModel.difficulty_mode`), and is MIRRORED here only so a settings screen can
## show it before a playthrough is loaded.
##
## Nothing here reaches into a service. `apply_to()` is handed the services it should
## push into, exactly once, by whoever owns them (`UiShell`).
##
## Every option the docs ask for is here and no more:
## `docs/design/combat.md` §Accessibility (full remapping, hold/toggle per held
## input, the Fool's Chance window slider, screen-shake and screen-flash toggles),
## §Difficulty modes, and `docs/design/art-audio.md` §UI/UX pillars (scalable text;
## a quest marker "is a setting, not a default", so it ships OFF).

## Something in here changed, and whoever pushed a setting into a service or a node
## has to push it again.
##
## The screen edits this object; the shell owns the nodes a setting reaches (the
## Fool's Chance wash obeys the screen-flash toggle, the theme obeys the text size).
## Without this signal the shell only ever pushed at boot and at a rebuild, so a
## toggle flipped mid-play reached the FILE and not the SCREEN.
signal changed()

## Where the file lives. Not `user://saves/`: this is not a playthrough.
const DEFAULT_PATH := "user://settings.cfg"

## The path `for_boot()` hands the shell instead of `DEFAULT_PATH`, when it is set.
##
## A test that let the shell boot against the real file would be reading - and, the
## first time anything saved, writing - the settings of whoever is at this keyboard.
## `res://tests/ui_test.gd` sets this to a scratch path before the persistent layer is
## instanced and clears it afterwards; nothing in the game ever sets it.
static var settings_path_override: String = ""

const SECTION_ACCESSIBILITY := "accessibility"
const SECTION_COMBAT := "combat"
const SECTION_INPUT := "input"
const SECTION_HOLD := "hold_modes"

const KEY_TEXT_SCALE := "text_scale"
const KEY_SCREEN_SHAKE := "screen_shake"
const KEY_SCREEN_FLASH := "screen_flash"
const KEY_QUEST_MARKERS := "quest_markers"
const KEY_DIFFICULTY := "difficulty_mode"
const KEY_PERFECT_WINDOW_BONUS := "perfect_window_bonus_seconds"

## Text scale bounds. 2.0 is the size the manuscript framing is asked to survive
## (`art-audio.md` §Accessibility notes: "degrade gracefully at large sizes rather
## than break its frame art"), which is what `res://tests/unit/ui/ui_scale_test.gd`
## holds the frames to.
const MIN_TEXT_SCALE := 0.75
const MAX_TEXT_SCALE := 2.0

## How a bound event is spelled in the file: `k:<physical_keycode>`,
## `b:<button_index>`, `a:<axis>:<value>`. Small, stable and human-readable, which
## matters for a file a player may open.
const EVENT_KEY := "k:"
const EVENT_BUTTON := "b:"
const EVENT_AXIS := "a:"

## The device id every restored event carries: -1, which `InputMap` reads as ALL
## DEVICES and which is what `project.godot` authors its own bindings with.
##
## It matters. An event restored with the default device 0 answers only to keyboard 0
## and joypad 0, so a rebound pad button silently stopped working on the second
## controller - and, less visibly, `InputMap.action_has_event()` stopped recognising
## the project's own events as the same binding.
const ALL_DEVICES := -1

## Which kind of thing a player pressed. Two events of the same class are two
## spellings of the same gesture on the same device, and a rebind replaces one with
## the other; two events of different classes are the keyboard and the controller,
## and neither speaks for the other.
enum DeviceClass {
	## Anything else - a mouse button, an event this file has no spelling for.
	OTHER,
	## A key on the keyboard.
	KEY,
	## A pad button, a stick or a trigger.
	PAD,
}

## What every option is before a player touches it - the one place a default is
## spelled, so `reset()` and a first run cannot drift apart.
const DEFAULT_TEXT_SCALE := 1.0
const DEFAULT_SCREEN_SHAKE := true
const DEFAULT_SCREEN_FLASH := true
const DEFAULT_QUEST_MARKERS := false
const DEFAULT_WINDOW_BONUS_SECONDS := 0.0

## Scalable text size across all UI (`art-audio.md` §Accessibility notes).
var text_scale: float = DEFAULT_TEXT_SCALE

## Screen-shake and screen-flash toggles (`combat.md` §Accessibility).
var screen_shake: bool = DEFAULT_SCREEN_SHAKE
var screen_flash: bool = DEFAULT_SCREEN_FLASH

## The opt-in quest marker (`art-audio.md` §UI/UX pillars). OFF is the default and
## the design: minimal quest UI, no waypoint arrows unless the player asks.
var quest_markers: bool = DEFAULT_QUEST_MARKERS

## The difficulty mode last chosen. Mirrored from the save; see the class doc.
var difficulty_mode: DifficultyMode.Id = DifficultyMode.DEFAULT

## The Fool's Chance timing-window slider, in seconds ADDED to the tuned window -
## `combat.md` §Accessibility says it is independent of difficulty mode.
var perfect_window_bonus_seconds: float = DEFAULT_WINDOW_BONUS_SECONDS

## Hold-or-toggle mode per held action (`combat.md` §Accessibility names block-step,
## charged heavy, sprint, Focus and the Pip wheel). Keyed by action name.
var hold_modes: Dictionary = {}

## Rebound actions: action name -> array of event spellings. An action absent here
## keeps whatever `project.godot` bound it to.
var bindings: Dictionary = {}

var _path: String = DEFAULT_PATH


func _init(path: String = DEFAULT_PATH) -> void:
	_path = path


## The settings the shell boots against: the player's own file, or the scratch path
## a test asked for through `settings_path_override`.
static func for_boot() -> UiSettings:
	if settings_path_override.is_empty():
		return UiSettings.new(DEFAULT_PATH)
	return UiSettings.new(settings_path_override)


## Where this settings object reads and writes.
func path() -> String:
	return _path


## Say that something changed, so whoever pushes these into services and nodes does
## it again. Called by every mutator here and by the settings screen, which writes
## the plain fields directly.
func notify_changed() -> void:
	changed.emit()


## Put every option back where it started, IN PLACE.
##
## In place and not by building a fresh object: the shell, the settings screen and
## whoever else was handed this one all still hold it, and a "reset" that swapped the
## object would leave every one of them editing a settings object nobody saves. The
## `InputMap` itself is the screen's to reload (`SettingsScreen.reset_to_defaults`) -
## this is only what the file remembers.
func reset() -> void:
	text_scale = DEFAULT_TEXT_SCALE
	screen_shake = DEFAULT_SCREEN_SHAKE
	screen_flash = DEFAULT_SCREEN_FLASH
	quest_markers = DEFAULT_QUEST_MARKERS
	difficulty_mode = DifficultyMode.DEFAULT
	perfect_window_bonus_seconds = DEFAULT_WINDOW_BONUS_SECONDS
	hold_modes.clear()
	bindings.clear()
	notify_changed()


## Read the file. Missing file is not an error - it means defaults, which is exactly
## what a first run should get. True when a file was found and read.
func load_file() -> bool:
	var config := ConfigFile.new()
	if config.load(_path) != OK:
		return false
	text_scale = clampf(
		float(config.get_value(SECTION_ACCESSIBILITY, KEY_TEXT_SCALE, text_scale)),
		MIN_TEXT_SCALE,
		MAX_TEXT_SCALE
	)
	screen_shake = bool(config.get_value(SECTION_ACCESSIBILITY, KEY_SCREEN_SHAKE, screen_shake))
	screen_flash = bool(config.get_value(SECTION_ACCESSIBILITY, KEY_SCREEN_FLASH, screen_flash))
	quest_markers = bool(
		config.get_value(SECTION_ACCESSIBILITY, KEY_QUEST_MARKERS, quest_markers)
	)
	difficulty_mode = _difficulty_from(
		int(config.get_value(SECTION_COMBAT, KEY_DIFFICULTY, int(difficulty_mode)))
	)
	perfect_window_bonus_seconds = float(
		config.get_value(SECTION_COMBAT, KEY_PERFECT_WINDOW_BONUS, perfect_window_bonus_seconds)
	)
	hold_modes.clear()
	if config.has_section(SECTION_HOLD):
		for action_name: String in config.get_section_keys(SECTION_HOLD):
			hold_modes[StringName(action_name)] = _hold_mode_from(
				int(config.get_value(SECTION_HOLD, action_name, int(HoldOrToggle.Mode.HOLD)))
			)
	bindings.clear()
	if config.has_section(SECTION_INPUT):
		for action_name: String in config.get_section_keys(SECTION_INPUT):
			var spellings: PackedStringArray = config.get_value(
				SECTION_INPUT, action_name, PackedStringArray()
			)
			bindings[StringName(action_name)] = spellings
	notify_changed()
	return true


## Write the file. True when it landed on disk.
func save_file() -> bool:
	var config := ConfigFile.new()
	config.set_value(SECTION_ACCESSIBILITY, KEY_TEXT_SCALE, text_scale)
	config.set_value(SECTION_ACCESSIBILITY, KEY_SCREEN_SHAKE, screen_shake)
	config.set_value(SECTION_ACCESSIBILITY, KEY_SCREEN_FLASH, screen_flash)
	config.set_value(SECTION_ACCESSIBILITY, KEY_QUEST_MARKERS, quest_markers)
	config.set_value(SECTION_COMBAT, KEY_DIFFICULTY, int(difficulty_mode))
	config.set_value(SECTION_COMBAT, KEY_PERFECT_WINDOW_BONUS, perfect_window_bonus_seconds)
	for action_name: StringName in hold_modes:
		config.set_value(SECTION_HOLD, String(action_name), int(hold_modes[action_name]))
	for action_name: StringName in bindings:
		config.set_value(SECTION_INPUT, String(action_name), bindings[action_name])
	var directory := _path.get_base_dir()
	if not directory.is_empty() and not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)
	return config.save(_path) == OK


## The hold-or-toggle mode chosen for an action, or HOLD where nothing was chosen.
func hold_mode(action_name: StringName) -> HoldOrToggle.Mode:
	if not hold_modes.has(action_name):
		return HoldOrToggle.Mode.HOLD
	return _hold_mode_from(int(hold_modes[action_name]))


## Choose hold or toggle for one held action.
func set_hold_mode(action_name: StringName, mode: HoldOrToggle.Mode) -> void:
	hold_modes[action_name] = mode
	notify_changed()


## Rebind an action to one event, and remember the WHOLE list the action now answers
## to. The `InputMap` is changed immediately: a rebinding screen that only wrote a
## file would leave the player pressing the old key until they restarted.
##
## **Only the events of the new event's own device class are replaced.** Every action
## in `project.godot` is bound twice - a key and a pad button - and a player who moves
## `rose` off R has said nothing at all about the pad button under their thumb. The
## old behaviour erased every event, so rebinding on the keyboard silently unbound the
## controller (and the reverse), which no rebinding screen in any game does.
func rebind(action_name: StringName, event: InputEvent) -> bool:
	if event == null or not InputMap.has_action(action_name):
		return false
	var spelling := _spell(event)
	if spelling.is_empty():
		return false
	var device_class := _device_class(event)
	var kept: Array[InputEvent] = []
	for existing: InputEvent in InputMap.action_get_events(action_name):
		if _device_class(existing) != device_class:
			kept.append(existing)
	# The player pressed a key on one keyboard; the binding is for every keyboard, the
	# same as the authored ones and the same as this one will be when the file is read
	# back (see `ALL_DEVICES`).
	var bound := event.duplicate() as InputEvent
	bound.device = ALL_DEVICES
	InputMap.action_erase_events(action_name)
	for existing: InputEvent in kept:
		InputMap.action_add_event(action_name, existing)
	InputMap.action_add_event(action_name, bound)
	bindings[action_name] = _spell_all(InputMap.action_get_events(action_name))
	notify_changed()
	return true


## Put every remembered binding back into the `InputMap`. Actions nobody rebound are
## left exactly as `project.godot` authored them.
##
## The WHOLE list is restored, not the one event that was rebound: an action answers
## to a key and a pad button at once, and `rebind()` records both (see its doc). An
## event kind `_spell()` has no spelling for is not written and therefore not
## restored; nothing in `project.godot` binds one, and the day something does it needs
## a spelling here rather than an exception.
func apply_bindings() -> int:
	var applied := 0
	for action_name: StringName in bindings:
		if not InputMap.has_action(action_name):
			continue
		var events: Array[InputEvent] = []
		var spellings: PackedStringArray = bindings[action_name]
		for spelling: String in spellings:
			var event := _parse(spelling)
			if event != null:
				events.append(event)
		if events.is_empty():
			continue
		InputMap.action_erase_events(action_name)
		for event: InputEvent in events:
			InputMap.action_add_event(action_name, event)
		applied += 1
	return applied


## Push every setting that a service owns into that service. Any argument may be
## null - a settings screen opened before a playthrough exists still works.
func apply_to(combat: CombatService, fool_combat: FoolCombat) -> void:
	if combat != null:
		combat.set_perfect_window_bonus_seconds(perfect_window_bonus_seconds)
		combat.set_difficulty(difficulty_mode)
	if fool_combat != null:
		for action_name: StringName in hold_modes:
			fool_combat.set_hold_mode(action_name, hold_mode(action_name))


func _difficulty_from(value: int) -> DifficultyMode.Id:
	if value < 0 or value >= DifficultyMode.ALL.size():
		return DifficultyMode.DEFAULT
	return value as DifficultyMode.Id


func _hold_mode_from(value: int) -> HoldOrToggle.Mode:
	if value < 0 or value >= HoldOrToggle.ALL_MODES.size():
		return HoldOrToggle.Mode.HOLD
	return value as HoldOrToggle.Mode


## Which device class one event belongs to.
static func _device_class(event: InputEvent) -> DeviceClass:
	if event is InputEventKey:
		return DeviceClass.KEY
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return DeviceClass.PAD
	return DeviceClass.OTHER


## A list of events, spelled for the file, with the ones nothing spells left out.
func _spell_all(events: Array[InputEvent]) -> PackedStringArray:
	var spellings := PackedStringArray()
	for event: InputEvent in events:
		var spelling := _spell(event)
		if not spelling.is_empty():
			spellings.append(spelling)
	return spellings


## One event, spelled for the file. Empty for an event kind nothing binds.
func _spell(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		return EVENT_KEY + str(int(code))
	var button := event as InputEventJoypadButton
	if button != null:
		return EVENT_BUTTON + str(int(button.button_index))
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return EVENT_AXIS + str(int(motion.axis)) + ":" + str(motion.axis_value)
	return ""


## One spelling, read back into an event. Null when the line is not one of ours.
func _parse(spelling: String) -> InputEvent:
	if spelling.begins_with(EVENT_KEY):
		var key := InputEventKey.new()
		key.device = ALL_DEVICES
		key.physical_keycode = int(spelling.substr(EVENT_KEY.length()))
		return key
	if spelling.begins_with(EVENT_BUTTON):
		var button := InputEventJoypadButton.new()
		button.device = ALL_DEVICES
		button.button_index = int(spelling.substr(EVENT_BUTTON.length()))
		return button
	if spelling.begins_with(EVENT_AXIS):
		var parts := spelling.substr(EVENT_AXIS.length()).split(":")
		if parts.size() != 2:
			return null
		var motion := InputEventJoypadMotion.new()
		motion.device = ALL_DEVICES
		motion.axis = int(parts[0])
		motion.axis_value = float(parts[1])
		return motion
	return null
