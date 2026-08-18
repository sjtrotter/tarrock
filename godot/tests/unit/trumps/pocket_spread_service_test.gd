extends TarrockTest

## The Pocket Spread: what is held, what is slotted, and what the rules refuse.
##
## `docs/design/progression.md` §The Pocket Spread is the canon - one copy of each
## Trump, slots that open at 1/3/7 held, free swapping out of combat, loadouts at
## Waystations only - and `docs/design/arcana.md` design rule 5 adds the burden a
## reversed card attaches.
##
## Built over the real generated Trumps and the real world-state matrix, because the
## contract being proved is about the real cards: TRUMP_01 arrives with
## `WS_MAGICIAN_UNBOUND` and nothing else hands it over.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"

## An id no Trump will ever carry.
const UNKNOWN_TRUMP := &"TRUMP_99"

## A player-typed loadout name. User text, not a translation key.
const LOADOUT_NAME := "for the Bower"

var _rules: SpreadRules = null
var _flags: WorldStateCatalog = null
var _trumps: TrumpCatalog = null
var _world_state: WorldStateService = null
var _fortune: FortuneService = null
var _spread: PocketSpreadService = null


func before_each() -> void:
	_rules = (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_flags = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	_trumps = load(TRUMP_CATALOG_PATH) as TrumpCatalog
	_world_state = WorldStateService.new(
		_flags, load(ACT_THRESHOLDS_PATH) as ActThresholds, load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_fortune = FortuneService.new(_rules)
	_spread = PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)


# --- Holding -----------------------------------------------------------------


func test_a_new_spread_holds_nothing_and_has_nothing_open() -> void:
	assert_eq(_spread.held_count(), 0)
	assert_eq(_spread.held_ids(), [] as Array[StringName])
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		assert_false(_spread.is_slot_unlocked(slot), "no slot opens before the first Trump")
	assert_true(_spread.is_pristine())


func test_unbinding_an_arcana_hands_over_its_trump() -> void:
	watch_signal(_spread, &"trump_gained")
	_grant(1)
	assert_true(_spread.is_held(TrumpIds.TRUMP_01), "the Magician's card arrives with his flag")
	assert_eq(_spread.held_ids(), [TrumpIds.TRUMP_01] as Array[StringName])
	assert_signal_emitted(_spread, &"trump_gained", 1)
	assert_eq(signal_arguments(_spread, &"trump_gained", 0), [TrumpIds.TRUMP_01])


func test_holding_is_derived_from_the_flags_and_stored_nowhere() -> void:
	# A second service built over the same world state must agree with the first
	# without being told anything - which is only true if neither stores the list.
	_grant(2)
	var other := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	assert_eq(other.held_ids(), _spread.held_ids())
	assert_eq(other.held_count(), 2)


func test_a_branch_flag_hands_over_no_trump() -> void:
	watch_signal(_spread, &"trump_gained")
	_world_state.fire(WorldStateIds.WS_TROUPE_TRAVELING, QuestIds.MQ01)
	assert_eq(_spread.held_count(), 0, "the troupe's fate is not a card")
	assert_signal_emitted(_spread, &"trump_gained", 0)


func test_the_world_hands_over_no_trump() -> void:
	# arcana.md §XXI: the World's card is turned, not carried.
	watch_signal(_spread, &"trump_gained")
	_world_state.fire(WorldStateIds.WS_WORLD_UNBOUND, QuestIds.MQ21)
	assert_eq(_spread.held_count(), 0)
	assert_signal_emitted(_spread, &"trump_gained", 0)


# --- Slot unlocks ------------------------------------------------------------


func test_the_slots_open_at_one_three_and_seven_trumps() -> void:
	watch_signal(_spread, &"slot_unlocked")
	_grant(1)
	assert_true(_spread.is_slot_unlocked(SpreadSlot.Id.PRESENT), "Present opens with the first")
	assert_false(_spread.is_slot_unlocked(SpreadSlot.Id.PAST))
	assert_false(_spread.is_slot_unlocked(SpreadSlot.Id.FUTURE))
	_grant(2)
	assert_false(_spread.is_slot_unlocked(SpreadSlot.Id.PAST), "two is not three")
	assert_false(_spread.is_slot_unlocked(SpreadSlot.Id.FUTURE))
	_grant(3)
	assert_true(_spread.is_slot_unlocked(SpreadSlot.Id.PAST), "Past opens at three")
	assert_false(_spread.is_slot_unlocked(SpreadSlot.Id.FUTURE))
	_grant(6)
	assert_false(_spread.is_slot_unlocked(SpreadSlot.Id.FUTURE), "six is not seven")
	_grant(7)
	assert_true(_spread.is_slot_unlocked(SpreadSlot.Id.FUTURE), "Future opens at seven")
	assert_signal_emitted(_spread, &"slot_unlocked", 3, "one announcement per slot, ever")


func test_the_thresholds_come_from_the_rules_and_not_from_code() -> void:
	# A literal-based implementation passes the test above and fails this one.
	_rules.present_unlock_at_held = 2
	_rules.past_unlock_at_held = 4
	_rules.future_unlock_at_held = 5
	var spread := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	_grant(1)
	assert_false(spread.is_slot_unlocked(SpreadSlot.Id.PRESENT), "retuned to two")
	_grant(4)
	assert_true(spread.is_slot_unlocked(SpreadSlot.Id.PAST))
	assert_false(spread.is_slot_unlocked(SpreadSlot.Id.FUTURE))
	_grant(5)
	assert_true(spread.is_slot_unlocked(SpreadSlot.Id.FUTURE))


# --- Assigning ---------------------------------------------------------------


func test_a_held_trump_can_be_slotted() -> void:
	_grant(1)
	watch_signal(_spread, &"slot_assigned")
	assert_true(
		_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	)
	var slotted := _spread.slotted(SpreadSlot.Id.PRESENT)
	assert_eq(slotted.trump_id, TrumpIds.TRUMP_01)
	assert_eq(slotted.orientation, CardOrientation.Id.UPRIGHT)
	assert_signal_emitted(_spread, &"slot_assigned", 1)


func test_what_is_slotted_is_handed_out_as_a_copy() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var stolen := _spread.slotted(SpreadSlot.Id.PRESENT)
	stolen.trump_id = UNKNOWN_TRUMP
	assert_eq(
		_spread.slotted(SpreadSlot.Id.PRESENT).trump_id,
		TrumpIds.TRUMP_01,
		"the Spread changes through assign() and nowhere else"
	)


func test_a_card_can_be_turned_over_in_place() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	assert_true(
		_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED),
		"reversing the card already in the slot is not a duplicate"
	)
	assert_eq(_spread.slotted(SpreadSlot.Id.PRESENT).orientation, CardOrientation.Id.REVERSED)


func test_a_trump_the_fool_does_not_hold_is_refused() -> void:
	_grant(1)
	watch_signal(_spread, &"assignment_refused")
	assert_false(
		_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_02, CardOrientation.Id.UPRIGHT)
	)
	assert_eq(
		signal_arguments(_spread, &"assignment_refused", 0),
		[SpreadSlot.Id.PRESENT, PocketSpreadService.REASON_NOT_HELD]
	)
	assert_true(_spread.slotted(SpreadSlot.Id.PRESENT).is_empty())


func test_a_locked_slot_is_refused() -> void:
	_grant(1)
	watch_signal(_spread, &"assignment_refused")
	assert_false(_spread.assign(SpreadSlot.Id.PAST, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT))
	assert_eq(
		signal_arguments(_spread, &"assignment_refused", 0),
		[SpreadSlot.Id.PAST, PocketSpreadService.REASON_SLOT_LOCKED]
	)


func test_one_copy_of_each_trump() -> void:
	# progression.md: "There is one copy of each Trump - no duplicates."
	_grant(3)
	assert_true(_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT))
	watch_signal(_spread, &"assignment_refused")
	assert_false(
		_spread.assign(SpreadSlot.Id.PAST, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED),
		"the same card cannot sit in two slots"
	)
	assert_eq(
		signal_arguments(_spread, &"assignment_refused", 0),
		[SpreadSlot.Id.PAST, PocketSpreadService.REASON_ALREADY_SLOTTED]
	)
	assert_eq(_spread.slot_of(TrumpIds.TRUMP_01), SpreadSlot.Id.PRESENT)


func test_the_spread_cannot_be_rebuilt_mid_fight() -> void:
	# progression.md: swapping is free "anywhere, out of combat".
	_grant(1)
	_spread.set_in_combat(true)
	watch_signal(_spread, &"assignment_refused")
	assert_false(
		_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	)
	assert_eq(
		signal_arguments(_spread, &"assignment_refused", 0),
		[SpreadSlot.Id.PRESENT, PocketSpreadService.REASON_IN_COMBAT]
	)
	_spread.set_in_combat(false)
	assert_true(
		_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT),
		"and free again the moment the fight is over"
	)


func test_an_unknown_trump_is_refused() -> void:
	_grant(1)
	watch_signal(_spread, &"assignment_refused")
	var assigned: bool = _quietly(
		func() -> bool:
			return _spread.assign(SpreadSlot.Id.PRESENT, UNKNOWN_TRUMP, CardOrientation.Id.UPRIGHT)
	)
	assert_false(assigned)
	assert_eq(
		signal_arguments(_spread, &"assignment_refused", 0),
		[SpreadSlot.Id.PRESENT, PocketSpreadService.REASON_UNKNOWN_TRUMP]
	)


func test_clearing_a_slot() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	watch_signal(_spread, &"slot_cleared")
	assert_true(_spread.clear(SpreadSlot.Id.PRESENT))
	assert_true(_spread.slotted(SpreadSlot.Id.PRESENT).is_empty())
	assert_signal_emitted(_spread, &"slot_cleared", 1)
	assert_false(_spread.clear(SpreadSlot.Id.PRESENT), "an empty slot is already clear")


func test_clearing_is_refused_mid_fight() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	_spread.set_in_combat(true)
	assert_false(_spread.clear(SpreadSlot.Id.PRESENT), "taking a card out is a swap too")


# --- The reversed burden -----------------------------------------------------


func test_only_a_reversed_card_carries_its_burden() -> void:
	# arcana.md design rule 5: the burden attaches to whichever slot the reversed
	# card occupies.
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	assert_null(_spread.slotted_burden(SpreadSlot.Id.PRESENT), "upright carries no burden")
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	var burden := _spread.slotted_burden(SpreadSlot.Id.PRESENT)
	if not assert_not_null(burden, "reversed carries one"):
		return
	assert_eq(burden.burden_id, &"THE_TRICK_COSTS_THE_TRICKSTER")


# --- Loadouts ----------------------------------------------------------------


func test_loadouts_are_a_waystation_privilege() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	watch_signal(_spread, &"loadout_refused")
	assert_eq(_spread.save_loadout(LOADOUT_NAME), PocketSpreadService.NO_LOADOUT)
	assert_eq(
		signal_arguments(_spread, &"loadout_refused", 0),
		[PocketSpreadService.NO_LOADOUT, PocketSpreadService.REASON_NOT_AT_WAYSTATION]
	)
	_spread.set_at_waystation(true)
	assert_eq(_spread.save_loadout(LOADOUT_NAME), 0, "at a Waystation it saves")
	assert_eq(_spread.loadout_count(), 1)


func test_a_saved_loadout_keeps_the_players_own_name_for_it() -> void:
	_grant(1)
	_spread.set_at_waystation(true)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	_spread.save_loadout(LOADOUT_NAME)
	var saved := _spread.loadouts()
	if not assert_eq(saved.size(), 1):
		return
	assert_eq(saved[0].label, LOADOUT_NAME, "player text, stored verbatim")
	assert_eq(saved[0].assignment(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)
	assert_eq(
		saved[0].assignment(SpreadSlot.Id.PRESENT).orientation, CardOrientation.Id.REVERSED
	)


func test_applying_a_loadout_switches_the_whole_spread() -> void:
	_grant(3)
	_spread.set_at_waystation(true)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	_spread.assign(SpreadSlot.Id.PAST, TrumpIds.TRUMP_02, CardOrientation.Id.UPRIGHT)
	var index := _spread.save_loadout(LOADOUT_NAME)
	_spread.clear(SpreadSlot.Id.PAST)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_03, CardOrientation.Id.REVERSED)
	watch_signal(_spread, &"loadout_applied")
	assert_true(_spread.apply_loadout(index))
	assert_eq(_spread.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)
	assert_eq(_spread.slotted(SpreadSlot.Id.PAST).trump_id, TrumpIds.TRUMP_02)
	assert_signal_emitted(_spread, &"loadout_applied", 1)


func test_applying_a_loadout_empties_the_slots_it_leaves_open() -> void:
	_grant(3)
	_spread.set_at_waystation(true)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var index := _spread.save_loadout(LOADOUT_NAME)
	_spread.assign(SpreadSlot.Id.PAST, TrumpIds.TRUMP_02, CardOrientation.Id.UPRIGHT)
	assert_true(_spread.apply_loadout(index))
	assert_true(
		_spread.slotted(SpreadSlot.Id.PAST).is_empty(), "a loadout is a switch, not a merge"
	)


func test_applying_a_loadout_is_a_waystation_privilege_too() -> void:
	_grant(1)
	_spread.set_at_waystation(true)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var index := _spread.save_loadout(LOADOUT_NAME)
	_spread.clear(SpreadSlot.Id.PRESENT)
	_spread.set_at_waystation(false)
	watch_signal(_spread, &"loadout_refused")
	assert_false(_spread.apply_loadout(index))
	assert_eq(
		signal_arguments(_spread, &"loadout_refused", 0),
		[index, PocketSpreadService.REASON_NOT_AT_WAYSTATION]
	)


func test_a_loadout_naming_a_trump_the_fool_does_not_hold_is_refused_whole() -> void:
	# The case a restored save really produces: a loadout is data that outlived the
	# world it was saved in.
	_grant(3)
	_spread.set_at_waystation(true)
	var restored := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	restored.set_at_waystation(true)
	var problems := restored.restore_snapshot({
		PocketSpreadService.SNAPSHOT_SLOTS: {},
		PocketSpreadService.SNAPSHOT_LOADOUTS: [
			{
				PocketSpreadService.SNAPSHOT_LABEL: LOADOUT_NAME,
				PocketSpreadService.SNAPSHOT_SLOTS: {
					"PRESENT": {"trump_id": "TRUMP_09", "orientation": "UPRIGHT"},
				},
			}
		],
	})
	assert_eq(problems, PackedStringArray(), "the loadout loads: it is only data")
	watch_signal(restored, &"loadout_refused")
	assert_false(restored.apply_loadout(0), "but applying it is refused")
	assert_eq(
		signal_arguments(restored, &"loadout_refused", 0), [0, PocketSpreadService.REASON_NOT_HELD]
	)
	assert_true(restored.slotted(SpreadSlot.Id.PRESENT).is_empty(), "and nothing was applied")


func test_a_missing_loadout_is_refused() -> void:
	watch_signal(_spread, &"loadout_refused")
	assert_false(_spread.apply_loadout(3))
	assert_eq(
		signal_arguments(_spread, &"loadout_refused", 0),
		[3, PocketSpreadService.REASON_NO_SUCH_LOADOUT]
	)


func test_deleting_a_loadout() -> void:
	_grant(1)
	_spread.set_at_waystation(true)
	_spread.save_loadout(LOADOUT_NAME)
	assert_true(_spread.delete_loadout(0))
	assert_eq(_spread.loadout_count(), 0)
	assert_false(_spread.delete_loadout(0))


func test_no_loadout_verb_works_mid_fight() -> void:
	# progression.md puts every Spread operation "anywhere, out of combat". Applying a
	# loadout already refused mid-fight; saving and deleting one are the same act of
	# rebuilding the Spread and refuse for the same reason - a fight that starts at a
	# Waystation must not leave a build menu open behind it.
	_grant(1)
	_spread.set_at_waystation(true)
	var index := _spread.save_loadout(LOADOUT_NAME)
	assert_eq(index, 0, "saved out of combat")
	_spread.set_in_combat(true)
	watch_signal(_spread, &"loadout_refused")

	assert_eq(_spread.save_loadout("mid-fight"), PocketSpreadService.NO_LOADOUT)
	assert_eq(
		signal_arguments(_spread, &"loadout_refused", 0),
		[PocketSpreadService.NO_LOADOUT, PocketSpreadService.REASON_IN_COMBAT]
	)
	assert_eq(_spread.loadout_count(), 1, "and nothing was saved")

	assert_false(_spread.delete_loadout(0))
	assert_eq(
		signal_arguments(_spread, &"loadout_refused", 1),
		[0, PocketSpreadService.REASON_IN_COMBAT]
	)
	assert_eq(_spread.loadout_count(), 1, "and nothing was deleted")

	_spread.set_in_combat(false)
	assert_true(_spread.delete_loadout(0), "the fight over, the build can go")


# --- Casting the Present slot ------------------------------------------------


func test_a_present_cast_spends_fortune_and_announces_itself() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var cost := _spread.present_cost(CardOrientation.Id.UPRIGHT)
	assert_true(cost > 0, "the Magician's Present costs Fortune")
	_fortune.earn(FortuneService.EarnSource.DISCOVERY, cost)
	watch_signal(_spread, &"present_cast")
	assert_true(_spread.can_cast_present())
	assert_true(_spread.cast_present())
	assert_eq(_fortune.value(), 0, "the meter paid for it")
	assert_eq(
		signal_arguments(_spread, &"present_cast", 0),
		[TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT]
	)


func test_a_reversed_present_cast_costs_less() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	assert_true(
		_spread.present_cost(CardOrientation.Id.REVERSED)
		< _spread.present_cost(CardOrientation.Id.UPRIGHT),
		"progression.md: reversed casts cost less, in exchange for the burden"
	)


func test_a_cast_with_no_fortune_is_refused() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	watch_signal(_spread, &"present_cast_refused")
	assert_false(_spread.can_cast_present())
	assert_false(_spread.cast_present())
	assert_eq(
		signal_arguments(_spread, &"present_cast_refused", 0),
		[PocketSpreadService.REASON_CANNOT_AFFORD]
	)


func test_a_fools_chance_pays_for_the_next_cast() -> void:
	# combat.md §Defense: the Fool's Chance is "the mechanical bridge between combat
	# and the Pocket Spread".
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var cost := _spread.present_cost(CardOrientation.Id.UPRIGHT)
	_rules.fortune_per_fools_chance = 1  # far less than the cast costs
	_fortune.on_fools_chance()
	assert_true(_fortune.value() < cost, "the meter alone could not pay for this")
	assert_true(_spread.can_cast_present(), "but the free cast can")
	var banked := _fortune.value()
	assert_true(_spread.cast_present())
	assert_eq(_fortune.value(), banked, "and it cost no Fortune")
	assert_false(_fortune.has_free_cast(), "the free cast is spent, once")


func test_a_cast_of_an_unimplemented_trump_is_refused() -> void:
	# Only the Magician's effects are authored. Every other Trump can be held and
	# slotted - it just has nothing to run yet, and says so.
	_grant(3)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_02, CardOrientation.Id.UPRIGHT)
	_fortune.earn(FortuneService.EarnSource.DISCOVERY, 100)
	watch_signal(_spread, &"present_cast_refused")
	assert_false(_spread.can_cast_present())
	assert_false(_spread.cast_present())
	assert_eq(
		signal_arguments(_spread, &"present_cast_refused", 0),
		[PocketSpreadService.REASON_NO_EFFECTS]
	)


func test_an_empty_present_slot_casts_nothing() -> void:
	_grant(1)
	watch_signal(_spread, &"present_cast_refused")
	assert_false(_spread.cast_present())
	assert_eq(
		signal_arguments(_spread, &"present_cast_refused", 0),
		[PocketSpreadService.REASON_EMPTY_SLOT]
	)
	assert_eq(_spread.present_cost(CardOrientation.Id.UPRIGHT), 0)


func test_an_effect_with_no_cost_of_its_own_takes_the_rules_default() -> void:
	# The fallback that lets a later round author a Trump without inventing a
	# number: `present_cost = 0` means "the default for this orientation".
	_rules.default_present_cost_upright = 44
	var effect := TrumpEffect.new()
	effect.effect_id = &"TEST_EFFECT"
	assert_eq(effect.present_cost, SpreadRules.UNSET_COST)
	assert_eq(_rules.default_present_cost(CardOrientation.Id.UPRIGHT), 44)


# --- Save --------------------------------------------------------------------


func test_a_snapshot_round_trips() -> void:
	_grant(3)
	_spread.set_at_waystation(true)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	_spread.assign(SpreadSlot.Id.PAST, TrumpIds.TRUMP_02, CardOrientation.Id.UPRIGHT)
	_spread.save_loadout(LOADOUT_NAME)
	var loaded := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	assert_eq(loaded.restore_snapshot(_spread.to_snapshot()), PackedStringArray())
	assert_eq(loaded.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)
	assert_eq(loaded.slotted(SpreadSlot.Id.PRESENT).orientation, CardOrientation.Id.REVERSED)
	assert_eq(loaded.slotted(SpreadSlot.Id.PAST).trump_id, TrumpIds.TRUMP_02)
	assert_true(loaded.slotted(SpreadSlot.Id.FUTURE).is_empty())
	assert_eq(loaded.loadout_count(), 1)
	assert_eq(loaded.loadouts()[0].label, LOADOUT_NAME)


func test_a_snapshot_survives_json() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var parsed: Variant = JSON.parse_string(JSON.stringify(_spread.to_snapshot()))
	if not assert_true(parsed is Dictionary, "the snapshot is JSON-safe"):
		return
	var loaded := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	assert_eq(loaded.restore_snapshot(parsed as Dictionary), PackedStringArray())
	assert_eq(loaded.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)


func test_the_snapshot_stores_slots_by_name_and_not_by_ordinal() -> void:
	# An ordinal would re-point at a different slot the day one is inserted.
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var snapshot := _spread.to_snapshot()
	var slots: Dictionary = snapshot[PocketSpreadService.SNAPSHOT_SLOTS]
	assert_has(slots, "PRESENT")
	assert_eq(
		(slots["PRESENT"] as Dictionary)[PocketSpreadService.SNAPSHOT_ORIENTATION], "UPRIGHT"
	)


func test_a_played_spread_refuses_a_load() -> void:
	_grant(1)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var problems := _spread.restore_snapshot({PocketSpreadService.SNAPSHOT_SLOTS: {}})
	assert_eq(problems.size(), 1, "a load is not a reset")
	assert_eq(_spread.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)


func test_a_snapshot_slotting_an_unheld_trump_is_refused_whole() -> void:
	_grant(1)
	var loaded := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	var problems := loaded.restore_snapshot({
		PocketSpreadService.SNAPSHOT_SLOTS: {
			"PRESENT": {"trump_id": "TRUMP_09", "orientation": "UPRIGHT"},
		},
	})
	assert_eq(problems.size(), 1, "a save cannot hand the Fool a card they never won")
	assert_true(loaded.slotted(SpreadSlot.Id.PRESENT).is_empty(), "and nothing was committed")
	assert_true(loaded.is_pristine())


func test_a_snapshot_slotting_the_same_trump_twice_is_refused() -> void:
	_grant(3)
	var loaded := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	var problems := loaded.restore_snapshot({
		PocketSpreadService.SNAPSHOT_SLOTS: {
			"PRESENT": {"trump_id": "TRUMP_01", "orientation": "UPRIGHT"},
			"PAST": {"trump_id": "TRUMP_01", "orientation": "REVERSED"},
		},
	})
	assert_eq(problems.size(), 1, "there is one copy of each Trump")


func test_a_snapshot_naming_an_orientation_this_build_lacks_is_refused() -> void:
	_grant(1)
	var loaded := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	var problems := loaded.restore_snapshot({
		PocketSpreadService.SNAPSHOT_SLOTS: {
			"PRESENT": {"trump_id": "TRUMP_01", "orientation": "SIDEWAYS"},
		},
	})
	assert_eq(problems.size(), 1)


func test_a_snapshot_filling_a_locked_slot_is_refused() -> void:
	_grant(1)
	var loaded := PocketSpreadService.new(_world_state, _trumps, _rules, _fortune)
	var problems := loaded.restore_snapshot({
		PocketSpreadService.SNAPSHOT_SLOTS: {
			"PAST": {"trump_id": "TRUMP_01", "orientation": "UPRIGHT"},
		},
	})
	assert_eq(problems.size(), 1, "one Trump held does not open the Past slot")


# --- Reading a slot without allocating ---------------------------------------


func test_the_id_and_orientation_queries_agree_with_the_copy() -> void:
	_grant(3)
	_spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	assert_eq(_spread.slotted_trump_id(SpreadSlot.Id.PRESENT), TrumpIds.TRUMP_01)
	assert_eq(_spread.slotted_orientation(SpreadSlot.Id.PRESENT), CardOrientation.Id.REVERSED)
	assert_eq(_spread.slotted_trump_id(SpreadSlot.Id.PAST), &"", "an empty slot holds no Trump")
	_spread.clear(SpreadSlot.Id.PRESENT)
	assert_eq(_spread.slotted_trump_id(SpreadSlot.Id.PRESENT), &"")


func test_the_polled_queries_never_copy_a_slot() -> void:
	# `can_cast_present()` is what a HUD asks every frame, and `slotted()` allocates a
	# `SlotAssignment` per call by design (nobody may hold the service's own). So the
	# read paths must go through `slotted_trump_id()` / `slotted_orientation()`
	# instead - which is not observable from outside, so this counts the calls from
	# inside, through a subclass. If a hot path reaches for `slotted()` again, this is
	# the test that says so.
	var spread := CountingSpread.new(_world_state, _trumps, _rules, _fortune)
	_grant(1)
	spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	_fortune.earn(FortuneService.EarnSource.DISCOVERY, 100)
	spread.slotted_calls = 0

	assert_true(spread.can_cast_present())
	assert_true(spread.can_cast_present(), "asked twice, as a HUD would")
	assert_true(spread.present_cost(CardOrientation.Id.REVERSED) > 0)
	assert_not_null(spread.slotted_burden(SpreadSlot.Id.PRESENT), "a reversed card carries one")
	assert_eq(spread.slotted_calls, 0, "none of the polled queries copied a slot")

	assert_true(spread.cast_present())
	assert_eq(spread.slotted_calls, 0, "and neither did the cast")
	assert_false(spread.slotted(SpreadSlot.Id.PRESENT).is_empty(), "the copy still works")
	assert_eq(spread.slotted_calls, 1, "and it is still the counted one")


func test_the_held_count_survives_a_world_restored_underneath_it() -> void:
	# `held_count()` is cached, and a load emits nothing - so a cache invalidated only
	# by `world_state_fired` would answer the count from before the load forever. The
	# stamp is `WorldStateService.unbound_count()`, which a restore does move.
	var world := WorldStateService.new(
		_flags, load(ACT_THRESHOLDS_PATH) as ActThresholds, load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var spread := PocketSpreadService.new(world, _trumps, _rules, _fortune)
	assert_eq(spread.held_count(), 0, "and the count is now cached at zero")
	assert_false(spread.is_slot_unlocked(SpreadSlot.Id.PRESENT))

	_grant(3)
	assert_eq(world.restore_snapshot(_world_state.to_snapshot()), PackedStringArray())
	assert_eq(spread.held_count(), 3, "the loaded world hands over three Trumps")
	assert_true(spread.is_slot_unlocked(SpreadSlot.Id.PAST), "so the Past slot is open")


func test_the_held_count_moves_the_moment_a_flag_fires() -> void:
	assert_eq(_spread.held_count(), 0)
	_grant(1)
	assert_eq(_spread.held_count(), 1, "a cached count that never moved would fail here")
	assert_eq(_spread.held_count(), 1, "and asking twice answers the same")
	_grant(2)
	assert_eq(_spread.held_count(), 2)


## A Spread that counts every `slotted()` call. GDScript methods are virtual, so the
## service's own internals call this override - which is what makes "the polled
## queries do not allocate a copy" a property a test can actually assert.
class CountingSpread extends PocketSpreadService:
	var slotted_calls: int = 0

	func slotted(slot: SpreadSlot.Id) -> SlotAssignment:
		slotted_calls += 1
		return super(slot)


# --- Helpers -----------------------------------------------------------------


## Unbind the first `count` Arcana in card order, so Trumps I..count are held.
##
## Each flag is fired by the quest the matrix says fires it, read off the definition
## rather than typed - the same rule the rest of the codebase keeps about ids.
func _grant(count: int) -> void:
	var granted := 0
	for flag_id: StringName in WorldStateIds.UNBINDING:
		if granted >= count:
			return
		var definition := _flags.find(flag_id)
		if definition == null:
			continue
		_world_state.fire(flag_id, definition.fired_by)
		granted += 1


## Run `action` with the engine's error printing muted, and hand back its result.
## Slotting an id no catalog holds is *meant* to push an error - that is how a typo
## surfaces - and `run_all.sh` fails any stage whose log holds an engine error line.
func _quietly(action: Callable) -> Variant:
	var was_printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Variant = action.call()
	Engine.print_error_messages = was_printing
	return result
