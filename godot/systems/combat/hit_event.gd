class_name HitEvent
extends RefCounted

## One hit actually being thrown: a `HitSpec` plus where, which way and when.
##
## The event is the MOVING half of a hit (the spec is the static half), and it is
## **reused, not reallocated**: a `Hitbox` owns one and calls `configure()` for each
## hit it lands, so a fight that lands a thousand hits allocates one event per hitbox
## (`docs/design/technical.md` §Performance guardrails). A receiver that needs to
## keep an event past the call that handed it one must copy the fields it wants;
## by the next hit this instance says something else.

## The side that threw it, so a `Combatant` can refuse a hit from its own side.
var attacker_faction: Faction.Id = Faction.Id.BLANK

## What the hit is. Shared and never edited - see `HitSpec`.
var spec: HitSpec = null

## Where the attacker was, in world space, when the hit landed.
var origin: Vector2 = Vector2.ZERO

## The attacker's facing when the hit landed; the direction knockback and the
## block-step's reposition are read off.
var direction: Vector2 = Vector2.RIGHT

## In-game seconds (`GameClock`) at the moment it landed, or 0 when nobody stamped it.
var time: float = 0.0


## Build an event. Every argument has a default so a `Hitbox` can allocate one bare
## in `_ready` and fill it in later with `configure()`.
func _init(
	faction: Faction.Id = Faction.Id.BLANK,
	hit_spec: HitSpec = null,
	hit_origin: Vector2 = Vector2.ZERO,
	hit_direction: Vector2 = Vector2.RIGHT,
	hit_time: float = 0.0
) -> void:
	configure(faction, hit_spec, hit_origin, hit_direction, hit_time)


## Point this event at a new hit, in place. The whole reason the class exists.
func configure(
	faction: Faction.Id,
	hit_spec: HitSpec,
	hit_origin: Vector2,
	hit_direction: Vector2,
	hit_time: float
) -> void:
	attacker_faction = faction
	spec = hit_spec
	origin = hit_origin
	direction = hit_direction
	time = hit_time


## The damage on the spec, or 0 when there is no spec.
func damage() -> int:
	return 0 if spec == null else spec.damage
