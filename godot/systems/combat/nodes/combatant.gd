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
## **The Fool's pool is not here.** Per the director's ruling on issue #11 the White
## Rose's petals ARE the Fool's health, so the Fool's Combatant is handed a
## `Vitality` (a `RoseVitality`, built by `CombatService.register_fool()`) and every
## health question it is asked is forwarded to the Rose. Everything above still holds
## exactly as written - the hit rule, the defence, `died` at zero - because the only
## thing that changed is WHERE the number is kept. Enemies keep their own field and
## are unaffected.
##
## One consequence is worth stating: with `vitality` set, health is counted in QUARTER
## PETALS (`WhiteRoseService.QUARTERS_PER_PETAL`), so an enemy's `HitSpec.damage`
## against the Fool is in quarter petals and `data/enemies/enemy_rules.tres` is
## authored in them. The Fool's own swings are still in enemy-pool points; the two
## sides of a fight have never shared a scale and do not start now.

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

## The smallest a landed hit may be worth once every multiplier has had its say. See
## `_resolve()` for why a hit that meant to cost something may not round to nothing.
const MIN_LANDED_DAMAGE := 1

## The side this Combatant fights for.
@export var faction: Faction.Id = Faction.Id.BLANK

## The pool's size. Set in the editor for authored enemies; set from `CombatRules`
## for the Fool.
@export var max_health: int = 40

## Asked before every hit. Never null - the base class is the "just stands there"
## answer (see the class doc).
var defense: CombatDefense = CombatDefense.new()

## Where this body's health actually lives, when it does not live here. Null for
## everything but the Fool; see the class doc. `max_health` is ignored while it is
## set, so a scene that authored one and a service that handed one over cannot
## disagree.
var vitality: Vitality = null

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
	if vitality != null:
		return vitality.quarters()
	if not _initialised:
		_health = max_health
		_initialised = true
	return _health


## The pool's size.
func health_capacity() -> int:
	if vitality != null:
		return vitality.max_quarters()
	return max_health


## Health left as a fraction of the pool, for a bar to draw.
func health_fraction() -> float:
	var capacity := health_capacity()
	if capacity <= 0:
		return 0.0
	return float(health()) / float(capacity)


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
## is 0 at full health.
##
## Nothing in the shipped kit calls this on the Fool: the Rose regrows on its own
## clock and at a Waystation, and there is no heal button (issue #11). It stays
## because a Trump effect that gives petals back is written in `arcana.md` and this
## is the door it will come through.
func heal(amount: int) -> int:
	if amount <= 0 or not is_alive():
		return 0
	if vitality != null:
		var given := vitality.give(amount)
		if given > 0:
			healed.emit(given, health())
		return given
	var target := mini(health() + amount, max_health)
	var restored := target - _health
	if restored <= 0:
		return 0
	_health = target
	healed.emit(restored, _health)
	return restored


## Resize the pool. `refill` tops it back up, which is what a permanent upgrade would
## want. Ignored while a `Vitality` is set: the Fool's capacity is the Rose's, raised
## by graftings and by nothing else.
func set_max_health(value: int, refill: bool = true) -> void:
	if vitality != null:
		return
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
	_stagger_left = 0.0
	if vitality != null:
		var missing := vitality.max_quarters() - vitality.quarters()
		vitality.fill()
		if missing > 0:
			healed.emit(missing, health())
		return
	var restored := max_health - _health
	_health = max_health
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
	# A swing that was AIMED to cost something always costs something. At quarter-petal
	# resolution the Fool's pool is small enough that Story's halved damage, a Coins
	# Blank's armour or a low rank curve can multiply a real hit down to zero, and an
	# enemy whose attacks are free is not a difficulty setting - it is an enemy the
	# player can stand still in front of. A spec that deals no damage on purpose (a
	# shove, a training dummy's) still lands for nothing, which is the case the zero
	# below is for.
	if taken <= 0 and spec.damage > 0:
		taken = MIN_LANDED_DAMAGE
	if taken > 0:
		taken = _apply_damage(taken)
		damaged.emit(taken, health())
	# `health()` rather than `_health`: a Combatant built in code and never `_ready`
	# holds an unfilled pool until something asks, and a hit that took nothing off (a
	# zero-damage spec) never asks. Reading the field directly would report that body
	# dead on the first harmless hit - and would read the wrong pool entirely for the
	# Fool, whose health lives in the Rose.
	if health() <= 0:
		_stagger_left = 0.0
		died.emit()
		return HitResult.Id.KILLED
	if spec.applies_stagger:
		apply_stagger(spec.stagger_seconds)
	return HitResult.Id.STAGGERED_HIT if landed_on_staggered else HitResult.Id.DAMAGED


## Take `taken` off whichever pool this body's health lives in, and answer what was
## actually taken - which is less than asked for when the pool ran out first.
func _apply_damage(taken: int) -> int:
	if vitality != null:
		return vitality.take(taken)
	var before := health()
	_health = maxi(0, before - taken)
	return before - _health
