extends RefCounted
class_name CharacterAnimator

## Data-keyed sprite animation: (direction, action) -> frame list.
##
## A *clip* is a Dictionary:
##   {
##     "frames":  Array[Texture2D],   # one or more frames
##     "offsets": Array[Vector2],     # per-frame Sprite2D.offset (the measured pivot)
##     "scale":   float,              # uniform Sprite2D.scale for this clip
##     "fps":     float,
##     "loop":    bool,
##   }
##
## A *table* is Dictionary[action][direction] -> clip. The action `static` is
## required and must hold every direction as a single-frame clip: it is the fallback
## whenever the requested (direction, action) pair has no art yet. That is how the
## Cliff ships today - one authored south-east walk cycle, seven directions still on
## their static facing frames (see godot/art/ART-REQUESTS.md).
##
## Pivots matter: every offset here was measured from the art's alpha channel, using
## the same convention as the hand-measured direction tables
## (offset = cell_centre - anchor, anchor = (alpha centroid x, alpha bottom y)).

const FALLBACK_ACTION := "static"

var _sprite: Sprite2D
var _table: Dictionary = {}
var _requested_action := FALLBACK_ACTION
var _direction := "south"
var _resolved_action := FALLBACK_ACTION
var _clip: Dictionary = {}
var _frame := 0
var _elapsed := 0.0


static func make_clip(frames: Array, offsets: Array, clip_scale: float, fps: float, loop: bool) -> Dictionary:
	assert(frames.size() == offsets.size(), "a clip needs one pivot offset per frame")
	return {
		"frames": frames,
		"offsets": offsets,
		"scale": clip_scale,
		"fps": fps,
		"loop": loop,
	}


func configure(sprite: Sprite2D, table: Dictionary) -> void:
	assert(table.has(FALLBACK_ACTION), "an animation table must define the 'static' action")
	_sprite = sprite
	_table = table
	_resolve()
	_apply()


## Ask for a pose. Unknown pairs silently fall back to the static facing frame, so
## gameplay never has to know which cycles have been drawn yet.
func set_state(direction: String, action: String) -> void:
	if direction == _direction and action == _requested_action:
		return
	_direction = direction
	_requested_action = action
	var previous := _resolved_action
	_resolve()
	if _resolved_action != previous or _clip["frames"].size() <= 1:
		_frame = 0
		_elapsed = 0.0
	_apply()


func advance(delta: float) -> void:
	var frames: Array = _clip.get("frames", [])
	if frames.size() <= 1:
		return
	_elapsed += delta
	var fps: float = _clip["fps"]
	var index := int(_elapsed * fps)
	if bool(_clip["loop"]):
		index = index % frames.size()
	else:
		index = mini(index, frames.size() - 1)
	if index == _frame:
		return
	_frame = index
	_apply()


func direction() -> String:
	return _direction


func requested_action() -> String:
	return _requested_action


## The action actually playing - `static` when the requested one has no art.
func current_action() -> String:
	return _resolved_action


func current_frame() -> int:
	return _frame


func frame_count() -> int:
	return _clip.get("frames", []).size()


func is_animated() -> bool:
	return frame_count() > 1


func has_clip(direction_name: String, action: String) -> bool:
	return _table.has(action) and (_table[action] as Dictionary).has(direction_name)


func _resolve() -> void:
	if has_clip(_direction, _requested_action):
		_resolved_action = _requested_action
	else:
		_resolved_action = FALLBACK_ACTION
	_clip = (_table[_resolved_action] as Dictionary)[_direction]


func _apply() -> void:
	if _sprite == null or _clip.is_empty():
		return
	var frames: Array = _clip["frames"]
	var index := clampi(_frame, 0, frames.size() - 1)
	_sprite.texture = frames[index]
	_sprite.offset = _clip["offsets"][index]
	var clip_scale: float = _clip["scale"]
	_sprite.scale = Vector2(clip_scale, clip_scale)
