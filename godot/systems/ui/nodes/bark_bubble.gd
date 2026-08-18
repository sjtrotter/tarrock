class_name BarkBubble
extends Control

## One floating line over somebody's head, for a few seconds.
##
## `docs/design/npc-system.md` is the whole owner of WHICH line gets said and WHEN;
## `BarkService.request()` picks it and hands back a `BarkPick` with a `text_key`. This
## is only the parchment slip that line appears on - a small chip above an NPC, gone
## again shortly, with no interaction of any kind. A bark is never a conversation:
## conversations are `DialogueFrame`'s, and they have a speaker plate and options.
##
## It follows a node in world space rather than being parented to one, so a bubble
## outlives the frame its speaker is culled in and nothing in a region scene has to
## know a UI class exists (`technical.md` §Architecture principles (Godot), 5).

## How long a bark hangs before it fades, in seconds.
const DEFAULT_SECONDS := 3.5

## How long the fade itself takes.
const FADE_SECONDS := 0.4

## How far above the speaker's origin the slip floats, in world pixels.
const LIFT := Vector2(0.0, -96.0)

var _speaker: Node2D = null
var _label: Label = null
var _text_key: StringName = &""
var _seconds_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(260.0, 64.0)
	add_child(UiFrames.chip_frame())
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_seconds_left -= delta
	if _seconds_left <= 0.0:
		clear_bark()
		return
	_follow()


## Say one line over a speaker for `seconds`. A second bark replaces the first.
func say(text_key: StringName, speaker: Node2D = null, seconds: float = DEFAULT_SECONDS) -> void:
	_text_key = text_key
	_speaker = speaker
	_seconds_left = maxf(0.0, seconds)
	if _label != null:
		_label.text = String(text_key)
	visible = _seconds_left > 0.0
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	set_process(visible)
	_follow()


## Take the bark away.
func clear_bark() -> void:
	_text_key = &""
	_speaker = null
	_seconds_left = 0.0
	visible = false
	set_process(false)
	if _label != null:
		_label.text = ""


## The key on the slip, or `&""` when nothing is being said.
func text_key() -> StringName:
	return _text_key


## The line, translated.
func bark_text() -> String:
	if _text_key == &"":
		return ""
	return TranslationServer.translate(_text_key)


## Who is speaking, or null for a bark with no body behind it.
func speaker() -> Node2D:
	return _speaker


## How long this bark has left, in seconds.
func seconds_left() -> float:
	return _seconds_left


## Put the slip over its speaker's head. A bark with no speaker stays where it is put.
func _follow() -> void:
	if _speaker == null or not is_instance_valid(_speaker) or not is_inside_tree():
		return
	var canvas := _speaker.get_global_transform_with_canvas()
	position = canvas.origin + LIFT - size * Vector2(0.5, 1.0)
