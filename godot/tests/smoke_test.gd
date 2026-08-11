extends SceneTree


func _initialize() -> void:
	var all_passed := true
	var packed_scene: PackedScene = load("res://main.tscn")
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)

	var fool: Variant = root.find_child("Fool", true, false)
	all_passed = check(fool != null, "Fool node exists") and all_passed

	if fool != null:
		var valid_texture: bool = (
			fool.texture != null
			and fool.texture.get_width() > 0
			and fool.texture.get_height() > 0
		)
		all_passed = check(valid_texture, "Fool texture loaded with non-zero dimensions") and all_passed

		var starting_position: Vector2 = fool.position
		for index in 10:
			fool.move(Vector2(1, 0), 1.0 / 60.0)
		all_passed = check(fool.position.x > starting_position.x, "Fool moves to the right") and all_passed
	else:
		all_passed = check(false, "Fool texture loaded with non-zero dimensions") and all_passed
		all_passed = check(false, "Fool moves to the right") and all_passed

	if all_passed:
		print("SMOKE TEST: PASS")
		quit(0)
	else:
		print("SMOKE TEST: FAIL")
		quit(1)


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true

	print("FAIL: " + description)
	return false
