extends Node2D
class_name PaintedWalk

## SPIKE B: the shipping four-frame painted walk, with the timing bug fixed and
## the on-screen fidelity turned down.
##
## The fidelity question has to be asked with the timing already corrected, or
## the answer is confounded: today the cycle plays at a flat 8 fps and the Fool
## slides along at 200 px/s, so "the small one looks better" could just mean
## "the small one hides the slide". Every variant here runs the corrected
## timing and the stride-matched speed; only the pixel count changes.
##
## Corrected timing: the same 0.6 s cycle as the rig, but non-uniform. Frames 0
## and 2 are the contacts (frame 2 is unambiguous - both boots planted, legs at
## full spread) and are held CONTACT_RATIO times as long as the passing frames.
##
## Fidelity is real, not cosmetic: each frame is resampled (Lanczos) down to
## the requested figure height and then drawn 1:1, so a 49 px Fool really only
## has 49 px of Fool in him. `posterize_levels` additionally quantises the
## palette, to preview a chunkier storybook read.

const FRAMES := [
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-0.png"),
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-1.png"),
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-2.png"),
	preload("res://art/game-ready-sprites-v1/frames/fool/actions/walk-3.png"),
]

## Measured per frame from the alpha, same convention as scripts/player.gd:
## x on the alpha centroid, y on the lowest opaque pixel. Sprite2D is centred,
## so offset = cell centre - anchor.
const OFFSETS := [
	Vector2(-16.1, -153.0),
	Vector2(10.1, -150.0),
	Vector2(15.0, -141.0),
	Vector2(38.6, -146.0),
]

const CYCLE := 0.6
## Contact hold : passing hold. 2*contact + 2*contact/RATIO = CYCLE.
const CONTACT_RATIO := 1.5
const CONTACT_FRAMES := [0, 2]

## The reference figure height inside the 320 px action cell - the same number
## scripts/player.gd derives WALK_SCALE (0.419) from, so "100%" here really is
## the shipping control.
const NATIVE_FIGURE_PX := 291.75
const CELL_PX := 320.0

## Palette size for the "chunky storybook" preview. 0 disables quantisation.
@export var posterize_levels := 0
## Figure height on screen, in real pixels. 122 = what ships today.
@export var figure_height := 122.0
## Set > 0 to reproduce the BROKEN shipping timing: flat frame rate, no holds.
## scripts/player.gd ships WALK_FPS = 8.0.
@export var uniform_fps := 0.0
## Set > 0 to force a speed instead of deriving it from the stride.
## scripts/player.gd ships SPEED = 200.0.
@export var speed_override := 0.0

var _sprite: Sprite2D
var _textures: Array[Texture2D] = []
var _offsets: Array[Vector2] = []


func _ready() -> void:
	build()


func build() -> void:
	if _sprite != null:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "Art"
	add_child(_sprite)
	rebuild_fidelity()


## The corrected timing: contacts held CONTACT_RATIO times the passing frames.
static func frame_durations() -> Array[float]:
	var passing := CYCLE / (2.0 * CONTACT_RATIO + 2.0)
	var contact := passing * CONTACT_RATIO
	var out: Array[float] = []
	for index in FRAMES.size():
		out.append(contact if CONTACT_FRAMES.has(index) else passing)
	return out


static func frame_at(time: float) -> int:
	return _frame_in(frame_durations(), time)


static func _frame_in(durations: Array[float], time: float) -> int:
	var total := 0.0
	for duration in durations:
		total += duration
	var t := fposmod(time, total)
	for index in durations.size():
		if t < durations[index]:
			return index
		t -= durations[index]
	return durations.size() - 1


func cycle() -> float:
	return (float(FRAMES.size()) / uniform_fps) if uniform_fps > 0.0 else CYCLE


func durations() -> Array[float]:
	if uniform_fps <= 0.0:
		return frame_durations()
	var flat: Array[float] = []
	for index in FRAMES.size():
		flat.append(1.0 / uniform_fps)
	return flat


## Screen pixels of ground per cycle: the same stride-to-height ratio the rig
## walks at (0.585 figure heights per cycle), so neither spike is flattered.
func cycle_distance_px() -> float:
	if speed_override > 0.0:
		return speed_override * cycle()
	var ratio := FoolCutoutRig.cycle_distance_px() / FoolCutoutRig.FIGURE_HEIGHT_PX
	return figure_height * ratio


func speed_px() -> float:
	if speed_override > 0.0:
		return speed_override
	return cycle_distance_px() / cycle()


func art_scale() -> float:
	return figure_height / NATIVE_FIGURE_PX


func rebuild_fidelity() -> void:
	var s := art_scale()
	var cell := maxi(int(round(CELL_PX * s)), 8)
	_textures.clear()
	_offsets.clear()
	for index in FRAMES.size():
		var image := (FRAMES[index] as Texture2D).get_image().duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
		image.resize(cell, cell, Image.INTERPOLATE_LANCZOS)
		if posterize_levels > 0:
			_quantise(image)
		_textures.append(ImageTexture.create_from_image(image))
		_offsets.append(OFFSETS[index] * s)
	_sprite.scale = Vector2.ONE
	set_frame(0)


func _quantise(image: Image) -> void:
	var step := 256.0 / float(posterize_levels)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.35:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			image.set_pixel(x, y, Color(
				floor(pixel.r * 255.0 / step) * step / 255.0,
				floor(pixel.g * 255.0 / step) * step / 255.0,
				floor(pixel.b * 255.0 / step) * step / 255.0,
				1.0
			))


func set_frame(index: int) -> void:
	_sprite.texture = _textures[index]
	_sprite.offset = _offsets[index]


func scrub(time: float) -> void:
	build()
	set_frame(_frame_in(durations(), time))


func sprite() -> Sprite2D:
	build()
	return _sprite
