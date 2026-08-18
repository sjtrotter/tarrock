class_name HitResult
extends RefCounted

## What became of one hit, as answered by the `Combatant` that received it.
##
## Every branch of `docs/design/combat.md` §Defense is a member here, so a caller
## reads one value rather than a bool and three out-parameters: a dodge with i-frames
## up, the same dodge timed to "the final instant before a hit lands" (Fool's Chance),
## the block-step that "absorbs a hit and repositions", an ordinary hit, a hit into
## the charged heavy's "brief helpless stagger", and the hit that empties the pool.
##
## `IGNORED` is the one member that is not an outcome of the hit rule at all: it is
## the answer to a hit that was never eligible to land - a swing from the defender's
## own side (`Faction.is_hostile()` says no), or an event with no spec behind it. It is
## deliberately distinct from `BLOCKED`: a hit refused because the two sides are
## friends did not cost anybody a guard, and reading it as a block would have the Fool
## "absorb" a hit that was never coming.
##
## `KILLED` is the mechanical name for a health pool reaching zero and nothing more.
## Nothing in Tarrock dies of it: a Blank "slumps and fades while the card it bore
## flutters free" (`combat.md` §Enemies), the Fool falls and wakes at a Waystation
## (§Defeat), Pip cannot be reduced past a retreat (§Pip). What happens next is the
## receiver's business; this enum only says the pool is empty.

## What one hit did.
enum Id {
	## Health was lost.
	DAMAGED,
	## Health reached zero. See the class doc: nothing here dies.
	KILLED,
	## The block-step ate it: no damage, and the hop repositions.
	BLOCKED,
	## I-frames were up, but the dodge started too early to be perfect.
	DODGED,
	## I-frames were up AND the dodge started inside the perfect window: this is
	## the hit that triggers Fool's Chance.
	DODGED_PERFECT,
	## It landed on a staggered target, so it paid the stagger bonus.
	STAGGERED_HIT,
	## The hit was never eligible: same side, or no spec to deliver. Nothing was
	## evaded, nothing landed, nothing was spent.
	IGNORED,
}

## Every outcome, for iteration.
const ALL: Array[Id] = [
	Id.DAMAGED,
	Id.KILLED,
	Id.BLOCKED,
	Id.DODGED,
	Id.DODGED_PERFECT,
	Id.STAGGERED_HIT,
	Id.IGNORED,
]


## True when the hit did no damage because the defender ANSWERED it - a guard, a
## dodge, a perfectly-timed dodge. `IGNORED` is not one of these: nobody answered a
## hit that was never eligible.
static func was_evaded(result: Id) -> bool:
	return result == Id.BLOCKED or result == Id.DODGED or result == Id.DODGED_PERFECT


## True when the hit connected and cost the defender health. Spelled out rather than
## written as `not was_evaded()`, so a member that is neither (today `IGNORED`) is
## neither - a hit at a friend is not a hit that landed, and must not pay Fortune.
static func was_landed(result: Id) -> bool:
	return result == Id.DAMAGED or result == Id.KILLED or result == Id.STAGGERED_HIT


## True when the hit was never eligible to land: same side, or no spec.
static func was_ignored(result: Id) -> bool:
	return result == Id.IGNORED
