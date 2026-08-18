class_name QuestService
extends RefCounted

## The quest runner: the ONE writer of world state.
##
## `docs/design/technical.md` §Quests at runtime (Godot) and §The WorldState service
## (Godot) put the whole contract in two sentences - a quest is a state machine whose
## transitions are gated by events and world-state conditions, and reaching a
## terminal state is the only thing that lets its `fires` be committed. Everything
## else in the game *raises events* here; only this service calls
## `WorldStateService.fire()`, `set_quest_state()` and `set_quest_choice()`.
##
## Four properties hold by construction rather than by discipline:
##
##   * **Nothing commits mid-quest.** `fire()` is called from one place,
##     `_complete()`, and only after the runner has decided the quest really is
##     finishing. A quest abandoned halfway has changed nothing about the world.
##   * **Exactly one branch per group.** A quest with `branches` cannot complete
##     until every group has a recorded choice; the attempt is refused, the quest
##     stays where it is, and `quest_completion_refused` says why. The choice itself
##     is set-once in `WorldStateService`, so the other half of a group can never be
##     chosen afterwards either.
##   * **Determinism.** Quests are considered in catalog order, and a quest's edges
##     in authoring order, so one raised event always produces the same moves.
##     `QuestGraph.validate()` rejects two edges on one (state, event) pair gated the
##     same way, so the tie-break never has to decide anything meaningful.
##   * **No polling, no per-frame work.** Everything here happens inside `raise()`,
##     `start()` or a query. Interested systems connect to the signals below.
##
## Quest state itself lives in `WorldStateService` (it is save data, and barks and
## dialogue read it), so a restored save resumes mid-quest with no extra plumbing:
## build a fresh `WorldStateService`, restore the snapshot into it, build a
## `QuestService` over it, and every quest is exactly where the player left it.

## A quest was started and is now in its graph's initial state.
signal quest_started(quest_id: StringName)

## A quest took a transition. Emitted for every move, including the last one.
signal quest_advanced(quest_id: StringName, from_state: StringName, to_state: StringName)

## A quest reached a complete state; its `fires` and its chosen branch flags are
## committed by the time this arrives.
signal quest_completed(quest_id: StringName)

## A quest could not complete and stayed where it was. `reason` is one of the
## `REFUSED_*` codes below - a code, never a sentence: nothing here is player-facing.
signal quest_completion_refused(quest_id: StringName, reason: StringName)

## The quest owes at least one of its branch groups a choice, so completing it would
## fire none of that group - or, worse, leave the world's story half-told.
const REFUSED_BRANCH_UNCHOSEN := &"BRANCH_GROUP_UNCHOSEN"

## The state a quest that has never started reports.
const UNSTARTED := &""

var _world_state: WorldStateService = null
var _catalog: QuestCatalog = null


## Build the runner over the live world state and the generated quest catalog.
##
## Both are required: without the catalog there are no quests, and without the world
## state there is nowhere for a completion to land.
func _init(world_state: WorldStateService, catalog: QuestCatalog) -> void:
	_world_state = world_state
	_catalog = catalog
	if world_state == null or catalog == null:
		push_error("QuestService was built without its world state or its catalog")


# --- Queries -----------------------------------------------------------------


## True when every id this quest `requires` holds: a `WS_*` flag has fired, another
## quest is complete. An id no catalog lists is an error and reads as unavailable.
##
## Availability says nothing about whether the quest has been played - a started or
## finished quest whose requirements hold is still "available" in this sense. Ask
## `is_started()` / `is_complete()` for that.
func is_available(quest_id: StringName) -> bool:
	var definition := _definition(quest_id)
	if definition == null:
		return false
	for required: StringName in definition.required_states:
		if _catalog.has(required):
			if not is_complete(required):
				return false
		elif not _world_state.is_fired(required):
			return false
	return true


## True once this quest has been started and has a current state.
func is_started(quest_id: StringName) -> bool:
	return state_of(quest_id) != UNSTARTED


## True when this quest's current state is one its graph marks complete.
func is_complete(quest_id: StringName) -> bool:
	var definition := _definition(quest_id)
	if definition == null or definition.graph == null:
		return false
	return definition.graph.is_complete_state(state_of(quest_id))


## This quest's current state id, or `&""` when it has never started.
func state_of(quest_id: StringName) -> StringName:
	if _world_state == null:
		return UNSTARTED
	return _world_state.quest_state(quest_id)


## Every quest that has started and not finished, in catalog order.
func active_quest_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	if _catalog == null:
		return found
	for entry: QuestDefinition in _catalog.entries:
		if entry == null:
			continue
		if is_started(entry.id) and not is_complete(entry.id):
			found.append(entry.id)
	return found


# --- Playing -----------------------------------------------------------------


## Start a quest, putting it in its graph's initial state. Returns true only when
## **this call** started it.
##
## Refused, without changing anything, when the quest is unknown, has no authored
## graph, has already started, or is not available yet. Emits `quest_started`.
func start(quest_id: StringName) -> bool:
	var definition := _definition(quest_id)
	if definition == null:
		return false
	if definition.graph == null:
		push_error("%s has no authored graph, so it cannot be started" % quest_id)
		return false
	if is_started(quest_id):
		return false
	if not is_available(quest_id):
		return false
	_world_state.set_quest_state(quest_id, definition.graph.initial_state)
	quest_started.emit(quest_id)
	return true


## Tell every running quest that something happened in the world.
##
## Scenes, combat and dialogue call this and nothing else: they never write world
## state. Every started, incomplete quest whose graph answers this event from its
## current state - with its world-state conditions met - takes that transition, in
## catalog order. An event no quest is listening for is ignored **silently**: most
## events are for nobody, and a warning per uninteresting event would be noise.
##
## `context` is carried for later rounds (which node, which enemy, which choice);
## nothing reads it yet, and quests must not start depending on it without a design
## decision saying what may live in there.
@warning_ignore("unused_parameter")
func raise(event: StringName, context: Dictionary = {}) -> void:
	if _catalog == null or _world_state == null or event == &"":
		return
	for entry: QuestDefinition in _catalog.entries:
		if entry == null or entry.graph == null:
			continue
		if not is_started(entry.id) or is_complete(entry.id):
			continue
		var transition := _transition_for(entry, event)
		if transition != null:
			_apply(entry, transition)


# --- Internals ---------------------------------------------------------------


## The first edge this quest would take on `event`, or `null` when it would take
## none. Authoring order is the tie-break; `QuestGraph.validate()` guarantees that
## two edges are never both legal for the same reason.
func _transition_for(definition: QuestDefinition, event: StringName) -> QuestTransition:
	var current := state_of(definition.id)
	for transition: QuestTransition in definition.graph.transitions_for(current, event):
		if transition.conditions_met(_world_state):
			return transition
	return null


## Take one edge: record its branch choice, move the state, and complete the quest
## when the new state is terminal.
##
## The completability check happens **before** anything is recorded, so a refusal
## leaves the quest exactly where it was - not just in the state it started at, but
## with every choice still unmade. Recording this transition's own choice first would
## burn a set-once pick for a completion that is about to be refused anyway, over a
## group this edge was never asked about.
func _apply(definition: QuestDefinition, transition: QuestTransition) -> void:
	var from_state := state_of(definition.id)
	if not definition.graph.has_state(transition.to_state):
		push_error("%s's transition from %s on %s arrives at %s, which is not a state in its graph" % [
			definition.id, from_state, transition.on_event, transition.to_state
		])
		return
	var completes := definition.graph.is_complete_state(transition.to_state)
	if completes:
		var unchosen := _unchosen_group(definition, transition.chooses_branch)
		if unchosen != &"":
			push_error("%s cannot finish: branch group %s was never chosen" % [
				definition.id, unchosen
			])
			quest_completion_refused.emit(definition.id, REFUSED_BRANCH_UNCHOSEN)
			return
	if not _record_choice(definition, transition):
		return
	if completes:
		_commit(definition)
	_world_state.set_quest_state(definition.id, transition.to_state)
	quest_advanced.emit(definition.id, from_state, transition.to_state)
	if completes:
		quest_completed.emit(definition.id)


## Record this edge's branch choice, if it makes one. False means the edge must not
## be taken: it asks to change a choice already made, which is not a thing a
## playthrough may do.
func _record_choice(definition: QuestDefinition, transition: QuestTransition) -> bool:
	if transition.chooses_branch == &"":
		return true
	var group := definition.branch_group_for(transition.chooses_branch)
	if group == null:
		push_error("%s chooses %s, which is in none of its branch groups" % [
			definition.id, transition.chooses_branch
		])
		return false
	var already := _world_state.quest_choice(definition.id, group.group_id)
	if already == transition.chooses_branch:
		return true
	if already != &"":
		push_error("%s already chose %s for group %s" % [definition.id, already, group.group_id])
		return false
	return _world_state.set_quest_choice(
		definition.id, group.group_id, transition.chooses_branch
	)


## The first branch group this quest still owes a choice, or `&""` when it owes none.
##
## `choosing` is the branch flag the transition under evaluation would itself record,
## or `&""` for a transition that chooses nothing. Its group is never reported as
## unchosen: this call decides whether that very choice may be recorded, so judging it
## against a choice that has not happened yet would refuse every completing edge that
## makes its group's pick on the same move that finishes the quest.
func _unchosen_group(definition: QuestDefinition, choosing: StringName = &"") -> StringName:
	var choosing_group := definition.branch_group_for(choosing) if choosing != &"" else null
	for group_id: StringName in definition.branch_group_ids():
		if choosing_group != null and group_id == choosing_group.group_id:
			continue
		if _world_state.quest_choice(definition.id, group_id) == &"":
			return group_id
	return &""


## Commit everything a completed quest changes about the world: its `fires`, then
## the branch flag it chose for each of its groups. The ONLY place this service
## fires anything.
func _commit(definition: QuestDefinition) -> void:
	for flag: StringName in definition.fired_states:
		_world_state.fire(flag, definition.id)
	for group_id: StringName in definition.branch_group_ids():
		var chosen := _world_state.quest_choice(definition.id, group_id)
		if chosen != &"":
			_world_state.fire(chosen, definition.id)


## The definition behind an id, or null (with an error) when the catalog has none.
func _definition(quest_id: StringName) -> QuestDefinition:
	if _catalog == null:
		return null
	var definition := _catalog.find(quest_id)
	if definition == null:
		push_error("no quest with id %s" % quest_id)
	return definition
