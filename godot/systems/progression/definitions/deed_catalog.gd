class_name DeedCatalog
extends Resource

## Every deed `docs/design/progression.md` §Renown's table defines, in one resource.
##
## GENERATED at `res://data/progression/deeds/catalog.tres` by
## `godot/tools/gen_definitions.py`, in the doc's own row order, and loaded once by
## `EconomyService` - which is the only thing that turns a deed into Renown.

## Every deed definition, in the doc's row order.
@export var entries: Array[DeedDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The deed with this id, or `null` when the catalog does not list it.
func find(deed_id: StringName) -> DeedDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(deed_id, null) as DeedDefinition


## True when this id is a deed the game knows.
func has(deed_id: StringName) -> bool:
	return find(deed_id) != null


## Every deed id, in doc order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: DeedDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Checks each deed, then the one fact only the whole set can prove: no id twice. A
## deed listed twice would be a doc row that generated itself into two files, and
## `record_deed()` would answer with whichever came first.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("deed catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("deed catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	for entry: DeedDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
