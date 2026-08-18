extends SceneTree

## Round 9, end to end, in a real scene with real physics: Pip's command wheel.
##
## The unit tests under `tests/unit/pip/` prove each piece on its own; this proves they
## are wired to each other, to round 7's combat loop and to round 8's Blanks - that the
## `pip_wheel` button really reaches `PipService`, that Fetch brings a thing back, that
## Seek finds a hidden thing, that Harry takes a Blank's attention off the Fool and
## gives it back, and that a Pip knocked to zero **retreats and returns rather than
## ending** (`docs/design/combat.md` §Pip).
##
## The fixture is `tests/fixtures/scenes/pip_arena.tscn`: the Fool and Pip from their
## own scenes, one `Fetchable`, one `Seekable`, and an `Encounter` holding a single Two
## of Swords. Its "ground" is a bare `Node2D`, for the reason `combat_test.gd` gives.
##
## **Nothing here waits on the wall clock.** Every beat is driven by physics frames and
## by what the service reports; where a duration matters it is asserted against the
## number in the rules table rather than against a stopwatch.
##
## **The service is INJECTED, with its own copy of the rules.** `PipCompanion` would
## have found the autoload's `PipService` by itself (and does, for the first few
## frames), but `attach_service()` is the contract, and a test-owned duplicate of
## `pip_rules.tres` lets the cooldowns be short enough to drive without touching the
## shipped definition - which nothing at runtime may write to.
##
## What each phase proves, in order:
##
##   1. the arena is wired: Pip has a health pool on the Fool's side and a companion;
##   2. holding `pip_wheel` up-left and releasing it fetches - through the real input;
##   3. Seek digs the hidden thing out and brings the news back;
##   4. Harry takes a Blank's attention off the Fool for the duration, and gives it back;
##   5. a Blank puts Pip to zero: he retreats, is never removed, and comes back whole;
##   6. the Fool goes down and Pip trots over and licks their face.

const ARENA_PATH := "res://tests/fixtures/scenes/pip_arena.tscn"
const PIP_RULES_PATH := "res://data/pip/pip_rules.tres"

## Physics frames to let pass before overlaps and services are believed.
const SETTLE_FRAMES := 6

## The most frames any one phase may take before the test calls it stuck.
const PHASE_FRAME_LIMIT := 1800

## Just inside the encounter's 220 px trigger, which the fixture puts at (700, 0).
const INSIDE_THE_TRIGGER := Vector2(500, 0)

## Where the Fool stands while Pip has the Blank: off the bearing Pip is on, so
## "the Blank is looking at the dog rather than at the Fool" is a thing this test can
## actually see rather than assume.
const FOOL_ASIDE := Vector2(700, 400)

## Where the Fool goes the moment the pin lapses: a bearing the Blank has never faced,
## far enough out that a Blank that wants the Fool has to walk. What "it went back to
## the Fool" is proven against - a Blank still pointing where it was pointing fails.
const FOOL_AFTER_PIN := Vector2(700, -500)

## Where Pip is put at the same moment, on the OPPOSITE side of the Blank from the
## Fool. He trots home from there, so for the whole of the assertion the dog and the
## Fool are two different directions and "it turned to the Fool" cannot be satisfied by
## still looking at the dog.
const PIP_AFTER_PIN := Vector2(700, 600)

## Test-only durations, written into a DUPLICATE of the rules resource. Long enough
## that "it held for the whole time" is a real assertion, short enough to drive.
const TEST_HARRY_SECONDS := 1.0
const TEST_SEEK_SECONDS := 0.4
const TEST_RETREAT_COOLDOWN := 1.0
const TEST_RETREAT_DISTANCE := 200.0

## Health Pip is given for the Harry phase, so that phase is about the Blank's
## attention rather than about whether a dog survives four seconds of a duelist. Put
## back before the phase that is about exactly that.
const PIP_TEST_HEALTH := 100000

## Health Pip is given for the retreat phase: one real swing from the Two of Swords
## must empty it. The phase is about what a zero DOES, and how many hits a dog takes is
## the combat-tuning pass's question rather than this test's.
const PIP_ONE_HIT_HEALTH := 1

## How long the pin holds for that phase. Long enough for the Blank to wind up and
## swing at the dog it has been given - the pin is what puts Pip in front of an enemy
## that is really trying to hit him.
const TEST_RETREAT_HARRY_SECONDS := 4.0

var _all_passed := true
var _phase := 0
var _phase_frame := 0
var _step := 0

var _scene: Node2D = null
var _fool: FoolBody = null
var _fool_combatant: Combatant = null
var _pip: PipFollower = null
var _companion: PipCompanion = null
var _pip_combatant: Combatant = null
var _item: Fetchable = null
var _earth: Seekable = null
var _ambush: Encounter = null
var _blank: Blank = null

var _combat: CombatService = null
var _rules: PipRules = null
var _service: PipService = null

## What the service and the props announced, in order.
var _issued: Array[int] = []
var _completed: Array[int] = []
var _refusals: Array[StringName] = []
var _found_count := 0
var _delivered_count := 0
var _retreated_count := 0
var _returned_count := 0
var _lick_count := 0

## Hits the Blank's own `Hitbox` reported on Pip's `Hurtbox`. The evidence that an
## enemy can really reach the dog, rather than that this test can call `take_hit`.
var _hits_on_pip := 0

## True once the pickup has been asserted, so it is asserted once rather than on every
## frame of the trot home.
var _saw_the_pickup := false

## Actions the test tapped: released at the top of the frame after next, so an edge is
## visible whichever order the engine walks the main loop and the nodes in.
var _release_now: Array[StringName] = []
var _release_next: Array[StringName] = []


func _initialize() -> void:
	var packed: PackedScene = load(ARENA_PATH)
	_scene = packed.instantiate() as Node2D
	root.add_child(_scene)
	_fool = _scene.get_node_or_null("Fool") as FoolBody
	_pip = _scene.get_node_or_null("Pip") as PipFollower
	_item = _scene.get_node_or_null("WoodenDog") as Fetchable
	_earth = _scene.get_node_or_null("DisturbedEarth") as Seekable
	_ambush = _scene.get_node_or_null("Ambush") as Encounter
	if _fool != null:
		_fool_combatant = _fool.get_node_or_null("Combatant") as Combatant
	if _pip != null:
		_companion = _pip.get_node_or_null("PipCompanion") as PipCompanion
		_pip_combatant = _pip.get_node_or_null("Combatant") as Combatant
	if _earth != null:
		_earth.found.connect(_on_found)


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
			return _phase_fetch()
		2:
			return _phase_seek()
		3:
			return _phase_harry()
		4:
			return _phase_the_retreat_that_is_not_a_death()
		5:
			return _phase_the_defeat_beat()
	_finish()
	return true


# --- Phase 0: the arena is wired ---------------------------------------------------


func _phase_setup() -> bool:
	if _phase_frame < SETTLE_FRAMES:
		return false
	_all_passed = check(_fool != null, "the arena holds the Fool from scenes/fool.tscn") and _all_passed
	_all_passed = check(_pip != null, "and Pip from scenes/pip.tscn") and _all_passed
	_all_passed = check(_companion != null, "with a PipCompanion on him") and _all_passed
	_all_passed = check(_item != null, "one Fetchable") and _all_passed
	_all_passed = check(_earth != null, "and one Seekable") and _all_passed
	if _fool == null or _pip == null or _companion == null or _item == null or _earth == null:
		_finish()
		return true
	_resolve_services()
	_all_passed = check(_combat != null, "the Services autoload owns a CombatService") and _all_passed
	if _combat == null:
		_finish()
		return true
	_all_passed = check(
		_pip_combatant != null and _pip_combatant.faction == Faction.Id.FOOL,
		"Pip is a Combatant on the Fool's side: enemies can hit him, the Fool cannot"
	) and _all_passed
	_all_passed = check(
		_pip.target_node() == _fool, "and he follows the Fool without being told twice"
	) and _all_passed
	_attach_test_service()
	_all_passed = check(_companion.service() == _service, "the scene injected Pip's service") and _all_passed
	_all_passed = check(
		_pip_combatant.health_capacity() == _rules.max_health,
		"whose rules table sized his health pool"
	) and _all_passed
	_all_passed = check(
		_service.state() == PipService.State.FOLLOWING, "and he starts at the Fool's heel"
	) and _all_passed
	_advance_phase()
	return false


# --- Phase 1: Fetch, through the real input path -------------------------------------


func _phase_fetch() -> bool:
	match _step:
		0:
			# The whole gesture: hold `pip_wheel`, aim up-left, release. Nothing else in
			# this test presses a button - the other two commands go through
			# `PipCompanion.issue()`, which is the same door the wheel knocks on.
			_press(InputActions.PIP_WHEEL)
			_press(InputActions.MOVE_UP)
			_press(InputActions.MOVE_LEFT)
			_step = 1
		1:
			if not _release_now.is_empty() or not _release_next.is_empty():
				return false
			# The button came up at the top of THIS frame, and the companion reads it
			# when the tree is walked, after this call returns. So the gesture is judged
			# on the next frame - which is the same "nothing physical has happened yet"
			# rule `tests/README.md` states for `_initialize`, one frame further in.
			_step = 2
		2:
			_all_passed = check(
				_issued == [int(PipCommand.Id.FETCH)],
				"holding the wheel up-left and letting go is a Fetch (%s)" % str(_issued)
			) and _all_passed
			_all_passed = check(
				_service.state() == PipService.State.FETCHING, "and Pip is away after it"
			) and _all_passed
			_all_passed = check(
				_pip.is_follow_suspended(), "with the follow suspended while he runs the errand"
			) and _all_passed
			_step = 3
		3:
			if _service.state() != PipService.State.FOLLOWING:
				if _service.phase() == PipService.Phase.RETURNING and not _saw_the_pickup:
					_saw_the_pickup = true
					_all_passed = check(
						_item.is_carried(), "he picks it up before he turns round"
					) and _all_passed
				return false
			_all_passed = check(_delivered_count == 1, "the item comes back to the Fool") and _all_passed
			_all_passed = check(_item.is_delivered(), "and knows it was delivered") and _all_passed
			_all_passed = check(
				_item.global_position.distance_to(_fool.global_position) < _rules.command_reach + 1.0,
				"at the Fool's feet"
			) and _all_passed
			_all_passed = check(
				_companion.carried() == null, "and out of Pip's teeth"
			) and _all_passed
			_all_passed = check(
				_completed == [int(PipCommand.Id.FETCH)], "the command completed once"
			) and _all_passed
			_all_passed = check(
				not _pip.is_follow_suspended(), "and the follow is his own again"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 2: Seek --------------------------------------------------------------------


func _phase_seek() -> bool:
	match _step:
		0:
			_all_passed = check(
				_companion.issue(PipCommand.Id.SEEK), "Pip is sent to the disturbed earth"
			) and _all_passed
			_step = 1
		1:
			if _service.phase() != PipService.Phase.WORKING:
				return false
			_all_passed = check(
				_found_count == 0, "nothing is found while he is still digging"
			) and _all_passed
			_all_passed = check(
				_pip.global_position.distance_to(_earth.global_position) <= _rules.command_reach + 1.0,
				"and he digs at the hole rather than at a distance"
			) and _all_passed
			_step = 2
		2:
			if _found_count == 0:
				return false
			_all_passed = check(
				_service.phase() == PipService.Phase.RETURNING,
				"he backs out of the hole and trots it back (MQ00 §The Old Campsites)"
			) and _all_passed
			_all_passed = check(
				_earth.is_available(),
				"and the fixture's dig site is not one-shot, so an early Seek cannot spend it"
			) and _all_passed
			_step = 3
		3:
			if _service.state() != PipService.State.FOLLOWING:
				return false
			_all_passed = check(
				_completed.size() == 2 and _completed[1] == int(PipCommand.Id.SEEK),
				"and the Seek completes when he is back, not when the hole is open"
			) and _all_passed
			_fool.global_position = INSIDE_THE_TRIGGER
			_advance_phase()
	return false


# --- Phase 3: Harry ---------------------------------------------------------------------


func _phase_harry() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES * 2:
				return false
			_blank = _first_standing()
			_all_passed = check(
				_blank != null, "walking between the stones raises the Two of Swords"
			) and _all_passed
			if _blank == null:
				_finish()
				return true
			# This phase is about the Blank's attention, not about whether a dog can
			# take four seconds of a duelist. Put back before the phase that is.
			_pip_combatant.set_max_health(PIP_TEST_HEALTH)
			_step = 1
		1:
			# Pip has to be near enough to be sent; he follows, so give him the frames.
			if _pip.global_position.distance_to(_blank.global_position) > _rules.command_radius:
				return false
			# The scene answers `target_requested` with the Blank - `_on_target_requested`
			# below, exactly as `the_cliff.gd` does. Nothing pre-loads the target: an
			# answer given outside the request is ignored by design.
			_all_passed = check(
				_companion.issue(PipCommand.Id.HARRY), "and the scene sends Pip at it"
			) and _all_passed
			_step = 2
		2:
			if _service.phase() != PipService.Phase.WORKING:
				return false
			_all_passed = check(
				_blank.distraction() == _pip, "Pip has the Blank's attention"
			) and _all_passed
			_all_passed = check(
				_blank.brain().is_distracted(),
				"so its brain is harried (combat.md §Pip: it holds the enemy's attention)"
			) and _all_passed
			# Move the Fool onto a different bearing, so "looking at the dog" is
			# something this test can see rather than assume.
			_fool.global_position = FOOL_ASIDE
			_step = 3
		3:
			if _phase_frame < SETTLE_FRAMES * 6:
				return false
			var to_pip := (_pip.global_position - _blank.global_position).normalized()
			var to_fool := (_fool.global_position - _blank.global_position).normalized()
			var facing := _blank.brain().facing()
			_all_passed = check(
				facing.dot(to_pip) > facing.dot(to_fool),
				"and it faces the dog rather than the Fool while the pin holds"
			) and _all_passed
			_step = 4
		4:
			if _blank.brain().is_distracted():
				return false
			# The pin has lapsed. Move BOTH of them: the Fool onto a bearing this Blank
			# has never faced, and Pip to the far side, so that what the Blank does next
			# cannot be satisfied by carrying on pointing where it was already pointing.
			_fool.global_position = FOOL_AFTER_PIN
			_pip.global_position = PIP_AFTER_PIN
			_step = 5
		5:
			# The WAIT is "the Blank is walking again" - it may still be finishing a
			# swing at the dog when the pin lapses, and every attacking state pins the
			# movement to zero. The ASSERTION is where it walks, which is a different
			# fact: `BlankBrain` builds that vector out of the target position its
			# perception was filled with, so a Blank whose perception still held Pip
			# would walk at Pip.
			if _blank.brain().movement_intent().is_zero_approx():
				return false
			var to_fool := (_fool.global_position - _blank.global_position).normalized()
			var to_pip := (_pip.global_position - _blank.global_position).normalized()
			_all_passed = check(
				_blank.distraction() == null, "the pin ends and the Blank looks up again"
			) and _all_passed
			_all_passed = check(
				to_fool.dot(to_pip) < 0.5,
				"with the dog and the Fool on genuinely different bearings from it"
			) and _all_passed
			_all_passed = check(
				_blank.brain().movement_intent().normalized().dot(to_fool) > 0.99,
				"and it walks at where the FOOL is: Harry is brief, and the doc says so"
			) and _all_passed
			_step = 6
		6:
			if _service.state() != PipService.State.FOLLOWING:
				return false
			_all_passed = check(
				_completed.size() == 3 and _completed[2] == int(PipCommand.Id.HARRY),
				"Pip comes back off the pin"
			) and _all_passed
			_pip_combatant.set_max_health(_rules.max_health)
			_advance_phase()
	return false


# --- Phase 4: the retreat, which is not a death -------------------------------------------


func _phase_the_retreat_that_is_not_a_death() -> bool:
	match _step:
		0:
			# Nothing in this phase throws a hit. The Blank swings, its own `Hitbox`
			# finds Pip's `Hurtbox`, and the hit rule decides - which is the only way to
			# know that the collision layers on `scenes/pip.tscn` really do let an enemy
			# reach the dog. Sending Pip to pin it is what puts him in front of an enemy
			# that is trying to hit him; his health is put out of reach until he is
			# there, so the hit that counts is the one landed on a pinned dog.
			_watch_the_blanks_swings()
			_pip_combatant.set_max_health(PIP_TEST_HEALTH)
			_rules.harry_seconds = TEST_RETREAT_HARRY_SECONDS
			if _pip.global_position.distance_to(_blank.global_position) > _rules.command_radius:
				return false
			_all_passed = check(
				_companion.issue(PipCommand.Id.HARRY), "Pip is sent back at the Blank"
			) and _all_passed
			_step = 1
		1:
			if _service.phase() != PipService.Phase.WORKING:
				return false
			# He is on it, and the Blank is committed to him. One swing's worth of
			# health from here: how many hits a dog takes is the combat-tuning pass's
			# question, and this phase is about what a zero DOES.
			_hits_on_pip = 0
			_pip_combatant.set_max_health(PIP_ONE_HIT_HEALTH)
			_step = 2
		2:
			if _retreated_count == 0:
				return false
			_all_passed = check(
				_hits_on_pip == 1,
				"the Two of Swords' own swing reaches Pip's hurtbox (%d hits)" % _hits_on_pip
			) and _all_passed
			_all_passed = check(_pip_combatant.health() == 0, "and empties his pool") and _all_passed
			_all_passed = check(
				_retreated_count == 1, "a Blank puts Pip to zero and he yelps and goes"
			) and _all_passed
			_all_passed = check(
				_service.state() == PipService.State.RETREATED, "out of the fight"
			) and _all_passed
			_all_passed = check(
				is_instance_valid(_pip) and _pip.get_parent() != null,
				"and he is STILL IN THE SCENE - combat.md §Pip: Pip cannot die"
			) and _all_passed
			_all_passed = check(
				_pip.visible, "still drawn, because nothing about this is a death"
			) and _all_passed
			_step = 3
		3:
			if _service.phase() != PipService.Phase.WORKING:
				return false
			_all_passed = check(
				_pip.global_position.distance_to(_blank.global_position) > _rules.command_reach,
				"he really leaves the fight before he shakes it off"
			) and _all_passed
			_all_passed = check(
				_returned_count == 0, "and is gone for the whole cooldown"
			) and _all_passed
			_step = 4
		4:
			if _returned_count == 0:
				return false
			_all_passed = check(
				_service.state() == PipService.State.FOLLOWING, "then he comes back"
			) and _all_passed
			_all_passed = check(
				_pip_combatant.health() == _pip_combatant.health_capacity(),
				"shaken off and whole again"
			) and _all_passed
			_all_passed = check(
				_refusals.size() > 0 and _refusals[0] == PipService.REASON_RETREATED,
				"and nothing reached him while he was out (%s)" % str(_refusals)
			) and _all_passed
			# The defeat beat is next and it is the Fool's, not Pip's: put the dog back
			# out of the Blank's reach so a stray swing cannot start a second retreat
			# in the middle of it.
			_pip_combatant.set_max_health(PIP_TEST_HEALTH)
			_advance_phase()
	return false


## Refused commands are collected while Pip is out, at the top of the phase above.
##
## The command goes through `issue()`, which asks the scene for a target the same way
## every other command in this test does: `_on_target_requested` answers with the
## disturbed earth, and `PipService` refuses him anyway, because he is out.
func _try_a_command_while_he_is_out() -> void:
	_companion.issue(PipCommand.Id.SEEK)


# --- Phase 5: the defeat beat --------------------------------------------------------------


func _phase_the_defeat_beat() -> bool:
	match _step:
		0:
			_fool.global_position = FOOL_ASIDE
			_fool_combatant.take_hit(_lethal_hit_on_the_fool())
			_all_passed = check(
				_combat.is_defeated(), "the Fool goes down (combat.md §Defeat, 1)"
			) and _all_passed
			_all_passed = check(
				_service.state() == PipService.State.DEFEAT_BEAT,
				"and Pip is already on his way over - no region has to remember to stage it"
			) and _all_passed
			_step = 1
		1:
			if _lick_count == 0:
				return false
			_all_passed = check(
				_pip.global_position.distance_to(_fool.global_position) <= _rules.command_reach + 1.0,
				"he trots to the Fool and licks their face (combat.md §Defeat, 2)"
			) and _all_passed
			_all_passed = check(
				_service.state() == PipService.State.DEFEAT_BEAT, "and stays until they are up"
			) and _all_passed
			_combat.revive_at_waystation()
			_step = 2
		2:
			_all_passed = check(
				_service.state() == PipService.State.FOLLOWING,
				"the Fool wakes at the Waystation, Pip already beside them (§Defeat, 3)"
			) and _all_passed
			_all_passed = check(_lick_count == 1, "and the beat played once") and _all_passed
			_finish()
			return true
	return false


# --- Signals ------------------------------------------------------------------------------


func _on_command_issued(command: PipCommand.Id) -> void:
	_issued.append(int(command))


func _on_command_completed(command: PipCommand.Id) -> void:
	_completed.append(int(command))


func _on_command_refused(_command: PipCommand.Id, reason: StringName) -> void:
	_refusals.append(reason)


func _on_found() -> void:
	_found_count += 1


func _on_fetch_delivered(_item: Node2D) -> void:
	_delivered_count += 1


func _on_pip_retreated() -> void:
	_retreated_count += 1
	# The one moment worth asking whether anything can reach him: the doc says nothing
	# does until the cooldown is up.
	_try_a_command_while_he_is_out()


func _on_pip_returned() -> void:
	_returned_count += 1


func _on_licked() -> void:
	_lick_count += 1


# --- The scene's own job -------------------------------------------------------------------


## Answer Pip's wheel with something to run at, exactly as `scripts/the_cliff.gd` does.
func _on_target_requested(command: PipCommand.Id, from: Vector2, radius: float) -> void:
	var candidate: Node2D = null
	match command:
		PipCommand.Id.FETCH:
			candidate = _item if _item != null and _item.is_available() else null
		PipCommand.Id.SEEK:
			candidate = _earth if _earth != null and _earth.is_available() else null
		PipCommand.Id.HARRY:
			candidate = _blank
	if candidate == null or from.distance_to(candidate.global_position) > radius:
		return
	_companion.provide_target(command, candidate)


# --- Setup --------------------------------------------------------------------------------


## Reach the composition root, which is NOT up in `_initialize`.
func _resolve_services() -> void:
	if _combat != null:
		return
	var services := root.get_node_or_null("Services")
	if services == null:
		return
	_combat = services.get(&"combat") as CombatService
	if _ambush != null:
		_ambush.attach_services(_combat, services.get(&"enemies") as EnemyService)


## Build Pip's service over a duplicate of the shipped rules, with the durations short
## enough to drive - see the class doc for why this is a duplicate and not an edit.
func _attach_test_service() -> void:
	_rules = (load(PIP_RULES_PATH) as PipRules).duplicate() as PipRules
	_rules.harry_seconds = TEST_HARRY_SECONDS
	_rules.seek_reveal_seconds = TEST_SEEK_SECONDS
	_rules.retreat_cooldown_seconds = TEST_RETREAT_COOLDOWN
	_rules.retreat_distance = TEST_RETREAT_DISTANCE
	_service = PipService.new(_rules, _combat)
	_service.command_issued.connect(_on_command_issued)
	_service.command_completed.connect(_on_command_completed)
	_service.command_refused.connect(_on_command_refused)
	_service.fetch_delivered.connect(_on_fetch_delivered)
	_service.pip_retreated.connect(_on_pip_retreated)
	_service.pip_returned.connect(_on_pip_returned)
	_companion.attach_service(_service)
	if not _companion.target_requested.is_connected(_on_target_requested):
		_companion.target_requested.connect(_on_target_requested)
	if not _companion.licked.is_connected(_on_licked):
		_companion.licked.connect(_on_licked)


## The Blank still on its feet, or `null`.
func _first_standing() -> Blank:
	if _ambush == null:
		return null
	for member: Blank in _ambush.members():
		if member != null and is_instance_valid(member) and member.is_awake() and member.is_alive():
			return member
	return null


## Listen to the Blank's own swings, so a hit on Pip is something this test WATCHED
## rather than something it threw. Idempotent: the phase calls it every frame it waits.
func _watch_the_blanks_swings() -> void:
	if _blank == null:
		return
	var hitbox := _blank.get_node_or_null("Combatant/Hitbox") as Hitbox
	if not check(hitbox != null, "the Blank swings through a Hitbox of its own"):
		_all_passed = false
		return
	if not hitbox.hit_landed.is_connected(_on_blank_hit_landed):
		hitbox.hit_landed.connect(_on_blank_hit_landed)


## One of those swings landed. Only the ones that found the dog are counted.
func _on_blank_hit_landed(hurtbox: Hurtbox, _spec: HitSpec, _result: HitResult.Id) -> void:
	if hurtbox != null and hurtbox.combatant() == _pip_combatant:
		_hits_on_pip += 1


## One hit big enough to empty the Fool's pool, thrown by the side that really is
## hostile to them. `Faction.is_hostile()` is what decides it lands, not this test.
func _lethal_hit_on_the_fool() -> HitEvent:
	return HitEvent.new(
		Faction.Id.BLANK,
		HitSpec.new(
			HitSpec.Kind.ENEMY_ATTACK,
			_fool_combatant.health_capacity(),
			HitSpec.Shape.ARC,
			360.0,
			400.0
		),
		_fool.global_position,
		Vector2.RIGHT,
		0.0
	)


## Press an action and hold it for two physics frames, for the reason
## `tests/enemies_test.gd` gives.
func _press(action: StringName) -> void:
	Input.action_press(action)
	if not _release_next.has(action):
		_release_next.append(action)


## Retire the taps whose two frames are up, before anything else this frame.
func _release_pressed() -> void:
	for action: StringName in _release_now:
		Input.action_release(action)
	_release_now = _release_next
	_release_next = []


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
		print("PIP TEST: PASS")
		quit(0)
	else:
		print("PIP TEST: FAIL")
		quit(1)
