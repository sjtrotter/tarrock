extends SceneTree

## The signature effect: a bound world holds still but yields to touch.
##
## Asserts the two halves of the canon rule (docs/design/art-audio.md):
##   1. Nothing moves on its own - with no body near, the field is bit-for-bit static
##      across physics steps.
##   2. Everything moves when a body moves through it - the Fool walking up to a tuft
##      leans it away from him, and it returns to its rest pose once he has passed.

const STEP := 1.0 / 60.0

var _all_passed := true
var _frame := 0


func _initialize() -> void:
	# The persistent layer, not the Cliff: from round 10 the Fool and Pip live above
	# the region scene, and booting the layer is what puts a region under them
	# (`docs/design/technical.md` §Regions and the persistent layer).
	var packed_scene: PackedScene = load("res://scenes/persistent_layer.tscn")
	root.add_child(packed_scene.instantiate())


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	var grass := root.find_child("TallGrass", true, false)
	var fool := root.find_child("Fool", true, false) as CharacterBody2D
	var pip := root.find_child("Pip", true, false) as Node2D
	_all_passed = check(grass != null and fool != null and pip != null, "TallGrass, Fool and Pip all exist") and _all_passed
	if grass == null or fool == null or pip == null:
		_finish()
		return true

	_all_passed = check(grass.tuft_count() >= 60, "Tall grass swatches were placed (%d tufts)" % grass.tuft_count()) and _all_passed

	# Park both bodies far away so nothing is being touched.
	fool.global_position = Vector2(-9000, -9000)
	pip.global_position = Vector2(-9000, -9200)
	for index in 60:
		grass.step_displacement(STEP)

	var index_under_test := 0
	var rest: float = grass.tuft_rest_lean(index_under_test)
	_all_passed = check(absf(rest) > 0.05, "Tufts rest in a wind-combed lean, not upright (%.3f rad)" % rest) and _all_passed

	var settled: float = grass.tuft_lean(index_under_test)
	grass.step_displacement(STEP)
	grass.step_displacement(STEP)
	var still: bool = grass.tuft_lean(index_under_test) == settled and is_equal_approx(settled, rest)
	_all_passed = check(still, "Untouched grass is exactly static across physics steps") and _all_passed

	# Walk the Fool up beside the tuft: it must lean away from him.
	var tuft_position: Vector2 = grass.tuft_position(index_under_test)
	fool.global_position = tuft_position + Vector2(40.0, 0.0)
	for index in 20:
		grass.step_displacement(STEP)
	var pushed: float = grass.tuft_lean(index_under_test)
	_all_passed = check(absf(pushed - rest) > 0.05, "A tuft leans when the Fool stands in it (%.3f -> %.3f rad)" % [rest, pushed]) and _all_passed
	_all_passed = check(pushed < rest, "The tuft leans away from the body, not into it") and _all_passed

	# Same tuft, body on the other side: it must lean the other way.
	fool.global_position = tuft_position - Vector2(40.0, 0.0)
	for index in 40:
		grass.step_displacement(STEP)
	var pushed_other: float = grass.tuft_lean(index_under_test)
	_all_passed = check(pushed_other > rest, "The lean direction follows which side the body is on") and _all_passed

	# Walk away: it must return to rest, exactly.
	fool.global_position = Vector2(-9000, -9000)
	var mid_recovery := 0.0
	for index in 200:
		grass.step_displacement(STEP)
		if index == 3:
			mid_recovery = grass.tuft_lean(index_under_test)
	var recovered: float = grass.tuft_lean(index_under_test)
	_all_passed = check(absf(mid_recovery - rest) < absf(pushed_other - rest), "The tuft eases back rather than snapping") and _all_passed
	_all_passed = check(recovered == rest, "The tuft returns exactly to its rest pose once the body has passed") and _all_passed

	# Pip displaces grass too.
	pip.global_position = tuft_position + Vector2(30.0, 10.0)
	for index in 20:
		grass.step_displacement(STEP)
	_all_passed = check(absf(grass.tuft_lean(index_under_test) - rest) > 0.05, "Pip displaces grass as well as the Fool") and _all_passed

	# Displacement is local: a tuft outside the influence radius is untouched.
	var far_index: int = grass.nearest_tuft(Vector2(-9000, -9000))
	if far_index == index_under_test:
		far_index = grass.tuft_count() - 1
	_all_passed = check(
		grass.tuft_lean(far_index) == grass.tuft_rest_lean(far_index),
		"Grass out of reach of a body does not move"
	) and _all_passed

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
		print("GRASS DISPLACEMENT TEST: PASS")
		quit(0)
	else:
		print("GRASS DISPLACEMENT TEST: FAIL")
		quit(1)
