class_name RenownLadder
extends TarrockDefinition

## The five-tier standing ladder every suit uses.
##
## `docs/design/progression.md` §Renown owns the tiers and their order (Stranger,
## Known, Welcome, Honored, Fabled) and states that all four suits share the same
## ladder. The **numeric** thresholds are not canon - they are tuning - so the
## generated resource carries placeholders and says so in `notes`.
##
## Tier names are stored so the localization key can be derived from the doc's own
## word; the displayed text comes from the translation table, never from here.

## How many tiers the ladder has.
const TIER_COUNT := 5

## The lowest tier number. Tiers are 1-based, as the doc's table is.
const FIRST_TIER := 1

## Prefix of the translation key a tier resolves to, e.g. `RENOWN_TIER_HONORED`.
const TIER_KEY_PREFIX := "RENOWN_TIER_"

## The doc's tier words, lowest standing first. Used to derive the tier's
## translation key; never displayed.
@export var tier_names: PackedStringArray = PackedStringArray()

## The Renown value at which each tier begins, lowest first. Entry 0 is always 0.
@export var tier_min_values: PackedInt32Array = PackedInt32Array()

## The doc section this ladder was generated from.
@export var doc_ref: String = ""

## Authoring notes: what in here is canon and what is a placeholder.
@export var notes: String = ""


## The tier (1..`TIER_COUNT`) a Renown value falls in.
func tier_for(value: int) -> int:
	var tier := FIRST_TIER
	for index: int in tier_min_values.size():
		if value >= tier_min_values[index]:
			tier = index + FIRST_TIER
	return tier


## The translation key naming a tier, e.g. `&"RENOWN_TIER_FABLED"`. An out-of-range
## tier returns `&""` rather than guessing.
func tier_name_key(tier: int) -> StringName:
	var index := tier - FIRST_TIER
	if index < 0 or index >= tier_names.size():
		return &""
	return StringName(TIER_KEY_PREFIX + tier_names[index].to_upper())


## Every problem with the ladder; empty means it is a usable five-tier ladder.
func validate() -> PackedStringArray:
	var errors := super()
	if tier_names.size() != TIER_COUNT:
		errors.append("%s has %d tier names, not %d" % [
			_describe(), tier_names.size(), TIER_COUNT
		])
	if tier_min_values.size() != TIER_COUNT:
		errors.append("%s has %d tier thresholds, not %d" % [
			_describe(), tier_min_values.size(), TIER_COUNT
		])
	if tier_min_values.size() > 0 and tier_min_values[0] != 0:
		errors.append("%s starts its first tier at %d, not 0" % [_describe(), tier_min_values[0]])
	for index: int in range(1, tier_min_values.size()):
		if tier_min_values[index] <= tier_min_values[index - 1]:
			errors.append("%s tier %d starts at %d, not above tier %d at %d" % [
				_describe(),
				index + FIRST_TIER,
				tier_min_values[index],
				index - 1 + FIRST_TIER,
				tier_min_values[index - 1],
			])
	for name_index: int in tier_names.size():
		if tier_names[name_index].strip_edges().is_empty():
			errors.append("%s tier %d has no name" % [_describe(), name_index + FIRST_TIER])
	return errors
