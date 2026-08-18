class_name Seekable
extends Area2D

## Something hidden a region scene has authored, for Pip's Seek to find.
##
## `docs/design/combat.md` §Pip: Seek "points toward something hidden nearby - a trap,
## a secret, a fog-hidden path". This is that thing, and it is deliberately as thin as
## `Interactable` is: it knows *that it was found*, never *what being found means*. It
## emits `found` and carries a `reward_event`; the region scene's own script is what
## forwards that to `QuestService.raise()` (`docs/design/technical.md` §Architecture
## principles (Godot), 5).
##
## `docs/quests/main/MQ00-the-leap.md` §The Old Campsites is the first one in the game:
## the patch of disturbed earth by the largest campsite, with the whittled wooden dog
## in it.
##
## **TBD - only half of Seek is built.** `combat.md` gives the command two readings in
## one sentence: Pip *goes to* a hidden thing and digs it out (the campsite dig, which
## is what round 9 built), and Pip *points toward* one from where he stands - "a trap,
## a secret, a fog-hidden path", none of which a dog should be sent to stand on. The
## second reading needs a point-and-hold beat rather than an OUTBOUND/WORKING/RETURNING
## errand, and it needs a trap system and a fog region to point at; neither exists.
## `approach` below is where that decision will land, and **nothing reads it yet**.
##
## **It scans nothing.** The `Area2D` is here for its shape - a place and a size a
## scene author can see and a later VFX or audio pass can hang on - and both monitoring
## flags are switched off in `_ready`, because the search for the nearest Seekable is
## the scene's (it is asked for one by `PipCompanion.target_requested`) and a hundred
## idle areas testing each other every physics frame would be a hundred areas of
## nothing.

## Pip found it. The scene answers by raising `reward_event`, if there is one.
signal found()

## The quest event finding this raises, from `QuestEvents`, or `&""` for a hidden thing
## no quest cares about. The node carries the id; the scene decides what to do with it.
@export var reward_event: StringName = &""

## True when Pip runs to this thing and digs it out; false when he points at it from a
## distance and never touches it.
##
## **NOT IMPLEMENTED beyond this declaration and the warning in `_ready()`.** Every
## Seek in the game today is an approach, so `true` is the only value anything is built
## for; a node authored `false` is authoring ahead of the system, and says so out loud
## rather than being quietly dug up. The half that is missing is described in the class
## doc, and `systems/pip/README.md` §What this round deliberately did not build lists
## it as owed work.
@export var approach: bool = true

## True when this may only ever be found once.
##
## The default is once, because most secrets are. MQ00's dig is authored the other way
## round on purpose - see `scripts/the_cliff.gd` - so that a Seek before the Bindle is
## taken cannot spend the one dig the quest is waiting for.
@export var one_shot: bool = true

## True once a one-shot node has been used up.
var _spent: bool = false


func _ready() -> void:
	monitoring = false
	monitorable = false
	if not approach:
		# The validation half of the TBD: a scene that authored the unbuilt reading of
		# Seek gets told, once, on the node that did it - instead of a dog walking onto
		# a trap and the author finding out in play.
		push_warning("%s: approach = false is not built; Pip will run to it and dig" % name)


## True when Pip could still be sent to this one.
func is_available() -> bool:
	return not _spent


## True once this has been found and, being one-shot, never will be again.
func is_spent() -> bool:
	return _spent


## Bring it to light. Returns true only when **this call** found it.
##
## Called by `PipCompanion` when Pip's dig finishes - which is the moment
## `docs/quests/main/MQ00-the-leap.md` writes as "Pip backs out of the hole holding
## something small in his teeth". He trots it back to the Fool afterwards, and the
## Querent's line about it plays over the trot.
func reveal() -> bool:
	if _spent:
		return false
	if one_shot:
		_spent = true
	found.emit()
	return true
