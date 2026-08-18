extends TarrockTest

## The map: 22 cards on a table, face-up only where an Arcanum has been unbound.
##
## `docs/design/art-audio.md` §Map, the Almanack, and UI: "The map screen renders the
## world as cards dealt face-down on a table; unbinding an Arcanum turns that region's
## card face-up. This is the game's primary progress-at-a-glance UI". So the assertions
## are: all 22 are dealt, a card turns when and only when its flag fires, the Fool's own
## region is marked, and fast travel refuses before `WS_CHARIOT_UNBOUND` in the
## service's own words (`progression.md` §Waystations).

const MAP_SCENE := "res://scenes/ui/map_screen.tscn"
const MAP_LAYOUT_PATH := "res://data/ui/map_layout.tres"
const REGION_CATALOG_PATH := "res://data/regions/catalog.tres"
const REGION_GRAPH_PATH := "res://data/regions/region_graph.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const SAVES_DIR := "user://test_ui_map_saves"

const FIRED_BY := &"tests/unit/ui/map_screen_test.gd"

var _map: MapScreen = null
var _regions: RegionService = null
var _world_state: WorldStateService = null
var _layout: MapLayout = null


func before_each() -> void:
	TranslationServer.set_locale("en")
	var rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var fortune := FortuneService.new(rules)
	var spread := PocketSpreadService.new(
		_world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, rules, fortune
	)
	var rose := WhiteRoseService.new(_world_state, rules)
	var combat := CombatService.new(
		(load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules,
		fortune, spread, rose, GameClock.new()
	)
	var save := SaveService.new(_world_state, GameClock.new(), SAVES_DIR, null, spread, fortune, rose)
	_regions = RegionService.new(
		load(REGION_CATALOG_PATH) as RegionCatalog,
		load(REGION_GRAPH_PATH) as RegionGraph,
		_world_state,
		save,
		rose,
		spread,
		combat
	)
	# `place_at()` asks the layer to instance a scene. There is no layer in a unit
	# test, so it is handed a swapper that says yes and moves nothing.
	_regions.set_swapper(RegionSwapper.new(_swap, _re_anchor, _respawn))
	_layout = load(MAP_LAYOUT_PATH) as MapLayout
	_map = (load(MAP_SCENE) as PackedScene).instantiate() as MapScreen
	tree().root.add_child(_map)


func after_each() -> void:
	if _map != null and is_instance_valid(_map):
		_map.get_parent().remove_child(_map)
		_map.free()
	_map = null


func test_the_layout_places_every_region_exactly_once() -> void:
	assert_eq(_layout.validate().size(), 0, str(_layout.validate()))
	assert_eq(_layout.placements.size(), RegionIds.ALL.size())
	assert_eq(_layout.placements.size(), 22, "world.md: 21 in the wheel plus the Cliff")


func test_a_map_with_no_layout_deals_nothing_rather_than_erroring() -> void:
	_map.attach(null, null, null)
	assert_eq(_map.card_count(), 0)
	assert_eq(_map.highlighted_region(), &"")


func test_every_region_is_dealt_face_down() -> void:
	_map.attach(_regions, _world_state, _layout)
	assert_eq(_map.card_count(), 22)
	for region_id: StringName in RegionIds.ALL:
		var card := _map.card_for(region_id)
		assert_not_null(card, "%s has a card" % region_id)
		assert_false(card.is_face_up(), "%s starts face-down" % region_id)


func test_unbinding_an_arcanum_turns_that_card_and_only_that_card() -> void:
	_map.attach(_regions, _world_state, _layout)
	var prestige := _regions.definition(RegionIds.PRESTIGE)
	assert_ne(prestige.unbinding_flag, &"", "the Prestige has an Arcanum")
	_world_state.fire(prestige.unbinding_flag, FIRED_BY)
	assert_true(_map.card_for(RegionIds.PRESTIGE).is_face_up())
	assert_false(_map.card_for(RegionIds.BOWER).is_face_up(), "its neighbour did not turn")


func test_the_cliffs_card_never_turns_because_it_has_no_arcanum() -> void:
	# `world.md` §The Cliff: it sits outside the Spread.
	_map.attach(_regions, _world_state, _layout)
	assert_eq(_regions.definition(RegionIds.CLIFF).unbinding_flag, &"")
	for flag_id: StringName in [
		WorldStateIds.WS_MAGICIAN_UNBOUND, WorldStateIds.WS_EMPRESS_UNBOUND
	]:
		_world_state.fire(flag_id, FIRED_BY)
	assert_false(_map.card_for(RegionIds.CLIFF).is_face_up())


func test_the_region_the_fool_stands_in_is_marked() -> void:
	_map.attach(_regions, _world_state, _layout)
	assert_eq(_map.highlighted_region(), &"", "nowhere yet")
	assert_true(_regions.place_at(RegionIds.CLIFF))
	_map.refresh()
	assert_eq(_map.highlighted_region(), RegionIds.CLIFF)


func test_fast_travel_refuses_before_the_chariot_and_says_why() -> void:
	_map.attach(_regions, _world_state, _layout)
	_regions.place_at(RegionIds.CLIFF)
	assert_false(_regions.fast_travel_unlocked())
	assert_false(_map.fast_travel_to_region(RegionIds.PRESTIGE))
	assert_eq(_map.last_refusal_key(), &"UI_REFUSED_NO_FAST_TRAVEL")
	assert_true(_map.refusal_chip().is_showing())
	assert_ne(
		_map.refusal_chip().prompt_text(),
		String(_map.last_refusal_key()),
		"the refusal has a CSV row"
	)


func test_every_region_has_a_shrine_so_the_maps_own_guard_is_only_a_guard() -> void:
	# The map refuses a region with no Waystation in the service's own words. No
	# region in the shipped catalog is one, which is the fact worth asserting: the
	# guard is defensive, and the day a region ships without a shrine this says so by
	# name rather than by a test quietly returning early.
	var without := _region_without_waystation()
	assert_eq(
		without, &"", "%s has no Waystation, so the map cannot fast travel to it" % without
	)


func test_the_cliff_is_outside_the_network_and_the_map_says_so() -> void:
	# `world.md` §Layout: the Cliff "is outside the Waystation network - no fast travel
	# returns there", and `RegionService` answers OUTSIDE_NETWORK rather than
	# NOT_VISITED because the Fool HAS slept at that shrine. The map draws that answer.
	_map.attach(_regions, _world_state, _layout)
	_world_state.fire(RegionService.FAST_TRAVEL_FLAG, FIRED_BY)
	assert_true(_regions.fast_travel_unlocked())
	assert_true(_regions.place_at(RegionIds.PRESTIGE))
	assert_false(_map.fast_travel_to_region(RegionIds.CLIFF))
	assert_eq(_map.last_refusal_key(), &"UI_REFUSED_OUTSIDE_NETWORK")
	assert_ne(
		_map.refusal_chip().prompt_text(),
		String(_map.last_refusal_key()),
		"and that refusal has a CSV row"
	)


func test_the_travel_button_asks_about_the_card_the_player_chose() -> void:
	_map.attach(_regions, _world_state, _layout)
	_regions.place_at(RegionIds.CLIFF)
	_map.choose(RegionIds.PRESTIGE)
	assert_eq(_map.chosen_region(), RegionIds.PRESTIGE)
	_map.travel_button().pressed.emit()
	assert_ne(_map.last_refusal_key(), &"", "the service was asked, and answered")


## The three jobs a persistent layer would do, done by nobody.
func _swap(_scene_path: String, _arrival: StringName) -> bool:
	return true


func _re_anchor(_arrival: StringName) -> bool:
	return true


func _respawn() -> int:
	return 0


func _region_without_waystation() -> StringName:
	for region_id: StringName in RegionIds.ALL:
		var definition := _regions.definition(region_id)
		if definition != null and definition.first_waystation_id() == &"":
			return region_id
	return &""
