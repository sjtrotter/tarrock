class_name DialogueCatalog
extends Resource

## Every conversation the game knows about, in one loadable resource.
##
## Hand-authored, like the graphs it holds (`docs/design/technical.md`
## §Generated vs. hand-authored: dialogue graphs are prose canon, so they are written
## rather than generated). `DialogueService` refuses to start anything this catalog
## does not list, and nothing mutates it at runtime - a definition is authored data
## (see `TarrockDefinition`).

## Every graph, in script order.
@export var entries: Array[DialogueGraph] = []

## Lazily built `graph id -> DialogueGraph` index. Definitions are immutable at
## runtime, so the index is built on first use and never invalidated.
var _index: Dictionary = {}


## The graph with this id, or `null` when the catalog does not list it.
func find(graph_id: StringName) -> DialogueGraph:
	if _index.size() != entries.size():
		_build_index()
	return _index.get(graph_id, null) as DialogueGraph


## True when this id is a conversation the game knows.
func has(graph_id: StringName) -> bool:
	return find(graph_id) != null


## Every graph id, in catalog order.
func ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for entry: DialogueGraph in entries:
		if entry != null:
			found.append(entry.id)
	return found


## Every graph belonging to one quest, in catalog order.
func graphs_for_quest(quest_id: StringName) -> Array[DialogueGraph]:
	var found: Array[DialogueGraph] = []
	for entry: DialogueGraph in entries:
		if entry != null and entry.quest_id == quest_id:
			found.append(entry)
	return found


## Every problem with the catalog as a whole, one string per problem.
##
## Each entry is checked, then the facts only the whole set can prove: no id twice,
## every `next_graph_id` resolves to another graph in this catalog and no chain of
## them rings back round to a graph it has already played, and every `EVENT` node
## raises an id `known_events` lists. Pass `QuestEvents.ALL`: without it the event
## half cannot be asked, and every caller in the game passes it.
func validate(known_events: Array[StringName] = []) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary = {}
	for index: int in entries.size():
		var entry := entries[index]
		if entry == null:
			errors.append("dialogue catalog entry %d is empty" % index)
			continue
		errors.append_array(entry.validate())
		errors.append_array(entry.unknown_events(known_events))
		if seen.has(entry.id):
			errors.append("dialogue catalog lists %s more than once" % entry.id)
		seen[entry.id] = true
	var in_reported_cycle: Dictionary = {}
	for entry: DialogueGraph in entries:
		if entry == null or entry.next_graph_id == &"":
			continue
		if not has(entry.next_graph_id):
			errors.append("%s chains into %s, which no graph defines" % [
				entry.id, entry.next_graph_id
			])
		elif entry.next_graph_id == entry.id:
			errors.append("%s chains into itself" % entry.id)
			in_reported_cycle[entry.id] = true
		else:
			errors.append_array(_chain_cycle_errors(entry, in_reported_cycle))
	return errors


## True when `validate()` finds nothing.
func is_valid(known_events: Array[StringName] = []) -> bool:
	return validate(known_events).is_empty()


## The one problem with the chain that starts at `entry`, or nothing.
##
## `DialogueService._finish()` starts `next_graph_id` the moment a graph ends, so a
## ring of chains - `A -> B -> A` as readily as `A -> A` - is an endless
## conversation the player cannot leave. The whole chain is followed rather than
## just the first hop, because a two-graph ring is exactly as fatal as a self-chain
## and is not visible from either graph on its own.
##
## `reported` is carried across entries so one ring is one problem: every graph on a
## ring is marked when it is found, and the graphs after it in the catalog skip it.
func _chain_cycle_errors(
	entry: DialogueGraph, reported: Dictionary
) -> PackedStringArray:
	var errors := PackedStringArray()
	var path := PackedStringArray()
	var on_path: Dictionary = {}
	var at := entry
	while at != null and at.next_graph_id != &"":
		if reported.has(at.id):
			return errors
		path.append(String(at.id))
		on_path[at.id] = true
		var next := find(at.next_graph_id)
		if next == null:
			return errors
		if on_path.has(next.id):
			for graph_id: String in path:
				reported[StringName(graph_id)] = true
			path.append(String(next.id))
			# Comma-joined rather than arrow-joined: a two-space string literal is
			# what the localization lint looks for, and a diagnostic list is not
			# worth widening its exemptions over.
			errors.append("dialogue chains in a ring that would never end: %s" % [
				", ".join(path)
			])
			return errors
		at = next
	return errors


func _build_index() -> void:
	_index.clear()
	for entry: DialogueGraph in entries:
		if entry != null:
			_index[entry.id] = entry
