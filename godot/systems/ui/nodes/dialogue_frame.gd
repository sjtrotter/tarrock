class_name DialogueFrame
extends Control

## The conversation, on parchment: who is speaking, what they said, and what the Fool
## may say back.
##
## Round U1's dialogue frame, used as drawn (`docs/gauntlet-ui/concepts/dialogue-a.svg`
## with the placeholder copy stripped - see `res://art/ui/README.md`). The name plate
## is the concept's gilded cartouche; U2 softens it further, and nothing here depends
## on which ornament it ends up wearing.
##
## **It is not a screen.** `docs/design/art-audio.md` §UI/UX pillars: "interactions and
## dialogue are framed in-world by a slight camera adjustment - an easing zoom into the
## shared space between the participants - rather than a cut to a separate dialogue
## screen ... No hard lock: the player keeps control and the frame releases as they move
## off." So this is a panel anchored to the bottom of the safe area, the world keeps
## running behind it, `UiState` is never told a menu opened, and the zoom is asked of
## `CameraFraming`, which lets go by itself.
##
## The Fool's options are `docs/design/narrative.md`'s choice table rows: an exhausted
## row is greyed rather than removed, because a table the player has been through is
## part of what they know they have asked.

## Where the frame sits and how tall it is, as a fraction of the safe area.
const FRAME_HEIGHT_RATIO := 0.34

## The node id the speaker-node provider is asked for when the voice on the plate has
## no body in the world: Pip's.
##
## **It is not a speaker id and never will be.** `docs/design/characters.md` §Pip:
## "Never speaks, never explained", so `Speakers` has no id for him. This is a NODE
## id - who to point the camera at - and the Querent is exactly the case that needs
## one: `art-audio.md` §UI/UX pillars frames "the shared space between the
## participants (the Fool and Pip especially)", and the Querent is a voice with no
## participant of his own, so the pair on screen is the Fool and his dog.
const PIP_NODE := &"PIP_NODE"

## What the shell hands over so this panel can find a body for a speaker:
## `func(node_id: StringName) -> Node2D`, answering `Speakers.*` ids, `PIP_NODE`, and
## null for anybody the world has no node for. The panel never walks the scene itself
## - the persistent layer owns the Fool and Pip, a region scene owns its NPCs, and
## `technical.md` §Architecture principles (Godot), 5 keeps this folder from reaching
## into either.
var _speaker_nodes: Callable = Callable()

var _dialogue: DialogueService = null
var _framing: CameraFraming = null
var _name_label: Label = null
var _line_label: RichTextLabel = null
var _options: VBoxContainer = null
var _leave: Button = null
var _caret: TextureRect = null
var _option_buttons: Array[Button] = []

## True while this panel is the one holding the conversational frame, so it releases
## exactly what it took and re-frames only when a conversation begins - not on every
## line, which would grab the camera back from a player who walked out of the frame.
var _engaged: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_build()
	visible = false


## Watch this conversation runner. Null detaches.
func attach(dialogue: DialogueService, framing: CameraFraming = null) -> void:
	_framing = framing
	if _dialogue == dialogue:
		return
	# A new runner is a new conversation; whatever frame the old one took is given
	# back before this panel starts drawing somebody else's.
	_release_framing()
	_disconnect()
	_dialogue = dialogue
	_connect()
	_refresh()


## The runner being drawn, or null.
func dialogue() -> DialogueService:
	return _dialogue


## Hand the panel the way to find a speaker's body in the world. See `_speaker_nodes`.
func set_speaker_node_provider(provider: Callable) -> void:
	_speaker_nodes = provider


## The provider, or an empty `Callable` when nobody set one.
func speaker_node_provider() -> Callable:
	return _speaker_nodes


## True while this panel is holding the conversational camera frame.
func is_framing() -> bool:
	return _engaged and _framing != null and _framing.is_framing()


## The speaker's name key on the plate, or `&""` when nothing is on screen.
func speaker_key() -> StringName:
	if _name_label == null or _name_label.text.is_empty():
		return &""
	return StringName(_name_label.text)


## The key of the line on the parchment, or `&""`.
func line_key() -> StringName:
	if _line_label == null or _line_label.text.is_empty():
		return &""
	return StringName(_line_label.text)


## How many of the Fool's options are drawn.
func option_count() -> int:
	return _option_buttons.size()


## One option row, or null.
func option_button(index: int) -> Button:
	if index < 0 or index >= _option_buttons.size():
		return null
	return _option_buttons[index]


## True when that row is drawn greyed - an exhaustible table's row already taken.
func is_option_used(index: int) -> bool:
	var button := option_button(index)
	return button != null and button.disabled


## How much room the panel's CONTENTS ask for at the current text size. The frame
## itself is a full-rect `NinePatchRect`, so it has no minimum of its own - this is
## the number that has to grow when the text does, and the reason large text does not
## break the frame art (`art-audio.md` §Accessibility notes).
func content_minimum_size() -> Vector2:
	var margin := get_node_or_null(^"MarginContainer") as MarginContainer
	if margin == null:
		for child: Node in get_children():
			var found := child as MarginContainer
			if found != null:
				return found.get_combined_minimum_size()
		return Vector2.ZERO
	return margin.get_combined_minimum_size()


## The "…" row: leaving a table of questions with questions left unasked.
func leave_button() -> Button:
	return _leave


## True while the "…" row is offered - only on an exhaustible table
## (`docs/design/narrative.md`: *(all questions may be exhausted)*).
func is_leave_offered() -> bool:
	return _leave != null and _leave.visible


## Move the conversation on: past a line, or nowhere at all on a choice table.
func advance() -> void:
	if _dialogue != null:
		_dialogue.advance()


## Take one of the Fool's options.
func choose(index: int) -> bool:
	return false if _dialogue == null else _dialogue.choose(index)


## Leave a table of questions.
func leave() -> bool:
	return false if _dialogue == null else _dialogue.leave()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _dialogue == null or not _dialogue.is_active():
		return
	var view := _dialogue.current()
	if view != null and view.is_choice():
		return
	# `interact` and nothing else: the action list in `technical.md` §Input actions is
	# what gameplay reads, and Godot's own focus actions are the menu system's. A
	# choice row is a `Button` and answers to focus navigation by itself.
	if event.is_action_pressed(InputActions.INTERACT):
		advance()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var frame := UiFrames.dialogue_frame()
	add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 120)
	margin.add_theme_constant_override(&"margin_right", 120)
	margin.add_theme_constant_override(&"margin_top", 46)
	margin.add_theme_constant_override(&"margin_bottom", 46)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	margin.add_child(column)

	var plate_row := HBoxContainer.new()
	column.add_child(plate_row)
	# A PanelContainer, not a fixed box: the cartouche is as big as the name in it,
	# at whatever text size the player chose.
	var plate := UiFrames.name_plate()
	plate.custom_minimum_size = Vector2(300.0, 0.0)
	plate_row.add_child(plate)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.add_child(_name_label)

	_line_label = RichTextLabel.new()
	_line_label.bbcode_enabled = false
	_line_label.fit_content = true
	_line_label.scroll_active = false
	_line_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_line_label)

	_options = VBoxContainer.new()
	_options.add_theme_constant_override(&"separation", 4)
	column.add_child(_options)

	_leave = Button.new()
	_leave.text = String(UiKeys.DIALOGUE_LEAVE)
	_leave.visible = false
	_leave.pressed.connect(_on_leave_pressed)
	_options.add_child(_leave)

	var caret_row := HBoxContainer.new()
	caret_row.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(caret_row)
	_caret = TextureRect.new()
	_caret.texture = load(UiFrames.CARET_TEXTURE) as Texture2D
	_caret.custom_minimum_size = Vector2(20.0, 20.0)
	_caret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	caret_row.add_child(_caret)


func _connect() -> void:
	if _dialogue == null:
		return
	_dialogue.node_presented.connect(_on_node_presented)
	_dialogue.dialogue_ended.connect(_on_dialogue_ended)


func _disconnect() -> void:
	if _dialogue == null:
		return
	if _dialogue.node_presented.is_connected(_on_node_presented):
		_dialogue.node_presented.disconnect(_on_node_presented)
	if _dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
		_dialogue.dialogue_ended.disconnect(_on_dialogue_ended)


func _on_node_presented(_view: DialogueView) -> void:
	_refresh()


func _on_dialogue_ended(_graph_id: StringName) -> void:
	_refresh()
	_release_framing()


## Take the conversational frame: an easing zoom into the space between the Fool and
## whoever is talking to him (`art-audio.md` §UI/UX pillars). Never a lock - the
## easing is `CameraFraming`'s, and it lets go by itself when the player walks off.
func _engage_framing(view: DialogueView) -> void:
	if _framing == null or _engaged:
		return
	var fool := _node_for(Speakers.FOOL)
	var other := _node_for(_speaker_of(view))
	if other == null:
		# The Querent, a choice table (the Fool's own lines), or a named speaker this
		# scene gave no body: the pair falls back to the Fool and Pip, and to the Fool
		# alone where there is no dog to hand.
		other = _node_for(PIP_NODE)
	if fool == null and other == null:
		return
	_engaged = _framing.frame_conversation(fool, other)


## Give the frame back. The camera eases home; nothing snaps.
func _release_framing() -> void:
	if _framing != null and _engaged:
		_framing.release()
	_engaged = false


## Whose body to look for, or `&""` for a view nobody in the world speaks: a choice
## table is the Fool's own lines, and the Querent is a voice with no body at all
## (`docs/design/characters.md` §The Querent).
func _speaker_of(view: DialogueView) -> StringName:
	if view == null:
		return &""
	if view.speaker == Speakers.QUERENT or view.speaker == Speakers.FOOL:
		return &""
	return view.speaker


## The body of one speaker, through the provider the shell set. Null when nobody set
## one, when the provider answers nothing, or when what came back is not a `Node2D`.
func _node_for(node_id: StringName) -> Node2D:
	if node_id == &"" or not _speaker_nodes.is_valid():
		return null
	return _speaker_nodes.call(node_id) as Node2D


func _on_leave_pressed() -> void:
	leave()


func _on_option_pressed(index: int) -> void:
	choose(index)


## Draw whatever is on screen now - or nothing, and get out of the way.
func _refresh() -> void:
	var view: DialogueView = null if _dialogue == null else _dialogue.current()
	if view == null:
		visible = false
		_clear_options()
		if _name_label != null:
			_name_label.text = ""
		if _line_label != null:
			_line_label.text = ""
		_release_framing()
		return
	visible = true
	# The conversation just came on screen, so the camera comes in with it - once,
	# not once per line. See `_engage_framing`.
	_engage_framing(view)
	_name_label.text = String(view.speaker_name_key())
	_line_label.text = String(view.text_key)
	_clear_options()
	if view.is_choice():
		for index: int in range(view.options.size()):
			var option := view.options[index]
			var button := Button.new()
			button.text = String(option.text_key)
			button.disabled = option.is_used
			button.pressed.connect(_on_option_pressed.bind(index))
			_options.add_child(button)
			_option_buttons.append(button)
	# The "…" row is always the last one offered: it is the way out of the table,
	# not one of the things the Fool has to say.
	_options.move_child(_leave, _options.get_child_count() - 1)
	_leave.visible = _dialogue != null and _dialogue.can_leave()
	_caret.visible = not view.is_choice()


func _clear_options() -> void:
	for button: Button in _option_buttons:
		_options.remove_child(button)
		button.queue_free()
	_option_buttons.clear()
	if _leave != null:
		_leave.visible = false
