class_name QuestTransition
extends Resource

## One edge of a quest's state machine: an event that moves it, and the world-state
## conditions that must hold for the move to happen.
##
## Events are raised by scenes, combat and dialogue through `QuestService.raise()`;
## the quest is the only thing that then writes world state
## (`docs/design/technical.md` §The WorldState service (Godot)). A transition never
## fires a flag itself - it may *record* a branch choice, and the flags commit when
## the quest reaches a complete state.

## The state this edge leaves.
@export var from_state: StringName = &""

## The state this edge arrives at.
@export var to_state: StringName = &""

## The event id that triggers it (`QuestEvents`).
@export var on_event: StringName = &""

## `WS_*` ids that must all have fired for this edge to be taken.
@export var requires_fired: Array[StringName] = []

## `WS_*` ids that must all be unfired for this edge to be taken.
@export var requires_not_fired: Array[StringName] = []

## The `WS_*` branch flag this edge records as the quest's choice, or `&""` for the
## usual case of an edge that decides nothing. The flag is *recorded* here (set-once,
## through `WorldStateService.set_quest_choice()`) and *fired* at completion.
@export var chooses_branch: StringName = &""


## Every problem with this transition, one string per problem; empty means valid.
##
## Endpoints are checked here for emptiness only; whether they name real states is a
## question for the whole graph, so `QuestGraph.validate()` asks it.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if from_state == &"":
		errors.append("a quest transition leaves no state")
	if to_state == &"":
		errors.append("a quest transition arrives at no state")
	if on_event == &"":
		errors.append("the transition %s -> %s listens for no event" % [from_state, to_state])
	for flag: StringName in requires_fired:
		if flag == &"":
			errors.append("the transition %s -> %s requires an empty flag" % [from_state, to_state])
	for flag: StringName in requires_not_fired:
		if flag == &"":
			errors.append("the transition %s -> %s excludes an empty flag" % [from_state, to_state])
		if requires_fired.has(flag):
			errors.append("the transition %s -> %s needs %s both fired and unfired" % [
				from_state, to_state, flag
			])
	return errors


## True when this edge's world-state conditions hold right now.
func conditions_met(world_state: WorldStateService) -> bool:
	if world_state == null:
		return false
	for flag: StringName in requires_fired:
		if not world_state.is_fired(flag):
			return false
	for flag: StringName in requires_not_fired:
		if world_state.is_fired(flag):
			return false
	return true


## True when this edge and `other` are gated by the same world-state conditions, so a
## graph offering both on one (state, event) pair would have to pick arbitrarily.
func has_same_conditions(other: QuestTransition) -> bool:
	if other == null:
		return false
	return (
		requires_fired == other.requires_fired
		and requires_not_fired == other.requires_not_fired
	)
