class_name HealthMeter
extends Control

## The Fool's wounds, drawn as the fullness of the Rose's own bloom.
##
## **THIS PRESENTATION IS TBD, PENDING DIRECTOR ISSUE #11.** `docs/design/art-audio.md`
## §UI/UX pillars says "health (White Rose petals) and Fortune are always visible",
## which reads as *petals are the health bar*; `docs/design/combat.md`'s defeat loop
## and round 7's working ruling instead give the Fool a health POOL
## (`Combatant.health()`) that petals HEAL. Rounds 7-12 built to the pool, and this
## round draws it - but it deliberately does not draw a second numeric bar beside the
## petals, because two health readouts on a HUD whose stated pillar is restraint would
## be the wrong answer to either reading.
##
## So: the petals (`RoseMeter`) stay the charges, and the pool is drawn as how full
## the bloom above them is - one object, two facts, no numerals. If #11 rules that
## petals ARE the health, this control is deleted and `RoseMeter` alone remains; if it
## rules the pool is separate and wants its own bar, this grows into one. Nothing else
## in the shell depends on which.

## The bloom's size in the base viewport.
const BLOOM_SIZE := Vector2(28.0, 34.0)

var _combatant: Combatant = null
var _bloom: TextureRect = null
var _fill: ColorRect = null


func _ready() -> void:
	custom_minimum_size = BLOOM_SIZE
	tooltip_text = String(UiKeys.HEALTH)
	_bloom = TextureRect.new()
	_bloom.texture = load(UiFrames.PETAL_TEXTURE) as Texture2D
	_bloom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bloom.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bloom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloom.modulate = Color(1.0, 1.0, 1.0, UiFrames.SPENT_ALPHA)
	add_child(_bloom)
	_fill = ColorRect.new()
	_fill.color = UiFrames.PARCHMENT
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)
	_refresh()


## Watch this body's health. Null detaches.
func attach(combatant: Combatant) -> void:
	if _combatant == combatant:
		return
	_disconnect()
	_combatant = combatant
	_connect()
	_refresh()


## The body being drawn, or null.
func combatant() -> Combatant:
	return _combatant


## How full the bloom is drawn, 0..1. Full when nothing is attached, because an
## unattached HUD must not read as a Fool at death's door.
func fullness() -> float:
	if _combatant == null:
		return 1.0
	return clampf(_combatant.health_fraction(), 0.0, 1.0)


func _connect() -> void:
	if _combatant == null:
		return
	_combatant.damaged.connect(_on_health_changed)
	_combatant.healed.connect(_on_health_changed)


func _disconnect() -> void:
	if _combatant == null:
		return
	if _combatant.damaged.is_connected(_on_health_changed):
		_combatant.damaged.disconnect(_on_health_changed)
	if _combatant.healed.is_connected(_on_health_changed):
		_combatant.healed.disconnect(_on_health_changed)


func _on_health_changed(_amount: int, _remaining: int) -> void:
	_refresh()


func _refresh() -> void:
	if _fill == null:
		return
	var box := size
	if box.x <= 0.0:
		box = BLOOM_SIZE
	var height := box.y * fullness()
	_fill.position = Vector2(0.0, box.y - height)
	_fill.size = Vector2(box.x, height)
