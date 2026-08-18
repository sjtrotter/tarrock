class_name DialogueOptionView
extends RefCounted

## One row of a choice table as the UI sees it: a key to render, and two facts about
## how it may be picked.
##
## A view is a **read-only copy**, not the definition: the UI round renders these and
## can neither reach the authored resource through one nor write to it (definitions
## are immutable at runtime, `docs/design/technical.md`).

## The Fool's line, as a translation key.
var text_key: StringName = &""

## True for the option the script marks *(earnest)*. The UI may style it; it is
## never a mechanical advantage.
var is_earnest: bool = false

## True once this option has been taken in the current conversation. An exhaustible
## table greys these out; `DialogueService.choose()` refuses them.
var is_used: bool = false


## Build one row's view.
func _init(
	option_text_key: StringName = &"", earnest: bool = false, used: bool = false
) -> void:
	text_key = option_text_key
	is_earnest = earnest
	is_used = used
