extends Sprite2D

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

const DIRECTIONS := [
	"east",
	"southeast",
	"south",
	"southwest",
	"west",
	"northwest",
	"north",
	"northeast",
]


func _physics_process(delta: float) -> void:
	move(Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"), delta)


func move(input_dir: Vector2, delta: float) -> void:
	if input_dir.is_zero_approx():
		return

	var normalized_input := input_dir.normalized()
	position += normalized_input * SPEED * delta

	var direction_index := wrapi(roundi(normalized_input.angle() / (PI / 4.0)), 0, 8)
	texture = DIRECTION_TEXTURES[DIRECTIONS[direction_index]]
