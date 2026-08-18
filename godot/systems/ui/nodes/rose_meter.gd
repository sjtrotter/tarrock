class_name RoseMeter
extends HBoxContainer

## The White Rose, drawn as petals: one icon per petal of capacity, filled by quarters.
##
## **This is the Fool's health bar** - the director's ruling on issue #11 is that the
## petals ARE the health, so there is no second readout beside it and `Hud` draws
## nothing else about the Fool's body. `docs/design/art-audio.md` §UI/UX pillars, HUD
## restraint: "health (White Rose petals) and Fortune are always visible; everything
## else ... fades to unobtrusive when not in use." `docs/design/progression.md` §The
## White Rose: "Starting capacity: 3 petals. Maximum: 8, raised by finding or earning
## Rose graftings" - so the number of icons is the CAP and how full they are is the
## health. **No numerals**: a petal is a petal, which is also what keeps this readable
## at any text size.
##
## **Quarters are drawn, not counted out.** The pool underneath is in quarter petals
## (`WhiteRoseService.QUARTERS_PER_PETAL`), because three petals is far too coarse a
## bar for a difficulty multiplier or a rank curve to survive - so the last petal
## carrying damage is drawn part-faded rather than snapping out, and the row reads as a
## Rose losing petals rather than as a counter. The fade is one step per quarter, which
## is a shape a player can read at a glance and without colour.
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


## How many of them have any petal left in them at all. The same number as
## `WhiteRoseService.petals()`, which rounds up for the same reason: a petal a quarter
## torn is still a petal on the flower.
func lit_count() -> int:
	var lit := 0
	for icon_node: TextureRect in _icons:
		if icon_node.modulate.a > UiFrames.SPENT_ALPHA:
			lit += 1
	return lit


## How many quarters of petal `index` are left, 0..4. What the fill of one icon means.
func quarter_fill(index: int) -> int:
	if _rose == null or index < 0 or index >= _icons.size():
		return 0
	return clampi(
		_rose.quarters() - index * WhiteRoseService.QUARTERS_PER_PETAL,
		0,
		WhiteRoseService.QUARTERS_PER_PETAL
	)


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


func _on_petals_changed(_old_quarters: int, _new_quarters: int) -> void:
	_refresh()


func _on_max_changed(_old_max: int, _new_max: int) -> void:
	_rebuild()


## Build one icon per point of capacity. Called only when the capacity itself moves
## (a grafting), never per quarter lost.
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


## The alpha one petal is drawn at, given how many of its quarters are left.
##
## `UiFrames.SPENT_ALPHA` at empty and 1.0 at whole, with the three quarters in
## between spaced evenly across that band - so a part-torn petal is always visibly
## brighter than a spent one and visibly dimmer than a whole one, which is what makes
## the four steps legible rather than merely different.
static func alpha_for_quarters(quarters_left: int) -> float:
	var filled := clampi(quarters_left, 0, WhiteRoseService.QUARTERS_PER_PETAL)
	if filled <= 0:
		return UiFrames.SPENT_ALPHA
	var fraction := float(filled) / float(WhiteRoseService.QUARTERS_PER_PETAL)
	return UiFrames.SPENT_ALPHA + (1.0 - UiFrames.SPENT_ALPHA) * fraction


func _refresh() -> void:
	for index: int in range(_icons.size()):
		var alpha := alpha_for_quarters(quarter_fill(index))
		_icons[index].modulate = Color(1.0, 1.0, 1.0, alpha)
