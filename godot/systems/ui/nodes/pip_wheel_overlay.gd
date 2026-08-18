class_name PipWheelOverlay
extends Control

## Pip's command wheel while the player holds it open: three sectors, one lit.
##
## `docs/design/combat.md` §Pip gives the wheel its three commands - Fetch, Harry,
## Seek - and `systems/pip/README.md` says outright that drawing it is this round's,
## against the read-only frame `PipWheelView` hands over. Nothing here writes to the
## wheel: it is held open, aimed and released by `PipCompanion` and the input map, and
## this only shows what that frame says.
##
## **It reads the view every frame, and that is deliberate.** A radial wheel's lit
## sector follows the stick, which is a per-frame fact with no signal to hang on;
## `PipWheelView` exists precisely so that read costs no allocation
## (`systems/pip/pip_wheel_view.gd`: "refilled, never reallocated"). Processing is off
## whenever nothing is attached, so a closed wheel costs nothing at all.

## How far from the centre a sector's label sits, as a fraction of the overlay.
const SECTOR_RADIUS := 0.16

## How faint a command Pip cannot obey right now is drawn.
const UNAVAILABLE_ALPHA := 0.35

var _companion: PipCompanion = null
var _labels: Array[Label] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	visible = false
	set_process(false)


func _process(_delta: float) -> void:
	refresh()


## Watch this dog's wheel. Null detaches and stops processing.
func attach(companion: PipCompanion) -> void:
	_companion = companion
	set_process(_companion != null)
	refresh()


## The companion being watched, or null.
func companion() -> PipCompanion:
	return _companion


## The frame currently being drawn, or null.
func view() -> PipWheelView:
	return null if _companion == null else _companion.wheel_view()


## The lit sector, or `PipCommand.NONE`.
func highlighted() -> int:
	var frame := view()
	return PipCommand.NONE if frame == null else frame.highlighted()


## One sector's label, or null.
func sector_label(command: int) -> Label:
	if command < 0 or command >= _labels.size():
		return null
	return _labels[command]


## True while that sector is drawn as one Pip could obey.
func is_sector_available(command: int) -> bool:
	var label := sector_label(command)
	return label != null and label.modulate.a > UNAVAILABLE_ALPHA


## Redraw from the view.
func refresh() -> void:
	var frame := view()
	visible = frame != null and frame.is_open()
	if frame == null:
		return
	for command: int in PipCommand.ALL:
		var label := _labels[command]
		label.modulate = Color(
			1.0, 1.0, 1.0, 1.0 if frame.is_available(command) else UNAVAILABLE_ALPHA
		)
		var lit := frame.highlighted() == command
		label.add_theme_color_override(&"font_color", UiFrames.GOLD if lit else UiFrames.INK)


func _build() -> void:
	var hub := Label.new()
	hub.text = String(UiKeys.PIP_WHEEL_TITLE)
	hub.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hub)
	for command: int in PipCommand.ALL:
		var sector := Control.new()
		var direction: Vector2 = PipWheel.SECTOR_DIRECTIONS[command]
		var centre := Vector2(0.5, 0.5) + direction * SECTOR_RADIUS
		sector.anchor_left = centre.x
		sector.anchor_right = centre.x
		sector.anchor_top = centre.y
		sector.anchor_bottom = centre.y
		sector.offset_left = -80.0
		sector.offset_right = 80.0
		sector.offset_top = -22.0
		sector.offset_bottom = 22.0
		sector.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sector)
		sector.add_child(UiFrames.chip_frame())
		var label := Label.new()
		label.text = String(PipCommand.NAME_KEYS[command])
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sector.add_child(label)
		_labels.append(label)
