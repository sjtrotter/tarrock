extends RefCounted
class_name PoseStepper

## SPIKE C: samples a walk cycle's continuous playback time onto a small,
## fixed number of held poses per cycle - "animate on Ns" - biased so the
## contact poses hold longer than the swing poses, the way a hand-drawn walk
## does it.
##
## Built for the anim-stepped spike (the director found the rig's continuous
## interpolation "too mechanical"; this is what turns that into a comparison
## instead of an argument). Consumed by scripts/spike/stepped_walk_stage.gd,
## which drives fool_cutout_rig.gd's `scrub(clip, time)` with the HELD time
## this returns instead of the true continuous time - the walker's on-screen
## POSITION still advances every frame, only the POSE freezes between holds.
##
## The walk cycle's two contacts sit at phase 0.0 and 0.5 (see
## fool_cutout_rig.gd's FOOT_X_KEYS docstring: "phase 0 = the near foot's
## heel strike", and the far foot mirrors it a half cycle later). Both halves
## are built with the same pattern, so the result is symmetric: the interval
## immediately AFTER each contact sample is stretched by HOLD_BIAS relative
## to every other interval, then the rest of the half-cycle is divided evenly.
##
## `steps` must be even (one contact sample per half-cycle) and >= 2. This is
## a spike, not a tool for every future gait - the bias is a hard-coded
## constant rather than one more knob nobody would ever tune per-call.

const HOLD_BIAS := 1.5


## The sample-anchor phases (0..1, ascending, first entry always 0.0) for
## `steps` held poses across one cycle.
static func sample_phases(steps: int) -> Array[float]:
	assert(steps >= 2 and steps % 2 == 0, "PoseStepper needs an even step count >= 2")
	var half_count := steps / 2  # samples in one half-cycle, including its contact
	var weights: Array[float] = [HOLD_BIAS]
	for _i in half_count - 1:
		weights.append(1.0)
	var total := 0.0
	for w in weights:
		total += w
	var half_phases: Array[float] = []
	var acc := 0.0
	for w in weights:
		half_phases.append(acc / total * 0.5)
		acc += w
	var phases: Array[float] = []
	for p in half_phases:
		phases.append(p)
	for p in half_phases:
		phases.append(p + 0.5)
	return phases


## The held pose for continuous time `t` on a `cycle`-second loop, sampled at
## `steps` poses per cycle (`steps <= 0` disables stepping - returns `t`
## itself, i.e. smooth/continuous, so callers can treat "off" uniformly).
## Returns {"time": <time to pose the rig at>, "index": <which of the `steps`
## held poses is active - stable for the whole hold, only changes when the
## pose does; used to key the jitter test's per-pose offsets>}.
static func held_pose(t: float, cycle: float, steps: int) -> Dictionary:
	if steps <= 0:
		return {"time": t, "index": -1}
	var phases := sample_phases(steps)
	var phase := fposmod(t / cycle, 1.0)
	var index := 0
	for i in phases.size():
		if phases[i] <= phase + 1e-6:
			index = i
	return {"time": phases[index] * cycle, "index": index}
