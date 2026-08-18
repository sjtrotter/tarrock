class_name SpreadSlot
extends RefCounted

## The three positions of the Pocket Spread, and the only place they are spelled.
##
## `docs/design/progression.md` §The Pocket Spread is canon: Past is "what you
## carry" (a passive), Present is "what you do" (an active that costs Fortune),
## Future is "what awaits" (a reactive that fires on a condition). It is an
## equipment metaphor, not time travel, and the doc says so twice.
##
## The slots live in their own class rather than as an enum on
## `PocketSpreadService` for the reason `Suit` and `DifficultyMode` do: a save file
## records a slot by its stable `name_key`, never by an enum ordinal, and the
## definitions (`TrumpEffects`) need to name a slot without depending on the service
## that runs them.

## A slot, in the doc's own order (the order a three-card spread is dealt in).
enum Id {
	PAST,
	PRESENT,
	FUTURE,
}

## Every slot, for iteration.
const ALL: Array[Id] = [Id.PAST, Id.PRESENT, Id.FUTURE]

## Returned by `from_name_key()` when the key names no slot. An `int`, not an `Id`,
## so the failure case is representable - the shape `Suit.UNKNOWN` uses.
const UNKNOWN := -1

## The stable key for each slot, indexed by `Id`. Snapshots use these; player-facing
## slot names are translation keys resolved elsewhere.
const NAME_KEYS: Array[StringName] = [&"PAST", &"PRESENT", &"FUTURE"]


## The stable key naming a slot, e.g. `&"PRESENT"`. `&""` for an id out of range.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The slot a key names, or `UNKNOWN` (-1) when it names none.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)
