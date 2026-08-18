class_name EconomyService
extends RefCounted

## Coins, what they buy, and what a deed does to the Fool's standing.
##
## `docs/design/progression.md` is canon for all of it - §Currency, shops, and
## gear-lite for the purse, the shops and the staff heads, §The White Rose for
## graftings, §Renown for the deed table. The rules this service exists to make
## structural rather than remembered:
##
##   * **A price is read, never stored.** §Currency, shops, and gear-lite: "a shop's
##     stock and prices are a live reflection of the world-state matrix ... not a
##     static price list". So `price_of()` computes from the item's base price, the
##     shop's region multiplier, the Fool's Renown tier with the shop's LOCAL suit,
##     and every `PriceRule` whose flag has fired. The canon example -
##     `WS_EMPRESS_UNBOUND` halves FOOD Spread-wide - is one row of
##     `EconomyRules.price_rules` and not one line of code in here.
##   * **Growth is horizontal.** §Philosophy allows exactly three growth vectors, and
##     two of them pass through here: a staff head is a *twist* on the Bindle
##     (`ItemDefinition.moveset_twist`, applied by the effect runner, never a number
##     this service adds up), and a grafting raises the White Rose's cap through
##     `WhiteRoseService.add_grafting()` - which owns the 8-petal ceiling, so nothing
##     here counts petals. Outfits are cosmetic and this service has no way to make
##     one anything else: `ItemDefinition.validate()` refuses the attempt in data.
##   * **A deed becomes Renown in ONE place.** `record_deed()` walks the four suits,
##     asks the deed what each culture makes of it and the rules what that is worth,
##     and calls `WorldStateService.adjust_renown()` - the only mutation path there
##     has ever been. Nothing else in the game may turn a deed into standing, and
##     nothing here adds the four movements up: Renown is not a morality meter.
##   * **Stock is world state, not a shelf.** A line the Fool cannot see is not on
##     the shelf at all, and what makes it visible is a fired flag or a held Trump
##     (Manifest's hidden stock, Bargain's fine print - see `ShopStockEntry`).
##
## The one non-obvious wiring rule: `RegionService` is held WEAKLY (see `_regions`),
## because it holds the save, and the save holds this service - an ordinary field
## would close a `RefCounted` cycle that nothing collects.
##
## Definitions are immutable: what has been bought lives here, in `_stock_sold`,
## never on the `ShopStockEntry`. Restocking is a rest at a Waystation, which is why
## this service listens to `RegionService.rested` (see `attach_regions()`) rather
## than ticking.
##
## Snapshot/restore follow the same contract as the other progression services: a
## fresh service only, all-or-nothing, emitting nothing. It travels as the save
## file's `inventory` section, whose keys this service owns (`SNAPSHOT_*`).

## The purse changed. `reason` is why - a shop id, a deed id, a quest id.
signal coins_changed(old_coins: int, new_coins: int, reason: StringName)

## The Fool picked something up.
signal item_added(item_id: StringName, count: int)

## Something left the Bindle: spent, sold, handed over.
signal item_removed(item_id: StringName, count: int)

## The Bindle wears a different head. The twist itself is the effect runner's to
## apply; this is the announcement it hangs on.
signal staff_head_changed(old_item_id: StringName, new_item_id: StringName)

## A Rose grafting was found at a source, for the first and only time.
signal grafting_found(source_id: StringName)

## A deed was recorded, and the four suits have already heard about it.
signal deed_recorded(deed_id: StringName)

## Something was bought.
signal purchase_made(shop_id: StringName, item_id: StringName, price: int)

## Something was not. `reason` is one of the `REASON_*` constants.
signal purchase_refused(shop_id: StringName, item_id: StringName, reason: StringName)

## The shop does not exist.
const REASON_NO_SUCH_SHOP := &"NO_SUCH_SHOP"

## The item does not exist.
const REASON_NO_SUCH_ITEM := &"NO_SUCH_ITEM"

## The shop does not carry it, or the Fool cannot see it yet (hidden or fine-print
## stock - `ShopStockEntry`). Deliberately the same answer either way: a shelf that
## refused differently would tell the Fool what is behind the counter.
const REASON_NOT_STOCKED := &"NOT_STOCKED"

## The shelf is empty until the next rest.
const REASON_OUT_OF_STOCK := &"OUT_OF_STOCK"

## The purse is too light.
const REASON_CANNOT_AFFORD := &"CANNOT_AFFORD"

## The item exists but shops do not stock or buy it (a QUEST item -
## `docs/design/progression.md`: Coins are found, looted, earned through quests, and
## spent - never traded back for one).
const REASON_NOT_FOR_SALE := &"NOT_FOR_SALE"

## The keys of the save file's `inventory` section. Spelled once here, because this
## service owns the section's contract exactly as `WhiteRoseService` owns its own.
const SNAPSHOT_COINS := "coins"
const SNAPSHOT_ITEMS := "items"
const SNAPSHOT_STAFF_HEAD := "staff_head"
const SNAPSHOT_GRAFTINGS := "graftings"

## The id nothing is: no staff head equipped, no reason given.
const UNSET := WorldStateService.UNSET

## What `price_of()` answers for a shop or an item that does not exist. Never a
## price: 0 would read as free and 1 as cheap.
const NO_PRICE := -1

var _rules: EconomyRules = null
var _items: ItemCatalog = null
var _shops: ShopCatalog = null
var _deeds: DeedCatalog = null
var _world_state: WorldStateService = null
var _spread: PocketSpreadService = null
var _rose: WhiteRoseService = null

## The region service, held WEAKLY. Everything else here is a plain reference; this
## one cannot be, because the graph closes into a cycle and `RefCounted` collects by
## reference count alone: this service is captured by `SaveService`, which
## `RegionService` holds, so an ordinary field here would make the pair immortal and
## the engine reports it at exit as "resources still in use". A weak handle keeps the
## composition root the only owner of both, which is what it is meant to be.
var _regions: WeakRef = null

## The purse.
var _coins: int = 0

## `item id -> count`. An item at zero is removed rather than kept at zero, so
## `count()` and "is it in the Bindle" cannot disagree.
var _carried: Dictionary = {}

## The staff head on the Bindle, or `UNSET`. Only ever one (§Currency, shops, and
## gear-lite: a staff head is what the Bindle *is* right now, not a set worn at once).
var _staff_head: StringName = UNSET

## The grafting sources already taken, as a set. Set-once per source: a cutting taken
## from a bush is a cutting that bush no longer has.
var _graftings_found: Dictionary = {}

## `shop id -> Dictionary of item id -> how many have been bought since the last
## restock`. Kept here rather than on the definition, which is immutable.
var _stock_sold: Dictionary = {}

## False from the first mutation - or the first load - onward. What makes
## `restore_snapshot()` a load rather than a reset.
var _pristine: bool = true


## Build the service over its definitions and the services it reads.
##
## `world_state` is the only mutation path for Renown, `spread` answers which Trumps
## are held (hidden and fine-print stock), and `rose` owns the petal cap a grafting
## raises. All three are optional so a test can build the half it cares about; the
## composition root passes them all.
##
## `RegionService` is deliberately NOT a constructor parameter: it is built *after*
## this service (it needs the save, which captures this one), so the rest signal is
## connected afterwards through `attach_regions()`.
func _init(
	rules: EconomyRules,
	items: ItemCatalog,
	shops: ShopCatalog,
	deeds: DeedCatalog,
	world_state: WorldStateService = null,
	spread: PocketSpreadService = null,
	rose: WhiteRoseService = null
) -> void:
	_rules = rules
	_items = items
	_shops = shops
	_deeds = deeds
	_world_state = world_state
	_spread = spread
	_rose = rose
	if rules != null:
		# The starting purse is configuration, not play: a service that has only been
		# built is still pristine, and a save can still be loaded into it.
		_coins = maxi(0, rules.starting_coins)


## Listen for rests, so a Waystation restocks the shelves.
##
## Called by the composition root once `RegionService` exists. The subscription lives
## here rather than in `Services` because the shape of a restock is this service's
## business and the composition root's job is only to introduce the two.
func attach_regions(regions: RegionService) -> void:
	var attached := attached_regions()
	if attached == regions:
		return
	if attached != null and attached.rested.is_connected(_on_rested):
		attached.rested.disconnect(_on_rested)
	_regions = null if regions == null else weakref(regions)
	if regions != null and not regions.rested.is_connected(_on_rested):
		regions.rested.connect(_on_rested)


## The region service this economy is listening to, or `null`. Weakly held: see
## `_regions`.
func attached_regions() -> RegionService:
	if _regions == null:
		return null
	return _regions.get_ref() as RegionService


## The rules this service prices with.
func rules() -> EconomyRules:
	return _rules


## The item catalog, for a screen that wants to name what is carried.
func item_catalog() -> ItemCatalog:
	return _items


## The shop catalog.
func shop_catalog() -> ShopCatalog:
	return _shops


## The deed catalog.
func deed_catalog() -> DeedCatalog:
	return _deeds


## True until this service is first mutated or first loaded into.
func is_pristine() -> bool:
	return _pristine


# --- Coins -------------------------------------------------------------------


## What is in the purse.
func coins() -> int:
	return _coins


## Put coins in the purse. `reason` is who paid - a quest id, a shop id.
##
## A gift of nothing changes nothing: `count` at or below zero is ignored rather than
## quietly subtracting, because `add_coins(-5)` is a caller that meant `spend_coins`.
func add_coins(count_added: int, reason: StringName = UNSET) -> void:
	if count_added <= 0:
		return
	_pristine = false
	var old_coins := _coins
	_coins += count_added
	coins_changed.emit(old_coins, _coins, reason)


## Take coins out of the purse. False when there are not enough, changing nothing.
func spend_coins(count_spent: int, reason: StringName = UNSET) -> bool:
	if count_spent <= 0 or count_spent > _coins:
		return false
	_pristine = false
	var old_coins := _coins
	_coins -= count_spent
	coins_changed.emit(old_coins, _coins, reason)
	return true


## True when the purse holds at least this much.
func can_afford(price: int) -> bool:
	return price >= 0 and _coins >= price


# --- What the Fool carries ---------------------------------------------------


## How many of this item are in the Bindle.
func count(item_id: StringName) -> int:
	return int(_carried.get(item_id, 0))


## Every item carried, in catalog order, so a screen is never at the mercy of the
## order things were picked up in.
func carried_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	if _items == null:
		return found
	for entry: ItemDefinition in _items.entries:
		if entry != null and count(entry.id) > 0:
			found.append(entry.id)
	return found


## Put items in the Bindle. False for an item the catalog does not define, or for a
## count at or below zero.
func add_item(item_id: StringName, count_added: int = 1) -> bool:
	if count_added <= 0 or _items == null or _items.find(item_id) == null:
		return false
	_pristine = false
	_carried[item_id] = count(item_id) + count_added
	item_added.emit(item_id, count_added)
	return true


## Take items out of the Bindle. False when the Fool is not carrying that many,
## changing nothing.
func remove_item(item_id: StringName, count_removed: int = 1) -> bool:
	if count_removed <= 0 or count(item_id) < count_removed:
		return false
	_pristine = false
	var remaining := count(item_id) - count_removed
	if remaining <= 0:
		_carried.erase(item_id)
		# A head that is no longer carried is no longer on the Bindle. Silent about
		# WHY - the effect runner hears `staff_head_changed` and takes the twist off.
		if _staff_head == item_id:
			_set_staff_head(UNSET)
	else:
		_carried[item_id] = remaining
	item_removed.emit(item_id, count_removed)
	return true


# --- Staff heads -------------------------------------------------------------


## The staff head on the Bindle, or `UNSET`.
func equipped_staff_head() -> StringName:
	return _staff_head


## Put a staff head on the Bindle. False unless the Fool owns one and it is a staff
## head that is not already fitted.
##
## What the head then DOES is not here: `ItemDefinition.moveset_twist` names a
## strategy and the combat effect runner owes the behaviour (§Currency, shops, and
## gear-lite - "a small, distinct twist on the Bindle's moveset ... never a numeric
## upgrade", so there is no number for this service to apply).
func equip_staff_head(item_id: StringName) -> bool:
	if _items == null:
		return false
	var definition := _items.find(item_id)
	if definition == null or not definition.is_staff_head():
		return false
	if count(item_id) <= 0 or _staff_head == item_id:
		return false
	_pristine = false
	_set_staff_head(item_id)
	return true


## Take the head off the Bindle, leaving it bare. False when it already is.
func unequip_staff_head() -> bool:
	if _staff_head == UNSET:
		return false
	_pristine = false
	_set_staff_head(UNSET)
	return true


## The twist the fitted head puts on the Bindle, or `UNSET` for a bare one. What the
## effect runner will look a behaviour up by.
func equipped_moveset_twist() -> StringName:
	if _staff_head == UNSET or _items == null:
		return UNSET
	var definition := _items.find(_staff_head)
	if definition == null:
		return UNSET
	return definition.moveset_twist


# --- Rose graftings ----------------------------------------------------------


## True when this grafting source has already been taken.
func has_grafting(source_id: StringName) -> bool:
	return _graftings_found.has(source_id)


## Every grafting source taken, in the order they were found. Append-only.
func graftings_found() -> Array[StringName]:
	var found: Array[StringName] = []
	for source_id: StringName in _graftings_found:
		found.append(source_id)
	return found


## Take the grafting at `source_id`: one more petal of capacity on the White Rose.
##
## SET-ONCE per source (`docs/design/progression.md` §The White Rose: graftings are
## "found or earned ... in the world or as side-quest rewards" - a cutting taken from
## a bush is a cutting that bush no longer has), so a second visit to the same place
## is false and changes nothing.
##
## The cap belongs to the Rose, not here: a grafting the Rose cannot take - it is
## already at its eight petals - is NOT recorded, so the source is not silently spent
## and the count of graftings found can never exceed the ones the Rose actually has.
func find_grafting(source_id: StringName) -> bool:
	if source_id == UNSET or _graftings_found.has(source_id) or _rose == null:
		return false
	if not _rose.add_grafting():
		return false
	_pristine = false
	_graftings_found[source_id] = true
	grafting_found.emit(source_id)
	return true


# --- Deeds and Renown --------------------------------------------------------


## Record that the Fool did a deed, and let all four suit-cultures react.
##
## THE ONLY PLACE A DEED BECOMES RENOWN. Each suit moves by its own reaction in
## `docs/design/progression.md` §Renown's table, valued by `EconomyRules`, with the
## deed id as the reason - so a Renown movement can always be traced back to a row of
## the doc. A NEUTRAL suit is not touched at all: `adjust_renown` by zero would emit
## `renown_changed` and tell a listener that a culture which does not care had an
## opinion.
##
## Nothing here sums the four movements. Renown is standing, not morality, and a deed
## that raises the Fool with Coins while it costs them with Cups has done exactly
## what the doc says it should.
##
## False for a deed the catalog does not define; a deed is a doc row, never a string
## a caller invented.
func record_deed(deed_id: StringName) -> bool:
	if _deeds == null or _world_state == null or _rules == null:
		return false
	var definition := _deeds.find(deed_id)
	if definition == null:
		return false
	_pristine = false
	for suit: Suit.Id in Suit.ALL:
		var delta := _rules.renown_delta_for(definition.reaction_for(suit))
		if delta == 0:
			continue
		_world_state.adjust_renown(suit, delta, deed_id)
	deed_recorded.emit(deed_id)
	return true


# --- Shops -------------------------------------------------------------------


## What one shop is asking for one item today, or `NO_PRICE` when it prices nothing.
##
## The whole of §Currency, shops, and gear-lite's pricing sentence, in order: the
## item's base price, then the region (the shop's own multiplier, or the economy's
## default), then the Fool's Renown with the shop's LOCAL suit, then every price rule
## whose world-state has fired. Rounded, and never below one Coin - a shop that gave
## something away would be a price the matrix cannot explain.
##
## The item does not have to be on this shop's shelf: what a place charges is a fact
## about the place, and a screen comparing two towns needs to be able to ask.
func price_of(shop_id: StringName, item_id: StringName) -> int:
	if _shops == null or _items == null:
		return NO_PRICE
	var shop := _shops.find(shop_id)
	var item := _items.find(item_id)
	if shop == null or item == null:
		return NO_PRICE
	var price := float(item.base_price)
	price *= shop.region_multiplier(_rules)
	price *= _renown_multiplier(shop)
	if _rules != null:
		for rule: PriceRule in _rules.price_rules_for(item, shop.region_id, _world_state):
			price *= rule.multiplier
	return maxi(1, int(roundf(price)))


## What is on this shop's shelf right now, in authoring order.
##
## VISIBLE LINES ONLY. A line waiting on a flag that has not fired, or on a Trump the
## Fool does not hold, is not an empty shelf slot - it is not there at all, which is
## what makes Manifest's "vendors show their hidden stock" a discovery rather than a
## discount (`ShopStockEntry`). A line bought out stays visible with a count of zero,
## because an empty shelf in a shop the Fool knows is information.
func stock_of(shop_id: StringName) -> Array[ShopOffer]:
	var offers: Array[ShopOffer] = []
	if _shops == null:
		return offers
	var shop := _shops.find(shop_id)
	if shop == null:
		return offers
	for entry: ShopStockEntry in shop.stock:
		if entry == null or not _is_visible(entry):
			continue
		offers.append(ShopOffer.new(
			entry.item_id,
			price_of(shop_id, entry.item_id),
			_remaining(shop_id, entry),
			entry.fine_print
		))
	return offers


## How many of an item this shop has left on the shelf, visible lines only. Zero for
## a line the Fool cannot see, which is the same answer as a line sold out - see
## `REASON_NOT_STOCKED`.
func stock_remaining(shop_id: StringName, item_id: StringName) -> int:
	if _shops == null:
		return 0
	var shop := _shops.find(shop_id)
	if shop == null:
		return 0
	var entry := shop.line_for(item_id)
	if entry == null or not _is_visible(entry):
		return 0
	return _remaining(shop_id, entry)


## Buy one. True when the Fool paid and is carrying it.
##
## Every refusal is announced with a reason rather than returned as a bare false, so
## a shop screen can say why without asking three more questions. Nothing is spent
## unless everything succeeds: the coins leave the purse only after the shelf has
## agreed there is one to sell.
##
## A QUEST item refuses with `REASON_NOT_FOR_SALE` before the shelf is even asked:
## `docs/design/progression.md` - Coins are found, looted, earned through quests, and
## spent; a quest item is carried because a quest says so, never bought
## (`ShopDefinition.validate_against()` refuses one on a shelf in the first place, so
## this is the defensive second reading of the same rule).
func buy(shop_id: StringName, item_id: StringName) -> bool:
	if _shops == null or _shops.find(shop_id) == null:
		purchase_refused.emit(shop_id, item_id, REASON_NO_SUCH_SHOP)
		return false
	var item: ItemDefinition = null if _items == null else _items.find(item_id)
	if item == null:
		purchase_refused.emit(shop_id, item_id, REASON_NO_SUCH_ITEM)
		return false
	if item.category == ItemCategory.Id.QUEST:
		purchase_refused.emit(shop_id, item_id, REASON_NOT_FOR_SALE)
		return false
	var shop := _shops.find(shop_id)
	var entry := shop.line_for(item_id)
	if entry == null or not _is_visible(entry):
		purchase_refused.emit(shop_id, item_id, REASON_NOT_STOCKED)
		return false
	if _remaining(shop_id, entry) <= 0:
		purchase_refused.emit(shop_id, item_id, REASON_OUT_OF_STOCK)
		return false
	var price := price_of(shop_id, item_id)
	if not can_afford(price):
		purchase_refused.emit(shop_id, item_id, REASON_CANNOT_AFFORD)
		return false
	spend_coins(price, shop_id)
	_record_sale(shop_id, item_id)
	add_item(item_id, 1)
	purchase_made.emit(shop_id, item_id, price)
	return true


## Put every restocking line back on every shelf.
##
## Rest is the world's own tick (`progression.md` §Waystations: a rest regrows the
## Rose and respawns the ambient dead), so it is what refills a shop. A line marked
## `restocks_on_rest = false` is a one-off - the staff head on the Prestige's stall is
## the shape of it - and stays sold for the rest of the playthrough.
func restock_on_rest() -> void:
	if _shops == null:
		return
	for shop_id: StringName in _stock_sold.keys():
		var shop := _shops.find(shop_id)
		if shop == null:
			continue
		var sold: Dictionary = _stock_sold[shop_id]
		for item_id: StringName in sold.keys():
			var entry := shop.line_for(item_id)
			if entry != null and entry.restocks_on_rest:
				sold.erase(item_id)


# --- The save file's `inventory` section --------------------------------------


## Everything the save file needs: the purse, what is carried, what is fitted and
## which grafting sources are spent - ids and numbers only.
##
## The shelves are NOT in here, deliberately. What a shop has sold is a fact about a
## shop between two rests, and the first rest after a load puts it right; a save that
## carried it would be a save that had to be migrated every time a shelf changed.
func to_snapshot() -> Dictionary:
	var carried: Dictionary = {}
	for item_id: StringName in _carried:
		carried[String(item_id)] = int(_carried[item_id])
	var sources: Array = []
	for source_id: StringName in _graftings_found:
		sources.append(String(source_id))
	return {
		SNAPSHOT_COINS: _coins,
		SNAPSHOT_ITEMS: carried,
		SNAPSHOT_STAFF_HEAD: String(_staff_head),
		SNAPSHOT_GRAFTINGS: sources,
	}


## Load a snapshot, returning every problem it found. Emits nothing.
##
## A fresh service only, all-or-nothing - the same contract `WorldStateService`,
## `FortuneService` and `WhiteRoseService` keep, and for the same reason: a load is
## not a reset, and a half-filled purse is not a playthrough.
##
## The White Rose is NOT re-grafted here. Its own `restore_snapshot()` carries the
## graftings count out of the same file, so replaying them would double every one;
## what this section carries is *which sources are spent*, which is the fact the Rose
## does not hold.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _pristine:
		errors.append("restore_snapshot needs a fresh economy; this one is already in play")
		return errors
	var stored_coins: Variant = data.get(SNAPSHOT_COINS, 0)
	if not (stored_coins is int or stored_coins is float):
		errors.append("snapshot coins are not a number")
		return errors
	var coins_value := int(stored_coins)
	if coins_value < 0:
		errors.append("snapshot has %d coins" % coins_value)
	var carried := _restored_items(data, errors)
	var sources := _restored_graftings(data, errors)
	var head := _restored_staff_head(data, carried, errors)
	if not errors.is_empty():
		return errors
	_coins = coins_value
	_carried = carried
	_graftings_found = sources
	_staff_head = head
	_stock_sold = {}
	_pristine = false
	return errors


# --- Internals ---------------------------------------------------------------


## What the Renown ladder does to this shop's prices: the Fool's tier with the shop's
## LOCAL suit, and nobody else's. Standing with Swords buys nothing in a Cups town.
func _renown_multiplier(shop: ShopDefinition) -> float:
	if _rules == null or _world_state == null or shop == null:
		return 1.0
	return _rules.renown_multiplier_for_tier(_world_state.renown_tier(shop.suit))


## True when the Fool can see this line: every flag it waits on has fired and every
## Trump it waits on is held.
func _is_visible(entry: ShopStockEntry) -> bool:
	for flag_id: StringName in entry.requires_fired:
		if _world_state == null or not _world_state.is_fired(flag_id):
			return false
	for trump_id: StringName in entry.trumps_required():
		if _spread == null or not _spread.is_held(trump_id):
			return false
	return true


## How many of a line are left after what has been bought since the last restock.
func _remaining(shop_id: StringName, entry: ShopStockEntry) -> int:
	var sold: Dictionary = _stock_sold.get(shop_id, {})
	return maxi(0, entry.count - int(sold.get(entry.item_id, 0)))


## Remember one more of this line has left the shelf.
func _record_sale(shop_id: StringName, item_id: StringName) -> void:
	if not _stock_sold.has(shop_id):
		_stock_sold[shop_id] = {}
	var sold: Dictionary = _stock_sold[shop_id]
	sold[item_id] = int(sold.get(item_id, 0)) + 1


## Fit a head (or none) and announce it. The one writer of `_staff_head`.
func _set_staff_head(item_id: StringName) -> void:
	var old_head := _staff_head
	if old_head == item_id:
		return
	_staff_head = item_id
	staff_head_changed.emit(old_head, item_id)


## A rest happened somewhere: every shelf that refills, refills.
func _on_rested(_waystation_id: StringName) -> void:
	restock_on_rest()


## The `items` section of a snapshot, as `id -> count`, with every problem recorded.
func _restored_items(data: Dictionary, errors: PackedStringArray) -> Dictionary:
	var carried: Dictionary = {}
	var stored: Variant = data.get(SNAPSHOT_ITEMS, {})
	if not (stored is Dictionary):
		errors.append("snapshot items are not a dictionary")
		return carried
	for key: Variant in stored as Dictionary:
		if not (key is String or key is StringName):
			errors.append("snapshot carries something that is not an item id: %s" % str(key))
			continue
		var item_id := StringName(key)
		var value: Variant = (stored as Dictionary)[key]
		if not (value is int or value is float):
			errors.append("snapshot count for %s is not a number" % item_id)
			continue
		var counted := int(value)
		if counted <= 0:
			errors.append("snapshot carries %d of %s" % [counted, item_id])
			continue
		if _items != null and _items.find(item_id) == null:
			errors.append("snapshot names an item this build does not have: %s" % item_id)
			continue
		carried[item_id] = counted
	return carried


## The `graftings` section of a snapshot, as a set, with every problem recorded.
func _restored_graftings(data: Dictionary, errors: PackedStringArray) -> Dictionary:
	var sources: Dictionary = {}
	var stored: Variant = data.get(SNAPSHOT_GRAFTINGS, [])
	if not (stored is Array):
		errors.append("snapshot graftings are not a list")
		return sources
	for entry: Variant in stored as Array:
		if not (entry is String or entry is StringName):
			errors.append("snapshot lists a grafting source that is not an id: %s" % str(entry))
			continue
		sources[StringName(entry)] = true
	return sources


## The `staff_head` field of a snapshot, checked against what the save says is
## carried: a head the Fool is not holding is a save that disagrees with itself.
func _restored_staff_head(
	data: Dictionary, carried: Dictionary, errors: PackedStringArray
) -> StringName:
	var stored: Variant = data.get(SNAPSHOT_STAFF_HEAD, String(UNSET))
	if not (stored is String or stored is StringName):
		errors.append("snapshot staff head is not an id")
		return UNSET
	var head := StringName(stored)
	if head == UNSET:
		return UNSET
	var definition: ItemDefinition = null if _items == null else _items.find(head)
	if definition == null:
		errors.append("snapshot fits a staff head this build does not have: %s" % head)
		return UNSET
	if not definition.is_staff_head():
		errors.append("snapshot fits %s to the Bindle, which is no staff head" % head)
		return UNSET
	if int(carried.get(head, 0)) <= 0:
		errors.append("snapshot fits %s without carrying one" % head)
		return UNSET
	return head
