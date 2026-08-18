extends TarrockTest

## `EconomyService`: the purse, the shops that read the world, the staff head on the
## Bindle, the graftings, and the one place a deed becomes Renown.
##
## The service is a plain `RefCounted`, so these are built directly. **The world-state
## flags, the Trumps, the regions and the deeds are the REAL ones** - no magic strings
## anywhere - but the items and the shops are built in the test, because a suite that
## priced the authored Prestige stall would go red every time a designer changed a
## price. The authored data has its own suite: `economy_data_test.gd`.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const DEED_CATALOG_PATH := "res://data/progression/deeds/catalog.tres"

## The two synthetic shops: one in the Prestige, one in the Noonlands. Two, because
## "Spread-wide" is only provable in more than one place.
const SHOP_A := &"SHOP_TEST_A"
const SHOP_B := &"SHOP_TEST_B"

## The synthetic goods. Ids that no authored item uses, so a test can never pass by
## accidentally reading the real catalog.
const FOOD := &"ITEM_TEST_FOOD"
const CURIO := &"ITEM_TEST_CURIO"
const HEAD := &"ITEM_TEST_HEAD"
const HIDDEN := &"ITEM_TEST_HIDDEN"
const FINE_PRINT := &"ITEM_TEST_FINE_PRINT"
const GATED := &"ITEM_TEST_GATED"

## A QUEST item, defined but deliberately on no shop's shelf: a quest item never
## appears on one at all (see `test_a_quest_item_is_never_bought`).
const QUEST_ITEM := &"ITEM_TEST_QUEST"

## A grafting source. Where a cutting was taken, not what it was.
const SOURCE_A := &"GRAFTING_TEST_SOURCE_A"
const SOURCE_B := &"GRAFTING_TEST_SOURCE_B"

const BASE_FOOD_PRICE := 100
const BASE_CURIO_PRICE := 40
const BASE_HEAD_PRICE := 60

var _world_state: WorldStateService = null
var _spread: PocketSpreadService = null
var _rose: WhiteRoseService = null
var _rules: EconomyRules = null
var _items: ItemCatalog = null
var _shops: ShopCatalog = null
var _service: EconomyService = null


func before_each() -> void:
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var spread_rules := load(SPREAD_RULES_PATH) as SpreadRules
	_spread = PocketSpreadService.new(
		_world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, spread_rules, null
	)
	_rose = WhiteRoseService.new(_world_state, spread_rules)
	_rules = _test_rules()
	_items = _test_items()
	_shops = _test_shops()
	_service = _build()


func _build() -> EconomyService:
	return EconomyService.new(
		_rules, _items, _shops, load(DEED_CATALOG_PATH) as DeedCatalog,
		_world_state, _spread, _rose
	)


# --- Coins --------------------------------------------------------------------


func test_the_purse_starts_where_the_rules_say() -> void:
	assert_eq(_service.coins(), _rules.starting_coins)
	assert_true(_service.is_pristine(), "building a service is not playing in it")


func test_coins_go_in_and_come_out_with_a_reason() -> void:
	watch_signal(_service, &"coins_changed")
	_service.add_coins(50, SHOP_A)
	assert_eq(_service.coins(), 50)
	assert_eq(signal_arguments(_service, &"coins_changed", 0), [0, 50, SHOP_A])
	assert_true(_service.spend_coins(20, SHOP_A))
	assert_eq(_service.coins(), 30)
	assert_false(_service.is_pristine())


func test_a_purse_cannot_be_overdrawn() -> void:
	_service.add_coins(10)
	assert_false(_service.spend_coins(11), "there is no credit in the Spread")
	assert_eq(_service.coins(), 10, "and a refused spend changes nothing")


func test_a_gift_of_nothing_is_nothing() -> void:
	watch_signal(_service, &"coins_changed")
	_service.add_coins(0)
	_service.add_coins(-5)
	assert_eq(_service.coins(), _rules.starting_coins)
	assert_signal_emitted(_service, &"coins_changed", 0)
	assert_true(_service.is_pristine(), "and it is not even a mutation")


# --- What the Fool carries -----------------------------------------------------


func test_items_go_in_and_out_of_the_bindle() -> void:
	watch_signal(_service, &"item_added")
	watch_signal(_service, &"item_removed")
	assert_true(_service.add_item(FOOD, 3))
	assert_eq(_service.count(FOOD), 3)
	assert_true(_service.remove_item(FOOD, 2))
	assert_eq(_service.count(FOOD), 1)
	assert_signal_emitted(_service, &"item_added", 1)
	assert_signal_emitted(_service, &"item_removed", 1)


func test_the_bindle_holds_nothing_it_cannot_name() -> void:
	assert_false(_service.add_item(&"ITEM_NOT_A_REAL_ITEM"), "an id is a definition or it is nothing")
	assert_eq(_service.count(&"ITEM_NOT_A_REAL_ITEM"), 0)


func test_what_is_not_carried_cannot_be_removed() -> void:
	_service.add_item(FOOD, 1)
	assert_false(_service.remove_item(FOOD, 2))
	assert_eq(_service.count(FOOD), 1)


# --- Prices ---------------------------------------------------------------------


func test_a_price_starts_at_the_item_s_own() -> void:
	assert_eq(_service.price_of(SHOP_A, FOOD), BASE_FOOD_PRICE)


func test_a_region_multiplier_prices_a_town() -> void:
	# progression.md: "prices vary by region". SHOP_B charges a fifth more.
	assert_eq(_service.price_of(SHOP_B, CURIO), int(roundf(BASE_CURIO_PRICE * 1.2)))


func test_the_empress_halves_food_spread_wide() -> void:
	# The canon rule, and the whole reason PriceRule is data: progression.md
	# §Currency, shops, and gear-lite - "food prices halve Spread-wide on
	# WS_EMPRESS_UNBOUND - shop pricing simply reads that state".
	assert_eq(_service.price_of(SHOP_A, FOOD), BASE_FOOD_PRICE, "not before she is unbound")
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	assert_eq(_service.price_of(SHOP_A, FOOD), BASE_FOOD_PRICE / 2, "halved here")
	assert_eq(
		_service.price_of(SHOP_B, FOOD),
		int(roundf(BASE_FOOD_PRICE * 1.2 * 0.5)),
		"and halved in the other town too - Spread-wide"
	)


func test_the_empress_prices_food_and_nothing_else() -> void:
	var before := _service.price_of(SHOP_A, CURIO)
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	assert_eq(_service.price_of(SHOP_A, CURIO), before, "a curio is not food")


func test_renown_prices_the_local_suit_only() -> void:
	# "further affected by the Fool's Renown with the LOCAL suit". SHOP_A is a Wands
	# town; standing with Swords buys nothing there.
	var full := _service.price_of(SHOP_A, CURIO)
	_world_state.adjust_renown(Suit.Id.SWORDS, 100, QuestIds.MQ01)
	assert_eq(_service.price_of(SHOP_A, CURIO), full, "a Swords name is nothing to Wands")
	_world_state.adjust_renown(Suit.Id.WANDS, 100, QuestIds.MQ01)
	assert_true(_service.price_of(SHOP_A, CURIO) < full, "but standing here is worth something")
	assert_eq(
		_service.price_of(SHOP_A, CURIO),
		int(roundf(BASE_CURIO_PRICE * _rules.renown_multiplier_for_tier(RenownLadder.TIER_COUNT))),
		"priced at the Fabled rung"
	)


func test_a_price_never_falls_below_one_coin() -> void:
	# A shop that gave something away would be a price the matrix cannot explain.
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	_world_state.adjust_renown(Suit.Id.WANDS, 100, QuestIds.MQ01)
	assert_eq(_service.price_of(SHOP_A, GATED), 1, "a one-coin trifle is still a coin")


func test_an_unknown_shop_or_item_has_no_price_at_all() -> void:
	assert_eq(_service.price_of(&"SHOP_NOWHERE", FOOD), EconomyService.NO_PRICE)
	assert_eq(_service.price_of(SHOP_A, &"ITEM_NOWHERE"), EconomyService.NO_PRICE)


# --- Stock ----------------------------------------------------------------------


func test_the_shelf_shows_what_the_fool_can_see() -> void:
	var ids: Array[StringName] = []
	for offer: ShopOffer in _service.stock_of(SHOP_A):
		ids.append(offer.item_id)
	assert_has(ids, FOOD)
	assert_has(ids, CURIO)
	assert_has(ids, HEAD)
	assert_false(ids.has(HIDDEN), "hidden stock is not on the shelf yet")
	assert_false(ids.has(FINE_PRINT), "nor is the fine print")
	assert_false(ids.has(GATED), "nor is stock waiting on a flag")


func test_manifest_shows_the_vendor_s_hidden_stock() -> void:
	# arcana.md Trump I, Past: "vendors show their hidden stock". The Trump is HELD
	# because the Magician is unbound - holding is derived from the flag, never stored.
	assert_false(_spread.is_held(TrumpIds.TRUMP_01))
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	assert_true(_spread.is_held(TrumpIds.TRUMP_01))
	var ids: Array[StringName] = []
	for offer: ShopOffer in _service.stock_of(SHOP_A):
		ids.append(offer.item_id)
	assert_has(ids, HIDDEN, "the hidden line is on the shelf now")


func test_bargain_makes_the_fine_print_legible_and_flagged() -> void:
	# arcana.md Trump XV, Past: "Fine-print stock at every shop: potent goods with
	# their costs printed honestly."
	_world_state.fire(WorldStateIds.WS_DEVIL_UNBOUND, QuestIds.MQ15)
	assert_true(_spread.is_held(TrumpIds.TRUMP_15))
	var flagged := 0
	for offer: ShopOffer in _service.stock_of(SHOP_A):
		if offer.item_id == FINE_PRINT:
			assert_true(offer.fine_print, "the offer says what kind of stock it is")
			flagged += 1
	assert_eq(flagged, 1, "the fine-print line is on the shelf and marked")


func test_a_line_waiting_on_a_flag_appears_when_it_fires() -> void:
	assert_eq(_service.stock_remaining(SHOP_A, GATED), 0)
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	assert_eq(_service.stock_remaining(SHOP_A, GATED), 2)


# --- Buying and selling ---------------------------------------------------------


func test_buying_takes_the_coins_and_the_stock() -> void:
	_service.add_coins(500)
	watch_signal(_service, &"purchase_made")
	assert_true(_service.buy(SHOP_A, FOOD))
	assert_eq(_service.count(FOOD), 1)
	assert_eq(_service.coins(), 500 - BASE_FOOD_PRICE)
	assert_eq(_service.stock_remaining(SHOP_A, FOOD), 2, "three on the shelf, one sold")
	assert_eq(signal_arguments(_service, &"purchase_made", 0), [SHOP_A, FOOD, BASE_FOOD_PRICE])


func test_an_empty_purse_buys_nothing() -> void:
	watch_signal(_service, &"purchase_refused")
	assert_false(_service.buy(SHOP_A, FOOD))
	assert_eq(_service.count(FOOD), 0)
	assert_eq(
		signal_arguments(_service, &"purchase_refused", 0),
		[SHOP_A, FOOD, EconomyService.REASON_CANNOT_AFFORD]
	)


func test_an_empty_shelf_sells_nothing() -> void:
	_service.add_coins(5000)
	watch_signal(_service, &"purchase_refused")
	assert_true(_service.buy(SHOP_A, HEAD), "there is exactly one head")
	assert_false(_service.buy(SHOP_A, HEAD), "and now there is none")
	assert_eq(
		signal_arguments(_service, &"purchase_refused", 0),
		[SHOP_A, HEAD, EconomyService.REASON_OUT_OF_STOCK]
	)


func test_stock_the_fool_cannot_see_cannot_be_bought() -> void:
	# Deliberately the same refusal as "not stocked at all": a shop that refused
	# differently would tell the Fool what is behind the counter.
	_service.add_coins(5000)
	watch_signal(_service, &"purchase_refused")
	assert_false(_service.buy(SHOP_A, HIDDEN))
	assert_eq(
		signal_arguments(_service, &"purchase_refused", 0),
		[SHOP_A, HIDDEN, EconomyService.REASON_NOT_STOCKED]
	)


func test_a_quest_item_is_never_bought() -> void:
	# LEAD RULING: shops do not buy back, and they do not stock or sell a QUEST item
	# either - progression.md: Coins are found, looted, earned through quests, and
	# spent. QUEST is not on either shelf built for this suite, so the refusal is
	# proven directly against the catalog rather than a stocked line.
	_service.add_coins(5000)
	watch_signal(_service, &"purchase_refused")
	assert_false(_service.buy(SHOP_A, QUEST_ITEM))
	assert_eq(_service.count(QUEST_ITEM), 0)
	assert_eq(
		signal_arguments(_service, &"purchase_refused", 0),
		[SHOP_A, QUEST_ITEM, EconomyService.REASON_NOT_FOR_SALE]
	)


func test_a_rest_restocks_the_shelves_that_restock() -> void:
	# progression.md §Waystations: rest is the world's own tick.
	_service.add_coins(5000)
	_service.buy(SHOP_A, FOOD)
	_service.buy(SHOP_A, HEAD)
	assert_eq(_service.stock_remaining(SHOP_A, FOOD), 2)
	assert_eq(_service.stock_remaining(SHOP_A, HEAD), 0)
	_service.restock_on_rest()
	assert_eq(_service.stock_remaining(SHOP_A, FOOD), 3, "the food is back")
	assert_eq(
		_service.stock_remaining(SHOP_A, HEAD),
		0,
		"the staff head is not: 8-10 exist in the whole Spread"
	)


# --- Staff heads ----------------------------------------------------------------


func test_only_a_staff_head_the_fool_owns_goes_on_the_bindle() -> void:
	watch_signal(_service, &"staff_head_changed")
	assert_false(_service.equip_staff_head(HEAD), "the Fool is not carrying one")
	_service.add_item(HEAD, 1)
	assert_true(_service.equip_staff_head(HEAD))
	assert_eq(_service.equipped_staff_head(), HEAD)
	assert_eq(_service.equipped_moveset_twist(), ItemIds.TWIST_REACH_PLUS)
	assert_false(_service.equip_staff_head(HEAD), "and it is already on")
	assert_signal_emitted(_service, &"staff_head_changed", 1)


func test_only_a_staff_head_goes_on_the_bindle_at_all() -> void:
	_service.add_item(CURIO, 1)
	assert_false(_service.equip_staff_head(CURIO))
	assert_eq(_service.equipped_staff_head(), EconomyService.UNSET)


func test_a_head_that_leaves_the_bindle_comes_off_it() -> void:
	_service.add_item(HEAD, 1)
	_service.equip_staff_head(HEAD)
	watch_signal(_service, &"staff_head_changed")
	assert_true(_service.remove_item(HEAD, 1))
	assert_eq(_service.equipped_staff_head(), EconomyService.UNSET)
	assert_signal_emitted(_service, &"staff_head_changed", 1)


# --- Rose graftings --------------------------------------------------------------


func test_a_grafting_raises_the_rose_and_is_taken_only_once() -> void:
	watch_signal(_service, &"grafting_found")
	var before := _rose.max_petals()
	assert_true(_service.find_grafting(SOURCE_A))
	assert_eq(_rose.max_petals(), before + 1, "the Rose's cap is the Rose's to raise")
	assert_true(_service.has_grafting(SOURCE_A))
	assert_false(_service.find_grafting(SOURCE_A), "a cutting is taken once")
	assert_eq(_rose.max_petals(), before + 1)
	assert_signal_emitted(_service, &"grafting_found", 1)


func test_two_sources_are_two_graftings() -> void:
	var before := _rose.max_petals()
	assert_true(_service.find_grafting(SOURCE_A))
	assert_true(_service.find_grafting(SOURCE_B))
	assert_eq(_rose.max_petals(), before + 2)
	assert_eq(_service.graftings_found().size(), 2)


func test_a_grafting_the_rose_cannot_take_is_not_spent() -> void:
	# The Rose caps at 8 petals (progression.md §The White Rose) and owns the cap.
	# A source refused there stays findable rather than being silently used up.
	var room := _rose.graftings_remaining()
	for index: int in room:
		assert_true(_service.find_grafting(StringName("GRAFTING_TEST_FILLER_%d" % index)))
	assert_eq(_rose.graftings_remaining(), 0)
	assert_false(_service.find_grafting(SOURCE_A))
	assert_false(_service.has_grafting(SOURCE_A), "the bush still has its cutting")


# --- Deeds become Renown ----------------------------------------------------------


func test_a_deed_moves_every_suit_by_its_own_reaction() -> void:
	# progression.md §Renown, row 1: Cups up, Swords neutral, Wands slight up, Coins
	# slight down. Four opinions, no sum.
	watch_signal(_world_state, &"renown_changed")
	watch_signal(_service, &"deed_recorded")
	assert_true(_service.record_deed(DeedIds.DEED_HELP_A_STRANGER))
	assert_eq(_world_state.renown(Suit.Id.CUPS), _rules.renown_delta_for(Reaction.Id.UP))
	assert_eq(_world_state.renown(Suit.Id.SWORDS), 0)
	assert_eq(_world_state.renown(Suit.Id.WANDS), _rules.renown_delta_for(Reaction.Id.SLIGHT_UP))
	assert_eq(_world_state.renown(Suit.Id.COINS), 0, "Renown floors at zero, so the slight down is absorbed")
	# Two movements, not four: the NEUTRAL suit is never touched at all (a zero
	# adjustment would tell a listener an indifferent culture had an opinion), and
	# Coins' slight down is already at the floor, which `WorldStateService` itself
	# reports as no movement.
	assert_signal_emitted(_world_state, &"renown_changed", 2)
	assert_signal_emitted(_service, &"deed_recorded", 1)


func test_a_deed_costs_standing_where_the_culture_dislikes_it() -> void:
	# The floor is what hides a slight-down at zero, so this starts from some standing.
	_world_state.adjust_renown(Suit.Id.CUPS, 20, QuestIds.MQ01)
	_service.record_deed(DeedIds.DEED_SHARP_BARGAIN)
	assert_eq(
		_world_state.renown(Suit.Id.CUPS),
		20 + _rules.renown_delta_for(Reaction.Id.SLIGHT_DOWN),
		"Cups finds a sharp bargain cold"
	)
	assert_eq(
		_world_state.renown(Suit.Id.COINS),
		_rules.renown_delta_for(Reaction.Id.UP),
		"and Coins prizes the shrewdness"
	)


func test_each_culture_prizes_its_own_kind_of_deed() -> void:
	# Row 2 (a formal duel) is Swords', row 4 (a finished craft) is Wands'. Two rows,
	# two different cultures raised, from the same table and the same call.
	_service.record_deed(DeedIds.DEED_WIN_A_DUEL)
	assert_eq(_world_state.renown(Suit.Id.SWORDS), _rules.renown_delta_for(Reaction.Id.UP))
	_service.record_deed(DeedIds.DEED_FINISH_A_CRAFT)
	assert_eq(_world_state.renown(Suit.Id.WANDS), (
		_rules.renown_delta_for(Reaction.Id.SLIGHT_UP) + _rules.renown_delta_for(Reaction.Id.UP)
	), "the duel was a spectacle to Wands and the craft is their own culture")


func test_a_deed_nobody_wrote_down_is_not_a_deed() -> void:
	watch_signal(_service, &"deed_recorded")
	assert_false(_service.record_deed(&"DEED_NOT_A_REAL_DEED"))
	assert_signal_emitted(_service, &"deed_recorded", 0)
	assert_eq(_world_state.renown(Suit.Id.CUPS), 0)


# --- Snapshot and restore ---------------------------------------------------------


func test_a_snapshot_round_trips_through_a_fresh_service() -> void:
	_service.add_coins(120)
	_service.add_item(FOOD, 2)
	_service.add_item(HEAD, 1)
	_service.equip_staff_head(HEAD)
	_service.find_grafting(SOURCE_A)
	var snapshot := _service.to_snapshot()

	# A load lands in a service nobody has played in - the composition root rebuilds
	# every service for a load, so this is what `SaveService.apply()` will be handed.
	var restored := _build()
	assert_true(restored.is_pristine())
	assert_eq(restored.restore_snapshot(snapshot), PackedStringArray())
	assert_eq(restored.coins(), 120)
	assert_eq(restored.count(FOOD), 2)
	assert_eq(restored.equipped_staff_head(), HEAD)
	assert_true(restored.has_grafting(SOURCE_A))
	assert_false(restored.is_pristine())


func test_a_snapshot_is_refused_by_a_service_in_play() -> void:
	_service.add_coins(10)
	var problems := _service.restore_snapshot({})
	assert_true(problems.size() > 0, "a load is not a reset")
	assert_eq(_service.coins(), 10, "and a refused load changes nothing")


func test_a_snapshot_naming_an_item_this_build_lacks_applies_nothing() -> void:
	var restored := _build()
	var problems := restored.restore_snapshot({
		EconomyService.SNAPSHOT_COINS: 5,
		EconomyService.SNAPSHOT_ITEMS: {"ITEM_NOT_A_REAL_ITEM": 1},
	})
	assert_true(problems.size() > 0)
	assert_eq(restored.coins(), _rules.starting_coins, "all-or-nothing, like the others")
	assert_true(restored.is_pristine())


func test_a_snapshot_cannot_fit_a_head_the_fool_is_not_carrying() -> void:
	var restored := _build()
	var problems := restored.restore_snapshot({
		EconomyService.SNAPSHOT_COINS: 0,
		EconomyService.SNAPSHOT_ITEMS: {},
		EconomyService.SNAPSHOT_STAFF_HEAD: String(HEAD),
	})
	assert_true(problems.size() > 0, "a save that disagrees with itself is not loaded")


func test_a_snapshot_cannot_fit_something_that_is_not_a_head() -> void:
	var restored := _build()
	var problems := restored.restore_snapshot({
		EconomyService.SNAPSHOT_COINS: 0,
		EconomyService.SNAPSHOT_ITEMS: {String(CURIO): 1},
		EconomyService.SNAPSHOT_STAFF_HEAD: String(CURIO),
	})
	assert_true(problems.size() > 0)


func test_a_snapshot_carries_no_object_and_no_path() -> void:
	_service.add_coins(3)
	_service.add_item(FOOD, 1)
	var text := JSON.stringify(_service.to_snapshot())
	assert_false(text.contains("res://"), "ids only, never a resource path")
	assert_false(text.contains("Object("), "and never an object")


# --- The test's own economy ------------------------------------------------------


## A tuning table with round numbers, so a price can be asserted rather than
## approximated. The one rule that is not the test's own invention is the canon
## Empress rule, which is authored here exactly as `economy_rules.tres` authors it.
func _test_rules() -> EconomyRules:
	var rules := EconomyRules.new()
	rules.id = &"ECONOMY_RULES_TEST"
	rules.starting_coins = 0
	rules.renown_price_multipliers = PackedFloat32Array([1.0, 0.95, 0.9, 0.85, 0.5])
	rules.default_region_price_multiplier = 1.0
	rules.renown_delta_up = 8
	rules.renown_delta_slight_up = 3
	rules.renown_delta_slight_down = -3
	rules.renown_delta_down = -8
	rules.max_staff_heads_hint = 10
	rules.settled_region_ids = [RegionIds.PRESTIGE, RegionIds.NOONLANDS]
	var food_rule := PriceRule.new()
	food_rule.when_fired = WorldStateIds.WS_EMPRESS_UNBOUND
	food_rule.category = ItemCategory.Id.FOOD
	food_rule.multiplier = 0.5
	rules.price_rules = [food_rule]
	return rules


func _test_items() -> ItemCatalog:
	var catalog := ItemCatalog.new()
	catalog.entries = [
		_item(FOOD, ItemCategory.Id.FOOD, BASE_FOOD_PRICE),
		_item(CURIO, ItemCategory.Id.CURIO, BASE_CURIO_PRICE),
		_staff_head(HEAD, BASE_HEAD_PRICE, ItemIds.TWIST_REACH_PLUS),
		_item(HIDDEN, ItemCategory.Id.CURIO, 30),
		_staff_head(FINE_PRINT, 90, ItemIds.TWIST_FIRE_TAG),
		_item(GATED, ItemCategory.Id.FOOD, 1),
		_item(QUEST_ITEM, ItemCategory.Id.QUEST, 0),
	]
	return catalog


func _item(item_id: StringName, category: ItemCategory.Id, price: int) -> ItemDefinition:
	var item := ItemDefinition.new()
	item.id = item_id
	item.name_key = StringName(String(item_id) + "_NAME")
	item.category = category
	item.base_price = price
	item.cosmetic_only = ItemCategory.is_cosmetic_only(category)
	return item


func _staff_head(item_id: StringName, price: int, twist: StringName) -> ItemDefinition:
	var item := _item(item_id, ItemCategory.Id.STAFF_HEAD, price)
	item.moveset_twist = twist
	return item


## Two shops: a Wands town at the economy's default multiplier, and a Coins town that
## charges a fifth more. Two, because "Spread-wide" needs somewhere else to be true.
func _test_shops() -> ShopCatalog:
	var catalog := ShopCatalog.new()
	var shop_a := ShopDefinition.new()
	shop_a.id = SHOP_A
	shop_a.region_id = RegionIds.PRESTIGE
	shop_a.suit = Suit.Id.WANDS
	shop_a.price_multiplier = 0.0
	shop_a.stock = [
		_line(FOOD, 3, true),
		_line(CURIO, 4, true),
		_line(HEAD, 1, false),
		_hidden_line(HIDDEN),
		_fine_print_line(FINE_PRINT),
		_gated_line(GATED),
	]
	var shop_b := ShopDefinition.new()
	shop_b.id = SHOP_B
	shop_b.region_id = RegionIds.NOONLANDS
	shop_b.suit = Suit.Id.COINS
	shop_b.price_multiplier = 1.2
	shop_b.stock = [_line(FOOD, 2, true), _line(CURIO, 2, true)]
	catalog.entries = [shop_a, shop_b]
	return catalog


func _line(item_id: StringName, count: int, restocks: bool) -> ShopStockEntry:
	var entry := ShopStockEntry.new()
	entry.item_id = item_id
	entry.count = count
	entry.restocks_on_rest = restocks
	return entry


func _hidden_line(item_id: StringName) -> ShopStockEntry:
	var entry := _line(item_id, 1, false)
	entry.hidden_until_manifest = true
	return entry


func _fine_print_line(item_id: StringName) -> ShopStockEntry:
	var entry := _line(item_id, 1, false)
	entry.fine_print = true
	return entry


func _gated_line(item_id: StringName) -> ShopStockEntry:
	var entry := _line(item_id, 2, true)
	entry.requires_fired = [WorldStateIds.WS_EMPRESS_UNBOUND]
	return entry


# --- The rest that restocks (the RegionService wiring) ---------------------------


func test_a_rest_at_a_waystation_restocks_the_shelves() -> void:
	# `progression.md` §Waystations makes rest the world's tick, so the shop listens
	# to `RegionService.rested` rather than to a clock. The service is built bare here
	# - what a real rest does to a real region is `region_service_test.gd`'s business;
	# what the shop does when it hears one is this test's.
	var regions := RegionService.new(null, null)
	_service.attach_regions(regions)
	assert_eq(_service.attached_regions(), regions)
	_service.add_coins(5000)
	_service.buy(SHOP_A, FOOD)
	assert_eq(_service.stock_remaining(SHOP_A, FOOD), 2)
	regions.rested.emit(&"WAYSTATION_TEST")
	assert_eq(_service.stock_remaining(SHOP_A, FOOD), 3)


func test_the_economy_does_not_keep_the_region_service_alive() -> void:
	# The one non-obvious wiring rule: `RegionService` holds the save, and the save
	# holds this service, so an ordinary field here would close a `RefCounted` cycle
	# that nothing collects - the engine reports it at exit as "resources still in
	# use" and `run_all.sh` fails the stage on the error line. The handle is weak, and
	# this is what says so.
	var regions := RegionService.new(null, null)
	_service.attach_regions(regions)
	assert_not_null(_service.attached_regions())
	regions = null
	assert_null(_service.attached_regions(), "the composition root owns it, not the shop")
