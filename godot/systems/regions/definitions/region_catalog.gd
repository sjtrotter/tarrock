class_name RegionCatalog
extends Resource

## Every region the game knows about, in one loadable resource.
##
## Generated from `docs/design/world.md` §Regions by `godot/tools/gen_definitions.py`
## and loaded once by `RegionService`, which refuses to travel anywhere this catalog
## does not list. Nothing mutates it at runtime: a definition is authored data (see
## `TarrockDefinition`).
##
## The set is closed and the doc closes it: twenty-two regions, the Cliff (0) plus
## the Arcana's twenty-one, and `validate()` proves every card number 0-21 is present
## exactly once. That is what stops the Spread quietly losing a region - or growing a
## twenty-third that no card answers for.

## Every region definition, in card order: the Cliff first, then I to XXI.
@export var entries: Array[RegionDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The region with this id, or `null` when the catalog does not list it.
func find(region_id: StringName) -> RegionDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(region_id, null) as RegionDefinition


## True when this id is a region the game knows.
func has(region_id: StringName) -> bool:
	return find(region_id) != null


## The region with this card number, or `null`. 0 is the Cliff.
func find_by_card(card_number: int) -> RegionDefinition:
	for entry: RegionDefinition in entries:
		if entry != null and entry.card_number == card_number:
			return entry
	return null


## The region that authors this Waystation, or `null` when nobody does.
##
## The lookup fast travel and the defeat loop both run on: a Waystation id is all the
## save file carries, and this is what turns it back into somewhere to stand.
func find_by_waystation(waystation_id: StringName) -> RegionDefinition:
	for entry: RegionDefinition in entries:
		if entry != null and entry.has_waystation(waystation_id):
			return entry
	return null


## Every region id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: RegionDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every Waystation id in the Spread, in catalog order.
func waystation_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: RegionDefinition in entries:
		if entry == null:
			continue
		for waystation_id: StringName in entry.waystation_ids:
			found.append(waystation_id)
	return found


## Every region in one difficulty band, in catalog order.
func of_band(band: DifficultyBand.Id) -> Array[RegionDefinition]:
	var found: Array[RegionDefinition] = []
	for entry: RegionDefinition in entries:
		if entry != null and entry.difficulty_band == band:
			found.append(entry)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Checks each definition, then the facts only the whole set can prove: no id twice,
## no Waystation id twice, and every card number 0-21 exactly once. When
## `world_states` is supplied it also resolves every `unbinding_flag` against the
## matrix - a region awakened by a flag the matrix does not define would be a region
## the White Rose could never regrow in, and nothing else in the game would notice.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var cards: Dictionary = {}
	var waystations: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("region catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("region catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
		if cards.has(entry.card_number):
			errors.append("%s and %s are both card %d" % [
				cards[entry.card_number], entry.id, entry.card_number
			])
		cards[entry.card_number] = entry.id
		for waystation_id: StringName in entry.waystation_ids:
			if waystations.has(waystation_id):
				errors.append("%s and %s both author the Waystation %s" % [
					waystations[waystation_id], entry.id, waystation_id
				])
			waystations[waystation_id] = entry.id
		if world_states != null and entry.unbinding_flag != &"":
			if world_states.find(entry.unbinding_flag) == null:
				errors.append("%s names %s, which no world-state row defines" % [
					entry.id, entry.unbinding_flag
				])
	for card_number: int in range(0, 22):
		if not cards.has(card_number):
			errors.append("no region carries card %d" % card_number)
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	for entry: RegionDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
