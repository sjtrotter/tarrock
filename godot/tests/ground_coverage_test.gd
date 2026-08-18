extends SceneTree

## Regression test for the "cloud swatches inside the island" bug.
##
## The cloud-sea sits at z=-100 behind everything. Before this test existed, the
## meadow tiler placed one organic blob per 256 px cell; each blob only paints about
## half its cell, so the island was a grid of grass islands with cloud showing
## through every gap. The tiler now guarantees coverage, and this asserts it at the
## data level: sample a grid of points inside the island polygon and require ground
## under every one of them.

const CliffGroundScript := preload("res://scripts/cliff_ground.gd")
const SAMPLE_STEP := 37.0

var _all_passed := true
var _frame := 0


func _initialize() -> void:
	# The persistent layer, not the Cliff: from round 10 the Fool and Pip live above
	# the region scene, and booting the layer is what puts a region under them
	# (`docs/design/technical.md` §Regions and the persistent layer). Instancing the
	# Cliff by hand also leaks its enemy pool at engine exit on 4.7 (see tests/README.md).
	var packed_scene: PackedScene = load("res://scenes/persistent_layer.tscn")
	root.add_child(packed_scene.instantiate())


func _physics_process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	var ground := root.find_child("Ground", true, false)
	_all_passed = check(ground != null, "Ground node exists") and _all_passed
	if ground == null:
		_finish()
		return true

	_all_passed = check(
		ground.ground_tile_count() >= 300,
		"Meadow tiler placed a full lattice (%d tiles)" % ground.ground_tile_count()
	) and _all_passed

	# A base fill sits under the tile detail so nothing can bleed through a seam.
	var base := ground.get_node_or_null("Base") as Polygon2D
	_all_passed = check(base != null and base.polygon == CliffGroundScript.ISLAND,
		"Base ground layer fills the whole island polygon") and _all_passed
	_all_passed = check(base != null and base.color.a >= 1.0,
		"Base ground layer is opaque") and _all_passed
	# The lattice overshoots the rim, so the base must also clip it back to the island.
	_all_passed = check(base != null and base.clip_children == CanvasItem.CLIP_CHILDREN_AND_DRAW,
		"Base ground layer clips the tile overshoot to the island polygon") and _all_passed

	var samples := 0
	var uncovered_by_tiles := 0
	var uncovered_at_all := 0
	var worst := Vector2.ZERO
	var bounds: Rect2 = CliffGroundScript.island_bounds()
	var y := bounds.position.y
	while y <= bounds.end.y:
		var x := bounds.position.x
		while x <= bounds.end.x:
			var point := Vector2(x, y)
			x += SAMPLE_STEP
			if not Geometry2D.is_point_in_polygon(point, CliffGroundScript.ISLAND):
				continue
			samples += 1
			if not ground.tile_coverage_at(point):
				uncovered_by_tiles += 1
				worst = point
			if not ground.has_ground_at(point):
				uncovered_at_all += 1
		y += SAMPLE_STEP

	_all_passed = check(samples > 4000, "Sampled the island densely (%d points)" % samples) and _all_passed
	_all_passed = check(
		uncovered_by_tiles == 0,
		"Every sampled point inside the island has meadow tile coverage (%d gaps, worst %s)" % [uncovered_by_tiles, worst]
	) and _all_passed
	_all_passed = check(
		uncovered_at_all == 0,
		"Every sampled point inside the island has ground of some kind beneath it (%d gaps)" % uncovered_at_all
	) and _all_passed

	# The rim itself must be covered - that is where the old tiler failed worst.
	var rim_samples := 0
	var rim_gaps := 0
	for edge_index in range(CliffGroundScript.ISLAND.size()):
		var a: Vector2 = CliffGroundScript.ISLAND[edge_index]
		var b: Vector2 = CliffGroundScript.ISLAND[(edge_index + 1) % CliffGroundScript.ISLAND.size()]
		var steps := maxi(2, int(a.distance_to(b) / 25.0))
		for step_index in range(steps):
			var edge_point := a.lerp(b, step_index / float(steps))
			var inward := ((a + b) * 0.5).direction_to(CliffGroundScript.BOWL_CENTRE)
			var point := edge_point + inward * 6.0
			rim_samples += 1
			if not ground.tile_coverage_at(point):
				rim_gaps += 1
	_all_passed = check(rim_gaps == 0, "Island rim is covered right up to the edge (%d/%d gaps)" % [rim_gaps, rim_samples]) and _all_passed

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
		print("GROUND COVERAGE TEST: PASS")
		quit(0)
	else:
		print("GROUND COVERAGE TEST: FAIL")
		quit(1)
