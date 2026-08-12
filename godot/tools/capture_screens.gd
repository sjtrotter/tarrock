extends SceneTree

## Screenshot harness for the Cliff. Not a test - a way to look at the scene.
##
##   godot --path godot --script tools/capture_screens.gd -- /some/prefix-
##
## Writes one PNG per entry in SHOTS. Needs a real (windowed) run: the capture reads
## the window's framebuffer, so `--headless` produces nothing useful.
##
## Two things this harness learned the hard way:
##   * Pose/teleport, THEN wait frames, THEN capture. Capturing in the same frame you
##     changed something grabs the previous frame's image.
##   * `set_physics_process(false)` has to happen after the node has finished entering
##     the tree - Godot re-enables it on ready - or the Fool's own physics step resets
##     the sprite to its static frame before anything is drawn.

const SHOTS := [
	{"name": "overview", "pos": Vector2(2500, 1700), "zoom": 0.22},
	{"name": "spawn", "pos": Vector2(3820, 2560), "zoom": 1.0},
	{"name": "bowl", "pos": Vector2(2400, 1700), "zoom": 1.0},
	{"name": "tree", "pos": Vector2(2250, 1350), "zoom": 1.0},
	{"name": "rim", "pos": Vector2(1000, 1800), "zoom": 1.0},
	# The Fool walking south-east: the one authored cycle, mid-stride.
	{"name": "walk", "pos": Vector2(2600, 2000), "zoom": 1.6, "walk_steps": 14},
	# The tall-grass swatch untouched, then with the Fool standing in it.
	{"name": "grass-rest", "pos": Vector2(3650, 2350), "zoom": 1.4, "camera_offset": Vector2(-900, 0)},
	{"name": "grass-touched", "pos": Vector2(2750, 2350), "zoom": 1.4},
]

var _prefix := "/tmp/cliff-"
var _scene: Node2D
var _fool: CharacterBody2D
var _camera: Camera2D
var _shot := 0
var _wait := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_prefix = args[0]
	var packed: PackedScene = load("res://scenes/the_cliff.tscn")
	_scene = packed.instantiate() as Node2D
	root.add_child(_scene)
	_fool = _scene.get_node_or_null("World/Fool") as CharacterBody2D
	_camera = _fool.get_node_or_null("Camera2D") as Camera2D
	_camera.position_smoothing_enabled = false
	_camera.limit_left = -100000
	_camera.limit_right = 100000
	_camera.limit_top = -100000
	_camera.limit_bottom = 100000
	_apply_shot()


func _apply_shot() -> void:
	var shot: Dictionary = SHOTS[_shot]
	_fool.set_physics_process(not shot.has("walk_steps"))
	_fool.global_position = shot["pos"]
	_camera.zoom = Vector2(shot["zoom"], shot["zoom"])
	_camera.position = shot.get("camera_offset", Vector2.ZERO)
	if shot.has("walk_steps"):
		for step in int(shot["walk_steps"]):
			_fool.move(Vector2(1, 1).normalized(), 1.0 / 60.0)
	_camera.reset_smoothing()
	_wait = 0


func _process(_delta: float) -> bool:
	_wait += 1
	if _wait < 20:
		return false
	var shot: Dictionary = SHOTS[_shot]
	var path := "%s%s.png" % [_prefix, shot["name"]]
	root.get_texture().get_image().save_png(path)
	print("SAVED ", path)
	_shot += 1
	if _shot >= SHOTS.size():
		return true
	_apply_shot()
	return false
