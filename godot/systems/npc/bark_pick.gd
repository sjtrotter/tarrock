class_name BarkPick
extends RefCounted

## What a bark request answered: the line, and which of the seven pools it came from.
##
## **THIS OBJECT IS REUSED.** `BarkService` keeps exactly one and re-stamps it for every
## request, because a request happens whenever an NPC is about to speak and allocating a
## result per request is an allocation per NPC per beat. Read what you need off it
## before calling `request()` again; the two constants below are what an empty answer
## looks like, so a caller never has to null-check the pick itself.
##
## An empty pick means no layer had anything - which, for a complete catalog, cannot
## happen: `docs/design/npc-system.md` §Bark layers makes layer 7 "mandatory and
## evergreen" and `BarkCatalog.validate()` refuses a complete catalog that is not.
## Silence is therefore a content bug, and it is representable here precisely so the
## bug can be seen rather than crashed on.

## The layer an empty pick reports. Not one of the seven.
const NO_LAYER := 0

## The bark that was picked, or `null` when nothing was.
var bark: BarkDefinition = null

## Which layer it came from (`BarkLayer`), or `NO_LAYER`.
var layer: int = NO_LAYER


## True when a line was found.
func is_empty() -> bool:
	return bark == null


## The id of the picked bark, or `&""`.
func bark_id() -> StringName:
	return &"" if bark == null else bark.id


## The translation key of the picked line, or `&""`. What a speech bubble asks for.
func text_key() -> StringName:
	return &"" if bark == null else bark.text_key


## Blank this pick. Called by the service at the top of every request, so a request that
## finds nothing cannot report the previous request's line.
func clear() -> void:
	bark = null
	layer = NO_LAYER


## Stamp this pick with a result.
func fill(with_bark: BarkDefinition, at_layer: int) -> void:
	bark = with_bark
	layer = at_layer
