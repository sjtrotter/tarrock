class_name NpcRank
extends RefCounted

## The Court ranks, as an NPC IDENTITY - the thing a crowd is read by.
##
## `docs/design/characters.md` §The Courts: Pages, Knights, Queens and Kings are
## "social ranks within each suit-culture", and `docs/design/npc-system.md` §Named vs.
## ambient NPCs says an ambient Minor is identified "by **visible suit + Court rank**
## (dress, insignia, bearing)". So rank is half of who an ambient NPC is, and it is a
## bark condition for exactly that reason.
##
## **This is NOT the enemy `Rank`.** The Blanks share the four words and are explicitly
## not these people - "what a suit's faceless soldiery looks like when the Stall has
## worn away everything but the office" (`characters.md` §The Courts, and `combat.md`
## for how the two never overlap on screen). Reusing the enemy roster's enum here would
## quietly say a Queen of Cups in a market and a Queen of Cups with a sword are the
## same kind of thing, so this is its own vocabulary and stays that way.

## An NPC's standing in their suit-culture. `NONE` is the commons - most of the
## population - and is a real answer, not a missing one.
enum Id {
	NONE,
	PAGE,
	KNIGHT,
	QUEEN,
	KING,
}

## Every rank, for iteration.
const ALL: Array[Id] = [Id.NONE, Id.PAGE, Id.KNIGHT, Id.QUEEN, Id.KING]

## A bark condition that does not care what rank the speaker holds. Not a rank: it is
## the ABSENCE of the condition, which is why it is negative and outside the enum,
## exactly as `Suit.UNKNOWN` is.
const ANY := -1

## The stable key for each rank, indexed by `Id`. Ids and save data use these; a
## player-facing rank name would be a translation key resolved elsewhere.
const NAME_KEYS: Array[StringName] = [&"NONE", &"PAGE", &"KNIGHT", &"QUEEN", &"KING"]


## The stable key naming a rank, e.g. `&"KNIGHT"`, or `&""` for no such rank.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## The rank a key names, or `ANY` (-1) when it names none.
static func from_name_key(key: StringName) -> int:
	return NAME_KEYS.find(key)


## True when `value` is a rank, or the "any rank" wildcard.
static func is_condition(value: int) -> bool:
	return value == ANY or (value >= 0 and value < NAME_KEYS.size())
