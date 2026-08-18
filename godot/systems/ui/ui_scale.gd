class_name UiScale
extends RefCounted

## Applies the player's text-size setting to the one UI theme.
##
## `docs/design/art-audio.md` §Accessibility notes: "Scalable text size across all
## UI, including the Almanack's manuscript styling (which must degrade gracefully at
## large sizes rather than break its frame art)." Two halves, and this class is the
## first: it multiplies every font size in the theme by the setting. The second half
## is a layout rule every framed view obeys - the frame is a `NinePatchRect` behind a
## container with margins, so the frame GROWS with the text it holds instead of
## clipping it, which is what `res://tests/unit/ui/ui_scale_test.gd` proves.
##
## The base sizes are read once from the theme as authored, so scaling is never
## applied on top of itself.

## The theme every view uses.
const THEME_PATH := "res://art/ui/theme.tres"

## Theme types whose `font_size` is scaled. A type with no font size of its own
## inherits `default_font_size`, which is scaled too.
const SCALED_TYPES: Array[StringName] = [
	&"Button",
	&"Label",
	&"OptionButton",
	&"RichTextLabel",
]

## The font-size item on each of those types. `RichTextLabel` names its own.
const FONT_SIZE_ITEMS: Dictionary = {
	&"Button": &"font_size",
	&"Label": &"font_size",
	&"OptionButton": &"font_size",
	&"RichTextLabel": &"normal_font_size",
}

var _theme: Theme = null
var _base_default: int = 0
var _base_sizes: Dictionary = {}
var _scale: float = 1.0


func _init(theme: Theme = null) -> void:
	_theme = theme if theme != null else load(THEME_PATH) as Theme
	if _theme == null:
		return
	_base_default = _theme.default_font_size
	for type_name: StringName in SCALED_TYPES:
		var item: StringName = FONT_SIZE_ITEMS[type_name]
		if _theme.has_font_size(item, type_name):
			_base_sizes[type_name] = _theme.get_font_size(item, type_name)


## The theme being scaled.
func theme() -> Theme:
	return _theme


## The scale currently applied.
func scale() -> float:
	return _scale


## The theme's default font size as authored, before any scaling.
func base_default_font_size() -> int:
	return _base_default


## Scale every font size in the theme. Always computed from the authored sizes, so
## calling this twice with the same value is the same as calling it once.
func apply(new_scale: float) -> void:
	if _theme == null:
		return
	_scale = clampf(new_scale, UiSettings.MIN_TEXT_SCALE, UiSettings.MAX_TEXT_SCALE)
	_theme.default_font_size = maxi(1, int(roundf(float(_base_default) * _scale)))
	for type_name: StringName in SCALED_TYPES:
		if not _base_sizes.has(type_name):
			continue
		var item: StringName = FONT_SIZE_ITEMS[type_name]
		var base: int = _base_sizes[type_name]
		_theme.set_font_size(item, type_name, maxi(1, int(roundf(float(base) * _scale))))
