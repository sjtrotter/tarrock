class_name TrumpEffects
extends Resource

## One Trump's six expressions and its burden, in one hand-authored resource.
##
## `docs/design/technical.md` §The runtime data model, "Six-expression rule in
## data": a `TrumpDefinition` "never stores 'one effect plus modifiers' - it stores
## six explicit effect references, so `arcana.md` design rule 5 is structurally
## impossible to under-implement. The reversed burden is data on the Trump, applied
## by whichever slot the reversed card currently occupies."
##
## That is this resource, and the six fields are deliberately six named fields
## rather than an array: a missing one is a null a validator names, not an index
## nobody counted.
##
## Authored per Trump under `res://data/trumps/effects/TRUMP_NN.tres` and linked by
## the generated definition when the file exists. A Trump with no effects file is
## still a real Trump - it can be held and slotted - but casting its Present refuses
## with a reason code (`PocketSpreadService`), because there is nothing to run.

## Past slot, upright: the passive as `arcana.md` prints it.
@export var past_upright: TrumpEffect = null

## Past slot, reversed: the same passive, strengthened, with the burden attached.
@export var past_reversed: TrumpEffect = null

## Present slot, upright: the active, at its upright Fortune cost.
@export var present_upright: TrumpEffect = null

## Present slot, reversed: the active, strengthened and cheaper (progression.md:
## "Reversed Present casts cost less"), with the burden attached.
@export var present_reversed: TrumpEffect = null

## Future slot, upright: the triggered effect and its condition.
@export var future_upright: TrumpEffect = null

## Future slot, reversed: the same trigger, strengthened, with the burden attached.
@export var future_reversed: TrumpEffect = null

## The one drawback this card carries when slotted reversed, whichever slot it sits
## in (`arcana.md` design rule 5).
@export var burden: TrumpBurden = null


## The expression for one slot at one orientation, or `null` when it is unauthored.
func for_slot(slot: SpreadSlot.Id, orientation: CardOrientation.Id) -> TrumpEffect:
	match slot:
		SpreadSlot.Id.PAST:
			return past_reversed if orientation == CardOrientation.Id.REVERSED else past_upright
		SpreadSlot.Id.PRESENT:
			return present_reversed if orientation == CardOrientation.Id.REVERSED else present_upright
		SpreadSlot.Id.FUTURE:
			return future_reversed if orientation == CardOrientation.Id.REVERSED else future_upright
	return null


## Every problem with this set; empty means all six expressions and the burden are
## present and readable.
##
## All six are required. A Trump with five is a Trump whose sixth expression nobody
## noticed was missing, which is exactly what the six-explicit-references rule
## exists to prevent.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		for orientation: CardOrientation.Id in CardOrientation.ALL:
			var effect := for_slot(slot, orientation)
			if effect == null:
				errors.append("%s has no %s %s effect" % [
					_describe(),
					SpreadSlot.name_key(slot),
					CardOrientation.name_key(orientation),
				])
				continue
			errors.append_array(effect.validate())
	if burden == null:
		errors.append("%s carries no reversed burden" % _describe())
	else:
		errors.append_array(burden.validate())
	return errors


func _describe() -> String:
	if not resource_path.is_empty():
		return resource_path
	return "<unsaved TrumpEffects>"
