class_name PersistentLayer
extends Node2D

## Everything that survives a region change: the Fool, Pip, the camera, the UI root -
## and the one node in the game allowed to instance or free a region scene.
##
## `docs/design/technical.md` §Regions and the persistent layer: "the `Services`
## autoload plus the Fool, Pip, the `Camera2D`, and the UI root live above the swapped
## scene and are never freed by a region change... `RegionService` is the only system
## allowed to load or free a region scene. A transition frees the outgoing scene,
## instances the incoming one under the persistent layer, and re-anchors the Fool and
## Pip at the arrival Waystation or edge marker; every service survives untouched."
##
## This is `run/main_scene`. The Cliff used to be, which is why the Cliff's own script
## used to start MQ00 and wire the services: that ownership moved here, where a second
## region cannot inherit it.
##
## **The service asks; this node does it.** `RegionService` holds a `RegionSwapper`
## built over the three methods below and calls it. This node never decides *whether*
## to travel and never reaches into a service to change anything - it registers
## itself, calls `Services.new_game()` or `load_game()`, and does as it is asked.
##
## **The node work is deferred by design.** A swap is very often asked for from inside
## a physics callback - the LeapPoint's `body_entered`, a Waystation's interact - and
## Godot cannot free a scene full of `Area2D`s while the physics server is flushing
## queries; deferring is the engine's own sanctioned answer to that. So `swap()`
## records the request and performs it when the frame's message queue flushes. The
## service's `region_changed` has already been emitted by then, because what the
## service announces is that the Fool has left, not that a `PackedScene` finished
## instancing; `region_ready` is this node's own signal for the other half.

## A region scene has been instanced under `RegionRoot` and the actors are standing on
## its arrival marker. The scene-level event `region_changed` is not: this one waits
## for the nodes.
signal region_ready(region_id: StringName, arrival: StringName)

## The composition root, looked up by path for the reason every scene script in the
## project does (see `RegionScene.SERVICES_PATH`).
const SERVICES_PATH := RegionScene.SERVICES_PATH

## Where the swapped region scene is instanced.
const REGION_ROOT := "RegionRoot"

## The actors and the eye, all three of them older than any region they stand in.
const FOOL := "Fool"
const PIP := "Pip"
const CAMERA := "Fool/Camera2D"

## The components on those two that hold a service each, and must be handed the new
## one when the composition root rebuilds - THE REATTACH LIST (`Services`). A region
## scene's own nodes are not here: a region is instanced AFTER the rebuild and wires
## itself on the way up.
const FOOL_COMBAT := "Fool/FoolCombat"
const PIP_COMPANION := "Pip/PipCompanion"

## Where Pip stands relative to the Fool on arrival: a step behind and to the side,
## inside `PipFollower.FOLLOW_DISTANCE` so he does not immediately break into a trot.
const PIP_OFFSET := Vector2(90.0, -40.0)

## The limit a camera with no region bounds is given: far enough out to be no limit
## at all, which is what `Camera2D` means by unbounded.
const NO_CAMERA_LIMIT := 10000000

## Start a new game as soon as this layer is up.
##
## True is the shipping configuration for as long as there is no title screen (round
## 13): the game opens on the Cliff with MQ00 running, exactly as it did when the
## Cliff was the main scene. A test that wants to drive the boot itself turns it off.
@export var boot_new_game_on_ready: bool = true

var _swapper: RegionSwapper = null
var _region: RegionScene = null

## The swap asked for and not yet performed: `[scene_path, arrival]`, or empty.
var _pending_swap: Array = []


func _ready() -> void:
	_register_swapper()
	var root := services()
	if root != null and not root.is_connected(&"rebuilt", _on_services_rebuilt):
		root.connect(&"rebuilt", _on_services_rebuilt)
	# The services already exist - the autoload was ready before this scene - so the
	# actors are attached once here as well as on every later rebuild.
	_attach_actors()
	if boot_new_game_on_ready:
		# Deferred by one call so that every child of this layer - the Fool, Pip,
		# their components - has certainly had its own `_ready()`, and so that a test
		# instancing this scene by hand before the tree has stepped gets the same
		# order the engine gives the real main scene.
		_boot.call_deferred()


# --- What the layer holds ---------------------------------------------------------


## The Fool. Never freed by a region change.
func fool() -> Node2D:
	return get_node_or_null(FOOL) as Node2D


## Pip. Same.
func pip() -> Node2D:
	return get_node_or_null(PIP) as Node2D


## The camera that follows the Fool. Lives on the Fool, above the region, so a swap
## cannot take the eye away with the scene.
func camera() -> Camera2D:
	return get_node_or_null(CAMERA) as Camera2D


## The region scene currently instanced, or `null` before the first travel.
func region() -> RegionScene:
	return _region


## The node region scenes are instanced under.
func region_root() -> Node2D:
	return get_node_or_null(REGION_ROOT) as Node2D


## The composition root, or `null`.
func services() -> Node:
	return get_node_or_null(SERVICES_PATH)


## The service that owns where the Fool is, or `null`.
func region_service() -> RegionService:
	var root := services()
	if root == null:
		return null
	return root.get(&"regions") as RegionService


## True while a swap has been asked for and the nodes have not caught up yet.
func swap_pending() -> bool:
	return not _pending_swap.is_empty()


# --- Booting ----------------------------------------------------------------------


## Start a new playthrough: fresh services, the Cliff, MQ00. See `Services.new_game()`.
func new_game() -> bool:
	var root := services()
	if root == null:
		return false
	return bool(root.call(&"new_game"))


## Write the playthrough to a slot. See `Services.save_game()`.
func save_game(slot: int) -> bool:
	var root := services()
	if root == null:
		return false
	return bool(root.call(&"save_game", slot))


## Load a playthrough from a slot. See `Services.load_game()`.
func load_game(slot: int) -> bool:
	var root := services()
	if root == null:
		return false
	return bool(root.call(&"load_game", slot))


# --- The swapper's three jobs ------------------------------------------------------


## Free the region on screen, instance another, and put the actors on its marker.
##
## Called only by `RegionService`, through the `RegionSwapper` registered below. The
## work itself happens on the next idle frame (see the class doc); the answer here is
## "the request is accepted", which is all a service can be told about node work.
func swap(scene_path: String, arrival: StringName) -> bool:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_error("the persistent layer cannot load the region scene %s" % scene_path)
		return false
	var already_asked := swap_pending()
	_pending_swap = [scene_path, arrival]
	if not already_asked:
		# Once per pending request: a second swap in the same frame replaces the
		# first rather than queueing a second teardown.
		_perform_pending_swap.call_deferred()
	return true


## Put the actors on a marker of the region already loaded - the defeat loop's walk
## back, and a fast travel that does not leave the region.
func re_anchor(arrival: StringName) -> bool:
	if _region == null:
		return false
	if swap_pending():
		# A swap already asked for will place them on ITS arrival marker; moving them
		# in the scene about to be freed would be work nobody would ever see.
		return false
	_place_actors(arrival)
	return true


## Put the ambient dead back on their feet, and answer how many fights were reset.
##
## `docs/design/progression.md` §Waystations: a rest respawns ambient (non-boss)
## enemies. Which fights answer to that is the `Encounter`'s own business
## (`respawns_on_rest`), so this walks the region and asks all of them.
func respawn_ambient() -> int:
	if _region == null:
		return 0
	var reset := 0
	for encounter: Encounter in _region.encounters():
		if encounter != null and encounter.reset_for_rest():
			reset += 1
	return reset


# --- Internals ---------------------------------------------------------------------


## Hand the region service this layer's three jobs, and take them back at teardown.
##
## Registered once, and NOT re-registered when the services are rebuilt for a new game
## or a load: the composition root keeps the swapper across a rebuild, because the
## layer outlives the services under it exactly as it outlives the regions above them.
func _register_swapper() -> void:
	var root := services()
	if root == null:
		return
	_swapper = RegionSwapper.new(swap, re_anchor, respawn_ambient)
	root.call(&"set_region_swapper", _swapper)


## A new game or a load threw every service away and built new ones. The Fool and Pip
## did not go with them, so their components are handed the new services here.
##
## `Services` emits `rebuilt` for exactly this: that node knows the services, this one
## knows the nodes, and neither reaches into the other's half
## (`docs/design/technical.md` §Architecture principles (Godot), 5). Without it, a Fool
## who loaded a save would still be reporting his swings into the playthrough he just
## left - a component that has found a service never looks for another.
func _on_services_rebuilt() -> void:
	_attach_actors()


## Hand the persistent actors' components their services. Idempotent; each `attach_*`
## ignores a service it already holds.
func _attach_actors() -> void:
	var root := services()
	if root == null:
		return
	var fool_combat := get_node_or_null(FOOL_COMBAT) as FoolCombat
	if fool_combat != null:
		fool_combat.attach_service(root.get(&"combat") as CombatService)
	var companion := get_node_or_null(PIP_COMPANION) as PipCompanion
	if companion != null:
		companion.attach_service(root.get(&"pip") as PipService)


func _boot() -> void:
	if not new_game():
		push_error("the persistent layer could not start a new game")


## Perform the swap asked for, now that the frame's physics callbacks are over.
func _perform_pending_swap() -> void:
	if _pending_swap.is_empty():
		return
	var scene_path: String = _pending_swap[0]
	var arrival: StringName = _pending_swap[1]
	_pending_swap = []

	var root := region_root()
	if root == null:
		push_error("the persistent layer has no %s to instance a region under" % REGION_ROOT)
		return
	_free_region()

	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("%s is not a scene the layer can instance" % scene_path)
		return
	var instanced := packed.instantiate()
	_region = instanced as RegionScene
	if _region != null:
		# Before `add_child`, so a region's own `_ready()` can already ask who the
		# Fool is and which service owns the place.
		_region.attach_layer(self, fool(), pip())
	root.add_child(instanced)
	_apply_camera_limits()
	_place_actors(arrival)
	var region_id := &"" if _region == null else _region.region_id
	region_ready.emit(region_id, arrival)


## Free the region on screen. Its encounters are shut down first: a fight whose Blanks
## are about to be freed must not leave those bodies engaged in `CombatService`, which
## is not going anywhere.
func _free_region() -> void:
	var root := region_root()
	if root == null:
		return
	for child: Node in root.get_children():
		var region := child as RegionScene
		if region != null:
			for encounter: Encounter in region.encounters():
				if encounter != null:
					encounter.shut_down()
		root.remove_child(child)
		child.queue_free()
	_region = null


## Put the Fool and Pip on an arrival marker. Pip lands beside the Fool rather than on
## him: he is a dog who has just walked in, not a decal.
func _place_actors(arrival: StringName) -> void:
	if _region == null:
		return
	var landing := _region.arrival_position(arrival)
	var walker := fool()
	if walker != null:
		walker.global_position = landing
	var dog := pip()
	if dog != null:
		dog.global_position = landing + PIP_OFFSET


## Give the camera the region's own bounds, or take its limits off entirely.
##
## The camera outlives every region it looks at, so limits set for one place would
## otherwise fence the next one in. An empty `camera_limits` means "unbounded", which
## is what a greybox wants.
func _apply_camera_limits() -> void:
	var eye := camera()
	if eye == null:
		return
	var limits := Rect2() if _region == null else _region.camera_limits
	if limits.size == Vector2.ZERO:
		eye.limit_left = -NO_CAMERA_LIMIT
		eye.limit_top = -NO_CAMERA_LIMIT
		eye.limit_right = NO_CAMERA_LIMIT
		eye.limit_bottom = NO_CAMERA_LIMIT
		return
	eye.limit_left = int(limits.position.x)
	eye.limit_top = int(limits.position.y)
	eye.limit_right = int(limits.position.x + limits.size.x)
	eye.limit_bottom = int(limits.position.y + limits.size.y)
