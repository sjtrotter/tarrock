class_name DialogueOption
extends Resource

## One row of a choice table: the Fool's line, and the thread it opens.
##
## `docs/quests/TEMPLATE.md` writes a choice dialog as a two-column table - the
## Fool's option on the left, the answer on the right - so an option is exactly
## that pairing: a line the player picks (`text_key`) and the node the conversation
## walks into when they do (`next`).
##
## `docs/design/narrative.md` §Dialogue style guide is what the two flags serve. The
## Fool's selectable lines stay short and "include one foolish/earnest option
## wherever possible; it is the character's soul" - the script marks that option
## *(earnest)*, and `is_earnest` is that marker, carried into data so a lint can ask
## for it rather than a reviewer having to remember.

## The Fool's line, as a translation key. Never a literal: the English lives in
## `res://localization/dialogue_*.csv` (`docs/design/technical.md` §Localization).
@export var text_key: StringName = &""

## The node this option walks into - the "If the Fool asked ..." thread. The thread
## runs to an `END` node, which returns to the choice in an exhaustible table.
@export var next: StringName = &""

## True for the option the script marks *(earnest)*: the honest, unguarded answer the
## style guide asks every choice table to offer.
@export var is_earnest: bool = false

## A `QuestEvents` id raised when this option is taken, or `&""` for the usual case
## of a line that changes nothing. Dialogue never writes world state: the service
## emits `event_raised`, the SCENE forwards it to `QuestService.raise()`, and the
## quest decides whether it meant anything (`docs/design/technical.md` §The
## WorldState service (Godot)).
@export var raises_event: StringName = &""


## Every problem with this option, one string per problem; empty means valid.
##
## Whether `next` names a real node is a question for the whole graph, so
## `DialogueGraph.validate()` asks it.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if text_key == &"":
		errors.append("a dialogue option has no text key")
	if next == &"":
		errors.append("the dialogue option %s leads nowhere" % text_key)
	return errors
