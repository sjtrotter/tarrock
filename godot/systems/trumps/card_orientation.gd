class_name CardOrientation
extends RefCounted

## Which way up a Trump is slotted, and the only place the two words are spelled.
##
## `docs/design/progression.md` §The Pocket Spread and `docs/design/arcana.md`
## design rule 5 are canon: every Trump can be slotted **upright** or **reversed**,
## and reversed strengthens the effect in exchange for the card's **burden** - a
## drawback themed to its traditional reversed meaning. Reversed Present casts also
## cost less Fortune, "a direct economic trade the player makes at slotting time,
## not at cast time".
##
## Own class, not an enum on the service, for the same reason `SpreadSlot` is: a
## save records an orientation by its stable key, never by an ordinal.

## An orientation, upright first (the way a card is dealt when nothing is wrong).
enum Id {
	UPRIGHT,
	REVERSED,
}

## Both orientations, for iteration.
const ALL: Array[Id] = [Id.UPRIGHT, Id.REVERSED]

## Returned by `from_name_key()` when the key names neither.
const UNKNOWN := -1

## The stable key for each orientation, indexed by `Id`.
const NAME_KEYS: Array[StringName] = [&"UPRIGHT", &"REVERSED"]


## The stable key naming an orientation, e.g. `&"REVERSED"`. `&""` when out of range.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The orientation a key names, or `UNKNOWN` (-1) when it names neither.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)
