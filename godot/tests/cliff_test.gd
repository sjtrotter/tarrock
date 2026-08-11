extends SceneTree

const ISLAND: PackedVector2Array = preload("res://scripts/cliff_ground.gd").ISLAND

var _all_passed := true
var _frame := 0
var _phase := 0
var _phase_frame := 0
var _scene: Node2D
var _fool: CharacterBody2D
var _pip: Node2D
var _leap_received := false


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/the_cliff.tscn")
	_scene = packed_scene.instantiate() as Node2D
	root.add_child(_scene)
	_fool = _scene.get_node_or_null("World/Fool") as CharacterBody2D
	_pip = _scene.get_node_or_null("World/Pip") as Node2D
	_scene.leap_point_reached.connect(_on_leap_point_reached)


func _physics_process(_delta: float) -> bool:
	_frame += 1
	_phase_frame += 1

	if _phase == 0:
		if _frame < 3:
			return false
		_run_initial_checks()
		if _fool != null:
			_fool.global_position = Vector2(4200, 1900)
		_advance_phase()
		return false

	if _phase == 1:
		if _fool != null:
			_fool.move(Vector2.RIGHT, 1.0 / 60.0)
		if _phase_frame < 150:
			return false
		var blocked := _fool != null and Geometry2D.is_point_in_polygon(_fool.global_position, ISLAND)
		_all_passed = check(blocked, "Island boundary blocks the Fool at a solid rim edge") and _all_passed
		if _fool != null:
			_fool.global_position = Vector2(1150, 650)
		_advance_phase()
		return false

	if _phase == 2:
		if _phase_frame < 3:
			return false
		var leap_point := _scene.get_node_or_null("LeapPoint") as Area2D
		var overlapping := leap_point != null and _fool != null and leap_point.get_overlapping_bodies().has(_fool)
		_all_passed = check(overlapping, "LeapPoint reports the Fool overlapping it") and _all_passed
		# The emitted signal is the deliverable, not just the overlap - assert it on its own.
		_all_passed = check(_leap_received, "leap_point_reached signal emitted when the Fool reaches the leap point") and _all_passed
		if _fool != null and _pip != null:
			_fool.global_position = Vector2(1150, 650)
			_pip.global_position = Vector2(2150, 650)
		_advance_phase()
		return false

	if _phase == 3:
		var followed := false
		if _fool != null and _pip != null:
			var starting_distance := _pip.global_position.distance_to(_fool.global_position)
			for index in 300:
				_pip.step_follow(1.0 / 60.0)
			var ending_distance := _pip.global_position.distance_to(_fool.global_position)
			followed = ending_distance < starting_distance and ending_distance >= 119.0 and ending_distance <= 121.0
		_all_passed = check(followed, "Pip follows and stops near FOLLOW_DISTANCE without converging to zero") and _all_passed
		_finish()
		return true

	return false


func _run_initial_checks() -> void:
	var fool_sprite := _fool.get_node_or_null("Sprite") as Sprite2D if _fool != null else null
	var fool_valid := _fool != null and _texture_is_loaded(fool_sprite)
	_all_passed = check(fool_valid, "Fool exists with a loaded Sprite texture") and _all_passed

	var pip_sprite := _pip.get_node_or_null("Sprite") as Sprite2D if _pip != null else null
	var pip_valid := _pip != null and _texture_is_loaded(pip_sprite)
	_all_passed = check(pip_valid, "Pip exists with a loaded Sprite texture") and _all_passed

	var moved_right := false
	if _fool != null:
		var starting_x := _fool.position.x
		for index in 10:
			_fool.move(Vector2.RIGHT, 1.0 / 60.0)
		moved_right = _fool.position.x > starting_x
	_all_passed = check(moved_right, "Fool moves right from the spawn point") and _all_passed

	var boundary := _scene.find_child("IslandBoundary", true, false) as StaticBody2D
	var collision_count := 0
	if boundary != null:
		for child in boundary.get_children():
			if child is CollisionShape2D:
				collision_count += 1
	_all_passed = check(boundary != null and collision_count >= 12, "IslandBoundary exists with at least 12 collision shapes") and _all_passed

	var leap_point := _scene.get_node_or_null("LeapPoint") as Area2D
	_all_passed = check(leap_point != null and leap_point.monitoring, "LeapPoint exists and is monitoring") and _all_passed


func _texture_is_loaded(sprite: Sprite2D) -> bool:
	return sprite != null and sprite.texture != null and sprite.texture.get_width() > 0 and sprite.texture.get_height() > 0


func _advance_phase() -> void:
	_phase += 1
	_phase_frame = 0


func _on_leap_point_reached() -> void:
	_leap_received = true


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true
	print("FAIL: " + description)
	return false


func _finish() -> void:
	if _all_passed:
		print("CLIFF TEST: PASS")
		quit(0)
	else:
		print("CLIFF TEST: FAIL")
		quit(1)
