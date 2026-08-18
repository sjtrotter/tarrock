class_name Fetchable
extends Area2D

## An item Pip can be sent to retrieve.
##
## `docs/design/combat.md` §Pip: Fetch "retrieves a dropped or thrown item (a lobbed
## weapon, a quest object, ammunition) and brings it back to the Fool". The three
## things that sentence names do not exist yet - the Bindle has no throw, the Cups lob
## belongs to its thrower, and there is no ammunition in the game - so nothing in the
## shipped scenes is a Fetchable today, and the round proved Fetch against a fixture
## item instead. This is the node those three become when their rounds land.
##
## Same contract as `Seekable` and `Interactable`: it knows what happened to it and
## never what it means. It scans nothing (see `Seekable`'s note on the flags), and the
## scene decides what a delivered item is worth.
##
## **Carrying is not reparenting.** While Pip has it, `PipCompanion` writes the item's
## world position each frame from Pip's own. Reparenting a node in the middle of a
## physics callback is the class of bug `Blank.wake()` already has a comment about, and
## a dog carrying a thing in his teeth is exactly "it is where he is" anyway.

## Pip picked it up.
signal picked_up()

## Pip put it down at the Fool's feet.
signal delivered()

## True while Pip has it in his teeth.
var _carried: bool = false

## True once it has been delivered.
var _delivered: bool = false


func _ready() -> void:
	monitoring = false
	monitorable = false


## True when Pip could still be sent for this one.
func is_available() -> bool:
	return not _carried and not _delivered


## True while Pip has it.
func is_carried() -> bool:
	return _carried


## True once it has reached the Fool.
func is_delivered() -> bool:
	return _delivered


## Pip has it. Returns true only when **this call** picked it up.
func take() -> bool:
	if not is_available():
		return false
	_carried = true
	picked_up.emit()
	return true


## Pip has put it down at `at`. Returns true only when **this call** delivered it.
func deliver(at: Vector2) -> bool:
	if not _carried:
		return false
	_carried = false
	_delivered = true
	global_position = at
	delivered.emit()
	return true


## Put it back to being an item lying in the grass, for a scene that re-arms it.
func restore() -> void:
	_carried = false
	_delivered = false
