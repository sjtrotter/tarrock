class_name EnemyFamily
extends RefCounted

## The three enemy families `docs/design/combat.md` names, and the only place their
## names are spelled.
##
## §Enemies: the Blanks is the standard enemy; §Other enemy families adds exactly two
## more, "both tied to specific regions and world-states" - the Beasts of the Maw and
## the wild spaces, and the Fog-masks of the Mirrormarsh. There is no fourth, and a
## regional skin is not one: "Regional skins dress Blanks to match the region they're
## found in... cosmetic only; suit and rank still govern behavior".
##
## This is NOT `Faction`. A faction is a side in a fight and answers "may this hit
## land"; a family is what a thing IS, and answers "which rules does it live by" -
## suit and rank for a Blank, a calming flag for a Beast, an ambush advantage for a
## Fog-mask. They happen to line up one-to-one today because the Stall did not start a
## civil war (see `Faction`'s class doc); `faction_for()` is the one place that
## correspondence is written down, so it can stop being one-to-one without a search.

## An enemy family.
enum Id {
	## `combat.md` §Enemies: the Blanks. Suit x rank, one art family.
	BLANK,
	## The wildlife of the Maw and the other wild spaces.
	BEAST,
	## The Mirrormarsh's "monsters", and the lost people under them.
	FOG_MASK,
}

## Every family, for iteration.
const ALL: Array[Id] = [Id.BLANK, Id.BEAST, Id.FOG_MASK]

## Returned by `from_name_key()` when the key names no family. An `int`, so the
## failure case is representable - the same shape `Suit.UNKNOWN` uses.
const UNKNOWN := -1

## The stable key naming each family, indexed by `Id`. Never displayed: enemy display
## names are not canon yet (no doc gives a Blank a name), so nothing resolves one.
const NAME_KEYS: Array[StringName] = [&"BLANK", &"BEAST", &"FOG_MASK"]


## The stable key naming a family, or `&""` for an id out of range.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The family a key names, or `UNKNOWN` (-1) when it names none.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## True when this family is defined by a suit and a rank. Only the Blanks are: a
## Beast has no suit, and a Fog-mask wears a mask rather than a tabard.
static func has_suit_and_rank(id: Id) -> bool:
	return id == Id.BLANK


## The side a family fights on. One-to-one today, and written here once so the day a
## family changes sides is one edit rather than a search (see the class doc).
static func faction_for(id: Id) -> Faction.Id:
	match id:
		Id.BEAST:
			return Faction.Id.BEAST
		Id.FOG_MASK:
			return Faction.Id.FOG_MASK
	return Faction.Id.BLANK
