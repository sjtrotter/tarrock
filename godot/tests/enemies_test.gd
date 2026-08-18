extends SceneTree

## Round 8, end to end, in a real scene with real physics.
##
## The unit tests under `tests/unit/enemies/` prove each piece on its own; this proves
## they are wired to each other and to round 7's combat loop - that walking into an
## authored volume raises three Blanks, that the Fool's own light string takes them
## down, that each one's card flutters free and its body goes back to the pool, that
## the encounter is cleared only when all three are down, and that a Blank's telegraph
## is a real thing the Fool can answer with a dodge.
##
## The fixture is `tests/fixtures/scenes/encounter_arena.tscn`: the Fool from
## `scenes/fool.tscn` and one `Encounter` carrying the three Twos MQ00 asks for - one
## Cups, one Swords, one Wands. Its "ground" is a bare `Node2D`, for the reason
## `combat_test.gd` gives: in the top-down grammar the floor is not a body.
##
## **Nothing here waits on the wall clock.** Every beat is driven by physics frames
## and by `Blank.time_until_hit()`, which is the fixture affordance that lets a dodge
## be pressed a known number of seconds before a hit lands without counting real time.
## `Input.action_press` is used rather than calling the controller, so the input path
## is part of what is proven, and a tap is HELD for two physics frames for the reason
## `combat_test.gd` spells out.
##
## What each phase proves, in order:
##
##   1. the arena is wired and the pool is full before the fight exists;
##   2. walking into the volume raises the three and locks the Pocket Spread - and
##      entering it does NOT clear it;
##   3. the Fool's light string takes them down one at a time; each defeat flutters a
##      card and returns a body; `cleared` waits for the third;
##   4. the whole fight instanced nothing and every body came home;
##   5. a Blank's telegraphed hit lands on a Fool who does not answer it;
##   6. a dodge timed against that telegraph is Fool's Chance;
##   7. a Cups Blank keeps its distance and lobs, which is the one suit whose hit
##      leaves its hand;
##   8. and the difficulty set on the `CombatService` really reaches a Blank's tell.

const ARENA_PATH := "res://tests/fixtures/scenes/encounter_arena.tscn"

## Physics frames to let pass before overlaps and services are believed.
const SETTLE_FRAMES := 6

## The most frames any one phase may take before the test calls it stuck. The fight
## phase is the long one: three Blanks at two light strings each.
const PHASE_FRAME_LIMIT := 2400

## Where the Fool starts, and where the encounter stands (the fixture's own numbers).
const FOOL_HOME := Vector2.ZERO
const AMBUSH_CENTRE := Vector2(400, 0)

## Just inside the encounter's 220 px trigger.
const INSIDE_THE_TRIGGER := Vector2(260, 0)

## How far from a Blank the Fool stands to swing at it. Inside the Bindle's light
## reach (`CombatRules.light_radius`, 96) with room to spare.
const SWING_DISTANCE := 64.0

## Health the Fool is given for the fight phase, so the phase is about the Blanks
## rather than about whether the Fool survives three of them at once. Put back before
## the defensive phases, which are about exactly that.
const FOOL_TEST_HEALTH := 100000

## The accessibility slider used for the Fool's Chance phase, in seconds. Wide enough
## that a one-frame difference in when a press is seen cannot decide the test - the
## same reason and the same value `combat_test.gd` uses.
const SLIDER_SECONDS := 0.10

## How long before the Blank's hit lands the dodge is pressed.
const PERFECT_DODGE_LEAD := 0.14

## Where the Cups Blank is stood up for the lob phase: inside its own reach (420) and
## outside its stand-off range (260), so it throws rather than backing away - and far
## enough that no melee suit in the roster could have reached the Fool from there.
const CUPS_STANDOFF := 300.0

var _all_passed := true
var _phase := 0
var _phase_frame := 0
var _step := 0

var _scene: Node2D = null
var _fool: FoolBody = null
var _fool_combat: FoolCombat = null
var _fool_combatant: Combatant = null
var _ambush: Encounter = null

var _combat: CombatService = null
var _enemies: EnemyService = null
var _spread: PocketSpreadService = null
var _rules: CombatRules = null

## What the encounter announced, in order.
var _engaged_count := 0
var _cleared_count := 0
var _defeats: Array[StringName] = []

## Every card the roster reported free, as "SUIT:RANK".
var _flutters: PackedStringArray = PackedStringArray()

## The pool's instance count at the moment the fight started.
var _instances_at_engage := 0

## One Blank raised by hand for the defensive phases, and what its swings did.
var _lone_blank: Blank = null
var _incoming: Array[int] = []

## What a Blank raised at Journey tells for, kept to compare Trial's against.
var _journey_telegraph := 0.0

## Actions the test tapped: released at the top of the frame after next, so an edge is
## visible whichever order the engine walks the main loop and the nodes in.
var _release_now: Array[StringName] = []
var _release_next: Array[StringName] = []


func _initialize() -> void:
	var packed: PackedScene = load(ARENA_PATH)
	_scene = packed.instantiate() as Node2D
	root.add_child(_scene)
	_fool = _scene.get_node_or_null("Fool") as FoolBody
	_ambush = _scene.get_node_or_null("Ambush") as Encounter
	if _fool != null:
		_fool_combat = _fool.get_node_or_null("FoolCombat") as FoolCombat
		_fool_combatant = _fool.get_node_or_null("Combatant") as Combatant
	if _ambush != null:
		_ambush.engaged.connect(_on_engaged)
		_ambush.cleared.connect(_on_cleared)
		_ambush.member_defeated.connect(_on_member_defeated)


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
			return _phase_walk_in()
		2:
			return _phase_fight()
		3:
			return _phase_the_cards_go_home()
		4:
			return _phase_a_blank_lands_a_hit()
		5:
			return _phase_a_dodge_answers_the_telegraph()
		6:
			return _phase_cups_lobs_from_its_range()
		7:
			return _phase_difficulty_reaches_the_tell()
	_finish()
	return true


# --- Phase 0: the arena is wired -------------------------------------------------


func _phase_setup() -> bool:
	if _phase_frame < SETTLE_FRAMES:
		return false
	_resolve_services()
	_all_passed = check(_fool != null, "the arena holds the Fool from scenes/fool.tscn") and _all_passed
	_all_passed = check(_ambush != null, "and one authored Encounter") and _all_passed
	_all_passed = check(_combat != null, "the Services autoload owns a CombatService") and _all_passed
	_all_passed = check(_enemies != null, "and an EnemyService") and _all_passed
	if _fool == null or _ambush == null or _combat == null or _enemies == null:
		_finish()
		return true
	var pool := _ambush.pool()
	_all_passed = check(pool != null, "the encounter owns a pool") and _all_passed
	if pool == null:
		_finish()
		return true
	_all_passed = check(
		pool.instance_count() > 0,
		"whose bodies exist before the fight does (technical.md: never instance on the hot path)"
	) and _all_passed
	_all_passed = check(
		pool.live_count() == 0, "with nothing standing in the world yet"
	) and _all_passed
	_all_passed = check(
		_enemies.alive_count() == 0, "and nothing on the roster"
	) and _all_passed
	_all_passed = check(
		not _ambush.is_engaged() and not _ambush.is_cleared(),
		"and the fight neither started nor won"
	) and _all_passed
	# The Fool is not the subject of the fight phase - three Blanks hitting back for
	# thirty seconds is. Put back before the phases that ARE about being hit.
	_fool_combatant.set_max_health(FOOL_TEST_HEALTH)
	_advance_phase()
	return false


# --- Phase 1: walking in ----------------------------------------------------------


func _phase_walk_in() -> bool:
	match _step:
		0:
			_fool.global_position = INSIDE_THE_TRIGGER
			_step = 1
		1:
			if _phase_frame < SETTLE_FRAMES * 2:
				return false
			_all_passed = check(
				_engaged_count == 1, "walking into the volume starts the fight, once"
			) and _all_passed
			_all_passed = check(
				_ambush.standing_count() == 3,
				"and three figures rise from the long grass (MQ00 §The Waystation Approach)"
			) and _all_passed
			# The MQ00 lesson, as an assertion: entering the volume is not clearing it.
			_all_passed = check(
				_cleared_count == 0 and not _ambush.is_cleared(),
				"entering the volume does NOT clear the encounter"
			) and _all_passed
			_all_passed = check(
				_combat.engaged_count() == 3, "all three announced themselves to the fight"
			) and _all_passed
			_all_passed = check(
				_spread.in_combat(), "so the Pocket Spread is locked (progression.md)"
			) and _all_passed
			_all_passed = check(
				_enemies.alive_count() == 3, "and the roster knows about all three"
			) and _all_passed
			var suits: Array[int] = []
			for member: Blank in _ambush.members():
				suits.append(member.definition().suit)
			suits.sort()
			_all_passed = check(
				suits == [int(Suit.Id.CUPS), int(Suit.Id.SWORDS), int(Suit.Id.WANDS)],
				"one Cups, one Swords, one Wands - the three MQ00 names"
			) and _all_passed
			_instances_at_engage = _ambush.pool().instance_count()
			_advance_phase()
	return false


# --- Phase 2: the fight -----------------------------------------------------------


## The Fool takes them down one at a time with the light string, standing next to
## whichever is still up. The Fool is repositioned rather than walked because this
## phase is about the enemies and the hit path, not about pathing.
func _phase_fight() -> bool:
	var target := _first_standing()
	if target == null:
		_all_passed = check(
			_cleared_count == 1, "the encounter is cleared once every member is down"
		) and _all_passed
		_all_passed = check(_ambush.is_cleared(), "and the latch is set") and _all_passed
		_all_passed = check(
			_defeats.size() == 3, "with one defeat announced per member (%s)" % str(_defeats)
		) and _all_passed
		_advance_phase()
		return false
	# One clear rule for the whole phase: stand beside whoever is still up, face them,
	# and swing whenever the moveset is free to.
	var offset := Vector2.LEFT * SWING_DISTANCE
	_fool.global_position = target.global_position + offset
	_fool.velocity = Vector2.ZERO
	_fool.face_direction(-offset)
	var controller := _fool_combat.controller()
	if controller.state() == MovesetController.State.IDLE:
		_press(InputActions.ATTACK_LIGHT)
	# `cleared` must not arrive early: it is a gate, and a gate that opened on the
	# second of three would be the MQ00 bug in a new place.
	if _cleared_count != 0:
		_all_passed = check(false, "the encounter cleared while somebody was still standing")
		_finish()
		return true
	return false


# --- Phase 3: the cards go home ----------------------------------------------------


func _phase_the_cards_go_home() -> bool:
	# `combat.md` §Enemies: the body "slumps and fades while the card it bore flutters
	# free". The flutter is a timer, so this waits for it rather than asserting it on
	# the frame of the defeat.
	if _flutters.size() < 3 and _phase_frame < PHASE_FRAME_LIMIT - 1:
		return false
	var pool := _ambush.pool()
	_all_passed = check(
		_flutters.size() == 3, "every defeated Blank's card flutters free (%s)" % str(_flutters)
	) and _all_passed
	var expected := PackedStringArray([
		"%d:%d" % [int(Suit.Id.CUPS), int(Rank.Id.TWO)],
		"%d:%d" % [int(Suit.Id.SWORDS), int(Rank.Id.TWO)],
		"%d:%d" % [int(Suit.Id.WANDS), int(Rank.Id.TWO)],
	])
	var sorted_flutters := _flutters.duplicate()
	sorted_flutters.sort()
	_all_passed = check(
		sorted_flutters == expected,
		"each card carries the suit and rank it was, so a new bearer can take it up"
	) and _all_passed
	_all_passed = check(
		pool.live_count() == 0, "and every body has gone back to the pool"
	) and _all_passed
	_all_passed = check(
		pool.instance_count() == _instances_at_engage,
		"the whole fight instanced nothing (technical.md §Performance guardrails)"
	) and _all_passed
	_all_passed = check(pool.grew_by() == 0, "and needed nothing new") and _all_passed
	_all_passed = check(
		_enemies.alive_count() == 0, "the roster is empty again"
	) and _all_passed
	_all_passed = check(
		not _combat.is_in_combat(), "the fight is over"
	) and _all_passed
	_all_passed = check(
		not _spread.in_combat(), "so the Pocket Spread unlocks"
	) and _all_passed
	_advance_phase()
	return false


# --- Phase 4: a telegraphed hit lands ----------------------------------------------


func _phase_a_blank_lands_a_hit() -> bool:
	match _step:
		0:
			_raise_a_lone_blank()
			if _lone_blank == null:
				_finish()
				return true
			_step = 1
		1:
			# Stand still inside its reach and do nothing: the telegraph is an offer,
			# and a Fool who does not answer it gets hit.
			_hold_still_beside_the_blank()
			if _incoming.is_empty():
				return false
			_all_passed = check(
				_incoming[0] == HitResult.Id.DAMAGED,
				"a Blank's swing lands on a Fool who does not answer it"
			) and _all_passed
			_all_passed = check(
				_fool_combatant.health() < _fool_combatant.health_capacity(),
				"and costs the Fool petals off the White Rose"
			) and _all_passed
			_all_passed = check(
				_lone_blank.brain().stats().damage > 0, "for the damage its stat block says"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 5: the dodge answers it --------------------------------------------------


func _phase_a_dodge_answers_the_telegraph() -> bool:
	match _step:
		0:
			# The accessibility slider, independent of difficulty (combat.md
			# §Accessibility). Widening it is what makes the beat deterministic at 60 Hz
			# - and proves the slider reaches a Blank's hit as well as a dummy's.
			_combat.set_perfect_window_bonus_seconds(SLIDER_SECONDS)
			_fool_combatant.restore_full_health()
			_incoming.clear()
			_step = 1
		1:
			# Wait for a FRESH telegraph rather than for a small `time_until_hit()`:
			# that reads 0 through the active window too, so timing against it alone
			# would press dodge after the hit had already been thrown.
			_hold_still_beside_the_blank()
			if _lone_blank.brain().state() != BlankBrain.State.TELEGRAPH:
				return false
			_incoming.clear()
			_step = 2
		2:
			# `Blank.time_until_hit()` is the fixture affordance: the dodge is pressed a
			# known number of seconds before the hit, never a known number of
			# milliseconds after a clock reading.
			_hold_still_beside_the_blank()
			if _lone_blank.time_until_hit() > PERFECT_DODGE_LEAD:
				return false
			if _fool_combat.controller().state() != MovesetController.State.IDLE:
				return false
			_press(InputActions.DODGE)
			_step = 3
		3:
			if _incoming.is_empty():
				return false
			_all_passed = check(
				_incoming[0] == HitResult.Id.DODGED_PERFECT,
				"a dodge timed against a real Blank's telegraph is a Fool's Chance"
			) and _all_passed
			_all_passed = check(
				_combat.is_fools_chance_active(), "which slows the world"
			) and _all_passed
			_all_passed = check(
				_fool_combatant.health() == _fool_combatant.health_capacity(),
				"and costs the Fool nothing"
			) and _all_passed
			_combat.end_fools_chance()
			_advance_phase()
	return false


# --- Phase 6: the Cups lob -----------------------------------------------------------


## `combat.md` §Enemies: Cups are "fluid skirmishers and ranged lobbers... harass at
## range and reposition". The Fool stands at a distance no melee suit could reach from
## and is hit anyway - which is the whole of what makes the suit a different fight.
func _phase_cups_lobs_from_its_range() -> bool:
	match _step:
		0:
			_retire_the_lone_blank()
			_raise_a_lone_blank(EnemyIds.BLANK_CUPS_TWO, CUPS_STANDOFF)
			if _lone_blank == null:
				_finish()
				return true
			var stats := _lone_blank.brain().stats()
			_all_passed = check(stats.is_ranged, "a Cups Blank fights at range") and _all_passed
			_all_passed = check(
				CUPS_STANDOFF > _blank_reach(EnemyIds.BLANK_SWORDS_TWO),
				"and the Fool is standing where no Swords Blank could touch them"
			) and _all_passed
			_step = 1
		1:
			# The Fool holds their ground; the Cups Blank should NOT close on them.
			_fool.global_position = FOOL_HOME
			_fool.velocity = Vector2.ZERO
			if _incoming.is_empty():
				return false
			_all_passed = check(
				_incoming[0] == HitResult.Id.DAMAGED, "its lob reaches the Fool and lands"
			) and _all_passed
			_all_passed = check(
				_fool_combatant.health() < _fool_combatant.health_capacity(),
				"and costs them petals"
			) and _all_passed
			_all_passed = check(
				_lone_blank.global_position.distance_to(_fool.global_position)
					> _lone_blank.brain().stats().preferred_range * 0.9,
				"and it never closed inside the range it likes"
			) and _all_passed
			_advance_phase()
	return false


# --- Phase 7: difficulty reaches the tell ---------------------------------------------


## `combat.md` §Difficulty modes: Trial has "tightened timing windows and telegraphs".
##
## `BlankBrain` is unit-tested against whatever multiplier it is handed; what is NOT
## provable there is the wiring - that the multiplier a real Blank runs on comes from
## the `CombatService` the scene attached, through `Blank._apply_difficulty()`. So this
## sets the mode on the service, raises a body out of the pool, and reads the tell off
## its brain. `systems/enemies/README.md`'s "there is no difficulty field on this side"
## is the claim under test.
func _phase_difficulty_reaches_the_tell() -> bool:
	match _step:
		0:
			_retire_the_lone_blank()
			_combat.set_difficulty(DifficultyMode.Id.JOURNEY)
			_raise_a_lone_blank()
			if _lone_blank == null:
				_finish()
				return true
			_journey_telegraph = _lone_blank.brain().telegraph_seconds()
			_all_passed = check(
				_journey_telegraph > 0.0, "a Blank raised at Journey has a tell to shorten"
			) and _all_passed
			_step = 1
		1:
			# A fresh body for the tightened mode: difficulty is applied when a Blank is
			# configured and when a service is attached, which is exactly what raising one
			# out of the pool does.
			_retire_the_lone_blank()
			_combat.set_difficulty(DifficultyMode.Id.TRIAL)
			_raise_a_lone_blank()
			if _lone_blank == null:
				_finish()
				return true
			var trial := _lone_blank.brain().telegraph_seconds()
			_all_passed = check(
				trial < _journey_telegraph,
				"Trial tightens a real Blank's telegraph: %.3f s against Journey's %.3f s"
				% [trial, _journey_telegraph]
			) and _all_passed
			_all_passed = check(
				is_equal_approx(
					_lone_blank.brain().difficulty_multiplier(),
					_rules.timing_window_multiplier(DifficultyMode.Id.TRIAL)
				),
				"and the number it used is CombatRules', not a copy on the enemy side"
			) and _all_passed
			_all_passed = check(
				trial >= EnemyRules.MIN_TELEGRAPH_SECONDS,
				"while still clearing the floor no difficulty may get under"
			) and _all_passed
			# Left as the game's default, so no later phase runs on Trial.
			_combat.set_difficulty(DifficultyMode.Id.JOURNEY)
			_advance_phase()
	return false


# --- Driving ---------------------------------------------------------------------


## The first member still standing, or `null` when they are all down.
func _first_standing() -> Blank:
	for member: Blank in _ambush.members():
		if member != null and is_instance_valid(member) and member.is_awake() and member.is_alive():
			return member
	return null


## Take one Blank out of the encounter's pool by hand and stand it up next to the
## Fool. The encounter is spent by now (it clears once), and these two phases are
## about one telegraph rather than about an ambush.
func _raise_a_lone_blank(enemy_id: StringName = EnemyIds.BLANK_SWORDS_TWO, at_distance: float = 70.0) -> void:
	var pool := _ambush.pool()
	var definition := _enemies.definition(enemy_id)
	if pool == null or definition == null:
		_all_passed = check(false, "a Blank could be raised for the defensive phases")
		return
	# `restore_full_health()` rests the White Rose, which IS the Fool's health
	# (issue #11) - nothing sizes a pool here because there is no pool to size.
	_fool_combatant.restore_full_health()
	_fool.global_position = FOOL_HOME
	_lone_blank = pool.acquire(definition, _enemies.rules())
	if _lone_blank == null:
		_all_passed = check(false, "the pool had a body to raise")
		return
	_lone_blank.attach_service(_combat)
	_lone_blank.rise(FOOL_HOME + Vector2(at_distance, 0.0), Vector2.LEFT, _fool)
	var hitbox := _lone_blank.combatant().get_node_or_null("Hitbox") as Hitbox
	if hitbox != null:
		hitbox.hit_landed.connect(_on_blank_hit_landed)
	# A Cups Blank's hit leaves its hand, so the lobs are watched too - a test that
	# only watched the melee hitbox would sit through a whole barrage and see nothing.
	for lob: Projectile in _lone_blank.projectiles():
		if not lob.hit_landed.is_connected(_on_blank_hit_landed):
			lob.hit_landed.connect(_on_blank_hit_landed)
	_incoming.clear()


## Put the Blank the last two phases used back in the pool, so the next one raised is
## a clean body rather than a Swords Two mid-recovery.
func _retire_the_lone_blank() -> void:
	if _lone_blank == null or not is_instance_valid(_lone_blank):
		return
	var hitbox := _lone_blank.combatant().get_node_or_null("Hitbox") as Hitbox
	if hitbox != null and hitbox.hit_landed.is_connected(_on_blank_hit_landed):
		hitbox.hit_landed.disconnect(_on_blank_hit_landed)
	for lob: Projectile in _lone_blank.projectiles():
		if lob.hit_landed.is_connected(_on_blank_hit_landed):
			lob.hit_landed.disconnect(_on_blank_hit_landed)
	_ambush.pool().release(_lone_blank)
	_lone_blank = null


## The reach of one enemy's own swing, off its stat block rather than off a number
## typed here.
func _blank_reach(enemy_id: StringName) -> float:
	var stats := _enemies.stats(enemy_id)
	return 0.0 if stats == null else stats.attack_radius


## Keep the Fool standing exactly where the Blank can reach, doing nothing. The Blank
## walks in on its own; this only stops the Fool drifting out of its arc.
func _hold_still_beside_the_blank() -> void:
	if _lone_blank == null:
		return
	_fool.global_position = _lone_blank.global_position + Vector2.LEFT * 50.0
	_fool.velocity = Vector2.ZERO
	_fool.face_direction(Vector2.RIGHT)


# --- Signals -----------------------------------------------------------------------


func _on_engaged() -> void:
	_engaged_count += 1


func _on_cleared() -> void:
	_cleared_count += 1


func _on_member_defeated(blank: Blank, _remaining: int) -> void:
	if blank != null and blank.definition() != null:
		_defeats.append(blank.definition().id)


func _on_card_fluttered(suit: int, rank: int, _from_position: Vector2) -> void:
	_flutters.append("%d:%d" % [suit, rank])


func _on_blank_hit_landed(_hurtbox: Hurtbox, _spec: HitSpec, result: HitResult.Id) -> void:
	_incoming.append(result)


# --- Input -------------------------------------------------------------------------


## Tap an action: pressed now, released two frames on. Two, for the reason
## `combat_test.gd` gives - which frame an edge is seen on depends on the order the
## engine walks the main loop and the nodes in.
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


# --- Setup ---------------------------------------------------------------------------


## Reach the composition root, which is NOT up in `_initialize` - the autoload layer is
## added after the main loop is initialised.
func _resolve_services() -> void:
	if _combat != null:
		return
	var services := root.get_node_or_null("Services")
	if services == null:
		return
	_combat = services.get(&"combat") as CombatService
	_enemies = services.get(&"enemies") as EnemyService
	_spread = services.get(&"spread") as PocketSpreadService
	if _combat != null:
		_rules = _combat.rules()
	if _enemies != null:
		_enemies.card_fluttered.connect(_on_card_fluttered)
	if _ambush != null:
		_ambush.attach_services(_combat, _enemies)


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
		print("ENEMIES TEST: PASS")
		quit(0)
	else:
		print("ENEMIES TEST: FAIL")
		quit(1)
