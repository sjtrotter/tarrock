class_name PipRules
extends TarrockDefinition

## Every number Pip runs on: the command wheel, the three commands, and the retreat.
##
## HAND-AUTHORED at `res://data/pip/pip_rules.tres`, from `docs/design/combat.md`
## §Pip. Nothing in `systems/pip/` spells a number - it asks this resource, exactly as
## `systems/combat/` asks `CombatRules` and `systems/enemies/` asks `EnemyRules`.
##
## **What is canon and what is a placeholder.** §Pip fixes the SHAPES and not one
## figure: three commands on a radial wheel, Harry "holding its attention and briefly
## reducing its aggression toward the Fool", and a Pip who "yelps, retreats out of the
## fight, shakes it off, and returns after a short cooldown". Every actual number here
## is therefore a TBD placeholder owned by the combat-tuning pass and listed by name in
## `notes`. They exist so the wheel is playable and testable, not because anybody
## decided them.
##
## What `validate()` enforces is the SHAPE, and only the shape: a cooldown that is
## really short rather than absent, a retreat that really leaves the fight, and a
## Harry that really does lengthen the harried enemy's tells rather than shorten them.

## The narrowest a wheel dead-zone may be. Under this the stick's own rest jitter
## picks a sector, and the "tap with no direction" gesture stops existing - which is
## not a tuning choice, it is the gesture breaking.
const MIN_WHEEL_DEAD_ZONE := 0.1

## The widest it may be: past this there is no ring of stick left to aim with.
const MAX_WHEEL_DEAD_ZONE := 0.9

# --- Pip himself -------------------------------------------------------------

## Pip's health pool. He never runs out of them permanently: at zero he leaves the
## fight and comes back (`combat.md` §Pip), which is what `PipService` does with it.
## TBD.
@export var max_health: int = 30

## How fast Pip runs while he is carrying out a command, in pixels per second. TBD -
## the doc has no figure; this is the "fetch speed" the round brief names, shared by
## every command because there is one dog and he has one run.
@export var command_speed: float = 260.0

## How close Pip has to get to a thing before he is at it: the pickup, the pin, the
## dig and the delivery all use it. TBD.
@export var command_reach: float = 48.0

# --- The wheel ---------------------------------------------------------------

## How far the move stick has to leave centre before the wheel reads a sector at all.
## Inside it the wheel is undecided, and a release is the "last used command" tap.
## TBD, within the two bounds above.
@export var wheel_dead_zone: float = 0.35

# --- Fetch and Harry ---------------------------------------------------------

## How far away an item or an enemy may be for Pip to accept a Fetch or a Harry, in
## pixels. A dog will cross a clearing for a thrown thing; he will not cross a region.
## TBD.
@export var command_radius: float = 640.0

## How long Pip holds a harried enemy's attention, in seconds. `combat.md` says
## "briefly", and this is what brief means. TBD.
@export var harry_seconds: float = 4.0

## What a harried enemy's telegraphs are multiplied by while Pip has it.
##
## This is `combat.md`'s "briefly reducing its aggression toward the Fool", in the one
## currency the enemy round already has: a harried Blank's brain takes Pip for its
## target AND tells for longer, so the Fool has more room in every window the enemy
## opens. Above 1.0 by definition - `validate()` refuses a table where Harry would
## make an enemy quicker. TBD.
@export var harry_telegraph_multiplier: float = 1.4

# --- Seek --------------------------------------------------------------------

## How far from Pip a hidden thing may be for Seek to reach it, in pixels. TBD.
@export var seek_radius: float = 420.0

## How long Pip works at a hidden thing before it is found - the dig at the disturbed
## earth in `docs/quests/main/MQ00-the-leap.md` §The Old Campsites. TBD.
@export var seek_reveal_seconds: float = 1.4

# --- The retreat -------------------------------------------------------------

## How far out of the fight Pip goes when he is put to zero, in pixels. TBD.
@export var retreat_distance: float = 520.0

## How long he shakes it off out there before he comes back, in seconds. `combat.md`
## §Pip: "returns after a short cooldown". TBD.
@export var retreat_cooldown_seconds: float = 6.0

# --- Provenance --------------------------------------------------------------

## The doc section these numbers came out of.
@export var doc_ref: String = ""

## Which of them are placeholders, and what the doc really fixes.
@export var notes: String = ""


## Every problem with this table; empty means the shape holds.
func validate() -> PackedStringArray:
	var errors := super()
	if max_health <= 0:
		errors.append("%s gives Pip no health to be put to zero" % _describe())
	if command_speed <= 0.0:
		errors.append("%s leaves Pip standing: no command speed" % _describe())
	if command_reach <= 0.0:
		errors.append("%s never lets Pip reach anything" % _describe())
	if wheel_dead_zone < MIN_WHEEL_DEAD_ZONE or wheel_dead_zone > MAX_WHEEL_DEAD_ZONE:
		errors.append("%s sets a dead-zone of %.2f, outside %.2f..%.2f" % [
			_describe(), wheel_dead_zone, MIN_WHEEL_DEAD_ZONE, MAX_WHEEL_DEAD_ZONE
		])
	if command_radius <= 0.0:
		errors.append("%s puts every item and every enemy out of Pip's range" % _describe())
	if harry_seconds <= 0.0:
		errors.append("%s holds no enemy's attention for any time at all" % _describe())
	if harry_telegraph_multiplier <= 1.0:
		errors.append("%s harries at %.2f, which sharpens the enemy instead" % [
			_describe(), harry_telegraph_multiplier
		])
	if seek_radius <= 0.0:
		errors.append("%s puts every hidden thing out of Seek's reach" % _describe())
	if seek_reveal_seconds <= 0.0:
		errors.append("%s finds a hidden thing with no dig at all" % _describe())
	if retreat_distance <= 0.0:
		errors.append("%s retreats nowhere: Pip stays in the fight at zero" % _describe())
	if retreat_cooldown_seconds <= 0.0:
		errors.append("%s returns Pip instantly, so nothing was shaken off" % _describe())
	return errors


## How far from Pip a target for `command` may stand. Seek has its own reach because
## it is the traversal verb rather than a combat one.
func radius_for(command: int) -> float:
	if command == PipCommand.Id.SEEK:
		return seek_radius
	return command_radius


## How long Pip works at the thing once he has reached it, for `command`. Fetch is
## nothing: picking a thing up is not a job, it is a mouthful.
func work_seconds_for(command: int) -> float:
	match command:
		PipCommand.Id.SEEK:
			return seek_reveal_seconds
		PipCommand.Id.HARRY:
			return harry_seconds
	return 0.0
