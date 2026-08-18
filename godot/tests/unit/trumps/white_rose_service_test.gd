extends TarrockTest

## The White Rose: the Fool's health. Quarters, petals, graftings, rest, the defeat
## thresholds, and the region rule.
##
## `docs/design/progression.md` §The White Rose is the canon for the shape: 3 petals
## to start, 8 at most, full regrowth on a Waystation rest, slow regrowth in an
## unbound region, and **none at all in a still-bound one** - "stasis means nothing
## grows, including the Fool's own healing". The director's ruling on issue #11 is the
## canon for what the petals ARE: the health itself, with no second pool beside them
## and no button to spend one.
##
## The region rule is the one worth breaking a test over, so it is proven in all three
## states: a bound region, the same region after its Arcana is unbound, and the Cliff,
## which has no Arcana and therefore no unbinding at all.

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

## One whole petal, in the quarters everything internal is counted in.
const PETAL := WhiteRoseService.QUARTERS_PER_PETAL

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


# --- Petals and quarters ------------------------------------------------------


func test_the_rose_starts_whole_at_three_petals() -> void:
	assert_eq(_rose.petals(), 3, "progression.md: starting capacity is 3 petals")
	assert_eq(_rose.max_petals(), 3, "and nothing has raised the capacity yet")
	assert_eq(_rose.quarters(), 12, "counted four to a petal")
	assert_eq(_rose.max_quarters(), 12)
	assert_eq(_rose.graftings(), 0)
	assert_false(_rose.is_bare())
	assert_true(_rose.is_pristine())


func test_a_part_torn_petal_is_still_a_petal() -> void:
	# `arcana.md` writes its hooks in petals ("at one petal remaining"), so the whole
	# count has to round the way a player reads a flower: a petal with a quarter left
	# on it is still on the Rose.
	_rose.take_damage(1)
	assert_eq(_rose.quarters(), 11)
	assert_eq(_rose.petals(), 3, "three petals, one of them nicked")
	assert_almost_eq(_rose.petals_left(), 2.75, 0.0001, "and the meter draws the nick")
	_rose.take_damage(10)
	assert_eq(_rose.quarters(), 1)
	assert_eq(_rose.petals(), 1, "a quarter left is one petal left, not none")
	assert_false(_rose.is_bare())


func test_no_petal_can_be_spent_by_hand() -> void:
	# The ruling on issue #11 in one assertion: petals are the health, so there is no
	# heal button and nothing to press. A later round that reintroduces `use_petal()`
	# fails here rather than quietly bringing the old model back.
	assert_false(
		_rose.has_method("use_petal"),
		"the White Rose has no spend verb: a hit costs petals, and nothing else does"
	)


# --- Taking damage ------------------------------------------------------------


func test_a_hit_tears_quarter_petals_off_and_says_so() -> void:
	watch_signal(_rose, &"petals_changed")
	assert_eq(_rose.take_damage(3), 3, "it took what it was asked for")
	assert_eq(_rose.quarters(), 9)
	assert_eq(signal_arguments(_rose, &"petals_changed", 0), [12, 9], "in quarters, both")


func test_damage_stops_at_a_bare_rose_rather_than_going_negative() -> void:
	watch_signal(_rose, &"bared")
	assert_eq(_rose.take_damage(100), 12, "only the twelve that were there could be taken")
	assert_eq(_rose.quarters(), 0)
	assert_true(_rose.is_bare())
	assert_signal_emitted(_rose, &"bared", 1)
	assert_eq(_rose.take_damage(4), 0, "and a bare Rose has nothing left to lose")
	assert_signal_emitted(_rose, &"bared", 1, "which is not a second fall")


func test_the_last_petal_announces_itself_once() -> void:
	# `arcana.md`'s "survive at 1 petal" / "at one petal remaining" hooks hang on this,
	# and an effect runner that heard it once a hit would fire them over and over.
	watch_signal(_rose, &"last_petal_reached")
	_rose.take_damage(7)
	assert_eq(_rose.petals(), 2, "five quarters is still two petals")
	assert_signal_emitted(_rose, &"last_petal_reached", 0)
	_rose.take_damage(1)
	assert_true(_rose.is_on_last_petal())
	assert_signal_emitted(_rose, &"last_petal_reached", 1)
	_rose.take_damage(1)
	assert_signal_emitted(_rose, &"last_petal_reached", 1, "still the last petal, once")


func test_a_hit_that_bares_the_rose_from_above_the_last_petal_only_bares_it() -> void:
	watch_signal(_rose, &"last_petal_reached")
	watch_signal(_rose, &"bared")
	_rose.take_damage(12)
	assert_signal_emitted(_rose, &"bared", 1)
	assert_signal_emitted(
		_rose, &"last_petal_reached", 0, "the Fool never stood on their last petal"
	)


# --- Healing ------------------------------------------------------------------


func test_healing_gives_quarters_back_and_stops_at_the_capacity() -> void:
	_rose.take_damage(5)
	assert_eq(_rose.heal(2), 2)
	assert_eq(_rose.quarters(), 9)
	assert_eq(_rose.heal(100), 3, "only the three missing quarters could be given back")
	assert_eq(_rose.quarters(), _rose.max_quarters())


func test_a_bare_rose_is_not_healed_back_up_by_a_trickle() -> void:
	# `combat.md` §Defeat: a fallen Fool wakes at a Waystation. Nothing else stands
	# them back up, and a regrowth tick that did would skip the whole beat.
	_rose.take_damage(12)
	assert_eq(_rose.heal(4), 0)
	assert_true(_rose.is_bare())


# --- Graftings ---------------------------------------------------------------


func test_a_grafting_raises_the_maximum_and_arrives_grown() -> void:
	watch_signal(_rose, &"max_petals_changed")
	assert_true(_rose.add_grafting())
	assert_eq(_rose.max_petals(), 4)
	assert_eq(_rose.max_quarters(), 16)
	assert_eq(_rose.quarters(), 16, "a grafting found in the world is a flower, not a promise")
	assert_eq(signal_arguments(_rose, &"max_petals_changed", 0), [3, 4], "in whole petals")


func test_graftings_stop_at_eight_petals() -> void:
	for _index: int in 5:
		assert_true(_rose.add_grafting())
	assert_eq(_rose.max_petals(), 8, "progression.md caps the Rose at 8")
	assert_eq(_rose.max_quarters(), 32)
	assert_eq(_rose.graftings_remaining(), 0)
	assert_false(_rose.add_grafting(), "a sixth grafting is refused")
	assert_eq(_rose.max_petals(), 8)


# --- Rest --------------------------------------------------------------------


func test_resting_a_full_rose_is_still_a_mutation() -> void:
	# A rest changes no number here, but it happened: the Rose has been played, and a
	# save must no longer load into it (`SaveService.apply()` asks `is_pristine()`).
	# `_set_quarters()` alone would have left this Rose looking untouched.
	assert_eq(_rose.quarters(), _rose.max_quarters(), "nothing has been spent yet")
	_rose.rest()
	assert_eq(_rose.quarters(), 12, "and nothing changed")
	assert_false(_rose.is_pristine(), "but the Rose has been rested; a load is not a reset")


func test_resting_regrows_every_petal_including_from_bare() -> void:
	_rose.add_grafting()
	_rose.take_damage(9)
	assert_eq(_rose.quarters(), 7)
	_rose.rest()
	assert_eq(_rose.quarters(), 16, "a Waystation rest fills the Rose, instantly")
	_rose.take_damage(16)
	assert_true(_rose.is_bare(), "and the defeat loop's return leg is the same call")
	_rose.rest()
	assert_eq(_rose.quarters(), _rose.max_quarters())


# --- Regrowth by region ------------------------------------------------------


func test_a_bound_region_regrows_nothing() -> void:
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(PETAL)
	assert_false(_rose.regrows_here(), "the Magician is still bound")
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 10.0)
	assert_eq(_rose.quarters(), 8, "stasis means nothing grows, the Rose included")


func test_unbinding_the_region_starts_the_rose_growing() -> void:
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(PETAL)
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	assert_true(_rose.regrows_here(), "the world woke up around the Fool")
	watch_signal(_rose, &"regrown")
	_rose.tick(_rose.regrow_seconds_per_quarter())
	assert_eq(_rose.quarters(), 9, "a quarter at a time")
	assert_signal_emitted(_rose, &"regrown", 1)
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 0.75)
	assert_eq(_rose.quarters(), 12, "and a whole petal in the doc's own period")


func test_the_regrowth_rate_is_the_docs_rate_divided_four_ways() -> void:
	# `SpreadRules` states the rate `progression.md` talks in - a whole petal - and a
	# second per-quarter number beside it would be two sources for one fact and a way
	# for the two to disagree.
	assert_almost_eq(
		_rose.regrow_seconds_per_quarter() * float(PETAL),
		_rules.rose_regrow_seconds_per_petal,
		0.0001
	)


func test_a_region_already_unbound_when_the_fool_arrives_regrows() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.take_damage(PETAL)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	assert_true(_rose.regrows_here())
	_rose.tick(_rules.rose_regrow_seconds_per_petal)
	assert_eq(_rose.quarters(), 12)


func test_a_bare_rose_grows_nothing_even_in_a_living_region() -> void:
	# The Fool is down. `combat.md` §Defeat brings them back at a Waystation, not by
	# standing still in a friendly field.
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(12)
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 10.0)
	assert_eq(_rose.quarters(), 0)


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
	rose.take_damage(PETAL)
	rose.tick(_rules.rose_regrow_seconds_per_petal)
	assert_eq(rose.quarters(), 12, "and a petal comes back")


func test_being_told_the_same_bound_region_again_banks_nothing_extra() -> void:
	# The other half of the same call: only the banked regrowth is behind the
	# "did anything change" check, so a repeated call must not silently reset a
	# quarter that is halfway grown.
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(1)
	_rose.tick(_rose.regrow_seconds_per_quarter() * 0.6)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.tick(_rose.regrow_seconds_per_quarter() * 0.4)
	assert_eq(_rose.quarters(), 12, "the banked six tenths survived being told again")


func test_the_cliff_never_regrows() -> void:
	# The Cliff has no Arcana and no unbinding (world.md §The Cliff), so it is
	# outside the Spread entirely - and MQ00's Waystation rest is meant to be the
	# first time the player sees petals come back.
	_rose.set_region(CLIFF, NO_UNBINDING)
	_rose.take_damage(PETAL)
	assert_false(_rose.regrows_here())
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 100.0)
	assert_eq(_rose.quarters(), 8, "nothing grows on the Cliff")
	_rose.rest()
	assert_eq(_rose.quarters(), 12, "but resting there still works")


func test_regrowth_stops_at_the_capacity() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(PETAL)
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 20.0)
	assert_eq(_rose.quarters(), 12, "a whole Rose grows no further")


func test_banked_regrowth_does_not_travel() -> void:
	# Walking out of a living region and back must not resume a quarter that was
	# nearly grown somewhere else.
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(1)
	_rose.tick(_rose.regrow_seconds_per_quarter() * 0.9)
	_rose.set_region(CLIFF, NO_UNBINDING)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.tick(_rose.regrow_seconds_per_quarter() * 0.5)
	assert_eq(_rose.quarters(), 11, "the walk did not finish the quarter")
	_rose.tick(_rose.regrow_seconds_per_quarter() * 0.5)
	assert_eq(_rose.quarters(), 12, "a full period in one place does")


func test_a_long_frame_regrows_at_most_the_capacity() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	_rose.set_region(PRESTIGE, WorldStateIds.WS_MAGICIAN_UNBOUND)
	_rose.take_damage(11)
	_rose.tick(_rules.rose_regrow_seconds_per_petal * 100.0)
	assert_eq(_rose.quarters(), 12, "the capacity, and never past it")


# --- Save --------------------------------------------------------------------


func test_a_snapshot_round_trips() -> void:
	_rose.add_grafting()
	_rose.add_grafting()
	_rose.take_damage(3)
	var loaded := WhiteRoseService.new(_world_state, _rules)
	assert_eq(loaded.restore_snapshot(_rose.to_snapshot()), PackedStringArray())
	assert_eq(loaded.quarters(), _rose.quarters())
	assert_eq(loaded.graftings(), _rose.graftings())
	assert_eq(loaded.max_petals(), _rose.max_petals())


func test_a_snapshot_survives_json() -> void:
	_rose.add_grafting()
	_rose.take_damage(3)
	var parsed: Variant = JSON.parse_string(JSON.stringify(_rose.to_snapshot()))
	if not assert_true(parsed is Dictionary):
		return
	var loaded := WhiteRoseService.new(_world_state, _rules)
	assert_eq(loaded.restore_snapshot(parsed as Dictionary), PackedStringArray())
	assert_eq(loaded.quarters(), _rose.quarters())


func test_a_played_rose_refuses_a_load() -> void:
	_rose.take_damage(PETAL)
	var problems := _rose.restore_snapshot({WhiteRoseService.SNAPSHOT_QUARTERS: 12})
	assert_eq(problems.size(), 1, "a load is not a reset")
	assert_eq(_rose.quarters(), 8)


func test_a_snapshot_with_more_petals_than_graftings_allow_is_refused() -> void:
	var loaded := WhiteRoseService.new(_world_state, _rules)
	var problems := loaded.restore_snapshot({
		WhiteRoseService.SNAPSHOT_QUARTERS: 32,
		WhiteRoseService.SNAPSHOT_GRAFTINGS: 0,
	})
	assert_eq(problems.size(), 1, "eight petals need five graftings")
	assert_eq(loaded.quarters(), 12, "and nothing was committed")


func test_a_snapshot_with_impossible_graftings_is_refused() -> void:
	var loaded := WhiteRoseService.new(_world_state, _rules)
	var problems := loaded.restore_snapshot({
		WhiteRoseService.SNAPSHOT_QUARTERS: 12,
		WhiteRoseService.SNAPSHOT_GRAFTINGS: 99,
	})
	assert_eq(problems.size(), 1, "there are only five graftings to find")
