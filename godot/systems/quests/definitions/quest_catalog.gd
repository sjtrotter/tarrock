class_name QuestCatalog
extends Resource

## Every quest the game knows about, in one loadable resource.
##
## Generated from every `docs/quests/**/*.md` frontmatter block by
## `godot/tools/gen_definitions.py` and loaded once by `QuestService`, which refuses
## to start anything this catalog does not list. Nothing mutates it at runtime: a
## definition is authored data (see `TarrockDefinition`).

## Every quest, in doc order (main quests by card number, then side quests by id).
@export var entries: Array[QuestDefinition] = []

## Lazily built `quest id -> definition` index. Definitions are immutable at
## runtime, so the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The quest with this id, or `null` when the catalog does not list it.
func find(quest_id: StringName) -> QuestDefinition:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(quest_id, null) as QuestDefinition


## True when this id is a quest the game knows.
func has(quest_id: StringName) -> bool:
	return find(quest_id) != null


## Every quest id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: QuestDefinition in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Each entry is checked, then the facts only the whole set can prove: no id twice,
## and every id a quest *names* resolves - a `requires` entry is either a world-state
## flag the matrix defines or another quest in this catalog, a `fires` entry is a
## flag, a branch group's members are BRANCH flags of that same group, and a graph
## only records branch choices its own quest is allowed to make.
##
## `world_states` is the generated world-state catalog. Pass it: without it the
## flag-existence half cannot be asked, and the drift tests always pass it. The
## parameter is optional only so a caller holding a synthetic catalog and no matrix
## can still ask the shape questions.
func validate(world_states: WorldStateCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("quest catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		if seen.has(entry.id):
			errors.append("quest catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	for entry: QuestDefinition in entries:
		if entry != null:
			errors.append_array(_reference_errors(entry, world_states))
	return errors


## True when `validate()` finds nothing.
func is_valid(world_states: WorldStateCatalog = null) -> bool:
	return validate(world_states).is_empty()


## Every id `entry` names that does not resolve.
func _reference_errors(
	entry: QuestDefinition, world_states: WorldStateCatalog
) -> PackedStringArray:
	var errors := PackedStringArray()
	for required: StringName in entry.required_states:
		var is_flag := world_states != null and world_states.has(required)
		if not is_flag and not has(required):
			errors.append("%s requires %s, which is neither a flag nor a quest" % [
				entry.id, required
			])
	for fired: StringName in entry.fired_states:
		if world_states != null and not world_states.has(fired):
			errors.append("%s fires %s, which no matrix row defines" % [entry.id, fired])
	for group: QuestBranchGroup in entry.branch_groups:
		if group == null:
			continue
		for flag: StringName in group.flags:
			if world_states == null:
				continue
			var definition := world_states.find(flag)
			if definition == null:
				errors.append("%s branches on %s, which no matrix row defines" % [entry.id, flag])
				continue
			if definition.is_unbinding():
				errors.append("%s branches on %s, which is an unbinding" % [entry.id, flag])
			elif definition.branch_group != group.group_id:
				errors.append("%s puts %s in group %s; the matrix puts it in %s" % [
					entry.id, flag, group.group_id, definition.branch_group
				])
	if entry.graph != null:
		for flag: StringName in entry.graph.chosen_branch_flags():
			if entry.branch_group_for(flag) == null:
				errors.append("%s's graph chooses %s, which is in none of its groups" % [
					entry.id, flag
				])
	return errors


func _build_index() -> void:
	_index.clear()
	for entry: QuestDefinition in entries:
		if entry != null:
			_index[entry.id] = entry
