class_name BlankPerception
extends RefCounted

## Everything a `BlankBrain` is allowed to know about the world this frame.
##
## The brain has no tree, no nodes and no scene: it is handed one of these and a
## delta, and answers with a state and a movement intent. That is what makes an
## enemy's whole behaviour headlessly testable - a test fills these fields by hand
## and drives frame by explicit frame, with no physics and no clock.
##
## **It is reused, not reallocated.** A `Blank` owns exactly one and refills it every
## physics frame, so a fight with fifty Blanks allocates fifty of these ever
## (`docs/design/technical.md` §Performance guardrails: no per-frame allocation in
## AI loops). A receiver that wants to keep one past the call it was handed in must
## copy the fields it wants.
##
## Note what is NOT in here: any node, any `Combatant`, any service. A brain that
## could reach a `Combatant` would start reading health off it mid-decision, and the
## rule that systems never reach into scenes would be gone.

## Where this enemy is standing, in world space.
var self_position: Vector2 = Vector2.ZERO

## Which way it is facing, as a unit vector.
var self_facing: Vector2 = Vector2.RIGHT

## Where the Fool is, in world space. Only meaningful when `has_target`.
var target_position: Vector2 = Vector2.ZERO

## True when there is a target at all - before an encounter starts there is not.
var has_target: bool = false

## True when the target can actually be perceived. Separate from `has_target` on
## purpose: `combat.md` §Other enemy families gives the Fog-masks an ambush advantage
## that a later round expresses by leaving this false while the fog holds.
var target_visible: bool = false

## How far away the target is, in pixels. `INF` when there is none.
var distance_to_target: float = INF

## How many living allies stand within the aura/alert radius being asked about.
var allies_nearby: int = 0

## Where the nearest living ally is. Only meaningful when `has_nearest_ally`.
var nearest_ally_position: Vector2 = Vector2.ZERO

## True when there is a living ally to run to. The Page needs one to flee toward.
var has_nearest_ally: bool = false

## Health left as a fraction of the pool, 0..1.
var health_fraction: float = 1.0

## True while the body is in the charged heavy's helpless window. A staggered enemy
## drops whatever it was doing (`combat.md` §The Bindle).
var staggered: bool = false


## Put every field back to "nothing known". Called before each refill so a field
## nobody sets this frame cannot carry last frame's answer.
func clear() -> void:
	self_position = Vector2.ZERO
	self_facing = Vector2.RIGHT
	target_position = Vector2.ZERO
	has_target = false
	target_visible = false
	distance_to_target = INF
	allies_nearby = 0
	nearest_ally_position = Vector2.ZERO
	has_nearest_ally = false
	health_fraction = 1.0
	staggered = false


## Point this perception at a target, filling `distance_to_target` from the two
## positions so no caller can set a distance that disagrees with them.
func see_target(position: Vector2, visible_now: bool = true) -> void:
	target_position = position
	has_target = true
	target_visible = visible_now
	distance_to_target = self_position.distance_to(position)


## The unit vector from this enemy toward its target, or `Vector2.ZERO` when there is
## none or it is standing on top of it.
func direction_to_target() -> Vector2:
	if not has_target:
		return Vector2.ZERO
	var offset := target_position - self_position
	if offset.is_zero_approx():
		return Vector2.ZERO
	return offset.normalized()
