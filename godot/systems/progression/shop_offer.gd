class_name ShopOffer
extends RefCounted

## One thing a shop is offering the Fool right now: the item, the price it is asking
## today, how many are left, and whether it is fine-print stock.
##
## A *runtime* value, not a definition: the price already has this region's
## multiplier, the Fool's standing with the local suit and every fired world-state
## rule in it (`docs/design/progression.md` §Currency, shops, and gear-lite), and the
## count is what is left after what has been bought. `EconomyService.stock_of()`
## builds these fresh on every ask, which is why nothing caches one - a shelf drawn
## from a stale offer would be a price that stopped reading the matrix.
##
## Only VISIBLE lines become offers: hidden stock the Fool cannot see yet is not on
## the shelf at all (`ShopStockEntry`). `fine_print` is carried out because the doc
## makes it a *kind* of stock - "potent goods with their costs printed honestly"
## (`arcana.md` Trump XV) - so a shelf can show it as what it is.

## What is for sale.
var item_id: StringName = &""

## What the shop is asking, in Coins, today. Never below 1.
var price: int = 0

## How many are left on the shelf.
var count: int = 0

## True when this is Bargain's fine-print stock (`ShopStockEntry.fine_print`).
var fine_print: bool = false


func _init(
	offered_item_id: StringName,
	asking_price: int,
	remaining: int,
	is_fine_print: bool = false
) -> void:
	item_id = offered_item_id
	price = asking_price
	count = remaining
	fine_print = is_fine_print


## True when there is at least one left to buy.
func in_stock() -> bool:
	return count > 0
