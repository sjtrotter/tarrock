extends Node2D
class_name CliffGround

## Procedural ground for the Cliff.
##
## The island is one authored polygon. Everything else is derived from it:
##   Base       - a flat fill of the polygon. Belt-and-braces so the cloud-sea can
##                never show through a seam.
##   Meadow     - the coverage layer. A brick lattice of meadow blobs, spaced so the
##                art-measured opaque disc of every blob overlaps its neighbours.
##                `tile_coverage_at()` is the queryable form of that guarantee.
##   Path/Worn  - dirt where feet have been.
##   Detail     - zoned overlays: rock toward the rim, flowers in the sheltered
##                bowl, bare earth at the camps and in the dead tree's shade.
##   Rim/Motes  - cliff edge sprites, suspended motes in the air layer.
##
## Terrain composition is zoned, never noise: see `exposure_at`, `shelter_at`,
## `worn_at` and `shade_at`.

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

# --- zones ---------------------------------------------------------------------
# The sheltered bowl holds the campsites; the rim is exposed; the dead tree casts a
# dead patch nothing grows in.
const BOWL_CENTRE := Vector2(2900, 2100)
const BOWL_RADIUS := 980.0
const EXPOSURE_DEPTH := 700.0
const DEAD_TREE_POSITION := Vector2(2250, 1250)
const SHADE_RADIUS := 470.0
## Nothing grows in the dead tree's shade (kept from the first pass).
const GROWTH_SUPPRESSION_RADIUS := 520.0
const CAMPSITES: PackedVector2Array = [
	Vector2(3750, 2500),
	Vector2(2950, 2150),
	Vector2(2600, 1900),
	Vector2(3250, 1800),
]

# --- coverage tiler ------------------------------------------------------------
# The meadow art is an organic blob, not a seamless tile. Each blob's largest fully
# opaque inscribed disc was measured from the alpha channel (radius 114-118 px,
# centred well off the cell centre) - the anchors below move that safe centre onto
# the sprite's origin so rotation and mirroring cannot shift it.
const MEADOW_TILES := [
	{
		"texture": preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-0.png"),
		"anchor": Vector2(-32.0, -20.0),
	},
	{
		"texture": preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-1.png"),
		"anchor": Vector2(-16.0, -28.0),
	},
	{
		"texture": preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-2.png"),
		"anchor": Vector2(9.0, -25.0),
	},
	{
		"texture": preload("res://art/game-ready-sprites-v1/frames/environment/terrain/meadow-3.png"),
		"anchor": Vector2(15.0, -27.0),
	},
]
## Conservative floor of the measured inscribed radii (114 px), minus a safety margin.
const TILE_SAFE_RADIUS := 112.0
## Brick lattice. Covering radius is STRIDE_X / sqrt(3) = 86.6 px; jitter adds at most
## TILE_JITTER * sqrt(2). Both together stay inside TILE_SAFE_RADIUS.
const TILE_STRIDE_X := 150.0
const TILE_STRIDE_Y := 130.0
const TILE_JITTER := 10.0
## The lattice runs past the rim so points on the polygon edge are still covered.
const TILE_OVERSHOOT := 200.0
const TILE_BUCKET := 150.0

const DETAIL_FLOWERS := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-flowers.png")
const DETAIL_STONES := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-stones.png")
const DETAIL_IVY := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-ivy.png")
const DETAIL_EARTH := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/detail-disturbed-earth.png")
const CLIFF_NORTH := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/cliff-north.png")
const CLIFF_EAST := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/cliff-east.png")
const PATH_TEXTURE := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/path-vertical.png")
const PATH_WORN := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/path-horizontal.png")
const PATH_CROSSROADS := preload("res://art/game-ready-sprites-v1/frames/environment/terrain/path-crossroads.png")

# --- tints ---------------------------------------------------------------------
# Multiplied onto the meadow art. Dry and bleached on the exposed rim, deeper green
# in the sheltered bowl, trodden brown along the path, grey and dead under the tree.
const BASE_GROUND_COLOR := Color(0.30, 0.30, 0.17, 1.0)
const TINT_DRY := Color(1.0, 0.94, 0.66)
const TINT_LUSH := Color(0.86, 1.0, 0.80)
const TINT_WORN := Color(0.96, 0.86, 0.68)
const TINT_SHADE := Color(0.62, 0.60, 0.55)

## Motes hang in the air layer, above ground and characters both.
const MOTE_Z_INDEX := 60

var _tile_centres: PackedVector2Array = PackedVector2Array()
var _tile_buckets: Dictionary = {}


func _ready() -> void:
	# The base fill doubles as the clip mask: the tile lattice deliberately overshoots
	# the rim so edge points stay covered, and clipping to the island polygon keeps
	# that overshoot from spilling out over the cloud-sea.
	var base := Polygon2D.new()
	base.name = "Base"
	base.polygon = ISLAND
	base.color = BASE_GROUND_COLOR
	base.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(base)

	var meadow := Node2D.new()
	meadow.name = "Meadow"
	base.add_child(meadow)
	_build_meadow(meadow)

	var path := Node2D.new()
	path.name = "Path"
	base.add_child(path)
	_build_path(path)
	_build_worn_ground(path)

	var detail := Node2D.new()
	detail.name = "Detail"
	base.add_child(detail)
	_build_detail(detail)

	var rim := Node2D.new()
	rim.name = "Rim"
	add_child(rim)
	_build_rim(rim)

	_build_boundary()

	var motes := Node2D.new()
	motes.name = "Motes"
	motes.z_index = MOTE_Z_INDEX
	add_child(motes)
	_build_motes(motes)


static func island_polygon() -> PackedVector2Array:
	return ISLAND


# --- zone queries --------------------------------------------------------------

static func distance_to_island_edge(point: Vector2) -> float:
	var best := INF
	for edge_index in range(ISLAND.size()):
		var a := ISLAND[edge_index]
		var b := ISLAND[(edge_index + 1) % ISLAND.size()]
		best = minf(best, point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)))
	return best


static func distance_to_path(point: Vector2) -> float:
	var best := INF
	for edge_index in range(PATH_POINTS.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(point, PATH_POINTS[edge_index], PATH_POINTS[edge_index + 1])
		best = minf(best, point.distance_to(closest))
	return best


## 1.0 on the wind-scoured rim, 0.0 deep inside.
static func exposure_at(point: Vector2) -> float:
	return clampf(1.0 - distance_to_island_edge(point) / EXPOSURE_DEPTH, 0.0, 1.0)


## 1.0 in the middle of the sheltered bowl, 0.0 outside it.
static func shelter_at(point: Vector2) -> float:
	var bowl := clampf(1.0 - point.distance_to(BOWL_CENTRE) / BOWL_RADIUS, 0.0, 1.0)
	return bowl * (1.0 - exposure_at(point))


## 1.0 directly under the dead tree, 0.0 beyond its shade.
static func shade_at(point: Vector2) -> float:
	var t := clampf(1.0 - point.distance_to(DEAD_TREE_POSITION) / SHADE_RADIUS, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## 1.0 on trodden ground - the path and the campsites - 0.0 where nobody walks.
static func worn_at(point: Vector2) -> float:
	var worn := clampf(1.0 - distance_to_path(point) / 210.0, 0.0, 1.0)
	for campsite in CAMPSITES:
		worn = maxf(worn, clampf(1.0 - point.distance_to(campsite) / 300.0, 0.0, 1.0))
	return worn


## Growing things are suppressed in the dead tree's shade.
static func growth_allowed_at(point: Vector2) -> bool:
	return point.distance_to(DEAD_TREE_POSITION) >= GROWTH_SUPPRESSION_RADIUS


static func ground_tint_at(point: Vector2) -> Color:
	var tint := Color.WHITE
	tint = tint.lerp(TINT_LUSH, shelter_at(point) * 0.55)
	tint = tint.lerp(TINT_DRY, exposure_at(point) * 0.85)
	tint = tint.lerp(TINT_WORN, worn_at(point) * 0.7)
	tint = tint.lerp(TINT_SHADE, shade_at(point))
	return tint


# --- ground coverage -----------------------------------------------------------

## True when the meadow tile layer paints opaque art over this point. This is the
## regression-testable form of "no cloud shows through the island".
func tile_coverage_at(point: Vector2) -> bool:
	var cell := Vector2i(floori(point.x / TILE_BUCKET), floori(point.y / TILE_BUCKET))
	for offset_x in range(-1, 2):
		for offset_y in range(-1, 2):
			var key := Vector2i(cell.x + offset_x, cell.y + offset_y)
			if not _tile_buckets.has(key):
				continue
			for index in _tile_buckets[key]:
				if point.distance_to(_tile_centres[index]) <= TILE_SAFE_RADIUS:
					return true
	return false


## True when anything opaque is under this point - the base fill counts.
func has_ground_at(point: Vector2) -> bool:
	if tile_coverage_at(point):
		return true
	return Geometry2D.is_point_in_polygon(point, ISLAND)


func ground_tile_count() -> int:
	return _tile_centres.size()


func ground_tile_centres() -> PackedVector2Array:
	return _tile_centres


# --- builders ------------------------------------------------------------------

func _build_meadow(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74071
	var bounds := _island_bounds().grow(TILE_OVERSHOOT)
	var row := 0
	var y := bounds.position.y
	while y <= bounds.end.y:
		var row_offset := 0.0 if row % 2 == 0 else TILE_STRIDE_X * 0.5
		var x := bounds.position.x + row_offset
		while x <= bounds.end.x:
			var centre := Vector2(x, y) + Vector2(
				rng.randf_range(-TILE_JITTER, TILE_JITTER),
				rng.randf_range(-TILE_JITTER, TILE_JITTER)
			)
			x += TILE_STRIDE_X
			# Keep any tile whose safe disc can still reach the island.
			if distance_to_island_edge(centre) > TILE_OVERSHOOT and not Geometry2D.is_point_in_polygon(centre, ISLAND):
				continue
			var choice: Dictionary = MEADOW_TILES[rng.randi_range(0, MEADOW_TILES.size() - 1)]
			var sprite := Sprite2D.new()
			sprite.texture = choice["texture"]
			sprite.offset = choice["anchor"]
			sprite.position = centre
			# Rotation and mirroring are about the origin, which the anchor has put on
			# the blob's safe centre - so neither can shrink the coverage disc.
			sprite.rotation = rng.randf_range(0.0, TAU)
			var tile_scale := rng.randf_range(1.0, 1.14)
			sprite.scale = Vector2(-tile_scale if rng.randi_range(0, 1) == 1 else tile_scale, tile_scale)
			sprite.modulate = ground_tint_at(centre)
			parent.add_child(sprite)
			_tile_centres.append(centre)
			_bucket_tile(_tile_centres.size() - 1, centre)
		row += 1
		y += TILE_STRIDE_Y


func _bucket_tile(index: int, centre: Vector2) -> void:
	var key := Vector2i(floori(centre.x / TILE_BUCKET), floori(centre.y / TILE_BUCKET))
	if not _tile_buckets.has(key):
		_tile_buckets[key] = PackedInt32Array()
	var bucket: PackedInt32Array = _tile_buckets[key]
	bucket.append(index)
	_tile_buckets[key] = bucket


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
			sprite.modulate = Color.WHITE.lerp(TINT_DRY, exposure_at(point) * 0.6)
			parent.add_child(sprite)


## Trampled dirt where the camps are, so the path does not read as the only worn ground.
func _build_worn_ground(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74076
	for campsite in CAMPSITES:
		var patches := rng.randi_range(2, 3)
		for index in range(patches):
			var sprite := Sprite2D.new()
			sprite.texture = PATH_CROSSROADS if index == 0 else PATH_WORN
			sprite.position = campsite + Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-110.0, 110.0))
			sprite.rotation = rng.randf_range(0.0, TAU)
			var worn_scale := rng.randf_range(0.7, 1.05)
			sprite.scale = Vector2(worn_scale, worn_scale)
			sprite.modulate = Color(1.0, 0.96, 0.88, 0.85)
			parent.add_child(sprite)


func _build_detail(parent: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 74072
	# Rock and scree gather on the scoured rim; flowers and ivy only in shelter;
	# bare earth where feet have been and where the dead tree has killed the grass.
	_scatter(parent, rng, DETAIL_STONES, 54, 0.45, 0.95, func(point: Vector2) -> float:
		return pow(exposure_at(point), 1.6) * (0.25 if distance_to_path(point) < 130.0 else 1.0))
	_scatter(parent, rng, DETAIL_FLOWERS, 30, 0.45, 0.8, func(point: Vector2) -> float:
		if not growth_allowed_at(point):
			return 0.0
		return shelter_at(point) * (1.0 - worn_at(point)))
	_scatter(parent, rng, DETAIL_IVY, 16, 0.4, 0.75, func(point: Vector2) -> float:
		if not growth_allowed_at(point):
			return 0.0
		return shelter_at(point) * 0.8 * (1.0 - worn_at(point)))
	# Sparingly: this tile has a distinctive dug pit in it, so it reads as repetition
	# fast. A plain bare-earth tile is on the art request list.
	_scatter(parent, rng, DETAIL_EARTH, 13, 0.35, 0.8, func(point: Vector2) -> float:
		return maxf(shade_at(point) * 0.7, worn_at(point) * 0.5))


func _scatter(
	parent: Node2D,
	rng: RandomNumberGenerator,
	texture: Texture2D,
	count: int,
	min_scale: float,
	max_scale: float,
	weight: Callable
) -> void:
	var bounds := _island_bounds()
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 400:
		attempts += 1
		var point := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		if not Geometry2D.is_point_in_polygon(point, ISLAND):
			continue
		if rng.randf() > float(weight.call(point)):
			continue
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = point
		sprite.rotation = rng.randf_range(0.0, TAU)
		var detail_scale := rng.randf_range(min_scale, max_scale)
		sprite.scale = Vector2(detail_scale, detail_scale)
		sprite.modulate = ground_tint_at(point)
		parent.add_child(sprite)
		placed += 1


func _build_rim(parent: Node2D) -> void:
	for edge_index in range(ISLAND.size()):
		var a := ISLAND[edge_index]
		var b := ISLAND[(edge_index + 1) % ISLAND.size()]
		var edge := b - a
		var normal := edge.normalized().orthogonal()
		var midpoint := (a + b) * 0.5
		if Geometry2D.is_point_in_polygon(midpoint + normal * 8.0, ISLAND):
			normal = -normal
		# Tighter than the 320 px tile width so neighbouring rim sprites overlap and
		# the clipped ground edge never shows between them.
		var steps := maxi(1, ceili(edge.length() / 160.0))
		for step_index in range(steps):
			var sprite := Sprite2D.new()
			sprite.position = a.lerp(b, (step_index + 0.5) / float(steps))
			# TODO(art): only north- and east-facing rim tiles exist; south and west
			# reuse them. Proper facings are on godot/art/ART-REQUESTS.md.
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
		# A diamond rather than a square: motes are specks of light, not pixels.
		var size := rng.randf_range(2.4, 4.6)
		mote.polygon = PackedVector2Array([
			Vector2(0.0, -size), Vector2(size * 0.7, 0.0), Vector2(0.0, size), Vector2(-size * 0.7, 0.0)
		])
		mote.color = Color(1.0, 0.97, 0.88, rng.randf_range(0.22, 0.38))
		mote.position = point
		parent.add_child(mote)
		placed += 1


func _island_bounds() -> Rect2:
	return island_bounds()


static func island_bounds() -> Rect2:
	var bounds := Rect2(ISLAND[0], Vector2.ZERO)
	for point in ISLAND:
		bounds = bounds.expand(point)
	return bounds
