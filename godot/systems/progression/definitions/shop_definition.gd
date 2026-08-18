class_name ShopDefinition
extends TarrockDefinition

## One shop: where it stands, whose regard prices it, and what is on the shelf.
##
## HAND-AUTHORED under `res://data/progression/shops/`.
## `docs/design/progression.md` §Currency, shops, and gear-lite puts a shop in "every
## settled region" and prices it three ways at once - "prices vary by region, and are
## further affected by the Fool's Renown with the local suit and by relevant
## world-states". This resource carries the first two (the region and the local suit,
## plus this shop's own multiplier); the third is `EconomyRules.price_rules`, because
## a world-state prices goods Spread-wide and belongs to the economy rather than to
## any one stall.
##
## **The local suit is a reading, not a table.** No doc assigns a suit-culture to a
## region: `docs/GLOSSARY.md` gives the four cultures their terrain (coasts, peaks,
## woods, plains) and `world.md` §Regions describes the places, and nobody has joined
## the two up. So `suit` is authored with the reading recorded in `notes`, and it is
## TBD content design - exactly as the identity of each staff head is.

## The region this shop stands in. Must be one `EconomyRules` calls settled.
@export var region_id: StringName = &""

## The suit-culture whose Renown prices this shop - the "local suit" of §Currency,
## shops, and gear-lite. A reading of the region; see the class doc.
@export var suit: Suit.Id = Suit.Id.COINS

## What this shop multiplies its prices by, before Renown and world-states. ZERO
## MEANS "no override": `EconomyRules.default_region_price_multiplier` is used
## instead, so an untuned shop and a shop deliberately tuned to 1.0 are different
## things in the data and a balance pass can tell them apart.
@export var price_multiplier: float = 0.0

## What is on the shelf, in the order it is shown.
@export var stock: Array[ShopStockEntry] = []

## The doc section this shop was authored from. Doc-only.
@export var doc_ref: String = ""

## Authoring notes: the readings made, and what is TBD. Doc-only.
@export var notes: String = ""


## What this shop multiplies its prices by, falling back to the economy's default.
func region_multiplier(rules: EconomyRules) -> float:
	if price_multiplier > 0.0:
		return price_multiplier
	if rules == null:
		return 1.0
	return rules.default_region_price_multiplier


## The stock line selling this item, or `null` when the shop does not carry it.
func line_for(item_id: StringName) -> ShopStockEntry:
	for entry: ShopStockEntry in stock:
		if entry != null and entry.item_id == item_id:
			return entry
	return null


## Every problem with this shop on its own; empty means it is a usable stall.
func validate() -> PackedStringArray:
	var errors := super()
	if region_id == &"":
		errors.append("%s stands in no region" % _describe())
	if suit < 0 or suit >= Suit.ALL.size():
		errors.append("%s prices off suit %d, which is not one of the four" % [_describe(), suit])
	if price_multiplier < 0.0:
		errors.append("%s multiplies its prices by %f" % [_describe(), price_multiplier])
	var seen: Dictionary = {}
	for index: int in stock.size():
		var entry := stock[index]
		if entry == null:
			errors.append("%s stock line %d is empty" % [_describe(), index])
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.item_id):
			errors.append("%s stocks %s on two lines" % [_describe(), entry.item_id])
		seen[entry.item_id] = true
	return errors


## Every problem with this shop, including the ones only the catalogs can find.
##
## Cross-references nothing else can make: the shop stands in a region that exists
## and that `EconomyRules` calls settled (a shop in an empty wilderness is a market
## with no town), every line sells an item the catalog defines and that item is not
## QUEST-category (a quest item is carried because a quest says so, never bought or
## sold - `EconomyService.buy()` refuses one too, but a shelf that offers one is
## wrong before a single Coin changes hands), and every condition on a line names a
## flag the matrix defines and a Trump `arcana.md` grants. A shelf waiting on a flag
## nobody fires is a shelf that never fills, and nothing else in the game would
## notice.
func validate_against(
	items: ItemCatalog,
	rules: EconomyRules,
	regions: RegionCatalog,
	world_states: WorldStateCatalog,
	trumps: TrumpCatalog
) -> PackedStringArray:
	var errors := validate()
	if regions != null and region_id != &"" and not regions.has(region_id):
		errors.append("%s stands in %s, and no region has that id" % [_describe(), region_id])
	if rules != null and region_id != &"" and not rules.is_settled(region_id):
		errors.append("%s stands in %s, which the economy does not call settled" % [
			_describe(), region_id
		])
	for entry: ShopStockEntry in stock:
		if entry == null:
			continue
		var item: ItemDefinition = null if items == null else items.find(entry.item_id)
		if items != null and item == null:
			errors.append("%s stocks %s, which no item defines" % [_describe(), entry.item_id])
		if item != null and item.category == ItemCategory.Id.QUEST:
			errors.append("%s stocks %s, a QUEST item - shops do not stock or buy those" % [
				_describe(), entry.item_id
			])
		for flag_id: StringName in entry.requires_fired:
			if world_states != null and world_states.find(flag_id) == null:
				errors.append("%s waits on %s, which no world-state row defines" % [
					_describe(), flag_id
				])
		for trump_id: StringName in entry.trumps_required():
			if trumps != null and trumps.find(trump_id) == null:
				errors.append("%s waits on %s, which no Trump defines" % [_describe(), trump_id])
	return errors
