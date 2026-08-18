extends SceneTree

## The direction+action animation system.
##
## What ships today: one authored south-east walk cycle for the Fool and one for Pip
## (his trot). Every other direction falls back to its static facing frame until the
## art lands (godot/art/ART-REQUESTS.md). This test pins that contract, and pins the
## measured pivot tables so a future edit cannot quietly break the foot anchors.

const PlayerScript := preload("res://scripts/player.gd")
const PipScript := preload("res://scripts/pip_follower.gd")
const STEP := 1.0 / 60.0

var _all_passed := true
var _frame := 0


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/the_cliff.tscn")
	root.add_child(packed_scene.instantiate())


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	var fool := root.find_child("Fool", true, false) as CharacterBody2D
	var pip := root.find_child("Pip", true, false) as Node2D
	if not check(fool != null and pip != null, "Fool and Pip exist"):
		_all_passed = false
		_finish()
		return true

	var sprite := fool.get_node_or_null("Sprite") as Sprite2D
	var animator: CharacterAnimator = fool.animator()

	# --- static facings ---------------------------------------------------------
	# Every direction resolves to something, and the measured pivots are applied.
	var pivots_ok := true
	var facings_ok := true
	for direction: String in PlayerScript.DIRECTIONS:
		animator.set_state(direction, "walk")
		if animator.current_action() != "walk":
			if animator.current_action() != "static":
				facings_ok = false
			if sprite.offset != PlayerScript.DIRECTION_OFFSETS[direction]:
				pivots_ok = false
			if sprite.texture != PlayerScript.DIRECTION_TEXTURES[direction]:
				facings_ok = false
	_all_passed = check(facings_ok, "Directions with no cycle fall back to their static facing frame") and _all_passed
	_all_passed = check(pivots_ok, "Static facings keep their measured per-direction pivots") and _all_passed

	# --- the one authored cycle -------------------------------------------------
	animator.set_state("southeast", "walk")
	_all_passed = check(animator.current_action() == "walk", "South-east resolves to the authored walk cycle") and _all_passed
	_all_passed = check(animator.frame_count() == 4, "The walk cycle is four frames") and _all_passed

	var seen_frames := {}
	var seen_textures := {}
	for index in 60:
		animator.advance(STEP)
		seen_frames[animator.current_frame()] = true
		seen_textures[sprite.texture] = true
	_all_passed = check(seen_frames.size() == 4, "All four walk frames play (%d seen)" % seen_frames.size()) and _all_passed
	_all_passed = check(seen_textures.size() == 4, "Each frame swaps the sprite texture") and _all_passed
	_all_passed = check(animator.is_animated(), "The walk clip reports itself as animated") and _all_passed

	# Anchors: every walk frame gets its own measured offset, and the clip scale
	# keeps the walking Fool the same height as the standing one.
	var offsets_ok := true
	for frame_index in range(PlayerScript.WALK_FRAMES.size()):
		# Re-enter the clip, then run it forward to the frame under test.
		animator.set_state("south", "walk")
		animator.set_state("southeast", "walk")
		while animator.current_frame() != frame_index:
			animator.advance(STEP)
		if sprite.offset != PlayerScript.WALK_OFFSETS[frame_index]:
			offsets_ok = false
		if sprite.texture != PlayerScript.WALK_FRAMES[frame_index]:
			offsets_ok = false
	_all_passed = check(offsets_ok, "Walk frames carry their own measured pivots") and _all_passed
	_all_passed = check(is_equal_approx(sprite.scale.x, PlayerScript.WALK_SCALE), "The walk clip applies its own scale") and _all_passed

	animator.set_state("west", "walk")
	_all_passed = check(is_equal_approx(sprite.scale.x, PlayerScript.DIRECTION_SCALE), "Falling back restores the direction-sheet scale") and _all_passed

	# --- the move() contract is unchanged ---------------------------------------
	fool.global_position = Vector2(2600, 2000)
	var start := fool.global_position
	for index in 10:
		fool.move(Vector2(1, 1).normalized(), STEP)
	_all_passed = check(fool.global_position.x > start.x and fool.global_position.y > start.y, "move() still walks the Fool south-east") and _all_passed
	_all_passed = check(fool.facing_name() == "southeast", "move() sets the facing from the input heading") and _all_passed
	_all_passed = check(fool.animator().current_action() == "walk", "Moving south-east plays the walk cycle") and _all_passed

	for index in 10:
		fool.move(Vector2.LEFT, STEP)
	_all_passed = check(fool.animator().current_action() == "static", "Moving west falls back to the static west facing") and _all_passed

	fool.move(Vector2.ZERO, STEP)
	_all_passed = check(fool.velocity == Vector2.ZERO, "Zero input stops the Fool") and _all_passed
	_all_passed = check(fool.animator().current_action() == "static", "Standing still shows a static frame - no idle animation while bound") and _all_passed

	# --- Pip uses the same system -----------------------------------------------
	var pip_animator: CharacterAnimator = pip.animator()
	pip_animator.set_state("southeast", "trot")
	_all_passed = check(pip_animator.current_action() == "trot" and pip_animator.frame_count() == 4, "Pip has the same data-keyed setup with his south-east trot") and _all_passed
	pip_animator.set_state("north", "trot")
	_all_passed = check(pip_animator.current_action() == "static", "Pip's undrawn directions fall back the same way") and _all_passed

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
		print("ANIMATION TEST: PASS")
		quit(0)
	else:
		print("ANIMATION TEST: FAIL")
		quit(1)
