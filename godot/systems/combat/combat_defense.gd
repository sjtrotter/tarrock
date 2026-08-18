class_name CombatDefense
extends RefCounted

## What a `Combatant` asks before it takes a hit.
##
## A Combatant knows how to lose health; it does NOT know about i-frames, block-steps,
## Fool's Chance or difficulty modes, because a Blank has none of those and the Fool
## has all of them. So the whole question is delegated to one of these, and the base
## class is the honest answer for everything that just stands there and gets hit.
##
## `FoolDefense` is the Fool's, and it answers out of the `MovesetController` and the
## `CombatService`. Round 8's enemies may grow their own (a Coins Blank's shield is a
## `is_blocking()` that means something).
##
## Every method is called on the hit path, so none of them allocates.


## True when the defender cannot be hit at all right now (`combat.md` §Defense:
## i-frames "covering the commit window" of a dodge).
func is_invulnerable() -> bool:
	return false


## True when the defender is guarding: the hit is absorbed for no damage rather than
## evaded (`combat.md` §Defense, the block-step).
func is_blocking() -> bool:
	return false


## True when the evasion happening right now was timed to "the final instant before a
## hit lands" - the Fool's Chance test. Only meaningful while `is_invulnerable()`.
func is_perfect_dodge() -> bool:
	return false


## What incoming damage is multiplied by before it is applied. The difficulty modes'
## "reduced damage taken" lives here (`combat.md` §Difficulty modes).
func damage_multiplier() -> float:
	return 1.0


## Told what became of the hit, after the Combatant applied it. This is where the
## Fool's side turns a perfectly-timed dodge into Fool's Chance.
func on_hit_resolved(_result: HitResult.Id, _event: HitEvent) -> void:
	pass
