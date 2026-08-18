extends Node2D
class_name GrassField

## Tall grass with touch displacement.
##
## Canon (docs/design/art-audio.md, "The world-state is the art direction"):
## a bound region holds its breath - nothing animates on a clock - but it still
## yields to touch. So every tuft sits in a STATIC wind-combed lean (the pose the
## last wind left, stronger on exposed ground than in shelter) and only moves when
## the Fool or Pip walks into it: it parts away from the passing body in proportion
## to how close the body is, then returns to its rest pose. The lean is a pure
## function of body position each physics frame; with nobody near, the field is a
## still image.

const TUFT_TEXTURES := [
	preload("res://art/derived-placeholder/tall-grass-tuft-0.png"),
	preload("res://art/derived-placeholder/tall-grass-tuft-1.png"),
	preload("res://art/derived-placeholder/tall-grass-tuft-2.png"),
]
## The tuft art is 192x256 with its root at (96, 250): this offset puts the root on
## the node origin so rotation pivots at the base of the blades.
const TUFT_ANCHOR := Vector2(0.0, -122.0)

## Wind-combed rest pose. Positive rotation leans the blades toward +x; the last
## wind over the Cliff came off the north-west shoulder.
const REST_LEAN := 0.26
const REST_LEAN_EXPOSED := 0.44
const REST_LEAN_VARIANCE := 0.06

## Displacement response.
const INFLUENCE_RADIUS := 200.0
const MAX_DISPLACEMENT_LEAN := 0.85
const EASE_RATE := 11.0
## Below this the tuft is snapped to its rest pose, so a settled field is exactly static.
const REST_EPSILON := 0.0015

## Authored swatches - the sheltered bowl and one pocket under the standing stones.
const SWATCHES := [
	{"centre": Vector2(2750, 2350), "radius": 340.0, "count": 34},
	{"centre": Vector2(3150, 1980), "radius": 300.0, "count": 26},
	{"centre": Vector2(2480, 2620), "radius": 270.0, "count": 20},
	{"centre": Vector2(1720, 1600), "radius": 320.0, "count": 24},
	{"centre": Vector2(3520, 2210), "radius": 280.0, "count": 20},
]
## Fringes either side of the path, never on it.
const PATH_FRINGE_COUNT := 46
const PATH_FRINGE_MIN := 105.0
const PATH_FRINGE_MAX := 215.0

const MIN_RIM_DISTANCE := 260.0
const MIN_PATH_DISTANCE := 95.0
const MIN_CAMP_DISTANCE := 230.0

## Bodies to part for, as paths relative to this node. Left over from when the Fool
## and Pip were children of the region scene; from round 10 they live in the
## persistent layer above it, so the region's own script hands them over instead
## (`set_bodies()`). Kept for a scene that stands its own bodies beside the field.
@export var body_paths: Array[NodePath] = []

var _tufts: Array[Sprite2D] = []
var _rest_leans: PackedFloat32Array = PackedFloat32Array()
var _leans: PackedFloat32Array = PackedFloat32Array()
var _bodies: Array[Node2D] = []


func _ready() -> void:
	y_sort_enabled = true
	for path in body_paths:
		var body := get_node_or_null(path) as Node2D
		if body != null:
			_bodies.append(body)
	_build_field()


func _physics_process(delta: float) -> void:
	step_displacement(delta)


## Tell the field who walks through it. Replaces whatever it found for itself.
##
## The region scene calls this: the Fool and Pip are the persistent layer's, and a
## field of grass has no business reaching up out of its own scene to find them
## (`docs/design/technical.md` §Architecture principles (Godot), 5).
func set_bodies(bodies: Array[Node2D]) -> void:
	_bodies.clear()
	for body: Node2D in bodies:
		if body != null and is_instance_valid(body):
			_bodies.append(body)


# --- queryable state (used by tests) -------------------------------------------

func tuft_count() -> int:
	return _tufts.size()


func tuft_position(index: int) -> Vector2:
	return _tufts[index].global_position


func tuft_lean(index: int) -> float:
	return _leans[index]


func tuft_rest_lean(index: int) -> float:
	return _rest_leans[index]


## Index of the tuft nearest a world point, or -1 when the field is empty.
func nearest_tuft(point: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for index in range(_tufts.size()):
		var distance := _tufts[index].global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


# --- displacement --------------------------------------------------------------

func step_displacement(delta: float) -> void:
	if _tufts.is_empty():
		return
	var weight := 1.0 - exp(-EASE_RATE * maxf(delta, 0.0))
	for index in range(_tufts.size()):
		var tuft := _tufts[index]
		var rest := _rest_leans[index]
		var target := rest
		for body in _bodies:
			if not is_instance_valid(body):
				continue
			var to_tuft := tuft.global_position - body.global_position
			var distance := to_tuft.length()
			if distance >= INFLUENCE_RADIUS:
				continue
			# Smoothstep, not linear: the response dies away smoothly at the edge of
			# the radius (no popping as a body walks in) but still bites at mid range.
			var push := 1.0 - distance / INFLUENCE_RADIUS
			push = push * push * (3.0 - 2.0 * push)
			# Lean away from the body. The horizontal ramp keeps the direction from
			# snapping when a body passes directly above or below the tuft.
			var away := clampf(to_tuft.x / 60.0, -1.0, 1.0)
			target += away * MAX_DISPLACEMENT_LEAN * push
		var lean: float = _leans[index]
		if is_equal_approx(lean, target):
			continue
		lean = lean + (target - lean) * weight
		if absf(lean - target) < REST_EPSILON:
			lean = target
		_leans[index] = lean
		tuft.rotation = lean


# --- placement -----------------------------------------------------------------

func _build_field() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74077
	for swatch: Dictionary in SWATCHES:
		var placed := 0
		var attempts := 0
		while placed < int(swatch["count"]) and attempts < 400:
			attempts += 1
			var angle := rng.randf_range(0.0, TAU)
			var radius: float = float(swatch["radius"]) * sqrt(rng.randf())
			var point: Vector2 = Vector2(swatch["centre"]) + Vector2(cos(angle), sin(angle)) * radius
			if not _accepts(point):
				continue
			_add_tuft(rng, point)
			placed += 1

	var placed_fringe := 0
	var fringe_attempts := 0
	while placed_fringe < PATH_FRINGE_COUNT and fringe_attempts < 900:
		fringe_attempts += 1
		var edge_index := rng.randi_range(0, CliffGround.PATH_POINTS.size() - 2)
		var a := CliffGround.PATH_POINTS[edge_index]
		var b := CliffGround.PATH_POINTS[edge_index + 1]
		var along := a.lerp(b, rng.randf())
		var side := 1.0 if rng.randi_range(0, 1) == 1 else -1.0
		var normal := (b - a).normalized().orthogonal()
		var point := along + normal * side * rng.randf_range(PATH_FRINGE_MIN, PATH_FRINGE_MAX)
		if not _accepts(point):
			continue
		_add_tuft(rng, point)
		placed_fringe += 1


func _accepts(point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point, CliffGround.ISLAND):
		return false
	if CliffGround.distance_to_island_edge(point) < MIN_RIM_DISTANCE:
		return false
	if CliffGround.distance_to_path(point) < MIN_PATH_DISTANCE:
		return false
	if not CliffGround.growth_allowed_at(point):
		return false
	for campsite in CliffGround.CAMPSITES:
		if point.distance_to(campsite) < MIN_CAMP_DISTANCE:
			return false
	return true


func _add_tuft(rng: RandomNumberGenerator, point: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = TUFT_TEXTURES[rng.randi_range(0, TUFT_TEXTURES.size() - 1)]
	sprite.offset = TUFT_ANCHOR
	sprite.position = point
	# Squashed slightly on y: the ground is painted in three-quarter view, so anything
	# standing up out of it is foreshortened.
	var tuft_scale := rng.randf_range(0.25, 0.35)
	sprite.scale = Vector2(-tuft_scale if rng.randi_range(0, 1) == 1 else tuft_scale, tuft_scale * 0.9)
	# The placeholder blades are painted brighter than the meadow art; knock them
	# back so they sit in the ground rather than on top of it.
	sprite.modulate = CliffGround.ground_tint_at(point) * Color(0.84, 0.89, 0.76)
	# Wind-combed: a static lean, stronger where the ground is exposed.
	var exposure := CliffGround.exposure_at(point)
	var rest: float = lerpf(REST_LEAN, REST_LEAN_EXPOSED, exposure) + rng.randf_range(-REST_LEAN_VARIANCE, REST_LEAN_VARIANCE)
	sprite.rotation = rest
	add_child(sprite)
	_tufts.append(sprite)
	_rest_leans.append(rest)
	_leans.append(rest)
