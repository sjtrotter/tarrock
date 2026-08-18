class_name DialogueView
extends RefCounted

## What the conversation is showing right now, as the UI sees it.
##
## `DialogueService` hands one of these out of `current()` and with every
## `node_presented` signal. It is a **read-only copy** of the node the runner stopped
## on: the UI round (13) renders it, and nothing it holds can be written back into
## the authored graph (definitions are immutable at runtime,
## `docs/design/technical.md`).
##
## Only presentable kinds ever reach a view. `BRANCH` and `EVENT` are resolved by the
## runner and never shown, and `END` is not shown either - a conversation finishing
## is the `dialogue_ended` signal, not a frame of dialogue. A view's `kind` is
## therefore `LINE`, `POOL` or `CHOICE`.

## Which shape this is: `LINE`, `POOL` or `CHOICE`.
var kind: DialogueNode.Kind = DialogueNode.Kind.LINE

## Who is speaking (`Speakers`), or `&""` for a `CHOICE`, whose options are the
## Fool's own lines. `Speakers.name_key()` turns it into a display-name key.
var speaker: StringName = &""

## The line to render, as a translation key. Empty for a `CHOICE`.
var text_key: StringName = &""

## The rows of a choice table, in script order. Empty for everything else.
var options: Array[DialogueOptionView] = []

## The id of the node this view was taken from, for tests and for the UI's own
## bookkeeping. Never displayed.
var node_id: StringName = &""

## The graph this node belongs to. Never displayed.
var graph_id: StringName = &""


## True when the player has to pick something before the conversation moves.
func is_choice() -> bool:
	return kind == DialogueNode.Kind.CHOICE


## The speaker's display name as a translation key, or `&""` when nobody speaks.
func speaker_name_key() -> StringName:
	if speaker == &"":
		return &""
	return Speakers.name_key(speaker)
