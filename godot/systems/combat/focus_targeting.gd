class_name FocusTargeting
extends RefCounted

## Who Focus is locked onto, and how it decides.
##
## `docs/design/combat.md` §Focus: holding the focus input drops the Fool into a
## ready-crouch and "locks onto a target when enemies are present", after which
## movement is "8-direction strafing around that target". §Philosophy adds the rule
## that keeps it optional: "Lock-on is available but optional - outside Focus the game
## assists target tracking without forcing a hard-lock", so nothing here ever picks a
## target on its own; a caller acquires, cycles, and releases.
##
## **The candidates are supplied, never searched for.** A system does not reach into
## a scene (`docs/design/technical.md`), so this class is handed the list of things
## that could be locked and knows nothing about where they came from. `FoolCombat`
## fills it from the enemies `CombatService` has been told are engaged.
##
## **Selection is deterministic**, which matters more than it sounds: a lock-on that
## picks a different target on two identical frames is a lock-on players stop
## trusting. Candidates are scored by distance, discounted for being in front of the
## Fool, and ties are broken by the order the caller supplied them in - never by
## anything the engine happens to iterate first.
##
## Freed nodes are skipped everywhere rather than purged eagerly: an enemy can be
## freed by anything at any time, and a targeting system that trusted its own list
## would be the thing that crashed.

## `_index_of()` when the target is not in the candidate list.
const NOT_A_CANDIDATE := -1

## Focus locked onto something.
signal target_acquired(target: Node2D)

## Focus let go, because the player released it or the target went away.
signal target_released()

## How far a candidate may be and still be locked onto.
var _max_range: float = 0.0

## How hard being in front of the Fool counts for. 0 = nearest wins outright.
var _cone_weight: float = 0.0

var _candidates: Array[Node2D] = []
var _target: Node2D = null


## Build the targeter over the two numbers `CombatRules` owns for it.
func _init(max_range: float, cone_weight: float) -> void:
	_max_range = max_range
	_cone_weight = cone_weight


## Replace the candidate list. The array is copied, so the caller may keep reusing
## its own buffer (which is what `FoolCombat` does, to avoid allocating one per
## focus press).
func set_candidates(candidates: Array[Node2D]) -> void:
	_candidates.clear()
	for candidate: Node2D in candidates:
		if candidate != null and is_instance_valid(candidate):
			_candidates.append(candidate)
	if _target != null and not _candidates.has(_target):
		release()


## How many candidates Focus currently has to choose from.
func candidate_count() -> int:
	return _candidates.size()


## Lock onto the best candidate from `from`, facing `facing`. Returns it, or `null`
## when nothing is in range - `combat.md`: Focus locks on "when enemies are present",
## and a stance with nothing to lock is still a stance.
func acquire(from: Vector2, facing: Vector2) -> Node2D:
	var best := _best(from, facing, null)
	if best == null:
		release()
		return null
	_set_target(best)
	return _target


## Move the lock to the next candidate round, in score order, wrapping. Returns the
## new target. With one candidate it stays put rather than releasing.
func cycle(from: Vector2, facing: Vector2) -> Node2D:
	if _candidates.size() <= 1:
		return _target
	var next := _best(from, facing, _target)
	if next == null:
		next = _best(from, facing, null)
	if next != null:
		_set_target(next)
	return _target


## What Focus is locked onto, or `null`. A target that has been freed reads as
## `null` and is dropped on the way out.
func target() -> Node2D:
	if _target != null and not is_instance_valid(_target):
		_target = null
		target_released.emit()
	return _target


## True while something is locked.
func has_target() -> bool:
	return target() != null


## The direction from `from` to the target, or `Vector2.ZERO` when there is none.
## This is what the moveset is told, so the Fool "keeps facing the target while
## circling" (`combat.md` §Focus).
func direction_to_target(from: Vector2) -> Vector2:
	var locked := target()
	if locked == null:
		return Vector2.ZERO
	var offset := locked.global_position - from
	if offset.is_zero_approx():
		return Vector2.ZERO
	return offset.normalized()


## Let go. Idempotent.
func release() -> void:
	if _target == null:
		return
	_target = null
	target_released.emit()


## Forget everything, candidates included. Used when a fight ends or a scene loads.
func clear() -> void:
	release()
	_candidates.clear()


# --- Internals ---------------------------------------------------------------


## The best candidate in range, ignoring `excluded` (which is how `cycle` steps past
## the current target). Ties go to the earlier entry in the supplied order.
func _best(from: Vector2, facing: Vector2, excluded: Node2D) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	var direction := facing.normalized() if not facing.is_zero_approx() else Vector2.RIGHT
	for candidate: Node2D in _candidates:
		if candidate == null or not is_instance_valid(candidate) or candidate == excluded:
			continue
		var offset := candidate.global_position - from
		var distance := offset.length()
		if distance > _max_range:
			continue
		var score := _score(offset, distance, direction)
		if score < best_score:
			best_score = score
			best = candidate
	return best


## Lower is better: distance, discounted for how far in front of the Fool the
## candidate is. A candidate straight ahead scores as if it were
## `1 / (1 + cone_weight)` of its real distance; one straight behind pays its
## distance in full.
func _score(offset: Vector2, distance: float, facing: Vector2) -> float:
	if distance <= 0.0:
		return 0.0
	var alignment := maxf(0.0, offset.normalized().dot(facing))
	return distance / (1.0 + _cone_weight * alignment)


## Lock on, announcing it only when it really changed.
func _set_target(candidate: Node2D) -> void:
	if _target == candidate:
		return
	_target = candidate
	target_acquired.emit(candidate)
