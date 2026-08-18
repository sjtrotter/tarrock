class_name ItemDefinition
extends TarrockDefinition

## One thing the Fool can carry, buy, sell, eat, wear or swing.
##
## HAND-AUTHORED under `res://data/progression/items/`, because
## `docs/design/progression.md` §Currency, shops, and gear-lite is prose and says so
## itself: "the exact identity and location of each staff head, and the full list of
## Rose-grafting sources, are TBD - content-design passes that happen once regions are
## greyboxed". No table in `docs/` can produce this file, so nothing generates it; the
## three staff heads shipped today are placeholders and their `notes` say so.
##
## The doc's scope cut is enforced here rather than remembered:
##
##   * **An OUTFIT is cosmetic, and cannot stop being one.** §Philosophy: outfits
##     "change how the Fool looks, never how the Fool plays". An OUTFIT carrying a
##     `moveset_twist` - the only field on this class that changes play - is a
##     validation error, not a balance question.
##   * **A staff head is a twist, never a number.** §Currency, shops, and gear-lite:
##     "a small, distinct twist on the Bindle's moveset or a minor property ... never
##     a numeric upgrade". So there is no damage field, no reach number, no tier: a
##     staff head names a `moveset_twist` strategy id and the combat effect runner
##     owes the behaviour. A STAFF_HEAD without one is a validation error too - it
##     would be gear that does nothing, which is the treadmill by another name.
##
## The player-facing name is a translation key into `res://localization/items.csv`;
## no English lives on this resource (PROMPT.md, standing decision 6).

## What the item is (`ItemCategory`).
@export var category: ItemCategory.Id = ItemCategory.Id.CURIO

## The translation key for the item's name, e.g. `&"ITEM_POPCORN_NAME"`. Resolved
## through `res://localization/items.csv`; never English.
@export var name_key: StringName = &""

## What the item costs before a region, a Renown tier or a world-state touches it.
## Coins, never negative. Zero means "not for sale at this price" - a QUEST item.
@export var base_price: int = 0

## True when the item may not change how the Fool plays. Authored, and checked
## against `ItemCategory.is_cosmetic_only()`, so the doc's rule and the data cannot
## quietly disagree.
@export var cosmetic_only: bool = false

## STAFF_HEAD only: the id of the twist this head puts on the Bindle's moveset, e.g.
## `&"REACH_PLUS"`. A strategy id, not a number (see the class doc). What it *does*
## is owed to the combat effect runner; this is the hook it will be looked up by.
@export var moveset_twist: StringName = &""

## Where this item came from in the docs, or why it is a placeholder. Doc-only.
@export var source_ref: String = ""

## Authoring notes: what here is canon and what is a TBD placeholder. Doc-only.
@export var notes: String = ""


## True when this item is a staff head - the one category that changes the moveset.
func is_staff_head() -> bool:
	return category == ItemCategory.Id.STAFF_HEAD


## True when this item raises the White Rose's maximum petals.
func is_grafting() -> bool:
	return category == ItemCategory.Id.ROSE_GRAFTING


## Every problem with this item; empty means it is authored as the doc allows.
func validate() -> PackedStringArray:
	var errors := super()
	if name_key == &"":
		errors.append("%s has no name key" % _describe())
	if base_price < 0:
		errors.append("%s has a base price of %d" % [_describe(), base_price])
	if category < 0 or category >= ItemCategory.ALL.size():
		errors.append("%s is category %d, which is not one of the six" % [_describe(), category])
		return errors
	if ItemCategory.is_cosmetic_only(category) and not cosmetic_only:
		errors.append("%s is an %s and must be cosmetic only" % [
			_describe(), ItemCategory.name_key(category)
		])
	if cosmetic_only and moveset_twist != &"":
		errors.append("%s is cosmetic only and carries the twist %s" % [
			_describe(), moveset_twist
		])
	if is_staff_head() and moveset_twist == &"":
		errors.append("%s is a staff head with no moveset twist" % _describe())
	if not is_staff_head() and moveset_twist != &"":
		errors.append("%s is not a staff head but carries the twist %s" % [
			_describe(), moveset_twist
		])
	return errors
