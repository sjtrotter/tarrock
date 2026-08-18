extends TarrockTest

## The Pocket Spread screen: three real cards, the pacing drawn as data, and every
## refusal shown rather than hidden.
##
## `docs/design/progression.md` §The Pocket Spread and §Slot unlock pacing are the
## canon; `docs/design/art-audio.md` §UI/UX pillars insists the slots are "an actual
## three-card spread, not an ability-bar reskin", which is why a locked slot is a card
## lying FACE-DOWN with the rule that opens it lettered under it.
##
## Built over the real generated Trumps, because the pacing being drawn is the real
## pacing: TRUMP_01 arrives with `WS_MAGICIAN_UNBOUND` and no slot opens before it.

const SPREAD_SCENE := "res://scenes/ui/pocket_spread_screen.tscn"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"

## Who fired the flags this suite grants. A test, honestly labelled.
const GRANTED_BY := &"tests/unit/ui/pocket_spread_screen_test.gd"

var _screen: PocketSpreadScreen = null
var _world_state: WorldStateService = null
var _spread: PocketSpreadService = null
var _trumps: TrumpCatalog = null


func before_each() -> void:
	TranslationServer.set_locale("en")
	var rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_trumps = load(TRUMP_CATALOG_PATH) as TrumpCatalog
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_spread = PocketSpreadService.new(
		_world_state, _trumps, rules, FortuneService.new(rules)
	)
	_screen = (load(SPREAD_SCENE) as PackedScene).instantiate() as PocketSpreadScreen
	tree().root.add_child(_screen)


func after_each() -> void:
	if _screen != null and is_instance_valid(_screen):
		_screen.get_parent().remove_child(_screen)
		_screen.free()
	_screen = null


func test_a_screen_with_no_spread_draws_three_face_down_cards() -> void:
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		assert_not_null(_screen.slot_card(slot))
		assert_false(_screen.slot_card(slot).is_face_up())
	assert_eq(_screen.hand_count(), 0)
	assert_false(_screen.loadouts_visible())


func test_a_locked_slot_lies_face_down_with_the_rule_that_opens_it() -> void:
	_screen.attach(_spread)
	assert_eq(_screen.slot_rule_key(SpreadSlot.Id.PRESENT), &"UI_SLOT_UNLOCK_PRESENT")
	assert_eq(_screen.slot_rule_key(SpreadSlot.Id.PAST), &"UI_SLOT_UNLOCK_PAST")
	assert_eq(_screen.slot_rule_key(SpreadSlot.Id.FUTURE), &"UI_SLOT_UNLOCK_FUTURE")
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		assert_false(_screen.slot_card(slot).is_face_up(), "%d is still face-down" % slot)


func test_the_first_trump_opens_the_present_slot_and_the_rule_comes_off_it() -> void:
	_screen.attach(_spread)
	_grant(1)
	assert_eq(_screen.hand_count(), 1, "the card is in the hand below the spread")
	assert_eq(_screen.slot_rule_key(SpreadSlot.Id.PRESENT), &"", "the Present slot has opened")
	assert_true(_screen.slot_card(SpreadSlot.Id.PRESENT).is_face_up())
	assert_eq(_screen.slot_card(SpreadSlot.Id.PRESENT).name_key(), UiKeys.SLOT_EMPTY)
	assert_ne(_screen.slot_rule_key(SpreadSlot.Id.PAST), &"", "three are still needed for Past")


func test_laying_a_card_puts_its_name_and_number_on_the_slot() -> void:
	_screen.attach(_spread)
	_grant(1)
	_screen.select(TrumpIds.TRUMP_01)
	assert_eq(_screen.selected_trump_id(), TrumpIds.TRUMP_01)
	assert_true(_screen.assign(SpreadSlot.Id.PRESENT))
	var card := _screen.slot_card(SpreadSlot.Id.PRESENT)
	assert_eq(card.name_key(), _trumps.find(TrumpIds.TRUMP_01).name_key)
	assert_eq(card.number(), 1)
	assert_false(card.is_reversed())


func test_turning_a_card_over_keeps_the_card_and_changes_only_which_way_it_lies() -> void:
	_screen.attach(_spread)
	_grant(1)
	_screen.select(TrumpIds.TRUMP_01)
	_screen.assign(SpreadSlot.Id.PRESENT)
	assert_true(_screen.flip(SpreadSlot.Id.PRESENT))
	assert_true(_screen.slot_card(SpreadSlot.Id.PRESENT).is_reversed())
	assert_eq(_spread.slotted_trump_id(SpreadSlot.Id.PRESENT), TrumpIds.TRUMP_01)
	assert_eq(_spread.slotted_orientation(SpreadSlot.Id.PRESENT), CardOrientation.Id.REVERSED)
	assert_true(_screen.flip(SpreadSlot.Id.PRESENT))
	assert_false(_screen.slot_card(SpreadSlot.Id.PRESENT).is_reversed())


func test_taking_a_card_back_empties_the_slot() -> void:
	_screen.attach(_spread)
	_grant(1)
	_screen.select(TrumpIds.TRUMP_01)
	_screen.assign(SpreadSlot.Id.PRESENT)
	assert_true(_screen.clear(SpreadSlot.Id.PRESENT))
	assert_eq(_screen.slot_card(SpreadSlot.Id.PRESENT).name_key(), UiKeys.SLOT_EMPTY)


func test_a_refusal_is_shown_on_a_chip_in_the_services_own_words() -> void:
	_screen.attach(_spread)
	_grant(1)
	_screen.select(TrumpIds.TRUMP_01)
	# `progression.md`: swapping is allowed "anywhere, out of combat".
	_spread.set_in_combat(true)
	assert_false(_screen.assign(SpreadSlot.Id.PRESENT))
	assert_eq(_screen.last_refusal_key(), &"UI_REFUSED_IN_COMBAT")
	assert_true(_screen.refusal_chip().is_showing())
	assert_ne(
		_screen.refusal_chip().prompt_text(),
		String(_screen.last_refusal_key()),
		"the refusal has a CSV row, so the player reads words and not a key"
	)


func test_a_locked_slot_refuses_and_says_so() -> void:
	_screen.attach(_spread)
	_grant(1)
	_screen.select(TrumpIds.TRUMP_01)
	assert_false(_screen.assign(SpreadSlot.Id.PAST))
	assert_eq(_screen.last_refusal_key(), &"UI_REFUSED_SLOT_LOCKED")


func test_the_loadouts_panel_appears_only_at_a_waystation() -> void:
	_screen.attach(_spread)
	assert_false(_screen.loadouts_visible(), "progression.md: loadouts are Waystation work")
	_spread.set_at_waystation(true)
	_screen.refresh()
	assert_true(_screen.loadouts_visible())
	_spread.set_at_waystation(false)
	_screen.refresh()
	assert_false(_screen.loadouts_visible())


func test_a_saved_loadout_gets_a_row() -> void:
	_screen.attach(_spread)
	_grant(1)
	_spread.set_at_waystation(true)
	_screen.refresh()
	assert_eq(_screen.loadout_count(), 0)
	assert_true(_spread.save_loadout("") >= 0)
	assert_eq(_screen.loadout_count(), 1)


func test_no_trump_effect_text_is_invented() -> void:
	# `arcana.md` owns what a Trump does and has authored no player-facing words for
	# it, so the screen letters a placeholder key rather than a guess.
	_screen.attach(_spread)
	_grant(1)
	assert_eq(UiKeys.TRUMP_TEXT_PENDING, &"UI_TRUMP_TEXT_PENDING")
	assert_eq(TranslationServer.translate(UiKeys.TRUMP_TEXT_PENDING), "—")


## Hand the Fool the first `count` Trumps by firing the flags that grant them, which is
## the only way a Trump is ever held (`PocketSpreadService`: holding is DERIVED).
func _grant(count: int) -> void:
	var granted := 0
	for definition: TrumpDefinition in _trumps.entries:
		if granted >= count:
			return
		if definition == null or definition.granted_by_flag == &"":
			continue
		_world_state.fire(definition.granted_by_flag, GRANTED_BY)
		granted += 1
