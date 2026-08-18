class_name TrainingDummy
extends Combatant

## A TEST FIXTURE, not game content: something that stands still, can be hit, and
## swings back on command.
##
## Round 8 owns the real enemies - the Blanks by suit and rank, the Beasts, the
## Fog-masks (`docs/design/combat.md` §Enemies). This exists only so round 7's combat
## loop has something to prove itself against: a body with a `Hurtbox` the Fool's
## swings can find, and a `Hitbox` on a **telegraph -> active -> recovery** rota the
## Fool's dodges and block-step can be timed against. It deliberately has no AI, no
## aggression, no suit and no rank - inventing any of those here would be inventing
## enemy canon in a fixture, which is exactly the thing briefs forbid.
##
## The rota is the one thing it does share with a real enemy, because
## `combat.md` §Philosophy makes it non-negotiable: "Every enemy telegraphs before it
## commits". `time_until_hit()` is the fixture's own affordance - it lets a test press
## dodge a known number of seconds before the hit lands without ever counting frames
## against a wall clock.

## Nothing is being swung.
const IDLE_PHASE := 0

## The telegraph is running; the hit has not landed.
const TELEGRAPH_PHASE := 1

## The hit window is open.
const ACTIVE_PHASE := 2

## The swing is over; the dummy is putting itself back together.
const RECOVERY_PHASE := 3

## The dummy started telegraphing.
signal telegraph_started()

## The hit window opened.
signal attack_active()

## The swing is finished and the dummy is idle again.
signal attack_finished()

## How long the telegraph runs before the hit lands.
@export var telegraph_seconds: float = 0.50

## How long the hit window stays open.
@export var active_seconds: float = 0.10

## How long the dummy takes to recover afterwards.
@export var recovery_seconds: float = 0.40

## What the swing deals, before the Fool's difficulty multiplier.
## What one of its swings costs, in the QUARTER PETALS the Fool's White Rose is
## counted in (issue #11 - the petals ARE the health). Small on purpose: the arena's
## defensive phases are about whether a hit lands at all, and a dummy that could
## one-shot a twelve-quarter Fool would turn a timing slip into a defeat loop.
@export var attack_damage: int = 3

## How far the swing reaches.
@export var attack_radius: float = 160.0

## How wide the swing is. Generous, because a fixture that missed because the Fool
## drifted two pixels would be a flaky test rather than a finding.
@export var attack_arc_degrees: float = 200.0

## Which way it swings when `attack()` is not given a direction.
var facing: Vector2 = Vector2.LEFT

var _phase: int = IDLE_PHASE
var _phase_time: float = 0.0
var _spec: HitSpec = null
var _hitbox: Hitbox = null


func _ready() -> void:
	super()
	_spec = HitSpec.new(
		HitSpec.Kind.ENEMY_ATTACK,
		attack_damage,
		HitSpec.Shape.ARC,
		attack_arc_degrees,
		attack_radius
	)
	for child: Node in get_children():
		var hitbox := child as Hitbox
		if hitbox != null:
			_hitbox = hitbox
			break
	if _hitbox != null:
		_hitbox.configure(faction, attack_radius)
		_hitbox.deactivate()


## Start a swing. Ignored while one is already running.
func attack(direction: Vector2 = Vector2.ZERO) -> void:
	if _phase != IDLE_PHASE or not is_alive():
		return
	if not direction.is_zero_approx():
		facing = direction.normalized()
	_phase = TELEGRAPH_PHASE
	_phase_time = 0.0
	telegraph_started.emit()


## Which part of the rota the dummy is in.
func attack_phase() -> int:
	return _phase


## True while a swing is running.
func is_attacking() -> bool:
	return _phase != IDLE_PHASE


## Seconds until the hit lands, or `INF` when no swing is running and 0 once it has
## landed. This is what a test times a dodge against - never a clock.
func time_until_hit() -> float:
	if _phase == IDLE_PHASE:
		return INF
	if _phase != TELEGRAPH_PHASE:
		return 0.0
	return maxf(0.0, telegraph_seconds - _phase_time)


## Advance the rota along with the stagger `Combatant` already counts down. A
## staggered dummy is helpless: its swing is dropped, which is what the charged
## heavy's launcher is for.
func advance(delta: float) -> void:
	super(delta)
	if _phase == IDLE_PHASE or delta <= 0.0:
		return
	if is_staggered():
		_cancel()
		return
	_phase_time += delta
	match _phase:
		TELEGRAPH_PHASE:
			if _phase_time >= telegraph_seconds:
				_phase = ACTIVE_PHASE
				_phase_time = 0.0
				if _hitbox != null:
					_hitbox.activate(_spec, facing)
				attack_active.emit()
		ACTIVE_PHASE:
			if _phase_time >= active_seconds:
				_phase = RECOVERY_PHASE
				_phase_time = 0.0
				if _hitbox != null:
					_hitbox.deactivate()
		RECOVERY_PHASE:
			if _phase_time >= recovery_seconds:
				_cancel()


## Stop swinging outright, whatever part of the rota it was in. A test calls this to
## put the fixture back to a known standing state before timing the next beat.
func cancel_attack() -> void:
	_cancel()


## Stop swinging, whatever part of the rota it was in.
func _cancel() -> void:
	var was_attacking := _phase != IDLE_PHASE
	_phase = IDLE_PHASE
	_phase_time = 0.0
	if _hitbox != null:
		_hitbox.deactivate()
	if was_attacking:
		attack_finished.emit()
