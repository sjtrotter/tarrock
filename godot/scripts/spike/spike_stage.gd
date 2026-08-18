extends Node2D
class_name SpikeStage

## The comparison bench for the animation spike.
##
## One stage holds N panels; a panel is a captioned patch of scrolling ground
## with one walker standing on it. The walker never translates - the GROUND
## moves under him at the walker's own stride-matched speed. That is deliberate:
##
##   * a treadmill loops perfectly, so a 2.5 s GIF is a clean loop;
##   * foot skate becomes measurable rather than a feeling, because the ground
##     carries tick marks and you can watch whether a planted boot holds one.
##
## Everything is scrubbed, never free-run: `scrub(t)` poses every panel at an
## exact time, so a 30 fps capture is exactly 30 fps whatever the window did.

const RigScript := preload("res://scripts/spike/fool_cutout_rig.gd")
const PaintedScript := preload("res://scripts/spike/painted_walk.gd")
const SouthRigScript := preload("res://scripts/spike/fool_cutout_rig_south.gd")

const BG_TOP := Color(0.30, 0.35, 0.32)
const BG_BOTTOM := Color(0.17, 0.21, 0.19)
const GROUND := Color(0.29, 0.26, 0.20)
const GROUND_EDGE := Color(0.40, 0.36, 0.26)
const TICK := Color(0.52, 0.47, 0.34)
const CAPTION := Color(0.92, 0.90, 0.84)

## Ground tick spacing as a fraction of one cycle's travel, so the ticks loop
## with the gait: six ticks per cycle, one every third of a step.
const TICKS_PER_CYCLE := 6

## The layouts the capture harness can ask for.
## Each entry: [caption, kind, figure_height, posterize_levels, clip, extras]
## `extras` (optional) reproduces the shipping defects for a before/after:
##   uniform_fps - flat frame timing instead of held contacts (today: 8)
##   speed       - forced travel speed instead of stride-matched (today: 200)
const LAYOUTS := {
	"rig_walk": [["cutout rig - east walk", "rig", 244.0, 0, "walk"]],
	"rig_south_walk": [["cutout rig - SOUTH walk (the hard facing)", "south", 244.0, 0, "walk"]],
	"rig_south_idle": [["cutout rig - south idle", "south", 244.0, 0, "idle"]],
	"rig_south_gamesize": [["cutout rig - south walk (game size)", "south", 122.0, 0, "walk"]],
	"facings": [
		["east profile - bones do the work", "rig", 200.0, 0, "walk"],
		["south - bob, depth slide, swapped feet", "south", 200.0, 0, "walk"],
	],
	"rig_idle": [["cutout rig - idle", "rig", 244.0, 0, "idle"]],
	"rig_walk_gamesize": [["cutout rig - walk (game size)", "rig", 122.0, 0, "walk"]],
	"painted_100": [["painted 4-frame - 122 px (100%)", "painted", 122.0, 0, "walk"]],
	"painted_60": [["painted 4-frame - 73 px (60%)", "painted", 73.0, 0, "walk"]],
	"painted_40": [["painted 4-frame - 49 px (40%)", "painted", 49.0, 0, "walk"]],
	"painted_40_post": [["painted 4-frame - 49 px, 6-level palette", "painted", 49.0, 6, "walk"]],
	"compare": [
		["A - Skeleton2D cutout rig", "rig", 244.0, 0, "walk"],
		["B - painted frames, timing fixed", "painted", 244.0, 0, "walk"],
	],
	"compare_gamesize": [
		["A - cutout rig", "rig", 122.0, 0, "walk"],
		["B - painted, timing fixed", "painted", 122.0, 0, "walk"],
	],
	"shipping": [[
		"shipping today - 8 fps flat, 200 px/s", "painted", 122.0, 0, "walk",
		{"uniform_fps": 8.0, "speed": 200.0},
	]],
	"three_way": [
		[
			"today: flat 8 fps, 200 px/s", "painted", 122.0, 0, "walk",
			{"uniform_fps": 8.0, "speed": 200.0},
		],
		["B: same art, timing + speed fixed", "painted", 122.0, 0, "walk"],
		["A: Skeleton2D cutout rig", "rig", 122.0, 0, "walk"],
	],
	"three_way_big": [
		[
			"today: flat 8 fps, 200 px/s", "painted", 200.0, 0, "walk",
			{"uniform_fps": 8.0, "speed": 328.0},
		],
		["B: same art, timing + speed fixed", "painted", 200.0, 0, "walk"],
		["A: Skeleton2D cutout rig", "rig", 200.0, 0, "walk"],
	],
	"fidelity": [
		["100% - 122 px", "painted", 122.0, 0, "walk"],
		["60% - 73 px", "painted", 73.0, 0, "walk"],
		["40% - 49 px", "painted", 49.0, 0, "walk"],
		["40% + 6-level palette", "painted", 49.0, 6, "walk"],
	],
}

var _panels: Array = []
var _layout := ""
var _time := 0.0
var _live := false


func _ready() -> void:
	# The window has no size during the first frame of a `--script` run, which
	# would lay every panel out into a zero-width strip. Re-lay out whenever the
	# viewport reports a real size.
	get_viewport().size_changed.connect(_on_viewport_resized)
	if _layout == "":
		configure("compare")
	# Opened by hand (godot --path godot scenes/spike/anim_spike.tscn) the stage
	# should just play. The capture harness turns this off and scrubs instead.
	set_live(true)


func _on_viewport_resized() -> void:
	if _layout != "":
		configure(_layout)


func configure(layout_name: String) -> void:
	assert(LAYOUTS.has(layout_name), "unknown spike layout: " + layout_name)
	for panel: Dictionary in _panels:
		# The caption is a sibling of the panel root, not a child of it: free
		# both, or every layout after the first captures with ghost labels
		# stacked on top of it.
		for node: Variant in [panel["root"], panel["label"]]:
			remove_child(node as Node)
			(node as Node).queue_free()
	_panels.clear()
	_layout = layout_name

	var specs: Array = LAYOUTS[layout_name]
	var viewport := get_viewport_rect().size
	# Panels are only as wide as the figure needs, then centred as a group, so
	# every capture crops tight with no dead space.
	var widths: Array[float] = []
	var total := 0.0
	for spec: Variant in specs:
		var w: float = clampf(float(spec[2]) * 3.4, 170.0, viewport.x / float(specs.size()))
		widths.append(w)
		total += w
	var x := (viewport.x - total) * 0.5
	for index in specs.size():
		_panels.append(_make_panel(specs[index], index, x, widths[index], viewport.y))
		x += widths[index]
	queue_redraw()
	scrub(_time)


func _make_panel(spec: Array, index: int, x0: float, width: float, height: float) -> Dictionary:
	var caption: String = spec[0]
	var kind: String = spec[1]
	var figure_height: float = spec[2]
	var posterize: int = spec[3]
	var clip: String = spec[4]
	var extras: Dictionary = spec[5] if spec.size() > 5 else {}
	var ground_y: float = height * 0.82

	var root := Node2D.new()
	root.name = "Panel%d" % index
	root.position = Vector2(x0 + width * 0.5, ground_y)
	add_child(root)

	var walker: Node2D
	var speed := 0.0
	var cycle := _cycle_for(kind, clip)
	if kind == "rig" or kind == "south":
		var s := figure_height / FoolCutoutRig.FIGURE_HEIGHT_PX
		var rig: Node2D = SouthRigScript.new() if kind == "south" else RigScript.new()
		rig.scale = Vector2(s, s)
		root.add_child(rig)
		rig.call("build")
		# An idling Fool is not going anywhere: the ground holds still.
		speed = 0.0 if clip == "idle" else FoolCutoutRig.walk_speed_px() * s
		walker = rig
	else:
		var painted: PaintedWalk = PaintedScript.new()
		painted.figure_height = figure_height
		painted.posterize_levels = posterize
		painted.uniform_fps = float(extras.get("uniform_fps", 0.0))
		painted.speed_override = float(extras.get("speed", 0.0))
		root.add_child(painted)
		painted.build()
		speed = painted.speed_px()
		cycle = painted.cycle()
		walker = painted

	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", CAPTION)
	label.size = Vector2(width - 12.0, 22.0)
	label.position = Vector2(x0 + 6.0, ground_y - figure_height - 50.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(label)

	return {
		"root": root,
		"label": label,
		"walker": walker,
		"kind": kind,
		"clip": clip,
		"speed": speed,
		"cycle": cycle,
		"x": x0,
		"width": width,
		"ground_y": ground_y,
		"figure_height": figure_height,
		# A south walker comes towards the camera, so his treadmill runs down
		# the screen and the whole panel is floor.
		"axis": "south" if kind == "south" else "east",
	}


static func _cycle_for(kind: String, clip: String) -> float:
	if kind == "painted":
		return PaintedWalk.CYCLE
	return FoolCutoutRig.IDLE_CYCLE if clip == "idle" else FoolCutoutRig.WALK_CYCLE


## The tight rectangle the capture harness should crop to.
func capture_rect() -> Rect2i:
	if _panels.is_empty():
		return Rect2i(Vector2i.ZERO, get_viewport_rect().size)
	var left := INF
	var right := -INF
	var top := INF
	var bottom := -INF
	for panel: Dictionary in _panels:
		left = minf(left, float(panel["x"]))
		right = maxf(right, float(panel["x"]) + float(panel["width"]))
		top = minf(top, float(panel["ground_y"]) - float(panel["figure_height"]) - 58.0)
		bottom = maxf(bottom, float(panel["ground_y"]) + 46.0)
	var viewport := get_viewport_rect().size
	left = maxf(left, 0.0)
	top = maxf(top, 0.0)
	right = minf(right, viewport.x)
	bottom = minf(bottom, viewport.y)
	return Rect2i(
		Vector2i(int(left), int(top)),
		Vector2i(int(right - left), int(bottom - top))
	)


## Pose every panel at absolute time `t`.
func scrub(t: float) -> void:
	_time = t
	for panel: Dictionary in _panels:
		if panel["kind"] == "painted":
			(panel["walker"] as PaintedWalk).scrub(t)
		else:
			(panel["walker"] as Node2D).call("scrub", panel["clip"], t)
	queue_redraw()


func set_live(value: bool) -> void:
	_live = value
	set_process(value)


func _process(delta: float) -> void:
	if _live:
		scrub(_time + delta)


func panels() -> Array:
	return _panels


func layout_name() -> String:
	return _layout


func _draw() -> void:
	var viewport := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport), BG_BOTTOM)
	draw_rect(Rect2(Vector2.ZERO, Vector2(viewport.x, viewport.y * 0.55)), BG_TOP)
	for panel: Dictionary in _panels:
		_draw_panel(panel)


func _draw_panel(panel: Dictionary) -> void:
	var x0: float = panel["x"]
	var width: float = panel["width"]
	var ground_y: float = panel["ground_y"]
	var viewport := get_viewport_rect().size
	var south: bool = str(panel["axis"]) == "south"

	var floor_top: float = (
		ground_y - float(panel["figure_height"]) * 0.62 if south else ground_y
	)
	draw_rect(Rect2(Vector2(x0, floor_top), Vector2(width, viewport.y - floor_top)), GROUND)
	draw_line(Vector2(x0, floor_top), Vector2(x0 + width, floor_top), GROUND_EDGE, 2.0)
	if x0 > 0.5:
		draw_line(Vector2(x0, 0.0), Vector2(x0, viewport.y), Color(0, 0, 0, 0.5), 2.0)

	# Ticks stapled to the ground, scrolling at the walker's own speed. A boot
	# that stays on one tick through its stance phase is not skating.
	var speed: float = float(panel["speed"])
	# One tick per sixth of a cycle's travel, so the ticks loop with the gait.
	# A standing figure still gets a ruled ground, just a stationary one.
	var spacing: float = (
		speed * float(panel["cycle"]) / float(TICKS_PER_CYCLE)
		if speed > 0.0
		else float(panel["figure_height"]) * 0.25
	)
	if spacing < 2.0:
		return
	var travelled: float = speed * _time
	var tick_height: float = clampf(float(panel["figure_height"]) * 0.09, 4.0, 22.0)
	# Index ticks by ground position, not screen position, or the "start of
	# cycle" tall tick hops between marks as the ground scrolls.
	if south:
		# Floor lines running across, scrolling towards the viewer.
		var span := viewport.y - floor_top
		var first_row := int(floor(travelled / spacing))
		var last_row := int(ceil((travelled + span) / spacing))
		for k in range(first_row, last_row + 1):
			var y := floor_top + float(k) * spacing - travelled
			if y < floor_top or y > viewport.y:
				continue
			var strong := posmod(k, TICKS_PER_CYCLE) == 0
			draw_line(
				Vector2(x0, y),
				Vector2(x0 + width, y),
				TICK,
				2.0 if strong else 1.0
			)
		return

	var first := int(floor(travelled / spacing))
	var last := int(ceil((travelled + width) / spacing))
	for k in range(first, last + 1):
		var x := x0 + float(k) * spacing - travelled
		if x < x0 or x > x0 + width:
			continue
		var tall := posmod(k, TICKS_PER_CYCLE) == 0
		draw_line(
			Vector2(x, ground_y),
			Vector2(x, ground_y + (tick_height * (2.0 if tall else 1.0))),
			TICK,
			2.0
		)
