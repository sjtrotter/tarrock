class_name Waystation
extends Interactable

## A wayside shrine standing in a region: the game's rest point, and the marker the
## Fool arrives on when they come back to it.
##
## `docs/design/progression.md` §Waystations is the whole contract, and none of it is
## implemented here - the rules are `RegionService`'s, because they touch the White
## Rose, the enemies, the save and the Pocket Spread, and a node in a scene owns none
## of those. This node is the *place*: it knows its id, it raises a quest event like
## any other `Interactable`, and it asks the service to rest when the Fool acts on it.
##
## Three things it is at once, which is why it is one node and not three:
##
##   * an **`Interactable`** - the Fool's interact verb finds it exactly as it finds
##     the Bindle, so resting needs no new input and no new reach;
##   * an **arrival marker** - it lives under a region scene's `Markers` and is named
##     for its Waystation id, so travelling to `WAYSTATION_CLIFF` puts the Fool on
##     this node (see `RegionScene`);
##   * a **circle to stand in** - `near_radius` is the zone where the Pocket Spread
##     may be respecced ("save, name, and switch between full loadouts"), which is
##     `PocketSpreadService`'s rule and only needs telling when the Fool is inside it.
##
## The near-zone is built in code rather than authored, the same way `Encounter`
## builds its trigger: the scene stays authored content, not collision plumbing.

## The Fool stepped in or out of the circle. The scene may hang a prompt on it.
signal proximity_changed(inside: bool)

## The Fool rested here. Emitted after the service has done it, never before.
signal rest_taken()

## How far up the tree this node looks for the `RegionScene` that owns it. A shrine
## lives under `Markers`, one step down; the rest is room for a region that groups its
## markers, and a hard stop so the walk can never reach the tree root.
const OWNER_LOOKUP_DEPTH := 8

## Which Waystation this is - a `RegionIds.WAYSTATION_*` id. It must be one the
## region's own definition lists, which the region test suite checks.
@export var waystation_id: StringName = &""

## How close the Fool has to be for this to count as standing at the shrine.
@export var near_radius: float = 260.0

var _near: Area2D = null
var _inside: bool = false

## The region scene this shrine stands in, found once (see `_owning_region()`).
var _region: RegionScene = null


func _ready() -> void:
	super()
	_build_near_zone()


## True while the Fool is standing in the circle.
func is_near() -> bool:
	return _inside


## Rest here, through the service that owns what resting means. True when the rest
## happened.
##
## Called by `interact()` below, and directly by a test or by a UI that offers the
## verb some other way. The refusals - not the region the Fool is in, no such
## Waystation - are the service's, and are developer diagnostics: a shrine the Fool
## is standing next to is always one they may sleep at.
func rest() -> bool:
	var regions := _region_service()
	if regions == null:
		return false
	if not regions.rest_at(waystation_id):
		return false
	rest_taken.emit()
	return true


## The Fool acted on the shrine: raise whatever quest event this node carries, and
## rest.
##
## Both, in that order, on purpose. The event is `Interactable`'s own contract (the
## region scene forwards it to the quests; MQ00's first rest is a beat), and the rest
## is what a Waystation IS. A one-shot event fires once; the rest never stops working.
func interact() -> bool:
	var raised := super()
	var slept := rest()
	return raised or slept


## True when the interact verb should be offered here. A Waystation is always
## interactable, even once its quest event has been spent: `Interactable.is_spent()`
## retires an event, not a place to sleep.
func is_interactable() -> bool:
	return not on_approach


# --- Internals -------------------------------------------------------------------


## The circle the Fool stands in to respec, built in code (see the class doc).
func _build_near_zone() -> void:
	if _near != null:
		return
	var shape := CircleShape2D.new()
	shape.radius = maxf(near_radius, 1.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	_near = Area2D.new()
	_near.name = "Near"
	_near.monitoring = true
	# It looks for the Fool and nothing looks for it: a shrine's circle is not a
	# hitbox and must never be found by one.
	_near.monitorable = false
	_near.add_child(collision)
	add_child(_near)
	_near.body_entered.connect(_on_body_entered)
	_near.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if _inside or not body.is_in_group(FOOL_GROUP):
		return
	_inside = true
	var regions := _region_service()
	if regions != null:
		regions.enter_waystation(waystation_id)
	proximity_changed.emit(true)


func _on_body_exited(body: Node2D) -> void:
	if not _inside or not body.is_in_group(FOOL_GROUP):
		return
	_inside = false
	var regions := _region_service()
	if regions != null and regions.at_waystation_id() == waystation_id:
		regions.leave_waystation()
	proximity_changed.emit(false)


## The service that owns what a rest means, asked of the region scene this shrine
## stands in.
##
## **Through the scene, not out of the tree root.** A Waystation is a node a region
## authored, and `RegionScene` is the seam that hands a region its services
## (`attach_layer()`, `region_service()`): asking upwards means a shrine takes the same
## service as everything else in its region, and a region instanced by a test with
## another composition root takes that one instead of quietly finding the autoload.
## `/root/Services` remains only as the bounded fallback below.
func _region_service() -> RegionService:
	var region := _owning_region()
	if region != null:
		var injected := region.region_service()
		if injected != null:
			return injected
	# The fallback: a Waystation instanced on its own by a test or a tool has no region
	# scene above it, and a shrine with no service simply cannot be slept at.
	var root := get_node_or_null(RegionScene.SERVICES_PATH)
	if root == null:
		return null
	return root.get(&"regions") as RegionService


## The region scene this shrine was authored in, or `null`.
##
## Walked up rather than exported, so a region's art can be rearranged without
## rewiring - the same reason `RegionScene` finds its markers by name. Bounded by
## `OWNER_LOOKUP_DEPTH` so a node hung somewhere unexpected costs a short walk and not
## a climb to the root, and cached because a node does not change scenes.
func _owning_region() -> RegionScene:
	if _region != null and is_instance_valid(_region):
		return _region
	var node: Node = get_parent()
	var depth := 0
	while node != null and depth < OWNER_LOOKUP_DEPTH:
		var region := node as RegionScene
		if region != null:
			_region = region
			return _region
		node = node.get_parent()
		depth += 1
	return null
