extends TarrockTest

## The authored economy: the tuning table, the items, the shops, and the one price
## rule `docs/design/progression.md` makes canon.
##
## The service's behaviour is `economy_service_test.gd`'s; this suite is about the
## data being loadable, self-consistent and consistent with the doc it cites - the
## same job `region_data_test.gd` does for the regions.

const ECONOMY_RULES_PATH := "res://data/progression/economy_rules.tres"
const ITEM_CATALOG_PATH := "res://data/progression/items/catalog.tres"
const SHOP_CATALOG_PATH := "res://data/progression/shops/catalog.tres"
const DEED_CATALOG_PATH := "res://data/progression/deeds/catalog.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const REGION_CATALOG_PATH := "res://data/regions/catalog.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

var _rules: EconomyRules = null
var _items: ItemCatalog = null
var _shops: ShopCatalog = null
var _world_states: WorldStateCatalog = null
var _regions: RegionCatalog = null
var _trumps: TrumpCatalog = null


func before_each() -> void:
	_rules = load(ECONOMY_RULES_PATH) as EconomyRules
	_items = load(ITEM_CATALOG_PATH) as ItemCatalog
	_shops = load(SHOP_CATALOG_PATH) as ShopCatalog
	_world_states = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	_regions = load(REGION_CATALOG_PATH) as RegionCatalog
	_trumps = load(TRUMP_CATALOG_PATH) as TrumpCatalog


# --- The catalogs load and validate ------------------------------------------


func test_the_economy_rules_load_and_validate() -> void:
	if not assert_not_null(_rules, "economy_rules.tres must load"):
		return
	assert_eq(
		_rules.validate_against(_world_states, _regions),
		PackedStringArray(),
		"the authored economy must be internally consistent"
	)


func test_the_item_catalog_loads_and_validates() -> void:
	if not assert_not_null(_items, "the item catalog must load"):
		return
	assert_true(_items.entries.size() > 0, "an economy with no items is not one")
	assert_eq(_items.validate(), PackedStringArray())


func test_the_shop_catalog_loads_and_validates() -> void:
	if not assert_not_null(_shops, "the shop catalog must load"):
		return
	assert_eq(
		_shops.validate_against(_items, _rules, _regions, _world_states, _trumps),
		PackedStringArray()
	)


func test_the_deed_catalog_loads_and_validates() -> void:
	var deeds: DeedCatalog = load(DEED_CATALOG_PATH) as DeedCatalog
	if not assert_not_null(deeds, "the generated deed catalog must load"):
		return
	assert_eq(deeds.validate(), PackedStringArray())


# --- The doc's own rules, in the authored data -------------------------------


func test_the_one_canon_price_rule_is_data() -> void:
	# progression.md §Currency, shops, and gear-lite: "food prices halve Spread-wide on
	# WS_EMPRESS_UNBOUND - shop pricing simply reads that state". If this ever becomes
	# a branch in EconomyService instead of a row here, this test is what says so.
	if not assert_not_null(_rules):
		return
	var found: Array[PriceRule] = []
	for rule: PriceRule in _rules.price_rules:
		if rule != null and rule.when_fired == WorldStateIds.WS_EMPRESS_UNBOUND:
			found.append(rule)
	if not assert_eq(found.size(), 1, "exactly one rule prices off the Empress"):
		return
	assert_eq(found[0].category, ItemCategory.Id.FOOD, "and it prices food")
	assert_almost_eq(found[0].multiplier, 0.5, 0.0001, "by halving it")
	assert_true(found[0].is_spread_wide(), "everywhere, as the doc says")


func test_the_fool_starts_with_an_empty_purse() -> void:
	# progression.md §Player growth over a playthrough, hour 1: the Bindle, three
	# petals, no Trump and no reputation - and nothing else.
	if not assert_not_null(_rules):
		return
	assert_eq(_rules.starting_coins, 0)


func test_renown_pays_off_at_every_rung_of_the_ladder() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(_rules.renown_price_multipliers.size(), RenownLadder.TIER_COUNT)
	var previous := 2.0
	for tier: int in range(RenownLadder.FIRST_TIER, RenownLadder.TIER_COUNT + 1):
		var multiplier := _rules.renown_multiplier_for_tier(tier)
		assert_true(multiplier < previous, "standing never costs the Fool more")
		previous = multiplier


func test_a_deed_reaction_is_worth_more_than_a_slight_one() -> void:
	# §Renown states no number at all, so the only thing that can be asserted is the
	# SHAPE: a full reaction outweighs a slight one, indifference is worth nothing,
	# and the ladder is symmetric about it.
	if not assert_not_null(_rules):
		return
	assert_true(_rules.renown_delta_for(Reaction.Id.UP) > _rules.renown_delta_for(Reaction.Id.SLIGHT_UP))
	assert_true(_rules.renown_delta_for(Reaction.Id.SLIGHT_UP) > 0)
	assert_eq(_rules.renown_delta_for(Reaction.Id.NEUTRAL), 0, "an indifferent suit does not move")
	assert_true(_rules.renown_delta_for(Reaction.Id.SLIGHT_DOWN) < 0)
	assert_true(_rules.renown_delta_for(Reaction.Id.DOWN) < _rules.renown_delta_for(Reaction.Id.SLIGHT_DOWN))


func test_the_staff_head_count_is_in_the_doc_s_range() -> void:
	# "roughly 8-10 exist across the Spread" - informational, so this checks the hint
	# rather than the authored set, which is three placeholders today.
	if not assert_not_null(_rules):
		return
	assert_true(_rules.max_staff_heads_hint >= 8 and _rules.max_staff_heads_hint <= 10)


func test_the_cliff_is_no_place_for_a_shop() -> void:
	# world.md §The Cliff is a plateau of long-dead campsites; progression.md puts
	# shops in SETTLED regions. Nobody settles the Cliff.
	if not assert_not_null(_rules):
		return
	assert_false(_rules.is_settled(RegionIds.CLIFF))
	if not assert_not_null(_shops):
		return
	assert_eq(_shops.in_region(RegionIds.CLIFF).size(), 0)


func test_the_prestige_has_the_proof_slice_s_shop() -> void:
	if not assert_not_null(_shops):
		return
	var shop := _shops.find(ShopIds.SHOP_PRESTIGE)
	if not assert_not_null(shop, "the Prestige's stall is the one authored shop"):
		return
	assert_eq(shop.region_id, RegionIds.PRESTIGE)
	assert_true(shop.stock.size() > 0)
	var categories: Dictionary = {}
	for entry: ShopStockEntry in shop.stock:
		var item := _items.find(entry.item_id)
		if item != null:
			categories[item.category] = true
	assert_true(categories.has(ItemCategory.Id.FOOD), "something to eat")
	assert_true(categories.has(ItemCategory.Id.CURIO), "something to keep")
	assert_true(categories.has(ItemCategory.Id.STAFF_HEAD), "and one staff head")


func test_the_shop_carries_both_trump_hooks() -> void:
	# arcana.md Trump I: "vendors show their hidden stock"; Trump XV: "Fine-print
	# stock at every shop". Both are stock conditions, so both are authored as data.
	if not assert_not_null(_shops):
		return
	var shop := _shops.find(ShopIds.SHOP_PRESTIGE)
	if not assert_not_null(shop):
		return
	var hidden := 0
	var fine_print := 0
	for entry: ShopStockEntry in shop.stock:
		if entry.hidden_until_manifest:
			hidden += 1
			assert_has(entry.trumps_required(), TrumpIds.TRUMP_01, "hidden stock waits on Manifest")
		if entry.fine_print:
			fine_print += 1
			assert_has(entry.trumps_required(), TrumpIds.TRUMP_15, "fine print waits on Bargain")
	assert_true(hidden > 0, "at least one line is hidden stock")
	assert_true(fine_print > 0, "at least one line is fine print")


# --- The doc's scope cut, enforced in data -----------------------------------


func test_every_outfit_is_cosmetic_only() -> void:
	# progression.md §Philosophy: outfits "change how the Fool looks, never how the
	# Fool plays". Enforced by ItemDefinition.validate(), proved here on real data.
	if not assert_not_null(_items):
		return
	var outfits := _items.of_category(ItemCategory.Id.OUTFIT)
	assert_true(outfits.size() > 0, "one outfit is authored so the rule has something to hold")
	for outfit: ItemDefinition in outfits:
		assert_true(outfit.cosmetic_only, "%s must be cosmetic only" % outfit.id)
		assert_eq(outfit.moveset_twist, &"", "%s must change nothing about play" % outfit.id)


func test_an_outfit_that_changes_play_is_refused() -> void:
	var outfit := ItemDefinition.new()
	outfit.id = &"ITEM_TEST_OUTFIT"
	outfit.name_key = &"ITEM_TEST_OUTFIT_NAME"
	outfit.category = ItemCategory.Id.OUTFIT
	outfit.cosmetic_only = true
	outfit.moveset_twist = ItemIds.TWIST_REACH_PLUS
	assert_true(outfit.validate().size() > 0, "a cosmetic that twists the moveset is invalid")


func test_an_outfit_not_marked_cosmetic_only_is_refused() -> void:
	# progression.md §Philosophy's headline rule gets its own assertion, separate
	# from `test_an_outfit_that_changes_play_is_refused` above: an OUTFIT that is not
	# marked `cosmetic_only` is refused on its own, with no twist involved at all.
	# Mutate `ItemDefinition.validate()`'s
	# `ItemCategory.is_cosmetic_only(category) and not cosmetic_only` guard away and
	# this is the test that goes red while the twist test above stays green.
	var outfit := ItemDefinition.new()
	outfit.id = &"ITEM_TEST_OUTFIT_NOT_COSMETIC"
	outfit.name_key = &"ITEM_TEST_OUTFIT_NOT_COSMETIC_NAME"
	outfit.category = ItemCategory.Id.OUTFIT
	outfit.cosmetic_only = false
	var errors := outfit.validate()
	assert_true(errors.size() > 0, "an outfit that is not cosmetic only must be refused")
	var named_the_rule := false
	for error: String in errors:
		if error.contains("cosmetic only"):
			named_the_rule = true
	assert_true(named_the_rule, "the refusal must name the cosmetic-only rule, not some other guard")


func test_a_staff_head_without_a_twist_is_refused() -> void:
	# "never a numeric upgrade" cuts both ways: gear that does nothing at all is the
	# treadmill by another name.
	var head := ItemDefinition.new()
	head.id = &"ITEM_TEST_HEAD"
	head.name_key = &"ITEM_TEST_HEAD_NAME"
	head.category = ItemCategory.Id.STAFF_HEAD
	assert_true(head.validate().size() > 0, "a staff head must twist something")
	head.moveset_twist = &"TEST_TWIST"
	assert_eq(head.validate(), PackedStringArray(), "and with a twist it is valid")


func test_every_authored_staff_head_twists_the_bindle_differently() -> void:
	if not assert_not_null(_items):
		return
	var heads := _items.of_category(ItemCategory.Id.STAFF_HEAD)
	assert_true(heads.size() > 0)
	var twists: Dictionary = {}
	for head: ItemDefinition in heads:
		assert_ne(head.moveset_twist, &"", "%s twists nothing" % head.id)
		assert_false(twists.has(head.moveset_twist), "%s twists what another head does" % head.id)
		twists[head.moveset_twist] = true


func test_a_price_rule_on_a_flag_the_matrix_lacks_is_refused() -> void:
	var rule := PriceRule.new()
	rule.when_fired = &"WS_NOT_A_REAL_FLAG"
	rule.category = ItemCategory.Id.FOOD
	rule.multiplier = 0.5
	assert_eq(rule.validate(), PackedStringArray(), "on its own the rule is well formed")
	assert_true(rule.validate(_world_states).size() > 0, "against the matrix it is not")


func test_a_shop_may_not_stock_a_quest_item() -> void:
	# LEAD RULING: a QUEST item is carried because a quest says so, never bought or
	# sold. `EconomyService.buy()` refuses one at the counter
	# (`test_a_quest_item_is_never_bought`, economy_service_test.gd); this is the
	# other half - a QUEST item must not even reach a shelf.
	var quest_item := ItemDefinition.new()
	quest_item.id = &"ITEM_TEST_QUEST_ON_SHELF"
	quest_item.name_key = &"ITEM_TEST_QUEST_ON_SHELF_NAME"
	quest_item.category = ItemCategory.Id.QUEST
	var items := ItemCatalog.new()
	items.entries = [quest_item]

	var entry := ShopStockEntry.new()
	entry.item_id = quest_item.id
	entry.count = 1

	var shop := ShopDefinition.new()
	shop.id = &"SHOP_TEST_QUEST_SHELF"
	shop.region_id = RegionIds.PRESTIGE
	shop.suit = Suit.Id.WANDS
	shop.stock = [entry]

	var errors := shop.validate_against(items, _rules, _regions, _world_states, _trumps)
	var named_the_rule := false
	for error: String in errors:
		if error.contains("QUEST item"):
			named_the_rule = true
	assert_true(named_the_rule, "a QUEST item on a shelf must be refused by name")


# --- Localization -------------------------------------------------------------


func test_every_item_name_translates() -> void:
	TranslationServer.set_locale("en")
	if not assert_not_null(_items):
		return
	for item: ItemDefinition in _items.entries:
		if item == null:
			continue
		var english := TranslationServer.translate(item.name_key)
		assert_ne(
			english,
			String(item.name_key),
			"%s has no English in localization/items.csv" % item.name_key
		)


func test_no_item_ships_english_on_the_resource() -> void:
	# The lint already forbids sentences in a .tres; this is the narrower rule the
	# lint cannot see: a name_key must be a KEY, not the word itself.
	if not assert_not_null(_items):
		return
	var key_regex := RegEx.new()
	key_regex.compile("^[A-Z0-9_]+$")
	for item: ItemDefinition in _items.entries:
		if item == null:
			continue
		assert_not_null(
			key_regex.search(String(item.name_key)),
			"%s is not a translation key" % item.name_key
		)


# --- The id constants match the authored data --------------------------------


func test_item_ids_and_the_catalog_agree() -> void:
	if not assert_not_null(_items):
		return
	assert_eq(_items.ids(), ItemIds.ALL, "ItemIds is the catalog, in order")
	for staff_head_id: StringName in ItemIds.STAFF_HEADS:
		var item := _items.find(staff_head_id)
		if assert_not_null(item, "%s must be an authored item" % staff_head_id):
			assert_true(item.is_staff_head())


func test_shop_ids_and_the_catalog_agree() -> void:
	if not assert_not_null(_shops):
		return
	assert_eq(_shops.ids(), ShopIds.ALL)
