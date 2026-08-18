class_name PriceRule
extends Resource

## One world-state's standing effect on what a category of goods costs.
##
## `docs/design/progression.md` §Currency, shops, and gear-lite is canon and states
## the rule this class exists to keep honest: "a shop's stock and prices are a live
## reflection of the world-state matrix in `world.md`, not a static price list", and
## it gives the worked example - "food prices halve Spread-wide on
## `WS_EMPRESS_UNBOUND` - shop pricing simply reads that state".
##
## So the example is DATA, not a branch in `EconomyService`. One `PriceRule` in
## `economy_rules.tres` says `WS_EMPRESS_UNBOUND` x FOOD x 0.5, and the day the
## Empress's row in `world.md` §World-state matrix grows a sibling, the change is a
## row in a resource that a reviewer can read against the matrix - never a new `if`.
##
## A rule is **Spread-wide** unless `region_ids` names regions: the doc's own example
## is Spread-wide, and a rule that quietly applied in one town would be a price the
## matrix does not explain.

## The `WS_*` flag that turns this rule on. It never turns off again: a flag can
## never be un-fired (`docs/design/world.md`), so neither can a price change.
@export var when_fired: StringName = &""

## The category of goods the rule prices.
@export var category: ItemCategory.Id = ItemCategory.Id.FOOD

## What the price is multiplied by while the flag is fired. 0.5 halves; 2.0 doubles.
@export var multiplier: float = 1.0

## The regions this rule applies in. EMPTY MEANS SPREAD-WIDE, which is what the
## doc's own example is; a rule that names regions applies only in those.
@export var region_ids: Array[StringName] = []

## The doc section - matrix row and progression rule - this was read from. Doc-only.
@export var doc_ref: String = ""


## True when this rule prices `item` in `region_id` with the world in this state.
func applies_to(
	item: ItemDefinition, region_id: StringName, fired: bool
) -> bool:
	if not fired or item == null:
		return false
	if item.category != category:
		return false
	return region_ids.is_empty() or region_ids.has(region_id)


## True when the rule prices everywhere rather than in named regions.
func is_spread_wide() -> bool:
	return region_ids.is_empty()


## Every problem with this rule; empty means it is a usable price rule.
##
## `world_states` resolves the flag when it is supplied: a rule waiting on a flag the
## matrix does not define is a price change that would never happen, and nothing else
## in the game would notice.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if when_fired == &"":
		errors.append("a price rule names no world-state flag")
	elif world_states != null and world_states.find(when_fired) == null:
		errors.append("a price rule waits on %s, which no world-state row defines" % when_fired)
	if category < 0 or category >= ItemCategory.ALL.size():
		errors.append("a price rule names category %d, which is not one of the six" % category)
	if multiplier <= 0.0:
		errors.append("the price rule on %s multiplies by %f" % [when_fired, multiplier])
	return errors
