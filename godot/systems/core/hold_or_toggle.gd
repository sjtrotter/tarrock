class_name HoldOrToggle
extends RefCounted

## One held input, in whichever way the player asked for it.
##
## `docs/design/combat.md` §Accessibility: "Hold/toggle options for held inputs
## (block-step, charged heavy, sprint)" - and Focus, which the 2D amendment made a
## held stance. Rather than every one of those growing its own `if toggle_mode`
## branch, each owns one of these: the caller feeds it the raw button state every
## frame and reads back the EFFECTIVE held state, and nothing downstream (the moveset
## controller least of all) ever learns which mode the player is on.
##
## `HOLD` answers the button. `TOGGLE` flips on each press - the rising edge - and
## holds that answer until the next press. Switching mode mid-play releases the latch
## rather than stranding an input that is on with nothing holding it.
##
## Where the mode is STORED is the settings round's question, not this class's: this
## is the mechanism, `FoolCombat` wires one per action, and a settings screen calls
## `set_mode`.

## How a held input behaves.
enum Mode {
	## The input is on while the button is down. The default.
	HOLD,
	## Each press flips the input on or off.
	TOGGLE,
}

## Every mode, for a settings screen to enumerate.
const ALL_MODES: Array[Mode] = [Mode.HOLD, Mode.TOGGLE]

## The stable key naming each mode, indexed by `Mode`. Never displayed.
const NAME_KEYS: Array[StringName] = [&"HOLD", &"TOGGLE"]

## The effective state changed. `held` is what `update()` now answers.
signal changed(held: bool)

var _mode: Mode = Mode.HOLD
var _held: bool = false
var _button_was_down: bool = false


## Build one, in a mode.
func _init(mode: Mode = Mode.HOLD) -> void:
	_mode = mode


## Feed this frame's raw button state; get back the effective held state.
##
## Called once per frame per action, and it allocates nothing: the accessibility
## layer sits directly on the combat loop (`docs/design/technical.md` §Performance
## guardrails).
func update(pressed_now: bool) -> bool:
	var pressed_edge := pressed_now and not _button_was_down
	_button_was_down = pressed_now
	var next := _held
	if _mode == Mode.TOGGLE:
		if pressed_edge:
			next = not _held
	else:
		next = pressed_now
	if next != _held:
		_held = next
		changed.emit(_held)
	return _held


## The effective held state, without feeding a frame.
func is_held() -> bool:
	return _held


## The mode this input is in.
func mode() -> Mode:
	return _mode


## Change the mode. A latched toggle is released on the way out, so the player never
## ends up with an input stuck on and no button holding it.
func set_mode(new_mode: Mode) -> void:
	if new_mode == _mode:
		return
	_mode = new_mode
	_button_was_down = false
	if _held:
		_held = false
		changed.emit(false)


## The stable key naming a mode. `&""` for a mode out of range.
static func name_key(mode_id: Mode) -> StringName:
	if mode_id < 0 or mode_id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[mode_id]


## Drop the latch and forget the button, without changing the mode. Used when a
## scene loads or a fight ends.
func reset() -> void:
	_button_was_down = false
	if _held:
		_held = false
		changed.emit(false)
