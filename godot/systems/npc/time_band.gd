class_name TimeBand
extends RefCounted

## The times of day a layer-6 bark and an anchor schedule can name.
##
## `docs/design/npc-system.md` §Bark layers, layer 6: the time/weather pool "only
## exists where `WS_SUN_UNBOUND` (day/night)... has fired", and §Daily life: NPCs move
## between anchors "on a simple time-of-day loop once `WS_SUN_UNBOUND` gives the world
## a day/night cycle to schedule against". Both sentences are the same rule read twice:
## BEFORE THE SUN IS UNBOUND THERE IS NO TIME OF DAY, so there is nothing here to
## query and `NONE` is the honest answer rather than an arbitrary band.
##
## Neither the four band names nor their boundary hours are in any doc: the doc says
## "day/night" and nothing finer. Four bands is this system's reading, and the hours
## live in `NpcRules` as tuning (see there) rather than as numbers typed into code.

## A band of the in-game day.
enum Id {
	## The world has no time of day - `WS_SUN_UNBOUND` has not fired. Also what a
	## caller passes when it does not know or does not care.
	NONE,
	DAWN,
	DAY,
	DUSK,
	NIGHT,
}

## Every band that is a real time of day, for iteration. `NONE` is deliberately out:
## it is the absence of one.
const ALL: Array[Id] = [Id.DAWN, Id.DAY, Id.DUSK, Id.NIGHT]

## A bark condition that does not care what time it is. Outside the enum for the same
## reason `NpcRank.ANY` is: it is the absence of the condition, not a value of it.
const ANY := -1

## The stable key for each band, indexed by `Id`.
const NAME_KEYS: Array[StringName] = [&"NONE", &"DAWN", &"DAY", &"DUSK", &"NIGHT"]


## The stable key naming a band, e.g. `&"DUSK"`, or `&""` for no such band.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The band a key names, or `ANY` (-1) when it names none.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## True when `value` is a band, or the "any time" wildcard.
static func is_condition(value: int) -> bool:
	return value == ANY or (value >= 0 and value < NAME_KEYS.size())
