class_name HitSpec
extends RefCounted

## One attack's hit, as data: what it is, what it deals, and the space it covers.
##
## A spec is the STATIC half of a hit - everything that is true of "the second light
## swing" whoever swings it, whenever. The moving half (where it came from, which way
## it faced, when) is a `HitEvent`, which carries a spec rather than copying it.
##
## **Specs are allocated once and reused.** `MovesetController` builds its whole set
## in `_init` and hands the same instance back from `active_hit()` for every frame of
## a state; a `Hitbox` holds the spec it was activated with. Nothing in the combat
## loop constructs one (`docs/design/technical.md` §Performance guardrails). Which is
## also why a spec is treated as immutable once built: two hitboxes may be holding
## the same instance.
##
## Shapes are deliberately two: an arc (the light string, the heavy's crowd sweep,
## the charged heavy) and a box (the running attack's lunge, which is a line rather
## than a sweep). Both are resolved against the attacker's facing by the `Hitbox`;
## neither is a collision shape, so a spec can be built and tested with no tree.

## Which move this hit belongs to.
enum Kind {
	## One of the light string's three.
	LIGHT,
	## The wide crowd sweep.
	HEAVY,
	## The stagger launcher.
	CHARGED_HEAVY,
	## The forward lunge.
	RUNNING_ATTACK,
	## Anything an enemy throws. Round 8 gives the families their own moves; until
	## then the training dummy and the tests use this.
	ENEMY_ATTACK,
}

## The space a hit covers.
enum Shape {
	## A wedge of `arc_degrees`, centred on the facing, out to `radius`.
	ARC,
	## A rectangle `box_size.x` across and `box_size.y` along the facing.
	BOX,
}

## Which move this is.
var kind: Kind = Kind.LIGHT

## Health it costs a defender before stagger bonuses and difficulty multipliers.
var damage: int = 0

## Arc or box.
var shape: Shape = Shape.ARC

## The wedge's full angle in degrees, `Shape.ARC` only.
var arc_degrees: float = 0.0

## The wedge's reach, `Shape.ARC` only.
var radius: float = 0.0

## The box as (width across the facing, length along it), `Shape.BOX` only.
var box_size: Vector2 = Vector2.ZERO

## True for the charged heavy: the target is lifted into a helpless stagger
## (`combat.md` §The Bindle).
var applies_stagger: bool = false

## How long that stagger lasts.
var stagger_seconds: float = 0.0

## What this hit is multiplied by when it lands on an already-staggered target - the
## "bonus follow-ups" the launcher opens.
var bonus_vs_staggered: float = 1.0


## Build a spec. Every field is set here because a spec is never edited afterwards
## (see the class doc: instances are shared).
func _init(
	hit_kind: Kind,
	hit_damage: int,
	hit_shape: Shape,
	first_dimension: float,
	second_dimension: float,
	staggers: bool = false,
	stagger_length: float = 0.0,
	staggered_bonus: float = 1.0
) -> void:
	kind = hit_kind
	damage = hit_damage
	shape = hit_shape
	if hit_shape == Shape.BOX:
		box_size = Vector2(first_dimension, second_dimension)
	else:
		arc_degrees = first_dimension
		radius = second_dimension
	applies_stagger = staggers
	stagger_seconds = stagger_length
	bonus_vs_staggered = staggered_bonus


## The farthest a defender can be and still be inside this hit, whatever its shape.
## The `Hitbox` sizes its detector with it.
func reach() -> float:
	if shape == Shape.BOX:
		return maxf(box_size.y, box_size.x * 0.5)
	return radius


## True when `offset` (defender minus attacker, in world space) falls inside this
## hit, given the direction the attacker is facing.
##
## Pure geometry, no nodes, no allocation: the same call answers for a headless test
## and for a live `Hitbox`.
func covers(offset: Vector2, facing: Vector2) -> bool:
	var direction := facing if not facing.is_zero_approx() else Vector2.RIGHT
	direction = direction.normalized()
	if shape == Shape.BOX:
		var along := offset.dot(direction)
		var across := absf(offset.dot(Vector2(-direction.y, direction.x)))
		return along >= 0.0 and along <= box_size.y and across <= box_size.x * 0.5
	if offset.length_squared() > radius * radius:
		return false
	if offset.is_zero_approx():
		return true
	if arc_degrees >= 360.0:
		return true
	return absf(direction.angle_to(offset)) <= deg_to_rad(arc_degrees) * 0.5
