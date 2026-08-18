class_name PromptChip
extends PanelContainer

## The marginal slip a prompt is written on: what to press, and what pressing it does.
##
## Round U1's prompt chip, used as it was drawn (`docs/gauntlet-ui/STATUS.md`: "the
## prompt chip is already usable"). `docs/design/art-audio.md` §UI/UX pillars, HUD
## restraint: everything that is not petals or Fortune "fades to unobtrusive when not
## in use" - so the chip has no idle state at all. It is shown for a prompt and it
## fades out when the prompt is taken away.
##
## The glyph is read live out of the `InputMap` (`InputGlyphs`), so a rebind changes
## the chip and nothing caches a keycode.

## How long the chip takes to fade in and out.
const FADE_SECONDS := 0.18

var _text_key: StringName = &""
var _action: StringName = &""
var _row: HBoxContainer = null
var _glyph: Label = null
var _label: Label = null
var _tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The chip IS the frame: a `PanelContainer` wearing U1's slip as a
	# `StyleBoxTexture`, so the slip is as tall as the line on it and a large text
	# size makes a bigger chip rather than a clipped one.
	add_theme_stylebox_override(
		&"panel", UiFrames.style_box(UiFrames.CHIP_TEXTURE, UiFrames.CHIP_MARGINS)
	)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_glyph = Label.new()
	# The key's own marking ("E", "Space"), not a line anybody translates.
	UiKeys.mark_composed(_glyph, UiKeys.COMPOSED_GLYPH)
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_glyph)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_label)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = false


## Show a prompt: a translation key, and optionally the action whose glyph goes on it.
func show_prompt(text_key: StringName, action_name: StringName = &"") -> void:
	_text_key = text_key
	_action = action_name
	if _label != null:
		_label.text = String(text_key)
	if _glyph != null:
		_glyph.text = "" if action_name == &"" else InputGlyphs.keyboard(action_name)
		_glyph.visible = action_name != &""
	visible = true
	_fade_to(1.0)


## Take the prompt away. The chip fades rather than blinking out.
func clear_prompt() -> void:
	_text_key = &""
	_action = &""
	_fade_to(0.0)


## The key the chip is showing, or `&""` when it shows nothing.
func text_key() -> StringName:
	return _text_key


## The action whose glyph the chip is showing, or `&""`.
func action_name() -> StringName:
	return _action


## The translated line on the chip. The `Label` itself holds the KEY - Godot
## translates a Control's text as it draws it, so a locale change redraws by itself -
## and this is the same line, resolved for a caller that wants to read it.
func prompt_text() -> String:
	if _text_key == &"":
		return ""
	return TranslationServer.translate(_text_key)


## The glyph drawn beside it, or "" when the chip names no action.
func glyph_text() -> String:
	return "" if _glyph == null else _glyph.text


## True while a prompt is up (asked for, and not cleared).
func is_showing() -> bool:
	return _text_key != &""


## Skip the fade. Tests and a region change both want the chip's real state now.
func settle() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	var target := 1.0 if is_showing() else 0.0
	modulate = Color(1.0, 1.0, 1.0, target)
	visible = target > 0.0


func _fade_to(alpha: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		settle()
		return
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", alpha, FADE_SECONDS)
	if alpha <= 0.0:
		_tween.tween_callback(func() -> void: visible = false)
