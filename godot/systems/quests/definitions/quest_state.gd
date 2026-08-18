class_name QuestState
extends Resource

## One named state in a quest's hand-authored state machine.
##
## `docs/design/technical.md` §Quests at runtime (Godot): a quest is named states and
## transitions gated by events and world-state conditions, and reaching a terminal
## `complete` state is the only thing that lets the quest's `fires` be committed. A
## quest doc's GAMEPLAY beats are what these states are lifted from - the doc is the
## source, the graph is the authored translation.

## The state's id inside its graph, e.g. `&"BINDLE_TAKEN"`. Unique per graph.
@export var id: StringName = &""

## True for a terminal state. Arriving here is what commits the quest's `fires`
## (`QuestService._complete()`); every graph needs at least one.
@export var is_complete: bool = false

## Why this state exists, in the quest doc's own words - normally the slugline the
## beat comes from. Documentation for a reviewer, **never displayed**: it is one of
## the doc-only resource properties the localization lint exempts.
@export var notes: String = ""


## Every problem with this state, one string per problem; empty means valid.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("a quest state has an empty id")
	return errors
