extends TarrockTest

## What a prompt chip draws for an action, read live out of the `InputMap`.
##
## `docs/design/technical.md` §Port-readiness rules (Godot), 1: gameplay code reads
## named actions and never raw keycodes. That makes ONE place responsible for turning a
## binding back into something a human reads, and this is the suite that holds it to
## reading the live map rather than a table somebody typed - because a rebind that did
## not change the chip would be a prompt telling the player to press the wrong key.

## A key nothing is bound to by default.
const SPARE_KEYCODE := KEY_F10

var _bindings_before: Array[InputEvent] = []


func before_each() -> void:
	TranslationServer.set_locale("en")
	_bindings_before = InputMap.action_get_events(InputActions.INTERACT)


func after_each() -> void:
	InputMap.action_erase_events(InputActions.INTERACT)
	for event: InputEvent in _bindings_before:
		InputMap.action_add_event(InputActions.INTERACT, event)


func test_every_action_the_docs_list_has_a_glyph() -> void:
	var unbound := PackedStringArray()
	for action_name: StringName in InputActions.ALL:
		if InputGlyphs.keyboard(action_name) == InputGlyphs.tr_unbound():
			unbound.append(String(action_name))
	assert_eq(unbound.size(), 0, "these actions draw no key on a chip: %s" % str(unbound))


func test_the_glyph_follows_a_rebind() -> void:
	var before := InputGlyphs.keyboard(InputActions.INTERACT)
	var event := InputEventKey.new()
	event.physical_keycode = SPARE_KEYCODE
	InputMap.action_erase_events(InputActions.INTERACT)
	InputMap.action_add_event(InputActions.INTERACT, event)
	var after := InputGlyphs.keyboard(InputActions.INTERACT)
	assert_ne(after, before, "a rebind must change the chip")
	assert_eq(after, OS.get_keycode_string(SPARE_KEYCODE))


func test_an_action_nothing_is_bound_to_draws_the_translated_mark() -> void:
	assert_eq(InputGlyphs.keyboard(&"not_an_action"), InputGlyphs.tr_unbound())
	assert_eq(InputGlyphs.tr_unbound(), TranslationServer.translate(UiKeys.GLYPH_UNBOUND))
	assert_ne(InputGlyphs.tr_unbound(), String(UiKeys.GLYPH_UNBOUND), "the mark has a row")


func test_a_pad_binding_draws_the_button_marking() -> void:
	# `interact` is authored with joypad button 0 beside its key.
	assert_eq(InputGlyphs.pad(InputActions.INTERACT), InputGlyphs.PAD_BUTTONS[0])
	# `focus` is a trigger axis in project.godot, so it draws an axis marking.
	assert_eq(InputGlyphs.pad(InputActions.FOCUS), InputGlyphs.PAD_AXES[JOY_AXIS_TRIGGER_LEFT])


func test_an_event_kind_nothing_binds_falls_back_rather_than_printing_debug_text() -> void:
	assert_eq(InputGlyphs.label_for(InputEventMouseButton.new()), InputGlyphs.tr_unbound())
	var out_of_range := InputEventJoypadButton.new()
	out_of_range.button_index = 99
	assert_eq(InputGlyphs.label_for(out_of_range), InputGlyphs.tr_unbound())
