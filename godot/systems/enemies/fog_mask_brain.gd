class_name FogMaskBrain
extends RefCounted

## The Fog-masks' one rule, and deliberately nothing else.
##
## `docs/design/combat.md` §Other enemy families: "the 'monsters' of the Mirrormarsh.
## Revealed as lost people wearing the fog's illusions once `WS_MOON_UNBOUND` fires,
## at which point they **lose their ambush advantage world-wide**. Before that state,
## they read and fight as their masks, not as the people beneath - the reveal is a
## world-state event, not a combat-time twist."
##
## Two things in that paragraph are mechanical and both are here:
##
##   * **The ambush advantage**, which `ambush_bonus()` answers and which is exactly
##     zero once the Moon is unbound. What the bonus DOES - a free first hit, a
##     surprise multiplier, an approach the Fool cannot see coming - is not stated
##     anywhere, so this returns the *fraction of the advantage still standing*
##     (1 or 0) and lets the Mirrormarsh round decide what it buys. A number invented
##     here would be enemy canon written in code.
##   * **`is_revealed()`**, which is a world-state question and never a combat-time
##     one: the doc closes that door explicitly ("not a combat-time twist"), so
##     nothing here can flip a mask mid-fight and nothing should ever add a way.
##
## Like `BeastBrain`, this family gets no stat block, no telegraph timings and no
## scene this round. The Mirrormarsh is the round that gives one a body.

## The advantage a Fog-mask has while the fog still lies for it. A fraction, not a
## mechanic: 1 means "whatever the ambush advantage turns out to be, this one has all
## of it".
const FULL_AMBUSH_ADVANTAGE := 1.0

## What is left of it once the Moon is unbound. `combat.md`: they "lose their ambush
## advantage world-wide" - all of it, everywhere, permanently.
const NO_AMBUSH_ADVANTAGE := 0.0

var _world_state: WorldStateService = null
var _reveal_flag: StringName = &""


## Build a Fog-mask's state over the world state and the flag that reveals its
## family. The flag comes off the `EnemyDefinition` (`reveal_flag`), generated from
## the doc; it is never typed here.
func _init(world_state: WorldStateService, reveal_flag: StringName) -> void:
	_world_state = world_state
	_reveal_flag = reveal_flag


## True once the fog has stopped lying: the reveal flag has fired, world-wide and for
## good (`WS_*` flags never un-fire).
func is_revealed() -> bool:
	if _world_state == null or _reveal_flag == &"":
		return false
	return _world_state.is_fired(_reveal_flag)


## How much of the ambush advantage this Fog-mask still has: `FULL_AMBUSH_ADVANTAGE`
## before the reveal, `NO_AMBUSH_ADVANTAGE` after it.
func ambush_bonus() -> float:
	return NO_AMBUSH_ADVANTAGE if is_revealed() else FULL_AMBUSH_ADVANTAGE


## True while this Fog-mask can still open a fight from ambush.
func has_ambush_advantage() -> bool:
	return ambush_bonus() > 0.0
