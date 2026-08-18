extends TarrockTest

## `BarkService.request()`: the seven-layer selector itself.
##
## Built over SYNTHETIC bark catalogs for most of this suite - `npc-system.md` owns
## no line and no pool (§Consistency note), so a test pinning its expectations to
## authored content would break the day a writer added a line. Ids, flags, quests and
## regions are the REAL ones (`WorldStateIds`, `QuestIds`, `RegionIds`, `Suit`,
## `NpcIds`) - only the bark TEXT KEYS and the pools they sit in are made up, exactly
## as `economy_service_test.gd` builds synthetic items against real world state.
##
## The one exception is `test_the_cliff_idle_pool_picks_all_four_before_repeating()`,
## which loads the real, checked-in Cliff content on purpose: that pool is the round's
## only proof content (`npc-system.md`'s Consistency note again), so a test that never
## touched it would leave the one shipped pool unexercised.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const CLIFF_BARK_CATALOG_PATH := "res://data/npc/barks/catalog.tres"
const CLIFF_NPC_RULES_PATH := "res://data/npc/npc_rules.tres"

## The real nine, because a NAMED speaker's suit is their profile's and the layer-7
## fall-through is keyed by it. Flick is the one whose suit is canon (a Page of Wands).
const PROFILE_CATALOG_PATH := "res://data/npc/profiles/catalog.tres"

## The five generated starter motifs, for the one test that reaches layer 2.
const MOTIF_CATALOG_PATH := "res://data/npc/motifs/catalog.tres"

var _world_state: WorldStateService = null
var _profiles: NpcCatalog = null


func before_each() -> void:
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_profiles = load(PROFILE_CATALOG_PATH) as NpcCatalog


# --- Layer priority and fall-through -------------------------------------------


func test_a_world_state_bark_wins_over_a_generic_one() -> void:
	var world_state_bark := _ambient_bark(&"BARK_WS", BarkLayer.WORLD_STATE, Suit.Id.CUPS)
	world_state_bark.requires_fired = [WorldStateIds.WS_EMPRESS_UNBOUND]
	var generic_bark := _ambient_bark(&"BARK_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([world_state_bark, generic_bark])
	var service := _service(catalog)
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)

	var pick := service.request(BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER))
	assert_eq(pick.layer, BarkLayer.WORLD_STATE, "layer 3 outranks layer 7, always")
	assert_eq(pick.bark_id(), &"BARK_WS")


func test_an_exhausted_layer_falls_through_to_the_next_one() -> void:
	var world_state_bark := _ambient_bark(&"BARK_WS", BarkLayer.WORLD_STATE, Suit.Id.CUPS)
	world_state_bark.requires_fired = [WorldStateIds.WS_EMPRESS_UNBOUND]
	var generic_bark := _ambient_bark(&"BARK_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([world_state_bark, generic_bark])
	var rules := _rules(3)
	var service := _service(catalog, rules)
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	var first := service.request(context)
	assert_eq(first.bark_id(), &"BARK_WS", "the only layer-3 line, spent")
	var second := service.request(context)
	assert_eq(second.layer, BarkLayer.GENERIC, "layer 3's one line is recently-spent; fall through")
	assert_eq(second.bark_id(), &"BARK_GENERIC")


func test_recently_spent_lines_are_excluded_then_decay_back() -> void:
	var bark_a := _ambient_bark(&"BARK_A", BarkLayer.GENERIC, Suit.Id.CUPS)
	var bark_b := _ambient_bark(&"BARK_B", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([bark_a, bark_b])
	# Memory of 1: only the SINGLE most recent pick is excluded, which makes every
	# pick after the first fully determined (one candidate left) whatever the seed.
	var service := _service(catalog, _rules(1))
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	# `BarkPick` IS REUSED (its own class doc says so): read `.bark_id()` into a
	# plain `StringName` right after each call, never hold the `BarkPick` itself
	# across the next `request()` - the next call re-stamps the same object.
	var first: StringName = service.request(context).bark_id()
	var second: StringName = service.request(context).bark_id()
	assert_ne(second, first, "the just-spent line is excluded")
	var third: StringName = service.request(context).bark_id()
	assert_eq(third, first, "memory of 1 forgot it; the first line decayed back")


func test_layer_six_is_not_evaluable_before_its_unbindings() -> void:
	var sky_bark := _ambient_bark(&"BARK_SKY", BarkLayer.TIME_WEATHER, Suit.Id.CUPS)
	sky_bark.time_band = TimeBand.Id.DAWN
	var generic_bark := _ambient_bark(&"BARK_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([sky_bark, generic_bark])
	var service := _service(catalog)
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)
	context.time_band = TimeBand.Id.DAWN

	var before := service.request(context)
	assert_eq(before.layer, BarkLayer.GENERIC, "no sun, no day - layer 6 is skipped whole")

	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	var after := service.request(context)
	assert_eq(after.layer, BarkLayer.TIME_WEATHER, "now the sky pool is real")
	assert_eq(after.bark_id(), &"BARK_SKY")


func test_layer_seven_always_yields_for_a_complete_catalog() -> void:
	var barks: Array[BarkDefinition] = []
	for suit: Suit.Id in Suit.ALL:
		barks.append(_ambient_bark(StringName("BARK_GENERIC_%d" % suit), BarkLayer.GENERIC, suit))
	var catalog := _catalog(barks)
	catalog.is_complete = true
	assert_eq(catalog.validate(), PackedStringArray(), "every suit has a floor")
	var service := _service(catalog)
	for suit: Suit.Id in Suit.ALL:
		var pick := service.request(BarkContext.ambient(suit, NpcRank.Id.NONE, RegionIds.BOWER))
		assert_false(pick.is_empty(), "suit %d never falls silent" % suit)
		assert_eq(pick.layer, BarkLayer.GENERIC)


func test_a_catalog_missing_a_suits_baseline_fails_validation() -> void:
	var barks: Array[BarkDefinition] = [
		_ambient_bark(&"BARK_CUPS", BarkLayer.GENERIC, Suit.Id.CUPS),
		_ambient_bark(&"BARK_SWORDS", BarkLayer.GENERIC, Suit.Id.SWORDS),
		_ambient_bark(&"BARK_WANDS", BarkLayer.GENERIC, Suit.Id.WANDS),
		# COINS has no layer-7 line.
	]
	var catalog := _catalog(barks)
	catalog.is_complete = true
	var errors := catalog.validate()
	var mentions_coins := false
	for error: String in errors:
		if error.contains("COINS"):
			mentions_coins = true
	assert_true(mentions_coins, "the missing suit is named: %s" % str(errors))
	assert_eq(catalog.suits_without_baseline(), [Suit.Id.COINS])


func test_layer_six_is_skipped_whole_rather_than_filtered_line_by_line() -> void:
	# `_matches_sky()` already refuses a DAWN line in a sunless world, so no VALID
	# layer-6 bark can tell the whole-layer gate from a per-line filter - which is why
	# this uses a line that names no sky at all. `validate()` refuses that line (first
	# assertion, so this test cannot quietly bless bad data), but the SERVICE never
	# validates, and §Bark layers is precise about the difference: before its
	# unbindings layer 6 is "**not evaluable at all**", not a pool that happens to
	# match nothing. Delete `_is_layer_evaluable()`'s gate and the first assertion
	# below goes red.
	var skyless := _ambient_bark(&"BARK_SKYLESS", BarkLayer.TIME_WEATHER, Suit.Id.CUPS)
	assert_true(
		_has_error(skyless.validate(), "names neither"),
		"a layer-6 line with no sky is refused by validation in the first place"
	)
	var generic_bark := _baseline(&"BARK_GENERIC", Suit.Id.CUPS)
	var service := _service(_catalog([skyless, generic_bark]))
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	assert_eq(
		service.request(context).layer,
		BarkLayer.GENERIC,
		"no sun and no Tower: layer 6 is not a pool with no matches, it is not there"
	)

	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, QuestIds.MQ19)
	assert_eq(
		service.request(context).layer,
		BarkLayer.TIME_WEATHER,
		"the sun makes the layer evaluable, and now the same line is asked"
	)


# --- The evergreen floor -------------------------------------------------------


func test_a_named_npc_with_no_bespoke_line_still_gets_their_suits_baseline() -> void:
	# The floor's whole promise, for a person: §Bark layers says the fall-through
	# always lands, and layer 7 is authored per SUIT, so a named NPC nobody has
	# written a line for draws the crowd's. Flick is a Page of Wands.
	var catalog := _catalog([
		_baseline(&"BARK_WANDS_GENERIC", Suit.Id.WANDS),
		_baseline(&"BARK_CUPS_GENERIC", Suit.Id.CUPS),
	])
	var service := _service(catalog)

	var pick := service.request(BarkContext.named(NpcIds.FLICK, RegionIds.PRESTIGE))
	assert_false(pick.is_empty(), "a named NPC never falls through the bottom either")
	assert_eq(pick.layer, BarkLayer.GENERIC)
	assert_eq(pick.bark_id(), &"BARK_WANDS_GENERIC", "his suit's baseline, not the Cups one")


func test_a_named_npc_with_no_suit_at_all_has_no_baseline_to_draw() -> void:
	# Six of the nine profiles leave `suit` unset rather than guess (`characters.md`
	# says nothing), and an unsuited speaker matches no suit's floor. That is a
	# CONTENT gap and it is meant to be audible: `bark_missing` is the round's own
	# "this is a bug, not flavor" signal.
	var service := _service(_catalog([_baseline(&"BARK_WANDS_GENERIC", Suit.Id.WANDS)]))
	var missing: Array[StringName] = []
	service.bark_missing.connect(
		func(speaker: StringName, _region: StringName) -> void: missing.append(speaker)
	)

	var pick := service.request(BarkContext.named(NpcIds.OLD_SALLOW, RegionIds.STILLMARSH))
	assert_true(pick.is_empty(), "no suit, no baseline - and no silent pretence otherwise")
	assert_eq(missing, [NpcIds.OLD_SALLOW] as Array[StringName], "the gap is announced")


func test_a_baseline_authored_for_one_person_is_not_a_suits_floor() -> void:
	# A Wands baseline said by Flick and nobody else leaves every other Wands speaker
	# with nothing, so it does not count - and the catalog says so twice: the line
	# itself fails validation, and the suit is still reported as floorless.
	var named_baseline := BarkDefinition.new()
	named_baseline.id = &"BARK_FLICK_BASELINE"
	named_baseline.layer = BarkLayer.GENERIC
	named_baseline.text_key = &"BARK_FLICK_BASELINE_KEY"
	named_baseline.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	named_baseline.speaker_id = NpcIds.FLICK
	named_baseline.suit = Suit.Id.WANDS
	var catalog := _catalog([named_baseline])

	assert_true(
		_has_error(named_baseline.validate(), "is a baseline for one person"),
		str(named_baseline.validate())
	)
	assert_true(
		catalog.suits_without_baseline().has(Suit.Id.WANDS),
		"Wands still has no floor: %s" % str(catalog.suits_without_baseline())
	)


func test_a_conditioned_layer_seven_line_is_not_a_floor_either() -> void:
	# `is_suit_baseline()` reads "evergreen" strictly, because the fall-through's
	# promise is strict: a line that can be filtered out is a line the floor can lose.
	var about_pip := _baseline(&"BARK_CUPS_ABOUT_PIP", Suit.Id.CUPS)
	about_pip.about_pip = true
	var catalog := _catalog([about_pip])
	assert_eq(about_pip.validate(), PackedStringArray(), "the line itself is legal")
	assert_true(
		catalog.suits_without_baseline().has(Suit.Id.CUPS),
		"but Cups has no evergreen line: %s" % str(catalog.suits_without_baseline())
	)


func test_an_ambient_speaker_with_no_suit_is_refused_at_the_context() -> void:
	# The other end of the same guarantee (`BarkContext.ambient()`): a crowd member
	# with no suit could match no floor, so the caller's bug is loud here rather than
	# an NPC that never speaks.
	var context: BarkContext = _quietly(
		func() -> BarkContext:
			return BarkContext.ambient(Suit.UNKNOWN, NpcRank.Id.NONE, RegionIds.BOWER)
	)
	assert_null(context, "a suitless Minor is not a speaker this system can serve")


# --- `request()` allocates nothing on the ordinary path -------------------------


func test_two_requests_from_one_context_build_one_pool_key() -> void:
	# `request()`'s class doc promises it does not allocate per call, and the pool key
	# is the string it used to build twice a call. A context re-asked is a context
	# whose key was built exactly once - the behavioural proxy for that promise.
	var catalog := _catalog([
		_baseline(&"BARK_CUPS_A", Suit.Id.CUPS),
		_baseline(&"BARK_CUPS_B", Suit.Id.CUPS),
	])
	var service := _service(catalog, _rules(0))
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	var first: StringName = service.request(context).bark_id()
	var second: StringName = service.request(context).bark_id()
	assert_eq(second, first, "a memory of 0 forgets at once; the seeded pick repeats")
	assert_eq(context.pool_key_builds(), 1, "one key, however many requests")

	# Re-stamping the context is the case a cached key must NOT get wrong.
	context.region_id = RegionIds.PRESTIGE
	assert_eq(
		context.pool_key(),
		"AMBIENT|%d|%d|%s" % [Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.PRESTIGE],
		"a re-stamped context is a different pool"
	)
	assert_eq(context.pool_key_builds(), 2, "and rebuilds exactly once more")


func test_a_pool_key_that_has_spent_nothing_is_answered_without_a_ring() -> void:
	# The other allocation `request()` used to make: a fresh empty ring per call, out
	# of `Dictionary.get()`'s eagerly-evaluated default, whether or not the key needed
	# one. A key earns a ring by SPENDING - so a service whose memory is 0 remembers
	# nothing and owns nothing to remember it in, however often it is asked.
	var forgetful := _service(_catalog([_baseline(&"BARK_CUPS", Suit.Id.CUPS)]), _rules(0))
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)
	forgetful.request(context)
	forgetful.request(context)
	assert_eq(
		forgetful.remembered_pool_keys(),
		PackedStringArray(),
		"no line was remembered, so no ring was made to remember it in"
	)
	assert_eq(forgetful.recent_picks(context.pool_key()), [] as Array[StringName])

	# And a service that DOES remember owns exactly the one ring it spent out of.
	var remembering := _service(_catalog([_baseline(&"BARK_CUPS", Suit.Id.CUPS)]), _rules(3))
	remembering.request(context)
	assert_eq(
		remembering.remembered_pool_keys(),
		PackedStringArray([context.pool_key()]),
		"one pool spoke, one pool remembers"
	)


func test_the_reading_is_only_read_when_a_motif_line_asks_for_it() -> void:
	# The lazy read, proved by its RESULT rather than by counting calls: a layer-2
	# line whose motif matches the live Reading still wins, which it could not do if
	# the Reading were never read - and every other request in this file passes
	# without a world state's `reading_order()` being touched at all.
	var motif_bark := _ambient_bark(&"BARK_MOTIF", BarkLayer.SEQUENCE, Suit.Id.CUPS)
	motif_bark.motif = MotifIds.MOTIF_MAGICIAN_NOT_FIRST
	var catalog := _catalog([motif_bark, _baseline(&"BARK_GENERIC", Suit.Id.CUPS)])
	var service := BarkService.new(
		catalog, load(MOTIF_CATALOG_PATH) as MotifCatalog, _profiles, _rules(3),
		_world_state, null, null, null, null, 7
	)
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	assert_eq(service.request(context).layer, BarkLayer.GENERIC, "an empty Reading has no shape")

	_world_state.fire(WorldStateIds.WS_PRIESTESS_UNBOUND, QuestIds.MQ02)
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	assert_eq(
		service.request(context).bark_id(),
		&"BARK_MOTIF",
		"the Magician came second, and the layer-2 line read the Reading to find out"
	)


# --- Named memory, act, CONFESSED, Renown --------------------------------------


func test_a_named_memory_flag_gates_a_layer_one_line() -> void:
	var memory_bark := BarkDefinition.new()
	memory_bark.id = &"BARK_MEMORY"
	memory_bark.layer = BarkLayer.QUEST_SCRIPTED
	memory_bark.text_key = &"BARK_MEMORY_KEY"
	memory_bark.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	memory_bark.speaker_id = NpcIds.FLICK
	memory_bark.npc_memory_flag = NpcMemoryIds.SAW_THE_SHOW_END
	# Flick's floor is his SUIT's baseline, not a line of his own: layer 7 is
	# "authored once per suit" and a per-person one is refused (see
	# `test_a_layer_seven_line_may_not_be_authored_for_one_person()`).
	var generic_bark := _baseline(&"BARK_WANDS_GENERIC", Suit.Id.WANDS)
	var catalog := _catalog([memory_bark, generic_bark])
	var service := _service(catalog)
	var context := BarkContext.named(NpcIds.FLICK, RegionIds.PRESTIGE)

	var before := service.request(context)
	assert_eq(before.bark_id(), &"BARK_WANDS_GENERIC", "Flick has not learned it yet")

	_world_state.npc_remember(NpcIds.FLICK, NpcMemoryIds.SAW_THE_SHOW_END)
	var after := service.request(context)
	assert_eq(after.bark_id(), &"BARK_MEMORY", "now he has, and the layer-1-adjacent line wins")


func test_an_act_condition_gates_a_layer_four_line() -> void:
	var act_bark := _ambient_bark(&"BARK_ACT_II", BarkLayer.ACT_STATE, Suit.Id.CUPS)
	act_bark.act = WorldStateService.Act.ACT_II
	var generic_bark := _ambient_bark(&"BARK_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([act_bark, generic_bark])
	var service := _service(catalog)
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	assert_eq(service.request(context).layer, BarkLayer.GENERIC, "still Act I")
	for flag: StringName in [
		WorldStateIds.WS_MAGICIAN_UNBOUND, WorldStateIds.WS_PRIESTESS_UNBOUND,
		WorldStateIds.WS_EMPRESS_UNBOUND, WorldStateIds.WS_EMPEROR_UNBOUND,
		WorldStateIds.WS_HIEROPHANT_UNBOUND, WorldStateIds.WS_LOVERS_UNBOUND,
		WorldStateIds.WS_CHARIOT_UNBOUND,
	]:
		_world_state.fire(flag, QuestIds.MQ01)
	assert_eq(_world_state.act(), WorldStateService.Act.ACT_II)
	assert_eq(service.request(context).bark_id(), &"BARK_ACT_II")


func test_a_confessed_condition_gates_a_layer_four_line() -> void:
	var confessed_bark := _ambient_bark(&"BARK_CONFESSED", BarkLayer.ACT_STATE, Suit.Id.CUPS)
	confessed_bark.requires_confessed = BarkDefinition.CONFESSED
	var generic_bark := _ambient_bark(&"BARK_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([confessed_bark, generic_bark])
	var service := _service(catalog)
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	assert_eq(service.request(context).layer, BarkLayer.GENERIC)
	_world_state.fire(WorldStateIds.WS_DEATH_UNBOUND, QuestIds.MQ13)
	assert_true(_world_state.is_confessed())
	assert_eq(service.request(context).bark_id(), &"BARK_CONFESSED")


func test_a_renown_tier_condition_gates_a_layer_five_line() -> void:
	var honored_bark := _ambient_bark(&"BARK_HONORED", BarkLayer.RENOWN, Suit.Id.CUPS)
	honored_bark.renown_tier_min = 4
	var generic_bark := _ambient_bark(&"BARK_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var catalog := _catalog([honored_bark, generic_bark])
	var service := _service(catalog)
	var context := BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, RegionIds.BOWER)

	assert_eq(service.request(context).layer, BarkLayer.GENERIC, "a Stranger, tier 1")
	_world_state.adjust_renown(Suit.Id.CUPS, 1000, &"TEST")
	assert_true(_world_state.renown_tier(Suit.Id.CUPS) >= 4)
	assert_eq(service.request(context).bark_id(), &"BARK_HONORED")


# --- Rumours, phrased per suit --------------------------------------------------


func test_a_rumor_bark_is_phrased_per_the_speakers_suit() -> void:
	const HOME := &"TEST_HOME"
	const ADJACENT := &"TEST_ADJACENT"
	const TEST_QUEST := &"MQ_TEST"

	var quest := QuestDefinition.new()
	quest.id = TEST_QUEST
	quest.type = QuestDefinition.Type.MAIN
	quest.region_id = HOME
	var quests_catalog := QuestCatalog.new()
	quests_catalog.entries = [quest]

	var graph := RegionGraph.new()
	var edge := RegionEdge.new()
	edge.a = HOME
	edge.b = ADJACENT
	edge.kind = RegionEdge.Kind.ROAD
	graph.edges = [edge]

	var cups_rumor := _ambient_bark(&"BARK_RUMOR_CUPS", BarkLayer.WORLD_STATE, Suit.Id.CUPS)
	cups_rumor.rumor_of_quest = TEST_QUEST
	var swords_rumor := _ambient_bark(&"BARK_RUMOR_SWORDS", BarkLayer.WORLD_STATE, Suit.Id.SWORDS)
	swords_rumor.rumor_of_quest = TEST_QUEST
	var cups_generic := _ambient_bark(&"BARK_CUPS_GENERIC", BarkLayer.GENERIC, Suit.Id.CUPS)
	var swords_generic := _ambient_bark(&"BARK_SWORDS_GENERIC", BarkLayer.GENERIC, Suit.Id.SWORDS)
	var catalog := _catalog([cups_rumor, swords_rumor, cups_generic, swords_generic])

	var clock := GameClock.new()
	var service := BarkService.new(
		catalog, null, null, _rules(3), _world_state, quests_catalog, graph, null, clock
	)
	service.rumors().seed_rumor(TEST_QUEST)
	clock.advance(_rules(3).rumor_delay_seconds(true) + 1.0)

	var cups_pick := service.request(BarkContext.ambient(Suit.Id.CUPS, NpcRank.Id.NONE, ADJACENT))
	assert_eq(cups_pick.bark_id(), &"BARK_RUMOR_CUPS")
	var swords_pick := service.request(
		BarkContext.ambient(Suit.Id.SWORDS, NpcRank.Id.NONE, ADJACENT)
	)
	assert_eq(swords_pick.bark_id(), &"BARK_RUMOR_SWORDS")


# --- The one real, shipped pool -------------------------------------------------


func test_the_cliff_idle_pool_picks_all_four_before_repeating() -> void:
	var catalog := load(CLIFF_BARK_CATALOG_PATH) as BarkCatalog
	var rules := load(CLIFF_NPC_RULES_PATH) as NpcRules
	var service := BarkService.new(catalog, null, null, rules, null, null, null, null, null, 7)
	var context := BarkContext.querent(RegionIds.CLIFF)

	var seen: Dictionary = {}
	var picks: Array[StringName] = []
	for _iteration: int in range(4):
		var pick := service.request(context)
		assert_false(pick.is_empty(), "the Cliff's evergreen pool never falls silent")
		picks.append(pick.bark_id())
		seen[pick.bark_id()] = true
	assert_eq(seen.size(), 4, "all four idle lines were said before any repeated: %s" % str(picks))

	var fifth := service.request(context)
	assert_eq(
		fifth.bark_id(), picks[0], "memory of 3 forgot the very first line; it is the only one left"
	)


# --- Internals ---------------------------------------------------------------


func _ambient_bark(bark_id: StringName, layer: int, suit: Suit.Id) -> BarkDefinition:
	var bark := BarkDefinition.new()
	bark.id = bark_id
	bark.layer = layer
	bark.text_key = StringName(String(bark_id) + "_KEY")
	bark.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	bark.suit = suit
	return bark


func _catalog(barks: Array[BarkDefinition]) -> BarkCatalog:
	var catalog := BarkCatalog.new()
	catalog.entries = barks
	return catalog


func _rules(recent_pick_memory: int) -> NpcRules:
	var rules := NpcRules.new()
	rules.id = &"NPC_RULES_TEST"
	rules.recent_pick_memory = recent_pick_memory
	rules.rumor_adjacent_delay_hours = 6.0
	rules.rumor_world_delay_hours = 48.0
	rules.seconds_per_in_game_hour = 1.0
	return rules


func _service(catalog: BarkCatalog, rules: NpcRules = null) -> BarkService:
	return BarkService.new(
		catalog, null, _profiles, rules if rules != null else _rules(3), _world_state,
		null, null, null, null, 7
	)


## A layer-7 suit baseline for the crowd: the evergreen floor, and nothing else.
func _baseline(bark_id: StringName, suit: Suit.Id) -> BarkDefinition:
	return _ambient_bark(bark_id, BarkLayer.GENERIC, suit)


## Run `action` with the engine's error printing muted, and hand back its result.
##
## `BarkContext.ambient()` with no suit is MEANT to push an error - that is how a
## caller's bug surfaces instead of an NPC going quiet. But `run_all.sh` fails any
## stage whose log holds an engine error line, so a test that provokes one deliberately
## must not print it.
func _quietly(action: Callable) -> Variant:
	var was_printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Variant = action.call()
	Engine.print_error_messages = was_printing
	return result


func _has_error(errors: PackedStringArray, needle: String) -> bool:
	for error: String in errors:
		if error.contains(needle):
			return true
	return false
