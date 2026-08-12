extends Node2D
class_name SteppedWalkStage

## SPIKE C: the stepped-pose comparison bench.
##
## The director finds the rig's continuous interpolation "too mechanical" and
## wants to see whether killing the tweening kills that read. Unlike
## spike_stage.gd's treadmill (the walker holds still, the GROUND scrolls
## under him - great for measuring foot skate, useless for judging THIS
## question), every panel here has its walker actually translate across the
## screen at the game's own walk speed. That is the point under test: a
## stepped POSE with the BODY still gliding continuously is the Gunstar
## Heroes look (pose-stepping over continuous motion); freeze both together
## and you can no longer tell whether it is the pose or the slide that reads
## as mechanical.
##
## Panels loop with a hard cut - the walker resets from the right edge of its
## track back to the left. That is a deliberate simplification for a taste-
## test: CYCLES_PER_PANEL is a whole number of gait cycles, so the POSE never
## hitches at the seam, only the on-screen position does, once per loop. A
## seamless infinite treadmill-of-bodies is more machinery than a five-minute
## verdict needs.
##
## Poses are held via scripts/spike/pose_stepper.gd. `steps == 0` means
## smooth/continuous - the control.

const RigScript := preload("res://scripts/spike/fool_cutout_rig.gd")
const PoseStepperScript := preload("res://scripts/spike/pose_stepper.gd")

const BG_TOP := Color(0.30, 0.35, 0.32)
const BG_BOTTOM := Color(0.17, 0.21, 0.19)
const GROUND := Color(0.29, 0.26, 0.20)
const GROUND_EDGE := Color(0.40, 0.36, 0.26)
const TICK := Color(0.52, 0.47, 0.34)
const CAPTION := Color(0.92, 0.90, 0.84)

## Per-part random offset for the jitter mode, in native... no - in the
## SCREEN pixels of the drawn art (post figure-height scale), so "+-1px" means
## what it says at whatever size the panel renders.
const JITTER_PX := 1.0
const PANEL_MARGIN := 24.0

## mode key -> [caption, steps (0 = smooth/continuous), jitter?]
const MODES := {
	"smooth": ["SMOOTH (control)", 0, false],
	"stepped_12": ["STEPPED-12", 12, false],
	"stepped_8": ["STEPPED-8", 8, false],
	"stepped_6": ["STEPPED-6", 6, false],
	"stepped_8_jitter": ["STEPPED-8 + JITTER", 8, true],
}
const COMPARE_ORDER := ["smooth", "stepped_12", "stepped_8", "stepped_6", "stepped_8_jitter"]

## layout name -> {modes, figure_height, cycles}. "compare"/"compare_2x" are
## the five-up strips; the rest are single-panel layouts for the individual
## GIFs. `cycles` is whole gait cycles per loop (0.6 s/cycle * 25 fps = 15
## frames/cycle exactly, so any whole `cycles` closes with no rounding
## anywhere in the capture harness) - it is tuned DOWN for the five-up strips
## because the project's canvas_items stretch mode fixes the logical canvas
## at 1280x720 regardless of window resolution (see capture_stepped.gd's
## header), and five panels of open-ended walking room has to fit in it. A
## single-panel layout has the whole canvas to itself, so it gets more cycles
## - a longer, more comfortable loop - for the same reason.
const LAYOUTS := {
	"compare": {"modes": COMPARE_ORDER, "figure_height": 122.0, "cycles": 2},
	"compare_2x": {"modes": COMPARE_ORDER, "figure_height": 244.0, "cycles": 1},
	"smooth": {"modes": ["smooth"], "figure_height": 122.0, "cycles": 4},
	"stepped_12": {"modes": ["stepped_12"], "figure_height": 122.0, "cycles": 4},
	"stepped_8": {"modes": ["stepped_8"], "figure_height": 122.0, "cycles": 4},
	"stepped_6": {"modes": ["stepped_6"], "figure_height": 122.0, "cycles": 4},
	"stepped_8_jitter": {"modes": ["stepped_8_jitter"], "figure_height": 122.0, "cycles": 4},
}

var _panels: Array = []
var _layout := ""
var _time := 0.0
var _live := false


func _ready() -> void:
	# The window has no size on frame one of a `--script` run, which would lay
	# every panel into a zero-width strip.
	get_viewport().size_changed.connect(_on_viewport_resized)
	if _layout == "":
		configure("compare")
	set_live(true)


func _on_viewport_resized() -> void:
	if _layout != "":
		configure(_layout)


func configure(layout_name: String) -> void:
	assert(LAYOUTS.has(layout_name), "unknown stepped-walk layout: " + layout_name)
	for panel in _panels:
		for node in [panel["root"], panel["label"]]:
			remove_child(node as Node)
			(node as Node).queue_free()
	_panels.clear()
	_layout = layout_name

	var config: Dictionary = LAYOUTS[layout_name]
	var modes: Array = config["modes"]
	var figure_height: float = config["figure_height"]
	var cycles: int = config["cycles"]

	# Every panel in a layout shares figure_height, so they share speed and
	# travel too - compute the one panel width the whole row needs.
	var s := figure_height / FoolCutoutRig.FIGURE_HEIGHT_PX
	var speed := FoolCutoutRig.walk_speed_px() * s
	var duration := FoolCutoutRig.WALK_CYCLE * float(cycles)
	var travel := speed * duration
	var panel_width := travel + PANEL_MARGIN * 2.0

	var viewport := get_viewport_rect().size
	var total := panel_width * modes.size()
	var x := (viewport.x - total) * 0.5
	for index in modes.size():
		_panels.append(
			_make_panel(
				String(modes[index]), index, x, panel_width, viewport.y, figure_height, speed, cycles
			)
		)
		x += panel_width
	queue_redraw()
	scrub(_time)


## Seconds for one loop of the current layout - what the capture harness
## multiplies by its own FPS to get a frame count. Ownership split matches
## tools/spike/capture_spike.gd's: FPS lives in the capture tool, not here.
func layout_duration() -> float:
	assert(LAYOUTS.has(_layout), "layout_duration() called before configure()")
	return FoolCutoutRig.WALK_CYCLE * float(LAYOUTS[_layout]["cycles"])


func _make_panel(
	mode: String, index: int, x0: float, width: float, height: float, figure_height: float,
	speed: float, cycles: int
) -> Dictionary:
	var entry: Array = MODES[mode]
	var caption: String = entry[0]
	var steps: int = entry[1]
	var jitter: bool = entry[2]
	var ground_y: float = height * 0.82

	var root := Node2D.new()
	root.name = "Panel%d" % index
	root.position = Vector2(x0 + PANEL_MARGIN, ground_y)
	add_child(root)

	var s := figure_height / FoolCutoutRig.FIGURE_HEIGHT_PX
	var rig := RigScript.new()
	rig.scale = Vector2(s, s)
	root.add_child(rig)
	rig.call("build")

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
		"rig": rig,
		"steps": steps,
		"jitter": jitter,
		"speed": speed,
		"cycle": FoolCutoutRig.WALK_CYCLE,
		"cycles": cycles,
		"start_x": PANEL_MARGIN,
		"ground_y": ground_y,
		"figure_height": figure_height,
		"x": x0,
		"width": width,
	}


## The tight rectangle the capture harness should crop to.
func capture_rect() -> Rect2i:
	if _panels.is_empty():
		return Rect2i(Vector2i.ZERO, get_viewport_rect().size)
	var left := INF
	var right := -INF
	var top := INF
	var bottom := -INF
	for panel in _panels:
		left = minf(left, float(panel["x"]))
		right = maxf(right, float(panel["x"]) + float(panel["width"]))
		top = minf(top, float(panel["ground_y"]) - float(panel["figure_height"]) - 58.0)
		bottom = maxf(bottom, float(panel["ground_y"]) + 46.0)
	var viewport := get_viewport_rect().size
	left = maxf(left, 0.0)
	top = maxf(top, 0.0)
	right = minf(right, viewport.x)
	bottom = minf(bottom, viewport.y)
	return Rect2i(Vector2i(int(left), int(top)), Vector2i(int(right - left), int(bottom - top)))


## Pose (and place) every panel at absolute time `t`.
func scrub(t: float) -> void:
	_time = t
	for panel in _panels:
		var cycle: float = panel["cycle"]
		var duration := cycle * float(panel["cycles"])
		var local_t := fposmod(t, duration)
		var speed: float = panel["speed"]

		# Translation: always continuous, always at the full walk speed,
		# whatever the pose is doing.
		var root: Node2D = panel["root"]
		root.position.x = float(panel["x"]) + float(panel["start_x"]) + speed * local_t

		# Pose: continuous for steps <= 0 (the control), held-and-stepped
		# otherwise.
		var rig: Node2D = panel["rig"]
		var steps: int = panel["steps"]
		if steps <= 0:
			rig.call("scrub", "walk", local_t)
		else:
			var held: Dictionary = PoseStepperScript.held_pose(local_t, cycle, steps)
			rig.call("scrub", "walk", float(held["time"]))
			if panel["jitter"]:
				rig.call("apply_jitter", int(held["index"]), JITTER_PX)
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
	for panel in _panels:
		_draw_panel(panel)


func _draw_panel(panel: Dictionary) -> void:
	var x0: float = panel["x"]
	var width: float = panel["width"]
	var ground_y: float = panel["ground_y"]
	var figure_height: float = panel["figure_height"]
	var viewport := get_viewport_rect().size

	draw_rect(Rect2(Vector2(x0, ground_y), Vector2(width, viewport.y - ground_y)), GROUND)
	draw_line(Vector2(x0, ground_y), Vector2(x0 + width, ground_y), GROUND_EDGE, 2.0)
	if x0 > 0.5:
		draw_line(Vector2(x0, 0.0), Vector2(x0, viewport.y), Color(0, 0, 0, 0.5), 2.0)

	# Fixed, NON-scrolling ground ticks. The treadmill bench scrolls the
	# ground because the walker stands still there; here the walker moves and
	# the ground doesn't, so a static grid is what lets the eye judge "is the
	# glide smooth" against something that holds still.
	var spacing: float = clampf(figure_height * 0.25, 8.0, width)
	var tick_height: float = clampf(figure_height * 0.09, 4.0, 22.0)
	var k := 0
	while x0 + float(k) * spacing < x0 + width:
		var x := x0 + float(k) * spacing
		var tall := posmod(k, 4) == 0
		draw_line(
			Vector2(x, ground_y),
			Vector2(x, ground_y + tick_height * (2.0 if tall else 1.0)),
			TICK,
			2.0
		)
		k += 1
