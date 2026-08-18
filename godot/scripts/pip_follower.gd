extends Node2D

const SPEED := 230.0
const FOLLOW_DISTANCE := 120.0
const RESUME_DISTANCE := 165.0

const DIRECTIONS := ["east", "southeast", "south", "southwest", "west", "northwest", "north", "northeast"]

const DIRECTION_TEXTURES := {
	"south": preload("res://art/game-ready-sprites-v1/frames/pip/directions/south.png"),
	"southwest": preload("res://art/game-ready-sprites-v1/frames/pip/directions/southwest.png"),
	"west": preload("res://art/game-ready-sprites-v1/frames/pip/directions/west.png"),
	"northwest": preload("res://art/game-ready-sprites-v1/frames/pip/directions/northwest.png"),
	"north": preload("res://art/game-ready-sprites-v1/frames/pip/directions/north.png"),
	"northeast": preload("res://art/game-ready-sprites-v1/frames/pip/directions/northeast.png"),
	"east": preload("res://art/game-ready-sprites-v1/frames/pip/directions/east.png"),
	"southeast": preload("res://art/game-ready-sprites-v1/frames/pip/directions/southeast.png"),
}

## Measured from the direction sheet's alpha. Do not eyeball these.
const PIP_OFFSETS := {
	"south": Vector2(-24.5, -219.0),
	"southwest": Vector2(-9.5, -219.0),
	"west": Vector2(32.5, -215.0),
	"northwest": Vector2(45.0, -217.0),
	"north": Vector2(-18.5, -115.0),
	"northeast": Vector2(-18.5, -120.0),
	"east": Vector2(30.0, -110.0),
	"southeast": Vector2(53.0, -111.0),
}
const DIRECTION_SCALE := 0.15

## Pip's one authored cycle: four frames of a south-east trot (action atlas row 0).
## Anchors measured per frame from the alpha, same convention as the Fool's walk.
const TROT_FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/pip/actions/trot-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/pip/actions/trot-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/pip/actions/trot-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/pip/actions/trot-3.png"),
]
const TROT_OFFSETS := [
	Vector2(-11.2, -118.0),
	Vector2(-7.9, -122.0),
	Vector2(6.7, -124.0),
	Vector2(16.5, -122.0),
]
## 310 px * 0.15 / 212.25 px = 0.219, so Pip keeps his height when he starts trotting.
const TROT_SCALE := 0.219
const TROT_FPS := 10.0

@export var target_path: NodePath = NodePath("../Fool")

var _target: Node2D
var _moving := false
var _facing := "south"
var _animator: CharacterAnimator = null

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_ensure_animator()
	_target = get_node_or_null(target_path) as Node2D


func _physics_process(delta: float) -> void:
	step_follow(delta)


func step_follow(delta: float) -> void:
	_ensure_animator()
	if not is_instance_valid(_target):
		return

	var to_target := _target.global_position - global_position
	var distance := to_target.length()
	if distance > RESUME_DISTANCE:
		_moving = true
	elif distance <= FOLLOW_DISTANCE:
		_moving = false

	if not _moving or to_target.is_zero_approx():
		_animator.set_state(_facing, "idle")
		_animator.advance(delta)
		return

	var direction := to_target.normalized()
	var distance_to_travel := minf(SPEED * delta, maxf(distance - FOLLOW_DISTANCE, 0.0))
	global_position += direction * distance_to_travel
	_update_facing(direction)
	_animator.set_state(_facing, "trot")
	_animator.advance(delta)


func facing_name() -> String:
	return _facing


func animator() -> CharacterAnimator:
	_ensure_animator()
	return _animator


func _update_facing(direction: Vector2) -> void:
	var direction_index := wrapi(roundi(direction.angle() / (PI / 4.0)), 0, 8)
	_facing = DIRECTIONS[direction_index]


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
			[DIRECTION_TEXTURES[direction]], [PIP_OFFSETS[direction]], DIRECTION_SCALE, 1.0, false
		)
	return {
		"static": static_action,
		"trot": {
			"southeast": CharacterAnimator.make_clip(TROT_FRAMES, TROT_OFFSETS, TROT_SCALE, TROT_FPS, true),
		},
	}
