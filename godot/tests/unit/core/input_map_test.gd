extends TarrockTest

## The InputMap contract.
##
## Gameplay code reads named actions from `InputActions` and never raw keys
## (docs/gauntlet-systems/PROMPT.md, standing decision 7). These tests fail if an
## action named in code has no binding, if a binding was dropped from
## `project.godot`, if `project.godot` grew an action nobody named in code, or if
## two gameplay actions were bound to the same physical input.

## Actions that must be reachable without a gamepad.
const KEYBOARD_REQUIRED: Array[StringName] = InputActions.ALL

## Actions that must also be reachable on a controller.
const GAMEPAD_REQUIRED: Array[StringName] = InputActions.ALL


func test_every_named_action_exists() -> void:
	for action: StringName in InputActions.ALL:
		assert_true(InputMap.has_action(action), "InputMap is missing action '%s'" % action)


func test_every_named_action_has_an_event() -> void:
	for action: StringName in InputActions.ALL:
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		assert_true(events.size() >= 1, "action '%s' has no bound event" % action)


func test_every_action_has_a_keyboard_binding() -> void:
	for action: StringName in KEYBOARD_REQUIRED:
		if not InputMap.has_action(action):
			continue
		var has_key := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				has_key = true
		assert_true(has_key, "action '%s' has no keyboard binding" % action)


func test_every_action_has_a_gamepad_binding() -> void:
	for action: StringName in GAMEPAD_REQUIRED:
		if not InputMap.has_action(action):
			continue
		var has_pad := false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_pad = true
		assert_true(has_pad, "action '%s' has no gamepad binding" % action)


func test_keyboard_bindings_use_physical_keycodes() -> void:
	# Bindings by `keycode` follow the OS layout and silently move on AZERTY;
	# `physical_keycode` keeps WASD where the fingers are. This bit the arrow-key
	# bindings once already.
	for action: StringName in InputActions.ALL:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			var key := event as InputEventKey
			if key == null:
				continue
			assert_true(
				key.physical_keycode != 0,
				"action '%s' has a keyboard event bound by keycode, not physical_keycode" % action
			)


func test_bindings_are_device_agnostic() -> void:
	for action: StringName in InputActions.ALL:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			assert_eq(
				event.device, -1, "action '%s' is bound to a specific device" % action
			)


func test_the_focus_stance_has_both_of_its_inputs() -> void:
	# combat.md §Focus is a HELD stance with more than one enemy in it: holding the
	# lock and stepping it round the candidates are two inputs, and the second one is
	# useless if it shares a button with the first.
	for action: StringName in [InputActions.FOCUS, InputActions.FOCUS_CYCLE]:
		assert_true(InputMap.has_action(action), "Focus action '%s' missing" % action)
	var focus_signatures := PackedStringArray()
	for event: InputEvent in InputMap.action_get_events(InputActions.FOCUS):
		focus_signatures.append(_event_signature(event))
	for event: InputEvent in InputMap.action_get_events(InputActions.FOCUS_CYCLE):
		assert_false(
			focus_signatures.has(_event_signature(event)),
			"cycling Focus is bound to the same input as holding it"
		)


func test_there_is_no_button_for_the_white_rose() -> void:
	# The director's ruling on issue #11: the petals ARE the Fool's health, so there is
	# nothing to press - a hit costs petals and the Rose grows back on its own and at a
	# Waystation. The action, its bindings and R itself are all free, and a round that
	# quietly reintroduces a heal button fails here first.
	assert_false(InputMap.has_action(&"rose"), "project.godot still binds a `rose` action")
	assert_false(InputActions.ALL.has(&"rose"), "InputActions still names one")
	for action: StringName in InputActions.ALL:
		for event: InputEvent in InputMap.action_get_events(action):
			var key := event as InputEventKey
			assert_true(
				key == null or key.physical_keycode != KEY_R,
				"action '%s' took R, which the Rose's removal was meant to leave free" % action
			)


func test_movement_resolves_as_a_vector() -> void:
	# The four movement actions are exactly what `Input.get_vector` needs; if any
	# of them is missing this call is the thing that breaks in the player.
	for action: StringName in [
		InputActions.MOVE_LEFT,
		InputActions.MOVE_RIGHT,
		InputActions.MOVE_UP,
		InputActions.MOVE_DOWN,
	]:
		assert_true(InputMap.has_action(action), "movement action '%s' missing" % action)
	assert_eq(
		Input.get_vector(
			InputActions.MOVE_LEFT,
			InputActions.MOVE_RIGHT,
			InputActions.MOVE_UP,
			InputActions.MOVE_DOWN
		),
		Vector2.ZERO,
		"no input held in a headless test"
	)


func test_gameplay_code_does_not_read_ui_actions() -> void:
	# `ui_*` belongs to Godot's focus/menu system. Gameplay reading it is how
	# rebinding quietly stops working. `res://tools` is swept too: a capture or
	# spike tool driving the game by `ui_*` is the same leak, and it is the kind of
	# script that gets copied into a real scene later.
	var offenders := PackedStringArray()
	for path: String in (
		_gdscripts_under("res://scripts")
		+ _gdscripts_under("res://systems")
		+ _gdscripts_under("res://tools")
	):
		var text := FileAccess.get_file_as_string(path)
		if text.contains('"ui_') or text.contains("&\"ui_"):
			offenders.append(path)
	assert_eq(offenders.size(), 0, "gameplay scripts referencing ui_* actions: %s" % str(offenders))


func test_no_project_action_is_missing_from_input_actions() -> void:
	# The other direction of `test_every_named_action_exists`: an action added in
	# the editor and never written down in `InputActions` is unreachable from
	# gameplay code and invisible to a rebinding screen. `ui_*` is Godot's own and
	# is deliberately absent from `InputActions`.
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		assert_true(
			InputActions.ALL.has(action),
			"action '%s' exists in project.godot but not in InputActions" % action
		)


func test_no_two_gameplay_actions_share_an_event() -> void:
	# Two actions on one key is a silent double-fire: the player presses J and both
	# swings the Bindle and opens the Almanack. The signature ignores the action it
	# came from, so a clash names both sides.
	var owners: Dictionary = {}
	for action: StringName in InputActions.ALL:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			var signature := _event_signature(event)
			if signature.is_empty():
				continue
			if owners.has(signature):
				fail(
					"actions '%s' and '%s' share the same input (%s)"
					% [owners[signature], action, signature]
				)
				continue
			owners[signature] = action


## How one bound event is identified for duplicate detection: the physical input it
## occupies. Keys are compared by `physical_keycode` plus modifiers (Shift+A is not
## A); joypad axes by axis and direction, because half an axis is one binding.
## An event shape with no signature (an unknown event type) returns "".
func _event_signature(event: InputEvent) -> String:
	var key := event as InputEventKey
	if key != null:
		return (
			"key:%d:%s%s%s%s"
			% [
				key.physical_keycode,
				"a" if key.alt_pressed else "-",
				"s" if key.shift_pressed else "-",
				"c" if key.ctrl_pressed else "-",
				"m" if key.meta_pressed else "-",
			]
		)
	var button := event as InputEventJoypadButton
	if button != null:
		return "pad_button:%d" % button.button_index
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return "pad_axis:%d:%s" % [motion.axis, "+" if motion.axis_value > 0.0 else "-"]
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return "mouse_button:%d" % mouse.button_index
	return ""


func _gdscripts_under(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child := dir_path.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_gdscripts_under(child))
		elif entry.ends_with(".gd"):
			found.append(child)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
