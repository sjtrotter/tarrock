class_name RoseMeter
extends HBoxContainer

## The White Rose, drawn as petals: one icon per charge, spent ones faded.
##
## `docs/design/art-audio.md` §UI/UX pillars, HUD restraint: "health (White Rose
## petals) and Fortune are always visible; everything else ... fades to unobtrusive
## when not in use." `docs/design/progression.md` §The White Rose: "Starting capacity:
## 3 petals. Maximum: 8, raised by finding or earning Rose graftings" - so the number
## of icons is the CAP and how many are lit is the charge. **No numerals**: a petal is
## a petal, which is also what keeps this readable at any text size.
##
## A spent petal is drawn faint rather than removed, because it comes back
## (`progression.md`: fully at a Waystation, slowly in an unbound region, never in a
## bound one). An empty row would say "gone"; a faint row says "not yet".

## The icon size, in the base 1280x720 viewport. Scaled by the control's own
## container, never positioned by hand (`technical.md` §Port-readiness rules, 2).
const PETAL_SIZE := Vector2(28.0, 28.0)

var _rose: WhiteRoseService = null
var _icons: Array[TextureRect] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", 2)
	tooltip_text = String(UiKeys.ROSE)
	_rebuild()


## Watch this Rose. Null detaches, which is what a rebuilt playthrough hands over
## before the new services arrive.
func attach(rose: WhiteRoseService) -> void:
	if _rose == rose:
		return
	_disconnect()
	_rose = rose
	_connect()
	_rebuild()


## The Rose being drawn, or null.
func rose() -> WhiteRoseService:
	return _rose


## How many petal icons are drawn - the Rose's capacity.
func icon_count() -> int:
	return _icons.size()


## How many of them are drawn lit - the charges actually held.
func lit_count() -> int:
	var lit := 0
	for icon: TextureRect in _icons:
		if icon.modulate.a > UiFrames.SPENT_ALPHA:
			lit += 1
	return lit


## One petal icon, or null for an index nothing draws.
func icon(index: int) -> TextureRect:
	if index < 0 or index >= _icons.size():
		return null
	return _icons[index]


func _connect() -> void:
	if _rose == null:
		return
	_rose.petals_changed.connect(_on_petals_changed)
	_rose.max_petals_changed.connect(_on_max_changed)
	_rose.regrown.connect(_refresh)


func _disconnect() -> void:
	if _rose == null:
		return
	if _rose.petals_changed.is_connected(_on_petals_changed):
		_rose.petals_changed.disconnect(_on_petals_changed)
	if _rose.max_petals_changed.is_connected(_on_max_changed):
		_rose.max_petals_changed.disconnect(_on_max_changed)
	if _rose.regrown.is_connected(_refresh):
		_rose.regrown.disconnect(_refresh)


func _on_petals_changed(_old_petals: int, _new_petals: int) -> void:
	_refresh()


func _on_max_changed(_old_max: int, _new_max: int) -> void:
	_rebuild()


## Build one icon per point of capacity. Called only when the capacity itself moves
## (a grafting), never per petal spent.
func _rebuild() -> void:
	for icon_node: TextureRect in _icons:
		remove_child(icon_node)
		icon_node.queue_free()
	_icons.clear()
	var capacity := 0 if _rose == null else _rose.max_petals()
	var texture: Texture2D = load(UiFrames.PETAL_TEXTURE) as Texture2D
	for index: int in range(capacity):
		var petal := TextureRect.new()
		petal.texture = texture
		petal.custom_minimum_size = PETAL_SIZE
		petal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		petal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		petal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(petal)
		_icons.append(petal)
	_refresh()


func _refresh() -> void:
	var held := 0 if _rose == null else _rose.petals()
	for index: int in range(_icons.size()):
		_icons[index].modulate = Color(1.0, 1.0, 1.0, 1.0 if index < held else UiFrames.SPENT_ALPHA)
