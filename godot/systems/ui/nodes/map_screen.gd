class_name MapScreen
extends Control

## The world, dealt on a table: 22 cards, face-down until the Arcanum is unbound.
##
## `docs/design/art-audio.md` §Map, the Almanack, and UI: "The map screen renders the
## world as cards dealt face-down on a table (`world.md`); unbinding an Arcanum turns
## that region's card face-up. **This is the game's primary progress-at-a-glance UI and
## should need no HUD counter duplicating it.**" That last clause is why the HUD has no
## unbound counter: this screen IS the counter.
##
## Where each card lies is `res://data/ui/map_layout.tres`, read off `world.md`
## §Layout's diagram. Which regions TOUCH is not here and is never asked here - that is
## `region_graph.tres`, and travel is `RegionService`'s answer, refusals included.
##
## Fast travel is offered from a card, and refused by the service before
## `WS_CHARIOT_UNBOUND` fires (`progression.md` §Waystations); the refusal is shown
## rather than the option hidden, because "the way is shut" is information.

## Card size on the table, in the base viewport. The layout is fractional, so the
## table itself scales with the window (`technical.md` §Port-readiness rules, 2).
const CARD_SIZE := Vector2(72.0, 116.0)

## The player asked to put this page down.
signal close_requested()

var _regions: RegionService = null
var _world_state: WorldStateService = null
var _layout: MapLayout = null
var _table: Control = null
var _chip: PromptChip = null
var _cards: Dictionary = {}
var _travel: Button = null
var _here: Label = null
var _chosen: StringName = &""
var _last_refusal: StringName = &""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	visible = false


## Hand the map a playthrough and a layout. Every argument may be null.
func attach(regions: RegionService, world_state: WorldStateService, layout: MapLayout) -> void:
	_disconnect()
	_regions = regions
	_world_state = world_state
	_layout = layout
	_connect()
	_deal()


## The layout being drawn, or null.
func layout() -> MapLayout:
	return _layout


## How many cards are on the table.
func card_count() -> int:
	return _cards.size()


## One region's card, or null.
func card_for(region_id: StringName) -> CardView:
	if not _cards.has(region_id):
		return null
	return _cards[region_id] as CardView


## The region whose card is marked as where the Fool stands, or `&""`.
func highlighted_region() -> StringName:
	for region_id: StringName in _cards:
		var card: CardView = _cards[region_id]
		if card.is_highlighted():
			return region_id
	return &""


## The chip a refusal is written on.
func refusal_chip() -> PromptChip:
	return _chip


## The key of the last refusal shown, or `&""`.
func last_refusal_key() -> StringName:
	return _last_refusal


## Travel to a region's Waystation from the map. The service decides, and its reason
## is shown when it says no.
func fast_travel_to_region(region_id: StringName) -> bool:
	if _regions == null:
		return false
	var definition := _regions.definition(region_id)
	if definition == null:
		_show_refusal(RegionService.REASON_NO_SUCH_REGION)
		return false
	var waystation := definition.first_waystation_id()
	if waystation == &"":
		_show_refusal(RegionService.REASON_NO_SUCH_WAYSTATION)
		return false
	var reason := _regions.fast_travel_refusal(waystation)
	if reason != &"":
		_show_refusal(reason)
		return false
	return _regions.fast_travel_to(waystation)


## The card the player has put a finger on, or `&""`.
func chosen_region() -> StringName:
	return _chosen


## Put a finger on a card. Travelling then asks the service about THAT region.
func choose(region_id: StringName) -> void:
	_chosen = region_id


## The button that asks to travel to the chosen card.
func travel_button() -> Button:
	return _travel


## Redraw every card from the world as it stands.
func refresh() -> void:
	for region_id: StringName in _cards:
		var card: CardView = _cards[region_id]
		card.set_face_up(_is_unbound(region_id))
		card.set_highlighted(_regions != null and _regions.current_region_id() == region_id)


func _build() -> void:
	add_child(UiFrames.panel_frame())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 64)
	margin.add_theme_constant_override(&"margin_right", 64)
	margin.add_theme_constant_override(&"margin_top", 52)
	margin.add_theme_constant_override(&"margin_bottom", 52)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var close := Button.new()
	close.text = String(UiKeys.CLOSE)
	close.pressed.connect(close_requested.emit)
	column.add_child(close)
	var title := Label.new()
	title.text = String(UiKeys.MAP_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_table = Control.new()
	_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_table)
	_travel = Button.new()
	_travel.text = String(UiKeys.MAP_FAST_TRAVEL)
	_travel.pressed.connect(_on_travel_pressed)
	column.add_child(_travel)
	_here = Label.new()
	_here.text = String(UiKeys.MAP_HERE)
	_here.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_here)
	_chip = PromptChip.new()
	_chip.custom_minimum_size = Vector2(420.0, 0.0)
	column.add_child(_chip)


func _connect() -> void:
	if _world_state != null:
		_world_state.world_state_fired.connect(_on_flag_fired)
	if _regions != null:
		_regions.region_changed.connect(_on_region_changed)
		_regions.travel_refused.connect(_on_travel_refused)


func _disconnect() -> void:
	if _world_state != null:
		_drop(_world_state.world_state_fired, _on_flag_fired)
	if _regions != null:
		_drop(_regions.region_changed, _on_region_changed)
		_drop(_regions.travel_refused, _on_travel_refused)


## Disconnect one handler if it is connected.
static func _drop(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		source.disconnect(target)


func _on_flag_fired(_flag_id: StringName) -> void:
	refresh()


func _on_region_changed(_from: StringName, _to: StringName, _arrival: StringName) -> void:
	refresh()


func _on_travel_refused(_to_region_id: StringName, reason: StringName) -> void:
	_show_refusal(reason)


func _on_travel_pressed() -> void:
	if _chosen != &"":
		fast_travel_to_region(_chosen)


func _show_refusal(reason: StringName) -> void:
	_last_refusal = UiKeys.refusal(reason)
	if _chip != null:
		_chip.show_prompt(_last_refusal)


## True when this region's Arcanum has been unbound, so its card is face-up. The Cliff
## has no Arcanum (`world.md` §The Cliff) and its card therefore never turns.
func _is_unbound(region_id: StringName) -> bool:
	if _regions == null or _world_state == null:
		return false
	var definition := _regions.definition(region_id)
	if definition == null:
		return false
	return definition.is_unbound(_world_state)


## Lay every card the layout places, at the fraction of the table it names.
func _deal() -> void:
	for child: Node in _table.get_children():
		_table.remove_child(child)
		child.queue_free()
	_cards.clear()
	if _layout == null:
		return
	for placement: MapPlacement in _layout.placements:
		if placement == null:
			continue
		var card := CardView.new()
		card.custom_minimum_size = CARD_SIZE
		card.anchor_left = placement.position.x
		card.anchor_right = placement.position.x
		card.anchor_top = placement.position.y
		card.anchor_bottom = placement.position.y
		card.offset_left = -CARD_SIZE.x * 0.5
		card.offset_right = CARD_SIZE.x * 0.5
		card.offset_top = -CARD_SIZE.y * 0.5
		card.offset_bottom = CARD_SIZE.y * 0.5
		var name_key := &""
		if _regions != null:
			var definition := _regions.definition(placement.region_id)
			if definition != null:
				name_key = definition.name_key
		card.set_name_key(name_key)
		_table.add_child(card)
		_cards[placement.region_id] = card
	refresh()
