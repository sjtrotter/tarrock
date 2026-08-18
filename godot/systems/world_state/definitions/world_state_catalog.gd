class_name WorldStateCatalog
extends Resource

## Every world-state flag the game knows about, in one loadable resource.
##
## Generated from `docs/design/world.md` §World-state matrix by
## `godot/tools/gen_definitions.py` and loaded once by `WorldStateService`, which
## refuses to fire anything this catalog does not list. Nothing mutates it at
## runtime: a definition is authored data (see `TarrockDefinition`).

## The matrix's rows plus the branch flags its Effect cells name, in doc order.
@export var entries: Array[WorldStateDefinition] = []

## Lazily built `id -> definition` index. Definitions are immutable at runtime, so
## the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The definition with this id, or `null` when the catalog does not list it.
func find(state_id: StringName) -> WorldStateDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(state_id, null) as WorldStateDefinition


## True when this id is a flag the game knows.
func has(state_id: StringName) -> bool:
	return find(state_id) != null


## Every unbinding flag's id, ordered by card number (MQ01 first, MQ21 last).
func unbinding_ids() -> Array[StringName]:
	var ordered: Array[WorldStateDefinition] = []
	for entry: WorldStateDefinition in entries:
		if entry != null and entry.is_unbinding():
			ordered.append(entry)
	ordered.sort_custom(
		func(left: WorldStateDefinition, right: WorldStateDefinition) -> bool:
			return left.arcana_number < right.arcana_number
	)
	var ids: Array[StringName] = []
	for entry: WorldStateDefinition in ordered:
		ids.append(entry.id)
	return ids


## Every branch flag id belonging to `group`, in doc order.
func branch_group_members(group: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: WorldStateDefinition in entries:
		if entry != null and not entry.is_unbinding() and entry.branch_group == group:
			ids.append(entry.id)
	return ids


## Every problem with the catalog as a whole, one string per problem.
##
## Checks each entry, then the three facts only the whole set can prove: no id
## appears twice, every card number 1..21 is used exactly once, and no branch group
## has fewer than two members (a choice with one option is not a choice).
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	var by_arcana: Dictionary = {}
	var group_sizes: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
		if entry.is_unbinding():
			if by_arcana.has(entry.arcana_number):
				errors.append("card number %d is claimed by %s and %s" % [
					entry.arcana_number, by_arcana[entry.arcana_number], entry.id
				])
			by_arcana[entry.arcana_number] = entry.id
		elif entry.branch_group != &"":
			group_sizes[entry.branch_group] = int(group_sizes.get(entry.branch_group, 0)) + 1
	for number: int in range(
		WorldStateDefinition.FIRST_ARCANA, WorldStateDefinition.LAST_ARCANA + 1
	):
		if not by_arcana.has(number):
			errors.append("no unbinding flag carries card number %d" % number)
	for group: StringName in group_sizes:
		if int(group_sizes[group]) < 2:
			errors.append("branch group %s has only one member" % group)
	return errors


func _build_index() -> void:
	_index.clear()
	for entry: WorldStateDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
