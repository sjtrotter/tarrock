class_name SlotAssignment
extends RefCounted

## What is in one slot of the Pocket Spread: a Trump, and which way up.
##
## A tiny value object rather than a Dictionary, so a caller cannot misspell a key
## and so `PocketSpreadService.slotted()` can answer "nothing" without answering
## `null` (an empty assignment is a real answer: the slot is open).
##
## It is a copy, always. `slotted()` hands one out and the service keeps its own, so
## nobody can reach into the Spread and change what is slotted without going through
## `assign()` - which is where the rules live.

## The Trump in this slot, or `&""` when the slot is empty.
var trump_id: StringName = &""

## Which way up it is slotted. Meaningless while `trump_id` is empty.
var orientation: CardOrientation.Id = CardOrientation.Id.UPRIGHT


func _init(
	slotted_trump: StringName = &"",
	slotted_orientation: CardOrientation.Id = CardOrientation.Id.UPRIGHT
) -> void:
	trump_id = slotted_trump
	orientation = slotted_orientation


## True when no Trump is in this slot.
func is_empty() -> bool:
	return trump_id == &""


## An independent copy of this assignment.
func copy() -> SlotAssignment:
	return SlotAssignment.new(trump_id, orientation)
