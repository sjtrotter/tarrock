extends SceneTree

var _all_passed := true
var _frame := 0
var _fool: CharacterBody2D


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/movement_test.tscn")
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	_fool = root.find_child("Fool", true, false) as CharacterBody2D


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	_all_passed = check(_fool != null, "Fool node exists") and _all_passed

	var sprite := _fool.get_node_or_null("Sprite") as Sprite2D if _fool != null else null
	var valid_texture := (
		sprite != null
		and sprite.texture != null
		and sprite.texture.get_width() > 0
		and sprite.texture.get_height() > 0
	)
	_all_passed = check(valid_texture, "Fool texture loaded with non-zero dimensions") and _all_passed

	var moved_right := false
	if _fool != null:
		var starting_x := _fool.position.x
		for index in 10:
			_fool.move(Vector2.RIGHT, 1.0 / 60.0)
		moved_right = _fool.position.x > starting_x
	_all_passed = check(moved_right, "Fool moves to the right") and _all_passed

	_finish()
	return true


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true
	print("FAIL: " + description)
	return false


func _finish() -> void:
	if _all_passed:
		print("SMOKE TEST: PASS")
		quit(0)
	else:
		print("SMOKE TEST: FAIL")
		quit(1)
