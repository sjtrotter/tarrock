class_name CardTransition
extends ColorRect

## Travelling between regions, as a card turned over.
##
## `docs/design/art-audio.md` §UI/UX pillars: "Diegetic card motifs everywhere.
## **Loading transitions are card cuts and flips**; menu navigation moves like laying
## out a hand". So a region change is not a black wipe: the screen takes a card's back,
## and the card turns.
##
## `RegionService` announces both halves of a journey - `region_will_change` before the
## world is taken away, `region_changed` once the Fool has left - and the flip is played
## across the pair. The transition never delays the travel: the persistent layer swaps
## scenes on its own deferred frame either way (`PersistentLayer`'s class doc), and a
## picture that could hold up a region change would be a picture that could soft-lock
## one.

## How long each half of the flip takes, in seconds.
const HALF_SECONDS := 0.22

var _regions: RegionService = null
var _card: TextureRect = null
var _tween: Tween = null
var _flipping: bool = false


func _ready() -> void:
	color = Color(UiFrames.GROUND.r, UiFrames.GROUND.g, UiFrames.GROUND.b, 0.0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = TextureRect.new()
	_card.texture = load(UiFrames.CARD_BACK_TEXTURE) as Texture2D
	_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card.stretch_mode = TextureRect.STRETCH_SCALE
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.pivot_offset = Vector2.ZERO
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	visible = false


## Watch this service's journeys. Null detaches.
func attach(regions: RegionService) -> void:
	_disconnect()
	_regions = regions
	_connect()


## True while the card is turning.
func is_flipping() -> bool:
	return _flipping


## Turn the card: closed over the outgoing region, open onto the incoming one.
func play() -> void:
	_flipping = true
	visible = true
	if not is_inside_tree():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_card.scale = Vector2(1.0, 1.0)
	_tween = create_tween()
	_tween.tween_property(self, ^"color:a", 1.0, HALF_SECONDS)
	_tween.parallel().tween_property(_card, ^"scale:x", 0.0, HALF_SECONDS)
	_tween.tween_property(_card, ^"scale:x", 1.0, HALF_SECONDS)
	_tween.parallel().tween_property(self, ^"color:a", 0.0, HALF_SECONDS)
	_tween.tween_callback(_finish)


func _connect() -> void:
	if _regions == null:
		return
	_regions.region_will_change.connect(_on_region_will_change)


func _disconnect() -> void:
	if _regions == null:
		return
	if _regions.region_will_change.is_connected(_on_region_will_change):
		_regions.region_will_change.disconnect(_on_region_will_change)


func _on_region_will_change(_from_region_id: StringName, _to_region_id: StringName) -> void:
	play()


func _finish() -> void:
	_flipping = false
	visible = false
	color = Color(UiFrames.GROUND.r, UiFrames.GROUND.g, UiFrames.GROUND.b, 0.0)
