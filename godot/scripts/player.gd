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

@onready var _sprite: Sprite2D = $Sprite

var _facing := "south"


func _physics_process(delta: float) -> void:
	move(Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"), delta)


func move(input_dir: Vector2, delta: float) -> void:
	if input_dir.is_zero_approx():
		velocity = Vector2.ZERO
		return

	var dir := input_dir.normalized()
	var direction_index := wrapi(roundi(dir.angle() / (PI / 4.0)), 0, 8)
	_facing = DIRECTIONS[direction_index]
	_sprite.texture = DIRECTION_TEXTURES[_facing]
	_sprite.offset = DIRECTION_OFFSETS[_facing]
	velocity = dir * SPEED
	move_and_collide(velocity * delta)


func facing_name() -> String:
	return _facing
