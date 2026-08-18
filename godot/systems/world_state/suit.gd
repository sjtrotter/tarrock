class_name Suit
extends RefCounted

## The four Minor suits, and the only place their names are spelled.
##
## `docs/GLOSSARY.md` owns the suits themselves: Cups, Swords, Wands, Coins. Renown
## is tracked per suit (`docs/design/progression.md` §Renown), saves key Renown by
## suit, and NPC identity reads suit + Court rank - all of which go through `Id` and
## `name_key()` rather than through a string anybody typed.

## A suit, in the doc's own order.
enum Id {
	CUPS,
	SWORDS,
	WANDS,
	COINS,
}

## Every suit, for iteration.
const ALL: Array[Id] = [Id.CUPS, Id.SWORDS, Id.WANDS, Id.COINS]

## Returned by `from_name_key()` when the key names no suit.
const UNKNOWN := -1

## The stable key for each suit, indexed by `Id`. Save files and Renown snapshots
## use these; player-facing suit names are translation keys resolved elsewhere.
const NAME_KEYS: Array[StringName] = [&"CUPS", &"SWORDS", &"WANDS", &"COINS"]


## The stable key naming a suit, e.g. `&"WANDS"`.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The suit a key names, or `UNKNOWN` (-1) when it names none. Returns an `int`
## rather than an `Id` precisely so the failure case is representable.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)
