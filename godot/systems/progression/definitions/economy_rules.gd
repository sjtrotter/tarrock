class_name EconomyRules
extends TarrockDefinition

## Every number the Coin economy runs on, in one hand-authored table.
##
## HAND-AUTHORED at `res://data/progression/economy_rules.tres`, from
## `docs/design/progression.md` §Currency, shops, and gear-lite and §Renown. It is
## not generated and cannot be: those sections fix *shapes* and almost no figures.
## What is canon and what is tuning is written down in `notes` on the resource, and
## the split is the point of this class - every TBD in the doc is one field here that
## a balance pass turns, rather than a constant somebody typed into a service.
##
## Canon, and structural rather than tunable:
##
##   * prices vary by region, by the Fool's Renown with the LOCAL suit, and by
##     world-states - all three are read by `EconomyService.price_of()`;
##   * `WS_EMPRESS_UNBOUND` halves FOOD Spread-wide. That lives in `price_rules` as
##     one `PriceRule`, because the doc says pricing "simply reads that state";
##   * roughly 8-10 staff heads exist across the Spread (`max_staff_heads_hint`);
##   * a deed moves each of the four suits by that suit's own reaction (§Renown).
##
## Tuning, and TBD by the doc's own admission: the starting purse, every renown price
## modifier, the default region multiplier, and the four Renown deltas. §Renown names
## no number anywhere - it gives four reactions and a five-tier ladder - so
## `renown_delta_for()` is where "Renown up" becomes points, and it is the only place
## it becomes points.
##
## Shops do not buy back. `progression.md` §Currency, shops, and gear-lite: Coins are
## found, looted, earned through quests, and spent - selling is not canon, so there is
## no sell-price field here to tune.

## The Renown a NEUTRAL reaction is worth. Zero, and not a field: "the suit does not
## care" is the one magnitude that is canon rather than tuning, and a NEUTRAL that
## could be turned to 1 would make an indifferent culture quietly approve.
const NEUTRAL_DELTA := 0

## What `renown_delta_for()` answers for a reaction this build does not have.
const NO_DELTA := 0

## Coins the Fool starts a playthrough with. `docs/design/progression.md` §Player
## growth over a playthrough, hour 1: the Fool has "the Bindle, an empty Rose beyond
## its 3 starting petals, no Trump yet, and no reputation anywhere" - and nothing
## else, so nothing in the purse either.
@export var starting_coins: int = 0

## What a price is multiplied by at each rung of the Renown ladder, tier 1 (Stranger)
## first. Five entries, one per `RenownLadder.TIER_COUNT`. Standing with the LOCAL
## suit is what a shop reads (§Currency, shops, and gear-lite); the numbers are TBD.
@export var renown_price_multipliers: PackedFloat32Array = PackedFloat32Array()

## What a shop that names no multiplier of its own charges. Prices "vary by region"
## and this is the region that has not been tuned yet.
@export var default_region_price_multiplier: float = 1.0

## The world-states that price goods, as data (see `PriceRule`). The canon one is
## `WS_EMPRESS_UNBOUND` x FOOD x 0.5, Spread-wide.
@export var price_rules: Array[PriceRule] = []

## What a deed is worth to a suit that prizes it ("Renown up"). TBD - §Renown states
## the reaction and no number.
@export var renown_delta_up: int = 8

## What a deed is worth to a suit that mildly approves ("Slight up"). TBD.
@export var renown_delta_slight_up: int = 3

## What a deed costs with a suit that mildly disapproves ("Slight down"). TBD.
@export var renown_delta_slight_down: int = -3

## What a deed costs with a suit that holds it against the Fool ("Renown down"). No
## row of §Renown's table uses this reaction yet; the ladder is symmetric, so the
## number is here for the day one does. TBD.
@export var renown_delta_down: int = -8

## Roughly how many staff heads exist across the Spread. INFORMATIONAL: §Currency,
## shops, and gear-lite says "roughly 8-10", so nothing refuses an eleventh - this is
## the figure a content audit checks the authored set against.
@export var max_staff_heads_hint: int = 10

## The regions a shop may stand in - `docs/design/progression.md`: Coins are "spent
## at shops in every settled region". `world.md` §Regions never uses the word
## "settled", so this list is a READING of it and is TBD content design; `notes`
## records the reading region by region.
@export var settled_region_ids: Array[StringName] = []

## The doc sections these numbers were authored from. Doc-only.
@export var doc_ref: String = ""

## Authoring notes: what is canon here and what is a TBD placeholder. Doc-only.
@export var notes: String = ""


## The Renown a reaction is worth, in points. The ONE place a word in §Renown's deed
## table becomes a number; `EconomyService.record_deed()` is the only caller.
func renown_delta_for(reaction: Reaction.Id) -> int:
	match reaction:
		Reaction.Id.UP:
			return renown_delta_up
		Reaction.Id.SLIGHT_UP:
			return renown_delta_slight_up
		Reaction.Id.NEUTRAL:
			return NEUTRAL_DELTA
		Reaction.Id.SLIGHT_DOWN:
			return renown_delta_slight_down
		Reaction.Id.DOWN:
			return renown_delta_down
	return NO_DELTA


## What a price is multiplied by at this rung of the ladder (1..5). A tier this table
## does not cover charges full price rather than guessing.
func renown_multiplier_for_tier(tier: int) -> float:
	var index := tier - RenownLadder.FIRST_TIER
	if index < 0 or index >= renown_price_multipliers.size():
		return 1.0
	return renown_price_multipliers[index]


## True when a shop may stand in this region (see `settled_region_ids`).
func is_settled(region_id: StringName) -> bool:
	return settled_region_ids.has(region_id)


## Every price rule that prices `item` in `region_id`, given what has fired.
##
## `world_state` is asked rather than a set of ids being passed in, because "is this
## flag fired" is `WorldStateService`'s question and duplicating it here would give
## the game two answers to it.
func price_rules_for(
	item: ItemDefinition, region_id: StringName, world_state: WorldStateService
) -> Array[PriceRule]:
	var found: Array[PriceRule] = []
	if item == null:
		return found
	for rule: PriceRule in price_rules:
		if rule == null:
			continue
		var fired := world_state != null and world_state.is_fired(rule.when_fired)
		if rule.applies_to(item, region_id, fired):
			found.append(rule)
	return found


## Every problem with the table on its own; empty means it is a usable economy.
##
## The cross-references - does the matrix define the flag a price rule waits on, does
## the region catalog know the regions it calls settled - need catalogs this resource
## does not hold, so they live in `validate_against()`, exactly as `EnemyRules` keeps
## its combat cross-check apart from its own.
func validate() -> PackedStringArray:
	var errors := super()
	if starting_coins < 0:
		errors.append("%s starts the Fool with %d coins" % [_describe(), starting_coins])
	if renown_price_multipliers.size() != RenownLadder.TIER_COUNT:
		errors.append("%s has %d renown price modifiers, not %d" % [
			_describe(), renown_price_multipliers.size(), RenownLadder.TIER_COUNT
		])
	for index: int in renown_price_multipliers.size():
		if renown_price_multipliers[index] <= 0.0:
			errors.append("%s prices tier %d at %f" % [
				_describe(), index + RenownLadder.FIRST_TIER, renown_price_multipliers[index]
			])
	if default_region_price_multiplier <= 0.0:
		errors.append("%s multiplies a region's prices by %f" % [
			_describe(), default_region_price_multiplier
		])
	if renown_delta_up <= 0 or renown_delta_slight_up <= 0:
		errors.append("%s pays nothing for a deed a suit prizes" % _describe())
	if renown_delta_slight_up >= renown_delta_up:
		errors.append("%s pays %d for a slight approval and %d for a full one" % [
			_describe(), renown_delta_slight_up, renown_delta_up
		])
	if renown_delta_slight_down >= 0 or renown_delta_down >= 0:
		errors.append("%s charges nothing for a deed a suit dislikes" % _describe())
	if renown_delta_down >= renown_delta_slight_down:
		errors.append("%s charges %d for a slight disapproval and %d for a full one" % [
			_describe(), renown_delta_slight_down, renown_delta_down
		])
	if max_staff_heads_hint <= 0:
		errors.append("%s expects %d staff heads" % [_describe(), max_staff_heads_hint])
	if settled_region_ids.is_empty():
		errors.append("%s knows no settled region for a shop to stand in" % _describe())
	var seen_regions: Dictionary = {}
	for region_id: StringName in settled_region_ids:
		if seen_regions.has(region_id):
			errors.append("%s lists %s as settled twice" % [_describe(), region_id])
		seen_regions[region_id] = true
	for rule: PriceRule in price_rules:
		if rule == null:
			errors.append("%s holds an empty price rule" % _describe())
			continue
		errors.append_array(rule.validate())
	return errors


## Every problem with the table, including the ones only the catalogs can find: a
## price rule waiting on a flag `world.md` does not define is a price change that
## would never happen, and a settled region no catalog knows is a market nobody can
## walk to. Neither is visible from this resource alone.
func validate_against(
	world_states: WorldStateCatalog, regions: RegionCatalog
) -> PackedStringArray:
	var errors := validate()
	for region_id: StringName in settled_region_ids:
		if regions != null and not regions.has(region_id):
			errors.append("%s calls %s settled, and no region has that id" % [
				_describe(), region_id
			])
	for rule: PriceRule in price_rules:
		if rule == null:
			continue
		if world_states != null and world_states.find(rule.when_fired) == null:
			errors.append("a price rule waits on %s, which no world-state row defines" % rule.when_fired)
		for region_id: StringName in rule.region_ids:
			if regions != null and not regions.has(region_id):
				errors.append("a price rule on %s names the region %s, which does not exist" % [
					rule.when_fired, region_id
				])
	return errors
