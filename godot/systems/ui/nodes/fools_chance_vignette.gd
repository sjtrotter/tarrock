class_name FoolsChanceVignette
extends ColorRect

## The gilded wash over the screen while Fool's Chance is running.
##
## `docs/design/combat.md` §Accessibility: "Screen-shake and screen-flash toggles,
## given how central slow-motion and flash-forward feedback (Fool's Chance,
## charged-heavy releases) are to combat feel." So this obeys the flash toggle: with
## flash off it does not draw at all, and the slow motion itself - which is the fight
## systems' and not the UI's - carries the beat instead.
##
## `systems/combat/README.md` names the optional flourish this pairs with; the
## flourish is the fight's, the tint is the shell's.

## How gold the world goes at full strength.
const TINT := Color(0.941, 0.874, 0.667, 0.16)

## How long the wash takes to arrive and to leave, in seconds.
const FADE_SECONDS := 0.12

var _combat: CombatService = null
var _flash_allowed: bool = true
var _tween: Tween = null


func _ready() -> void:
	color = Color(TINT.r, TINT.g, TINT.b, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


## Watch this fight. Null detaches.
func attach(combat: CombatService) -> void:
	if _combat == combat:
		return
	_disconnect()
	_combat = combat
	_connect()
	_refresh()


## Obey (or stop obeying) the player's screen-flash setting.
func set_flash_allowed(allowed: bool) -> void:
	_flash_allowed = allowed
	_refresh()


## True while the player has screen flash on.
func flash_allowed() -> bool:
	return _flash_allowed


## True while the wash is drawn. The alpha is a tween away from zero on the frame it
## starts, so what is asked here is whether the wash is UP, not how far in it is.
func is_washing() -> bool:
	return visible


func _connect() -> void:
	if _combat == null:
		return
	_combat.fools_chance_started.connect(_on_started)
	_combat.fools_chance_ended.connect(_on_ended)


func _disconnect() -> void:
	if _combat == null:
		return
	if _combat.fools_chance_started.is_connected(_on_started):
		_combat.fools_chance_started.disconnect(_on_started)
	if _combat.fools_chance_ended.is_connected(_on_ended):
		_combat.fools_chance_ended.disconnect(_on_ended)


func _on_started(_real_seconds: float) -> void:
	_refresh()


func _on_ended() -> void:
	_refresh()


func _refresh() -> void:
	var active := _flash_allowed and _combat != null and _combat.is_fools_chance_active()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	visible = active
	if not is_inside_tree():
		color = Color(TINT.r, TINT.g, TINT.b, TINT.a if active else 0.0)
		return
	if active:
		color = Color(TINT.r, TINT.g, TINT.b, 0.0)
		_tween = create_tween()
		_tween.tween_property(self, ^"color:a", TINT.a, FADE_SECONDS)
	else:
		color = Color(TINT.r, TINT.g, TINT.b, 0.0)
