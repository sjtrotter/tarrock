class_name RegionSwapper
extends RefCounted

## The seam between the region SYSTEM and the region SCENES.
##
## `docs/design/technical.md` §Regions and the persistent layer: "`RegionService` is
## the only system allowed to load or free a region scene." But a service is a plain
## `RefCounted` with no tree and no business reaching into scenes
## (§Architecture principles (Godot), 5), so it cannot do the loading itself. This is
## how both stay true: the persistent layer - a scene - builds one of these over its
## own methods and hands it to the service, and the service calls it. Nothing else in
## the game holds one, so the service really is the only caller.
##
## Three jobs, and the layer owns HOW each happens (including WHEN: a swap asked for
## from inside a physics callback cannot free an `Area2D` on the spot, so the layer
## defers the node work by a frame - see `PersistentLayer`). The service's contract is
## that it asked; the layer's contract is that it will have happened by the next idle
## frame.
##
## A test builds one over lambdas and asserts what the service asked for, which is
## the whole reason the seam is an object rather than a hard call.

## Free the current region scene, instance `scene_path` under the layer, and put the
## Fool and Pip on the `arrival` marker. `Callable(scene_path: String,
## arrival: StringName) -> bool`.
var _swap: Callable = Callable()

## Move the Fool and Pip to the `arrival` marker of the region already loaded - the
## defeat loop's walk back, which must not reload a scene the Fool is standing in.
## `Callable(arrival: StringName) -> bool`.
var _re_anchor: Callable = Callable()

## Put the ambient enemies back on their feet after a rest, and answer how many
## encounters were reset. `Callable() -> int`.
var _respawn_ambient: Callable = Callable()


## Build a swapper over the layer's three methods.
##
## Any of them may be left empty and the service simply gets `false`/`0` back - but
## note what a `false` from `swap()` now MEANS: `RegionService` believes it and refuses
## the journey, because a layer that will not take the scene is a Fool who never
## arrived. A fixture that wants the bookkeeping to happen has to answer the swap.
func _init(
	swap_scene: Callable = Callable(),
	re_anchor: Callable = Callable(),
	respawn_ambient: Callable = Callable()
) -> void:
	_swap = swap_scene
	_re_anchor = re_anchor
	_respawn_ambient = respawn_ambient


## Ask for a region swap. True when the layer accepted the request - and a false is a
## refusal the service acts on, not a diagnostic (see `_init`).
func swap(scene_path: String, arrival: StringName) -> bool:
	if not _swap.is_valid():
		return false
	return bool(_swap.call(scene_path, arrival))


## Ask for the Fool and Pip to be put on a marker in the region already loaded.
func re_anchor(arrival: StringName) -> bool:
	if not _re_anchor.is_valid():
		return false
	return bool(_re_anchor.call(arrival))


## Ask for the ambient enemies to come back. Answers how many encounters were reset.
func respawn_ambient() -> int:
	if not _respawn_ambient.is_valid():
		return 0
	return int(_respawn_ambient.call())
