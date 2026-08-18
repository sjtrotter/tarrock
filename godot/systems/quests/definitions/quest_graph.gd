class_name QuestGraph
extends Resource

## A quest's hand-authored state machine: its states, and the event-gated edges
## between them.
##
## `docs/design/technical.md` §Quests at runtime (Godot) splits a quest in two, and
## this is the half a person writes. The other half - id, title key, arcana, region,
## `requires`/`fires`/`branches` - is **generated** from the quest doc's frontmatter
## by `godot/tools/gen_definitions.py`, which links a `QuestDefinition` to the graph
## file of the same name when one exists (`res://data/quests/graphs/<ID>.tres`).
## Authoring a quest is therefore writing its graph; regenerating never touches it.
##
## The beats come from the quest doc's GAMEPLAY blocks - each state's `notes` cites
## the slugline it was lifted from, so a reviewer can check the graph against
## `docs/quests/` without guessing.
##
## A graph decides nothing about the world. It says which event moves the quest and
## under which world-state conditions; `QuestService` is what applies a move, and
## the quest's `fires` commit only on reaching a state marked `is_complete`.

## The quest this graph belongs to, e.g. `&"MQ00"`. Checked against the
## `QuestDefinition` that links it.
@export var quest_id: StringName = &""

## The state a quest is put into by `QuestService.start()`.
@export var initial_state: StringName = &""

## Every state in the graph, in authoring order.
@export var states: Array[QuestState] = []

## Every edge, in authoring order. Order is the tie-break when two edges are legal
## at once, so the runner is deterministic.
@export var transitions: Array[QuestTransition] = []

## Lazily built `state id -> QuestState`. Definitions are immutable at runtime, so
## the index is built once and never invalidated.
var _index: Dictionary = {}


## The state with this id, or `null` when the graph has no such state.
func find_state(state_id: StringName) -> QuestState:
	if _index.size() != states.size():
		_build_index()
	return _index.get(state_id, null) as QuestState


## True when the graph has a state with this id.
func has_state(state_id: StringName) -> bool:
	return find_state(state_id) != null


## True when this state is terminal - arriving there completes the quest.
func is_complete_state(state_id: StringName) -> bool:
	var state := find_state(state_id)
	return state != null and state.is_complete


## Every edge leaving `state_id` that listens for `event`, in authoring order.
func transitions_for(state_id: StringName, event: StringName) -> Array[QuestTransition]:
	var found: Array[QuestTransition] = []
	for transition: QuestTransition in transitions:
		if transition == null:
			continue
		if transition.from_state == state_id and transition.on_event == event:
			found.append(transition)
	return found


## Every event id any edge listens for, in authoring order, without repeats.
func event_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	for transition: QuestTransition in transitions:
		if transition != null and transition.on_event != &"" and not found.has(transition.on_event):
			found.append(transition.on_event)
	return found


## Every branch flag any edge records, in authoring order, without repeats.
func chosen_branch_flags() -> Array[StringName]:
	var found: Array[StringName] = []
	for transition: QuestTransition in transitions:
		if transition != null and transition.chooses_branch != &"" and not found.has(transition.chooses_branch):
			found.append(transition.chooses_branch)
	return found


## Every problem with this graph, one string per problem; empty means valid.
##
## Five things only the whole graph can prove: no state id is used twice, the initial
## state exists, every edge's endpoints exist, at least one complete state is
## reachable from the initial state (a quest nobody can finish would silently never
## commit its `fires`), and no (state, event) pair offers two edges gated the same
## way - which would make the runner's choice between them arbitrary.
##
## Whether `chooses_branch` names a flag this quest is allowed to choose needs the
## `QuestDefinition`'s branch groups, so `QuestCatalog.validate()` asks that.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if quest_id == &"":
		errors.append("a quest graph names no quest")
	var seen: Dictionary = {}
	for state: QuestState in states:
		if state == null:
			errors.append("graph %s has an empty state slot" % quest_id)
			continue
		errors.append_array(state.validate())
		if seen.has(state.id):
			errors.append("graph %s has two states called %s" % [quest_id, state.id])
		seen[state.id] = true
	if initial_state == &"":
		errors.append("graph %s has no initial state" % quest_id)
	elif not has_state(initial_state):
		errors.append("graph %s starts at %s, which is not a state" % [quest_id, initial_state])
	for transition: QuestTransition in transitions:
		if transition == null:
			errors.append("graph %s has an empty transition slot" % quest_id)
			continue
		errors.append_array(transition.validate())
		if transition.from_state != &"" and not has_state(transition.from_state):
			errors.append("graph %s moves from %s, which is not a state" % [
				quest_id, transition.from_state
			])
		if transition.to_state != &"" and not has_state(transition.to_state):
			errors.append("graph %s moves to %s, which is not a state" % [
				quest_id, transition.to_state
			])
	errors.append_array(_ambiguity_errors())
	if not _completable():
		errors.append("graph %s can never reach a complete state" % quest_id)
	return errors


## True when `validate()` finds nothing.
func is_valid() -> bool:
	return validate().is_empty()


## Two edges on one (state, event) pair gated by identical conditions, reported.
func _ambiguity_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	for index: int in transitions.size():
		var left := transitions[index]
		if left == null:
			continue
		for other: int in range(index + 1, transitions.size()):
			var right := transitions[other]
			if right == null:
				continue
			if left.from_state != right.from_state or left.on_event != right.on_event:
				continue
			if left.has_same_conditions(right):
				errors.append("graph %s answers %s from %s two ways with the same conditions" % [
					quest_id, left.on_event, left.from_state
				])
	return errors


## True when a complete state is reachable from the initial state.
func _completable() -> bool:
	if not has_state(initial_state):
		return false
	var reached: Dictionary = {initial_state: true}
	var frontier: Array[StringName] = [initial_state]
	while not frontier.is_empty():
		var current: StringName = frontier.pop_back()
		if is_complete_state(current):
			return true
		for transition: QuestTransition in transitions:
			if transition == null or transition.from_state != current:
				continue
			if reached.has(transition.to_state) or not has_state(transition.to_state):
				continue
			reached[transition.to_state] = true
			frontier.append(transition.to_state)
	return false


func _build_index() -> void:
	_index.clear()
	for state: QuestState in states:
		if state != null:
			_index[state.id] = state
