extends CharacterBody2D

const SPEED := 200.0

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

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_ensure_animator()


func _physics_process(delta: float) -> void:
	move(
		Input.get_vector(
			InputActions.MOVE_LEFT,
			InputActions.MOVE_RIGHT,
			InputActions.MOVE_UP,
			InputActions.MOVE_DOWN
		),
		delta
	)


func move(input_dir: Vector2, delta: float) -> void:
	_ensure_animator()
	if input_dir.is_zero_approx():
		velocity = Vector2.ZERO
		# No idle cycle is wired: a bound world holds still, and only the south-east
		# idle exists anyway. This resolves to the static facing frame.
		_animator.set_state(_facing, "idle")
		_animator.advance(delta)
		return

	var dir := input_dir.normalized()
	var direction_index := wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)
	_facing = DIRECTIONS[direction_index]
	_animator.set_state(_facing, "walk")
	_animator.advance(delta)
	velocity = dir * SPEED
	move_and_collide(velocity * delta)


func facing_name() -> String:
	return _facing


func animator() -> CharacterAnimator:
	_ensure_animator()
	return _animator


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
