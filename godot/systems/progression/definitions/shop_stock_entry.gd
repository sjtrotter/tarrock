class_name ShopStockEntry
extends Resource

## One line of a shop's stock list: what it sells, how many, and who gets to see it.
##
## `docs/design/progression.md` §Currency, shops, and gear-lite: "a shop's stock and
## prices are a live reflection of the world-state matrix", so what is on the shelf
## is a condition on the world rather than a fixed list. Two Trumps reach in here as
## well, and both are `docs/design/arcana.md` Past-slot passives:
##
##   * **Trump I, Manifest** - "Nimble hands: instant chest/door interactions;
##     **vendors show their hidden stock**." An entry flagged `hidden_until_manifest`
##     is not on the shelf until the Fool holds the Magician's card.
##   * **Trump XV, Bargain** - "**Fine-print stock at every shop**: potent goods with
##     their costs printed honestly." An entry flagged `fine_print` is the same shape
##     from the other side: it is there all along, and only the Devil's card makes
##     the terms legible enough to buy.
##
## Both flags are HOOKS: this class decides whether an offer is on the shelf, and the
## effect runner that owns Trump behaviour owes everything else (what a "cost printed
## honestly" then does to the Fool who pays it). `ShopOffer.fine_print` carries the
## flag out to whoever draws the shelf, so fine-print goods can be shown as what they
## are rather than as ordinary stock.

## The Trump whose Past slot reveals hidden stock (Manifest). Named, never typed.
const MANIFEST_TRUMP := TrumpIds.TRUMP_01

## The Trump whose Past slot makes fine-print stock legible (Bargain).
const FINE_PRINT_TRUMP := TrumpIds.TRUMP_15

## What is for sale.
@export var item_id: StringName = &""

## How many the shop holds when it is fully stocked. A restock returns to this.
@export var count: int = 1

## True when a rest at a Waystation puts this line back to `count`
## (`progression.md` §Waystations: resting is the world's tick).
@export var restocks_on_rest: bool = true

## `WS_*` flags that must ALL have fired before this line is on the shelf.
@export var requires_fired: Array[StringName] = []

## Trump ids that must ALL be held before this line is on the shelf. The two flags
## below are the canon cases; this is the general form for the ones a later shop
## needs.
@export var requires_trump_held: Array[StringName] = []

## Trump I's hidden stock (see the class doc).
@export var hidden_until_manifest: bool = false

## Trump XV's fine-print stock (see the class doc).
@export var fine_print: bool = false

## Authoring notes: why this line is here and what is TBD about it. Doc-only.
@export var notes: String = ""


## Every Trump that must be held for this line to be on the shelf: the ones authored
## by hand, plus the two the canon flags stand for.
##
## Folded together here rather than at the shop, so "is this offer visible" has one
## answer and a reviewer can read a flag off the resource instead of remembering
## which card it meant.
func trumps_required() -> Array[StringName]:
	var found: Array[StringName] = []
	for trump_id: StringName in requires_trump_held:
		found.append(trump_id)
	if hidden_until_manifest and not found.has(MANIFEST_TRUMP):
		found.append(MANIFEST_TRUMP)
	if fine_print and not found.has(FINE_PRINT_TRUMP):
		found.append(FINE_PRINT_TRUMP)
	return found


## Every problem with this line on its own; empty means it is usable stock.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_id == &"":
		errors.append("a stock line names no item")
	if count <= 0:
		errors.append("the stock line for %s holds %d" % [item_id, count])
	return errors
