class_name DialogueGraph
extends TarrockDefinition

## One authored conversation, as data.
##
## `docs/design/technical.md`'s data-model row for `DialogueGraph` is the whole
## contract in one line: a node graph resource whose "branch conditions are
## WorldState queries, never hardcoded booleans" and where "every line is a
## translation key". Both are structural here - a `BRANCH` node has no place to put
## a boolean, and a `LINE` has no place to put a sentence.
##
## A graph is hand-authored (technical.md §Generated vs. hand-authored) and cites the
## script section it was lifted from in `source_ref`, so a reviewer can check it
## against `docs/quests/` without guessing. One graph is one beat of a quest script:
## a `CUT SCENE` block, a `### CHOICE DIALOG` table with its follow-up threads, or a
## `**... Random Lines**` list. Beats that run straight into one another chain
## through `next_graph_id` rather than through scene code.
##
## Nothing here decides anything about the world. `DialogueService` walks a graph;
## quests are still the only writer of world state, and the only path from a
## conversation to a permanent change is an `EVENT` node the scene forwards to
## `QuestService.raise()`.

## The quest this conversation belongs to, e.g. `&"MQ00"` (`QuestIds`).
@export var quest_id: StringName = &""

## The script section this graph was authored from, e.g.
## `docs/quests/main/MQ00-the-leap.md §The Cliff's Edge`. Documentation for
## reviewers and never displayed - one of the doc-only properties the localization
## lint exempts.
@export var source_ref: String = ""

## Where the conversation begins.
@export var start_node: StringName = &""

## Every node, in authoring order.
@export var nodes: Array[DialogueNode] = []

## The graph that begins the moment this one ends, or `&""` when the conversation
## simply stops. This is how a script's "the line, then the table" reads as data: the
## Querent's `Someone made that...` beat names the wooden-dog choice, and the scene
## starts one thing rather than sequencing two.
@export var next_graph_id: StringName = &""

## Lazily built `node id -> DialogueNode`. Definitions are immutable at runtime, so
## the index is built once and never invalidated.
var _index: Dictionary = {}


## The node with this id, or `null` when the graph has none.
func find_node(node_id: StringName) -> DialogueNode:
	if _index.size() != nodes.size():
		_build_index()
	return _index.get(node_id, null) as DialogueNode


## True when the graph holds a node with this id.
func has_node_id(node_id: StringName) -> bool:
	return find_node(node_id) != null


## Every translation key this graph can put on screen, in authoring order, without
## repeats: every line, every pool entry, every choice option.
func text_keys() -> PackedStringArray:
	var found := PackedStringArray()
	for node: DialogueNode in nodes:
		if node == null:
			continue
		if node.text_key != &"" and not found.has(String(node.text_key)):
			found.append(String(node.text_key))
		for key: String in node.text_keys:
			if not key.is_empty() and not found.has(key):
				found.append(key)
		for option: DialogueOption in node.options:
			if option != null and option.text_key != &"" and not found.has(String(option.text_key)):
				found.append(String(option.text_key))
	return found


## Every choice node in the graph, in authoring order. The style lint's subject: the
## ≤ 12-word rule is about the Fool's *selectable* lines, not about narration.
func choice_nodes() -> Array[DialogueNode]:
	var found: Array[DialogueNode] = []
	for node: DialogueNode in nodes:
		if node != null and node.kind == DialogueNode.Kind.CHOICE:
			found.append(node)
	return found


## Every speaker this graph gives a line to, in authoring order, without repeats.
func speaker_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for node: DialogueNode in nodes:
		if node != null and node.speaker != &"" and not found.has(node.speaker):
			found.append(node.speaker)
	return found


## Every `QuestEvents` id this graph raises, in authoring order, without repeats.
func event_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for node: DialogueNode in nodes:
		if node == null:
			continue
		if node.event != &"" and not found.has(node.event):
			found.append(node.event)
		for option: DialogueOption in node.options:
			if option == null or option.raises_event == &"":
				continue
			if not found.has(option.raises_event):
				found.append(option.raises_event)
	return found


## Every problem with this graph, one string per problem; empty means valid.
##
## What only the whole graph can prove: it names a quest and a source, it starts
## somewhere real, no node id is used twice, every node holds its own kind's fields,
## and every exit any node offers resolves to a node in this graph.
##
## Two questions are deliberately NOT asked here, because they need something outside
## the graph: whether an `EVENT` node raises an id `QuestEvents` knows (ask
## `unknown_events()`), and whether every `text_key` has English behind it (the
## localization test asks `TranslationServer`).
##
## Cycle detection is also deliberately absent. A loop with no `CHOICE` or `END` in
## it would hang the runner, but a loop *through* a choice table is exactly what an
## exhaustible table is, and separating the two needs a reachability analysis worth
## more than it saves at this size. `DialogueService` bounds its walk instead
## (`DialogueService.MAX_WALK_STEPS`), so a bad graph fails loudly rather than hangs.
func validate() -> PackedStringArray:
	var errors := super()
	if quest_id == &"":
		errors.append("%s names no quest" % _describe())
	if source_ref.is_empty():
		errors.append("%s cites no script section" % _describe())
	var seen: Dictionary = {}
	for node: DialogueNode in nodes:
		if node == null:
			errors.append("%s has an empty node slot" % _describe())
			continue
		errors.append_array(node.validate())
		if seen.has(node.id):
			errors.append("%s has two nodes called %s" % [_describe(), node.id])
		seen[node.id] = true
	if start_node == &"":
		errors.append("%s has no start node" % _describe())
	elif not has_node_id(start_node):
		errors.append("%s starts at %s, which is not a node" % [_describe(), start_node])
	for node: DialogueNode in nodes:
		if node == null:
			continue
		for exit_id: StringName in node.exits():
			if not has_node_id(exit_id):
				errors.append("%s: %s leads to %s, which is not a node" % [
					_describe(), node.id, exit_id
				])
	return errors


## Every `EVENT` id this graph raises that `known_events` does not list.
##
## An event nobody knows is a typo that would be swallowed silently forever -
## `QuestService.raise()` ignores an event no quest listens for, by design - so this
## is the only place it can be caught. Pass `QuestEvents.ALL`.
func unknown_events(known_events: Array[StringName]) -> PackedStringArray:
	var errors := PackedStringArray()
	for event: StringName in event_ids():
		if not known_events.has(event):
			errors.append("%s raises %s, which is not a QuestEvents id" % [_describe(), event])
	return errors


func _build_index() -> void:
	_index.clear()
	for node: DialogueNode in nodes:
		if node != null:
			_index[node.id] = node
