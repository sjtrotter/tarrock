class_name NpcCatalog
extends Resource

## Every named NPC the game knows, in one loadable resource.
##
## HAND-AUTHORED at `res://data/npc/profiles/catalog.tres` - see `NpcIds` for why
## `characters.md` §Recurring named NPCs cannot be parsed into this.
##
## The set is NOT closed, deliberately, and `npc-system.md` §Named vs. ambient NPCs is
## why: named NPCs are "`characters.md` recurring cast + quest-promoted NPCs (an ambient
## Minor a quest gives a name and arc to)". A quest that promotes somebody adds a
## profile here, so counting these against a doc's list would fight the system's own
## growth path.

## Every profile, in `NpcIds.ALL`'s order.
@export var entries: Array[NpcProfile] = []

## Lazily built `id -> profile` index. Definitions are immutable at runtime.
var _index: Dictionary = {}


## The profile with this id, or `null` when nobody has it.
func find(npc_id: StringName) -> NpcProfile:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(npc_id, null) as NpcProfile


## True when this id is a named NPC the game knows.
func has(npc_id: StringName) -> bool:
	return find(npc_id) != null


## Every named NPC id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: NpcProfile in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Everyone who lives in this region, in catalog order.
func of_region(region_id: StringName) -> Array[NpcProfile]:
	var found: Array[NpcProfile] = []
	for entry: NpcProfile in entries:
		if entry != null and entry.home_region == region_id:
			found.append(entry)
	return found


## Every problem with the catalog as a whole, one string per problem.
func validate(regions: RegionCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("npc catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		errors.append_array(entry.validate_against(regions))
		if seen.has(entry.id):
			errors.append("npc catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	return errors


# --- Internals ----------------------------------------------------------------


func _build_index() -> void:
	_index.clear()
	for entry: NpcProfile in entries:
		if entry != null:
			_index[entry.id] = entry
