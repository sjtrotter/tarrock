class_name MovesetController
extends RefCounted

## The Bindle, as a state machine: the whole player moveset with no nodes in it.
##
## `docs/design/combat.md` is canon for every rule here:
##
##   * §The Bindle - a **three-hit light string**, a **heavy** crowd sweep, a
##     **charged heavy** that is the *stagger launcher*, and a **running attack**
##     lunge. No aerial moveset, because there is no jump verb.
##   * §Focus - in Focus the dodge input is **directional**: forward or neutral is
##     the roll, left/right is the side-hop, backward is the **grand backflip**
##     ("roughly 1.5 body-widths"). Out of Focus the same input is the plain roll.
##     All three share the roll's i-frame rules and all three can trigger Fool's
##     Chance.
##   * §Defense - the roll's i-frames "cover the commit window"; the block-step is a
##     hop-guard that absorbs a hit and repositions, **with no counter-window**.
##   * §Philosophy - "no combo-counter, no style meter, and no button-mash reward
##     loop": every action has a windup, an active frame and "recovery the player can
##     feel", and this controller is where that is made true. A committed state
##     accepts no input except the one continuation the string is allowed.
##
## **It is pure.** No `Node`, no `Input`, no `Engine`, no scene: `update()` is handed
## a `CombatInput` and a delta and answers with state, an `active_hit()`, a movement
## multiplier and a frame displacement. Everything that needs a tree - reading the
## buttons, moving the body, swinging a real `Hitbox` - is `FoolCombat`'s, one layer
## up. That is what lets the entire moveset be tested headlessly, frame by explicit
## frame, with no wall clock anywhere near it.
##
## **It allocates nothing per frame.** The four `HitSpec`s (three light, heavy,
## charged heavy, running attack) are built once in `_init` and handed back by
## reference; `frame_displacement()` returns a `Vector2`, which is a value. Nothing
## in `update()` constructs an object (`docs/design/technical.md` §Performance
## guardrails).
##
## **Time here is the Fool's own time, not the world's.** The caller decides what a
## delta means, which is exactly how `combat.md`'s Fool's Chance works: while the
## world runs at `slowmo_time_scale`, `FoolCombat` feeds this controller
## `delta / Engine.time_scale`, so the Fool "moves at normal speed relative to a
## slowed world" without this class knowing that slow motion exists.

## What the Fool is doing. `IDLE` is the only state that accepts a new action (the
## light string's continuation is the one exception - see `update()`).
enum State {
	## Free: walking, standing, strafing in Focus.
	IDLE,
	## First hit of the light string.
	LIGHT_1,
	## Second hit.
	LIGHT_2,
	## Third and last hit.
	LIGHT_3,
	## The wide crowd sweep.
	HEAVY,
	## Holding the heavy down, building toward the launcher.
	CHARGING,
	## The stagger launcher, released after a full charge.
	CHARGED_HEAVY,
	## The forward lunge, from a run.
	RUNNING_ATTACK,
	## The dodge roll: forward/neutral in Focus, and the only dodge out of it.
	DODGE_ROLL,
	## The Focus left/right strafing hop.
	SIDE_HOP,
	## The Focus back-dodge: the grand backflip.
	BACKFLIP,
	## The hop-guard.
	BLOCK_STEP,
}

## Where inside a state the Fool is. `combat.md` §Philosophy names all three.
enum Phase {
	## Telegraph. The hit is not out yet.
	WINDUP,
	## The hit window. `active_hit()` answers here and nowhere else.
	ACTIVE,
	## The part the player feels. Nothing may be cancelled out of it.
	RECOVERY,
}

## `_combo_index` when no light string is running.
const NO_COMBO := 0

## Half the width of the forward and backward dodge cones, in degrees. A quarter
## turn each way: forward is anything within 45 degrees of the facing, backward
## anything more than 135 away, and the two side quadrants are what is left. Even
## quarters are the only division that makes a stick's four intuitive pushes give the
## four dodges `combat.md` §Focus names, so it is a constant rather than a rules
## field - retuning it would not tune a dodge, it would move the dodges around.
const DODGE_CONE_HALF_DEGREES := 45.0

## The state changed. Both values are `State`.
signal state_changed(old_state: State, new_state: State)

## A hit window opened; `spec` is the same instance `active_hit()` will answer with.
signal hit_window_opened(spec: HitSpec)

## The hit window closed.
signal hit_window_closed()

## A dodge began. `kind` is `DODGE_ROLL`, `SIDE_HOP` or `BACKFLIP`.
signal dodge_started(kind: State)

## The heavy went down and the charge began.
signal charge_started()

## The heavy came up. `fully_charged` is what decides whether the release was the
## stagger launcher or a plain heavy.
signal charge_released(fully_charged: bool)

var _rules: CombatRules = null

var _state: State = State.IDLE
var _phase: Phase = Phase.WINDUP

## Seconds inside the current phase, and inside the current state. Dodges read the
## second one (i-frames are measured from the start of the dodge, not of a phase).
var _phase_time: float = 0.0
var _state_time: float = 0.0

## The controller's own clock, in the Fool's seconds. Only ever compared against
## itself - never against the wall clock, never against `Time`.
var _time: float = 0.0

## Which light hit the string is on, 1..3, or `NO_COMBO`.
var _combo_index: int = NO_COMBO

## Seconds left in which the next light input still chains. **Armed the moment a light
## hit starts**, not when its active frame opens, and counted down whatever the state
## is - so a press just after a hit's recovery ends still continues the string.
var _combo_window_left: float = 0.0

## True once this block-step's guard has eaten a hit. `combat.md` §Defense: the
## hop-guard "absorbs a hit and repositions" - one hit, not every hit that happens to
## arrive inside the window.
var _guard_spent: bool = false

## Seconds the heavy has been held this charge.
var _charge_time: float = 0.0

## Where the Fool is facing, unit length.
var _facing: Vector2 = Vector2.RIGHT

## The direction of the Focus target from the Fool, when Focus has one.
var _focus_target_dir: Vector2 = Vector2.ZERO
var _has_focus_target: bool = false

## The current dodge's direction and how far it still has to carry the Fool. The
## remaining distance is tracked rather than recomputed so the dodge covers exactly
## the rules' distance however the frames fall.
var _dodge_direction: Vector2 = Vector2.ZERO
var _dodge_distance_left: float = 0.0
var _dodge_speed: float = 0.0

## `_time` when the current (or last) dodge began. `-INF` until one has.
var _dodge_started_at: float = -INF

## This frame's displacement, computed at the end of `update()`.
var _frame_displacement: Vector2 = Vector2.ZERO

## The specs, allocated once. Index 0..2 are the light string's three hits.
var _light_specs: Array[HitSpec] = []
var _heavy_spec: HitSpec = null
var _charged_spec: HitSpec = null
var _running_spec: HitSpec = null


## Build the moveset over its tuning data. Every `HitSpec` is built here, once.
func _init(rules: CombatRules) -> void:
	_rules = rules
	if rules == null:
		push_error("MovesetController was built without its rules")
		return
	for index: int in CombatRules.LIGHT_STRING_HITS:
		_light_specs.append(
			HitSpec.new(
				HitSpec.Kind.LIGHT,
				rules.light_damage_at(index),
				HitSpec.Shape.ARC,
				rules.light_arc_degrees,
				rules.light_radius,
				false,
				0.0,
				rules.stagger_bonus_multiplier
			)
		)
	_heavy_spec = HitSpec.new(
		HitSpec.Kind.HEAVY,
		rules.heavy_damage,
		HitSpec.Shape.ARC,
		rules.heavy_arc_degrees,
		rules.heavy_radius,
		false,
		0.0,
		rules.stagger_bonus_multiplier
	)
	_charged_spec = HitSpec.new(
		HitSpec.Kind.CHARGED_HEAVY,
		rules.charged_heavy_damage,
		HitSpec.Shape.ARC,
		rules.charged_heavy_arc_degrees,
		rules.charged_heavy_radius,
		true,
		rules.stagger_seconds,
		rules.stagger_bonus_multiplier
	)
	_running_spec = HitSpec.new(
		HitSpec.Kind.RUNNING_ATTACK,
		rules.running_attack_damage,
		HitSpec.Shape.BOX,
		rules.running_attack_box_size.x,
		rules.running_attack_box_size.y,
		false,
		0.0,
		rules.stagger_bonus_multiplier
	)


# --- The frame ---------------------------------------------------------------


## Advance the moveset one frame and act on this frame's intent.
##
## The order is deliberate and is the contract the tests hold it to:
##
##   1. **Time first.** Timers advance, phases end, a finished state falls back to
##      `IDLE`. Signals for a hit window closing fire here.
##   2. **Input second.** Which means a state that ended *this* frame can be followed
##      by a new action on the same frame, rather than costing the player a frame of
##      input for nothing.
##   3. **Displacement last**, so a dodge that began on step 2 already moves on the
##      frame it began.
##
## The sub-frame remainder of a state that ends mid-frame is deliberately dropped:
## the state that follows starts its own phase clock at zero. At any sane frame rate
## that is under a millisecond, and carrying it would make every state's timing
## depend on where the frame boundaries happened to fall.
func update(input: CombatInput, delta: float) -> void:
	_frame_displacement = Vector2.ZERO
	if _rules == null:
		return
	if delta > 0.0:
		_time += delta
		_tick_combo_window(delta)
		_advance_state(delta)
	if input != null:
		_apply_input(input)
	if delta > 0.0:
		_apply_displacement(delta)


# --- Reading -----------------------------------------------------------------


## What the Fool is doing.
func state() -> State:
	return _state


## Where inside that state.
func phase() -> Phase:
	return _phase


## Seconds inside the current phase.
func phase_time() -> float:
	return _phase_time


## Seconds since the current state began. What i-frames are measured against.
func state_time() -> float:
	return _state_time


## Which light hit the string is on (1..3), or `NO_COMBO`.
func combo_index() -> int:
	return _combo_index


## Seconds the heavy has been held this charge.
func charge_seconds_held() -> float:
	return _charge_time


## True when the charge has passed `CombatRules.charge_seconds`, so releasing now
## gives the stagger launcher.
func is_fully_charged() -> bool:
	if _rules == null:
		return false
	return _charge_time >= _rules.charge_seconds


## True while the Fool is mid-action and will not start another one.
func is_committed() -> bool:
	return _state != State.IDLE


## True while an attack is being thrown (charging counts: the heavy is out).
func is_attacking() -> bool:
	return _is_attack_state(_state) or _state == State.CHARGING


## True while the Fool is in any of the three dodges.
func is_dodging() -> bool:
	return _is_dodge_state(_state)


## True while i-frames are up. `combat.md` §Defense: only a dodge grants them - the
## block-step absorbs a hit instead, and absorbing is not evading.
##
## The window is half-open, `[iframe_start, iframe_end)`, measured from the start of
## the dodge, and it is the SAME window for all three directional dodges: "All
## directional dodges share the roll's i-frame rules" (`combat.md` §Focus).
func is_invulnerable() -> bool:
	if _rules == null or not _is_dodge_state(_state):
		return false
	return (
		_state_time >= _rules.dodge_iframe_start_seconds
		and _state_time < _rules.dodge_iframe_end_seconds
	)


## True while the block-step is actually guarding: its first
## `CombatRules.block_step_guard_seconds`, and only until the guard has absorbed a
## hit. The tail is the commitment that pays for having no counter-window, and the
## one-hit limit is the other half of it - `combat.md` §Defense gives the hop-guard
## "absorbs a hit", singular, so a Fool standing in a guard window is not immune to
## the second swing of a pair.
func is_blocking() -> bool:
	if _rules == null or _state != State.BLOCK_STEP or _guard_spent:
		return false
	return _state_time < _rules.block_step_guard_seconds


## Spend this block-step's absorb. Called by the defence side the moment a hit comes
## back `BLOCKED`; the Fool stays committed to the rest of the hop with no guard left.
## Ignored outside a block-step, so nothing can spend a guard that is not up.
func consume_guard() -> void:
	if _state == State.BLOCK_STEP:
		_guard_spent = true


## True once this block-step's guard has been spent.
func is_guard_spent() -> bool:
	return _guard_spent


## The hit this state is throwing right now, or `null` outside an active window.
##
## The SAME instance every frame of one state - callers may compare by identity, and
## nothing here allocates (see the class doc).
func active_hit() -> HitSpec:
	if _phase != Phase.ACTIVE:
		return null
	return _spec_for(_state)


## True when the current dodge's i-frames opened within `seconds_ago` of now.
##
## This is the Fool's Chance test (`combat.md` §Defense: "a dodge timed to the final
## instant before a hit lands"), asked by the defence side at the moment a hit
## arrives.
##
## **It is measured from the moment i-frames open, not from the dodge's first frame**,
## and that is the whole point of the fix it encodes: a hit that arrives before
## `CombatRules.dodge_iframe_start_seconds` is a hit that LANDS (`is_invulnerable()`
## is false), so a window measured from the dodge's start spends its first
## `dodge_iframe_start_seconds` on frames where no Fool's Chance is possible. On the
## authored numbers that turned a 0.12 s window into a 0.06 s usable band, and less
## than that on Trial. Measured from i-frames opening, the usable band IS the authored
## window, on every difficulty, and `CombatRules.validate()` holds it to a floor of
## three physics frames.
##
## It is time-only on purpose: whether the dodge is ALSO invulnerable is a separate
## question with a separate answer (`is_invulnerable()`), and the two are asked
## together by `FoolDefense`.
func perfect_dodge_started_within(seconds_ago: float) -> bool:
	if _dodge_started_at == -INF or _rules == null:
		return false
	return _time - _dodge_started_at - _rules.dodge_iframe_start_seconds <= seconds_ago


## How fast the Fool may move this frame, as a fraction of top speed.
##
## Zero through an attack's windup and active frames, small through its recovery,
## reduced while charging, and zero in a dodge or a block-step (those move the Fool
## themselves - see `frame_displacement()`).
func movement_multiplier() -> float:
	if _rules == null:
		return 1.0
	if _state == State.CHARGING:
		return _rules.charge_movement_multiplier
	if _is_dodge_state(_state) or _state == State.BLOCK_STEP:
		return 0.0
	if _is_attack_state(_state):
		if _phase == Phase.RECOVERY:
			return _rules.recovery_movement_multiplier
		return _rules.attack_movement_multiplier
	return 1.0


## How far the Fool's own action moves them this frame, in pixels, on top of whatever
## walking `movement_multiplier()` still allows. Zero except during a dodge, a
## block-step hop, or a running attack's lunge.
func frame_displacement() -> Vector2:
	return _frame_displacement


## The direction the Fool is facing.
func facing() -> Vector2:
	return _facing


## Point the Fool. A zero vector is ignored: a facing is never nothing.
func set_facing(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	_facing = direction.normalized()


## Tell the controller which way its Focus target lies, so strafing keeps the Fool
## turned toward it (`combat.md` §Focus: "the Fool keeps facing the target while
## circling, backing off, or closing").
func set_focus_target_dir(direction: Vector2) -> void:
	if direction.is_zero_approx():
		clear_focus_target()
		return
	_focus_target_dir = direction.normalized()
	_has_focus_target = true


## Forget the Focus target; strafing falls back to the movement facing.
func clear_focus_target() -> void:
	_focus_target_dir = Vector2.ZERO
	_has_focus_target = false


## True when Focus has been given a target direction.
func has_focus_target() -> bool:
	return _has_focus_target


## The direction the Fool's body should face: the Focus target when there is one,
## otherwise the travel facing. This is the whole of "8-direction strafing around
## that target" as far as the moveset is concerned - the strafing itself is movement,
## which the body does.
func strafe_facing() -> Vector2:
	return _focus_target_dir if _has_focus_target else _facing


## Which dodge a given intent would produce, without performing it. Exposed because
## it is the rule `combat.md` §Focus states in prose and the one worth reading back:
## forward or neutral is the roll, left/right the side-hop, backward the backflip,
## and out of Focus every direction is the plain roll.
func dodge_kind_for(move: Vector2, in_focus: bool) -> State:
	if not in_focus or move.is_zero_approx():
		return State.DODGE_ROLL
	var reference := strafe_facing()
	if reference.is_zero_approx():
		return State.DODGE_ROLL
	var offset := absf(rad_to_deg(reference.angle_to(move)))
	if offset <= DODGE_CONE_HALF_DEGREES:
		return State.DODGE_ROLL
	if offset >= 180.0 - DODGE_CONE_HALF_DEGREES:
		return State.BACKFLIP
	return State.SIDE_HOP


## Back to standing, string forgotten, charge dropped. Used when a fight ends, when a
## scene loads, and when the Fool is defeated.
func reset() -> void:
	var old_state := _state
	if _phase == Phase.ACTIVE and _is_attack_state(_state):
		hit_window_closed.emit()
	_state = State.IDLE
	_phase = Phase.WINDUP
	_phase_time = 0.0
	_state_time = 0.0
	_combo_index = NO_COMBO
	_combo_window_left = 0.0
	_charge_time = 0.0
	_guard_spent = false
	_dodge_distance_left = 0.0
	_dodge_started_at = -INF
	_frame_displacement = Vector2.ZERO
	if old_state != State.IDLE:
		state_changed.emit(old_state, State.IDLE)


# --- Timing ------------------------------------------------------------------


## Count the combo window down. It runs whatever the state is, so the string survives
## the gap between one hit's recovery ending and the next input arriving.
func _tick_combo_window(delta: float) -> void:
	if _combo_window_left <= 0.0:
		return
	_combo_window_left -= delta
	if _combo_window_left <= 0.0:
		_combo_window_left = 0.0
		_combo_index = NO_COMBO


## Advance the current state's clocks, ending phases and the state as they run out.
##
## The loop consumes the frame across as many phase boundaries as it crosses, so a
## long frame cannot swallow an active window: the window opens and closes, and the
## signals for both fire, even if no `update()` ever observed the state mid-ACTIVE.
func _advance_state(delta: float) -> void:
	if _state == State.IDLE:
		return
	if _state == State.CHARGING:
		_charge_time += delta
		_state_time += delta
		return
	var remaining := delta
	while true:
		var duration := _phase_duration(_state, _phase)
		var left := duration - _phase_time
		if remaining < left:
			_phase_time += remaining
			_state_time += remaining
			return
		_state_time += left
		remaining -= left
		_phase_time = 0.0
		if not _enter_next_phase():
			return


## Move to the next phase, or end the state. False means the state ended.
func _enter_next_phase() -> bool:
	match _phase:
		Phase.WINDUP:
			_phase = Phase.ACTIVE
			var spec := _spec_for(_state)
			if spec != null:
				hit_window_opened.emit(spec)
			return true
		Phase.ACTIVE:
			_phase = Phase.RECOVERY
			if _is_attack_state(_state):
				hit_window_closed.emit()
			return true
	_end_state()
	return false


## The state is over; the Fool stands up.
func _end_state() -> void:
	_change_state(State.IDLE)


## Move the Fool to `next`, resetting the phase clocks and announcing it.
func _change_state(next: State) -> void:
	if _phase == Phase.ACTIVE and _is_attack_state(_state) and next != _state:
		hit_window_closed.emit()
	var old_state := _state
	_state = next
	_phase = Phase.WINDUP
	_phase_time = 0.0
	_state_time = 0.0
	if next == State.IDLE:
		_dodge_distance_left = 0.0
	if old_state != next:
		state_changed.emit(old_state, next)
	# A state whose windup is zero is already active on the frame it starts, and a
	# hit window that opened has to say so even then.
	if next != State.IDLE and next != State.CHARGING and _phase_duration(next, Phase.WINDUP) <= 0.0:
		_phase = Phase.ACTIVE
		var spec := _spec_for(next)
		if spec != null:
			hit_window_opened.emit(spec)


# --- Input -------------------------------------------------------------------


## Act on this frame's intent, under the one rule that makes the moveset readable:
## **a committed state accepts nothing**, except the light string's own continuation
## and the release of a charge. `combat.md` §Philosophy - recovery is meant to be
## felt, so nothing cancels out of it, not even a dodge.
func _apply_input(input: CombatInput) -> void:
	# Moving turns the Fool, so a swing goes where the player is heading - but NOT on
	# the frame a dodge is asked for, and not in Focus. A dodge reads its direction
	# against the facing the Fool ALREADY had ("forward", "backward" and the two sides
	# are meaningless if pushing the stick has just redefined forward), and in Focus
	# the body faces the target, not the travel (`combat.md` §Focus).
	if (
		_state == State.IDLE
		and not input.dodge_pressed
		and not input.focus_held
		and not input.move.is_zero_approx()
	):
		set_facing(input.move)
	if _state == State.CHARGING:
		_apply_charge_input(input)
		return
	if _is_light_state(_state):
		if input.light_pressed and _may_chain():
			_start_light(_combo_index + 1)
		return
	if _state != State.IDLE:
		return
	if input.dodge_pressed:
		_start_dodge(input)
		return
	if input.block_pressed:
		_change_state(State.BLOCK_STEP)
		_begin_block_step()
		return
	if input.heavy_pressed:
		_charge_time = 0.0
		_change_state(State.CHARGING)
		charge_started.emit()
		return
	if input.light_pressed:
		if input.run_speed_fraction >= _rules.running_attack_min_speed_fraction:
			_begin_running_attack()
			return
		_start_light(_next_light_index())
	# What is deliberately NOT here: a branch for `input.heavy_released`.
	# A heavy RELEASE from standing swings nothing. The only route to a heavy is
	# `_release_charge()` out of `CHARGING`, i.e. a press this controller actually took
	# up: a release whose press was eaten by a committed state (pressed mid-recovery,
	# let go once the Fool was free) would otherwise fire a phantom heavy out of
	# nothing. The one-frame tap still owes the player its swing and still gets it -
	# the press enters CHARGING on the frame it arrives, and the release is answered by
	# `_apply_charge_input` on the very next frame.


## While charging: hold to keep building, release to swing.
func _apply_charge_input(input: CombatInput) -> void:
	if input.heavy_released or not input.heavy_held:
		_release_charge()


## Let the charge go: the stagger launcher if it is full, a plain heavy if not.
func _release_charge() -> void:
	var fully_charged := is_fully_charged()
	charge_released.emit(fully_charged)
	_change_state(State.CHARGED_HEAVY if fully_charged else State.HEAVY)
	_charge_time = 0.0


## True when the string is still live: the window has time left and there is a hit
## left to throw. **The one authoritative window check** - both a mid-string chain and
## a fresh press from standing ask this and nothing else, so the two can never
## disagree about whether the string continues.
func _combo_window_open() -> bool:
	return _combo_window_left > 0.0 and _combo_index < CombatRules.LIGHT_STRING_HITS


## True when a light press right now continues the string rather than restarting it:
## the string is live, and the Fool is in the ACTIVE or RECOVERY phase of a light hit
## (a press during a windup is mashing, and mashing buys nothing - §Philosophy).
func _may_chain() -> bool:
	if not _combo_window_open():
		return false
	return _phase == Phase.ACTIVE or _phase == Phase.RECOVERY


## Which light hit a fresh press starts: the next one when the window survived the
## end of the last hit, otherwise the first.
func _next_light_index() -> int:
	return _combo_index + 1 if _combo_window_open() else 1


## Throw light hit `index` (1-based).
func _start_light(index: int) -> void:
	_combo_index = clampi(index, 1, CombatRules.LIGHT_STRING_HITS)
	_change_state(_light_state(_combo_index))
	_combo_window_left = _rules.light_combo_window_seconds


## Throw the lunge, and set up the distance it carries the Fool.
func _begin_running_attack() -> void:
	_change_state(State.RUNNING_ATTACK)
	_dodge_direction = strafe_facing()
	_dodge_distance_left = _rules.running_attack_lunge_distance
	var duration := (
		_rules.running_attack_windup_seconds
		+ _rules.running_attack_active_seconds
	)
	_dodge_speed = _rules.running_attack_lunge_distance / maxf(duration, 0.0001)


## Set up the block-step's own reposition: the hop carries the Fool away from the
## facing, which IS the "repositions slightly" of `combat.md` §Defense. There is no
## separate push on absorbing a hit - one hop, one reposition, and no counter-window
## anywhere in it.
func _begin_block_step() -> void:
	_guard_spent = false
	_dodge_direction = -strafe_facing()
	_dodge_distance_left = _rules.block_step_reposition_distance
	_dodge_speed = _rules.block_step_reposition_distance / maxf(_rules.block_step_seconds, 0.0001)


## Begin the dodge this intent asks for, in the direction it asks for.
func _start_dodge(input: CombatInput) -> void:
	var kind := dodge_kind_for(input.move, input.focus_held)
	_change_state(kind)
	_dodge_started_at = _time
	_dodge_direction = input.move.normalized() if not input.move.is_zero_approx() else _facing
	var distance := _dodge_distance(kind)
	_dodge_distance_left = distance
	_dodge_speed = distance / maxf(_dodge_duration(kind), 0.0001)
	dodge_started.emit(kind)


# --- Displacement ------------------------------------------------------------


## Move the Fool along the current action's own vector, never past its total
## distance. Tracking the remainder rather than recomputing from the elapsed time is
## what makes a dodge cover exactly the rules' distance however the frames fall.
func _apply_displacement(delta: float) -> void:
	if _dodge_distance_left <= 0.0:
		return
	if not (_is_dodge_state(_state) or _state == State.BLOCK_STEP or _state == State.RUNNING_ATTACK):
		_dodge_distance_left = 0.0
		return
	if _state == State.RUNNING_ATTACK and _phase == Phase.RECOVERY:
		# The lunge is the approach, not the follow-through.
		_dodge_distance_left = 0.0
		return
	var step := minf(_dodge_speed * delta, _dodge_distance_left)
	_dodge_distance_left -= step
	_frame_displacement = _dodge_direction * step


# --- Tables ------------------------------------------------------------------


## How long one phase of one state lasts.
func _phase_duration(state_id: State, phase_id: Phase) -> float:
	match state_id:
		State.LIGHT_1, State.LIGHT_2, State.LIGHT_3:
			var index := _light_index(state_id)
			match phase_id:
				Phase.WINDUP:
					return _rules.light_windup(index)
				Phase.ACTIVE:
					return _rules.light_active(index)
			return _rules.light_recovery(index)
		State.HEAVY:
			match phase_id:
				Phase.WINDUP:
					return _rules.heavy_windup_seconds
				Phase.ACTIVE:
					return _rules.heavy_active_seconds
			return _rules.heavy_recovery_seconds
		State.CHARGED_HEAVY:
			match phase_id:
				Phase.WINDUP:
					return _rules.charged_heavy_windup_seconds
				Phase.ACTIVE:
					return _rules.charged_heavy_active_seconds
			return _rules.charged_heavy_recovery_seconds
		State.RUNNING_ATTACK:
			match phase_id:
				Phase.WINDUP:
					return _rules.running_attack_windup_seconds
				Phase.ACTIVE:
					return _rules.running_attack_active_seconds
			return _rules.running_attack_recovery_seconds
		State.DODGE_ROLL, State.SIDE_HOP, State.BACKFLIP, State.BLOCK_STEP:
			# One phase, the whole move: a dodge has no hit window to open, and its
			# i-frames are measured from the start of the state, not of a phase.
			if phase_id == Phase.ACTIVE:
				return _dodge_duration(state_id)
			return 0.0
	return 0.0


## The spec a state throws, or `null` for a state that throws nothing.
func _spec_for(state_id: State) -> HitSpec:
	match state_id:
		State.LIGHT_1, State.LIGHT_2, State.LIGHT_3:
			return _light_specs[_light_index(state_id)]
		State.HEAVY:
			return _heavy_spec
		State.CHARGED_HEAVY:
			return _charged_spec
		State.RUNNING_ATTACK:
			return _running_spec
	return null


## How long one of the dodges (or the block-step) lasts.
func _dodge_duration(state_id: State) -> float:
	match state_id:
		State.SIDE_HOP:
			return _rules.side_hop_seconds
		State.BACKFLIP:
			return _rules.backflip_seconds
		State.BLOCK_STEP:
			return _rules.block_step_seconds
	return _rules.dodge_roll_seconds


## How far one of the dodges carries the Fool. The backflip's is the doc's own
## measure - 1.5 body-widths - resolved by the rules table.
func _dodge_distance(state_id: State) -> float:
	match state_id:
		State.SIDE_HOP:
			return _rules.side_hop_distance
		State.BACKFLIP:
			return _rules.backflip_distance()
	return _rules.dodge_roll_distance


## The state for light hit `index` (1-based).
func _light_state(index: int) -> State:
	match index:
		2:
			return State.LIGHT_2
		3:
			return State.LIGHT_3
	return State.LIGHT_1


## The 0-based array index for a light state.
func _light_index(state_id: State) -> int:
	match state_id:
		State.LIGHT_2:
			return 1
		State.LIGHT_3:
			return 2
	return 0


## True for the three light states.
func _is_light_state(state_id: State) -> bool:
	return (
		state_id == State.LIGHT_1
		or state_id == State.LIGHT_2
		or state_id == State.LIGHT_3
	)


## True for every state that throws a hit.
func _is_attack_state(state_id: State) -> bool:
	return (
		_is_light_state(state_id)
		or state_id == State.HEAVY
		or state_id == State.CHARGED_HEAVY
		or state_id == State.RUNNING_ATTACK
	)


## True for the three directional dodges. The block-step is NOT one: it absorbs
## rather than evades, and grants no i-frames (`combat.md` §Defense).
func _is_dodge_state(state_id: State) -> bool:
	return (
		state_id == State.DODGE_ROLL
		or state_id == State.SIDE_HOP
		or state_id == State.BACKFLIP
	)
