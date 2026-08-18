extends SceneTree

## The combat round, end to end, in a real scene with real physics.
##
## The unit tests under `tests/unit/combat/` prove each piece in isolation; this
## proves they are actually wired to each other - that a button press reaches the
## moveset, that the moveset's hit window becomes an `Area2D` overlap, that the
## overlap becomes damage and Fortune, and that a dodge timed against a real enemy's
## real telegraph triggers Fool's Chance and pays for a Trump.
##
## The fixture is `tests/fixtures/scenes/combat_arena.tscn`: the Fool from
## `scenes/fool.tscn` and a `TrainingDummy`. It is a TEST FIXTURE and not game
## content - round 8 owns the actual enemies. The "ground" in it is a bare `Node2D`,
## because in the top-down grammar the floor is not a body: giving the arena a
## collision-shaped floor would put a static body inside the Fool.
##
## **Nothing here waits on the wall clock.** Every beat is driven by physics frames
## and by the fixture's own `time_until_hit()`, which is why the dodge timings are
## deterministic headless. `Input.action_press` is used rather than calling the
## controller directly, so the input path is part of what is proven - and a tap is
## HELD for two physics frames rather than one, because which frame a node sees an
## edge on depends on the order the engine walks the main loop and the scene, and a
## test that depended on that order would be a test of Godot's internals.
##
## What each phase proves, in order:
##
##   1. Focus locks onto the engaged enemy and turns the Fool toward it, and the
##      back-dodge inside Focus comes out as the grand backflip;
##   2. the light string lands three times and each hit trickles Fortune;
##   3. the charged heavy staggers, and the follow-up pays the stagger bonus;
##   4. the block-step absorbs a hit for nothing;
##   5. a dodge with i-frames up but early is DODGED and slows nothing;
##   6. a dodge inside the perfect window is Fool's Chance: the world slows and the
##      next Present cast is free;
##   7. Story halves the damage the Fool takes;
##   8. the Fool WALKS at normal speed through the slowed world, not only dodges;
##   9. the Fool at zero is defeated and comes back whole at a Waystation.

const ARENA_PATH := "res://tests/fixtures/scenes/combat_arena.tscn"

## Physics frames to let pass before overlaps and services are believed.
const SETTLE_FRAMES := 6

## The most frames any one phase may take before the test calls it stuck. Generous:
## the charged heavy alone is a 0.7 s hold.
const PHASE_FRAME_LIMIT := 900

## Where the Fool stands at the start of each phase, and where the dummy waits.
const FOOL_HOME := Vector2.ZERO

## The accessibility slider used for the Fool's Chance phase, in seconds. It widens
## the perfect window enough that a one-frame difference in when the press is seen
## cannot decide the test - and proves the slider itself works end to end.
const SLIDER_SECONDS := 0.10

## How long before the hit lands each timed input is made, in seconds.
const PERFECT_DODGE_LEAD := 0.14
const LATE_DODGE_LEAD := 0.30
const BLOCK_LEAD := 0.10

## Frames the heavy is held for the charged release: comfortably past
## `CombatRules.charge_seconds` at 60 Hz.
const CHARGE_HOLD_FRAMES := 60

## Physics frames of walking averaged for each half of the slow-motion comparison.
const WALK_SAMPLE_FRAMES := 12

## How far the slowed walk may differ from the normal one, as a fraction. Loose enough
## to absorb the sub-pixel edges of `move_and_collide`, tight enough that an
## uncompensated body - which would walk at `slowmo_time_scale`, 30% of normal - fails
## it several times over.
const WALK_TOLERANCE := 0.10

## The quest id world-state changes are attributed to in this test.
const TEST_QUEST := &"MQ01"

## The Magician's unbinding, which is what puts Trump I in the Fool's hand.
const MAGICIAN_FLAG := &"WS_MAGICIAN_UNBOUND"

var _all_passed := true
var _phase := 0
var _phase_frame := 0

## A sub-step inside the current phase, reset with the phase.
var _step := 0

var _scene: Node2D = null
var _fool: FoolBody = null
var _fool_combat: FoolCombat = null
var _fool_combatant: Combatant = null
var _dummy: TrainingDummy = null
var _dummy_hitbox: Hitbox = null
var _fool_hitbox: Hitbox = null

var _rules: CombatRules = null
var _combat: CombatService = null
var _fortune: FortuneService = null
var _spread: PocketSpreadService = null
var _rose: WhiteRoseService = null
var _world_state: WorldStateService = null

## What the dummy's swings did to the Fool, newest last.
var _incoming_results: Array[int] = []

## One Fortune reading per landed hit, taken on the frame AFTER the hit so it does
## not depend on which handler the engine calls first.
var _hit_count := 0
var _fortune_samples: Array[int] = []
var _sample_due := false

## Damage the dummy took from the last hit that landed on it.
var _last_damage_to_dummy := 0

var _defeated := false
var _revived := false

## Distance the Fool walked on each sampled physics frame, where they stood at the last
## sample, and the normal-time average the slowed one is measured against.
var _walk_samples: Array[float] = []
var _walk_from := Vector2.ZERO
var _normal_walk := 0.0

## Actions the test tapped: released at the top of the frame after next, so an edge
## is visible whichever order the engine processes the main loop and the nodes in.
var _release_now: Array[StringName] = []
var _release_next: Array[StringName] = []


func _initialize() -> void:
	var packed: PackedScene = load(ARENA_PATH)
	_scene = packed.instantiate() as Node2D
	root.add_child(_scene)
	_fool = _scene.get_node_or_null("Fool") as FoolBody
	_dummy = _scene.get_node_or_null("Dummy") as TrainingDummy
	if _fool != null:
		_fool_combat = _fool.get_node_or_null("FoolCombat") as FoolCombat
		_fool_combatant = _fool.get_node_or_null("Combatant") as Combatant
	if _fool_combatant != null:
		_fool_hitbox = _fool_combatant.get_node_or_null("Hitbox") as Hitbox
	if _dummy != null:
		_dummy_hitbox = _dummy.get_node_or_null("Hitbox") as Hitbox
	if _dummy != null:
		_dummy.damaged.connect(_on_dummy_damaged)
	if _dummy_hitbox != null:
		_dummy_hitbox.hit_landed.connect(_on_dummy_hit_landed)
	# Connected AFTER `FoolCombat`, which hooks its own hitbox up in `_ready`, so this
	# handler runs second and sees the Fortune the hit has already earned.
	if _fool_hitbox != null:
		_fool_hitbox.hit_landed.connect(_on_fool_hit_landed)


func _physics_process(_delta: float) -> bool:
	_release_pressed()
	_phase_frame += 1
	if _phase_frame > PHASE_FRAME_LIMIT:
		_all_passed = check(false, "phase %d finished within its frame budget" % _phase)
		_finish()
		return true
	match _phase:
		0:
			return _phase_setup()
		1:
			return _phase_focus_lock()
		2:
			return _phase_light_string()
		3:
			return _phase_charged_heavy_stagger()
		4:
			return _phase_block_step()
		5:
			return _phase_late_dodge()
		6:
			return _phase_perfect_dodge()
		7:
			return _phase_story_damage()
		8:
			return _phase_slow_motion_walk()
		9:
			return _phase_defeat_loop()
	_finish()
	return true


# --- Phase 0: the arena is wired ---------------------------------------------


func _phase_setup() -> bool:
	if _phase_frame < SETTLE_FRAMES:
		return false
	_resolve_services()
	_all_passed = check(_fool != null, "the arena holds the Fool from scenes/fool.tscn") and _all_passed
	_all_passed = check(_fool_combat != null, "the Fool carries a FoolCombat component") and _all_passed
	_all_passed = check(_fool_combatant != null, "and a Combatant of their own") and _all_passed
	_all_passed = check(_dummy != null, "the arena holds a TrainingDummy") and _all_passed
	_all_passed = check(_combat != null, "the Services autoload owns a CombatService") and _all_passed
	if _fool == null or _dummy == null or _combat == null or _fool_combatant == null:
		_finish()
		return true
	_all_passed = check(
		_combat.fool() == _fool_combatant, "and the Fool registered themselves with it"
	) and _all_passed
	_all_passed = check(
		_fool_combatant.health() == _rules.fool_max_health,
		"the Fool's pool is sized from CombatRules, not from the scene"
	) and _all_passed
	_all_passed = check(
		_fool_combatant.faction == Faction.Id.FOOL, "and the Fool fights for the Fool"
	) and _all_passed

	# Trump I into the Present slot, before any enemy engages: the Spread cannot be
	# rebuilt mid-fight (progression.md), which is a rule this round's own
	# CombatService turns on.
	_world_state.fire(MAGICIAN_FLAG, TEST_QUEST)
	var assigned := _spread.assign(
		SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT
	)
	_all_passed = check(assigned, "Trump I is slotted in the Present, out of combat") and _all_passed
	_combat.enemy_engaged(_dummy)
	_all_passed = check(_spread.in_combat(), "engaging an enemy locks the Pocket Spread") and _all_passed
	_fool.face_direction(Vector2.RIGHT)
	_advance_phase()
	return false


# --- Phase 1: Focus ------------------------------------------------------------


func _phase_focus_lock() -> bool:
	match _step:
		0:
			if not _is_fool_idle():
				return false
			_reset_positions()
			_hold(InputActions.FOCUS)
			_step = 1
		1:
			var focus := _fool_combat.focus()
			_all_passed = check(
				focus.target() == _dummy,
				"Focus locks onto the enemy the fight knows about (combat.md §Focus)"
			) and _all_passed
			_all_passed = check(
				_fool_combat.controller().has_focus_target(),
				"and the moveset is told which way the target lies"
			) and _all_passed
			var facing := _fool_combat.controller().strafe_facing()
			_all_passed = check(
				facing.x > 0.9,
				"so the Fool keeps facing the target rather than the travel direction"
			) and _all_passed
			_step = 2
		2:
			if not _is_fool_idle():
				return false
			# Backward, relative to a Fool facing the target: the grand backflip.
			# Both inputs are HELD rather than tapped for one frame, because a dodge
			# is an edge and the frame the edge is seen on depends on the order the
			# engine walks the main loop and the nodes in.
			_hold(InputActions.MOVE_LEFT)
			_hold(InputActions.DODGE)
			_step = 3
		3:
			if _is_fool_idle() and _phase_frame < 30:
				return false
			_all_passed = check(
				_fool_combat.controller().state() == MovesetController.State.BACKFLIP,
				"the back-dodge in Focus is the grand backflip, through the real input path"
			) and _all_passed
			_let_go(InputActions.DODGE)
			_let_go(InputActions.MOVE_LEFT)
			_let_go(InputActions.FOCUS)
			_step = 4
		4:
			if not _is_fool_idle():
				return false
			_all_passed = check(
				not _fool_combat.controller().has_focus_target(),
				"and letting Focus go releases the lock"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 2: the light string -------------------------------------------------


func _phase_light_string() -> bool:
	if _phase_frame == 1:
		_hit_count = 0
		_fortune_samples = [_fortune.value()]
		_sample_due = false
		_reset_positions()
		_press(InputActions.ATTACK_LIGHT)
		return false
	if _sample_due:
		_fortune_samples.append(_fortune.value())
		_sample_due = false
	if _hit_count < CombatRules.LIGHT_STRING_HITS or _fortune_samples.size() <= CombatRules.LIGHT_STRING_HITS:
		# Chain as soon as the last hit has landed: the combo window is open through
		# the ACTIVE and RECOVERY phases of the hit before.
		var controller := _fool_combat.controller()
		if controller.combo_index() == _hit_count and _hit_count > 0:
			_press(InputActions.ATTACK_LIGHT)
		return false
	_all_passed = check(
		_hit_count == CombatRules.LIGHT_STRING_HITS,
		"the light string lands all three of its hits on the dummy"
	) and _all_passed
	var grew_every_hit := true
	for index: int in range(1, _fortune_samples.size()):
		if _fortune_samples[index] <= _fortune_samples[index - 1]:
			grew_every_hit = false
	_all_passed = check(
		_fortune_samples.size() == CombatRules.LIGHT_STRING_HITS + 1,
		"Fortune was read once before the string and once after each hit"
	) and _all_passed
	_all_passed = check(
		grew_every_hit, "and every landed hit trickled Fortune (combat.md §Fortune in combat)"
	) and _all_passed
	_advance_phase()
	return false


# --- Phase 3: the stagger launcher and its follow-up --------------------------


func _phase_charged_heavy_stagger() -> bool:
	match _step:
		0:
			if not _is_fool_idle():
				return false
			_reset_positions()
			_dummy.restore_full_health()
			_last_damage_to_dummy = 0
			_hold(InputActions.ATTACK_HEAVY)
			_step = 1
		1:
			if not _fool_combat.controller().is_fully_charged():
				return false
			_all_passed = check(
				_fool_combat.controller().is_fully_charged(),
				"holding the heavy past charge_seconds fills the charge"
			) and _all_passed
			_let_go(InputActions.ATTACK_HEAVY)
			_step = 2
		2:
			if _last_damage_to_dummy == 0:
				return false
			_all_passed = check(
				_dummy.is_staggered(),
				"the charged heavy staggers the target (combat.md: the stagger launcher)"
			) and _all_passed
			_all_passed = check(
				_last_damage_to_dummy == _rules.charged_heavy_damage,
				"and pays no stagger bonus for a stagger it caused itself"
			) and _all_passed
			_last_damage_to_dummy = 0
			_step = 3
		3:
			if not _is_fool_idle():
				return false
			_press(InputActions.ATTACK_LIGHT)
			_step = 4
		4:
			if _last_damage_to_dummy == 0:
				return false
			var expected := int(roundf(_rules.light_damage_at(0) * _rules.stagger_bonus_multiplier))
			_all_passed = check(
				_dummy.is_staggered(), "the dummy is still helpless when the follow-up lands"
			) and _all_passed
			_all_passed = check(
				_last_damage_to_dummy == expected,
				"the follow-up into a staggered target pays the bonus: %d, not %d"
				% [expected, _rules.light_damage_at(0)]
			) and _all_passed
			_last_damage_to_dummy = 0
			_advance_phase()
	return false


# --- Phase 4: the block-step ---------------------------------------------------


func _phase_block_step() -> bool:
	match _step:
		0:
			if not _is_fool_idle():
				return false
			_incoming_results.clear()
			_reset_positions()
			_ready_the_dummy()
			_dummy.attack(Vector2.LEFT)
			_step = 1
		1:
			if _dummy.is_attacking() and _dummy.time_until_hit() <= BLOCK_LEAD:
				if _is_fool_idle():
					_press(InputActions.BLOCK_STEP)
					_step = 2
			return false
		2:
			if _incoming_results.is_empty():
				return false
			_all_passed = check(
				_incoming_results[0] == HitResult.Id.BLOCKED,
				"the block-step absorbs the hit (combat.md §Defense)"
			) and _all_passed
			_all_passed = check(
				_fool_combatant.health() == _rules.fool_max_health,
				"and absorbing it costs the Fool nothing"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 5: an ordinary dodge -----------------------------------------------


func _phase_late_dodge() -> bool:
	match _step:
		0:
			_combat.set_perfect_window_bonus_seconds(0.0)
			if not _open_a_dummy_swing():
				return false
		1:
			if not _dodge_at(LATE_DODGE_LEAD):
				return false
		2:
			if _incoming_results.is_empty():
				return false
			_all_passed = check(
				_incoming_results[0] == HitResult.Id.DODGED,
				"a dodge with i-frames up but started well before the hit is a plain dodge"
			) and _all_passed
			_all_passed = check(
				not _combat.is_fools_chance_active(),
				"combat.md: dodging early and often does not buy Fool's Chance"
			) and _all_passed
			_all_passed = check(
				absf(Engine.time_scale - 1.0) < 0.0001, "and the world is not slowed"
			) and _all_passed
			_all_passed = check(
				not _fortune.has_free_cast(), "nor is a free Present cast armed"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 6: Fool's Chance ---------------------------------------------------


func _phase_perfect_dodge() -> bool:
	match _step:
		0:
			# The accessibility slider, independent of difficulty (combat.md
			# §Accessibility). Widening it here is what makes the beat deterministic
			# at 60 Hz - and proves the slider reaches the hit path.
			_combat.set_perfect_window_bonus_seconds(SLIDER_SECONDS)
			if not _open_a_dummy_swing():
				return false
		1:
			if not _dodge_at(PERFECT_DODGE_LEAD):
				return false
		2:
			if _incoming_results.is_empty():
				return false
			_all_passed = check(
				_incoming_results[0] == HitResult.Id.DODGED_PERFECT,
				"a dodge timed to the final instant before the hit is a Fool's Chance"
			) and _all_passed
			_all_passed = check(
				_combat.is_fools_chance_active(), "which slows the world"
			) and _all_passed
			_all_passed = check(
				absf(Engine.time_scale - _rules.slowmo_time_scale) < 0.0001,
				"to exactly the authored time scale"
			) and _all_passed
			_all_passed = check(
				_fortune.has_free_cast(),
				"and makes the next Present cast free (combat.md §Defense)"
			) and _all_passed
			var fortune_before := _fortune.value()
			var cast := _spread.cast_present()
			_all_passed = check(cast, "Trump I casts out of the Present slot") and _all_passed
			_all_passed = check(
				_fortune.value() == fortune_before,
				"and the free cast paid for it: the meter did not move"
			) and _all_passed
			_all_passed = check(
				not _fortune.has_free_cast(), "the free cast is spent, not kept"
			) and _all_passed
			_combat.end_fools_chance()
			_advance_phase()
	return false


# --- Phase 7: difficulty --------------------------------------------------------


func _phase_story_damage() -> bool:
	# The Fool has to be standing: a hit thrown at a Fool still mid-roll is dodged,
	# which would prove nothing about difficulty.
	if _phase_frame < 2 or not _is_fool_idle():
		return false
	_reset_positions()
	var damage := 20
	_combat.set_difficulty(DifficultyMode.Id.JOURNEY)
	_fool_combatant.restore_full_health()
	_fool_combatant.take_hit(_enemy_hit(damage))
	var journey_lost := _rules.fool_max_health - _fool_combatant.health()
	_combat.set_difficulty(DifficultyMode.Id.STORY)
	_fool_combatant.restore_full_health()
	_fool_combatant.take_hit(_enemy_hit(damage))
	var story_lost := _rules.fool_max_health - _fool_combatant.health()
	_all_passed = check(journey_lost == damage, "Journey is the baseline: the hit costs its damage") and _all_passed
	_all_passed = check(
		story_lost == int(roundf(damage * _rules.damage_taken_multiplier_story)),
		"Story reduces damage taken (combat.md §Difficulty modes)"
	) and _all_passed
	_combat.set_difficulty(DifficultyMode.Id.JOURNEY)
	_advance_phase()
	return false


# --- Phase 8: walking through Fool's Chance ---------------------------------------


## `combat.md` §Defense: during Fool's Chance "the Fool moves at normal speed relative
## to a slowed world". Compensating the MOVESET is not that on its own - the moveset
## owns the swings and the dodge displacement, and walking is the body's. Uncompensated,
## the Fool would roll at full speed and then wade at `slowmo_time_scale`.
##
## The measure is per PHYSICS FRAME rather than per second, deliberately:
## `Engine.time_scale` shortens the delta each physics frame carries while the frames
## themselves keep coming at the same real rate, so "the same distance per frame" IS
## "the same speed in real time" - and it needs no clock to say so.
func _phase_slow_motion_walk() -> bool:
	match _step:
		0:
			if not _is_fool_idle():
				return false
			_reset_positions()
			_hold(InputActions.MOVE_RIGHT)
			_walk_samples.clear()
			_step = 1
		1:
			# One frame of settling: which frame the input edge is seen on depends on
			# the order the engine walks the main loop and the nodes in, and half a
			# frame of walking would spoil the measurement for reasons that are not
			# about time at all.
			_walk_from = _fool.global_position
			_step = 2
		2:
			_sample_walk()
			if _walk_samples.size() < WALK_SAMPLE_FRAMES:
				return false
			_normal_walk = _mean(_walk_samples)
			_all_passed = check(
				_normal_walk > 0.0, "the Fool walks when the stick is held"
			) and _all_passed
			_combat.trigger_fools_chance()
			_all_passed = check(
				absf(Engine.time_scale - _rules.slowmo_time_scale) < 0.0001,
				"the world is slowed for the second half of the measurement"
			) and _all_passed
			_walk_samples.clear()
			_step = 3
		3:
			# Skip the frame the time scale changed on, for the same reason.
			_walk_from = _fool.global_position
			_step = 4
		4:
			_sample_walk()
			if _walk_samples.size() < WALK_SAMPLE_FRAMES:
				return false
			var slowed := _mean(_walk_samples)
			_all_passed = check(
				absf(slowed - _normal_walk) <= _normal_walk * WALK_TOLERANCE,
				"the Fool walks at normal speed through a slowed world: %.2f px/frame slowed, %.2f normal"
				% [slowed, _normal_walk]
			) and _all_passed
			_all_passed = check(
				_fool.time_compensation() > 1.0,
				"which is the body's own time compensation doing it, not the moveset's"
			) and _all_passed
			_let_go(InputActions.MOVE_RIGHT)
			_combat.end_fools_chance()
			_step = 5
		5:
			# One frame on: the compensation is set by the component every physics frame,
			# so the frame the window is closed on is not the frame the body hears about it.
			_all_passed = check(
				absf(_fool.time_compensation() - 1.0) < 0.0001,
				"and the body is back on the world's time once the window shuts"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 9: the defeat loop ----------------------------------------------------


func _phase_defeat_loop() -> bool:
	if _phase_frame < 2 or not _is_fool_idle():
		return false
	_fool_combatant.restore_full_health()
	_rose.use_petal()
	var petals_before := _rose.petals()
	_fool_combatant.take_hit(_enemy_hit(_rules.fool_max_health))
	_all_passed = check(_fool_combatant.health() == 0, "the Fool's pool empties") and _all_passed
	_all_passed = check(_defeated, "and the scene is told the Fool fell (combat.md §Defeat)") and _all_passed
	_all_passed = check(_combat.is_defeated(), "the service knows it too") and _all_passed
	_all_passed = check(
		petals_before < _rose.max_petals(), "the Rose really was short a petal before the fall"
	) and _all_passed
	_combat.revive_at_waystation()
	_all_passed = check(_revived, "the return leg announces itself") and _all_passed
	_all_passed = check(
		_fool_combatant.health() == _rules.fool_max_health,
		"the Fool wakes whole - no penalty beyond the walk back"
	) and _all_passed
	_all_passed = check(
		_rose.petals() == _rose.max_petals(), "with the White Rose regrown"
	) and _all_passed
	_all_passed = check(not _combat.is_defeated(), "and back on their feet") and _all_passed
	_combat.enemy_disengaged(_dummy)
	_all_passed = check(
		not _spread.in_combat(), "with the fight over, the Pocket Spread unlocks again"
	) and _all_passed
	_advance_phase()
	return false


# --- Signals ---------------------------------------------------------------------


func _on_dummy_damaged(amount: int, _remaining: int) -> void:
	_last_damage_to_dummy = amount


## One of the Fool's own swings connected. Fortune is read HERE rather than off the
## dummy's `damaged`, because the trickle is earned by `FoolCombat` on this signal -
## reading it a moment earlier would be reading it before it was paid.
func _on_fool_hit_landed(_hurtbox: Hurtbox, _spec: HitSpec, result: HitResult.Id) -> void:
	if _phase != 2 or not HitResult.was_landed(result):
		return
	_hit_count += 1
	_sample_due = true


func _on_dummy_hit_landed(_hurtbox: Hurtbox, _spec: HitSpec, result: HitResult.Id) -> void:
	_incoming_results.append(result)


func _on_fool_defeated(_count: int, _at_seconds: int) -> void:
	_defeated = true


func _on_fool_revived() -> void:
	_revived = true


# --- Driving ---------------------------------------------------------------------


## Tap an action: pressed now, released two frames on. See the class doc for why two.
func _press(action: StringName) -> void:
	Input.action_press(action)
	if not _release_next.has(action):
		_release_next.append(action)


## Press and keep pressing until `_let_go`.
func _hold(action: StringName) -> void:
	Input.action_press(action)
	_release_now.erase(action)
	_release_next.erase(action)


## Release a held action.
func _let_go(action: StringName) -> void:
	Input.action_release(action)
	_release_now.erase(action)
	_release_next.erase(action)


## Retire the taps whose two frames are up, before anything else this frame.
func _release_pressed() -> void:
	for action: StringName in _release_now:
		Input.action_release(action)
	_release_now = _release_next
	_release_next = []


## Put the dummy back to standing and start one clean swing, once the Fool is free to
## answer it. True on the frame the swing begins, having moved the phase on a step.
func _open_a_dummy_swing() -> bool:
	if not _is_fool_idle():
		return false
	_incoming_results.clear()
	_ready_the_dummy()
	_reset_positions()
	_dummy.attack(Vector2.LEFT)
	_step += 1
	return true


## Press dodge `lead` seconds before the dummy's hit lands, and only during the
## telegraph. True on the frame it is pressed, having moved the phase on a step. A
## swing that reaches its active frame with no dodge pressed fails the phase rather
## than quietly waiting for the next one.
func _dodge_at(lead: float) -> bool:
	if _dummy.attack_phase() != TrainingDummy.TELEGRAPH_PHASE:
		_all_passed = check(false, "the dodge was pressed before the dummy's hit landed")
		_finish()
		return false
	if _dummy.time_until_hit() > lead or not _is_fool_idle():
		return false
	_press(InputActions.DODGE)
	_step += 1
	return true


## Record how far the Fool moved since the last sample.
func _sample_walk() -> void:
	var now := _fool.global_position
	_walk_samples.append(now.distance_to(_walk_from))
	_walk_from = now


## The mean of a sample set, or 0 for an empty one.
func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value: float in values:
		total += value
	return total / float(values.size())


## True while the Fool is standing free, so a new action would actually come out.
func _is_fool_idle() -> bool:
	return _fool_combat.controller().state() == MovesetController.State.IDLE


## Reach the composition root, which is NOT up yet in `_initialize` - the autoload
## layer is added after the main loop is initialised, which is why `cliff_test` waits
## for a frame before asking for a service too.
func _resolve_services() -> void:
	if _combat != null:
		return
	var services := root.get_node_or_null("Services")
	if services == null:
		return
	_combat = services.get(&"combat") as CombatService
	_fortune = services.get(&"fortune") as FortuneService
	_spread = services.get(&"spread") as PocketSpreadService
	_rose = services.get(&"rose") as WhiteRoseService
	_world_state = services.get(&"world_state") as WorldStateService
	if _combat == null:
		return
	_rules = _combat.rules()
	_combat.fool_defeated.connect(_on_fool_defeated)
	_combat.fool_revived.connect(_on_fool_revived)


## Put the Fool back on their mark, standing, facing the dummy.
func _reset_positions() -> void:
	_fool.global_position = FOOL_HOME
	_fool.velocity = Vector2.ZERO
	_fool.face_direction(Vector2.RIGHT)


## Put the dummy back to a clean standing state before a timed beat: no swing part
## way through, no stagger left over from the launcher (a staggered dummy drops its
## attack, which is the launcher working, not the fixture misbehaving), full health.
func _ready_the_dummy() -> void:
	_dummy.cancel_attack()
	_dummy.restore_full_health()


## An enemy hit for `damage`, thrown through the real `Combatant` path so the defence
## and the difficulty multiplier are exercised rather than bypassed.
func _enemy_hit(damage: int) -> HitEvent:
	return HitEvent.new(
		Faction.Id.BLANK,
		HitSpec.new(HitSpec.Kind.ENEMY_ATTACK, damage, HitSpec.Shape.ARC, 360.0, 400.0),
		_dummy.global_position,
		Vector2.LEFT,
		0.0
	)


func _advance_phase() -> void:
	_phase += 1
	_phase_frame = 0
	_step = 0


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true
	print("FAIL: " + description)
	return false


func _finish() -> void:
	Engine.time_scale = 1.0
	if _all_passed:
		print("COMBAT TEST: PASS")
		quit(0)
	else:
		print("COMBAT TEST: FAIL")
		quit(1)
