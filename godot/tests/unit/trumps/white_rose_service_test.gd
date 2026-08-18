extends TarrockTest

## The White Rose: petals, graftings, rest, and the region rule.
##
## `docs/design/progression.md` §The White Rose is the canon: 3 petals to start, 8
## at most, one petal per heal, full regrowth on a Waystation rest, slow regrowth in
## an unbound region, and **none at all in a still-bound one** - "stasis means
## nothing grows, including the Fool's own healing".
##
## The last rule is the one worth breaking a test over, so it is proven in all three
## states: a bound region, the same region after its Arcana is unbound, and the
## Cliff, which has no Arcana and therefore no unbinding at all.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"

## The Cliff's region token and its unbinding flag - which is none (world.md §The
## Cliff: it has no Arcana), the case `scripts/the_cliff.gd` passes in.
const CLIFF := &"CLIFF"
const NO_UNBINDING := &""

## A region with an Arcana: the Prestige, unbound by MQ01.
const PRESTIGE := &"PRESTIGE"

var _rules: SpreadRules = null
var _world_state: WorldStateService = null
var _rose: WhiteRoseService = null


func before_each() -> void:
	_rules = (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_rose = WhiteRoseService.new(_world_state, _rules)


# --- Petals ------------------------------------------------------------------


func test_the_rose_starts_at_three_petals() -> void:
	assert_eq(_rose.petals(), 3, "progression.md: starting capacity is 3 petals")
	assert_eq(_rose.max_petals(), 3, "and nothing has raised the capacity yet")
	assert_eq(_rose.graftings(), 0)
	assert_true(_rose.is_pristine())


func test_a_petal_is_one_heal() -> void:
	watch_signal(_rose, &"petal_used")
	watch_signal(_rose, &"petals_changed")
	assert_true(_rose.use_petal())
	assert_eq(_rose.petals(), 2)
	assert_signal_emitted(_rose, &"petal_used", 1)
	assert_eq(signal_arguments(_rose, &"petals_changed", 0), [3, 2])


func test_an_empty_rose_has_nothing_to_spend() -> void:
	for _index: int in 3:
		_rose.use_petal()
	assert_eq(_rose.petals(), 0)
	assert_false(_rose.use_petal(), "the Fool at zero petals falls; combat owns what happens next")


# --- Graftings ---------------------------------------------------------------


func test_a_grafting_raises_the_maximum_and_arrives_grown() -> void:
	watch_signal(_rose, &"max_petals_changed")
	assert_true(_rose.add_grafting())
	assert_eq(_rose.max_petals(), 4)
	assert_eq(_rose.petals(), 4, "a grafting found in the world is a flower, not a promise")
	assert_eq(signal_arguments(_rose, &"max_petals_changed", 0), [3, 4])


func test_graftings_stop_at_eight_petals() -> void:
	for _index: int in 5:
		assert_true(_rose.add_grafting())
	assert_eq(_rose.max_petals(), 8, "progression.md caps the Rose at 8")
	assert_eq(_rose.graftings_remaining(), 0)
	assert_false(_rose.add_grafting(), "a sixth grafting is refused")
	assert_eq(_rose.max_petals(), 8)


# --- Rest --------------------------------------------------------------------


func test_resting_a_full_rose_is_still_a_mutation() -> void:
	# A rest changes no number here, but it happened: the Rose has been played, and a
	# save must no longer load into it (`SaveService.apply()` asks `is_pristine()`).
	# `_set_petals()` alone would have left this Rose looking untouched.
	assert_eq(_rose.petals(), _rose.max_petals(), "nothing has been spent yet")
	_rose.rest()
	assert_eq(_rose.petals(), 3, "and nothing changed")
	assert_false(_rose.is_pristine(), "but the Rose has been rested; a load is not a reset")


func test_resting_regrows_every_petal() -> void:
	_rose.add_grafting()
	_rose.use_petal()
	_rose.use_petal()
	assert_eq(_rose.petals(), 2)
	_rose.rest()
	assert_eq(_rose.petals(), 4, "a Waystation rest fills the Rose, instantly")


# --- Regrowth by region ------------------------------------------------------


func test_a_bound_region_regrows_nothing() -> void:
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.use_petal()
	assert_false(_rose.regrows_here(), "the Magician is still bound")
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 10.0)
	assert_eq(_rose.petals(), 2, "stasis means nothing grows, the Rose included")


func test_unbinding_the_region_starts_the_rose_growing() -> void:
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.use_petal()
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	assert_true(_rose.regrows_here(), "the world woke up around the Fool")
	watch_signal(_rose, &"regrown")
	_rose.tick(_rules.rose_regrow_seconds_per_petal)
	assert_eq(_rose.petals(), 3)
	assert_signal_emitted(_rose, &"regrown", 1)


func test_a_region_already_unbound_when_the_fool_arrives_regrows() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.use_petal()
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	assert_true(_rose.regrows_here())
	_rose.tick(_rules.rose_regrow_seconds_per_petal)
	assert_eq(_rose.petals(), 3)


func test_a_load_teaches_the_rose_its_region_woke_when_it_is_told_again() -> void:
	# The load path, exactly: `WorldStateService.restore_snapshot()` emits nothing, so
	# `_on_world_state_fired()` never runs and the Rose's cached "is this region
	# awake" would still say no. The Regions round tells the Rose where the Fool is
	# after a load - with the SAME region and flag it was already standing in - and
	# that call is the only moment the Rose can notice. An early return on unchanged
	# arguments would strand it in a region that woke up while it was not looking.
	var world := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var rose := WhiteRoseService.new(world, _rules)
	rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	assert_false(rose.regrows_here(), "the Magician is still bound in this fresh world")

	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	assert_eq(
		world.restore_snapshot(_world_state.to_snapshot()),
		PackedStringArray(),
		"the saved world loads"
	)
	assert_true(world.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "and it woke the Prestige")

	rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	assert_true(rose.regrows_here(), "so the Rose regrows once it is told where it is")
	rose.use_petal()
	rose.tick(_rules.rose_regrow_seconds_per_petal)
	assert_eq(rose.petals(), 3, "and a petal comes back")


func test_being_told_the_same_bound_region_again_banks_nothing_extra() -> void:
	# The other half of the same call: only the banked regrowth is behind the
	# "did anything change" check, so a repeated call must not silently reset a
	# petal that is halfway grown.
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.use_petal()
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 0.6)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 0.4)
	assert_eq(_rose.petals(), 3, "the banked six tenths survived being told again")


func test_the_cliff_never_regrows() -> void:
	# The Cliff has no Arcana and no unbinding (world.md §The Cliff), so it is
	# outside the Spread entirely - and MQ00's Waystation rest is meant to be the
	# first time the player sees petals come back.
	_rose.set_region(CLIFF, NO_UNBINDING)
	_rose.use_petal()
	assert_false(_rose.regrows_here())
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 100.0)
	assert_eq(_rose.petals(), 2, "nothing grows on the Cliff")
	_rose.rest()
	assert_eq(_rose.petals(), 3, "but resting there still works")


func test_regrowth_stops_at_the_capacity() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.use_petal()
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 20.0)
	assert_eq(_rose.petals(), 3, "a full Rose grows no further")


func test_banked_regrowth_does_not_travel() -> void:
	# Walking out of a living region and back must not resume a petal that was
	# nearly grown somewhere else.
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.use_petal()
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 0.9)
	_rose.set_region(CLIFF, NO_UNBINDING)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 0.5)
	assert_eq(_rose.petals(), 2, "the walk did not finish the petal")
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 0.5)
	assert_eq(_rose.petals(), 3, "a full period in one place does")


func test_a_long_frame_regrows_at_most_the_capacity() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.use_petal()
	_rose.use_petal()
	_rose.use_petal()
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 2.0)
	assert_eq(_rose.petals(), 2, "one petal per period, however long the frame")


# --- Save --------------------------------------------------------------------


func test_a_snapshot_round_trips() -> void:
	_rose.add_grafting()
	_rose.add_grafting()
	_rose.use_petal()
	var loaded := WhiteRoseService.new(_world_state, _rules)
	assert_eq(loaded.restore_snapshot(_rose.to_snapshot()), PackedStringArray())
	assert_eq(loaded.petals(), _rose.petals())
	assert_eq(loaded.graftings(), _rose.graftings())
	assert_eq(loaded.max_petals(), _rose.max_petals())


func test_a_snapshot_survives_json() -> void:
	_rose.add_grafting()
	_rose.use_petal()
	var parsed: Variant = JSON.parse_string(JSON.stringify(_rose.to_snapshot()))
	if not assert_true(parsed is Dictionary):
		return
	var loaded := WhiteRoseService.new(_world_state, _rules)
	assert_eq(loaded.restore_snapshot(parsed as Dictionary), PackedStringArray())
	assert_eq(loaded.petals(), _rose.petals())


func test_a_played_rose_refuses_a_load() -> void:
	_rose.use_petal()
	var problems := _rose.restore_snapshot({WhiteRoseService.SNAPSHOT_PETALS: 8})
	assert_eq(problems.size(), 1, "a load is not a reset")
	assert_eq(_rose.petals(), 2)


func test_a_snapshot_with_more_petals_than_graftings_allow_is_refused() -> void:
	var loaded := WhiteRoseService.new(_world_state, _rules)
	var problems := loaded.restore_snapshot({
		WhiteRoseService.SNAPSHOT_PETALS: 8,
		WhiteRoseService.SNAPSHOT_GRAFTINGS: 0,
	})
	assert_eq(problems.size(), 1, "eight petals need five graftings")
	assert_eq(loaded.petals(), 3, "and nothing was committed")


func test_a_snapshot_with_impossible_graftings_is_refused() -> void:
	var loaded := WhiteRoseService.new(_world_state, _rules)
	var problems := loaded.restore_snapshot({
		WhiteRoseService.SNAPSHOT_PETALS: 3,
		WhiteRoseService.SNAPSHOT_GRAFTINGS: 99,
	})
	assert_eq(problems.size(), 1, "there are only five graftings to find")
