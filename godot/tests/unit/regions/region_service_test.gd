extends TarrockTest

## `RegionService`: where the Fool may go, what stops them, and what a Waystation does.
##
## The service is a plain `RefCounted`, so these are built directly, with a fake
## `RegionSwapper` standing in for the persistent layer - which is the whole reason
## the swap is an object and not a hard call. What the layer does with a swap request
## is `res://tests/regions_test.gd`'s business; what the service asks for is this
## suite's.
##
## **The Spread here is synthetic.** The ids, the flags and the Trumps are the real
## ones (`RegionIds`, `WorldStateIds`, `TrumpIds` - no magic strings anywhere), but the
## edges are built in the test, because a suite that read the authored graph would
## only be able to test the journeys that graph happens to allow, and would go red
## every time a designer moved a road. The authored graph has its own suite:
## `region_graph_test.gd` checks it against `world.md` §Layout.

const CLIFF_SCENE := "res://scenes/the_cliff.tscn"
const PRESTIGE_SCENE := "res://scenes/regions/prestige.tscn"
const MISSING_SCENE := "res://scenes/regions/bower.tscn"

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"

## A scratch save directory. Nothing here writes a file - the service only reads and
## writes the save's in-memory fields - but a test must never be pointed at the
## player's saves by accident.
const SAVES_DIR := "user://test_regions_saves"

var _service: RegionService = null
var _world_state: WorldStateService = null
var _save: SaveService = null
var _rose: WhiteRoseService = null
var _spread: PocketSpreadService = null
var _combat: CombatService = null
var _clock: GameClock = null

## The Fool's own body. `CombatService.revive_at_waystation()` restores the combatant
## it was given, so the defeat loop has nothing to wake without one.
var _fool: Combatant = null

## What the fake swapper was asked for: `[[scene_path, arrival], ...]`.
var _swaps: Array = []

## Arrival markers the fake swapper was asked to re-anchor on.
var _anchors: Array[StringName] = []

## How many times the layer was asked to put the ambient dead back on their feet.
var _respawns: int = 0


func before_each() -> void:
	_swaps = []
	_anchors = []
	_respawns = 0
	_build(_spread_of_five())


func after_each() -> void:
	_service = null
	_combat = null
	if _fool != null and is_instance_valid(_fool):
		_fool.free()
	_fool = null


# --- Reading the map ---------------------------------------------------------------


func test_adjacency_is_what_the_graph_says() -> void:
	assert_true(_service.is_adjacent(RegionIds.PRESTIGE, RegionIds.BOWER))
	assert_true(_service.is_adjacent(RegionIds.BOWER, RegionIds.PRESTIGE))
	assert_false(_service.is_adjacent(RegionIds.PRESTIGE, RegionIds.HOLLOWS))


func test_the_leap_off_the_cliff_runs_one_way() -> void:
	assert_true(_service.is_adjacent(RegionIds.CLIFF, RegionIds.PRESTIGE))
	assert_false(_service.is_adjacent(RegionIds.PRESTIGE, RegionIds.CLIFF))


func test_the_first_placement_of_a_playthrough_needs_no_road() -> void:
	# A new game onto the Cliff, or a load onto wherever the save says: nobody walked
	# there, so adjacency has nothing to say about it.
	assert_eq(_service.current_region_id(), RegionService.UNSET)
	assert_true(_service.can_travel(RegionIds.PRESTIGE), "and it is not the Cliff either")


# --- Travelling ---------------------------------------------------------------------


func test_travelling_swaps_the_scene_and_announces_both_ends() -> void:
	_service.travel_to(RegionIds.CLIFF)
	watch_signal(_service, &"region_will_change")
	watch_signal(_service, &"region_changed")
	assert_true(_service.travel_to(RegionIds.PRESTIGE, RegionService.LEAP_ARRIVAL))
	assert_eq(_service.current_region_id(), RegionIds.PRESTIGE)
	assert_signal_emitted(_service, &"region_will_change", 1)
	assert_signal_emitted(_service, &"region_changed", 1)
	assert_eq(
		signal_arguments(_service, &"region_changed", 0),
		[RegionIds.CLIFF, RegionIds.PRESTIGE, RegionService.LEAP_ARRIVAL]
	)
	assert_eq(_swaps.size(), 2, "the layer was asked to load both regions")
	assert_eq(_swaps[1], [PRESTIGE_SCENE, RegionService.LEAP_ARRIVAL])


func test_travelling_tells_the_white_rose_where_it_is_standing() -> void:
	# `progression.md` §The White Rose: it regrows only in a region whose Arcana has
	# been unbound, and not at all on the Cliff, which has no Arcana. The Rose cannot
	# know that by itself - this is the call that tells it.
	_service.travel_to(RegionIds.CLIFF)
	assert_eq(_rose.region_id(), RegionIds.CLIFF)
	assert_false(_rose.regrows_here(), "the Cliff is outside the Spread; nothing grows")
	_service.travel_to(RegionIds.PRESTIGE)
	assert_eq(_rose.region_id(), RegionIds.PRESTIGE)
	assert_false(_rose.regrows_here(), "the Magician is still bound")
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	assert_true(_rose.regrows_here(), "and awake once he is unbound")


func test_travelling_empties_the_fight() -> void:
	# A Blank engaged in the region being freed would be a fight nobody can win, in a
	# `CombatService` that is not going anywhere.
	_service.travel_to(RegionIds.CLIFF)
	var enemy := Combatant.new()
	enemy.faction = Faction.Id.BLANK
	_combat.enemy_engaged(enemy)
	assert_true(_combat.is_in_combat())
	_service.travel_to(RegionIds.PRESTIGE)
	assert_false(_combat.is_in_combat(), "nobody is still swinging in the region we left")
	enemy.free()


func test_travelling_somewhere_with_no_road_is_refused() -> void:
	_service.travel_to(RegionIds.PRESTIGE)
	watch_signal(_service, &"travel_refused")
	assert_false(_service.travel_to(RegionIds.HOLLOWS))
	assert_eq(_service.travel_refusal(RegionIds.HOLLOWS), RegionService.REASON_NOT_ADJACENT)
	assert_signal_emitted(_service, &"travel_refused", 1)
	assert_eq(_service.current_region_id(), RegionIds.PRESTIGE, "and nobody moved")
	assert_eq(_swaps.size(), 1, "and no scene was thrown away")


func test_travelling_to_a_region_nobody_has_built_is_refused() -> void:
	# Twenty of the twenty-two regions have no scene yet. That is a refusal with a
	# reason, not a crash and not a black screen.
	_service.travel_to(RegionIds.PRESTIGE)
	assert_eq(_service.travel_refusal(RegionIds.BOWER), RegionService.REASON_NO_SCENE)
	assert_false(_service.travel_to(RegionIds.BOWER))


func test_travelling_to_a_region_that_does_not_exist_is_refused() -> void:
	assert_eq(_service.travel_refusal(&"NOWHERE"), RegionService.REASON_NO_SUCH_REGION)


func test_travelling_where_the_fool_already_stands_is_refused() -> void:
	_service.travel_to(RegionIds.PRESTIGE)
	assert_eq(_service.travel_refusal(RegionIds.PRESTIGE), RegionService.REASON_ALREADY_THERE)


func test_a_service_with_no_layer_cannot_load_anything() -> void:
	_service.set_swapper(null)
	assert_eq(_service.travel_refusal(RegionIds.CLIFF), RegionService.REASON_NO_SWAPPER)


# --- Gates --------------------------------------------------------------------------


func test_the_hollows_are_shut_until_death_is_unbound() -> void:
	# `world.md` §Hard and soft gates: "The Hollows (MQ20) | Death unbound (MQ13)".
	_service.travel_to(RegionIds.LONGROAD)
	assert_eq(_service.travel_refusal(RegionIds.HOLLOWS), RegionService.REASON_GATE_CLOSED)
	assert_false(_service.travel_to(RegionIds.HOLLOWS))
	_world_state.fire(WorldStateIds.WS_DEATH_UNBOUND, QuestIds.MQ13)
	assert_true(_service.can_travel(RegionIds.HOLLOWS), "Judgement can call them now")
	assert_true(_service.travel_to(RegionIds.HOLLOWS))
	assert_true(_service.can_travel(RegionIds.LONGROAD), "and the way back was never shut")


func test_the_mirrormarsh_wants_a_light_and_any_one_will_do() -> void:
	# `world.md` §Hard and soft gates: "Any true light: Hermit's Lantern, Star's Wish,
	# or the Sun unbound". Three keys, one lock, and the Trump-held half is read off
	# the Pocket Spread rather than off a flag of its own.
	_service.travel_to(RegionIds.LONGROAD)
	assert_eq(
		_service.travel_refusal(RegionIds.MIRRORMARSH), RegionService.REASON_GATE_CLOSED
	)
	_world_state.fire(WorldStateIds.WS_HERMIT_UNBOUND, QuestIds.MQ09)
	assert_true(
		_spread.is_held(TrumpIds.TRUMP_09), "unbinding the Hermit hands over the Lantern"
	)
	assert_true(_service.can_travel(RegionIds.MIRRORMARSH), "and the fog stops lying")


func test_the_suns_light_opens_the_marsh_without_a_trump() -> void:
	_service.travel_to(RegionIds.LONGROAD)
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	assert_true(_service.can_travel(RegionIds.MIRRORMARSH))


# --- Waystations --------------------------------------------------------------------


func test_resting_regrows_the_rose_and_remembers_the_shrine() -> void:
	# `progression.md` §Waystations: "Rest - fully regrow the White Rose and respawn
	# ambient (non-boss) enemies."
	_service.travel_to(RegionIds.CLIFF)
	_rose.use_petal()
	_rose.use_petal()
	assert_true(_rose.petals() < _rose.max_petals())
	watch_signal(_service, &"rested")
	assert_true(_service.rest_at(RegionIds.WAYSTATION_CLIFF))
	assert_eq(_rose.petals(), _rose.max_petals(), "the Rose is whole")
	assert_eq(_respawns, 1, "and the layer was asked to put the ambient dead back")
	assert_signal_emitted(_service, &"rested", 1)
	assert_eq(_service.last_waystation_id(), RegionIds.WAYSTATION_CLIFF)
	assert_true(_service.has_visited(RegionIds.WAYSTATION_CLIFF))


func test_resting_at_a_shrine_in_another_region_is_refused() -> void:
	_service.travel_to(RegionIds.CLIFF)
	assert_false(_service.rest_at(RegionIds.WAYSTATION_PRESTIGE))
	assert_false(_service.rest_at(&"WAYSTATION_NOWHERE"))
	assert_eq(_service.last_waystation_id(), RegionService.UNSET)


func test_standing_in_the_circle_is_what_lets_the_spread_be_respecced() -> void:
	# `progression.md` §Waystations: "Respec the Pocket Spread - save, name, and switch
	# between full loadouts." The rule is the Spread's; being there is this service's.
	_service.travel_to(RegionIds.CLIFF)
	assert_false(_spread.at_waystation())
	watch_signal(_service, &"waystation_entered")
	assert_true(_service.enter_waystation(RegionIds.WAYSTATION_CLIFF))
	assert_true(_spread.at_waystation())
	assert_eq(_service.at_waystation_id(), RegionIds.WAYSTATION_CLIFF)
	assert_signal_emitted(_service, &"waystation_entered", 1)
	_service.leave_waystation()
	assert_false(_spread.at_waystation())
	assert_eq(_service.at_waystation_id(), RegionService.UNSET)


func test_leaving_a_region_leaves_its_waystation() -> void:
	_service.travel_to(RegionIds.CLIFF)
	_service.enter_waystation(RegionIds.WAYSTATION_CLIFF)
	_service.travel_to(RegionIds.PRESTIGE)
	assert_eq(_service.at_waystation_id(), RegionService.UNSET)
	assert_false(_spread.at_waystation(), "no respeccing halfway to the carnival")


func test_arriving_on_a_waystation_marker_is_standing_at_it() -> void:
	_service.travel_to(RegionIds.CLIFF)
	_service.travel_to(RegionIds.PRESTIGE, RegionIds.WAYSTATION_PRESTIGE)
	assert_eq(_service.at_waystation_id(), RegionIds.WAYSTATION_PRESTIGE)


# --- Fast travel ---------------------------------------------------------------------


func test_fast_travel_is_refused_until_the_chariot_is_unbound() -> void:
	# `progression.md` §Waystations: Waystations "become fast-travel points world-wide
	# once `WS_CHARIOT_UNBOUND` fires... before that they are rest-only, keeping early
	# traversal grounded in the physical world".
	_service.travel_to(RegionIds.PRESTIGE)
	_service.rest_at(RegionIds.WAYSTATION_PRESTIGE)
	_service.travel_to(RegionIds.LONGROAD)
	_service.rest_at(RegionIds.WAYSTATION_LONGROAD_N)
	assert_eq(
		_service.fast_travel_refusal(RegionIds.WAYSTATION_PRESTIGE),
		RegionService.REASON_NO_FAST_TRAVEL
	)
	assert_false(_service.fast_travel_to(RegionIds.WAYSTATION_PRESTIGE))
	assert_eq(_service.current_region_id(), RegionIds.LONGROAD, "and nobody moved")


func test_fast_travel_crosses_the_spread_once_the_chariot_is_unbound() -> void:
	_world_state.fire(WorldStateIds.WS_CHARIOT_UNBOUND, QuestIds.MQ07)
	_world_state.fire(WorldStateIds.WS_DEATH_UNBOUND, QuestIds.MQ13)
	_service.travel_to(RegionIds.PRESTIGE)
	_service.rest_at(RegionIds.WAYSTATION_PRESTIGE)
	_service.travel_to(RegionIds.LONGROAD)
	_service.travel_to(RegionIds.HOLLOWS)
	_service.rest_at(RegionIds.WAYSTATION_HOLLOWS)
	watch_signal(_service, &"fast_travelled")
	# `progression.md` §Waystations makes the network "world-wide": the terraces are two
	# regions deep and no road runs from them back to the carnival, and the Fool goes
	# anyway, because the shrine at the far end is one they have slept at.
	assert_false(_service.is_adjacent(RegionIds.HOLLOWS, RegionIds.PRESTIGE))
	assert_true(_service.fast_travel_to(RegionIds.WAYSTATION_PRESTIGE))
	assert_eq(_service.current_region_id(), RegionIds.PRESTIGE)
	assert_eq(_service.at_waystation_id(), RegionIds.WAYSTATION_PRESTIGE)
	assert_signal_emitted(_service, &"fast_travelled", 1)


func test_fast_travel_does_not_ask_the_roads_anything() -> void:
	# A Waystation the Fool has slept at is one they walked to, which means they
	# already opened whatever stood in the way. Asking the gate a second time would
	# refuse a journey the player has demonstrably earned.
	_world_state.fire(WorldStateIds.WS_CHARIOT_UNBOUND, QuestIds.MQ07)
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	_service.travel_to(RegionIds.MIRRORMARSH)
	_service.rest_at(RegionIds.WAYSTATION_MIRRORMARSH)
	_service.travel_to(RegionIds.LONGROAD)
	_service.rest_at(RegionIds.WAYSTATION_LONGROAD_N)
	assert_true(_service.fast_travel_to(RegionIds.WAYSTATION_MIRRORMARSH))
	assert_eq(_service.current_region_id(), RegionIds.MIRRORMARSH)


func test_fast_travel_goes_only_to_shrines_the_fool_has_slept_at() -> void:
	_world_state.fire(WorldStateIds.WS_CHARIOT_UNBOUND, QuestIds.MQ07)
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	assert_eq(
		_service.fast_travel_refusal(RegionIds.WAYSTATION_PRESTIGE),
		RegionService.REASON_NOT_VISITED,
		"a shrine nobody has found is not a place to appear at"
	)
	assert_false(_service.fast_travel_to(RegionIds.WAYSTATION_PRESTIGE))


func test_fast_travel_starts_at_a_waystation() -> void:
	# `progression.md` §Waystations lists fast travel among the things the Fool can do
	# **at a Waystation**; it is not a menu item to be used mid-field.
	_world_state.fire(WorldStateIds.WS_CHARIOT_UNBOUND, QuestIds.MQ07)
	_service.travel_to(RegionIds.PRESTIGE)
	_service.rest_at(RegionIds.WAYSTATION_PRESTIGE)
	_service.travel_to(RegionIds.LONGROAD)
	_service.rest_at(RegionIds.WAYSTATION_LONGROAD_N)
	_service.leave_waystation()
	assert_eq(
		_service.fast_travel_refusal(RegionIds.WAYSTATION_PRESTIGE),
		RegionService.REASON_NOT_AT_WAYSTATION
	)


func test_fast_travel_never_returns_to_the_cliff() -> void:
	# `world.md` §Layout: the Cliff "touches nothing: its only exit is the one-way leap
	# to the Prestige crossroads (MQ00), and it is outside the Waystation network - no
	# fast travel returns there", which `progression.md` §Waystations repeats. The leap
	# is the game's opening image and it is meant to be final: a network that carried
	# the Fool back up would undo the one thing MQ00 is about.
	_world_state.fire(WorldStateIds.WS_CHARIOT_UNBOUND, QuestIds.MQ07)
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	_service.travel_to(RegionIds.PRESTIGE)
	_service.rest_at(RegionIds.WAYSTATION_PRESTIGE)
	assert_true(
		_service.has_visited(RegionIds.WAYSTATION_CLIFF),
		"the Fool slept at the Cliff's shrine and the save remembers it"
	)
	assert_eq(
		_service.fast_travel_refusal(RegionIds.WAYSTATION_CLIFF),
		RegionService.REASON_OUTSIDE_NETWORK,
		"and the refusal says why, rather than pretending they never found it"
	)
	assert_false(_service.fast_travel_to(RegionIds.WAYSTATION_CLIFF))
	assert_eq(_service.current_region_id(), RegionIds.PRESTIGE, "nobody leapt back up")


func test_the_cliffs_shrine_is_still_a_shrine() -> void:
	# The exclusion is from the NETWORK and from nothing else: MQ00's first rest happens
	# at that shrine, and a defeat on the plateau still wakes the Fool there.
	_service.travel_to(RegionIds.CLIFF)
	assert_true(_service.rest_at(RegionIds.WAYSTATION_CLIFF), "resting there is untouched")
	assert_eq(_service.last_waystation_id(), RegionIds.WAYSTATION_CLIFF)
	_rose.use_petal()
	_combat.fool_defeated.emit(1, 0)
	assert_eq(_service.current_region_id(), RegionIds.CLIFF, "and a defeat wakes them there")


func test_fast_travel_within_a_region_walks_rather_than_reloads() -> void:
	_world_state.fire(WorldStateIds.WS_CHARIOT_UNBOUND, QuestIds.MQ07)
	_service.travel_to(RegionIds.LONGROAD)
	_service.rest_at(RegionIds.WAYSTATION_LONGROAD_N)
	_service.rest_at(RegionIds.WAYSTATION_LONGROAD_S)
	var swaps_before := _swaps.size()
	assert_true(_service.fast_travel_to(RegionIds.WAYSTATION_LONGROAD_N))
	assert_eq(_swaps.size(), swaps_before, "the Longroad was not thrown away and rebuilt")
	assert_eq(_anchors, [RegionIds.WAYSTATION_LONGROAD_N] as Array[StringName])
	assert_eq(_service.at_waystation_id(), RegionIds.WAYSTATION_LONGROAD_N)


# --- The defeat loop -------------------------------------------------------------------


func test_a_defeat_wakes_the_fool_at_the_last_waystation_rested_at() -> void:
	# `combat.md` §Defeat: "the Fool wakes at the last Waystation rested at, White Rose
	# regrown". The walk back crosses regions when it has to - the Fool went down a
	# long way from where they slept.
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	_service.travel_to(RegionIds.PRESTIGE)
	_rose.use_petal()
	_combat.fool_defeated.emit(1, 0)
	assert_eq(_service.current_region_id(), RegionIds.CLIFF, "back at the shrine they slept at")
	assert_eq(_swaps.back(), [CLIFF_SCENE, RegionIds.WAYSTATION_CLIFF])
	assert_eq(_rose.petals(), _rose.max_petals(), "and the Rose is whole again")


func test_a_defeat_in_the_region_the_fool_slept_in_does_not_reload_it() -> void:
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	var swaps_before := _swaps.size()
	_combat.fool_defeated.emit(1, 0)
	assert_eq(_swaps.size(), swaps_before, "nothing was freed; they only walked back")
	assert_eq(_anchors.back(), RegionIds.WAYSTATION_CLIFF)


func test_a_defeat_before_the_first_rest_wakes_the_fool_where_they_fell() -> void:
	# A Fool can be put down on the Cliff before ever reaching the Waystation, and the
	# gentlest reading of "no penalty beyond the walk back" is the shrine of the region
	# they fell in.
	_service.travel_to(RegionIds.CLIFF)
	assert_eq(_service.last_waystation_id(), RegionService.UNSET)
	_combat.fool_defeated.emit(1, 0)
	assert_eq(_service.current_region_id(), RegionIds.CLIFF)
	assert_eq(_anchors.back(), RegionIds.WAYSTATION_CLIFF)


func test_a_defeat_never_strands_the_fool_when_the_walk_back_cannot_happen() -> void:
	# `combat.md` §Defeat promises a loop that always closes: "the Fool wakes at the last
	# Waystation rested at, White Rose regrown... no penalty beyond the walk back". The
	# shrine they slept at is in a region the game has to be able to DRAW, and twenty of
	# the twenty-two have no scene yet - so a save carried across a build that dropped
	# one, or a layer that will not take the swap, must not leave the Fool lying in a
	# region nobody walked back from with no revive and no way up.
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	_service.travel_to(RegionIds.PRESTIGE)
	# The layer now answers every swap with "I cannot load that scene", which is what
	# `PersistentLayer.swap()` says about a region file that is not there.
	_service.set_swapper(RegionSwapper.new(_refuse_swap, _record_anchor, _record_respawn))
	_rose.use_petal()
	_combat.fool_defeated.emit(1, 0)
	assert_eq(
		_service.current_region_id(),
		RegionIds.PRESTIGE,
		"the walk back to the Cliff could not happen, and the Fool did not half-move"
	)
	assert_eq(
		_anchors.back(),
		RegionIds.WAYSTATION_PRESTIGE,
		"so they woke at the shrine of the region they fell in"
	)
	assert_eq(_service.at_waystation_id(), RegionIds.WAYSTATION_PRESTIGE)
	assert_eq(_rose.petals(), _rose.max_petals(), "and they were revived, not left down")


func test_a_region_the_layer_will_not_load_is_not_travelled_to() -> void:
	# The other half of the same rule, and the reason the fallback above can be trusted:
	# a swapper answers whether it TOOK the request, and a refusal means the Fool never
	# arrived - so the save must not be told they did.
	_service.travel_to(RegionIds.CLIFF)
	_service.set_swapper(RegionSwapper.new(_refuse_swap, _record_anchor, _record_respawn))
	watch_signal(_service, &"region_changed")
	assert_false(_service.travel_to(RegionIds.PRESTIGE))
	assert_eq(_service.current_region_id(), RegionIds.CLIFF, "still where they were")
	assert_eq(_rose.region_id(), RegionIds.CLIFF, "and the Rose was never told otherwise")
	assert_signal_emitted(_service, &"region_changed", 0)


func test_the_walk_back_can_be_held_while_the_defeat_beat_plays() -> void:
	# `combat.md` §Defeat is a sequence: the fall, Pip's lick, the fade, and only then
	# the Waystation. Nothing draws that yet, so the return is immediate by default and
	# this is the seam that will hold it.
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	_service.travel_to(RegionIds.PRESTIGE)
	_service.hold_defeat_return(true)
	_combat.fool_defeated.emit(1, 0)
	assert_eq(_service.current_region_id(), RegionIds.PRESTIGE, "still lying where they fell")
	_service.hold_defeat_return(false)
	assert_eq(_service.current_region_id(), RegionIds.CLIFF, "and up once the beat is over")


# --- The save ----------------------------------------------------------------------------


func test_where_the_fool_is_round_trips_through_the_save() -> void:
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	_service.travel_to(RegionIds.PRESTIGE)
	_service.rest_at(RegionIds.WAYSTATION_PRESTIGE)
	var written := _save.capture()
	if not assert_not_null(written, "the playthrough captures"):
		return

	# A load builds a fresh world and fills it - `SaveService.apply()` refuses any
	# other kind (`technical.md` §Save system), which is what `Services.load_game()`
	# does for real.
	var loaded_json := SaveModel.from_dictionary(written.to_dictionary())
	var world_state := _fresh_world_state()
	var save := SaveService.new(world_state, GameClock.new(), SAVES_DIR)
	assert_eq(save.apply(loaded_json), PackedStringArray(), "it loads")
	var service := RegionService.new(_service.catalog(), _service.graph(), world_state, save)
	assert_eq(service.current_region_id(), RegionIds.PRESTIGE)
	assert_eq(service.last_waystation_id(), RegionIds.WAYSTATION_PRESTIGE)
	assert_true(service.has_visited(RegionIds.WAYSTATION_CLIFF), "both shrines are remembered")
	assert_true(service.has_visited(RegionIds.WAYSTATION_PRESTIGE))


func test_the_visited_set_is_append_only() -> void:
	# Every container in a save is (`technical.md` §Save system). A shrine the Fool has
	# slept at is a place they know, and there is no call anywhere that takes it back.
	_service.travel_to(RegionIds.CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	_service.rest_at(RegionIds.WAYSTATION_CLIFF)
	assert_eq(_service.visited_waystations(), [RegionIds.WAYSTATION_CLIFF] as Array[StringName])
	for method: Dictionary in _save.get_method_list():
		var name_text: String = method["name"]
		assert_false(
			name_text.contains("forget") or name_text.contains("unvisit"),
			"nothing on the save service takes a Waystation back: %s" % name_text
		)


# --- Fixtures -------------------------------------------------------------------------


## Build the service over a synthetic Spread and a fake layer.
func _build(pair: Array) -> void:
	var catalog: RegionCatalog = pair[0]
	var graph: RegionGraph = pair[1]
	_world_state = _fresh_world_state()
	_clock = GameClock.new()
	var rules := load(SPREAD_RULES_PATH) as SpreadRules
	var fortune := FortuneService.new(rules)
	_spread = PocketSpreadService.new(
		_world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, rules, fortune
	)
	_rose = WhiteRoseService.new(_world_state, rules)
	_combat = CombatService.new(
		load(COMBAT_RULES_PATH) as CombatRules, fortune, _spread, _rose, _clock
	)
	_save = SaveService.new(_world_state, _clock, SAVES_DIR, null, _spread, fortune, _rose)
	_service = RegionService.new(
		catalog, graph, _world_state, _save, _rose, _spread, _combat
	)
	_service.set_swapper(RegionSwapper.new(_record_swap, _record_anchor, _record_respawn))
	_fool = Combatant.new()
	_fool.faction = Faction.Id.FOOL
	_combat.register_fool(_fool)


func _fresh_world_state() -> WorldStateService:
	return WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)


## A small Spread with one of everything the service has to answer for: a one-way leap,
## an ordinary road, a region nobody has built, a flag-gated way in, a light-gated way
## in, and a region with more than one Waystation.
func _spread_of_five() -> Array:
	var catalog := RegionCatalog.new()
	catalog.entries = [
		_region(RegionIds.CLIFF, 0, &"", CLIFF_SCENE, [RegionIds.WAYSTATION_CLIFF]),
		_region(
			RegionIds.PRESTIGE,
			1,
			WorldStateIds.WS_MAGICIAN_UNBOUND,
			PRESTIGE_SCENE,
			[RegionIds.WAYSTATION_PRESTIGE]
		),
		_region(
			RegionIds.BOWER,
			3,
			WorldStateIds.WS_EMPRESS_UNBOUND,
			MISSING_SCENE,
			[RegionIds.WAYSTATION_BOWER]
		),
		_region(
			RegionIds.LONGROAD,
			7,
			WorldStateIds.WS_CHARIOT_UNBOUND,
			PRESTIGE_SCENE,
			[RegionIds.WAYSTATION_LONGROAD_N, RegionIds.WAYSTATION_LONGROAD_S]
		),
		_region(
			RegionIds.MIRRORMARSH,
			18,
			WorldStateIds.WS_MOON_UNBOUND,
			PRESTIGE_SCENE,
			[RegionIds.WAYSTATION_MIRRORMARSH]
		),
		_region(
			RegionIds.HOLLOWS,
			20,
			WorldStateIds.WS_JUDGEMENT_UNBOUND,
			PRESTIGE_SCENE,
			[RegionIds.WAYSTATION_HOLLOWS]
		),
	]
	var graph := RegionGraph.new()
	# `world.md` §Layout: the Cliff "is outside the Waystation network - no fast travel
	# returns there". The synthetic Spread carries the real rule, because a fixture that
	# quietly left it out would let the suite prove the opposite of the doc.
	graph.fast_travel_network_excludes = [RegionIds.WAYSTATION_CLIFF]
	graph.edges = [
		_edge(RegionIds.CLIFF, RegionIds.PRESTIGE, RegionEdge.Kind.LEAP),
		_edge(RegionIds.PRESTIGE, RegionIds.BOWER, RegionEdge.Kind.ROAD),
		_edge(RegionIds.PRESTIGE, RegionIds.LONGROAD, RegionEdge.Kind.ROAD),
		_gated_edge(
			RegionIds.LONGROAD,
			RegionIds.HOLLOWS,
			RegionIds.HOLLOWS,
			[WorldStateIds.WS_DEATH_UNBOUND],
			[],
			[]
		),
		_gated_edge(
			RegionIds.LONGROAD,
			RegionIds.MIRRORMARSH,
			RegionIds.MIRRORMARSH,
			[],
			[WorldStateIds.WS_SUN_UNBOUND],
			[TrumpIds.TRUMP_09, TrumpIds.TRUMP_17]
		),
	]
	return [catalog, graph]


func _region(
	region_id: StringName,
	card: int,
	flag: StringName,
	scene_path: String,
	waystations: Array[StringName]
) -> RegionDefinition:
	var definition := RegionDefinition.new()
	definition.id = region_id
	definition.card_number = card
	definition.name_key = StringName("REGION_%s_NAME" % region_id)
	definition.unbinding_flag = flag
	definition.scene_path = scene_path
	definition.waystation_ids = waystations
	definition.doc_ref = "a test fixture, not the Spread"
	return definition


func _edge(a: StringName, b: StringName, kind: RegionEdge.Kind) -> RegionEdge:
	var edge := RegionEdge.new()
	edge.a = a
	edge.b = b
	edge.kind = kind
	edge.notes = "a test fixture, not §Layout"
	return edge


func _gated_edge(
	a: StringName,
	b: StringName,
	gated_end: StringName,
	musts: Array[StringName],
	any_flags: Array[StringName],
	any_trumps: Array[StringName]
) -> RegionEdge:
	var edge := _edge(a, b, RegionEdge.Kind.ROAD)
	edge.gates_entry_to = gated_end
	edge.requires_fired = musts
	edge.requires_any_fired = any_flags
	edge.requires_any_trump_held = any_trumps
	return edge


# --- The fake layer ---------------------------------------------------------------------


func _record_swap(scene_path: String, arrival: StringName) -> bool:
	_swaps.append([scene_path, arrival])
	return true


## A layer that cannot load the scene it was handed - what `PersistentLayer.swap()`
## answers for a region file that is not in the project.
func _refuse_swap(scene_path: String, arrival: StringName) -> bool:
	_swaps.append([scene_path, arrival])
	return false


func _record_anchor(arrival: StringName) -> bool:
	_anchors.append(arrival)
	return true


func _record_respawn() -> int:
	_respawns += 1
	return _respawns
