extends SceneTree

## Frame grabber for the animation spike. Not a test - a way to look at it.
##
##   godot --path godot --script tools/spike/capture_spike.gd -- OUTDIR [layouts...]
##
## Writes OUTDIR/<layout>/frame-####.png, one per capture frame, then the GIFs
## are assembled outside Godot with ImageMagick.
##
## Needs a real (windowed) run: the capture reads the window framebuffer, so
## --headless produces nothing useful. Two hard-won rules from
## tools/capture_screens.gd apply here too:
##   * pose, THEN wait frames, THEN capture - grabbing in the same frame you
##     changed something returns the previous frame's image;
##   * everything is scrubbed to an exact time, never free-run, so the GIF's
##     frame rate is a fact rather than whatever the compositor allowed.

const SCENE := "res://scenes/spike/anim_spike.tscn"
## 25, not 30: a GIF frame delay is a whole number of centiseconds, so 30 fps
## can only be written as 3 cs (33.3 fps, 11% fast). This spike is an argument
## about timing - the playback rate has to be exact.
const FPS := 25.0
const SETTLE_FRAMES := 2

var _out_dir := "/tmp/anim-spike"
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


## How many capture frames a layout needs.
##
## The clip has to close on itself or the GIF hitches every loop, and a layout
## can mix cycle lengths (the three-way puts today's broken 0.5 s cycle beside
## the corrected 0.6 s one). So: the shortest whole number of frames, at least
## ~2.2 s, that is a whole number of cycles for EVERY panel.
func _frames_for(layout: String) -> int:
	var periods: Array[float] = []
	for panel in _stage.call("panels"):
		periods.append(float(panel["cycle"]))
	var longest := 0.6
	for period in periods:
		longest = maxf(longest, period)
	for frames in range(int(2.2 * FPS), int(12.0 * FPS)):
		var seconds := float(frames) / FPS
		var closes := true
		for period in periods:
			var loops := seconds / period
			if absf(loops - round(loops)) > 0.005:
				closes = false
				break
		if closes:
			return frames
	push_warning("no common loop length for %s; falling back" % layout)
	return int(round(maxi(int(round(2.5 / longest)), 1) * longest * FPS))


func _begin_layout() -> void:
	var layout: String = str(_layouts[_layout_index])
	_stage.call("set_live", false)
	_stage.call("configure", layout)
	_stage.call("set_live", false)
	_rect = _stage.call("capture_rect")
	_total = _frames_for(layout)
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
