class_name CoinsShield
extends CombatDefense

## A Coins Blank's shield: the `CombatDefense` that makes the suit "built to be
## broken through rather than out-traded".
##
## `docs/design/combat.md` §Enemies: the Blanks gives Coins one sentence - "Heavy
## shielded bruisers - slow, armored, built to be broken through rather than
## out-traded" - and this is the whole mechanical reading of it:
##
##   * **Shielded.** A hit arriving from inside the shield's wedge is absorbed
##     (`HitResult.BLOCKED`), so the Fool earns nothing for it and takes nothing off.
##   * **Broken through.** The wedge is a wedge: it faces where the Blank faces, so
##     walking round the back is the answer, and the arc is `EnemyRules`'.
##   * **Armored.** Whatever gets past it is multiplied down by
##     `EnemyRules.coins_armour_multiplier`, which is the part a player cannot
##     side-step.
##
## **Why it reads a bearing rather than the hit.** `Combatant` asks its defence
## `is_blocking()` with no arguments, and that contract is round 7's and is not
## changed here. So the shield is told, every physics frame, which way its bearer
## faces and where the threat it is guarding against stands - which is what a shield
## IS: something held up in a direction, not something that inspects each incoming
## blow. A Fool who circles behind between the telegraph and the hit gets past it,
## which is the behaviour the doc asks for and is the reason this is frame-accurate
## rather than hit-accurate.
##
## Nothing here allocates: `is_blocking()` is on the hit path.

## What `block_chance` has to reach before no random number is drawn at all. A shield
## authored at 1.0 is deterministic, which is what every test and every honest
## telegraph-and-answer fight wants.
const CERTAIN := 1.0

## The full angle of the shield in degrees, centred on the bearer's facing.
var _arc_degrees: float = 0.0

## How often a hit inside the arc is stopped, 0..1.
var _chance: float = 0.0

## What a hit that gets past is multiplied by.
var _armour: float = 1.0

## Which way the bearer faces.
var _facing: Vector2 = Vector2.RIGHT

## Where the threat is, relative to the bearer. Zero means "nothing to guard".
var _threat_offset: Vector2 = Vector2.ZERO

## False while the shield is down: a Blank that is staggered, defeated or mid-swing
## is not guarding.
var _raised: bool = false

## Drawn from only when `_chance` is below `CERTAIN`. Owned rather than global so a
## test can seed it and get the same fight twice.
var _rng: RandomNumberGenerator = null


## Build a shield from a solved stat block. A stat block with no shield in it makes a
## shield that never blocks, which is the honest answer for the other three suits.
func _init(stats: EnemyStats = null) -> void:
	if stats == null or not stats.has_shield:
		return
	_arc_degrees = stats.block_arc_degrees
	_chance = stats.block_chance
	_armour = stats.armour_multiplier


## Put the shield up or down. Down whenever the bearer cannot hold it: staggered,
## defeated, or committed to its own swing.
func set_raised(raised: bool) -> void:
	_raised = raised


## True while the shield is up.
func is_raised() -> bool:
	return _raised


## Tell the shield which way its bearer faces and where the threat stands. Called
## once per physics frame by the `Blank`; see the class doc for why this rather than
## an argument on `is_blocking()`.
func aim(facing: Vector2, threat_offset: Vector2) -> void:
	_facing = facing if not facing.is_zero_approx() else Vector2.RIGHT
	_threat_offset = threat_offset


## Seed the shield's own random source, so a fight with a sub-1.0 block chance runs
## the same way twice. Ignored at `CERTAIN`, where nothing is drawn.
func seed_rng(seed_value: int) -> void:
	_ensure_rng()
	_rng.seed = seed_value


## True when this shield really covers the bearing it is aimed at: the threat lies
## inside the wedge. Pure geometry, so a test can ask it without throwing a hit.
func covers_threat() -> bool:
	if _arc_degrees <= 0.0 or _threat_offset.is_zero_approx():
		return false
	if _arc_degrees >= 360.0:
		return true
	return absf(_facing.angle_to(_threat_offset)) <= deg_to_rad(_arc_degrees) * 0.5


## The `CombatDefense` answer: the hit is absorbed when the shield is up, the threat
## is in front, and the roll (if there is one) says so.
func is_blocking() -> bool:
	if not _raised or not covers_threat():
		return false
	if _chance >= CERTAIN:
		return true
	if _chance <= 0.0:
		return false
	_ensure_rng()
	return _rng.randf() < _chance


## What gets past the shield is multiplied by the armour. Applies whether or not the
## shield is up: the plate is worn, not held.
func damage_multiplier() -> float:
	return _armour


func _ensure_rng() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
