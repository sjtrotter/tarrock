class_name ItemCatalog
extends Resource

## Every item the game knows about, in one loadable resource.
##
## Hand-authored at `res://data/progression/items/catalog.tres` and loaded once by
## `EconomyService`, which refuses to price, stock, buy, sell or equip anything this
## catalog does not list. Nothing mutates it at runtime: a definition is authored
## data (see `TarrockDefinition`).

## Every item definition, in authoring order.
@export var entries: Array[ItemDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The item with this id, or `null` when the catalog does not list it.
func find(item_id: StringName) -> ItemDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(item_id, null) as ItemDefinition


## True when this id is an item the game knows.
func has(item_id: StringName) -> bool:
	return find(item_id) != null


## Every item id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: ItemDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every item of one category, in catalog order.
func of_category(category: ItemCategory.Id) -> Array[ItemDefinition]:
	var found: Array[ItemDefinition] = []
	for entry: ItemDefinition in entries:
		if entry != null and entry.category == category:
			found.append(entry)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Checks each item, then the facts only the whole set can prove: no id twice, no
## name key twice (two items sharing a key would be two things with one name on
## screen), and no two staff heads claiming the same moveset twist - which would be
## the "distinct twist" rule (§Currency, shops, and gear-lite) broken in data.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var keys: Dictionary = {}
	var twists: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("item catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("item catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
		if entry.name_key != &"":
			if keys.has(entry.name_key):
				errors.append("%s and %s share the name key %s" % [
					keys[entry.name_key], entry.id, entry.name_key
				])
			keys[entry.name_key] = entry.id
		if entry.moveset_twist == &"":
			continue
		if twists.has(entry.moveset_twist):
			errors.append("%s and %s both twist the Bindle with %s" % [
				twists[entry.moveset_twist], entry.id, entry.moveset_twist
			])
		twists[entry.moveset_twist] = entry.id
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	for entry: ItemDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
