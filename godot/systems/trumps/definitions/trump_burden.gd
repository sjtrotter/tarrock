class_name TrumpBurden
extends Resource

## The drawback a Trump attaches when it is slotted reversed.
##
## `docs/design/arcana.md` design rule 5 is canon: slotting a card reversed
## strengthens its effect in that slot and attaches its **burden** - "one drawback
## theme per card, applied to whichever slot it occupies". So a Trump has exactly
## one burden, not one per slot, and it lives on `TrumpEffects` beside the six
## expressions rather than on any one of them.
##
## Like `TrumpEffect`, this is data and not behaviour: `burden_id` is a strategy key
## the combat round resolves. Nothing applies a burden yet - `PocketSpreadService`
## reports which burden is live (`slotted_burden()`) and the round that owns damage
## and Fortune deduction does the applying.

## The burden this Trump carries, e.g. `&"THE_TRICK_COSTS_THE_TRICKSTER"`. `&""`
## means the burden is documented but has no implementation behind it yet.
@export var burden_id: StringName = &""

## The burden's numbers, keyed by name, e.g. `{"extra_fortune_per_trigger": 5}`.
## Numbers only, for the same reason `TrumpEffect.params` are.
@export var params: Dictionary = {}

## Authoring notes: the doc sentence this came from, and what is still TBD.
@export var notes: String = ""


## True when something implements this burden. A placeholder answers false.
func is_implemented() -> bool:
	return burden_id != &""


## The number stored under `key`, or `fallback` when there is none.
##
## Both spellings of the key are tried. A `.tres` written by hand carries plain
## String keys, a `.tres` written by the editor may carry StringName ones, and
## Godot's Dictionary hashes the two differently - so a param authored one way and
## read the other would silently answer the fallback.
func param(key: StringName, fallback: float) -> float:
	var value: Variant = params.get(key, params.get(String(key), fallback))
	if value is int or value is float:
		return float(value)
	return fallback


## Every problem with this burden; empty means it is readable authored data.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for key: Variant in params:
		if not (key is String or key is StringName):
			errors.append("%s has a param key that is not a name: %s" % [_describe(), str(key)])
			continue
		var value: Variant = params[key]
		if not (value is int or value is float):
			errors.append("%s param %s is not a number" % [_describe(), str(key)])
	return errors


func _describe() -> String:
	if not resource_path.is_empty():
		return "%s (%s)" % [resource_path, burden_id]
	return "burden %s" % burden_id
