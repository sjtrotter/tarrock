extends TarrockTest

## The Beasts and the Fog-masks: the two world-state rules `docs/design/combat.md`
## §Other enemy families states, and nothing else.
##
## Neither family has a stat block, a telegraph or a scene this round, because the doc
## gives them none - one sentence each, and both sentences are about a `WS_*` flag.
## What is testable is exactly what is written down: `WS_STRENGTH_UNBOUND` calms the
## Beasts world-wide, `WS_MOON_UNBOUND` takes the Fog-masks' ambush advantage away
## world-wide, and neither can be undone, because `WS_*` flags never un-fire.
##
## The flags themselves are never typed here: they come off the generated
## `EnemyDefinition`s, so a doc edit moves them and a wrong one fails the drift test
## next door rather than passing quietly here.

const CATALOG_PATH := "res://data/enemies/catalog.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## Who a flag is attributed to. `WorldStateService.fire()` insists on a firer.
const FIRED_BY := &"MQ08"

var _catalog: EnemyCatalog = null
var _world_state: WorldStateService = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)


# --- Beasts -------------------------------------------------------------------


func test_a_beast_is_hostile_by_default() -> void:
	var beast := _beast()
	if beast == null:
		return
	assert_eq(beast.stance(), BeastBrain.Stance.HOSTILE, "combat.md: 'Hostile by default'")
	assert_true(beast.is_hostile_on_sight(), "so it comes at the Fool unprompted")
	assert_false(beast.is_calmed(), "and nothing has calmed it")


func test_strength_calms_every_beast_world_wide() -> void:
	# `combat.md`: "calmed to neutral-until-provoked world-wide once
	# `WS_STRENGTH_UNBOUND` fires". World-wide is why this reads the world state and
	# not a region or an encounter.
	var beast := _beast()
	var another := _beast()
	if beast == null or another == null:
		return
	_world_state.fire(_calming_flag(), FIRED_BY)
	assert_eq(
		beast.stance(),
		BeastBrain.Stance.NEUTRAL_UNTIL_PROVOKED,
		"the Beast the Fool is looking at is calm"
	)
	assert_eq(another.stance(), BeastBrain.Stance.NEUTRAL_UNTIL_PROVOKED, "and so is every other")
	assert_false(beast.is_hostile_on_sight(), "neither attacks on sight any more")
	assert_true(beast.is_calmed(), "and both know why")


func test_a_calmed_beast_that_is_struck_stays_provoked() -> void:
	# "neutral-until-provoked" is a promise about the FIRST move, not a temper that
	# cools: a Beast the Fool picked a fight with does not forget half way through it.
	var beast := _beast()
	if beast == null:
		return
	_world_state.fire(_calming_flag(), FIRED_BY)
	beast.provoke()
	assert_eq(beast.stance(), BeastBrain.Stance.PROVOKED, "it fights back")
	assert_true(beast.is_hostile_on_sight(), "and keeps fighting")
	assert_true(beast.is_calmed(), "though the world around it is still calm")


func test_a_beast_out_of_a_pool_starts_over() -> void:
	var beast := _beast()
	if beast == null:
		return
	beast.provoke()
	beast.reset()
	assert_false(beast.is_provoked(), "a body raised again has nobody's grudge")


func test_calming_can_never_be_undone() -> void:
	# There is no method that un-fires a flag (`WorldStateService`), which is what
	# makes "world-wide" mean the rest of the game rather than the rest of the scene.
	var beast := _beast()
	if beast == null:
		return
	_world_state.fire(_calming_flag(), FIRED_BY)
	assert_false(
		_world_state.has_method("unfire"), "nothing can put the Beasts back the way they were"
	)
	assert_true(beast.is_calmed())


# --- Fog-masks -----------------------------------------------------------------


func test_a_fog_mask_ambushes_until_the_moon_is_unbound() -> void:
	# `combat.md`: "Revealed as lost people wearing the fog's illusions once
	# `WS_MOON_UNBOUND` fires, at which point they lose their ambush advantage
	# world-wide."
	var fog_mask := _fog_mask()
	if fog_mask == null:
		return
	assert_false(fog_mask.is_revealed(), "the fog still lies")
	assert_true(fog_mask.has_ambush_advantage(), "so the ambush advantage stands")
	assert_almost_eq(
		fog_mask.ambush_bonus(), FogMaskBrain.FULL_AMBUSH_ADVANTAGE, 0.0001, "all of it"
	)
	_world_state.fire(_reveal_flag(), FIRED_BY)
	assert_true(fog_mask.is_revealed(), "the Moon unbound reveals them")
	assert_almost_eq(
		fog_mask.ambush_bonus(),
		FogMaskBrain.NO_AMBUSH_ADVANTAGE,
		0.0001,
		"and the advantage is gone entirely"
	)
	assert_false(fog_mask.has_ambush_advantage())


func test_the_reveal_is_world_wide_and_not_per_creature() -> void:
	var first := _fog_mask()
	var second := _fog_mask()
	if first == null or second == null:
		return
	_world_state.fire(_reveal_flag(), FIRED_BY)
	assert_true(first.is_revealed(), "the one the Fool is looking at is revealed")
	assert_true(second.is_revealed(), "and so is every other, everywhere")


func test_nothing_can_flip_a_mask_mid_fight() -> void:
	# `combat.md` closes this door explicitly: "the reveal is a world-state event, not
	# a combat-time twist". So the class offers no way to reveal one, and this is the
	# test that notices the day somebody adds one.
	var fog_mask := _fog_mask()
	if fog_mask == null:
		return
	assert_false(fog_mask.has_method("reveal"), "a Fog-mask cannot be unmasked by a fight")
	assert_false(fog_mask.has_method("set_revealed"), "nor by anything setting a flag on it")


# --- Both, through the service ----------------------------------------------------


func test_the_service_builds_both_over_the_flags_the_doc_names() -> void:
	# The whole point of generating the stubs: nothing types `WS_STRENGTH_UNBOUND`
	# next to a Beast. The service reads the flag off the definition, which was
	# generated from `combat.md`.
	if not assert_not_null(_catalog):
		return
	var service := EnemyService.new(_catalog, load("res://data/enemies/enemy_rules.tres") as EnemyRules)
	var beast := service.beast_brain(_world_state)
	var fog_mask := service.fog_mask_brain(_world_state)
	if not assert_not_null(beast) or not assert_not_null(fog_mask):
		return
	assert_true(beast.is_hostile_on_sight(), "a fresh world has hostile Beasts")
	assert_true(fog_mask.has_ambush_advantage(), "and Fog-masks still wearing their fog")
	_world_state.fire(WorldStateIds.WS_STRENGTH_UNBOUND, FIRED_BY)
	_world_state.fire(WorldStateIds.WS_MOON_UNBOUND, FIRED_BY)
	assert_false(beast.is_hostile_on_sight(), "Strength calms the Beasts")
	assert_false(fog_mask.has_ambush_advantage(), "and the Moon unmasks the Fog-masks")


func test_neither_family_has_numbers_this_round() -> void:
	# Not an omission - a refusal. `combat.md` gives these two families one sentence
	# each and no stat block, so inventing telegraph timings for them here would be
	# writing enemy canon in code. The Maw and the Mirrormarsh are the rounds that
	# give one a body.
	if not assert_not_null(_catalog):
		return
	var rules := load("res://data/enemies/enemy_rules.tres") as EnemyRules
	for enemy_id: StringName in [EnemyIds.BEAST, EnemyIds.FOG_MASK]:
		var found := _catalog.find(enemy_id)
		if not assert_not_null(found, "%s is in the catalog" % enemy_id):
			continue
		assert_false(found.has_suit_and_rank(), "%s has no suit and no rank" % enemy_id)
		assert_null(found.stats(rules), "%s has no invented stat block" % enemy_id)


# --- Helpers ------------------------------------------------------------------------


func _beast() -> BeastBrain:
	var flag := _calming_flag()
	if flag == &"":
		return null
	return BeastBrain.new(_world_state, flag)


func _fog_mask() -> FogMaskBrain:
	var flag := _reveal_flag()
	if flag == &"":
		return null
	return FogMaskBrain.new(_world_state, flag)


## The Beasts' calming flag, off the generated definition rather than typed.
func _calming_flag() -> StringName:
	if _catalog == null:
		fail("the enemy catalog did not load")
		return &""
	var found := _catalog.find(EnemyIds.BEAST)
	if found == null:
		fail("no BEAST definition")
		return &""
	return found.calming_flag


## The Fog-masks' reveal flag, the same way.
func _reveal_flag() -> StringName:
	if _catalog == null:
		fail("the enemy catalog did not load")
		return &""
	var found := _catalog.find(EnemyIds.FOG_MASK)
	if found == null:
		fail("no FOG_MASK definition")
		return &""
	return found.reveal_flag
