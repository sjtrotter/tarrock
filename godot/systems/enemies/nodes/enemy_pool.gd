class_name EnemyPool
extends Node

## A pool of `Blank` bodies, so a fight never instances or frees one.
##
## `docs/design/technical.md` §Performance guardrails: "**Pooling** for Blanks and for
## repeated VFX - never instance/free on the hot path", and `systems/combat/README.md`
## logged it as owed to this round. The rule is not about the frame the Blank appears
## on; it is about the twenty seconds afterwards, when a card flutters free and a new
## bearer rises past the ridge line and the whole thing happens again.
##
## It is a `Node` rather than a `RefCounted` because it owns scene instances and they
## have to live somewhere in the tree. They stay children of the pool for their whole
## life - **acquiring does not reparent** - because reparenting is a tree operation in
## the middle of a fight, and a `Blank` positions itself in world space anyway. The
## pool is added wherever its owner wants it (today, by the `Encounter`; when the
## persistent layer exists in the Regions round, by that).
##
## Growth is allowed but counted. A pool asked for more than it preallocated will make
## one rather than hand back `null` - a fight that silently lost an enemy would be
## worse than a frame spent instancing - and `grew_by()` says how often that happened,
## so a test can prove a fight took nothing new and a profile can find an encounter
## whose `pool_size` is authored too small.
##
## Nothing is ever freed back: `release()` puts a body to sleep. The bodies go when
## the pool does.

## A body was handed out.
signal acquired(blank: Blank)

## A body went back to sleep.
signal released(blank: Blank)

## The scene every body is made from.
const BLANK_SCENE_PATH := "res://scenes/enemies/blank.tscn"

var _scene: PackedScene = null

## Every body this pool owns, awake or asleep.
var _all: Array[Blank] = []

## The ones asleep, ready to be handed out. Cleared and appended to, never replaced.
var _free: Array[Blank] = []

## How many bodies were made after the preallocation, i.e. how often the pool ran out.
var _grown: int = 0


## Fill the pool. Called once, before anything asks for a body.
##
## `scene` defaults to `blank.tscn`; a test may pass its own. A pool configured twice
## keeps what it already has and tops up to the new size, so re-entering a region does
## not throw away bodies that are perfectly good.
func configure(size: int, scene: PackedScene = null) -> void:
	if scene != null:
		_scene = scene
	if _scene == null:
		_scene = load(BLANK_SCENE_PATH) as PackedScene
	if _scene == null:
		push_error("%s has no Blank scene to pool" % name)
		return
	while _all.size() < size:
		var made := _make()
		if made == null:
			return
		_free.append(made)


## Take a body and configure it for this enemy. `null` only when the pool has no
## scene to make one from.
##
## The body comes back asleep-shaped: hidden, not processing, boxes off. The caller
## places it, points it at a target and wakes it, which is `Blank.rise()`.
func acquire(definition: EnemyDefinition, rules: EnemyRules) -> Blank:
	var blank: Blank = null
	if _free.is_empty():
		blank = _make()
		if blank != null:
			_grown += 1
	else:
		blank = _free.pop_back()
	if blank == null:
		return null
	blank.configure(definition, rules)
	acquired.emit(blank)
	return blank


## Put a body back to sleep. Idempotent: releasing one twice is not an error, it is
## what happens when a defeat and an encounter shutdown both tidy up.
func release(blank: Blank) -> void:
	if blank == null or not is_instance_valid(blank):
		return
	if _free.has(blank):
		return
	blank.sleep()
	_free.append(blank)
	released.emit(blank)


## Put every body back to sleep. What a scene unload or a scripted encounter shutdown
## calls.
func release_all() -> void:
	for blank: Blank in _all:
		release(blank)


## How many bodies this pool owns.
func instance_count() -> int:
	return _all.size()


## How many are asleep and ready.
func available_count() -> int:
	return _free.size()


## How many are out in the world right now.
func live_count() -> int:
	return _all.size() - _free.size()


## How many bodies had to be made after the preallocation. Zero is the number a fight
## is supposed to leave behind.
func grew_by() -> int:
	return _grown


## Every body this pool owns, for a test that wants to look at them all.
func instances() -> Array[Blank]:
	return _all


# --- Internals ------------------------------------------------------------------


## One new sleeping body, parented here for its whole life.
##
## It is NOT put on the free list: `configure()` does that for a preallocation, and
## `acquire()` hands its own straight to the caller. A `_make()` that filed the body
## as free and returned it would have the same body out in the world and waiting to be
## handed out again.
func _make() -> Blank:
	if _scene == null:
		return null
	var blank := _scene.instantiate() as Blank
	if blank == null:
		push_error("%s is not a Blank scene" % BLANK_SCENE_PATH)
		return null
	add_child(blank)
	blank.sleep()
	_all.append(blank)
	return blank
