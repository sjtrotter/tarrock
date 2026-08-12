extends SceneTree

## Frame grabber for the anim-stepped spike. Same discipline as
## tools/spike/capture_spike.gd: pose, THEN wait, THEN capture - grabbing in
## the same frame you changed something returns the previous frame's image -
## and every frame is scrubbed to an exact time, never free-run, so a 25 fps
## GIF is exactly 25 fps regardless of what the window managed to render.
##
##   godot --path godot --script tools/spike/capture_stepped.gd -- OUTDIR [layouts...]
##
## Needs a real (windowed) run: the capture reads the window framebuffer.
## No --resolution override: the project's window/stretch/mode is
## "canvas_items" with a fixed 1280x720 base, so the SceneTree root
## viewport's logical size is 1280x720 regardless of the OS window's pixel
## size - stepped_walk_stage.gd's per-layout `cycles` (not window size) is
## what keeps every layout's panels inside that canvas. Passing --resolution
## here would only supersample the same 1280x720 layout, not grant more
## logical width to lay panels out in.
##
## Writes OUTDIR/<layout>/frame-####.png; tools/spike/make_stepped_gifs.py
## assembles those into the deliverable GIFs.

const SCENE := "res://scenes/spike/anim_stepped.tscn"
const FPS := 25.0
const SETTLE_FRAMES := 2

var _out_dir := "/tmp/anim-stepped"
var _layouts: Array = []
var _stage: Node2D
var _layout_index := 0
var _frame := 0
var _settle := 0
var _total := 0
var _rect := Rect2i()
var _warmup := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
	_layouts = args.slice(1) if args.size() > 1 else ["compare"]
	var packed: PackedScene = load(SCENE)
	_stage = packed.instantiate() as Node2D
	root.add_child(_stage)


func _begin_layout() -> void:
	var layout: String = str(_layouts[_layout_index])
	_stage.call("set_live", false)
	_stage.call("configure", layout)
	_stage.call("set_live", false)
	_rect = _stage.call("capture_rect")
	_total = int(round(float(_stage.call("layout_duration")) * FPS))
	_frame = 0
	_settle = 0
	DirAccess.make_dir_recursive_absolute(_out_dir + "/" + layout)
	print("LAYOUT %s  frames=%d  crop=%s" % [layout, _total, str(_rect)])


func _process(_delta: float) -> bool:
	# Let the window come up before measuring anything: get_viewport_rect() is
	# zero-sized on frame one of a headless-style `--script` launch.
	if _warmup < 5:
		_warmup += 1
		if _warmup == 5:
			_begin_layout()
		return false
	var layout: String = str(_layouts[_layout_index])
	if _settle == 0:
		_stage.call("scrub", float(_frame) / FPS)
	_settle += 1
	if _settle <= SETTLE_FRAMES:
		return false
	_settle = 0

	var image := root.get_texture().get_image()
	if image == null:
		push_error("no framebuffer - is this a windowed run?")
		return true
	var cropped := image.get_region(_rect)
	cropped.save_png("%s/%s/frame-%04d.png" % [_out_dir, layout, _frame])

	_frame += 1
	if _frame < _total:
		return false
	print("SAVED %d frames for %s" % [_total, layout])
	_layout_index += 1
	if _layout_index >= _layouts.size():
		return true
	_begin_layout()
	return false
