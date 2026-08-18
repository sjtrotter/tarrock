class_name FoolBody
extends CharacterBody2D

## The Fool's body: movement, facing, the interact reach, and the small API the
## combat component drives it through.
##
## It is presentation plus locomotion and nothing else - it owns no combat rule. The
## Bindle moveset lives in `systems/combat/` and reaches the body only through
## `set_movement_multiplier()`, `displace()`, `face_direction()`, `facing_vector()`,
## `speed_fraction()`, `set_time_compensation()` and `set_sprint_hold_mode()`, which is
## the whole of the seam.
##
## The UI has a seam of its own, one call wide: `set_world_interaction_enabled()`. While
## somebody is talking to the Fool or a menu is up, `interact` belongs to the screen and
## not to the world - see that method for why a consumed event is not enough on its own.

const SPEED := 200.0

## How much faster the Fool travels while the sprint input is on. Sprinting is what
## makes an attack come out as the running attack (`docs/design/combat.md` §The
## Bindle: "A forward lunge strike, closes distance and interrupts"), so the body has
## to have a run to attack out of. TBD, like every other combat number - it belongs
## to the same tuning pass as `res://data/combat/combat_rules.tres`.
const SPRINT_MULTIPLIER := 1.6

## How far from the Fool an `Interactable` may sit and still answer the interact
## key. A reach, not a room: far enough that a prop does not need pixel-perfect
## approach, near enough that "the nearest one" is never a surprise.
const INTERACT_REACH := 96.0

## The smallest `set_time_compensation()` will accept. A compensation of zero would
## freeze the Fool outright and a negative one would walk them backwards; neither is
## a thing any caller means.
const MIN_TIME_COMPENSATION := 0.01

const DIRECTION_TEXTURES := {
	"south": preload("res://art/game-ready-sprites-v1/frames/fool/directions/south.png"),
	"southwest": preload("res://art/game-ready-sprites-v1/frames/fool/directions/southwest.png"),
	"west": preload("res://art/game-ready-sprites-v1/frames/fool/directions/west.png"),
	"northwest": preload("res://art/game-ready-sprites-v1/frames/fool/directions/northwest.png"),
	"north": preload("res://art/game-ready-sprites-v1/frames/fool/directions/north.png"),
	"northeast": preload("res://art/game-ready-sprites-v1/frames/fool/directions/northeast.png"),
	"east": preload("res://art/game-ready-sprites-v1/frames/fool/directions/east.png"),
	"southeast": preload("res://art/game-ready-sprites-v1/frames/fool/directions/southeast.png"),
}

const DIRECTIONS := ["east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast"]

## Measured from the direction sheet's alpha. Do not eyeball these.
const DIRECTION_OFFSETS := {
	"south": Vector2(-44.5, -195.0),
	"southwest": Vector2(12.0, -197.0),
	"west": Vector2(46.0, -199.0),
	"northwest": Vector2(78.0, -195.0),
	"north": Vector2(-41.0, -191.0),
	"northeast": Vector2(7.5, -199.0),
	"east": Vector2(65.0, -199.0),
	"southeast": Vector2(79.0, -204.0),
}
const DIRECTION_SCALE := 0.28

## The one authored walk cycle: four frames, south-east facing (action atlas row 0).
## Anchors were measured per frame from the alpha - x on the alpha centroid (the
## steadiest landmark across the cycle, the frames drift ~56 px across the cell),
## y on the lowest opaque pixel so the planted foot stays on the ground line.
const WALK_FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-3.png"),
]
const WALK_OFFSETS := [
	Vector2(-16.1, -153.0),
	Vector2(10.1, -150.0),
	Vector2(15.0, -141.0),
	Vector2(38.6, -146.0),
]
## The action cells are 320 px and the direction cells 512 px, so the walk cycle
## needs its own scale to keep the Fool the same height when he starts moving:
## 437 px * 0.28 / 291.75 px = 0.419.
const WALK_SCALE := 0.419
const WALK_FPS := 8.0

var _facing := "south"
var _animator: CharacterAnimator = null

## What the combat component scales this frame's movement by: 0 through an attack's
## windup, small through its recovery, 1 when the Fool is free.
var _movement_multiplier := 1.0

## Sprint, through the hold/toggle layer `combat.md` §Accessibility asks for.
var _sprint := HoldOrToggle.new()
var _sprinting := false

## What this frame's delta is multiplied by before the body moves or the animator
## advances. 1.0 normally; `1 / Engine.time_scale` while Fool's Chance is running, so
## the Fool walks and animates at NORMAL speed through a slowed world - see
## `set_time_compensation()`.
var _time_compensation := 1.0

## The Fool's reach, built in code so the character scene stays art-only. Areas
## overlapping it are the `Interactable`s the interact key may reach.
var _sensor: Area2D = null

## True while the Fool's hands are his own. `UiShell` puts it down for as long as a
## conversation is on screen or a menu is up (`set_world_interaction_enabled()`).
var _world_interaction_enabled := true

## True while the press that ENDED a conversation is still held down. That press is the
## parchment's, and the key has to come up before the world hears it again - see
## `set_world_interaction_enabled()`.
var _interact_held_through_resume := false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_ensure_animator()
	_ensure_sensor()


func _physics_process(delta: float) -> void:
	_sprinting = _sprint.update(Input.is_action_pressed(InputActions.SPRINT))
	move(
		Input.get_vector(
			InputActions.MOVE_LEFT,
			InputActions.MOVE_RIGHT,
			InputActions.MOVE_UP,
			InputActions.MOVE_DOWN
		),
		delta
	)
	if _interact_held_through_resume and not Input.is_action_pressed(InputActions.INTERACT):
		_interact_held_through_resume = false
	if (
		_world_interaction_enabled
		and not _interact_held_through_resume
		and Input.is_action_just_pressed(InputActions.INTERACT)
	):
		try_interact()


## Act on the nearest `Interactable` within reach; returns the one that answered.
##
## This is the whole interact verb: the Fool never knows what a prop means, and the
## prop never knows a quest exists - it emits its event and the region scene forwards
## it to `QuestService`. Approach-shaped and used-up nodes are skipped, so a spent
## trigger cannot shadow a live one standing behind it.
##
## Answers nothing at all while world interaction is suspended, so the suspension holds
## for a caller as well as for the key.
func try_interact() -> Interactable:
	if not _world_interaction_enabled:
		return null
	_ensure_sensor()
	var nearest: Interactable = null
	var nearest_distance := INF
	for area: Area2D in _sensor.get_overlapping_areas():
		var candidate := area as Interactable
		if candidate == null or not candidate.is_interactable():
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	if nearest != null:
		nearest.interact()
	return nearest


## Take the Fool's hands off the world, or give them back.
##
## `UiShell` calls this - it is the one node that knows both that a conversation is on
## screen and that a menu is up - and the default is true, so a Fool with no shell over
## him (a fixture, a spike scene) still interacts.
##
## **Why a consumed event is not enough.** `DialogueFrame` answers `interact` as an
## EVENT and calls `set_input_as_handled()`, and this body POLLS the same action;
## handling an event does not stop a poll, so without this the press that advances the
## Querent's waking line also picks up whatever prop is in reach. On the Cliff that is
## not theoretical: a new game stands the Fool 184 px from the `BindleTrigger`, whose
## 90 px circle and the 96 px `INTERACT_REACH` overlap at 186, and the Bindle was taken
## before the tutorial asked for it (`res://tests/README.md` §The proof slice).
##
## Turning interaction back on does not hand over the press that turned it on: the
## conversation is dismissed by an `interact` that is still down in the same frame this
## is called, so that press is left to the parchment and the key must come up before
## the world hears it again.
func set_world_interaction_enabled(enabled: bool) -> void:
	if enabled == _world_interaction_enabled:
		return
	_world_interaction_enabled = enabled
	_interact_held_through_resume = (
		enabled and Input.is_action_pressed(InputActions.INTERACT)
	)


## True while the Fool may act on the world with `interact`.
func world_interaction_enabled() -> bool:
	return _world_interaction_enabled


func move(input_dir: Vector2, delta: float) -> void:
	_ensure_animator()
	# One place, one multiplication: everything downstream of here runs on the Fool's
	# own seconds rather than the world's (see `set_time_compensation()`).
	var own_delta := delta * _time_compensation
	if input_dir.is_zero_approx():
		velocity = Vector2.ZERO
		# No idle cycle is wired: a bound world holds still, and only the south-east
		# idle exists anyway. This resolves to the static facing frame.
		_animator.set_state(_facing, "idle")
		_animator.advance(own_delta)
		return

	var dir := input_dir.normalized()
	# A committed attack does not turn the Fool: the swing goes where it was aimed.
	if _movement_multiplier > 0.0:
		face_direction(dir)
	_animator.set_state(_facing, "walk")
	_animator.advance(own_delta)
	velocity = dir * top_speed() * _movement_multiplier
	move_and_collide(velocity * own_delta)


## The fastest the Fool can travel right now, sprint included. `speed_fraction()` is
## measured against the sprint speed, so walking reads as a fraction and only a real
## run clears `CombatRules.running_attack_min_speed_fraction`.
func top_speed() -> float:
	return SPEED * (SPRINT_MULTIPLIER if _sprinting else 1.0)


## How fast the Fool is moving as a fraction of a full sprint. What the moveset reads
## to decide whether an attack input is the running attack.
func speed_fraction() -> float:
	return velocity.length() / (SPEED * SPRINT_MULTIPLIER)


## Run the body in the Fool's own time rather than the world's.
##
## `docs/design/combat.md` §Defense: during Fool's Chance "the Fool moves at normal
## speed relative to a slowed world". The engine has already scaled this frame's delta
## down by `Engine.time_scale`, and `MovesetController` gets that scale divided back
## out by `FoolCombat` - but the moveset is only the swings and the dodges. WALKING
## and the walk cycle are the body's, and without this they would still crawl at
## `Engine.time_scale` while the Fool's dodge covered its full distance: the Fool would
## roll at normal speed and then wade. `FoolCombat` sets this to `1 / Engine.time_scale`
## for exactly as long as the service reports the window open, and back to 1.0 after.
##
## It is a compensation, not a speed setting: nothing else may write it, and it is
## never how the Fool is made faster (`SPRINT_MULTIPLIER` and
## `set_movement_multiplier()` are).
func set_time_compensation(scale: float) -> void:
	_time_compensation = maxf(MIN_TIME_COMPENSATION, scale)


## What this frame's delta is being multiplied by. 1.0 in normal time.
func time_compensation() -> float:
	return _time_compensation


## Put sprint on hold or on toggle (`combat.md` §Accessibility lists sprint as one of
## the held inputs that needs the choice). Sprint is the body's own input rather than
## the moveset's, so its `HoldOrToggle` lives here and `FoolCombat.set_hold_mode()`
## forwards to this - one settings call reaches every held input in the game.
func set_sprint_hold_mode(mode: HoldOrToggle.Mode) -> void:
	_sprint.set_mode(mode)


## Which mode sprint is in.
func sprint_hold_mode() -> HoldOrToggle.Mode:
	return _sprint.mode()


## Scale this frame's walking. Set by the combat component every frame; 1 means free.
func set_movement_multiplier(multiplier: float) -> void:
	_movement_multiplier = clampf(multiplier, 0.0, 1.0)


## What walking is currently scaled by.
func movement_multiplier() -> float:
	return _movement_multiplier


## Move the Fool by a vector this frame, on top of walking. This is how a dodge, a
## block-step hop and a running attack's lunge actually travel: the moveset decides
## the distance, the body decides what it collides with on the way.
func displace(step: Vector2) -> void:
	if step.is_zero_approx():
		return
	move_and_collide(step)


## Turn the Fool to face a direction without moving them. Focus strafing is this
## called every frame with the direction of the lock (`combat.md` §Focus: "the Fool
## keeps facing the target while circling").
func face_direction(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	var index := wrapi(roundi(direction.angle() / (PI / 4.0)), 0, 8)
	_facing = DIRECTIONS[index]


## The Fool's facing as a unit vector, the form the moveset works in.
func facing_vector() -> Vector2:
	return Vector2.RIGHT.rotated(DIRECTIONS.find(_facing) * PI / 4.0)


func facing_name() -> String:
	return _facing


func animator() -> CharacterAnimator:
	_ensure_animator()
	return _animator


func _ensure_sensor() -> void:
	if _sensor != null:
		return
	var shape := CircleShape2D.new()
	shape.radius = INTERACT_REACH
	var collision := CollisionShape2D.new()
	collision.shape = shape
	_sensor = Area2D.new()
	_sensor.name = "InteractionSensor"
	# It looks for areas, and nothing looks for it: a reach is not a hitbox.
	_sensor.monitoring = true
	_sensor.monitorable = false
	_sensor.add_child(collision)
	add_child(_sensor)


func _ensure_animator() -> void:
	if _animator != null:
		return
	if _sprite == null:
		_sprite = get_node_or_null("Sprite") as Sprite2D
	_animator = CharacterAnimator.new()
	_animator.configure(_sprite, build_animation_table())


## (direction, action) -> clip. Add a direction's cycle here when its art lands.
static func build_animation_table() -> Dictionary:
	var static_action := {}
	for direction: String in DIRECTIONS:
		static_action[direction] = CharacterAnimator.make_clip(
			[DIRECTION_TEXTURES[direction]], [DIRECTION_OFFSETS[direction]], DIRECTION_SCALE, 1.0, false
		)
	return {
		"static": static_action,
		"walk": {
			"southeast": CharacterAnimator.make_clip(WALK_FRAMES, WALK_OFFSETS, WALK_SCALE, WALK_FPS, true),
		},
	}
