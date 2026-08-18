extends TarrockTest

## The WorldState service: the game's only mutation path.
##
## Built over the *generated* definitions (`res://data/world_states/`), because the
## contract this file is proving is a contract about the real matrix: 21 unbindings,
## the branch flags MQ01 and MQ06 choose between, acts at 7 and 15.
##
## `docs/design/world.md` §World-state matrix and §Global states are the canon;
## `docs/design/technical.md` §The WorldState service is the shape.

const CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## Method-name fragments that would mean permanence is only a convention.
## `world.md`: "States are permanent within a save. No unbinding is reversible."
const REVERSAL_WORDS: Array[String] = [
	"unfire",
	"clear",
	"reset",
	"remove",
	"erase",
	"unset",
	"set_fired",
]

## Every public method `WorldStateService` is allowed to have.
##
## The word blacklist above catches the obvious way back in; this list catches the
## rest, by refusing anything new. Permanence, "a load is not a reset" and "nothing
## else may mutate the matrix" are all properties of the *surface*: they hold only
## while the surface is this and no more. Adding a public method to the service is
## therefore a decision taken here too, in review, and not a side effect of writing
## one. Underscore-prefixed methods are internals and are not judged.
const PUBLIC_METHODS: Array[String] = [
	"act",
	"adjust_renown",
	"fire",
	"fired_by",
	"hermit_answer",
	"is_confessed",
	"is_fired",
	"is_pristine",
	"npc_memory",
	"npc_remember",
	"npc_remembers",
	"quest_choice",
	"quest_state",
	"reading_order",
	"renown",
	"renown_tier",
	"renown_tier_name_key",
	"restore_snapshot",
	"set_hermit_answer",
	"set_quest_choice",
	"set_quest_state",
	"to_snapshot",
	"unbound_count",
]

## An id no matrix row will ever carry.
const UNKNOWN_FLAG := &"WS_NOT_A_REAL_FLAG"

var _catalog: WorldStateCatalog = null
var _thresholds: ActThresholds = null
var _ladder: RenownLadder = null
var _service: WorldStateService = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as WorldStateCatalog
	_thresholds = load(ACT_THRESHOLDS_PATH) as ActThresholds
	_ladder = load(RENOWN_LADDER_PATH) as RenownLadder
	_service = WorldStateService.new(_catalog, _thresholds, _ladder)


## Run `action` with the engine's error printing muted, and hand back its result.
##
## Firing or querying an unknown id is *meant* to `push_error` - that is how a typo
## in a quest surfaces. But `run_all.sh` fails any stage whose log holds an engine
## error line, so a test that provokes one deliberately must not print it.
func _quietly(action: Callable) -> Variant:
	var was_printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Variant = action.call()
	Engine.print_error_messages = was_printing
	return result


## Fire the first `count` unbindings in card order, as a playthrough would.
func _unbind(count: int) -> void:
	var ids := _catalog.unbinding_ids()
	for index: int in count:
		var definition := _catalog.find(ids[index])
		_service.fire(ids[index], definition.fired_by)


# --- Firing ------------------------------------------------------------------


func test_a_flag_starts_unfired() -> void:
	assert_false(_service.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_eq(_service.unbound_count(), 0)
	assert_eq(_service.fired_by(WorldStateIds.WS_MAGICIAN_UNBOUND), &"")


func test_firing_reports_that_this_call_did_it() -> void:
	assert_true(_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01"), "the first call fires")
	assert_true(_service.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_eq(_service.fired_by(WorldStateIds.WS_MAGICIAN_UNBOUND), &"MQ01")


func test_firing_twice_changes_nothing() -> void:
	_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	watch_signal(_service, &"world_state_fired")
	assert_false(
		_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01_AGAIN"),
		"a quest that completes twice does not fire twice"
	)
	assert_eq(_service.fired_by(WorldStateIds.WS_MAGICIAN_UNBOUND), &"MQ01", "the store is untouched")
	assert_eq(_service.unbound_count(), 1)
	assert_eq(_service.reading_order().size(), 1)
	assert_signal_emitted(_service, &"world_state_fired", 0, "no signal for a repeat")


func test_an_unknown_flag_is_refused_and_fires_nothing() -> void:
	var fired: bool = _quietly(func() -> bool: return _service.fire(UNKNOWN_FLAG, &"MQ01"))
	assert_false(fired, "an id the matrix never wrote down cannot be invented by firing it")
	var reads: bool = _quietly(func() -> bool: return _service.is_fired(UNKNOWN_FLAG))
	assert_false(reads)
	assert_eq(_service.unbound_count(), 0)
	assert_eq(_service.reading_order().size(), 0)


func test_firing_without_the_quest_that_fired_it_is_refused() -> void:
	# `fired_by()` answers &"" for a flag that never fired, so a flag fired *by*
	# &"" would be indistinguishable from one that never happened.
	var fired: bool = _quietly(
		func() -> bool: return _service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"")
	)
	assert_false(fired, "an unbinding is fired by a quest, and the quest is recorded")
	var reads: bool = _quietly(
		func() -> bool: return _service.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND)
	)
	assert_false(reads)
	assert_eq(_service.unbound_count(), 0)
	assert_eq(_service.reading_order().size(), 0)
	assert_true(_service.is_pristine(), "a refused call is not a mutation")


func test_the_service_has_no_way_back() -> void:
	# Permanence by construction, not by discipline: `world.md` says no unbinding is
	# reversible, so the call that would reverse one must not exist. Only the
	# script's own methods are judged - Object itself ships `remove_meta`.
	var script := _service.get_script() as Script
	if not assert_not_null(script, "the service has a script to reflect over"):
		return
	for entry: Dictionary in script.get_script_method_list():
		var method_name := String(entry["name"])
		for word: String in REVERSAL_WORDS:
			assert_false(
				method_name.contains(word),
				"WorldStateService.%s() would let a flag be taken back" % method_name
			)


func test_the_public_surface_is_exactly_the_reviewed_one() -> void:
	# The blacklist above only refuses the names we thought of. This refuses every
	# name we did not: a new public method fails here until it is added to
	# PUBLIC_METHODS, which is where someone has to look at it.
	var script := _service.get_script() as Script
	if not assert_not_null(script, "the service has a script to reflect over"):
		return
	var found := PackedStringArray()
	for entry: Dictionary in script.get_script_method_list():
		var method_name := String(entry["name"])
		if method_name.begins_with("_") or found.has(method_name):
			continue
		found.append(method_name)
	found.sort()
	var expected := PackedStringArray(PUBLIC_METHODS)
	expected.sort()
	var unexpected := PackedStringArray()
	for method_name: String in found:
		if not expected.has(method_name):
			unexpected.append(method_name)
	var missing := PackedStringArray()
	for method_name: String in expected:
		if not found.has(method_name):
			missing.append(method_name)
	assert_eq(
		found,
		expected,
		"unreviewed public methods %s; reviewed methods that vanished %s"
		% [str(unexpected), str(missing)]
	)


# --- Acts --------------------------------------------------------------------


func test_act_one_holds_through_six_unbindings() -> void:
	assert_eq(_service.act(), WorldStateService.Act.ACT_I, "no Arcana unbound is Act I")
	_unbind(6)
	assert_eq(_service.unbound_count(), 6)
	assert_eq(_service.act(), WorldStateService.Act.ACT_I, "six unbound is still Act I")


func test_act_two_begins_at_the_seventh() -> void:
	_unbind(7)
	assert_eq(_service.act(), WorldStateService.Act.ACT_II)
	_unbind(14)
	assert_eq(_service.act(), WorldStateService.Act.ACT_II, "fourteen unbound is still Act II")


func test_act_three_begins_at_the_fifteenth() -> void:
	_unbind(15)
	assert_eq(_service.act(), WorldStateService.Act.ACT_III)
	_unbind(21)
	assert_eq(_service.unbound_count(), 21)
	assert_eq(_service.act(), WorldStateService.Act.ACT_III)


func test_act_changed_fires_once_per_crossing_with_both_acts() -> void:
	watch_signal(_service, &"act_changed")
	_unbind(6)
	assert_signal_emitted(_service, &"act_changed", 0, "six unbindings cross nothing")
	_unbind(7)
	assert_signal_emitted(_service, &"act_changed", 1)
	assert_eq(
		signal_arguments(_service, &"act_changed", 0),
		[WorldStateService.Act.ACT_I, WorldStateService.Act.ACT_II]
	)
	_unbind(15)
	assert_signal_emitted(_service, &"act_changed", 2)
	assert_eq(
		signal_arguments(_service, &"act_changed", 1),
		[WorldStateService.Act.ACT_II, WorldStateService.Act.ACT_III]
	)


func test_the_act_boundaries_come_from_the_data_not_from_literals() -> void:
	# Retune the thresholds and the service must follow. A service that spelled 7
	# and 15 into its own code would still be answering Act I here.
	var retuned := ActThresholds.new()
	retuned.id = &"ACT_THRESHOLDS"
	retuned.act_ii_min = 2
	retuned.act_iii_min = 3
	var service := WorldStateService.new(_catalog, retuned, _ladder)
	var ids := _catalog.unbinding_ids()
	service.fire(ids[0], &"MQ01")
	assert_eq(service.act(), WorldStateService.Act.ACT_I)
	service.fire(ids[1], &"MQ02")
	assert_eq(service.act(), WorldStateService.Act.ACT_II)
	service.fire(ids[2], &"MQ03")
	assert_eq(service.act(), WorldStateService.Act.ACT_III)


func test_branch_flags_do_not_move_the_acts() -> void:
	# The troupe's fate is a choice, not an unbinding: it must not push the world
	# an act closer to the end.
	_unbind(6)
	for flag_id: StringName in WorldStateIds.BRANCH:
		_service.fire(flag_id, _catalog.find(flag_id).fired_by)
	assert_eq(_service.unbound_count(), 6, "branch flags are not Arcana")
	assert_eq(_service.act(), WorldStateService.Act.ACT_I)


# --- The Fool's Reading ------------------------------------------------------


func test_the_reading_records_unbindings_in_the_order_they_happened() -> void:
	_service.fire(WorldStateIds.WS_SUN_UNBOUND, &"MQ19")
	_service.fire(WorldStateIds.WS_STAR_UNBOUND, &"MQ17")
	var reading := _service.reading_order()
	assert_eq(reading.size(), 2)
	assert_eq(reading[0], WorldStateIds.WS_SUN_UNBOUND, "Sun before Star, because it was")
	assert_eq(reading[1], WorldStateIds.WS_STAR_UNBOUND)


func test_the_reading_excludes_branch_flags() -> void:
	_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	_service.fire(WorldStateIds.WS_TROUPE_SETTLED, &"MQ01")
	var reading := _service.reading_order()
	assert_eq(reading.size(), 1, "a choice is not an unbinding")
	assert_eq(reading[0], WorldStateIds.WS_MAGICIAN_UNBOUND)


func test_the_reading_handed_out_is_a_copy() -> void:
	_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	var reading := _service.reading_order()
	reading.append(WorldStateIds.WS_WORLD_UNBOUND)
	assert_eq(_service.reading_order().size(), 1, "a caller cannot write the Reading")


func test_reading_appended_carries_the_flag_and_its_index() -> void:
	watch_signal(_service, &"reading_appended")
	_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	_service.fire(WorldStateIds.WS_TROUPE_SETTLED, &"MQ01")
	_service.fire(WorldStateIds.WS_PRIESTESS_UNBOUND, &"MQ02")
	assert_signal_emitted(_service, &"reading_appended", 2, "only unbindings append")
	assert_eq(
		signal_arguments(_service, &"reading_appended", 0), [WorldStateIds.WS_MAGICIAN_UNBOUND, 0]
	)
	assert_eq(
		signal_arguments(_service, &"reading_appended", 1), [WorldStateIds.WS_PRIESTESS_UNBOUND, 1]
	)


func test_world_state_fired_carries_the_flag() -> void:
	watch_signal(_service, &"world_state_fired")
	_service.fire(WorldStateIds.WS_DEVIL_UNBOUND, &"MQ15")
	assert_signal_emitted(_service, &"world_state_fired", 1)
	assert_eq(signal_arguments(_service, &"world_state_fired", 0), [WorldStateIds.WS_DEVIL_UNBOUND])


# --- CONFESSED ---------------------------------------------------------------


func test_confessed_follows_death_and_nothing_else() -> void:
	assert_false(_service.is_confessed(), "the world does not know yet")
	_unbind(12)
	assert_false(_service.is_confessed(), "twelve unbindings do not confess for the Fool")
	_service.fire(WorldStateIds.WS_DEATH_UNBOUND, &"MQ13")
	assert_true(_service.is_confessed())


# --- Renown ------------------------------------------------------------------


func test_every_suit_starts_a_stranger() -> void:
	for suit: Suit.Id in Suit.ALL:
		assert_eq(_service.renown(suit), 0, "no reputation anywhere at hour one")
		assert_eq(_service.renown_tier(suit), 1)
		assert_eq(_service.renown_tier_name_key(suit), &"RENOWN_TIER_STRANGER")


func test_renown_moves_per_suit_and_only_that_suit() -> void:
	_service.adjust_renown(Suit.Id.CUPS, 12, &"HELPED_A_STRANGER")
	assert_eq(_service.renown(Suit.Id.CUPS), 12)
	assert_eq(_service.renown(Suit.Id.COINS), 0, "Renown is per suit, never a single meter")


func test_renown_never_goes_below_zero() -> void:
	_service.adjust_renown(Suit.Id.SWORDS, 3, &"WON_A_DUEL")
	_service.adjust_renown(Suit.Id.SWORDS, -10, &"REFUSED_A_DUEL")
	assert_eq(_service.renown(Suit.Id.SWORDS), 0, "standing bottoms out at stranger")


func test_a_change_that_changes_nothing_is_silent() -> void:
	watch_signal(_service, &"renown_changed")
	_service.adjust_renown(Suit.Id.WANDS, 0, &"NOTHING_HAPPENED")
	_service.adjust_renown(Suit.Id.WANDS, -5, &"ALREADY_AT_THE_FLOOR")
	assert_signal_emitted(_service, &"renown_changed", 0)


func test_renown_changed_carries_suit_and_both_values() -> void:
	watch_signal(_service, &"renown_changed")
	_service.adjust_renown(Suit.Id.COINS, 7, &"STRUCK_A_SHARP_BARGAIN")
	assert_signal_emitted(_service, &"renown_changed", 1)
	assert_eq(signal_arguments(_service, &"renown_changed", 0), [Suit.Id.COINS, 0, 7])


func test_the_tier_signal_fires_only_when_the_rung_moves() -> void:
	watch_signal(_service, &"renown_tier_changed")
	_service.adjust_renown(Suit.Id.CUPS, 9, &"SMALL_KINDNESSES")
	assert_eq(_service.renown_tier(Suit.Id.CUPS), 1, "nine is still a stranger")
	assert_signal_emitted(_service, &"renown_tier_changed", 0)
	_service.adjust_renown(Suit.Id.CUPS, 1, &"ONE_MORE_KINDNESS")
	assert_eq(_service.renown_tier(Suit.Id.CUPS), 2)
	assert_signal_emitted(_service, &"renown_tier_changed", 1)
	assert_eq(signal_arguments(_service, &"renown_tier_changed", 0), [Suit.Id.CUPS, 1, 2])


func test_the_tier_signal_fires_when_standing_is_lost() -> void:
	_service.adjust_renown(Suit.Id.WANDS, 30, &"FINISHED_A_TRIAL_PIECE")
	watch_signal(_service, &"renown_tier_changed")
	_service.adjust_renown(Suit.Id.WANDS, -25, &"ABANDONED_THE_WORK")
	assert_eq(signal_arguments(_service, &"renown_tier_changed", 0), [Suit.Id.WANDS, 3, 1])


func test_the_tier_name_is_a_key_not_a_word() -> void:
	_service.adjust_renown(Suit.Id.COINS, 100, &"MADE_A_FORTUNE")
	assert_eq(_service.renown_tier(Suit.Id.COINS), 5)
	assert_eq(_service.renown_tier_name_key(Suit.Id.COINS), &"RENOWN_TIER_FABLED")


func test_the_renown_ladder_comes_from_the_data_not_from_literals() -> void:
	var retuned := RenownLadder.new()
	retuned.id = &"RENOWN_LADDER"
	retuned.tier_names = PackedStringArray(["Nobody", "Somebody", "Known", "Trusted", "Legend"])
	retuned.tier_min_values = PackedInt32Array([0, 1, 2, 3, 4])
	var service := WorldStateService.new(_catalog, _thresholds, retuned)
	service.adjust_renown(Suit.Id.CUPS, 3, &"A_FEW_KINDNESSES")
	assert_eq(service.renown_tier(Suit.Id.CUPS), 4, "the rungs are data, not constants")
	assert_eq(service.renown_tier_name_key(Suit.Id.CUPS), &"RENOWN_TIER_TRUSTED")


# --- The Hermit's answer -----------------------------------------------------


func test_the_hermit_answer_is_set_once() -> void:
	assert_eq(_service.hermit_answer(), &"", "the tea has not happened yet")
	watch_signal(_service, &"hermit_answer_set")
	assert_true(_service.set_hermit_answer(&"MQ09_ANSWER_KINDNESS"))
	assert_eq(_service.hermit_answer(), &"MQ09_ANSWER_KINDNESS")
	assert_false(
		_service.set_hermit_answer(&"MQ09_ANSWER_FEAR"), "the Fool answers the Hermit once"
	)
	assert_eq(_service.hermit_answer(), &"MQ09_ANSWER_KINDNESS", "and the first answer stands")
	assert_signal_emitted(_service, &"hermit_answer_set", 1)
	assert_eq(signal_arguments(_service, &"hermit_answer_set", 0), [&"MQ09_ANSWER_KINDNESS"])


func test_an_empty_hermit_answer_is_refused() -> void:
	var accepted: bool = _quietly(func() -> bool: return _service.set_hermit_answer(&""))
	assert_false(accepted)
	assert_eq(_service.hermit_answer(), &"")


# --- Named-NPC memory --------------------------------------------------------


func test_a_named_npc_remembers_a_thing_once() -> void:
	watch_signal(_service, &"npc_memory_flag_set")
	assert_true(_service.npc_remember(&"flick", &"MET_THE_FOOL"))
	assert_false(_service.npc_remember(&"flick", &"MET_THE_FOOL"), "memory is append-only")
	assert_true(_service.npc_remembers(&"flick", &"MET_THE_FOOL"))
	assert_signal_emitted(_service, &"npc_memory_flag_set", 1)
	assert_eq(signal_arguments(_service, &"npc_memory_flag_set", 0), [&"flick", &"MET_THE_FOOL"])


func test_npc_memories_do_not_leak_between_npcs() -> void:
	_service.npc_remember(&"flick", &"MET_THE_FOOL")
	assert_false(_service.npc_remembers(&"old_tomkin", &"MET_THE_FOOL"))
	assert_eq(_service.npc_memory(&"old_tomkin").size(), 0)


func test_npc_memory_is_handed_out_as_a_copy() -> void:
	_service.npc_remember(&"flick", &"MET_THE_FOOL")
	var memory := _service.npc_memory(&"flick")
	memory.append(&"OWES_THE_FOOL_MONEY")
	assert_eq(_service.npc_memory(&"flick").size(), 1, "a caller cannot rewrite what Flick knows")


func test_npc_memory_keeps_the_order_it_was_learned_in() -> void:
	_service.npc_remember(&"flick", &"MET_THE_FOOL")
	_service.npc_remember(&"flick", &"SAW_THE_SHOW_END")
	assert_eq(_service.npc_memory(&"flick"), [&"MET_THE_FOOL", &"SAW_THE_SHOW_END"] as Array[StringName])


# --- Quest state -------------------------------------------------------------


func test_quest_state_starts_empty_and_reports_its_moves() -> void:
	assert_eq(_service.quest_state(&"MQ00"), &"")
	watch_signal(_service, &"quest_state_changed")
	_service.set_quest_state(&"MQ00", &"ACTIVE")
	assert_eq(_service.quest_state(&"MQ00"), &"ACTIVE")
	_service.set_quest_state(&"MQ00", &"ACTIVE")
	assert_signal_emitted(_service, &"quest_state_changed", 1, "a no-op transition is silent")
	_service.set_quest_state(&"MQ00", &"COMPLETE")
	assert_eq(signal_arguments(_service, &"quest_state_changed", 1), [&"MQ00", &"ACTIVE", &"COMPLETE"])


# --- Save --------------------------------------------------------------------


func _play_a_little() -> void:
	_service.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	_service.fire(WorldStateIds.WS_TROUPE_TRAVELING, &"MQ01")
	_service.fire(WorldStateIds.WS_PRIESTESS_UNBOUND, &"MQ02")
	_service.adjust_renown(Suit.Id.CUPS, 26, &"GUEST_RIGHT_HONOURED")
	_service.adjust_renown(Suit.Id.SWORDS, 4, &"A_MATTER_OF_FORM")
	_service.set_hermit_answer(&"MQ09_ANSWER_KINDNESS")
	_service.npc_remember(&"flick", &"MET_THE_FOOL")
	_service.npc_remember(&"flick", &"SAW_THE_SHOW_END")
	_service.set_quest_state(&"MQ01", &"COMPLETE")


func test_a_snapshot_holds_only_ids_ints_and_strings() -> void:
	_play_a_little()
	var snapshot := _service.to_snapshot()
	var round_tripped: Variant = JSON.parse_string(JSON.stringify(snapshot))
	assert_true(round_tripped is Dictionary, "the snapshot survives a trip through JSON")


func test_a_snapshot_restores_into_an_identical_world() -> void:
	_play_a_little()
	var snapshot := _service.to_snapshot()
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	assert_eq(loaded.restore_snapshot(snapshot), PackedStringArray(), "a clean save has no problems")
	assert_eq(loaded.to_snapshot(), snapshot, "what came out goes back in unchanged")
	assert_true(loaded.is_fired(WorldStateIds.WS_PRIESTESS_UNBOUND))
	assert_eq(loaded.fired_by(WorldStateIds.WS_PRIESTESS_UNBOUND), &"MQ02")
	assert_eq(loaded.unbound_count(), 2, "the branch flag is not counted after a load either")
	assert_eq(loaded.reading_order(), _service.reading_order())
	assert_eq(loaded.renown(Suit.Id.CUPS), 26)
	assert_eq(loaded.renown_tier(Suit.Id.CUPS), 3)
	assert_eq(loaded.hermit_answer(), &"MQ09_ANSWER_KINDNESS")
	assert_eq(loaded.npc_memory(&"flick").size(), 2)
	assert_eq(loaded.quest_state(&"MQ01"), &"COMPLETE")


func test_a_load_leaves_the_count_the_reading_and_the_flags_agreeing() -> void:
	# The three ways the game asks "how far along is this?" must answer the same
	# thing after a load, or content keyed to one contradicts content keyed to
	# another. The count is derived from the committed flags, never carried in the
	# save, so there is nothing for a save editor to desynchronise.
	_unbind(9)
	_service.fire(WorldStateIds.WS_TROUPE_SETTLED, &"MQ01")
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	assert_eq(loaded.restore_snapshot(_service.to_snapshot()), PackedStringArray())
	var restored_unbindings := 0
	for flag_id: StringName in WorldStateIds.UNBINDING:
		if loaded.is_fired(flag_id):
			restored_unbindings += 1
	assert_eq(restored_unbindings, 9)
	assert_eq(loaded.unbound_count(), restored_unbindings)
	assert_eq(loaded.reading_order().size(), restored_unbindings)
	assert_false(loaded.is_pristine(), "a loaded world is in play")


func test_the_act_survives_a_load() -> void:
	_unbind(15)
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	loaded.restore_snapshot(_service.to_snapshot())
	assert_eq(loaded.unbound_count(), 15)
	assert_eq(loaded.act(), WorldStateService.Act.ACT_III)


func test_restoring_emits_nothing() -> void:
	# Loading is not an event: a subscriber must not hear three hundred years of
	# world change arrive in one frame (technical.md §The WorldState service).
	_play_a_little()
	var snapshot := _service.to_snapshot()
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	watch_signal(loaded, &"world_state_fired")
	watch_signal(loaded, &"act_changed")
	watch_signal(loaded, &"reading_appended")
	watch_signal(loaded, &"renown_changed")
	watch_signal(loaded, &"renown_tier_changed")
	watch_signal(loaded, &"hermit_answer_set")
	watch_signal(loaded, &"npc_memory_flag_set")
	watch_signal(loaded, &"quest_state_changed")
	loaded.restore_snapshot(snapshot)
	for signal_name: StringName in [
		&"world_state_fired",
		&"act_changed",
		&"reading_appended",
		&"renown_changed",
		&"renown_tier_changed",
		&"hermit_answer_set",
		&"npc_memory_flag_set",
		&"quest_state_changed",
	]:
		assert_signal_emitted(loaded, signal_name, 0, "%s must be silent during a load" % signal_name)


func test_a_snapshot_naming_a_flag_this_build_lost_is_reported_and_commits_nothing() -> void:
	var snapshot := _service.to_snapshot()
	snapshot[WorldStateService.SNAPSHOT_FIRED][String(UNKNOWN_FLAG)] = "MQ99"
	snapshot[WorldStateService.SNAPSHOT_READING].append(String(UNKNOWN_FLAG))
	var problems := _service.restore_snapshot(snapshot)
	assert_eq(problems.size(), 2, "one problem per unreadable entry: %s" % str(problems))
	assert_has(str(problems), String(UNKNOWN_FLAG))
	assert_eq(_service.unbound_count(), 0)
	assert_true(_service.is_pristine(), "a refused load leaves a service still loadable")


func test_a_snapshot_naming_an_unknown_suit_is_reported_and_commits_nothing() -> void:
	var snapshot := _service.to_snapshot()
	snapshot[WorldStateService.SNAPSHOT_RENOWN]["PENTACLES"] = 40
	var problems := _service.restore_snapshot(snapshot)
	assert_eq(problems.size(), 1, str(problems))
	assert_has(str(problems), "PENTACLES")
	assert_true(_service.is_pristine())


func test_a_reading_that_names_an_unbinding_that_never_fired_is_refused() -> void:
	# A Reading entry with no flag behind it is a world whose own history disagrees
	# with itself; no later system could tell which half was true.
	_unbind(2)
	var snapshot := _service.to_snapshot()
	snapshot[WorldStateService.SNAPSHOT_READING].append(String(WorldStateIds.WS_SUN_UNBOUND))
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	var problems := loaded.restore_snapshot(snapshot)
	assert_eq(problems.size(), 1, str(problems))
	assert_has(str(problems), String(WorldStateIds.WS_SUN_UNBOUND))
	assert_eq(loaded.unbound_count(), 0, "nothing at all was committed")
	assert_eq(loaded.reading_order().size(), 0)
	assert_true(loaded.is_pristine())


func test_a_reading_that_repeats_an_unbinding_is_refused() -> void:
	_unbind(2)
	var snapshot := _service.to_snapshot()
	snapshot[WorldStateService.SNAPSHOT_READING].append(String(WorldStateIds.WS_MAGICIAN_UNBOUND))
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	var problems := loaded.restore_snapshot(snapshot)
	assert_eq(problems.size(), 1, str(problems))
	assert_has(str(problems), String(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_eq(loaded.reading_order().size(), 0, "an Arcana is unbound once, in the save too")
	assert_true(loaded.is_pristine())


func test_an_unbinding_the_reading_never_recorded_is_refused() -> void:
	_unbind(2)
	var snapshot := _service.to_snapshot()
	var reading: Array = snapshot[WorldStateService.SNAPSHOT_READING]
	reading.remove_at(0)
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	var problems := loaded.restore_snapshot(snapshot)
	assert_eq(problems.size(), 1, str(problems))
	assert_has(str(problems), String(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_eq(loaded.unbound_count(), 0)
	assert_true(loaded.is_pristine())


func test_a_misshapen_snapshot_is_reported_and_never_crashes() -> void:
	var problems := _service.restore_snapshot(
		{
			WorldStateService.SNAPSHOT_FIRED: "not a dictionary",
			WorldStateService.SNAPSHOT_READING: 7,
			WorldStateService.SNAPSHOT_RENOWN: {"CUPS": "not a number"},
			WorldStateService.SNAPSHOT_NPC_MEMORY: {"flick": 3},
		}
	)
	assert_eq(problems.size(), 4, "every malformed field is named: %s" % str(problems))
	assert_eq(_service.unbound_count(), 0)
	assert_eq(_service.renown(Suit.Id.CUPS), 0)


func test_an_empty_snapshot_loads_as_a_new_game() -> void:
	assert_eq(_service.restore_snapshot({}), PackedStringArray(), "nothing saved is not a problem")
	assert_eq(_service.unbound_count(), 0)
	assert_eq(_service.act(), WorldStateService.Act.ACT_I)
	assert_eq(_service.hermit_answer(), &"")


func test_a_load_refuses_a_world_already_in_play() -> void:
	# A load is not a reset. Loading a save means building a service and filling it;
	# a `restore_snapshot()` that blanked a world in play would be the un-fire this
	# service exists to make unwritable, reachable by any caller with a save file.
	_play_a_little()
	var in_play := WorldStateService.new(_catalog, _thresholds, _ladder)
	in_play.fire(WorldStateIds.WS_SUN_UNBOUND, &"MQ19")
	assert_false(in_play.is_pristine(), "one fired flag is a world in play")
	var before := in_play.to_snapshot()
	watch_signal(in_play, &"world_state_fired")
	watch_signal(in_play, &"act_changed")
	watch_signal(in_play, &"reading_appended")
	var problems := in_play.restore_snapshot(_service.to_snapshot())
	assert_eq(problems.size(), 1, "one refusal, not a list of field problems: %s" % str(problems))
	assert_true(in_play.is_fired(WorldStateIds.WS_SUN_UNBOUND), "the Sun stays unbound")
	assert_false(
		in_play.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "and the save did not merge in"
	)
	assert_eq(in_play.to_snapshot(), before, "nothing else moved either")
	assert_signal_emitted(in_play, &"world_state_fired", 0)
	assert_signal_emitted(in_play, &"act_changed", 0)
	assert_signal_emitted(in_play, &"reading_appended", 0)


func test_a_service_is_pristine_until_it_is_played_or_loaded() -> void:
	assert_true(_service.is_pristine(), "a fresh service has no world in it yet")
	_service.adjust_renown(Suit.Id.CUPS, 1, &"A_SMALL_KINDNESS")
	assert_false(_service.is_pristine(), "any mutation is a world in play")
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	assert_eq(loaded.restore_snapshot(_service.to_snapshot()), PackedStringArray())
	assert_false(loaded.is_pristine(), "a loaded world is in play too, and cannot be loaded over")


# --- Definitions are immutable ------------------------------------------------


func test_playing_the_game_never_writes_to_a_definition() -> void:
	# technical.md §The runtime data model: definitions are authored data, loaded
	# once, never written to during play. The catalog is a cached resource, so a
	# single stray write would follow the player into every later scene.
	var before := PackedStringArray()
	for entry: WorldStateDefinition in _catalog.entries:
		before.append(_fingerprint(entry))
	_unbind(21)
	for flag_id: StringName in WorldStateIds.BRANCH:
		_service.fire(flag_id, _catalog.find(flag_id).fired_by)
	_play_a_little()
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	loaded.restore_snapshot(_service.to_snapshot())
	var after := PackedStringArray()
	for entry: WorldStateDefinition in _catalog.entries:
		after.append(_fingerprint(entry))
	assert_eq(after, before, "a definition changed while the game was running")


func _fingerprint(definition: WorldStateDefinition) -> String:
	return "%s|%d|%s|%d|%s|%s" % [
		definition.id,
		definition.kind,
		definition.fired_by,
		definition.arcana_number,
		definition.branch_group,
		definition.effect_summary,
	]


# --- Quest branch choices ----------------------------------------------------


func test_a_quest_has_chosen_nothing_to_begin_with() -> void:
	assert_eq(_service.quest_choice(&"MQ01", &"MQ01_TROUPE"), &"")


func test_a_choice_is_recorded_once_and_then_refused() -> void:
	watch_signal(_service, &"quest_choice_made")
	assert_true(
		_service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_TRAVELING),
		"the first choice is the quest's to make"
	)
	assert_eq(_service.quest_choice(&"MQ01", &"MQ01_TROUPE"), WorldStateIds.WS_TROUPE_TRAVELING)
	assert_false(
		_service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_SETTLED),
		"the other half of a made choice is refused"
	)
	assert_eq(
		_service.quest_choice(&"MQ01", &"MQ01_TROUPE"),
		WorldStateIds.WS_TROUPE_TRAVELING,
		"and the refusal changed nothing"
	)
	assert_signal_emitted(_service, &"quest_choice_made", 1)


func test_a_choice_is_not_a_fire() -> void:
	watch_signal(_service, &"world_state_fired")
	_service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_SETTLED)
	assert_false(
		_service.is_fired(WorldStateIds.WS_TROUPE_SETTLED),
		"choosing a branch does not make it true; completing the quest does"
	)
	assert_signal_emitted(_service, &"world_state_fired", 0)
	assert_eq(_service.unbound_count(), 0)


func test_two_quests_choose_independently() -> void:
	_service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_TRAVELING)
	_service.set_quest_choice(&"MQ06", &"MQ06_DIVIDE", WorldStateIds.WS_DIVIDE_EASTMARRIED)
	assert_eq(_service.quest_choice(&"MQ01", &"MQ01_TROUPE"), WorldStateIds.WS_TROUPE_TRAVELING)
	assert_eq(_service.quest_choice(&"MQ06", &"MQ06_DIVIDE"), WorldStateIds.WS_DIVIDE_EASTMARRIED)


func test_only_a_branch_flag_can_be_chosen() -> void:
	var unknown: bool = _quietly(
		func() -> bool: return _service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", UNKNOWN_FLAG)
	)
	assert_false(unknown, "a flag the matrix does not define is not a choice")
	var unbinding: bool = _quietly(
		func() -> bool:
			return _service.set_quest_choice(
				&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_MAGICIAN_UNBOUND
			)
	)
	assert_false(unbinding, "an unbinding is not a branch a quest may pick")
	assert_true(_service.is_pristine(), "and neither refusal counted as play")


func test_a_choice_needs_a_quest_and_a_group() -> void:
	var no_quest: bool = _quietly(
		func() -> bool:
			return _service.set_quest_choice(&"", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_SETTLED)
	)
	assert_false(no_quest)
	var no_group: bool = _quietly(
		func() -> bool:
			return _service.set_quest_choice(&"MQ01", &"", WorldStateIds.WS_TROUPE_SETTLED)
	)
	assert_false(no_group)


func test_choices_round_trip_through_a_snapshot() -> void:
	_service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_SETTLED)
	var snapshot := _service.to_snapshot()
	var round_tripped: Variant = JSON.parse_string(JSON.stringify(snapshot))
	assert_true(round_tripped is Dictionary, "a choice survives a trip through JSON")
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	assert_eq(loaded.restore_snapshot(snapshot), PackedStringArray(), "a clean save has no problems")
	assert_eq(
		loaded.quest_choice(&"MQ01", &"MQ01_TROUPE"),
		WorldStateIds.WS_TROUPE_SETTLED,
		"the loaded world remembers what the quest chose"
	)
	assert_eq(loaded.to_snapshot(), snapshot, "what came out goes back in unchanged")


func test_restoring_a_choice_emits_nothing() -> void:
	_service.set_quest_choice(&"MQ01", &"MQ01_TROUPE", WorldStateIds.WS_TROUPE_SETTLED)
	var loaded := WorldStateService.new(_catalog, _thresholds, _ladder)
	watch_signal(loaded, &"quest_choice_made")
	loaded.restore_snapshot(_service.to_snapshot())
	assert_signal_emitted(loaded, &"quest_choice_made", 0)


func test_a_snapshot_choosing_something_impossible_is_reported_and_commits_nothing() -> void:
	var snapshot := _service.to_snapshot()
	snapshot[WorldStateService.SNAPSHOT_QUEST_CHOICES]["MQ01"] = {
		"MQ01_TROUPE": String(WorldStateIds.WS_MAGICIAN_UNBOUND),
	}
	var problems := _service.restore_snapshot(snapshot)
	assert_eq(problems.size(), 1, "the impossible choice is reported: %s" % str(problems))
	assert_eq(_service.quest_choice(&"MQ01", &"MQ01_TROUPE"), &"", "and nothing was committed")
