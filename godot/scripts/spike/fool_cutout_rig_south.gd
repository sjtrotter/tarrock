extends Node2D
class_name FoolCutoutRigSouth

## SPIKE A2: the same cutout idea, on the facing that should break it.
##
## Walking SOUTH is the hard case for a 2D cutout rig, and it is the honest
## test of the whole approach: the stride runs along the view axis, so the
## thing a bone is good at - rotating a limb in the image plane - buys almost
## nothing. Rotate a leg towards the camera and you get a leg that swings
## sideways.
##
## So this rig is deliberately built from the standard top-down cheats rather
## than from bone rotation, and shares the east rig's TIMING exactly
## (FoolCutoutRig.WALK_CYCLE, the same hip-bob curve, the same stride) so the
## two GIFs are comparable:
##
##   1. THE BOB CARRIES THE WEIGHT. Same 13 px, twice a cycle, lowest just
##      after each contact. From the front there is no leg silhouette to read
##      the gait from, so the vertical is nearly the whole story.
##   2. A LATERAL WEIGHT SHIFT. The pelvis slides over the stance foot, once
##      per cycle. Invisible from the side, essential from the front.
##   3. A SCALE PULSE ON THE TORSO through each passing position - the body
##      lengthening as it rides up over the straight leg.
##   4. THE STRIDE IS DEPTH, NOT WIDTH. A leg swung forward is nearer the
##      camera: it slides DOWN the screen and grows; swung back it slides up
##      and shrinks. That is the leg animation, in full.
##   5. FEET ARE SWAPPED DRAWINGS, NOT ROTATED BONES - a hybrid of frame
##      animation and rigging. Three positions per foot (planted, lifted,
##      forward), swapped on a discrete track, because a boot pointing at the
##      camera cannot be reached by rotating the drawn one.
##
## Whether that is enough is a judgement call for the director; see the report.

const PARTS_PATH := "res://art/spike/fool-cutout-south/parts.json"
const ART_DIR := "res://art/spike/fool-cutout-south/"

const FORWARD := -1.0
const FIGURE_HEIGHT_PX := 435.0

## name -> [parent, part key or ""]
##
## Production update (purpose-drawn Codex parts, replacing the sliced spike
## art): each leg and arm is now drawn as two purpose-drawn parts (thigh/shin,
## upper/lower) instead of one fused image, plus a small knee-cap overlay.
## Minimal re-keying: the new Shin/Lower/KneeCap bones are static children -
## they carry no animation track of their own and simply ride rigidly with
## their parent Thigh/Upper bone, exactly as the old fused single-image leg
## and arm did. Only the bone names in _add_leg/_build_walk/_build_idle
## changed (LegLeft -> LegLeftThigh, ArmRight -> ArmRightUpper, etc).
const BONE_TREE := [
	["Hips", "", ""],
	["Spine", "Hips", ""],
	["Chest", "Spine", ""],
	["Head", "Chest", "head"],
	["Stick", "Chest", "stick"],
	["BindleBag", "Stick", "bag"],
	["LegLeftThigh", "Hips", "leg_left_thigh"],
	["LegLeftShin", "LegLeftThigh", "leg_left_shin"],
	["KneeCapLeft", "LegLeftShin", "knee_cap_left"],
	["FootLeft", "LegLeftShin", "foot_left"],
	["LegRightThigh", "Hips", "leg_right_thigh"],
	["LegRightShin", "LegRightThigh", "leg_right_shin"],
	["KneeCapRight", "LegRightShin", "knee_cap_right"],
	["FootRight", "LegRightShin", "foot_right"],
	["Torso", "Chest", "torso"],
	["ArmRightUpper", "Chest", "arm_right_upper"],
	["ArmRightLower", "ArmRightUpper", "arm_right_lower"],
	["ArmLeftUpper", "Chest", "arm_left_upper"],
	["ArmLeftLower", "ArmLeftUpper", "arm_left_lower"],
]

const EXTRA_PIVOTS := {
	"Hips": Vector2(92, 284),
	"Spine": Vector2(96, 240),
	"Chest": Vector2(100, 140),
}

const DRAW_ORDER := [
	"BindleBag",
	"LegLeftThigh", "LegLeftShin", "KneeCapLeft", "FootLeft",
	"LegRightThigh", "LegRightShin", "KneeCapRight", "FootRight",
	"Torso", "ArmRightUpper", "ArmRightLower", "Stick", "ArmLeftUpper", "ArmLeftLower", "Head",
]

# --- cheat tables (phase 0..1 of FoolCutoutRig.WALK_CYCLE) ------------------
# Phase 0 = the LEFT foot's forward contact. The right leg runs +0.5.

## Pelvis slides over whichever foot is carrying the weight. Positive = towards
## the viewer's right, native px. Once per cycle, unlike the bob.
const HIPS_SWAY_KEYS := [
	[0.00, -3.0], [0.22, -3.4], [0.50, 3.0], [0.72, 3.4], [1.00, -3.0],
]

## The leg's fore-aft position, expressed the only way a front view can express
## it: as screen depth. Positive = down the screen = nearer the camera.
const LEG_DEPTH_KEYS := [
	[0.00, 15.0], [0.15, 10.0], [0.30, 0.0], [0.45, -9.0],
	[0.50, -12.0], [0.60, -11.0], [0.72, -3.0], [0.85, 7.0],
	[0.95, 13.5], [1.00, 15.0],
]
## The one thing a front view CAN give a bone: a little lateral scissor. The
## swinging leg tucks towards the midline and the stance leg braces outwards.
## Positive = away from the body's centre line.
const LEG_SPLAY_KEYS := [
	[0.00, 1.5], [0.22, 2.6], [0.50, 1.0], [0.64, -3.2],
	[0.80, -2.0], [1.00, 1.5],
]
## Foreshortening. Scaled about the hip, so shrinking the leg also lifts the
## boot off the floor - which is how a knee-raise reads from the front.
const LEG_SCALE_KEYS := [
	[0.00, 1.045], [0.30, 1.000], [0.50, 0.955], [0.62, 0.915],
	[0.78, 0.950], [0.92, 1.015], [1.00, 1.045],
]
## Which of the three drawn boots is showing. Discrete, by design.
const FOOT_POSE_KEYS := [
	[0.00, "fwd"], [0.26, ""], [0.52, "lift"], [0.88, "fwd"], [1.00, "fwd"],
]

## The body lengthens over the straight stance leg and settles at each contact.
## Twice a cycle, in phase with the bob. Tiny - 1.8% - and it is the difference
## between a puppet sliding up and down and a body taking weight.
const TORSO_STRETCH_KEYS := [
	[0.00, -0.008], [0.15, -0.012], [0.33, 0.010], [0.42, 0.018],
	[0.50, -0.008], [0.65, -0.012], [0.83, 0.010], [0.92, 0.018],
	[1.00, -0.008],
]

## Shoulders counter-rotating against the hips. Head-on that is not a twist you
## can draw, but the tilt it produces is.
const TORSO_TILT_KEYS := [
	[0.00, 1.4], [0.25, 0.0], [0.50, -1.4], [0.75, 0.0], [1.00, 1.4],
]
const HEAD_TILT_KEYS := [
	[0.00, 1.6], [0.25, 0.0], [0.50, -1.6], [0.75, 0.0], [1.00, 1.6],
]
const HEAD_LAG := 0.07
## The free arm. Fore-aft again, so: a vertical slide plus a scale pulse plus a
## little lateral swing to keep it off the tunic.
const ARM_DEPTH_KEYS := [
	[0.00, -8.0], [0.25, 0.0], [0.50, 8.0], [0.75, 0.0], [1.00, -8.0],
]
const ARM_SCALE_KEYS := [
	[0.00, 0.97], [0.25, 1.00], [0.50, 1.03], [0.75, 1.00], [1.00, 0.97],
]
const ARM_SWING_KEYS := [
	[0.00, -8.0], [0.25, 0.0], [0.50, 8.0], [0.75, 0.0], [1.00, -8.0],
]
const BAG_KEYS := [
	[0.00, 0.0], [0.12, 6.0], [0.25, 0.0], [0.37, -6.0],
	[0.50, 0.0], [0.62, 6.0], [0.75, 0.0], [0.87, -6.0], [1.00, 0.0],
]
const BAG_LAG := 0.10

const IDLE_CYCLE := 2.8

var _skeleton: Skeleton2D
var _player: AnimationPlayer
var _bones: Dictionary = {}
var _parts: Dictionary = {}
var _rest: Dictionary = {}
var _clip := "walk"


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	build()


static func load_parts() -> Dictionary:
	var text := FileAccess.get_file_as_string(PARTS_PATH)
	assert(text != "", "south spike parts missing - run tools/spike/segment_fool_south.py")
	return JSON.parse_string(text) as Dictionary


func build() -> void:
	if _skeleton != null:
		return
	var manifest := load_parts()
	_parts = manifest["parts"]
	var origin := Vector2(manifest["origin"][0], manifest["origin"][1])

	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton"
	add_child(_skeleton)

	for entry in BONE_TREE:
		var bone_name: String = entry[0]
		var parent_name: String = entry[1]
		var part_key: String = entry[2]
		var pivot := _pivot_for(bone_name, part_key, origin)
		_rest[bone_name] = pivot
		var parent_node: Node = _skeleton if parent_name == "" else _bones[parent_name]
		var bone := Bone2D.new()
		bone.name = bone_name
		bone.position = pivot - (Vector2.ZERO if parent_name == "" else _rest[parent_name])
		bone.rest = Transform2D(0.0, bone.position)
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(24.0)
		parent_node.add_child(bone)
		_bones[bone_name] = bone
		if part_key != "":
			bone.add_child(_make_sprite(part_key))

	for index in DRAW_ORDER.size():
		var sprite := (_bones[DRAW_ORDER[index]] as Bone2D).get_node_or_null("Art") as Sprite2D
		if sprite != null:
			sprite.z_index = index + 1

	_player = AnimationPlayer.new()
	_player.name = "Anim"
	add_child(_player)
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	var library := AnimationLibrary.new()
	library.add_animation("walk", _build_walk())
	library.add_animation("idle", _build_idle())
	_player.add_animation_library("", library)
	_player.play(_clip)


func _pivot_for(bone_name: String, part_key: String, origin: Vector2) -> Vector2:
	if part_key != "":
		var part: Dictionary = _parts[part_key]
		return Vector2(part["rig_position"][0], part["rig_position"][1])
	assert(EXTRA_PIVOTS.has(bone_name), "no pivot for jointless bone " + bone_name)
	return (EXTRA_PIVOTS[bone_name] as Vector2) - origin


func _make_sprite(part_key: String) -> Sprite2D:
	var part: Dictionary = _parts[part_key]
	var sprite := Sprite2D.new()
	sprite.name = "Art"
	sprite.centered = false
	sprite.texture = load(ART_DIR + str(part["file"]))
	sprite.offset = Vector2(part["offset"][0], part["offset"][1])
	return sprite


# --- animation ---------------------------------------------------------------

func _bone_path(bone_name: String) -> String:
	var lookup := {}
	for entry in BONE_TREE:
		lookup[entry[0]] = entry[1]
	var chain := [bone_name]
	var current: String = lookup[bone_name]
	while current != "":
		chain.push_front(current)
		current = lookup[current]
	return "Skeleton/" + "/".join(chain)


func _track(anim: Animation, path: String, discrete := false) -> int:
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, path)
	if discrete:
		anim.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_NEAREST)
	else:
		anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
		anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	return track


func _add_curve(
	anim: Animation, path: String, keys: Array, cycle: float, build: Callable
) -> void:
	var track := _track(anim, path)
	for key in keys:
		anim.track_insert_key(track, float(key[0]) * cycle, build.call(float(key[1])))


## One leg, all cheats: depth slide, foreshortening, and the drawn foot swap.
## Only the thigh bone is animated - the shin and knee-cap are static children
## of it (see BONE_TREE) and ride along rigidly, same as the old fused image.
func _add_leg(anim: Animation, side: String, offset: float, cycle: float) -> void:
	var leg := "Leg" + side + "Thigh"
	var foot := "Foot" + side
	var rest_position: Vector2 = _bones[leg].position

	var depth := _track(anim, _bone_path(leg) + ":position")
	var leg_scale := _track(anim, _bone_path(leg) + ":scale")
	var leg_splay := _track(anim, _bone_path(leg) + ":rotation_degrees")
	var foot_scale := _track(anim, _bone_path(foot) + ":scale")
	var foot_splay := _track(anim, _bone_path(foot) + ":rotation_degrees")
	# Splay is mirrored: "outwards" is -x for the left leg and +x for the right.
	var mirror := -1.0 if side == "Left" else 1.0
	for index in 41:
		var phase := float(index) / 40.0
		var leg_phase := fposmod(phase + offset, 1.0)
		var s := FoolCutoutRig.sample_curve(LEG_SCALE_KEYS, leg_phase)
		var splay := mirror * FoolCutoutRig.sample_curve(LEG_SPLAY_KEYS, leg_phase)
		anim.track_insert_key(leg_splay, phase * cycle, splay)
		# The boot stays flat on the floor while the leg above it leans.
		anim.track_insert_key(foot_splay, phase * cycle, -splay)
		anim.track_insert_key(
			depth,
			phase * cycle,
			rest_position + Vector2(0.0, FoolCutoutRig.sample_curve(LEG_DEPTH_KEYS, leg_phase))
		)
		anim.track_insert_key(leg_scale, phase * cycle, Vector2(1.0, s))
		# Keep the boot its own size while the leg above it foreshortens.
		anim.track_insert_key(foot_scale, phase * cycle, Vector2(1.0, 1.0 / s))

	# The drawn foot positions. Texture and pivot offset swap together, on a
	# discrete track - this is the frame-animation half of the hybrid.
	var texture_track := _track(anim, _bone_path(foot) + "/Art:texture", true)
	var offset_track := _track(anim, _bone_path(foot) + "/Art:offset", true)
	var base := "foot_" + side.to_lower()
	for key in FOOT_POSE_KEYS:
		var phase := fposmod(float(key[0]) - offset, 1.0)
		var pose: String = str(key[1])
		var part_key: String = base if pose == "" else base + "_" + pose
		var part: Dictionary = _parts[part_key]
		anim.track_insert_key(texture_track, phase * cycle, load(ART_DIR + str(part["file"])))
		anim.track_insert_key(
			offset_track, phase * cycle, Vector2(part["offset"][0], part["offset"][1])
		)


func _build_walk() -> Animation:
	var cycle := FoolCutoutRig.WALK_CYCLE
	var anim := Animation.new()
	anim.length = cycle
	anim.loop_mode = Animation.LOOP_LINEAR

	# The bob is shared verbatim with the east rig - same curve, same 13 px.
	var hips_rest: Vector2 = _bones["Hips"].position
	var hips := _track(anim, _bone_path("Hips") + ":position")
	var phases: Array = []
	for key in FoolCutoutRig.HIPS_BOB_KEYS:
		phases.append(float(key[0]))
	for key in HIPS_SWAY_KEYS:
		if not phases.has(float(key[0])):
			phases.append(float(key[0]))
	phases.sort()
	for phase in phases:
		anim.track_insert_key(hips, phase * cycle, hips_rest + Vector2(
			FoolCutoutRig.sample_curve(HIPS_SWAY_KEYS, phase),
			-FoolCutoutRig.sample_curve(FoolCutoutRig.HIPS_BOB_KEYS, phase)
		))

	_add_curve(
		anim, _bone_path("Chest") + ":scale", TORSO_STRETCH_KEYS, cycle,
		func(v): return Vector2(1.0 - v * 0.5, 1.0 + v)
	)
	_add_curve(
		anim, _bone_path("Chest") + ":rotation_degrees", TORSO_TILT_KEYS, cycle,
		func(v): return FORWARD * v
	)
	_add_curve(
		anim, _bone_path("Head") + ":rotation_degrees",
		FoolCutoutRig.lag(HEAD_TILT_KEYS, HEAD_LAG), cycle,
		func(v): return FORWARD * v
	)

	_add_leg(anim, "Left", 0.0, cycle)
	_add_leg(anim, "Right", 0.5, cycle)

	# The free arm mirrors the opposite leg. ArmRightLower/ArmLeftLower are
	# static children of the Upper bones (see BONE_TREE) and ride along.
	var arm_rest: Vector2 = _bones["ArmRightUpper"].position
	_add_curve(
		anim, _bone_path("ArmRightUpper") + ":position", ARM_DEPTH_KEYS, cycle,
		func(v): return arm_rest + Vector2(0.0, v)
	)
	_add_curve(
		anim, _bone_path("ArmRightUpper") + ":scale", ARM_SCALE_KEYS, cycle,
		func(v): return Vector2(1.0, v)
	)
	_add_curve(
		anim, _bone_path("ArmRightUpper") + ":rotation_degrees", ARM_SWING_KEYS, cycle,
		func(v): return v
	)
	# The bindle arm is pinned to the stick, so it only counter-swings a little.
	_add_curve(
		anim, _bone_path("ArmLeftUpper") + ":rotation_degrees",
		FoolCutoutRig.scaled(ARM_SWING_KEYS, -0.35), cycle,
		func(v): return v
	)
	_add_curve(
		anim, _bone_path("BindleBag") + ":rotation_degrees",
		FoolCutoutRig.lag(BAG_KEYS, BAG_LAG), cycle,
		func(v): return v
	)
	return anim


func _build_idle() -> Animation:
	var anim := Animation.new()
	anim.length = IDLE_CYCLE
	anim.loop_mode = Animation.LOOP_LINEAR
	var chest_rest: Vector2 = _bones["Chest"].position
	_add_curve(
		anim, _bone_path("Chest") + ":position", FoolCutoutRig.IDLE_CHEST_LIFT, IDLE_CYCLE,
		func(v): return chest_rest + Vector2(0.0, -v)
	)
	_add_curve(
		anim, _bone_path("Chest") + ":scale", FoolCutoutRig.IDLE_CHEST_LIFT, IDLE_CYCLE,
		func(v): return Vector2(1.0 - v * 0.0015, 1.0 + v * 0.003)
	)
	var hips_rest: Vector2 = _bones["Hips"].position
	_add_curve(
		anim, _bone_path("Hips") + ":position", FoolCutoutRig.IDLE_HIPS_X, IDLE_CYCLE,
		func(v): return hips_rest + Vector2(v, 0.0)
	)
	_add_curve(
		anim, _bone_path("Head") + ":rotation_degrees", FoolCutoutRig.IDLE_HEAD, IDLE_CYCLE,
		func(v): return FORWARD * v
	)
	_add_curve(
		anim, _bone_path("Chest") + ":rotation_degrees", [[0.0, 0.0], [1.0, 0.0]],
		IDLE_CYCLE, func(v): return v
	)
	_add_curve(
		anim, _bone_path("ArmRightUpper") + ":rotation_degrees", [[0.0, 0.0], [1.0, 0.0]],
		IDLE_CYCLE, func(v): return v
	)
	var arm_rest: Vector2 = _bones["ArmRightUpper"].position
	_add_curve(
		anim, _bone_path("ArmRightUpper") + ":position", [[0.0, 0.0], [1.0, 0.0]],
		IDLE_CYCLE, func(v): return arm_rest + Vector2(0.0, v)
	)
	_add_curve(
		anim, _bone_path("ArmRightUpper") + ":scale", [[0.0, 1.0], [1.0, 1.0]],
		IDLE_CYCLE, func(v): return Vector2(1.0, v)
	)
	_add_curve(
		anim, _bone_path("BindleBag") + ":rotation_degrees",
		FoolCutoutRig.lag(FoolCutoutRig.IDLE_BAG, 0.09), IDLE_CYCLE,
		func(v): return v
	)
	# Legs and feet back to rest, or the idle inherits a mid-stride pose.
	for side in ["Left", "Right"]:
		var rest_position: Vector2 = _bones["Leg" + side + "Thigh"].position
		_add_curve(
			anim, _bone_path("Leg" + side + "Thigh") + ":position", [[0.0, 0.0], [1.0, 0.0]],
			IDLE_CYCLE, func(v): return rest_position + Vector2(0.0, v)
		)
		_add_curve(
			anim, _bone_path("Leg" + side + "Thigh") + ":scale", [[0.0, 1.0], [1.0, 1.0]],
			IDLE_CYCLE, func(v): return Vector2(1.0, v)
		)
		_add_curve(
			anim, _bone_path("Foot" + side) + ":scale", [[0.0, 1.0], [1.0, 1.0]],
			IDLE_CYCLE, func(v): return Vector2(1.0, v)
		)
		for joint in ["Leg" + side + "Thigh", "Foot" + side]:
			_add_curve(
				anim, _bone_path(joint) + ":rotation_degrees", [[0.0, 0.0], [1.0, 0.0]],
				IDLE_CYCLE, func(v): return v
			)
		var part: Dictionary = _parts["foot_" + side.to_lower()]
		var texture_track := _track(anim, _bone_path("Foot" + side) + "/Art:texture", true)
		anim.track_insert_key(texture_track, 0.0, load(ART_DIR + str(part["file"])))
		var offset_track := _track(anim, _bone_path("Foot" + side) + "/Art:offset", true)
		anim.track_insert_key(
			offset_track, 0.0, Vector2(part["offset"][0], part["offset"][1])
		)
	return anim


# --- driving -----------------------------------------------------------------

func clip_length(clip_name: String) -> float:
	return IDLE_CYCLE if clip_name == "idle" else FoolCutoutRig.WALK_CYCLE


func scrub(clip_name: String, time: float) -> void:
	build()
	if clip_name != _clip:
		_clip = clip_name
		_player.play(_clip)
	_player.pause()
	_player.seek(fposmod(time, clip_length(clip_name)), true)


func bone(bone_name: String) -> Bone2D:
	build()
	return _bones.get(bone_name, null)


func animation_player() -> AnimationPlayer:
	build()
	return _player
