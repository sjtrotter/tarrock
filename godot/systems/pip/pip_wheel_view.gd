class_name PipWheelView
extends RefCounted

## One frame of the command wheel, as the UI needs to see it - and nothing the UI can
## write back.
##
## The wheel itself is drawn by the UI round (round 13 of
## `docs/gauntlet-systems/PROMPT.md`). What this round owes that round is a shape it
## can bind to without reaching into `PipWheel` or `PipService` for their internals: is
## the wheel up, which sector is lit, which commands could actually be given, what the
## last one was, and how long the player has been holding it.
##
## It is **refilled, never reallocated** - `PipCompanion` owns one and calls
## `refresh()` every physics frame, so an open wheel allocates nothing
## (`docs/design/technical.md` §Performance guardrails). A UI that wants to keep a
## frame past the one it was handed copies the fields it wants.
##
## Availability is `PipService.is_available()`'s answer, which today means: everything
## is available except while Pip is out of the fight shaking off a knock, and while
## the Fool is down and Pip has a face to lick.

## True while the wheel is open.
var _open: bool = false

## The lit sector, or `PipCommand.NONE`.
var _highlighted: int = PipCommand.NONE

## The last command confirmed, or `PipCommand.NONE`.
var _last_used: int = PipCommand.NONE

## How long the wheel has been open, in seconds.
var _held_seconds: float = 0.0

## One entry per `PipCommand.Id`: 1 when the command could be given now, 0 when not.
## A `PackedByteArray` rather than an `Array[bool]` so refreshing it writes into
## storage that already exists.
var _available: PackedByteArray = PackedByteArray()


func _init() -> void:
	_available.resize(PipCommand.ALL.size())


## Read this frame off the wheel and the service. Allocates nothing.
func refresh(wheel: PipWheel, service: PipService) -> void:
	if wheel != null:
		_open = wheel.is_open()
		_highlighted = wheel.highlighted()
		_last_used = wheel.last_used()
		_held_seconds = wheel.held_seconds()
	for command: int in PipCommand.ALL:
		var usable := service != null and service.is_available(command)
		_available[command] = 1 if usable else 0


## True while the wheel is open.
func is_open() -> bool:
	return _open


## The sector lit right now, or `PipCommand.NONE`.
func highlighted() -> int:
	return _highlighted


## The command a directionless release would repeat, or `PipCommand.NONE`.
func last_used() -> int:
	return _last_used


## How long the wheel has been open, in seconds.
func held_seconds() -> float:
	return _held_seconds


## True when `command` could be given right now - what a greyed-out sector reads.
func is_available(command: int) -> bool:
	if not PipCommand.is_valid(command) or command >= _available.size():
		return false
	return _available[command] == 1
