class_name CameraFraming
extends Node

## The conversational frame: an easing zoom into the space between two people.
##
## `docs/design/art-audio.md` §UI/UX pillars, Conversational framing: "interactions and
## dialogue are framed in-world by a slight camera adjustment - an easing zoom into the
## shared space between the participants (the Fool and Pip especially; the Fool and an
## NPC generally) - rather than a cut to a separate dialogue screen. Text (and Querent
## VO) plays over that adjusted frame. **No hard lock:** the player keeps control and
## the frame releases as they move off."
##
## So: this zooms and it offsets, and it does BOTH gently; it never reparents the
## camera, never takes input, and lets go by itself the moment the Fool walks out of
## the framed space. The doc calls the direction tentative and names MQ00 the proving
## ground - which is exactly why it is one small node with one job, rather than a
## framing state machine nobody has earned yet.

## How far in the frame pushes. A slight adjustment, per the doc: not a cutscene.
const ZOOM := 1.18

## How fast the zoom and the offset ease, per second.
const EASE_PER_SECOND := 4.0

## How far the Fool may walk from the framed midpoint before the frame lets go.
const RELEASE_DISTANCE := 420.0

## How close to the resting frame counts as arrived, so the easing can stop being
## processed at all: a hundredth of a zoom step and a pixel of offset, neither of
## which anybody can see.
const SETTLED_ZOOM := 0.001
const SETTLED_OFFSET := 1.0

var _camera: Camera2D = null
var _base_zoom: Vector2 = Vector2.ONE
var _a: Node2D = null
var _b: Node2D = null
var _framing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Nothing to ease yet. `_process` is turned on while a frame is being taken or
	# given back, and off again the moment the camera has arrived: this node runs
	# every frame of a conversation and none of the rest of the game.
	set_process(false)


## Watch this camera from now on; null detaches. The camera's own zoom as it stands
## is remembered as the resting frame, so releasing always returns to where the
## gameplay camera was.
func attach_camera(camera: Camera2D) -> void:
	_camera = camera
	if _camera != null:
		_base_zoom = _camera.zoom
	_framing = false
	_a = null
	_b = null
	set_process(false)


## The camera being framed, or null.
func camera() -> Camera2D:
	return _camera


## Frame the space between two people. Either may be null, in which case the other is
## framed alone; both null releases.
func frame_conversation(a: Node2D, b: Node2D) -> bool:
	if _camera == null or (a == null and b == null):
		release()
		return false
	_a = a
	_b = b
	_framing = true
	set_process(true)
	return true


## Let the frame go. The camera eases back to the resting zoom - which is easing
## too, so the processing stays on until it has arrived.
func release() -> void:
	_framing = false
	_a = null
	_b = null
	if _camera != null:
		set_process(true)


## True while a conversation is being framed.
func is_framing() -> bool:
	return _framing


## The two people being framed, in the order they were handed over, with whoever was
## null left out. For the tests and for anyone debugging a frame that took the wrong
## pair.
func framed_nodes() -> Array[Node2D]:
	var nodes: Array[Node2D] = []
	if _a != null:
		nodes.append(_a)
	if _b != null:
		nodes.append(_b)
	return nodes


## The point being framed - the midpoint of the two participants.
func framed_point() -> Vector2:
	if _a != null and _b != null:
		return (_a.global_position + _b.global_position) * 0.5
	if _a != null:
		return _a.global_position
	if _b != null:
		return _b.global_position
	return Vector2.ZERO


## The zoom the frame is easing toward.
func target_zoom() -> Vector2:
	return _base_zoom * ZOOM if _framing else _base_zoom


## True once the camera is sitting where it is being eased to, near enough that no
## further frame of easing would show.
func is_settled() -> bool:
	if _camera == null:
		return true
	return (
		_camera.zoom.distance_to(target_zoom()) <= SETTLED_ZOOM
		and _camera.offset.length() <= SETTLED_OFFSET
	)


func _process(delta: float) -> void:
	if _camera == null:
		set_process(false)
		return
	if _framing and _a != null and _a.global_position.distance_to(framed_point()) > RELEASE_DISTANCE:
		# The Fool walked off. No hard lock means exactly this: the frame lets go
		# without being told to.
		release()
	var weight := minf(1.0, EASE_PER_SECOND * delta)
	_camera.zoom = _camera.zoom.lerp(target_zoom(), weight)
	var offset := Vector2.ZERO
	if _framing:
		offset = framed_point() - _camera.get_screen_center_position()
		offset *= 0.5
	_camera.offset = _camera.offset.lerp(offset, weight)
	if not _framing and is_settled():
		# Home. Nothing to ease until somebody asks for a frame again.
		_camera.zoom = target_zoom()
		_camera.offset = Vector2.ZERO
		set_process(false)
