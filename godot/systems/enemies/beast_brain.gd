class_name BeastBrain
extends RefCounted

## The Beasts' one rule, and deliberately nothing else.
##
## `docs/design/combat.md` §Other enemy families gives the Beasts exactly one
## sentence of behaviour: "the wildlife of the Maw and other wild spaces. Hostile by
## default; calmed to neutral-until-provoked world-wide once `WS_STRENGTH_UNBOUND`
## fires." That sentence is a **world-state rule**, not a moveset, and it is the only
## thing about the Beasts that any doc states. So this class is the rule and nothing
## more: no stat block, no telegraph timings, no scene, no art.
##
## Building a Beast moveset here would be inventing enemy canon in code, which is the
## thing briefs forbid; the Maw round (`world.md` §Regions) is where a Beast gets a
## body. What this does buy today is that the flag is wired, tested, and impossible to
## get wrong later: whatever the Beasts turn out to fight like, `stance()` is where
## "are they hostile right now" is answered, once, world-wide.
##
## "World-wide" is load-bearing and is why this reads `WorldStateService` rather than
## a region or an encounter: `WS_*` flags never un-fire, so once Strength is unbound
## every Beast everywhere is calm for the rest of the game.
##
## **Neutral is not friendly.** `NEUTRAL_UNTIL_PROVOKED` means a Beast ignores the
## Fool until the Fool hits it - `provoke()` is that, and it is per-creature and lasts
## as long as that creature does. A calmed Beast is still a `Faction.Id.BEAST`; no
## `CALMED_BEAST` faction exists and none should (see `Faction`'s class doc).

## How a Beast stands toward the Fool.
enum Stance {
	## The default: it attacks on sight.
	HOSTILE,
	## After `WS_STRENGTH_UNBOUND`: it ignores the Fool until struck.
	NEUTRAL_UNTIL_PROVOKED,
	## It was struck anyway. Hostile again, for this creature, for good.
	PROVOKED,
}

## Every stance, for iteration.
const ALL_STANCES: Array[Stance] = [
	Stance.HOSTILE,
	Stance.NEUTRAL_UNTIL_PROVOKED,
	Stance.PROVOKED,
]

var _world_state: WorldStateService = null
var _calming_flag: StringName = &""
var _provoked: bool = false


## Build a Beast's stance over the world state and the flag that calms its family.
## The flag comes off the `EnemyDefinition` (`calming_flag`), which is generated from
## the doc - it is never typed here.
func _init(world_state: WorldStateService, calming_flag: StringName) -> void:
	_world_state = world_state
	_calming_flag = calming_flag


## How this Beast stands toward the Fool right now.
func stance() -> Stance:
	if _provoked:
		return Stance.PROVOKED
	if not is_calmed():
		return Stance.HOSTILE
	return Stance.NEUTRAL_UNTIL_PROVOKED


## True when the world has been calmed: the calming flag has fired.
func is_calmed() -> bool:
	if _world_state == null or _calming_flag == &"":
		return false
	return _world_state.is_fired(_calming_flag)


## True when this Beast would attack the Fool unprompted.
func is_hostile_on_sight() -> bool:
	return stance() != Stance.NEUTRAL_UNTIL_PROVOKED


## The Fool hit it. A provoked Beast stays provoked: "neutral-until-provoked" is a
## promise about the first move, not a temper that cools.
func provoke() -> void:
	_provoked = true


## True once this Beast has been provoked.
func is_provoked() -> bool:
	return _provoked


## Put this Beast back to how it started, for a body going back to a pool.
func reset() -> void:
	_provoked = false
