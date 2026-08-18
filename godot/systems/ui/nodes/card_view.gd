class_name CardView
extends Control

## One card on the table: face-down, face-up, upright or reversed.
##
## The single card control the whole shell reuses - the map's 22 regions
## (`docs/design/art-audio.md` §Map: "cards dealt face-down on a table; unbinding an
## Arcanum turns that region's card face-up"), the Pocket Spread's three slots
## (`docs/design/progression.md`: the slots "are rendered as an actual three-card
## spread, not an ability-bar reskin"), and the Almanack's collected Trumps.
##
## **The illustrations do not exist yet.** `art-audio.md` §Card art asks for 22
## full-frame illustrated cards, each with a distinct reversed treatment and a
## bound-state variant; until they are drawn, a card is its gold-framed parchment with
## the name and the printed number lettered on it, and a reversed card is drawn turned
## about - which is what a reversed card in a spread physically IS, and what the
## finished art will replace rather than contradict. See `res://art/ui/README.md`.

## The card's size in the base viewport. Containers scale it; nothing positions it.
const CARD_SIZE := Vector2(120.0, 192.0)

## How much of the card the face art occupies once there is any.
const REVERSED_ROTATION := PI

var _face: TextureRect = null
var _name_label: Label = null
var _number_label: Label = null
var _face_up: bool = false
var _reversed: bool = false
var _name_key: StringName = &""
var _number: int = 0
var _highlight: ColorRect = null


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	_highlight = ColorRect.new()
	_highlight.color = UiFrames.PALE_GOLD
	_highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.visible = false
	add_child(_highlight)
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_number_label = Label.new()
	# The card's printed number - a numeral the deck prints, not a line
	# (`UiKeys.COMPOSED_TEXT_META`).
	UiKeys.mark_composed(_number_label, UiKeys.COMPOSED_NUMBER)
	_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_number_label)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_name_label)
	_refresh()


## Turn the card face-up or face-down.
func set_face_up(face_up: bool) -> void:
	_face_up = face_up
	_refresh()


## True when the card is face-up.
func is_face_up() -> bool:
	return _face_up


## Draw the card the other way about - a reversed slotting
## (`docs/design/progression.md`: reversed is stronger, and carries a burden).
func set_reversed(reversed: bool) -> void:
	_reversed = reversed
	_refresh()


## True when the card is drawn reversed.
func is_reversed() -> bool:
	return _reversed


## Letter a name on the card. A translation key, never a name.
func set_name_key(name_key: StringName) -> void:
	_name_key = name_key
	_refresh()


## The key lettered on the card, or `&""`.
func name_key() -> StringName:
	return _name_key


## Letter the card's printed number on it. Zero prints nothing - the Fool's own card
## is numbered zero and the Cliff has no Arcanum at all.
func set_number(number: int) -> void:
	_number = number
	_refresh()


## The printed number, or 0.
func number() -> int:
	return _number


## Mark this card as the one the Fool is standing in.
func set_highlighted(highlighted: bool) -> void:
	if _highlight != null:
		_highlight.visible = highlighted


## True while the card is marked.
func is_highlighted() -> bool:
	return _highlight != null and _highlight.visible


func _refresh() -> void:
	if _face == null:
		return
	var path := UiFrames.CARD_FACE_TEXTURE if _face_up else UiFrames.CARD_BACK_TEXTURE
	_face.texture = load(path) as Texture2D
	_name_label.text = String(_name_key) if _face_up else ""
	_number_label.text = str(_number) if _face_up and _number > 0 else ""
	pivot_offset = size * 0.5
	rotation = REVERSED_ROTATION if _face_up and _reversed else 0.0
