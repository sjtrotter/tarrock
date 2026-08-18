class_name SpreadLoadout
extends RefCounted

## One saved Pocket Spread configuration: a player's name for it, and three slots.
##
## `docs/design/progression.md` §The Pocket Spread: "Full loadout saving and respec
## - naming and swapping between whole saved Spread configurations - is available at
## Waystations only." This is one of those saved configurations.
##
## `label` is text the PLAYER typed. It is user data, not content: it is never
## translated, never linted as a missing translation key, and it goes into the save
## file verbatim. Everything else in here is ids.
##
## Named `SpreadLoadout` rather than `Loadout` because the project's `class_name`s
## are global: "loadout" will mean something else the day staff heads or outfits get
## saved sets of their own.

## What the player called this spread. Player-typed text; may be anything, including
## empty.
var label: String = ""

## One entry per `SpreadSlot.Id`, in `SpreadSlot.ALL` order. Empty entries are open
## slots: a loadout may deliberately leave a slot clear.
var assignments: Array[SlotAssignment] = []


func _init(loadout_label: String = "", slots: Array[SlotAssignment] = []) -> void:
	label = loadout_label
	assignments = []
	for index: int in SpreadSlot.ALL.size():
		var source: SlotAssignment = slots[index] if index < slots.size() else null
		assignments.append(SlotAssignment.new() if source == null else source.copy())


## What this loadout puts in one slot; an empty assignment when it leaves it open.
func assignment(slot: SpreadSlot.Id) -> SlotAssignment:
	if slot < 0 or slot >= assignments.size():
		return SlotAssignment.new()
	return assignments[slot]


## An independent copy, assignments included.
func copy() -> SpreadLoadout:
	return SpreadLoadout.new(label, assignments)
