extends SceneTree

## The animation spike's craft targets, as assertions.
##
## The spike exists to be judged by eye, but "it looks bouncier" is not a
## finding. These checks pin the numbers the walk-defect review asked for, so
## the GIFs can be argued about on top of facts rather than instead of them:
##
##   * the hips really move vertically, by >= 2.5% of the figure height;
##   * the bob happens twice per cycle (once per step), lowest just after each
##     contact - the shipping painted cycle bobs once, which reads as a limp;
##   * the timing is non-uniform - contacts are held;
##   * travel is stride-matched, so a planted foot cannot skate;
##   * the bindle bag lags the body (overlapping action) instead of being
##     welded to it;
##   * spike B's four painted frames hold their contacts 1.5x as long as their
##     passing frames, at the same cycle length as the rig.
##
## Nothing here touches the shipping Cliff scene or its tests.

const RigScript := preload("res://scripts/spike/fool_cutout_rig.gd")
const PaintedScript := preload("res://scripts/spike/painted_walk.gd")
const StageScript := preload("res://scripts/spike/spike_stage.gd")
const SouthScript := preload("res://scripts/spike/fool_cutout_rig_south.gd")

const SAMPLES := 240

## The rest-pose gate. Every attachment on this rig is placed by measurement
## against the direction stills, and a placement bug is invisible in a bone
## graph: the first purpose-drawn pass shipped a Fool wearing his bindle as a
## backpack with the stick buried inside the torso, and every structural check
## above still passed. So the assembled rest pose is compared to the painting
## it was cut from. 0.88 leaves room for the parts that are genuinely drawn at
## slightly different proportions; anything that moves a limb, swaps a hand or
## re-orders a layer falls well below it.
const REST_IOU_MIN := 0.88
const EAST_STILL := "res://art/game-ready-sprites-v1/frames/fool/directions/east.png"
const SOUTH_STILL := "res://art/game-ready-sprites-v1/frames/fool/directions/south.png"

var _all_passed := true
var _frame := 0


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/spike/anim_spike.tscn")
	root.add_child(packed.instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false

	var rig: FoolCutoutRig = RigScript.new()
	root.add_child(rig)
	rig.build()

	_check_parts()
	_check_rig_structure(rig)
	_check_bob(rig)
	_check_timing()
	_check_stride(rig)
	_check_skate(rig)
	_check_overlap(rig)
	_check_rest_pose(rig)
	_check_south()
	_check_painted()
	_check_stage()

	_finish()
	return true


func _check_parts() -> void:
	var manifest := RigScript.load_parts()
	var parts: Dictionary = manifest["parts"]
	var expected := [
		"head", "torso", "arm_upper", "arm_lower", "stick", "bag",
		"leg_near_thigh", "leg_near_shin",
		"leg_far_thigh", "leg_far_shin",
		"arm_far_upper", "arm_far_lower",
		"knee_cap_near", "knee_cap_far",
	]
	var missing := []
	for key in expected:
		if not parts.has(key):
			missing.append(key)
		elif not ResourceLoader.exists("res://art/spike/fool-cutout/" + str(parts[key]["file"])):
			missing.append(key + " (texture)")
	_ok(missing.is_empty(), "every cutout part is present (%s)" % str(missing))


func _check_rig_structure(rig: FoolCutoutRig) -> void:
	_ok(rig.skeleton() != null, "the rig builds a Skeleton2D")
	_ok(
		rig.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF,
		"physics interpolation is off on the rig (Godot #100881)"
	)
	_ok(
		rig.animation_player().callback_mode_process
			== AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE,
		"the rig animates on process, never on physics"
	)
	var chain := ["Hips", "Spine", "Chest", "Head", "Stick", "BindleBag"]
	var present := true
	for bone_name in chain:
		present = present and rig.bone(bone_name) != null
	_ok(present, "the spine chain hips -> spine -> chest -> head exists")
	var legs := true
	for side in ["Near", "Far"]:
		for segment in ["Thigh", "Shin"]:
			legs = legs and rig.bone("Leg%s%s" % [side, segment]) != null
		legs = legs and rig.bone("KneeCap%s" % side) != null
	_ok(legs, "both legs have thigh and shin bones plus a knee-cap overlay")
	# Production update: the far arm is now a real, purpose-drawn limb.
	_ok(
		rig.bone("ArmFarUpper") != null and rig.bone("ArmFarLower") != null,
		"the far arm is a real purpose-drawn limb, not faked from the near arm's drawing"
	)
	_ok(
		rig.animation_player().get_animation_list().size() == 2,
		"the rig carries both a walk and an idle"
	)


## Sample the hip's world height across a cycle. This is the headline number.
func _check_bob(rig: FoolCutoutRig) -> void:
	var heights: Array[float] = []
	for index in SAMPLES:
		var t := float(index) / float(SAMPLES) * FoolCutoutRig.WALK_CYCLE
		rig.scrub("walk", t)
		heights.append(rig.bone("Hips").global_position.y)

	# y grows downwards, so the largest y is the body at its LOWEST.
	var top_y: float = heights.min()
	var bottom_y: float = heights.max()
	var range_px := bottom_y - top_y
	var percent := range_px / FoolCutoutRig.FIGURE_HEIGHT_PX * 100.0
	_ok(
		percent >= 2.5,
		"hips travel %.1f px = %.2f%% of the figure (target >= 2.5%%)" % [range_px, percent]
	)

	# Two dips per cycle: one per step. The shipping painted cycle has one.
	var dips := 0
	for index in SAMPLES:
		var prev := heights[posmod(index - 1, SAMPLES)]
		var here := heights[index]
		var next := heights[posmod(index + 1, SAMPLES)]
		if here > prev and here >= next:  # y down, so a maximum is a low point
			dips += 1
	_ok(dips == 2, "the body drops twice per cycle, once per step (%d found)" % dips)

	# ... and it is lowest shortly after a contact, not at the passing position.
	var lowest_phase := float(heights.find(bottom_y)) / float(SAMPLES)
	_ok(
		lowest_phase < 0.25 or (lowest_phase > 0.5 and lowest_phase < 0.75),
		"the lowest point falls in a stance phase (phase %.2f)" % lowest_phase
	)


## Non-uniform timing, expressed where this rig actually keeps it: the foot's
## path. The stance half is a straight line at ground speed; the swing half has
## to slow out of toe-off, rush through the middle and ease into contact.
func _check_timing() -> void:
	var keys: Array = FoolCutoutRig.FOOT_X_KEYS
	var shortest := INF
	var longest := 0.0
	for index in range(1, keys.size()):
		var gap: float = float(keys[index][0]) - float(keys[index - 1][0])
		shortest = minf(shortest, gap)
		longest = maxf(longest, gap)
	_ok(
		longest / shortest >= 1.5,
		"the foot path is non-uniformly keyed: longest gap / shortest = %.1f"
			% (longest / shortest)
	)

	# Slow in, slow out: the swinging foot's peak speed must beat its average,
	# or the leg is being dragged round at a constant rate.
	# Relative to the body the swinging foot covers one step in half a cycle.
	var average := FoolCutoutRig.STEP_PX / (0.5 * FoolCutoutRig.WALK_CYCLE)
	var peak := 0.0
	var slowest := INF
	var step := 0.01
	for index in 50:
		var phase := 0.5 + float(index) * step
		var here := FoolCutoutRig.foot_target(phase).x
		var next := FoolCutoutRig.foot_target(phase + step).x
		var speed := (next - here) / (step * FoolCutoutRig.WALK_CYCLE)
		peak = maxf(peak, speed)
		slowest = minf(slowest, speed)
	_ok(
		peak / average >= 1.4,
		"the swing eases in and out: peak %.0f px/s vs %.0f average (%.2fx)"
			% [peak, average, peak / average]
	)
	_ok(
		slowest >= -1.0,
		"the swinging foot never travels backwards (min %.0f px/s)" % slowest
	)

	# Stance is a dead-straight line at exactly the ground speed.
	var stance_start := FoolCutoutRig.foot_target(0.0).x
	var stance_end := FoolCutoutRig.foot_target(0.5).x
	_ok(
		is_equal_approx(stance_start - stance_end, FoolCutoutRig.cycle_distance_px() * 0.5),
		"stance carries the foot exactly one step: %.1f px" % (stance_start - stance_end)
	)
	_ok(
		FoolCutoutRig.WALK_CYCLE >= 0.5 and FoolCutoutRig.WALK_CYCLE <= 0.6,
		"one gait cycle is %.2f s" % FoolCutoutRig.WALK_CYCLE
	)


func _check_stride(rig: FoolCutoutRig) -> void:
	var per_cycle := FoolCutoutRig.cycle_distance_px()
	var speed := FoolCutoutRig.walk_speed_px()
	_ok(
		is_equal_approx(speed * FoolCutoutRig.WALK_CYCLE, per_cycle),
		"travel is stride-matched: %.0f px/s x %.2f s = %.0f px per cycle"
			% [speed, FoolCutoutRig.WALK_CYCLE, per_cycle]
	)
	# A step should be a plausible fraction of the leg, or the feet will skate
	# however carefully the cycle is keyed.
	# The rest hip height, not the animated one - _check_bob leaves the rig posed.
	var hip_height := FoolCutoutRig.HIP_HEIGHT_PX
	var ratio := FoolCutoutRig.STEP_PX / hip_height
	_ok(
		ratio > 0.6 and ratio < 0.9,
		"step length is %.2f x leg length (%.0f px leg)" % [ratio, hip_height]
	)


## Foot skate, measured rather than felt.
##
## On the treadmill the ground moves at `walk_speed_px()`. A foot that is
## planted must therefore travel backwards, relative to the body, by exactly
## one step length over its stance phase. Anything else is the boot sliding.
## There is no ankle bone any more (the boot is fused onto the shin - see
## BONE_TREE); reconstruct the ankle's world x from the shin bone's global
## transform plus its fixed SHIN_LEN, the same way the rig's own IK solve
## does internally.
##
## The shin's baked rotation is solved_angle - shin_rest (see
## _add_leg_tracks), where shin_rest is the shin's own rest-direction angle
## as drawn in rig space; add it back to recover the true world angle before
## rotating the fixed-length shin vector. shin_rest equals the shin bone's
## own local (rest) position angle, since fool_cutout_rig.gd defines it as
## thigh_rest = knee_local.angle() and reuses that same value for the shin.
func _ankle_x(rig: FoolCutoutRig) -> float:
	var shin := rig.bone("LegNearShin")
	var shin_rest := shin.position.angle()
	var true_shin_angle := shin.global_rotation + shin_rest
	var ankle := shin.global_position + Vector2(FoolCutoutRig.SHIN_LEN, 0.0).rotated(
		true_shin_angle
	)
	return ankle.x


func _check_skate(rig: FoolCutoutRig) -> void:
	# Stance for the near leg runs from heel strike to toe-off.
	var stance_end := 0.50
	rig.scrub("walk", 0.0)
	var start_x := _ankle_x(rig)
	rig.scrub("walk", stance_end * FoolCutoutRig.WALK_CYCLE)
	var end_x := _ankle_x(rig)
	var travelled := start_x - end_x
	var ideal := FoolCutoutRig.cycle_distance_px() * stance_end
	var error := absf(travelled - ideal) / ideal * 100.0
	_ok(
		error < 8.0,
		"planted foot tracks the ground: %.1f px over stance vs %.1f ideal (%.1f%% off)"
			% [travelled, ideal, error]
	)
	# And it must always go backwards - never pause or creep forward.
	var monotonic := true
	var previous := start_x
	for index in range(1, 17):
		var phase := stance_end * float(index) / 16.0
		rig.scrub("walk", phase * FoolCutoutRig.WALK_CYCLE)
		var here := _ankle_x(rig)
		if here > previous + 0.5:
			monotonic = false
		previous = here
	_ok(monotonic, "the planted foot never creeps forward during stance")


func _check_overlap(rig: FoolCutoutRig) -> void:
	_ok(FoolCutoutRig.BAG_LAG > 0.0, "the bindle bag lags the body by %.2f of a cycle"
		% FoolCutoutRig.BAG_LAG)
	var swing := 0.0
	var at_rest := true
	for index in 60:
		var t := float(index) / 60.0 * FoolCutoutRig.WALK_CYCLE
		rig.scrub("walk", t)
		swing = maxf(swing, absf(rig.bone("BindleBag").rotation_degrees))
		if not is_zero_approx(rig.bone("BindleBag").rotation_degrees):
			at_rest = false
	_ok(not at_rest and swing > 4.0, "the bag actually swings (peak %.1f deg)" % swing)

	# The idle is not a freeze frame either.
	var head_range := 0.0
	var lowest := INF
	var highest := -INF
	for index in 80:
		rig.scrub("idle", float(index) / 80.0 * FoolCutoutRig.IDLE_CYCLE)
		var y := rig.bone("Chest").global_position.y
		lowest = minf(lowest, y)
		highest = maxf(highest, y)
		head_range = maxf(head_range, absf(rig.bone("Head").rotation_degrees))
	_ok(highest - lowest > 1.0, "the idle breathes (chest moves %.1f px)" % (highest - lowest))
	_ok(head_range > 1.0, "the idle glances (head turns %.1f deg)" % head_range)


## Composite the rig's own rest pose the way the renderer will: every sprite's
## texture, at the bone's rest world position plus the sprite's offset, in the
## rig's own draw order.
func _rest_silhouette(rig: Node2D, draw_order: Array, manifest: Dictionary) -> Image:
	rig.call("pose_rest")
	var crop: Array = manifest["crop"]
	var origin := Vector2(float(manifest["origin"][0]), float(manifest["origin"][1]))
	var canvas := Image.create(
		int(crop[2]) - int(crop[0]), int(crop[3]) - int(crop[1]), false, Image.FORMAT_RGBA8
	)
	for bone_name in draw_order:
		var bone: Bone2D = rig.call("bone", bone_name)
		if bone == null:
			continue
		var sprite := bone.get_node_or_null("Art") as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var art := Image.load_from_file(sprite.texture.resource_path)
		var at := bone.global_position + sprite.offset + origin
		canvas.blend_rect(
			art, Rect2i(Vector2i.ZERO, art.get_size()),
			Vector2i(roundi(at.x), roundi(at.y))
		)
	return canvas


func _still_region(path: String, manifest: Dictionary) -> Image:
	var crop: Array = manifest["crop"]
	return Image.load_from_file(path).get_region(Rect2i(
		int(crop[0]), int(crop[1]), int(crop[2]) - int(crop[0]), int(crop[3]) - int(crop[1])
	))


func _alpha_iou(a: Image, b: Image) -> float:
	var intersection := 0
	var union := 0
	for y in a.get_height():
		for x in a.get_width():
			var in_a := a.get_pixel(x, y).a > 0.19
			var in_b := b.get_pixel(x, y).a > 0.19
			if in_a or in_b:
				union += 1
				if in_a and in_b:
					intersection += 1
	return float(intersection) / maxf(float(union), 1.0)


func _check_rest_pose(east: FoolCutoutRig) -> void:
	var east_iou := _alpha_iou(
		_rest_silhouette(east, FoolCutoutRig.DRAW_ORDER, RigScript.load_parts()),
		_still_region(EAST_STILL, RigScript.load_parts())
	)
	_ok(
		east_iou >= REST_IOU_MIN,
		"east rest pose matches the still: silhouette IoU %.3f (>= %.2f)"
			% [east_iou, REST_IOU_MIN]
	)

	var south: FoolCutoutRigSouth = SouthScript.new()
	root.add_child(south)
	south.build()
	var south_iou := _alpha_iou(
		_rest_silhouette(south, FoolCutoutRigSouth.DRAW_ORDER, SouthScript.load_parts()),
		_still_region(SOUTH_STILL, SouthScript.load_parts())
	)
	_ok(
		south_iou >= REST_IOU_MIN,
		"south rest pose matches the still: silhouette IoU %.3f (>= %.2f)"
			% [south_iou, REST_IOU_MIN]
	)
	south.queue_free()

	# The bindle is the attachment that went wrong, so pin it directly: the bag
	# hangs BEHIND the shoulder line and the stick is drawn in FRONT of the
	# tunic, not buried behind it.
	east.call("pose_rest")
	var bag := east.bone("BindleBag")
	var chest := east.bone("Chest")
	_ok(
		bag.global_position.x < chest.global_position.x - 20.0,
		"the bindle bag hangs behind the shoulder (%.0f px back of the chest)"
			% (chest.global_position.x - bag.global_position.x)
	)
	var order: Array = FoolCutoutRig.DRAW_ORDER
	_ok(
		order.find("Stick") > order.find("Torso")
			and order.find("Stick") < order.find("ArmNearLower"),
		"the stick is drawn over the tunic and under the fist that grips it"
	)
	_ok(
		order.find("KneeCapNear") < order.find("LegNearThigh")
			and order.find("KneeCapFar") < order.find("LegFarThigh"),
		"the knee caps are gap fillers behind the limbs, not pads in front"
	)


## The south facing: the cutout approach on the case that should break it.
func _check_south() -> void:
	var rig: FoolCutoutRigSouth = SouthScript.new()
	root.add_child(rig)
	rig.build()

	var bones := [
		"Hips", "Chest", "Head",
		"LegLeftThigh", "KneeCapLeft", "FootLeft",
		"LegRightThigh", "KneeCapRight", "FootRight",
		"ArmLeftUpper", "ArmLeftLower", "ArmRightUpper", "ArmRightLower",
	]
	var present := true
	for bone_name in bones:
		present = present and rig.bone(bone_name) != null
	_ok(present, "the south rig builds its own skeleton (thigh+boot legs, upper/lower arms, knee caps)")
	_ok(
		rig.clip_length("walk") == FoolCutoutRig.WALK_CYCLE,
		"south runs the east rig's timing exactly (%.2f s)" % rig.clip_length("walk")
	)

	# Cheat 1: the bob does the work. Same curve, same amplitude as east.
	var top_y := INF
	var bottom_y := -INF
	var stretch := 0.0
	var flat := true
	for index in 120:
		rig.scrub("walk", float(index) / 120.0 * FoolCutoutRig.WALK_CYCLE)
		var y: float = rig.bone("Hips").global_position.y
		top_y = minf(top_y, y)
		bottom_y = maxf(bottom_y, y)
		stretch = maxf(stretch, absf(rig.bone("Chest").scale.y - 1.0))
		if not is_equal_approx(rig.bone("Chest").scale.y, 1.0):
			flat = false
	var percent := (bottom_y - top_y) / FoolCutoutRigSouth.FIGURE_HEIGHT_PX * 100.0
	_ok(percent >= 2.5, "south hips travel %.2f%% of the figure" % percent)

	# Cheat 2: a scale pulse instead of a silhouette change.
	_ok(not flat and stretch > 0.005, "the torso pulses %.1f%% through the passing position"
		% (stretch * 100.0))

	# Cheat 3: the stride is depth, and the two legs are in antiphase.
	var left_depth: Array[float] = []
	var right_depth: Array[float] = []
	for index in 60:
		rig.scrub("walk", float(index) / 60.0 * FoolCutoutRig.WALK_CYCLE)
		left_depth.append(rig.bone("LegLeftThigh").position.y)
		right_depth.append(rig.bone("LegRightThigh").position.y)
	var depth_range: float = left_depth.max() - left_depth.min()
	_ok(depth_range > 15.0, "a swung leg moves %.0f px of screen depth" % depth_range)
	var left_mid: float = (left_depth.max() + left_depth.min()) * 0.5
	var right_mid: float = (right_depth.max() + right_depth.min()) * 0.5
	var antiphase := true
	for index in 60:
		# Sampled off the crossover points, one leg must always be forward of
		# its own midpoint while the other is behind.
		if index % 15 != 7:
			continue
		var left_ahead: bool = left_depth[index] > left_mid
		var right_ahead: bool = right_depth[index] > right_mid
		if left_ahead == right_ahead:
			antiphase = false
	_ok(antiphase, "the two legs are half a cycle apart")

	# Cheat 4: feet are swapped drawings, not rotated bones.
	var seen := {}
	for index in 60:
		rig.scrub("walk", float(index) / 60.0 * FoolCutoutRig.WALK_CYCLE)
		var sprite := rig.bone("FootLeft").get_node("Art") as Sprite2D
		seen[sprite.texture.resource_path] = true
	_ok(
		seen.size() >= 2,
		"the foot swaps between %d drawn positions (hybrid frame + rig)" % seen.size()
	)
	rig.queue_free()


func _check_painted() -> void:
	var durations := PaintedWalk.frame_durations()
	var total := 0.0
	for duration in durations:
		total += duration
	_ok(
		is_equal_approx(total, PaintedWalk.CYCLE),
		"the painted cycle is %.2f s, same as the rig" % total
	)
	var contact := durations[0]
	var passing := durations[1]
	_ok(
		is_equal_approx(contact / passing, PaintedWalk.CONTACT_RATIO),
		"painted contacts are held %.2fx the passing frames" % (contact / passing)
	)
	var seen := {}
	for index in 120:
		seen[PaintedWalk.frame_at(float(index) / 120.0 * PaintedWalk.CYCLE)] = true
	_ok(seen.size() == 4, "all four painted frames still play (%d seen)" % seen.size())

	# Fidelity variants are real resamples, not just a scale factor.
	var control: PaintedWalk = PaintedScript.new()
	control.figure_height = 122.0
	root.add_child(control)
	control.build()
	var small: PaintedWalk = PaintedScript.new()
	small.figure_height = 49.0
	root.add_child(small)
	small.build()
	control.set_frame(0)
	small.set_frame(0)
	var big_px := control.sprite().texture.get_width()
	var small_px := small.sprite().texture.get_width()
	_ok(
		small_px < big_px and is_equal_approx(control.sprite().scale.x, 1.0),
		"lowered fidelity really removes pixels (%d px cell vs %d px), drawn 1:1"
			% [small_px, big_px]
	)
	_ok(
		is_equal_approx(control.speed_px() / 122.0, small.speed_px() / 49.0),
		"every fidelity variant walks at the same stride-to-height ratio"
	)
	control.queue_free()
	small.queue_free()


func _check_stage() -> void:
	var stage := root.find_child("AnimSpike", true, false) as Node2D
	_ok(stage != null, "the spike scene boots")
	if stage == null:
		return
	for layout in StageScript.LAYOUTS.keys():
		stage.call("configure", layout)
	_ok(true, "all %d comparison layouts configure" % StageScript.LAYOUTS.size())
	stage.call("configure", "compare")
	stage.call("scrub", 0.37)
	var panels: Array = stage.call("panels")
	_ok(panels.size() == 2, "the side-by-side layout builds two panels")
	if panels.size() == 2:
		_ok(
			is_equal_approx(float(panels[0]["figure_height"]), float(panels[1]["figure_height"])),
			"the money shot compares them at the same on-screen height"
		)
		var ratio_a: float = float(panels[0]["speed"]) / float(panels[0]["figure_height"])
		var ratio_b: float = float(panels[1]["speed"]) / float(panels[1]["figure_height"])
		_ok(
			absf(ratio_a - ratio_b) < 0.01,
			"both panels travel at the same stride-matched speed (%.1f vs %.1f px/s)"
				% [panels[0]["speed"], panels[1]["speed"]]
		)


func _ok(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		print("FAIL: " + description)
		_all_passed = false


func _finish() -> void:
	if _all_passed:
		print("SPIKE RIG TEST: PASS")
		quit(0)
	else:
		print("SPIKE RIG TEST: FAIL")
		quit(1)
