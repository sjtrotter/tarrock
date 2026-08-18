extends TarrockTest

## The world-state definitions, judged on their own terms.
##
## These are the shapes `docs/design/world.md` §World-state matrix and
## `docs/design/progression.md` §Renown are generated into. Everything here builds
## its own resources: what the *generated* data says is
## `world_state_data_test.gd`'s job, and what the service does with it is
## `world_state_service_test.gd`'s.


func _unbinding(state_id: StringName, number: int) -> WorldStateDefinition:
	var definition := WorldStateDefinition.new()
	definition.id = state_id
	definition.kind = WorldStateDefinition.Kind.UNBINDING
	definition.fired_by = StringName("MQ%02d" % number)
	definition.arcana_number = number
	return definition


func _branch(state_id: StringName, group: StringName) -> WorldStateDefinition:
	var definition := WorldStateDefinition.new()
	definition.id = state_id
	definition.kind = WorldStateDefinition.Kind.BRANCH
	definition.fired_by = &"MQ01"
	definition.branch_group = group
	return definition


func _full_catalog() -> WorldStateCatalog:
	var catalog := WorldStateCatalog.new()
	var entries: Array[WorldStateDefinition] = []
	for number: int in range(
		WorldStateDefinition.FIRST_ARCANA, WorldStateDefinition.LAST_ARCANA + 1
	):
		entries.append(_unbinding(StringName("WS_CARD_%02d" % number), number))
	entries.append(_branch(&"WS_TROUPE_TRAVELING", &"MQ01_TROUPE"))
	entries.append(_branch(&"WS_TROUPE_SETTLED", &"MQ01_TROUPE"))
	catalog.entries = entries
	return catalog


# --- WorldStateDefinition ----------------------------------------------------


func test_a_well_formed_unbinding_is_valid() -> void:
	var definition := _unbinding(&"WS_MAGICIAN_UNBOUND", 1)
	assert_eq(definition.validate(), PackedStringArray(), "a matrix row as written is valid")
	assert_true(definition.is_unbinding())


func test_a_well_formed_branch_is_valid() -> void:
	var definition := _branch(&"WS_TROUPE_SETTLED", &"MQ01_TROUPE")
	assert_eq(definition.validate(), PackedStringArray())
	assert_false(definition.is_unbinding(), "a branch flag is not an unbinding")


func test_an_id_that_is_not_a_ws_flag_is_invalid() -> void:
	var definition := _unbinding(&"MAGICIAN_UNBOUND", 1)
	assert_eq(definition.validate().size(), 1)
	assert_has(definition.validate()[0], "not a WS_ flag")


func test_a_lowercase_id_is_invalid() -> void:
	var definition := _unbinding(&"WS_magician_unbound", 1)
	assert_false(definition.is_valid(), "the matrix is SHOUTING_SNAKE_CASE")


func test_an_empty_id_is_invalid() -> void:
	var definition := _unbinding(&"", 1)
	assert_false(definition.is_valid(), "the base class catches the empty id")


func test_a_flag_nothing_fires_is_invalid() -> void:
	var definition := _unbinding(&"WS_MAGICIAN_UNBOUND", 1)
	definition.fired_by = &""
	assert_has(definition.validate()[0], "names no firing quest")


func test_an_unbinding_needs_a_card_number_in_range() -> void:
	var without := _unbinding(&"WS_MAGICIAN_UNBOUND", 1)
	without.arcana_number = 0
	assert_has(without.validate()[0], "outside 1..21")
	var beyond := _unbinding(&"WS_MAGICIAN_UNBOUND", 1)
	beyond.arcana_number = 22
	assert_has(beyond.validate()[0], "outside 1..21")


func test_an_unbinding_may_not_belong_to_a_branch_group() -> void:
	var definition := _unbinding(&"WS_MAGICIAN_UNBOUND", 1)
	definition.branch_group = &"MQ01_TROUPE"
	assert_has(definition.validate()[0], "names a branch group")


func test_a_branch_needs_a_branch_group() -> void:
	var definition := _branch(&"WS_TROUPE_SETTLED", &"")
	assert_has(definition.validate()[0], "no branch group")


func test_a_branch_may_not_carry_a_card_number() -> void:
	var definition := _branch(&"WS_TROUPE_SETTLED", &"MQ01_TROUPE")
	definition.arcana_number = 1
	assert_has(definition.validate()[0], "carries card number")


# --- WorldStateCatalog -------------------------------------------------------


func test_a_complete_catalog_is_valid() -> void:
	assert_eq(_full_catalog().validate(), PackedStringArray())


func test_find_answers_by_id_and_nothing_else() -> void:
	var catalog := _full_catalog()
	var found := catalog.find(&"WS_CARD_07")
	if not assert_not_null(found, "an id in the catalog is found"):
		return
	assert_eq(found.arcana_number, 7)
	assert_true(catalog.has(&"WS_TROUPE_SETTLED"))
	assert_null(catalog.find(&"WS_NOT_A_FLAG"), "an id nobody wrote down is not invented")
	assert_false(catalog.has(&"WS_NOT_A_FLAG"))


func test_unbinding_ids_are_in_card_order() -> void:
	var catalog := _full_catalog()
	# Author them backwards: the catalog sorts by card number, not by file order.
	catalog.entries.reverse()
	var ids := catalog.unbinding_ids()
	assert_eq(ids.size(), WorldStateDefinition.LAST_ARCANA, "branch flags are not unbindings")
	assert_eq(ids[0], &"WS_CARD_01")
	assert_eq(ids[ids.size() - 1], &"WS_CARD_21")


func test_branch_group_members_are_listed() -> void:
	var members := _full_catalog().branch_group_members(&"MQ01_TROUPE")
	assert_eq(members.size(), 2)
	assert_has(members, &"WS_TROUPE_SETTLED")


func test_a_duplicate_id_is_a_catalog_error() -> void:
	var catalog := _full_catalog()
	catalog.entries.append(_unbinding(&"WS_CARD_01", 1))
	assert_has(str(catalog.validate()), "more than once")


func test_a_missing_card_number_is_a_catalog_error() -> void:
	var catalog := _full_catalog()
	catalog.entries.remove_at(0)
	assert_has(str(catalog.validate()), "no unbinding flag carries card number 1")


func test_two_flags_claiming_one_card_is_a_catalog_error() -> void:
	var catalog := _full_catalog()
	catalog.entries.append(_unbinding(&"WS_OTHER_MAGICIAN", 1))
	assert_has(str(catalog.validate()), "is claimed by")


func test_a_branch_group_of_one_is_a_catalog_error() -> void:
	# A choice with a single option is not a choice; the matrix never writes one.
	var catalog := _full_catalog()
	catalog.entries.append(_branch(&"WS_LONELY_BRANCH", &"MQ06_DIVIDE"))
	assert_has(str(catalog.validate()), "has only one member")


func test_an_empty_catalog_entry_is_a_catalog_error() -> void:
	var catalog := _full_catalog()
	catalog.entries.append(null)
	assert_has(str(catalog.validate()), "is empty")


func test_a_catalog_reports_its_entries_own_problems() -> void:
	var catalog := _full_catalog()
	catalog.entries[0].fired_by = &""
	assert_has(str(catalog.validate()), "names no firing quest")


# --- ActThresholds -----------------------------------------------------------


func _thresholds(second: int, third: int) -> ActThresholds:
	var thresholds := ActThresholds.new()
	thresholds.id = &"ACT_THRESHOLDS"
	thresholds.act_ii_min = second
	thresholds.act_iii_min = third
	return thresholds


func test_the_documented_thresholds_are_valid() -> void:
	assert_eq(_thresholds(7, 15).validate(), PackedStringArray())


func test_thresholds_that_skip_act_one_are_invalid() -> void:
	assert_has(str(_thresholds(0, 15).validate()), "Act I never happens")


func test_thresholds_out_of_order_are_invalid() -> void:
	assert_has(str(_thresholds(15, 7).validate()), "not after Act II")


func test_thresholds_past_the_last_card_are_invalid() -> void:
	assert_has(str(_thresholds(7, 22).validate()), "past the last card")


# --- RenownLadder ------------------------------------------------------------


func _ladder() -> RenownLadder:
	var ladder := RenownLadder.new()
	ladder.id = &"RENOWN_LADDER"
	ladder.tier_names = PackedStringArray(["Stranger", "Known", "Welcome", "Honored", "Fabled"])
	ladder.tier_min_values = PackedInt32Array([0, 10, 25, 50, 100])
	return ladder


func test_the_documented_ladder_is_valid() -> void:
	assert_eq(_ladder().validate(), PackedStringArray())


func test_tier_for_lands_on_the_right_rung_at_every_edge() -> void:
	var ladder := _ladder()
	assert_eq(ladder.tier_for(0), 1, "a stranger everywhere at zero")
	assert_eq(ladder.tier_for(9), 1)
	assert_eq(ladder.tier_for(10), 2, "the rung changes at the threshold, not after it")
	assert_eq(ladder.tier_for(24), 2)
	assert_eq(ladder.tier_for(25), 3)
	assert_eq(ladder.tier_for(49), 3)
	assert_eq(ladder.tier_for(50), 4)
	assert_eq(ladder.tier_for(99), 4)
	assert_eq(ladder.tier_for(100), 5)
	assert_eq(ladder.tier_for(100000), 5, "the top rung has no ceiling")


func test_tier_name_keys_are_keys_not_words() -> void:
	var ladder := _ladder()
	assert_eq(ladder.tier_name_key(1), &"RENOWN_TIER_STRANGER")
	assert_eq(ladder.tier_name_key(5), &"RENOWN_TIER_FABLED")
	assert_eq(ladder.tier_name_key(0), &"", "an off-ladder tier is not guessed at")
	assert_eq(ladder.tier_name_key(6), &"")


func test_a_ladder_of_the_wrong_height_is_invalid() -> void:
	var ladder := _ladder()
	ladder.tier_names = PackedStringArray(["Stranger", "Known"])
	assert_has(str(ladder.validate()), "tier names, not 5")


func test_a_ladder_that_does_not_start_at_zero_is_invalid() -> void:
	var ladder := _ladder()
	ladder.tier_min_values = PackedInt32Array([1, 10, 25, 50, 100])
	assert_has(str(ladder.validate()), "not 0")


func test_a_ladder_that_does_not_climb_is_invalid() -> void:
	var ladder := _ladder()
	ladder.tier_min_values = PackedInt32Array([0, 10, 10, 50, 100])
	assert_has(str(ladder.validate()), "not above tier")


func test_a_nameless_tier_is_invalid() -> void:
	var ladder := _ladder()
	ladder.tier_names = PackedStringArray(["Stranger", "Known", "  ", "Honored", "Fabled"])
	assert_has(str(ladder.validate()), "has no name")


# --- Suit --------------------------------------------------------------------


func test_every_suit_has_a_key_and_round_trips() -> void:
	assert_eq(Suit.ALL.size(), 4, "Cups, Swords, Wands, Coins")
	for suit: Suit.Id in Suit.ALL:
		var key := Suit.name_key(suit)
		assert_ne(key, &"", "suit %d has a key" % suit)
		assert_eq(Suit.from_name_key(key), suit, "the key names the suit it came from")


func test_an_unknown_suit_key_is_reported_not_guessed() -> void:
	assert_eq(Suit.from_name_key(&"PENTACLES"), Suit.UNKNOWN)
	var beyond: Suit.Id = Suit.ALL.size() + 5
	assert_eq(Suit.name_key(beyond), &"", "an out-of-range suit is not guessed at")
