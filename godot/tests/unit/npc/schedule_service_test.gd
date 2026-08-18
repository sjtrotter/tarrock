extends TarrockTest

## `ScheduleService`: the anchor lookup behind §Daily life. A pure lookup - nothing
## here ticks or moves a body - so these tests only ever ask "which anchor, right
## now" and check the three rules the doc states: no time of day before
## `WS_SUN_UNBOUND`, a bound region stays in its tableau regardless, and a schedule
## variant only applies once its own unbinding has fired.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

const BOUND_REGION := &"TEST_BOUND"
const UNBOUND_REGION := &"TEST_UNBOUND"

var _world_state: WorldStateService = null
var _regions: RegionCatalog = null
var _rules: NpcRules = null
var _service: ScheduleService = null


func before_each() -> void:
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_regions = _region_catalog()
	_rules = _npc_rules()
	_service = ScheduleService.new(_rules, _world_state, _regions)


func test_no_time_of_day_before_the_sun_is_unbound() -> void:
	assert_false(_service.has_time_of_day())
	assert_eq(_service.band_at(_hours(12.0)), TimeBand.Id.NONE)


func test_time_of_day_arrives_with_the_sun() -> void:
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	assert_true(_service.has_time_of_day())
	assert_eq(_service.band_at(_hours(12.0)), TimeBand.Id.DAY)
	assert_eq(_service.band_at(_hours(2.0)), TimeBand.Id.NIGHT)


func test_a_bound_region_holds_its_tableau_regardless_of_the_sun() -> void:
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	var profile := _profile(BOUND_REGION)
	var anchor := _service.anchor_for(profile, TimeBand.Id.DAY)
	assert_eq(anchor, profile.home_anchor, "the bound region's tableau anchor, not the day's")


func test_before_the_sun_every_region_answers_with_its_tableau() -> void:
	var profile := _profile(UNBOUND_REGION)
	var anchor := _service.anchor_for(profile, TimeBand.Id.DAY)
	assert_eq(anchor, profile.tableau_anchor())


func test_an_unbound_region_reads_the_schedule_once_the_sun_is_up() -> void:
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	var profile := _profile(UNBOUND_REGION)
	assert_eq(_service.anchor_for(profile, TimeBand.Id.DAY), &"WORK_MARKER")
	assert_eq(_service.anchor_for(profile, TimeBand.Id.NIGHT), &"HOME_MARKER")


func test_a_variant_only_applies_once_its_unbinding_has_fired() -> void:
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	var profile := _profile(UNBOUND_REGION)
	assert_eq(
		_service.anchor_for(profile, TimeBand.Id.DAY),
		&"WORK_MARKER",
		"the wedding is not active yet; the base entry wins"
	)
	assert_false(_service.is_variant_active(ScheduleVariant.Kind.WEDDING))

	_world_state.fire(WorldStateIds.WS_HIEROPHANT_UNBOUND, QuestIds.MQ05)
	assert_true(_service.is_variant_active(ScheduleVariant.Kind.WEDDING))
	assert_eq(
		_service.anchor_for(profile, TimeBand.Id.DAY),
		&"WEDDING_MARKER",
		"now the variant entry beats the base one"
	)


func test_the_cliff_is_never_bound_even_with_no_unbinding_flag() -> void:
	var cliff := RegionDefinition.new()
	cliff.id = RegionIds.CLIFF
	cliff.unbinding_flag = &""
	var catalog := RegionCatalog.new()
	catalog.entries = [cliff]
	var service := ScheduleService.new(_rules, _world_state, catalog)
	assert_false(service.is_region_bound(RegionIds.CLIFF), "the Cliff has no Arcana to hold it")


# --- Internals ---------------------------------------------------------------


func _hours(hour: float) -> float:
	return hour * _rules.seconds_per_in_game_hour


func _npc_rules() -> NpcRules:
	var rules := NpcRules.new()
	rules.id = &"NPC_RULES_TEST"
	rules.recent_pick_memory = 3
	rules.seconds_per_in_game_hour = 3600.0
	rules.hours_per_day = 24.0
	rules.time_band_start_hours = PackedFloat32Array([0, 5, 8, 18, 21])

	var wedding := ScheduleVariant.new()
	wedding.kind = ScheduleVariant.Kind.WEDDING
	wedding.when_fired = WorldStateIds.WS_HIEROPHANT_UNBOUND
	rules.schedule_variants = [wedding]
	return rules


func _region_catalog() -> RegionCatalog:
	var bound := RegionDefinition.new()
	bound.id = BOUND_REGION
	bound.unbinding_flag = WorldStateIds.WS_EMPRESS_UNBOUND

	var unbound := RegionDefinition.new()
	unbound.id = UNBOUND_REGION
	unbound.unbinding_flag = WorldStateIds.WS_MAGICIAN_UNBOUND
	# `_world_state` is already built (`before_each` sets it before calling this), so
	# UNBOUND_REGION starts awake and BOUND_REGION starts held - the two fixtures the
	# suite's names promise.
	_world_state.fire(unbound.unbinding_flag, QuestIds.MQ01)

	var catalog := RegionCatalog.new()
	catalog.entries = [bound, unbound]
	return catalog


func _profile(home_region: StringName) -> NpcProfile:
	var profile := NpcProfile.new()
	profile.id = &"NPC_TEST"
	profile.name_key = &"NPC_TEST_NAME"
	profile.home_region = home_region
	profile.home_anchor = &"HOME_MARKER"
	profile.work_anchor = &"WORK_MARKER"

	var work_entry := ScheduleEntry.new()
	work_entry.time_band = TimeBand.Id.DAY
	work_entry.anchor = &"WORK_MARKER"
	var home_entry := ScheduleEntry.new()
	home_entry.time_band = TimeBand.Id.NIGHT
	home_entry.anchor = &"HOME_MARKER"
	var wedding_entry := ScheduleEntry.new()
	wedding_entry.time_band = TimeBand.Id.DAY
	wedding_entry.anchor = &"WEDDING_MARKER"
	wedding_entry.variant = ScheduleVariant.Kind.WEDDING
	profile.schedule = [work_entry, home_entry, wedding_entry]
	return profile
