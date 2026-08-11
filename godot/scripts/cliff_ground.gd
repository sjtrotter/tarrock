extends Node2D

const ISLAND: PackedVector2Array = [
	Vector2(700, 900),
	Vector2(1000, 675),
	Vector2(1200, 525),
	Vector2(1500, 300),
	Vector2(2200, 260),
	Vector2(2900, 340),
	Vector2(3500, 560),
	Vector2(4050, 900),
	Vector2(4400, 1350),
	Vector2(4480, 1900),
	Vector2(4300, 2400),
	Vector2(3900, 2800),
	Vector2(3300, 3060),
	Vector2(2600, 3140),
	Vector2(1900, 3050),
	Vector2(1300, 2800),
	Vector2(850, 2400),
	Vector2(620, 1850),
	Vector2(600, 1350),
]

const LEAP_GAP_EDGE := 1
const LEAP_POINT := Vector2(1150, 650)

const PATH_POINTS: PackedVector2Array = [
	Vector2(3820, 2560),
	Vector2(3400, 2300),
	Vector2(2950, 2150),
	Vector2(2600, 1900),
	Vector2(2400, 1700),
	Vector2(2050, 1450),
	Vector2(1655, 1240),
	Vector2(1430, 1000),
	Vector2(1150, 650),
]

const MEADOW_TEXTURES := [
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-3.png"),
]
const DETAIL_TEXTURES := [
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-flowers.png"),
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-stones.png"),
	preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-ivy.png"),
]
const CLIFF_NORTH := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/cliff-north.png")
const CLIFF_EAST := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/cliff-east.png")
const PATH_TEXTURE := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/path-vertical.png")
const DEAD_TREE_POSITION := Vector2(2250, 1250)


func _ready() -> void:
	var meadow := Node2D.new()
	meadow.name = "Meadow"
	add_child(meadow)
	_build_meadow(meadow)

	var path := Node2D.new()
	path.name = "Path"
	add_child(path)
	_build_path(path)

	var detail := Node2D.new()
	detail.name = "Detail"
	add_child(detail)
	_build_detail(detail)

	var rim := Node2D.new()
	rim.name = "Rim"
	add_child(rim)
	_build_rim(rim)

	_build_boundary()

	var motes := Node2D.new()
	motes.name = "Motes"
	add_child(motes)
	_build_motes(motes)


static func island_polygon() -> PackedVector2Array:
	return ISLAND


func _build_meadow(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74071
	var bounds := _island_bounds()
	var start_x := floori(bounds.position.x / 256.0) * 256
	var start_y := floori(bounds.position.y / 256.0) * 256
	var end_x := ceili(bounds.end.x / 256.0) * 256
	var end_y := ceili(bounds.end.y / 256.0) * 256
	for y in range(start_y, end_y, 256):
		for x in range(start_x, end_x, 256):
			var cell_center := Vector2(x + 128, y + 128)
			if not Geometry2D.is_point_in_polygon(cell_center, ISLAND):
				continue
			var sprite := Sprite2D.new()
			sprite.texture = MEADOW_TEXTURES[rng.randi_range(0, 3)]
			sprite.position = cell_center + Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-18.0, 18.0))
			sprite.flip_h = rng.randi_range(0, 1) == 1
			sprite.scale = Vector2.ONE
			parent.add_child(sprite)


func _build_detail(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74072
	var bounds := _island_bounds()
	var placed := 0
	while placed < 26:
		var point := Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
		if not Geometry2D.is_point_in_polygon(point, ISLAND) or point.distance_to(DEAD_TREE_POSITION) < 520.0:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = DETAIL_TEXTURES[rng.randi_range(0, 2)]
		sprite.position = point
		var detail_scale := rng.randf_range(0.5, 0.8)
		sprite.scale = Vector2(detail_scale, detail_scale)
		sprite.flip_h = rng.randi_range(0, 1) == 1
		parent.add_child(sprite)
		placed += 1


func _build_path(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74073
	for edge_index in range(PATH_POINTS.size() - 1):
		var a := PATH_POINTS[edge_index]
		var b := PATH_POINTS[edge_index + 1]
		var heading := b - a
		var steps := maxi(1, ceili(heading.length() / 150.0))
		for step_index in range(steps):
			var point := a.lerp(b, (step_index + 0.5) / float(steps))
			var sprite := Sprite2D.new()
			sprite.texture = PATH_TEXTURE
			sprite.position = point
			sprite.rotation = heading.angle() - PI / 2.0
			var path_scale := rng.randf_range(0.80, 1.15)
			if point.distance_to(Vector2(1655, 1240)) < 220.0:
				path_scale = 0.8
			sprite.scale = Vector2(path_scale, path_scale)
			parent.add_child(sprite)


func _build_rim(parent: Node2D) -> void:
	for edge_index in range(ISLAND.size()):
		var a := ISLAND[edge_index]
		var b := ISLAND[(edge_index + 1) % ISLAND.size()]
		var edge := b - a
		var normal := edge.normalized().orthogonal()
		var midpoint := (a + b) * 0.5
		if Geometry2D.is_point_in_polygon(midpoint + normal * 8.0, ISLAND):
			normal = -normal
		var steps := maxi(1, ceili(edge.length() / 200.0))
		for step_index in range(steps):
			var sprite := Sprite2D.new()
			sprite.position = a.lerp(b, (step_index + 0.5) / float(steps))
			if absf(normal.y) >= absf(normal.x):
				sprite.texture = CLIFF_NORTH
			else:
				sprite.texture = CLIFF_EAST
				sprite.flip_h = normal.x < 0.0
			parent.add_child(sprite)


func _build_boundary() -> void:
	var boundary := StaticBody2D.new()
	boundary.name = "IslandBoundary"
	add_child(boundary)
	for edge_index in range(ISLAND.size()):
		if edge_index == LEAP_GAP_EDGE:
			continue
		var a := ISLAND[edge_index]
		var b := ISLAND[(edge_index + 1) % ISLAND.size()]
		var edge := b - a
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(edge.length(), 48.0)
		var collision := CollisionShape2D.new()
		collision.name = "Edge%d" % edge_index
		collision.shape = rectangle
		collision.position = (a + b) * 0.5
		collision.rotation = edge.angle()
		boundary.add_child(collision)


func _build_motes(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74074
	var bounds := _island_bounds()
	var placed := 0
	while placed < 60:
		var point := Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
		if not Geometry2D.is_point_in_polygon(point, ISLAND):
			continue
		var mote := Polygon2D.new()
		mote.polygon = PackedVector2Array([Vector2(-2.5, -2.5), Vector2(2.5, -2.5), Vector2(2.5, 2.5), Vector2(-2.5, 2.5)])
		mote.color = Color(1.0, 0.97, 0.88, 0.28)
		mote.position = point
		parent.add_child(mote)
		placed += 1


func _island_bounds() -> Rect2:
	var bounds := Rect2(ISLAND[0], Vector2.ZERO)
	for point in ISLAND:
		bounds = bounds.expand(point)
	return bounds
