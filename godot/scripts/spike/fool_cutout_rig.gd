extends Node2D
class_name FoolCutoutRig

## SPIKE A: the Fool as a Godot Skeleton2D cutout puppet, east-facing.
##
## Throwaway evaluation code. It exists to answer one question for the director:
## does a bone-driven cutout of the painted Fool read as a walking boy or as a
## cardboard puppet? Nothing here is meant to survive into the game as-is.
##
## The parts come from tools/spike/segment_fool_east.py; the joint pivots and
## the rest positions are all read out of art/spike/fool-cutout/parts.json, so
## re-cutting the art cannot desync the rig.
##
## ---------------------------------------------------------------------------
## Craft targets this rig is built to hit (from the walk-defect review):
##
##   * visible vertical displacement - hips travel HIPS_BOB_PX (13 px on a
##     434 px figure = 3.0%), lowest just after each contact, highest through
##     the passing position. The current painted cycle's bob is both too small
##     and at half the right frequency.
##   * non-uniform timing - contacts are held (a duplicate key 0.05 of a cycle
##     after each contact) and the swing phase is keyed sparsely, so the
##     longest gap between keys is >= 1.5x the shortest.
##   * one gait cycle in WALK_CYCLE seconds (0.6) - two steps.
##   * stride-matched travel: STEP_PX * 2 of ground per cycle, no foot skate.
##   * secondary motion: the bindle bag swings at twice the cycle frequency
##     (it is driven by the bob) and lags the body by BAG_LAG.
##
## All angle tables below are written in an intuitive "forward is positive"
## convention and applied through FORWARD. In Godot 2D a positive rotation
## swings a downward-pointing limb towards -x, i.e. backwards for an
## east-facing character, hence the sign flip in one place instead of
## everywhere.
##
## NOTE (Godot bug #100881): Skeleton2D + physics interpolation corrupts bone
## transforms. This rig disables physics interpolation on itself and animates
## on the idle/process callback, never on physics.

const PARTS_PATH := "res://art/spike/fool-cutout/parts.json"

const FORWARD := -1.0

## Read off the painting: 434 px from hair to boot sole is a 1.75 m boy, so
## 248 px per metre. Hip pivot to sole is 169 px = 0.68 m of leg.
const FIGURE_HEIGHT_PX := 434.0
const PIXELS_PER_METRE := 248.0
## Hip pivot to sole - what a step length has to be measured against.
const HIP_HEIGHT_PX := 169.0
## Knee to ankle, measured off the pre-fusion spike geometry. The shin+boot
## part has no ankle child bone to read a rest length from any more (see
## BONE_TREE), so this is the IK solve's fixed second segment length.
const SHIN_LEN := 71.0

## One full cycle - two steps. 0.6 s is brisk for a real walk (a life-accurate
## cycle is nearer 1.0 s) but it is the storybook-game read the brief asks for.
const WALK_CYCLE := 0.6
## Step length: 0.75 x leg length, the textbook adult ratio. 169 * 0.75 = 127.
const STEP_PX := 127.0
## Hips rise and fall this far, peak to trough, in native art pixels.
const HIPS_BOB_PX := 13.0

const IDLE_CYCLE := 2.8

## Bones that carry a sprite, and where their rest transform comes from.
## name -> [parent, part key or "" for a jointless bone]
##
## Production update (purpose-drawn Codex parts, replacing the sliced spike
## art): the foot is no longer its own bone - "leg_near_shin" and
## "leg_far_shin" are now fused shin+boot pieces drawn as one rigid part (see
## docs in the anim-parts generation brief), so the separate ankle-pitch
## track is gone too. In exchange there is now a REAL far arm (purpose-drawn,
## not a tinted duplicate) and a small knee-cap overlay piece per leg that
## sits over the thigh/shin seam.
const BONE_TREE := [
	["Hips", "", ""],
	["Spine", "Hips", ""],
	["Chest", "Spine", ""],
	["Head", "Chest", "head"],
	["Stick", "Chest", "stick"],
	["BindleBag", "Stick", "bag"],
	["LegFarThigh", "Hips", "leg_far_thigh"],
	["LegFarShin", "LegFarThigh", "leg_far_shin"],
	["KneeCapFar", "LegFarShin", "knee_cap_far"],
	["LegNearThigh", "Hips", "leg_near_thigh"],
	["LegNearShin", "LegNearThigh", "leg_near_shin"],
	["KneeCapNear", "LegNearShin", "knee_cap_near"],
	["Torso", "Chest", "torso"],
	["ArmFarUpper", "Chest", "arm_far_upper"],
	["ArmFarLower", "ArmFarUpper", "arm_far_lower"],
	["ArmNearUpper", "Chest", "arm_upper"],
	["ArmNearLower", "ArmNearUpper", "arm_lower"],
]

## Bones with no part of their own need an explicit rest point, in the crop
## space parts.json uses (the source's alpha bbox, 171 x 434).
const EXTRA_PIVOTS := {
	"Hips": Vector2(80, 262),
	"Spine": Vector2(86, 225),
	"Chest": Vector2(98, 120),
}

## Back to front. The far limbs sit behind the tunic, the near ones in front.
const DRAW_ORDER := [
	"BindleBag", "Stick",
	"LegFarThigh", "LegFarShin", "KneeCapFar",
	"ArmFarUpper", "ArmFarLower",
	"LegNearThigh", "LegNearShin", "KneeCapNear",
	"Torso", "ArmNearUpper", "ArmNearLower", "Head",
]

## Production update: the far arm and far leg are now purpose-drawn parts
## (see the anim-parts generation brief), not silhouette slices of the near
## limb. They still get a light recede tint - not because the art is fake,
## but because a same-lit far limb reads as popping forward of the torso it
## should be sitting behind.
const FAR_TINT := Color(0.86, 0.85, 0.87, 1.0)

# --- the legs: a foot path, solved with IK ----------------------------------
#
# The first version of this rig keyed thigh/knee/ankle angles by hand. It
# looked fine in stills and skated 24% during stance: over the supporting half
# of the cycle the boot only travelled 77 native px while the ground travelled
# 102, so the Fool moon-walked a quarter of every step. Hand-keyed FK cannot
# fix that reliably - the foot's position is three angles away from the thing
# you are trying to control.
#
# So the leg is authored the way the defect is stated: as the FOOT'S PATH over
# the ground, with a two-bone IK solve for the angles. Stance is a straight
# line at exactly the ground speed, which makes skate impossible by
# construction rather than by careful keying.
#
# Phase 0 = the near foot's heel strike. Stance 0.00 -> 0.50, swing after.

## Fore-aft position of the ankle, native px, positive = forward, measured from
## the body's centre line. During stance this MUST be linear at the ground
## speed: 127 px back over half a cycle = 254 px per cycle = cycle_distance_px.
const FOOT_X_KEYS := [
	[0.00, 63.5],
	[0.50, -63.5],
	# Swing: slow out of toe-off, quick through the middle, slow into the next
	# contact. This is where the non-uniform timing of the gait lives.
	[0.58, -48.0], [0.66, -20.0], [0.74, 16.0], [0.82, 43.0],
	[0.90, 57.0], [0.96, 62.5], [1.00, 63.5],
]
## Ankle height above the ground line, native px. 31 is the drawn standing
## height; the heel strike and the toe-off both lift the ankle because the foot
## is one rigid part pivoting at the ankle.
const FOOT_H_KEYS := [
	[0.00, 38.0], [0.06, 31.0], [0.36, 31.0], [0.44, 35.0],
	[0.50, 47.0], [0.60, 70.0], [0.72, 72.0], [0.85, 56.0],
	[0.94, 42.0], [1.00, 38.0],
]
## How finely the solved angles are baked into the animation. 40 keys a cycle
## is a key every 15 ms, so the tracks can interpolate linearly and still
## reproduce the foot path exactly - no cubic overshoot at the heel strike.
const LEG_SAMPLES := 40

## Hips, in native pixels, positive = up. Twice per cycle: lowest just after
## each contact, highest through each passing position.
const HIPS_BOB_KEYS := [
	[0.00, -3.0], [0.15, -6.5], [0.28, 2.0], [0.38, 6.5],
	[0.50, -3.0], [0.65, -6.5], [0.78, 2.0], [0.88, 6.5], [1.00, -3.0],
]
## A small fore-aft surge: the body checks at each contact and creeps forward
## over the supporting foot.
const HIPS_SURGE_KEYS := [
	[0.00, -1.5], [0.25, 0.6], [0.50, -1.5], [0.75, 0.6], [1.00, -1.5],
]
const HIPS_TILT_KEYS := [
	[0.00, 2.0], [0.25, 0.0], [0.50, -2.0], [0.75, 0.0], [1.00, 2.0],
]
## Shoulders counter-rotate against the hips. Subtle - it is a profile view.
const CHEST_KEYS := [
	[0.00, -3.0], [0.25, 0.0], [0.50, 3.0], [0.75, 0.0], [1.00, -3.0],
]
const SPINE_KEYS := [
	[0.00, 1.5], [0.25, 0.0], [0.50, -1.5], [0.75, 0.0], [1.00, 1.5],
]
## The head counters the chest and lags it, so it stays level-ish.
const HEAD_KEYS := [
	[0.00, 2.5], [0.25, 0.0], [0.50, -2.5], [0.75, 0.0], [1.00, 2.5],
]
const HEAD_LAG := 0.06
## The free (far) arm swings with the near leg. The near arm is holding the
## bindle, so it only breathes - that is the pose the painting gives us.
const ARM_SWING_KEYS := [
	[0.00, 20.0], [0.25, 0.0], [0.50, -20.0], [0.75, 0.0], [1.00, 20.0],
]
const ARM_ELBOW_KEYS := [
	[0.00, -8.0], [0.25, -22.0], [0.50, -30.0], [0.75, -16.0], [1.00, -8.0],
]
const NEAR_ARM_SCALE := 0.25
## Overlapping action. The sack is driven by the bob, so it swings at twice the
## cycle rate, and it arrives late.
const BAG_KEYS := [
	[0.00, 0.0], [0.12, 9.0], [0.25, 0.0], [0.37, -9.0],
	[0.50, 0.0], [0.62, 9.0], [0.75, 0.0], [0.87, -9.0], [1.00, 0.0],
]
const BAG_LAG := 0.10
const STICK_KEYS := [
	[0.00, 0.0], [0.25, 3.0], [0.50, 0.0], [0.75, -3.0], [1.00, 0.0],
]
const STICK_LAG := 0.08

# --- idle pose tables (phase 0..1 over IDLE_CYCLE) --------------------------
# What a rig gives you for free: a breath, a weight shift, one glance.

## Amplitudes are in native art pixels on a 434 px figure, so divide by ~3.6
## for what the director sees at the 122 px game size. A first pass at
## life-accurate values (2-3 native px of breath) measured 1 px of head travel
## even on the 244 px review figure - invisible. These are pushed to roughly
## twice life, which is the usual storybook-animation cheat.
const IDLE_CHEST_KEYS := [[0.00, 0.0], [0.32, -2.6], [0.60, -1.4], [1.00, 0.0]]
## Positive is UP, same as HIPS_BOB_KEYS: the chest rises on the inhale.
const IDLE_CHEST_LIFT := [[0.00, 0.0], [0.32, 6.0], [0.60, 2.8], [1.00, 0.0]]
const IDLE_HIPS_Y := [[0.00, 0.0], [0.35, 1.2], [0.72, -0.6], [1.00, 0.0]]
const IDLE_HIPS_X := [[0.00, 0.0], [0.25, 3.5], [0.62, -3.5], [1.00, 0.0]]
const IDLE_HEAD := [
	[0.00, 0.0], [0.20, 1.8], [0.50, 1.4], [0.55, 5.0], [0.70, 4.6],
	[0.85, 0.6], [1.00, 0.0],
]
const IDLE_BAG := [[0.00, 0.0], [0.30, 5.0], [0.62, -4.0], [1.00, 0.0]]
const IDLE_ARM := [[0.00, 0.0], [0.34, -3.5], [0.68, 2.0], [1.00, 0.0]]
const IDLE_KNEE := [[0.00, 0.0], [0.36, -2.2], [0.70, 0.7], [1.00, 0.0]]
const IDLE_STILL := [[0.00, 0.0], [1.00, 0.0]]

var _skeleton: Skeleton2D
var _player: AnimationPlayer
var _bones: Dictionary = {}
var _parts: Dictionary = {}
var _rest_positions: Dictionary = {}
var _clip := "walk"


func _ready() -> void:
	# Godot #100881: never let physics interpolation near a Skeleton2D.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	build()


## Native art pixels of ground covered per cycle. Two steps.
static func cycle_distance_px() -> float:
	return STEP_PX * 2.0


## Native art pixels per second. Multiply by the rig's scale for screen speed.
static func walk_speed_px() -> float:
	return cycle_distance_px() / WALK_CYCLE


static func load_parts() -> Dictionary:
	var text := FileAccess.get_file_as_string(PARTS_PATH)
	assert(text != "", "spike parts manifest missing - run tools/spike/segment_fool_east.py")
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed is Dictionary, "spike parts manifest is not JSON")
	return parsed as Dictionary


func build() -> void:
	if _skeleton != null:
		return
	var manifest := load_parts()
	_parts = manifest["parts"]
	var origin: Vector2 = Vector2(manifest["origin"][0], manifest["origin"][1])

	_skeleton = Skeleton2D.new()
	_skeleton.name = "Skeleton"
	add_child(_skeleton)

	for entry in BONE_TREE:
		var bone_name: String = entry[0]
		var parent_name: String = entry[1]
		var part_key: String = entry[2]
		var pivot := _pivot_for(bone_name, part_key, origin)
		_rest_positions[bone_name] = pivot
		var parent_node: Node = _skeleton if parent_name == "" else _bones[parent_name]
		var parent_pivot: Vector2 = Vector2.ZERO
		if parent_name != "":
			parent_pivot = _rest_positions[parent_name]
		var bone := Bone2D.new()
		bone.name = bone_name
		bone.position = pivot - parent_pivot
		bone.rest = Transform2D(0.0, bone.position)
		parent_node.add_child(bone)
		_bones[bone_name] = bone
		if part_key != "":
			bone.add_child(_make_sprite(bone_name, part_key))

	# Bone2D length/angle only feed the editor gizmo and Polygon2D skinning,
	# neither of which a sprite cutout uses - but leaf bones warn every frame
	# unless they are told explicitly.
	for entry in BONE_TREE:
		var bone: Bone2D = _bones[entry[0]]
		bone.set_autocalculate_length_and_angle(false)
		var child_bone: Bone2D = null
		for child in bone.get_children():
			if child is Bone2D:
				child_bone = child
				break
		var span: Vector2 = child_bone.position if child_bone != null else Vector2(0, 24)
		bone.set_length(maxf(span.length(), 8.0))
		bone.set_bone_angle(span.angle() if span.length() > 0.01 else PI * 0.5)

	for index in DRAW_ORDER.size():
		var bone: Bone2D = _bones[DRAW_ORDER[index]]
		var sprite := bone.get_node_or_null("Art") as Sprite2D
		if sprite != null:
			sprite.z_index = index + 1

	_player = AnimationPlayer.new()
	_player.name = "Anim"
	add_child(_player)
	_player.root_node = _player.get_path_to(self)
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


func _make_sprite(bone_name: String, part_key: String) -> Sprite2D:
	var part: Dictionary = _parts[part_key]
	var sprite := Sprite2D.new()
	sprite.name = "Art"
	sprite.centered = false
	sprite.texture = load("res://art/spike/fool-cutout/" + str(part["file"]))
	sprite.offset = Vector2(part["offset"][0], part["offset"][1])
	if bone_name.begins_with("ArmFar") or bone_name.begins_with("LegFar"):
		sprite.modulate = FAR_TINT
	return sprite


# --- animation assembly ----------------------------------------------------

## Shift a phase table later in time, wrapping. This is how overlapping action
## is expressed here: the sack and the head run the same curve as the body, a
## fraction of a cycle behind it.
##
## Tables are written closed (the key at phase 1 repeats phase 0), so the
## duplicate endpoint is dropped before shifting and re-derived afterwards.
static func lag(keys: Array, amount: float) -> Array:
	var body: Array = keys.duplicate()
	if body.size() > 1 and is_equal_approx(float(body[body.size() - 1][0]), 1.0):
		body.remove_at(body.size() - 1)
	var shifted: Array = []
	for key in body:
		var phase := fposmod(float(key[0]) + amount, 1.0)
		if phase > 0.0001 and phase < 0.9999:
			shifted.append([phase, float(key[1])])
	# The value that lands on the loop seam is whatever the source table held
	# `amount` of a cycle earlier.
	var seam := sample_curve(keys, fposmod(-amount, 1.0))
	shifted.append([0.0, seam])
	shifted.append([1.0, seam])
	shifted.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	return shifted


static func scaled(keys: Array, factor: float) -> Array:
	var out: Array = []
	for key in keys:
		out.append([float(key[0]), float(key[1]) * factor])
	return out


func _add_rotation_track(anim: Animation, bone_name: String, keys: Array, cycle: float) -> void:
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "Skeleton/%s:rotation_degrees" % _bone_path(bone_name))
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	for key in keys:
		anim.track_insert_key(track, float(key[0]) * cycle, FORWARD * float(key[1]))


# --- leg IK -----------------------------------------------------------------

## Where the hips bone sits at this phase, in rig space (the ground point is
## the origin and y grows downwards). Mirrors what the Hips tracks will do.
static func hips_transform(phase: float) -> Transform2D:
	var offset := Vector2(sample_curve(HIPS_SURGE_KEYS, phase), -sample_curve(HIPS_BOB_KEYS, phase))
	var rest := Vector2(0.0, -HIP_HEIGHT_PX)
	return Transform2D(deg_to_rad(FORWARD * sample_curve(HIPS_TILT_KEYS, phase)), rest + offset)


## The ankle target for one leg at one phase, in rig space.
## Both feet track the body's centre line: in a side view the two hip pivots
## are only 36 px apart because the painting draws the legs side by side, and
## letting each foot orbit its own hip would give a 0.66 m stance.
static func foot_target(phase: float) -> Vector2:
	return Vector2(sample_curve(FOOT_X_KEYS, phase), -sample_curve(FOOT_H_KEYS, phase))


## Two-bone IK. Returns [thigh_world_rad, shin_world_rad], choosing the
## knee-forward solution - the only one a human leg can reach.
static func solve_leg(hip: Vector2, ankle: Vector2, thigh_len: float, shin_len: float) -> Array:
	var delta := ankle - hip
	var reach := clampf(delta.length(), absf(thigh_len - shin_len) + 0.5, thigh_len + shin_len - 0.5)
	var to_ankle := delta.angle()
	var cosine := (thigh_len * thigh_len + reach * reach - shin_len * shin_len) / (
		2.0 * thigh_len * reach
	)
	var spread := acos(clampf(cosine, -1.0, 1.0))
	# y grows downwards, so subtracting the spread swings the knee towards +x,
	# which is forward for this east-facing rig.
	var thigh := to_ankle - spread
	var knee := hip + Vector2(thigh_len, 0.0).rotated(thigh)
	return [thigh, (ankle - knee).angle()]


## Bake one leg's solved angles into rotation tracks.
##
## Every bone in this rig has a zero rest rotation, so a bone's world rotation
## is just the sum of its own and its ancestors'. That is what makes unwinding
## the IK result into local bone rotations subtraction instead of a matrix
## chain.
##
## Production update: the shin bone now carries a fused shin+boot part (see
## BONE_TREE), so there is no separate ankle bone/track any more - the boot
## rides the shin's IK-solved angle rigidly. That trades away the old rig's
## heel-strike roll (FOOT_PITCH_KEYS), which is an intentional, named
## simplification: see the anim-parts report for the residual-gap note.
func _add_leg_tracks(anim: Animation, side: String, phase_offset: float) -> void:
	var hip_local: Vector2 = _bones["Leg%sThigh" % side].position
	var knee_local: Vector2 = _bones["Leg%sShin" % side].position
	var thigh_len := knee_local.length()
	var shin_len := SHIN_LEN
	var thigh_rest := knee_local.angle()
	# No ankle child left to read a "natural" shin direction from; the fused
	# shin+boot part is drawn hanging straight from the knee, continuing the
	# thigh's own rest direction, so reuse thigh_rest as the shin's too.
	var shin_rest := thigh_rest

	var thigh_keys: Array = []
	var knee_keys: Array = []
	for index in LEG_SAMPLES + 1:
		var phase := float(index) / float(LEG_SAMPLES)
		var leg_phase := fposmod(phase + phase_offset, 1.0)
		var hips := hips_transform(phase)
		var hip_world: Vector2 = hips * hip_local
		var solved := solve_leg(hip_world, foot_target(leg_phase), thigh_len, shin_len)
		var hips_rotation: float = hips.get_rotation()
		var thigh_world: float = solved[0] - thigh_rest
		var shin_world: float = solved[1] - shin_rest
		thigh_keys.append([phase, thigh_world - hips_rotation])
		knee_keys.append([phase, shin_world - thigh_world])

	_add_solved_track(anim, "Leg%sThigh" % side, thigh_keys)
	_add_solved_track(anim, "Leg%sShin" % side, knee_keys)


## Solved angles go in as radians, already signed, and interpolate linearly:
## the samples are 15 ms apart, and cubic would round off the heel strike.
func _add_solved_track(anim: Animation, bone_name: String, keys: Array) -> void:
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "Skeleton/%s:rotation" % _bone_path(bone_name))
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
	anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	for key in keys:
		anim.track_insert_key(track, float(key[0]) * WALK_CYCLE, float(key[1]))


func _add_position_track(
	anim: Animation, bone_name: String, x_keys: Array, y_keys: Array, cycle: float
) -> void:
	var rest: Vector2 = _bones[bone_name].position
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, "Skeleton/%s:position" % _bone_path(bone_name))
	anim.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	anim.value_track_set_update_mode(track, Animation.UPDATE_CONTINUOUS)
	var phases: Array = []
	for key in x_keys:
		phases.append(float(key[0]))
	for key in y_keys:
		if not phases.has(float(key[0])):
			phases.append(float(key[0]))
	phases.sort()
	for phase in phases:
		# y is negated: the tables say "positive is up", Godot says y grows down.
		var value := rest + Vector2(sample_curve(x_keys, phase), -sample_curve(y_keys, phase))
		anim.track_insert_key(track, phase * cycle, value)


## Piecewise-linear read of a phase table. Shared with the south rig.
static func sample_curve(keys: Array, phase: float) -> float:
	if keys.is_empty():
		return 0.0
	if phase <= float(keys[0][0]):
		return float(keys[0][1])
	for index in range(1, keys.size()):
		var here: Array = keys[index]
		if phase <= float(here[0]):
			var prev: Array = keys[index - 1]
			var span := float(here[0]) - float(prev[0])
			if span <= 0.0:
				return float(here[1])
			var t := (phase - float(prev[0])) / span
			return lerpf(float(prev[1]), float(here[1]), t)
	return float(keys[keys.size() - 1][1])


func _bone_path(bone_name: String) -> String:
	var chain: Array = [bone_name]
	var lookup: Dictionary = {}
	for entry in BONE_TREE:
		lookup[entry[0]] = entry[1]
	var current: String = lookup[bone_name]
	while current != "":
		chain.push_front(current)
		current = lookup[current]
	return "/".join(chain)


func _build_walk() -> Animation:
	var anim := Animation.new()
	anim.length = WALK_CYCLE
	anim.loop_mode = Animation.LOOP_LINEAR

	_add_position_track(anim, "Hips", HIPS_SURGE_KEYS, HIPS_BOB_KEYS, WALK_CYCLE)
	_add_rotation_track(anim, "Hips", HIPS_TILT_KEYS, WALK_CYCLE)
	_add_rotation_track(anim, "Spine", SPINE_KEYS, WALK_CYCLE)
	_add_rotation_track(anim, "Chest", CHEST_KEYS, WALK_CYCLE)
	_add_rotation_track(anim, "Head", lag(HEAD_KEYS, HEAD_LAG), WALK_CYCLE)

	_add_leg_tracks(anim, "Near", 0.0)
	_add_leg_tracks(anim, "Far", 0.5)

	# The near arm is holding the bindle: it counter-swings against its own
	# leg, but at a quarter amplitude - a grip adjusting, not a free arm.
	_add_rotation_track(
		anim, "ArmNearUpper", scaled(lag(ARM_SWING_KEYS, 0.5), NEAR_ARM_SCALE), WALK_CYCLE
	)
	_add_rotation_track(
		anim, "ArmNearLower", scaled(lag(ARM_ELBOW_KEYS, 0.5), NEAR_ARM_SCALE), WALK_CYCLE
	)

	# The far arm is now a real, purpose-drawn limb (not a silhouette), so it
	# gets the full free-swing the near arm can't: same phase relationship as
	# the near arm (it is the "free" counterpart swinging with the near leg,
	# per the original design note), but without NEAR_ARM_SCALE's grip-
	# adjustment damping.
	_add_rotation_track(anim, "ArmFarUpper", lag(ARM_SWING_KEYS, 0.5), WALK_CYCLE)
	_add_rotation_track(anim, "ArmFarLower", lag(ARM_ELBOW_KEYS, 0.5), WALK_CYCLE)

	_add_rotation_track(anim, "Stick", lag(STICK_KEYS, STICK_LAG), WALK_CYCLE)
	_add_rotation_track(anim, "BindleBag", lag(BAG_KEYS, BAG_LAG), WALK_CYCLE)
	return anim


func _build_idle() -> Animation:
	var anim := Animation.new()
	anim.length = IDLE_CYCLE
	anim.loop_mode = Animation.LOOP_LINEAR
	_add_position_track(anim, "Hips", IDLE_HIPS_X, IDLE_HIPS_Y, IDLE_CYCLE)
	_add_position_track(anim, "Chest", [], IDLE_CHEST_LIFT, IDLE_CYCLE)
	_add_rotation_track(anim, "Chest", IDLE_CHEST_KEYS, IDLE_CYCLE)
	_add_rotation_track(anim, "Head", lag(IDLE_HEAD, 0.04), IDLE_CYCLE)
	_add_rotation_track(anim, "BindleBag", lag(IDLE_BAG, 0.09), IDLE_CYCLE)
	_add_rotation_track(anim, "Stick", scaled(IDLE_BAG, 0.35), IDLE_CYCLE)
	_add_rotation_track(anim, "ArmNearUpper", scaled(IDLE_ARM, -0.6), IDLE_CYCLE)
	_add_rotation_track(anim, "ArmFarUpper", scaled(IDLE_ARM, 0.45), IDLE_CYCLE)
	# Every leg bone has to be written, not just the knees: the walk drives the
	# thighs, so an idle that ignores them leaves the Fool standing still with
	# one leg still mid-stride. There is no separate foot bone any more (the
	# boot is fused onto the shin - see BONE_TREE), so the knee sway is the
	# only leg motion idle needs.
	_add_rotation_track(anim, "LegNearThigh", IDLE_STILL, IDLE_CYCLE)
	_add_rotation_track(anim, "LegFarThigh", IDLE_STILL, IDLE_CYCLE)
	_add_rotation_track(anim, "LegNearShin", IDLE_KNEE, IDLE_CYCLE)
	_add_rotation_track(anim, "LegFarShin", scaled(IDLE_KNEE, 0.7), IDLE_CYCLE)
	return anim


# --- driving ----------------------------------------------------------------

func clip_length(clip_name: String) -> float:
	return WALK_CYCLE if clip_name == "walk" else IDLE_CYCLE


## Pose the rig at an absolute time. Deterministic: the capture harness scrubs
## instead of letting the player free-run, so a 30 fps GIF is exactly 30 fps
## regardless of what the window managed to render.
func scrub(clip_name: String, time: float) -> void:
	build()
	if clip_name != _clip:
		_clip = clip_name
		_player.play(_clip)
	_player.pause()
	_player.seek(fposmod(time, clip_length(clip_name)), true)


func play_live(clip_name: String) -> void:
	build()
	_clip = clip_name
	_player.play(clip_name)


func bone(bone_name: String) -> Bone2D:
	build()
	return _bones.get(bone_name, null)


func skeleton() -> Skeleton2D:
	build()
	return _skeleton


func animation_player() -> AnimationPlayer:
	build()
	return _player
