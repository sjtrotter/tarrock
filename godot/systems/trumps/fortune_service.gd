class_name FortuneService
extends RefCounted

## The Fortune meter: the single resource a Present-slot Trump spends.
##
## `docs/design/progression.md` §Fortune is canon for the meter (roughly 100 units),
## for what earns it (combat hits, Fool's Chance disproportionately, discovery,
## daring), and for **Fortune's Favor** - "immediately after a Fool's Chance, the
## meter can briefly hold *more* than its normal maximum - an overfill window that
## empties back down to the cap if unspent". `docs/design/combat.md` §Defense adds
## the other half of a Fool's Chance: "the next Present-slot Trump cast is free (no
## Fortune cost)", and §Difficulty modes says Story earns faster and Trial earns
## less.
##
## Every number comes from `SpreadRules`; none is spelled here. Most of them are
## TBD placeholders (see that resource) - what this service pins is the *shape*: a
## capped meter, an overfill window that opens on a Fool's Chance and drains after
## it, and a free cast that is spent instead of Fortune.
##
## The service is deliberately ignorant of what a cast does. `spend()` is called by
## `PocketSpreadService.cast_present()`; the effect itself is round 7's.
##
## `tick(delta)` is called once a frame by whoever owns the frame and allocates
## nothing (technical.md §Performance guardrails).

## The meter moved. Both values are Fortune, not a fraction.
signal fortune_changed(old_value: int, new_value: int)

## A Fool's Chance opened the overfill window.
signal favor_opened()

## The overfill window closed; anything above the cap now drains.
signal favor_closed()

## The next Present cast is free.
signal free_cast_armed()

## A cast took the free flag instead of Fortune.
signal free_cast_consumed()

## What earned Fortune. `progression.md` §Fortune's three sources, with combat's
## two halves kept apart because they pay differently (combat.md §Fortune in
## combat: a Fool's Chance is "a disproportionate reward per trigger").
enum EarnSource {
	## A landed hit - the baseline trickle.
	HIT,
	## A perfectly timed dodge.
	FOOLS_CHANCE,
	## A new location or a secret found.
	DISCOVERY,
	## A near-miss dodge, a survived high fall.
	DARING,
}

## Snapshot keys. The save model writes these verbatim.
const SNAPSHOT_VALUE := "value"
const SNAPSHOT_FREE_CAST := "free_cast"

## The meter's floor. Fortune is never negative.
const FLOOR := 0

## `earn()`'s "use the rules table" argument.
const NO_OVERRIDE := -1

var _rules: SpreadRules = null
var _difficulty: DifficultyMode.Id = DifficultyMode.DEFAULT

var _value: int = FLOOR
var _free_cast: bool = false

## Seconds left in the Favor window, or 0 when it is closed.
var _favor_seconds_left: float = 0.0

## Fractional Fortune the overfill drain has accumulated but not yet spent. Kept so
## the drain is smooth at any frame rate without the meter holding a float.
var _decay_carry: float = 0.0

## False from the first mutation - or the first successful load - onward, exactly as
## `WorldStateService.is_pristine()` is, and for the same reason.
var _pristine: bool = true


## Build the meter over its tuning data and the difficulty being played.
func _init(rules: SpreadRules, difficulty: DifficultyMode.Id = DifficultyMode.DEFAULT) -> void:
	_rules = rules
	_difficulty = difficulty
	if rules == null:
		push_error("FortuneService was built without its rules")


# --- Reading -----------------------------------------------------------------


## Fortune held right now. May exceed `max_value()` during and just after Fortune's
## Favor, which is the whole point of the overfill.
func value() -> int:
	return _value


## The meter's normal maximum (`SpreadRules.fortune_max`).
func max_value() -> int:
	if _rules == null:
		return FLOOR
	return _rules.fortune_max


## The most the meter may hold at this instant: the maximum, plus the overfill while
## the Favor window is open.
func ceiling() -> int:
	if _rules == null:
		return FLOOR
	if is_favor_open():
		return _rules.fortune_max + _rules.favor_overfill
	return _rules.fortune_max


## True while the Favor window is open.
func is_favor_open() -> bool:
	return _favor_seconds_left > 0.0


## Seconds left in the Favor window; 0 when it is closed.
func favor_seconds_left() -> float:
	return _favor_seconds_left


## True when the next Present cast costs nothing.
func has_free_cast() -> bool:
	return _free_cast


## The difficulty this meter earns at.
func difficulty() -> DifficultyMode.Id:
	return _difficulty


## True until this service is first mutated or first loaded into.
func is_pristine() -> bool:
	return _pristine


# --- Earning and spending ----------------------------------------------------


## Earn Fortune from a source. Returns how much was actually added.
##
## The amount is the rules table's entry for the source (or `amount_override`, when
## a caller has a reason to pay differently - a boss's discovery bonus, a tuning
## experiment), scaled by the difficulty's income multiplier and rounded. The
## multiplier applies to an override too: "Fortune earns faster on Story" is a
## property of income, not of one source.
##
## Capped at `ceiling()`, which is the maximum except during Fortune's Favor. A
## meter already above the ceiling (the window just closed and the overfill is still
## draining) is never pushed *down* by earning.
func earn(source: EarnSource, amount_override: int = NO_OVERRIDE) -> int:
	if _rules == null:
		return 0
	var base := amount_override if amount_override >= 0 else _base_amount(source)
	var scaled := int(roundf(float(base) * _rules.earn_multiplier(_difficulty)))
	if scaled <= 0:
		return 0
	var target := mini(_value + scaled, ceiling())
	if target <= _value:
		return 0
	var gained := target - _value
	_set_value(target)
	return gained


## A Fool's Chance happened: pay for it, open the Favor window, arm the free cast.
##
## Order matters and is canon. The window opens FIRST so the reward itself may
## overfill the meter - `progression.md` says the meter can hold more than its
## maximum "immediately after a Fool's Chance", which is this grant. Then the free
## cast is armed (`combat.md` §Defense).
func on_fools_chance() -> int:
	if _rules == null:
		return 0
	var was_open := is_favor_open()
	_pristine = false
	_favor_seconds_left = _rules.favor_window_seconds
	_decay_carry = 0.0
	if not was_open:
		favor_opened.emit()
	var gained := earn(EarnSource.FOOLS_CHANCE)
	if not _free_cast:
		_free_cast = true
		free_cast_armed.emit()
	return gained


## True when the meter holds at least this much. Says nothing about the free cast -
## `PocketSpreadService` asks `has_free_cast()` separately, so a UI can show "free"
## rather than "affordable".
func can_afford(cost: int) -> bool:
	return _value >= cost


## Pay for a cast. Returns false when it cannot be paid for, having changed nothing.
##
## An armed free cast is spent INSTEAD of Fortune, whatever the cost - that is what
## `combat.md` means by "the next Present-slot Trump cast is free". A free cast is
## consumed even by a cast the meter could have afforded: the player earned it, and
## silently charging them for it would be the wrong kind of generous.
func spend(cost: int) -> bool:
	if cost < 0:
		return false
	if _free_cast:
		_pristine = false
		_free_cast = false
		free_cast_consumed.emit()
		return true
	if not can_afford(cost):
		return false
	_set_value(_value - cost)
	return true


## Change the difficulty this meter earns at (`combat.md` §Difficulty modes).
func set_difficulty(mode: DifficultyMode.Id) -> void:
	_difficulty = mode


## Advance the Favor window and the overfill drain by one frame.
##
## While the window is open, nothing drains. When it closes, everything above the
## maximum drains at `SpreadRules.favor_decay_per_second` until the meter is back at
## the cap - the doc's "empties back down to the cap if unspent". A frame long
## enough to close the window drains with the remainder of its own delta, so the
## drain does not depend on the frame rate.
func tick(delta: float) -> void:
	if delta <= 0.0 or _rules == null:
		return
	var remaining := delta
	if _favor_seconds_left > 0.0:
		if _favor_seconds_left > remaining:
			_favor_seconds_left -= remaining
			return
		remaining -= _favor_seconds_left
		_favor_seconds_left = 0.0
		favor_closed.emit()
	var cap := max_value()
	if _value <= cap:
		_decay_carry = 0.0
		return
	_decay_carry += remaining * _rules.favor_decay_per_second
	var whole := int(floorf(_decay_carry))
	if whole <= 0:
		return
	_decay_carry -= float(whole)
	_set_value(maxi(cap, _value - whole))


# --- Save --------------------------------------------------------------------


## Everything the save file needs: the meter and the free cast, as plain values.
##
## The Favor window is deliberately NOT saved. It is a 6-second combat window; a
## player who saves mid-Favor and loads tomorrow is not owed the tail of it, and
## restoring one would mean restoring a meter above its own maximum with nothing
## running to bring it down.
func to_snapshot() -> Dictionary:
	return {
		SNAPSHOT_VALUE: _value,
		SNAPSHOT_FREE_CAST: _free_cast,
	}


## Load a snapshot, returning every problem it found. Emits nothing.
##
## Same contract as `WorldStateService.restore_snapshot()`: a fresh service only,
## all-or-nothing, problems reported rather than pushed. JSON has one number type,
## so an integral float is read as the int it is.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _pristine:
		errors.append("restore_snapshot needs a fresh Fortune meter; this one is in play")
		return errors
	var stored: Variant = data.get(SNAPSHOT_VALUE, 0)
	if not (stored is int or stored is float):
		errors.append("snapshot Fortune is not a number")
		return errors
	var restored := int(stored)
	if restored < FLOOR:
		errors.append("snapshot Fortune is negative: %d" % restored)
	if restored > max_value() + (0 if _rules == null else _rules.favor_overfill):
		errors.append("snapshot Fortune of %d is above anything this build allows" % restored)
	var free: Variant = data.get(SNAPSHOT_FREE_CAST, false)
	if not (free is bool):
		errors.append("snapshot free cast is not a bool")
	if not errors.is_empty():
		return errors
	_value = restored
	_free_cast = bool(free)
	_favor_seconds_left = 0.0
	_decay_carry = 0.0
	_pristine = false
	return errors


# --- Internals ---------------------------------------------------------------


## The rules table's amount for one source, before the difficulty multiplier.
func _base_amount(source: EarnSource) -> int:
	if _rules == null:
		return 0
	match source:
		EarnSource.HIT:
			return _rules.fortune_per_hit
		EarnSource.FOOLS_CHANCE:
			return _rules.fortune_per_fools_chance
		EarnSource.DISCOVERY:
			return _rules.fortune_per_discovery
		EarnSource.DARING:
			return _rules.fortune_per_daring
	return 0


## The one place the meter changes: clamped at the floor, announced when it moved.
func _set_value(new_value: int) -> void:
	var clamped := maxi(FLOOR, new_value)
	if clamped == _value:
		return
	var old_value := _value
	_pristine = false
	_value = clamped
	fortune_changed.emit(old_value, clamped)
