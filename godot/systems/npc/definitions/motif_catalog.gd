class_name MotifCatalog
extends Resource

## Every motif the Fool's Reading can be asked for, in one loadable resource.
##
## GENERATED from `docs/design/world.md` §The Fool's Reading by
## `godot/tools/gen_definitions.py`, and the set is the doc's own: the five starter
## motifs, in the table's order. §The Fool's Reading says "quests and the NPC system
## may add more, locally", so this is deliberately not closed the way the region
## catalog is - a sixth row in the doc is a sixth motif here, and nothing counts them.

## Every motif, in the doc's table order.
@export var entries: Array[ReadingMotif] = []

## Lazily built `id -> motif` index. Definitions are immutable at runtime, so the index
## is built on first use and never invalidated.
var _index: Dictionary = {}


## The motif with this id, or `null` when the catalog does not list it.
func find(motif_id: StringName) -> ReadingMotif:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(motif_id, null) as ReadingMotif


## True when this id is a motif the game knows.
func has(motif_id: StringName) -> bool:
	return find(motif_id) != null


## Every motif id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: ReadingMotif in entries:
		if entry != null:
			found.append(entry.id)
	return found


## True when the Reading, as it stands, has the shape this motif names. An id the
## catalog does not list is an error and reads as false: a bark waiting on a motif
## nobody defined must never be said.
func matches(motif_id: StringName, reading: Array[StringName]) -> bool:
	var motif := find(motif_id)
	if motif == null:
		push_error("no reading motif with id %s" % motif_id)
		return false
	return motif.matches(reading)


## Every problem with the catalog as a whole, one string per problem.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("motif catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		errors.append_array(entry.validate_against(world_states))
		if seen.has(entry.id):
			errors.append("motif catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	for entry: ReadingMotif in entries:
		if entry != null:
			_index[entry.id] = entry
