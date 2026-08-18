class_name Weather
extends RefCounted

## The weather a layer-6 bark can name.
##
## `docs/design/npc-system.md` §Bark layers, layer 6: the pool "only exists where...
## `WS_TOWER_UNBOUND` (storm rotation) has fired", and the layer's own note - "before
## `WS_TOWER_UNBOUND`, no storm rotation exists. Region docs omit layer 6 entirely
## until then rather than authoring dead pools."
##
## STORM is the only weather any doc names, so it is the only one here. `CLEAR` is not
## a state the docs give the world - a bark that wants to be said in fair weather is a
## bark with no weather condition at all - and inventing it would be inventing canon.

## Weather a bark may wait on.
enum Id {
	## No weather worth remarking on, and what the world has before the Tower is
	## unbound.
	NONE,
	## The storm rotation `WS_TOWER_UNBOUND` brings (`docs/design/world.md`
	## §World-state matrix).
	STORM,
}

## Every weather that is a real condition, for iteration. `NONE` is the absence of one.
const ALL: Array[Id] = [Id.STORM]

## A bark condition that does not care about the weather.
const ANY := -1

## The stable key for each weather, indexed by `Id`.
const NAME_KEYS: Array[StringName] = [&"NONE", &"STORM"]


## The stable key naming a weather, e.g. `&"STORM"`, or `&""` for no such weather.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The weather a key names, or `ANY` (-1) when it names none.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## True when `value` is a weather, or the "any weather" wildcard.
static func is_condition(value: int) -> bool:
	return value == ANY or (value >= 0 and value < NAME_KEYS.size())
