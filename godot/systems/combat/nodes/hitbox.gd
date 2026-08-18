class_name Hitbox
extends Area2D

## The space one swing covers while its window is open.
##
## The controller decides WHEN (`MovesetController.hit_window_opened`); this decides
## WHO. It is switched on with a `HitSpec` and a direction, delivers the hit to every
## hostile `Hurtbox` the spec covers, and switches off - **once per hurtbox per
## activation**, so a three-frame active window is one hit and not three.
##
## Two-phase detection, and the reason matters:
##
##   * **Broad phase** is the Area2D itself, whose detector is sized once
##     (`configure_reach()`) to the largest reach the owner will ever swing and then
##     never touched again. Resizing a collision shape mid-frame would ask the physics
##     server for overlaps it has not computed yet, and the swing would miss for one
##     frame at unpredictable times - the worst kind of combat bug.
##   * **Narrow phase** is `HitSpec.covers()`, pure geometry against the facing, which
##     is what actually gives the heavy its wide arc and the running attack its box.
##
## Nothing is allocated per frame: the `HitEvent` is built once and refilled, and the
## already-hit set is a Dictionary that is cleared, never replaced
## (`docs/design/technical.md` §Performance guardrails). The one array this class ever
## builds is the overlap sweep at the instant a window opens - once per swing, not
## once per frame - which is what catches a target already standing inside the box.

## A hit was delivered. `result` is what the defender made of it, so the owner can
## earn Fortune for a hit that landed and stay quiet about one that was dodged.
signal hit_landed(hurtbox: Hurtbox, spec: HitSpec, result: HitResult.Id)

## The side swinging. Set from the owning `Combatant` by `configure()`.
@export var faction: Faction.Id = Faction.Id.FOOL

## How far the detector reaches. Sized once from the widest spec its owner can swing;
## the spec's own shape is what actually decides a hit.
@export var detection_radius: float = 160.0

var _spec: HitSpec = null
var _direction: Vector2 = Vector2.RIGHT
var _active: bool = false

## Instance ids already hit during this activation. Cleared, never reallocated.
var _already_hit: Dictionary = {}

## Refilled per hit rather than rebuilt (see the class doc).
var _event: HitEvent = HitEvent.new()

var _shape: CircleShape2D = null
var _collision: CollisionShape2D = null


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = CombatLayers.NONE
	collision_mask = CombatLayers.HURTBOX_MASK
	_ensure_shape()
	area_entered.connect(_on_area_entered)


## Point this hitbox at the Combatant swinging it, and size its detector to the
## widest hit that Combatant can throw.
func configure(owner_faction: Faction.Id, reach: float) -> void:
	faction = owner_faction
	configure_reach(reach)


## Size the detector. Called once at setup - see the class doc for why never again.
func configure_reach(reach: float) -> void:
	detection_radius = maxf(reach, 1.0)
	_ensure_shape()
	if _shape != null:
		_shape.radius = detection_radius


## Open the window: this spec, thrown this way, from wherever this node is.
##
## `at_time` is in-game seconds (`GameClock`), stamped onto the event for anything
## that wants to know when a hit happened; it is never compared to real time.
func activate(spec: HitSpec, direction: Vector2, at_time: float = 0.0) -> void:
	if spec == null:
		return
	_spec = spec
	_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_event.time = at_time
	_already_hit.clear()
	_active = true
	_sweep()


## Close the window.
func deactivate() -> void:
	_active = false
	_spec = null


## True while the window is open.
func is_active() -> bool:
	return _active


## The spec currently being swung, or `null`.
func spec() -> HitSpec:
	return _spec


## How many distinct hurtboxes this activation has hit. What "one hit per activation"
## is proven with.
func hits_this_activation() -> int:
	return _already_hit.size()


# --- Internals ---------------------------------------------------------------


## Everything already standing inside the box when the window opened. `area_entered`
## alone would miss a target that never moved, which is most of them.
func _sweep() -> void:
	for area: Area2D in get_overlapping_areas():
		_try_hit(area as Hurtbox)


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	_try_hit(area as Hurtbox)


## Deliver the hit, if this hurtbox is one this swing may hit and has not hit yet.
func _try_hit(hurtbox: Hurtbox) -> void:
	if not _active or _spec == null or hurtbox == null or not hurtbox.is_vulnerable():
		return
	if not Faction.is_hostile(faction, hurtbox.faction):
		return
	var key := hurtbox.get_instance_id()
	if _already_hit.has(key):
		return
	if not _spec.covers(hurtbox.global_position - global_position, _direction):
		return
	_already_hit[key] = true
	_event.configure(faction, _spec, global_position, _direction, _event.time)
	var result := hurtbox.combatant().take_hit(_event)
	hit_landed.emit(hurtbox, _spec, result)


## Build the detector if the scene did not author one.
func _ensure_shape() -> void:
	if _collision != null:
		return
	for child: Node in get_children():
		var found := child as CollisionShape2D
		if found != null:
			_collision = found
			break
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "Detector"
		add_child(_collision)
	var circle := _collision.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		_collision.shape = circle
	_shape = circle
	_shape.radius = detection_radius
