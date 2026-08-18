class_name ItemIds
extends RefCounted

## Every item id, as a constant.
##
## HAND-AUTHORED, unlike `WorldStateIds` or `DeedIds`: `docs/design/progression.md`
## §Currency, shops, and gear-lite has no item table to generate from and says why -
## "the exact identity and location of each staff head, and the full list of
## Rose-grafting sources, are TBD - content-design passes that happen once regions
## are greyboxed". So these are authored beside the `.tres` files under
## `res://data/progression/items/`, and the set grows as regions are built.
##
## Code never types an item id: it names one of these constants, or reads an id off
## an `ItemDefinition` (docs/design/technical.md, no magic strings).
##
## `COINS` is deliberately NOT here. Coins are money, not an item - `EconomyService`
## keeps a counter and there is no `ITEM_COINS` to buy, sell, or leave in a chest.

## Food. `world.md` §Regions gives the Prestige "popcorn older than nations"; this is
## a bag of it, and it is the item `WS_EMPRESS_UNBOUND` halves the price of.
const ITEM_POPCORN := &"ITEM_POPCORN"

## A curio: a bill for a show that has been mid-performance for three hundred years.
## TBD content - the Prestige's stall needs something to sell that is not food.
const ITEM_SHOWBILL := &"ITEM_SHOWBILL"

## An outfit, and therefore COSMETIC ONLY (§Philosophy). TBD content; it exists today
## to keep the cosmetic-only rule enforced by a real resource rather than by a test
## fixture.
const ITEM_MOTLEY_COAT := &"ITEM_MOTLEY_COAT"

## A cutting that raises the White Rose's maximum petals (§The White Rose). One id,
## not one per source: `EconomyService.find_grafting()` keys the set-once on WHERE it
## was found, and the full list of sources is doc-TBD.
const ROSE_GRAFTING := &"ROSE_GRAFTING"

## The staff heads. Roughly 8-10 exist across the Spread; these three are
## PLACEHOLDERS, and their identity and location are doc-TBD (see the class doc).
const STAFF_REACHING := &"STAFF_REACHING"
const STAFF_BROADHEAD := &"STAFF_BROADHEAD"
const STAFF_EMBER := &"STAFF_EMBER"

## Every item authored today, in catalog order.
const ALL: Array[StringName] = [
	ITEM_POPCORN,
	ITEM_SHOWBILL,
	ITEM_MOTLEY_COAT,
	ROSE_GRAFTING,
	STAFF_REACHING,
	STAFF_BROADHEAD,
	STAFF_EMBER,
]

## Every staff head authored today.
const STAFF_HEADS: Array[StringName] = [
	STAFF_REACHING,
	STAFF_BROADHEAD,
	STAFF_EMBER,
]

## The moveset twists the authored staff heads put on the Bindle. Strategy ids the
## combat effect runner will look a behaviour up by - never numbers
## (§Currency, shops, and gear-lite: "never a numeric upgrade").
const TWIST_REACH_PLUS := &"REACH_PLUS"
const TWIST_HEAVY_WIDE := &"HEAVY_WIDE"
const TWIST_FIRE_TAG := &"FIRE_TAG"
