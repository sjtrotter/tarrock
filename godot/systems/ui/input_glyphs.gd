class_name InputGlyphs
extends RefCounted

## What to draw on a prompt chip for an InputMap action: the key or the pad button
## the player would actually press.
##
## `docs/design/technical.md` §Port-readiness rules (Godot), 1: gameplay code reads
## named actions and never raw keycodes - so the ONE place a keycode is turned back
## into something a human reads is here, and it reads it out of the live `InputMap`.
## Rebind an action and the chip changes with it; nothing caches a glyph.
##
## **A device label is not prose.** A key's name ("E", "Space") and a pad button's
## label ("A", "LB") are hardware markings, printed the same in every language, and
## Godot's own `OS.get_keycode_string()` returns them untranslated for that reason.
## They are therefore NOT translation keys. The one string here a translator owns is
## the answer for an action nothing is bound to (`UiKeys.GLYPH_UNBOUND`).

## Pad button labels by `JoyButton` index, in Godot's own order. Short hardware
## markings, deliberately not CSV rows (see the class doc).
const PAD_BUTTONS: Array[String] = [
	"A",  # JOY_BUTTON_A
	"B",  # JOY_BUTTON_B
	"X",  # JOY_BUTTON_X
	"Y",  # JOY_BUTTON_Y
	"Back",  # JOY_BUTTON_BACK
	"Guide",  # JOY_BUTTON_GUIDE
	"Start",  # JOY_BUTTON_START
	"LS",  # JOY_BUTTON_LEFT_STICK
	"RS",  # JOY_BUTTON_RIGHT_STICK
	"LB",  # JOY_BUTTON_LEFT_SHOULDER
	"RB",  # JOY_BUTTON_RIGHT_SHOULDER
	"Up",  # JOY_BUTTON_DPAD_UP
	"Down",  # JOY_BUTTON_DPAD_DOWN
	"Left",  # JOY_BUTTON_DPAD_LEFT
	"Right",  # JOY_BUTTON_DPAD_RIGHT
]

## Stick and trigger labels by `JoyAxis` index.
const PAD_AXES: Array[String] = [
	"LX",  # JOY_AXIS_LEFT_X
	"LY",  # JOY_AXIS_LEFT_Y
	"RX",  # JOY_AXIS_RIGHT_X
	"RY",  # JOY_AXIS_RIGHT_Y
	"LT",  # JOY_AXIS_TRIGGER_LEFT
	"RT",  # JOY_AXIS_TRIGGER_RIGHT
]


## The keyboard glyph for an action - the first key event bound to it - or the
## translated "nothing is bound" mark when it has none.
static func keyboard(action_name: StringName) -> String:
	var event := first_key_event(action_name)
	if event == null:
		return tr_unbound()
	return label_for(event)


## The pad glyph for an action - the first joypad button or axis bound to it - or
## the translated "nothing is bound" mark.
static func pad(action_name: StringName) -> String:
	if not InputMap.has_action(action_name):
		return tr_unbound()
	for event: InputEvent in InputMap.action_get_events(action_name):
		var button := event as InputEventJoypadButton
		if button != null:
			return label_for(button)
		var motion := event as InputEventJoypadMotion
		if motion != null:
			return label_for(motion)
	return tr_unbound()


## The first `InputEventKey` bound to an action, or `null`.
static func first_key_event(action_name: StringName) -> InputEventKey:
	if not InputMap.has_action(action_name):
		return null
	for event: InputEvent in InputMap.action_get_events(action_name):
		var key := event as InputEventKey
		if key != null:
			return key
	return null


## The label for one event: a key's printed name, a pad button's marking, a stick or
## trigger's axis name. Unknown events fall back to the unbound mark rather than to
## Godot's debug spelling.
static func label_for(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		var code := key.physical_keycode if key.physical_keycode != 0 else key.keycode
		var name := OS.get_keycode_string(code)
		return tr_unbound() if name.is_empty() else name
	var button := event as InputEventJoypadButton
	if button != null:
		var index := int(button.button_index)
		if index >= 0 and index < PAD_BUTTONS.size():
			return PAD_BUTTONS[index]
		return tr_unbound()
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var axis := int(motion.axis)
		if axis >= 0 and axis < PAD_AXES.size():
			return PAD_AXES[axis]
		return tr_unbound()
	return tr_unbound()


## The mark shown where an action has nothing bound to it.
static func tr_unbound() -> String:
	return TranslationServer.translate(UiKeys.GLYPH_UNBOUND)
