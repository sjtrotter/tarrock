class_name Combatant
extends Node2D

## Anything in Tarrock that can be hit: the Fool, a Blank, a Beast, a Fog-mask.
##
## It owns exactly one fact - a health pool - and one rule: what a `HitEvent` does to
## it. Everything else about being hit is delegated, on purpose:
##
##   * **Whether the hit connects at all** is the `CombatDefense`'s (i-frames, the
##     hop-guard, the difficulty's damage multiplier). A Combatant with the base
##     `CombatDefense` just stands there and takes it, which is the correct behaviour
##     for a training dummy and for most of a Blank's life.
##   * **What happens at zero** is the owner's. `died` is emitted and nothing else:
##     `combat.md` is emphatic that nothing in the Spread truly ends - a Blank "slumps
##     and fades while the card it bore flutters free", the Fool wakes at a Waystation
##     (§Defeat), Pip retreats and comes back (§Pip). Deciding which of those this is
##     would be this class overstepping.
##
## The stagger the charged heavy opens (`combat.md` §The Bindle: "the target is lifted
## off its feet into a brief helpless stagger that opens bonus follow-ups") lives here
## because it is a property of the body, not of the swing: a staggered Combatant is
## helpless, and the next hit into it pays `HitSpec.bonus_vs_staggered`.
##
## PER GAUNTLET RULING PENDING ISSUE #11: the Fool's health pool is a Combatant like
## any other, and White Rose petals heal it (`CombatService.use_rose()`). There is one
## health model in the game, not a petal model for the Fool and a health model for
## everybody else.

## Health was lost. `amount` is what was actually taken off, after multipliers.
signal damaged(amount: int, remaining: int)

## Health was restored.
signal healed(amount: int, remaining: int)

## The pool reached zero. See the class doc: this is not a death.
signal died()

## A hit knocked this Combatant into the helpless window.
signal staggered(seconds: float)

## The stagger ran out.
signal recovered()

## The side this Combatant fights for.
@export var faction: Faction.Id = Faction.Id.BLANK

## The pool's size. Set in the editor for authored enemies; set from `CombatRules`
## for the Fool.
@export var max_health: int = 40

## Asked before every hit. Never null - the base class is the "just stands there"
## answer (see the class doc).
var defense: CombatDefense = CombatDefense.new()

var _health: int = 0

## Seconds of helplessness left, or 0.
var _stagger_left: float = 0.0

## True once `_ready` (or `set_max_health`) has filled the pool, so a Combatant built
## bare in a test still starts alive.
var _initialised: bool = false


func _ready() -> void:
	if not _initialised:
		_health = max_health
		_initialised = true


func _physics_process(delta: float) -> void:
	advance(delta)


# --- Reading -----------------------------------------------------------------


## Health left.
func health() -> int:
	if not _initialised:
		_health = max_health
		_initialised = true
	return _health


## The pool's size.
func health_capacity() -> int:
	return max_health


## Health left as a fraction of the pool, for a bar to draw.
func health_fraction() -> float:
	if max_health <= 0:
		return 0.0
	return float(health()) / float(max_health)


## True while there is health left.
func is_alive() -> bool:
	return health() > 0


## True during the charged heavy's helpless window.
func is_staggered() -> bool:
	return _stagger_left > 0.0


## Seconds of stagger left.
func stagger_seconds_left() -> float:
	return _stagger_left


# --- Being hit ---------------------------------------------------------------


## Take one hit, and answer what became of it.
##
## The order is the order `combat.md` §Defense reads in, and it matters: evasion
## first (a dodge beats everything, including a stagger), then the guard, then the
## damage. A hit that lands on a staggered target pays the bonus; a hit that
## staggers cannot also pay the bonus for a stagger it caused. Nothing staggers a
## body whose pool the same hit emptied.
##
## A hit from the defender's own side is refused outright: `Faction.is_hostile()` is
## the only place sides are decided. It answers `IGNORED`, not `BLOCKED` - a swing
## from a friend costs nobody a guard - and the defence is NOT told about it: a hit
## that was never eligible must not spend a block-step's absorb or report a dodge
## that never happened.
func take_hit(event: HitEvent) -> HitResult.Id:
	if event == null or event.spec == null:
		return HitResult.Id.IGNORED
	if not Faction.is_hostile(event.attacker_faction, faction):
		return HitResult.Id.IGNORED
	var result := _resolve(event)
	defense.on_hit_resolved(result, event)
	return result


## Restore health, capped at the pool. Returns how much was actually restored, which
## is 0 at full health - the caller decides whether that is a refusal (it is, for the
## White Rose: see `CombatService.use_rose()`).
func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	var target := mini(health() + amount, max_health)
	var restored := target - _health
	if restored <= 0:
		return 0
	_health = target
	healed.emit(restored, _health)
	return restored


## Resize the pool. `refill` tops it back up, which is what building the Fool from
## `CombatRules` wants and what a permanent upgrade would want.
func set_max_health(value: int, refill: bool = true) -> void:
	max_health = maxi(1, value)
	_initialised = true
	if refill:
		_health = max_health
	else:
		_health = mini(_health, max_health)


## Back to full, standing, unstaggered. The defeat loop's return leg
## (`combat.md` §Defeat: the Fool wakes "White Rose regrown", no penalty).
func restore_full_health() -> void:
	_initialised = true
	var restored := max_health - _health
	_health = max_health
	_stagger_left = 0.0
	if restored > 0:
		healed.emit(restored, _health)


## Knock this Combatant into the helpless window. Re-staggering refreshes it rather
## than stacking: two launchers do not make a target helpless for twice as long.
func apply_stagger(seconds: float) -> void:
	if seconds <= 0.0 or not is_alive():
		return
	var was_staggered := is_staggered()
	_stagger_left = maxf(_stagger_left, seconds)
	if not was_staggered:
		staggered.emit(_stagger_left)


## Count the stagger down. Called from `_physics_process`, and callable directly by a
## test that drives its own frames.
func advance(delta: float) -> void:
	if delta <= 0.0 or _stagger_left <= 0.0:
		return
	_stagger_left -= delta
	if _stagger_left <= 0.0:
		_stagger_left = 0.0
		recovered.emit()


# --- Internals ---------------------------------------------------------------


## The whole hit rule. Returns what became of the hit; emits as it goes.
func _resolve(event: HitEvent) -> HitResult.Id:
	if defense.is_invulnerable():
		return (
			HitResult.Id.DODGED_PERFECT
			if defense.is_perfect_dodge()
			else HitResult.Id.DODGED
		)
	if defense.is_blocking():
		return HitResult.Id.BLOCKED
	var spec := event.spec
	var landed_on_staggered := is_staggered()
	var amount := float(spec.damage)
	if landed_on_staggered:
		amount *= spec.bonus_vs_staggered
	amount *= defense.damage_multiplier()
	var taken := maxi(0, int(roundf(amount)))
	if taken > 0:
		_health = maxi(0, health() - taken)
		damaged.emit(taken, _health)
	# `health()` rather than `_health`: a Combatant built in code and never `_ready`
	# holds an unfilled pool until something asks, and a hit that took nothing off
	# (a zero-damage spec, a multiplier that rounded to nothing) never asks. Reading
	# the field directly would report that body dead on the first harmless hit.
	if health() <= 0:
		_stagger_left = 0.0
		died.emit()
		return HitResult.Id.KILLED
	if spec.applies_stagger:
		apply_stagger(spec.stagger_seconds)
	return HitResult.Id.STAGGERED_HIT if landed_on_staggered else HitResult.Id.DAMAGED
