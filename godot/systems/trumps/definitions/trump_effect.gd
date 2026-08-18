class_name TrumpEffect
extends Resource

## One of a Trump's six expressions: what the card does in one slot, one way up.
##
## `docs/design/arcana.md` design rule 5 - "one card, six expressions" - is canon,
## and `docs/design/technical.md` §The runtime data model requires a
## `TrumpDefinition` to store **six explicit effect references** rather than one
## effect plus modifiers, "so `arcana.md` design rule 5 is structurally impossible
## to under-implement". This is one of those six.
##
## HAND-AUTHORED (technical.md §Generated vs. hand-authored): what a Trump *does* is
## prose in `arcana.md`, so a person lifts it into `res://data/trumps/effects/` and
## cites the section in `notes`. The generated `TrumpDefinition` links the file when
## it exists and carries `null` when it does not.
##
## **This resource is not the behaviour.** `effect_id` is a strategy key that the
## combat round (round 7) resolves to an implementation; `params` are its numbers.
## Until that round exists, an authored effect is a promise nothing keeps yet, and
## `PocketSpreadService.cast_present()` says so rather than pretending: an effect
## with an empty `effect_id` is a placeholder and refuses to cast.

## The strategy this effect runs, e.g. `&"CONJURED_HAND"`. `&""` means the effect is
## authored from the doc but has no implementation behind it yet - a placeholder,
## not a bug (see the class doc).
@export var effect_id: StringName = &""

## The effect's numbers, keyed by name, e.g. `{"uses_per_fight": 1}`. Numbers only:
## a param is tuning data that survives being written to a JSON balance dump, and a
## resource or a node in here would be a behaviour hiding in a definition.
@export var params: Dictionary = {}

## Present slot only: the Fortune one cast costs. `0` means "take the default for
## this orientation from `SpreadRules`" - the costs are TBD tuning
## (`progression.md` sets the 20-50 band; `arcana.md` sets no per-Trump number).
@export var present_cost: int = 0

## Authoring notes: which doc sentence this came from, and what is still TBD.
@export var notes: String = ""


## True when something implements this effect. A placeholder answers false.
func is_implemented() -> bool:
	return effect_id != &""


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


## Every problem with this effect; empty means it is authored data a system can read.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if present_cost < 0:
		errors.append("%s has a negative Present cost: %d" % [_describe(), present_cost])
	for key: Variant in params:
		if not (key is String or key is StringName):
			errors.append("%s has a param key that is not a name: %s" % [_describe(), str(key)])
			continue
		var value: Variant = params[key]
		if not (value is int or value is float):
			errors.append("%s param %s is not a number" % [_describe(), str(key)])
	return errors


## How this effect names itself in an error message.
func _describe() -> String:
	if not resource_path.is_empty():
		return "%s (%s)" % [resource_path, effect_id]
	return "effect %s" % effect_id
