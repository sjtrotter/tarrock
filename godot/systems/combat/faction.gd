class_name Faction
extends RefCounted

## Who a fighter fights for, and the only place the sides are spelled.
##
## `docs/design/combat.md` names exactly three hostile families - the Blanks (the
## standard enemy), the Beasts of the Maw and other wild spaces, and the Fog-masks of
## the Mirrormarsh - plus the Fool. Rank and suit scale a Blank's *role*; they do not
## make it a different side, so they are not factions.
##
## Hostility is deliberately simple and deliberately asymmetric-free: the Fool is
## hostile to the other three and they to the Fool, and nothing else fights anything.
## Beasts do not maul Blanks and Fog-masks do not ambush Beasts - the Stall froze the
## world, it did not start a civil war in it. When a fight between two enemy families
## is ever wanted, it is a rule added HERE, once, not a faction check open-coded in a
## behaviour tree.
##
## `WS_STRENGTH_UNBOUND` calming the Beasts and `WS_MOON_UNBOUND` unmasking the
## Fog-masks are aggression rules, not faction changes: a calmed Beast is still a
## Beast. Round 8 (Enemies) owns those; they are named here so nobody adds a
## `CALMED_BEAST` faction to express one.

## A side in a fight.
enum Id {
	## The player.
	FOOL,
	## `combat.md` §Enemies: the Blanks, every suit and every rank.
	BLANK,
	## The wildlife of the Maw and the other wild spaces.
	BEAST,
	## The Mirrormarsh's "monsters", and the lost people under them.
	FOG_MASK,
}

## Every faction, for iteration.
const ALL: Array[Id] = [Id.FOOL, Id.BLANK, Id.BEAST, Id.FOG_MASK]

## The stable key naming each faction, indexed by `Id`. Never displayed: an enemy's
## player-facing name is its definition's `name_key`, resolved through the CSV.
const NAME_KEYS: Array[StringName] = [&"FOOL", &"BLANK", &"BEAST", &"FOG_MASK"]


## The stable key naming a faction. `&""` for an id out of range.
static func name_key(id: Id) -> StringName:
	if id < 0 or id >= NAME_KEYS.size():
		return &""
	return NAME_KEYS[id]


## True when these two sides fight each other: the Fool against any enemy family,
## and nothing else (see the class doc for why).
static func is_hostile(attacker: Id, defender: Id) -> bool:
	if attacker == defender:
		return false
	return attacker == Id.FOOL or defender == Id.FOOL
