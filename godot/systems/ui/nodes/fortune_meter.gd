class_name FortuneMeter
extends Control

## Fortune, drawn as a manuscript band - with Fortune's Favor overfilling past the cap.
##
## `docs/design/progression.md` §Fortune: the meter is "roughly 100 units baseline",
## and "immediately after a Fool's Chance, the meter can briefly hold *more* than its
## normal maximum - an overfill window that empties back down to the cap if unspent,
## encouraging the player to actually spend the free cast's momentum". So the cap is
## drawn as a fixed edge and the Favor is drawn PAST it: the player must be able to
## see that they are holding something they are about to lose.
##
## The free cast a Fool's Chance arms (`combat.md`) is a small gilded mark beside the
## band, not a number.
##
## **This is the one control in the shell that polls.** The bar eases toward the
## meter's real value in `_process` so a cast does not snap; everything else in
## `res://systems/ui/` is signal-driven. `settle()` is the way to skip the easing.

## How much of the gap the bar closes per second. Fast enough to feel immediate,
## slow enough that a 40-point cast reads as a drain rather than a cut.
const EASE_PER_SECOND := 6.0

## Anything closer than this counts as arrived.
const SNAP_EPSILON := 0.5

## The band's size in the base viewport, before any container stretches it.
const BAND_SIZE := Vector2(220.0, 22.0)

var _fortune: FortuneService = null
var _displayed: float = 0.0
var _frame: NinePatchRect = null
var _fill: ColorRect = null
var _overfill: ColorRect = null
var _free_cast: TextureRect = null


func _ready() -> void:
	custom_minimum_size = BAND_SIZE
	tooltip_text = String(UiKeys.FORTUNE)
	_frame = UiFrames.chip_frame()
	add_child(_frame)
	_fill = ColorRect.new()
	_fill.color = UiFrames.GOLD
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)
	_overfill = ColorRect.new()
	_overfill.color = UiFrames.PALE_GOLD
	_overfill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overfill)
	_free_cast = TextureRect.new()
	_free_cast.texture = load(UiFrames.CARET_TEXTURE) as Texture2D
	_free_cast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_free_cast.visible = false
	add_child(_free_cast)
	settle()


func _process(delta: float) -> void:
	if _fortune == null:
		return
	var target := float(_fortune.value())
	if absf(target - _displayed) <= SNAP_EPSILON:
		_displayed = target
	else:
		_displayed = lerpf(_displayed, target, minf(1.0, EASE_PER_SECOND * delta))
	_layout()


## Watch this meter. Null detaches.
func attach(fortune: FortuneService) -> void:
	if _fortune == fortune:
		return
	_disconnect()
	_fortune = fortune
	_connect()
	settle()


## The service being drawn, or null.
func fortune() -> FortuneService:
	return _fortune


## The value the bar is currently drawing, which lags the meter while it eases.
func displayed_value() -> float:
	return _displayed


## How full the band is drawn, 0..1. Never more than full: the surplus is the
## overfill, drawn beyond the cap.
func fill_ratio() -> float:
	var cap := _cap()
	if cap <= 0.0:
		return 0.0
	return clampf(_displayed / cap, 0.0, 1.0)


## How far past the cap the Favor reaches, as a fraction of the band's width.
## Zero whenever the meter is at or under its normal maximum.
func overfill_ratio() -> float:
	var cap := _cap()
	if cap <= 0.0:
		return 0.0
	return maxf(0.0, (_displayed - cap) / cap)


## True while the gilded free-cast mark is drawn.
func free_cast_visible() -> bool:
	return _free_cast != null and _free_cast.visible


## Stop easing and draw the meter's real value now.
func settle() -> void:
	_displayed = 0.0 if _fortune == null else float(_fortune.value())
	_layout()


func _cap() -> float:
	return 0.0 if _fortune == null else float(_fortune.max_value())


func _connect() -> void:
	if _fortune == null:
		return
	_fortune.free_cast_armed.connect(_refresh_free_cast)
	_fortune.free_cast_consumed.connect(_refresh_free_cast)


func _disconnect() -> void:
	if _fortune == null:
		return
	if _fortune.free_cast_armed.is_connected(_refresh_free_cast):
		_fortune.free_cast_armed.disconnect(_refresh_free_cast)
	if _fortune.free_cast_consumed.is_connected(_refresh_free_cast):
		_fortune.free_cast_consumed.disconnect(_refresh_free_cast)


func _refresh_free_cast() -> void:
	if _free_cast != null:
		_free_cast.visible = _fortune != null and _fortune.has_free_cast()


## Place the fill, the overfill and the mark inside whatever size this control got.
func _layout() -> void:
	if _fill == null:
		return
	var band := size
	if band.x <= 0.0:
		band = BAND_SIZE
	var inset := Vector2(6.0, 5.0)
	var inner := Vector2(maxf(0.0, band.x - inset.x * 2.0), maxf(0.0, band.y - inset.y * 2.0))
	_fill.position = inset
	_fill.size = Vector2(inner.x * fill_ratio(), inner.y)
	_overfill.position = Vector2(inset.x + inner.x, inset.y)
	_overfill.size = Vector2(inner.x * overfill_ratio(), inner.y)
	_overfill.visible = _overfill.size.x > 0.0
	_free_cast.position = Vector2(band.x + 6.0, (band.y - 18.0) * 0.5)
	_free_cast.size = Vector2(18.0, 18.0)
	_refresh_free_cast()
