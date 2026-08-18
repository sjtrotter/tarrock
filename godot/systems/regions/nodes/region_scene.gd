class_name RegionScene
extends Node2D

## The root of one region's scene: what every region has, whatever else it has.
##
## `docs/design/technical.md` §Regions and the persistent layer: one scene per region,
## instanced under the persistent layer, which is where the Fool, Pip, the camera and
## the services live. So a region scene owns **the place** - its ground, its props,
## its triggers, its encounters, its Waystations, its arrival markers - and owns
## neither of the two people walking around in it.
##
## This class is the seam. The layer hands a region the actors and itself
## (`attach_layer()`) before the scene enters the tree, so `_ready()` on a region can
## already ask `fool()`, `pip()` and `region_service()`. Scenes call systems and
## systems never reach back (§Architecture principles (Godot), 5): a region's script
## may call `RegionService`, and `RegionService` only ever asks the LAYER to swap a
## scene, never a scene to do anything.
##
## **Markers.** `Markers/DEFAULT` is where a region puts the Fool when nothing else is
## named; any other child of `Markers` is an arrival by its own node name, and a
## `Waystation` node is an arrival named by its Waystation id. That is the whole
## protocol - a region scene declares where the Fool can appear by putting nodes there
## and naming them, with no table to keep in step.

## Where the arrival markers live, so a region's art can be rearranged without
## touching the travel wiring.
const MARKER_ROOT := "Markers"

## The composition root, resolved defensively: `--check-only` (the lint stage of
## `res://tests/run_all.sh`) never runs the autoload bootstrap, so the bare `Services`
## identifier is an unconditional parse error there. Every scene script in the project
## looks the autoload up by path for this reason.
const SERVICES_PATH := "/root/Services"

## Which region this scene is, as a `RegionIds` token. Authored on the root node and
## checked against the catalog by the region test suite: a scene claiming a region no
## definition describes is a scene nothing can travel to.
@export var region_id: StringName = &""

## The camera bounds for this region, in world pixels. An empty rect means "no
## limits" - the layer clears the camera's own when it arrives somewhere that does
## not care. Authored here rather than on the camera, because the camera lives in the
## persistent layer and outlives every region it looks at.
@export var camera_limits: Rect2 = Rect2()

var _fool: Node2D = null
var _pip: Node2D = null
var _layer: Node = null


## The layer hands over the actors and itself, before this scene enters the tree.
##
## Deliberately typed as plain `Node2D`/`Node` rather than as the layer's own class:
## a region scene knowing the layer's type, while the layer instances region scenes,
## would be a cycle between two `class_name`s for no gain.
func attach_layer(layer: Node, fool: Node2D, pip: Node2D) -> void:
	_layer = layer
	_fool = fool
	_pip = pip


## The Fool, who lives in the persistent layer above this scene. `null` in a scene
## instanced on its own by a test.
func fool() -> Node2D:
	return _fool


## Pip, same.
func pip() -> Node2D:
	return _pip


## The persistent layer this scene hangs under, or `null`.
func layer() -> Node:
	return _layer


## The composition root, or `null` when nothing built it (a scene loaded by a tool).
func services() -> Node:
	return get_node_or_null(SERVICES_PATH)


## The service that owns where the Fool is, or `null`.
func region_service() -> RegionService:
	var root := services()
	if root == null:
		return null
	return root.get(&"regions") as RegionService


## This region's own definition, or `null` when the catalog has no such region.
func definition() -> RegionDefinition:
	var regions := region_service()
	if regions == null:
		return null
	return regions.definition(region_id)


## The node the Fool arrives on for this arrival id, or `null`.
##
## Looked up by node name under `Markers`, which is what makes a Waystation double as
## an arrival: the node is named for its Waystation id.
func marker(arrival: StringName) -> Node2D:
	var markers := get_node_or_null(MARKER_ROOT)
	if markers == null:
		return null
	return markers.get_node_or_null(NodePath(String(arrival))) as Node2D


## Where the Fool should stand for this arrival: the named marker, the region's
## `DEFAULT`, or this scene's own origin as the last resort. A region that named no
## markers at all still has to put the Fool somewhere.
func arrival_position(arrival: StringName) -> Vector2:
	var found := marker(arrival)
	if found == null:
		found = marker(RegionService.DEFAULT_ARRIVAL)
	if found == null:
		return global_position
	return found.global_position


## Every Waystation authored in this scene, in tree order.
func waystations() -> Array[Waystation]:
	var found: Array[Waystation] = []
	var markers := get_node_or_null(MARKER_ROOT)
	if markers == null:
		return found
	for child: Node in markers.get_children():
		var waystation := child as Waystation
		if waystation != null:
			found.append(waystation)
	return found


## Every encounter standing in this region, wherever in the scene it was authored.
## The layer asks for these when a rest respawns the ambient dead.
func encounters() -> Array[Encounter]:
	var found: Array[Encounter] = []
	_collect_encounters(self, found)
	return found


func _collect_encounters(node: Node, into: Array[Encounter]) -> void:
	for child: Node in node.get_children():
		var encounter := child as Encounter
		if encounter != null:
			into.append(encounter)
			continue
		_collect_encounters(child, into)
