class_name PipWheel
extends RefCounted

## The radial command wheel, as input rather than as picture.
##
## `docs/design/combat.md` §Pip gives Pip "a **radial command wheel**" with three
## entries and says nothing about how it is driven, so this is the gesture, decided in
## the round brief and written down once here:
##
##   * **hold `pip_wheel`** and the wheel opens;
##   * **the move vector picks a sector** while it is held - so the wheel is aimed with
##     the stick the player is already holding, and no new action is bound;
##   * **release confirms** whatever sector is lit;
##   * **a tap with no direction repeats the last command used**, because a wheel that
##     needed a full aim for the command you just gave would be an insult to a dog.
##
## The three sectors, in screen space (`+y` is down, so "up" is `-y`):
##
## ```
##      FETCH  \   /  HARRY        FETCH  = up-left   = (-1, -1)
##              \ /                HARRY  = up-right  = ( 1, -1)
##        ------ o ------          SEEK   = down      = ( 0,  1)
##              / \
##             /   \
##             SEEK
## ```
##
## A direction picks the sector whose centre it points most nearly at (the largest dot
## product), so the boundaries are the bisectors between the three centres: straight up
## divides Fetch from Harry, and the two down-diagonals divide each of them from Seek.
## The sectors are therefore NOT equal thirds - Fetch and Harry are 90 degrees apart
## and Seek has the whole bottom - and that is deliberate: the two combat commands sit
## either side of "forward", where a thumb already is mid-fight, and the traversal
## command sits where nothing else is.
##
## It is pure: no `Input`, no nodes, no clock. `PipCompanion` reads the buttons and
## hands them here; a test drives the same method with made-up vectors. Nothing is
## allocated per update.

## The direction each sector points, indexed by `PipCommand.Id`. Unit vectors, so the
## dot product below really is a cosine and the widest one really is the nearest.
const SECTOR_DIRECTIONS: Array[Vector2] = [
	Vector2(-0.7071068, -0.7071068),
	Vector2(0.7071068, -0.7071068),
	Vector2(0.0, 1.0),
]

## How far the stick must leave centre before a sector lights up.
var _dead_zone: float = 0.35

## True while the wheel button is down.
var _open: bool = false

## The sector currently lit, or `PipCommand.NONE`.
var _highlighted: int = PipCommand.NONE

## The last command this wheel actually confirmed, or `PipCommand.NONE` when the
## player has not used it yet.
var _last_used: int = PipCommand.NONE

## How long the wheel has been held open, in seconds. What a UI fades in against.
var _held_seconds: float = 0.0


## Build a wheel with the dead-zone from `PipRules`.
func _init(dead_zone: float) -> void:
	_dead_zone = clampf(dead_zone, PipRules.MIN_WHEEL_DEAD_ZONE, PipRules.MAX_WHEEL_DEAD_ZONE)


## Run one frame of the gesture, and answer the command it confirmed.
##
## `held` is the `pip_wheel` action's state, `move` the raw move vector (it is NOT
## normalised here: its length is what the dead-zone is measured against). Returns
## `PipCommand.NONE` on every frame except the one the button is released on, and on
## that frame the command the release confirmed - which is the lit sector, or the last
## command used when the stick was inside the dead-zone.
##
## A release that confirms nothing (nothing lit, nothing used before) answers
## `PipCommand.NONE` too: an empty wheel does not guess.
func update(held: bool, move: Vector2, delta: float) -> int:
	if held:
		if not _open:
			_open = true
			_held_seconds = 0.0
		_held_seconds += maxf(0.0, delta)
		_highlighted = sector_for(move)
		return PipCommand.NONE
	if not _open:
		return PipCommand.NONE
	var confirmed := _highlighted if _highlighted != PipCommand.NONE else _last_used
	_open = false
	_held_seconds = 0.0
	_highlighted = PipCommand.NONE
	if confirmed == PipCommand.NONE:
		return PipCommand.NONE
	_last_used = confirmed
	return confirmed


## Which sector `move` points at, or `PipCommand.NONE` inside the dead-zone.
##
## Public because it is the whole geometry of the wheel, and a test that could only
## reach it through a press and a release would be testing the gesture twice.
func sector_for(move: Vector2) -> int:
	if move.length() < _dead_zone:
		return PipCommand.NONE
	var direction := move.normalized()
	var best := PipCommand.NONE
	var best_dot := -INF
	for command: PipCommand.Id in PipCommand.ALL:
		var dot := SECTOR_DIRECTIONS[command].dot(direction)
		if dot <= best_dot:
			continue
		best_dot = dot
		best = command
	return best


## True while the wheel is open.
func is_open() -> bool:
	return _open


## The sector lit right now, or `PipCommand.NONE`.
func highlighted() -> int:
	return _highlighted


## The last command confirmed, or `PipCommand.NONE`. What a directionless tap repeats.
func last_used() -> int:
	return _last_used


## How long the wheel has been open, in seconds. 0 while it is shut.
func held_seconds() -> float:
	return _held_seconds


## The dead-zone this wheel was built with.
func dead_zone() -> float:
	return _dead_zone


## Shut the wheel without confirming anything - what a pause, a cut scene or a
## conversation does to a gesture half-made.
func cancel() -> void:
	_open = false
	_highlighted = PipCommand.NONE
	_held_seconds = 0.0
