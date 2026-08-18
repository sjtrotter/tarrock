class_name Vitality
extends RefCounted

## A pool of life that lives OUTSIDE the `Combatant` holding it.
##
## Every enemy in Tarrock carries its own health field and needs nothing else. The
## Fool does not: the director's ruling on issue #11 is that the White Rose's petals
## ARE the Fool's health, and the Rose is a progression service that outlives every
## scene, holds world state, saves itself, and is read by Trump effects. Copying its
## number into a `Combatant` every frame would be two sources for one fact, and the
## copy would be the one the fight wrote to.
##
## So a Combatant may be handed one of these instead, and every health question it is
## asked is forwarded here. `RoseVitality` is the only implementation; this base
## class exists so `Combatant` depends on a shape in its own folder rather than on
## `systems/trumps/`, and so a test can hand one a stub.
##
## The unit is the QUARTER PETAL (`WhiteRoseService.QUARTERS_PER_PETAL`) - see that
## service for why the pool is counted four times finer than it is drawn. Anything
## that hits the Fool therefore deals damage in quarter petals, which is what
## `data/enemies/enemy_rules.tres` is authored in.
##
## Every method is called on the hit path, so none of them allocates.


## Quarter petals left.
func quarters() -> int:
	return 0


## Quarter petals this pool holds when it is whole.
func max_quarters() -> int:
	return 0


## Take `amount` quarters off, and answer how many were actually taken.
func take(_amount: int) -> int:
	return 0


## Give `amount` quarters back, and answer how many were actually restored.
func give(_amount: int) -> int:
	return 0


## Fill the pool. The defeat loop's return leg, and a Waystation rest.
func fill() -> void:
	pass


## True when there is nothing left.
func is_bare() -> bool:
	return true
