class_name PauseMenu
extends Control

## The pause screen: put the Reading down, pick it back up, or leave it.
##
## Resume, Save, Load, Settings, Quit - and nothing that belongs to another screen. The
## Almanack, the Spread and the map each open on their own action
## (`docs/design/technical.md` §Input actions), because `art-audio.md` §UI/UX pillars
## wants "menu navigation [that] moves like laying out a hand", not a menu tree.
##
## **It asks; it does not act.** Saving and loading are the composition root's
## (`Services.save_game` / `load_game`), and a menu that called them directly would be
## a menu holding a playthrough. So this emits, `UiShell` connects, and the persistent
## layer does the work - the same shape every other view in this folder has.

## How many slots the menu offers. Three is a placeholder: no doc fixes a number, and
## `SaveService` puts no ceiling on them.
const SLOT_COUNT := 3

## The player asked to go back to the game.
signal resume_requested()

## The player asked to write the playthrough to a slot.
signal save_requested(slot: int)

## The player asked to read a slot back.
signal load_requested(slot: int)

## The player asked to open the settings.
signal settings_requested()

## The player asked to leave.
signal quit_requested()

var _save: SaveService = null
var _save_rows: Array[Button] = []
var _load_rows: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


## Watch this save service, so the slot rows can say which are written. Null detaches.
func attach(save: SaveService) -> void:
	_save = save
	refresh()


## One save row, or null.
func save_row(slot: int) -> Button:
	if slot < 0 or slot >= _save_rows.size():
		return null
	return _save_rows[slot]


## One load row, or null. A row for a slot with nothing in it is disabled.
func load_row(slot: int) -> Button:
	if slot < 0 or slot >= _load_rows.size():
		return null
	return _load_rows[slot]


## Redraw the slot rows from what is on disk.
func refresh() -> void:
	for slot: int in range(_load_rows.size()):
		var written := _save != null and _save.slot_exists(slot)
		_load_rows[slot].disabled = not written
		_load_rows[slot].text = _slot_label(slot, written)
		_save_rows[slot].text = _slot_label(slot, written)


## A slot's row: "Slot 1", and whether anything is in it.
##
## The number is FORMATTED INTO the key's own row (`UI_SLOT_N` is "Slot {n}") rather
## than concatenated after it, so a language that puts the number first, or wraps it,
## or needs a different word order can say so in the CSV without touching this file.
## It is one-based because a player counts saves from one; `slot` stays zero-based
## everywhere else, because `SaveService` does.
func _slot_label(slot: int, written: bool) -> String:
	var line := TranslationServer.translate(UiKeys.SAVE_SLOT_N).format({"n": slot + 1})
	if not written:
		line += " %s" % TranslationServer.translate(UiKeys.SAVE_SLOT_EMPTY)
	return line


func _build() -> void:
	add_child(UiFrames.panel_frame())
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 64)
	margin.add_theme_constant_override(&"margin_right", 64)
	margin.add_theme_constant_override(&"margin_top", 52)
	margin.add_theme_constant_override(&"margin_bottom", 52)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)

	var title := Label.new()
	title.text = String(UiKeys.PAUSE_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var resume := Button.new()
	resume.text = String(UiKeys.PAUSE_RESUME)
	resume.pressed.connect(resume_requested.emit)
	column.add_child(resume)

	var save_title := Label.new()
	save_title.text = String(UiKeys.PAUSE_SAVE)
	column.add_child(save_title)
	for slot: int in range(SLOT_COUNT):
		var row := Button.new()
		# Its text is "Slot 1" and the like, built in `_slot_label` out of a key and a
		# number - see `UiKeys.COMPOSED_TEXT_META`.
		UiKeys.mark_composed(row, UiKeys.COMPOSED_FORMATTED)
		row.pressed.connect(save_requested.emit.bind(slot))
		column.add_child(row)
		_save_rows.append(row)

	var load_title := Label.new()
	load_title.text = String(UiKeys.PAUSE_LOAD)
	column.add_child(load_title)
	for slot: int in range(SLOT_COUNT):
		var row := Button.new()
		UiKeys.mark_composed(row, UiKeys.COMPOSED_FORMATTED)
		row.pressed.connect(load_requested.emit.bind(slot))
		column.add_child(row)
		_load_rows.append(row)

	var settings := Button.new()
	settings.text = String(UiKeys.PAUSE_SETTINGS)
	settings.pressed.connect(settings_requested.emit)
	column.add_child(settings)

	var back := Button.new()
	back.text = String(UiKeys.BACK)
	back.pressed.connect(resume_requested.emit)
	column.add_child(back)

	var quit := Button.new()
	quit.text = String(UiKeys.PAUSE_QUIT)
	quit.pressed.connect(quit_requested.emit)
	column.add_child(quit)

	refresh()
