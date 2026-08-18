extends TarrockTest

## `BlankBrain`, driven frame by explicit frame.
##
## The brain has no tree, no physics and no clock, so every beat here is a delta this
## test chose and a perception this test filled in. **Nothing is compared to the wall
## clock**: a telegraph is asserted against the seconds `EnemyRules` says it should
## be, counted in frames of a fixed delta.
##
## What it proves, section by section, is `docs/design/combat.md` §Enemies read as
## behaviour: the telegraph -> commit -> recovery rota with no way to skip the tell,
## the four suits fighting differently, the court ranks doing their jobs, and the
## stagger the Fool's charged heavy opens actually interrupting a swing.

const CATALOG_PATH := "res://data/enemies/catalog.tres"
const RULES_PATH := "res://data/enemies/enemy_rules.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"

## One physics frame at 60 Hz. Every timing below is counted in these.
const FRAME := 1.0 / 60.0

## A generous ceiling on how many frames a beat may take before the test calls it
## stuck, so a brain that never leaves a state fails rather than hangs.
const FRAME_LIMIT := 600

var _catalog: EnemyCatalog = null
var _rules: EnemyRules = null

## Refilled between drives, never reallocated - the same discipline the `Blank` node
## keeps.
var _perception: BlankPerception = BlankPerception.new()


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_rules = load(RULES_PATH) as EnemyRules
	if _catalog == null:
		return
	for entry: EnemyDefinition in _catalog.entries:
		if entry != null:
			entry.clear_stats_cache()


# --- The rota -------------------------------------------------------------------


func test_the_full_cycle_runs_in_the_order_the_doc_asks_for() -> void:
	# `combat.md` §Philosophy: "every player action has a clear windup, a clear active
	# frame, and recovery the player can feel", and §Encounter philosophy demands the
	# same of enemies. IDLE -> AWARE -> APPROACH -> TELEGRAPH -> ATTACK -> RECOVER,
	# and back to APPROACH.
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	var stats := brain.stats()
	var seen: Array[int] = []
	brain.state_changed.connect(func(_from: BlankBrain.State, to: BlankBrain.State) -> void:
		seen.append(int(to))
	)
	assert_eq(brain.state(), BlankBrain.State.IDLE, "a Blank starts in the long grass")
	# Just inside reach, so APPROACH has nothing to close and the rota is not padded
	# by a walk whose length depends on a movement speed.
	_drive_until(brain, Vector2(stats.attack_radius * 0.5, 0.0), BlankBrain.State.RECOVER)
	assert_eq(
		seen,
		[
			int(BlankBrain.State.AWARE),
			int(BlankBrain.State.APPROACH),
			int(BlankBrain.State.TELEGRAPH),
			int(BlankBrain.State.ATTACK),
			int(BlankBrain.State.TELEGRAPH),
			int(BlankBrain.State.ATTACK),
			int(BlankBrain.State.TELEGRAPH),
			int(BlankBrain.State.ATTACK),
			int(BlankBrain.State.RECOVER),
		],
		"a Swords Blank notices, closes, tells, hits three times, then recovers"
	)


func test_the_telegraph_runs_for_exactly_the_seconds_the_rules_give_it() -> void:
	# The tell IS the answer the player is offered, so its length is not approximately
	# anything. Counted in frames of a known delta against the rules' own number.
	var brain := _brain_for(Suit.Id.WANDS, Rank.Id.TWO)
	if brain == null:
		return
	var stats := brain.stats()
	var target := Vector2(stats.attack_radius * 0.5, 0.0)
	_drive_until(brain, target, BlankBrain.State.TELEGRAPH)
	assert_almost_eq(
		brain.telegraph_seconds(),
		stats.telegraph_seconds,
		0.0001,
		"at Journey with no buffs, the telegraph is the rules' own number"
	)
	assert_almost_eq(
		brain.time_until_hit(), stats.telegraph_seconds, 0.0001, "and it starts full"
	)
	var frames := _drive_until(brain, target, BlankBrain.State.ATTACK)
	# Within one frame, not exactly one integer: a telegraph is counted in physics
	# frames, so the hit lands on the first frame at or past its length. Asserting an
	# exact frame count would be asserting a float division's rounding.
	assert_almost_eq(
		float(frames) * FRAME,
		stats.telegraph_seconds,
		FRAME * 1.5,
		"the hit lands when the number says it does"
	)
	assert_almost_eq(brain.time_until_hit(), 0.0, 0.0001, "and nothing is left to wait for")


func test_nothing_reaches_an_attack_without_telling_first() -> void:
	# `combat.md` §Encounter philosophy: "an enemy that hits without a tell is a bug,
	# not a difficulty knob". Structural: across every suit and every rank that
	# attacks at all, the state before ATTACK is always TELEGRAPH.
	if not assert_not_null(_catalog) or not assert_not_null(_rules):
		return
	for suit: Suit.Id in Suit.ALL:
		var brain := _brain_for(suit, Rank.Id.KNIGHT)
		if brain == null:
			continue
		var previous: Array[int] = [int(BlankBrain.State.IDLE)]
		var offenders: Array[int] = []
		brain.state_changed.connect(func(from: BlankBrain.State, to: BlankBrain.State) -> void:
			if to == BlankBrain.State.ATTACK and from != BlankBrain.State.TELEGRAPH:
				offenders.append(int(from))
			previous.append(int(to))
		)
		_drive_until(brain, Vector2(_attack_distance(brain.stats()), 0.0), BlankBrain.State.ATTACK)
		assert_eq(
			offenders, [] as Array[int], "%s reaches its hit only through a tell" % Suit.name_key(suit)
		)


func test_no_telegraph_can_be_shorter_than_the_floor() -> void:
	# The runtime half of the same rule: whatever difficulty, aura and duel-string
	# multipliers stack up, `EnemyRules.MIN_TELEGRAPH_SECONDS` is the floor. Driven
	# with a deliberately absurd multiplier so the clamp is what is being tested, not
	# the authored numbers.
	for suit: Suit.Id in Suit.ALL:
		for rank: Rank.Id in Rank.ALL:
			var brain := _brain_for(suit, rank)
			if brain == null:
				continue
			assert_true(
				brain.telegraph_seconds() >= EnemyRules.MIN_TELEGRAPH_SECONDS,
				"%s of %s tells for at least the floor" % [Rank.name_key(rank), Suit.name_key(suit)]
			)
			brain.set_difficulty_multiplier(0.01)
			brain.set_aura_buff(1.0, 0.01)
			assert_true(
				brain.telegraph_seconds() >= EnemyRules.MIN_TELEGRAPH_SECONDS,
				"and still does with every multiplier pushed to nothing"
			)


func test_trial_tightens_the_telegraph_and_story_lengthens_it() -> void:
	# `combat.md` §Difficulty modes: Trial has "tightened timing windows and
	# telegraphs", Story has "generous timing windows". The multiplier is
	# `CombatRules`' - the same one the Fool's perfect window is scaled by - so a mode
	# moves the whole of combat rather than half of it.
	var combat_rules := load(COMBAT_RULES_PATH) as CombatRules
	var brain := _brain_for(Suit.Id.COINS, Rank.Id.TWO)
	if brain == null or not assert_not_null(combat_rules):
		return
	brain.set_difficulty_multiplier(combat_rules.timing_window_multiplier(DifficultyMode.Id.JOURNEY))
	var journey := brain.telegraph_seconds()
	brain.set_difficulty_multiplier(combat_rules.timing_window_multiplier(DifficultyMode.Id.TRIAL))
	var trial := brain.telegraph_seconds()
	brain.set_difficulty_multiplier(combat_rules.timing_window_multiplier(DifficultyMode.Id.STORY))
	var story := brain.telegraph_seconds()
	assert_true(trial < journey, "Trial tightens the tell: %.3f vs %.3f" % [trial, journey])
	assert_true(story > journey, "Story lengthens it: %.3f vs %.3f" % [story, journey])
	assert_true(trial >= EnemyRules.MIN_TELEGRAPH_SECONDS, "and Trial still clears the floor")


func test_a_stagger_interrupts_a_telegraph_and_a_swing() -> void:
	# `combat.md` §The Bindle: the charged heavy lifts the target "into a brief
	# helpless stagger that opens bonus follow-ups". Helpless has to mean the swing is
	# dropped, or the launcher would trade rather than open.
	for state: BlankBrain.State in [BlankBrain.State.TELEGRAPH, BlankBrain.State.ATTACK]:
		var brain := _brain_for(Suit.Id.WANDS, Rank.Id.TWO)
		if brain == null:
			return
		var target := Vector2(brain.stats().attack_radius * 0.5, 0.0)
		_drive_until(brain, target, state)
		_perception.staggered = true
		brain.update(_perception, FRAME)
		assert_eq(
			brain.state(),
			BlankBrain.State.STAGGERED,
			"a stagger drops what the Blank was doing"
		)
		assert_null(brain.active_hit(), "and closes any window it had open")
		_perception.staggered = false
		brain.update(_perception, FRAME)
		assert_eq(brain.state(), BlankBrain.State.APPROACH, "and it starts over when it comes to")


func test_the_hit_spec_is_one_instance_for_the_whole_fight() -> void:
	# `docs/design/technical.md` §Performance guardrails: no per-frame allocation in an
	# AI loop. The spec is built once in `_init` and handed back unchanged - which is
	# also why `HitSpec` is treated as immutable.
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	var target := Vector2(brain.stats().attack_radius * 0.5, 0.0)
	_drive_until(brain, target, BlankBrain.State.ATTACK)
	var first := brain.active_hit()
	if not assert_not_null(first, "the window is open"):
		return
	var identity := first.get_instance_id()
	for index in 3:
		brain.update(_perception, FRAME)
		if brain.active_hit() == null:
			continue
		assert_eq(brain.active_hit().get_instance_id(), identity, "the same spec every frame")
	_drive_until(brain, target, BlankBrain.State.ATTACK)
	assert_eq(
		brain.active_hit().get_instance_id(), identity, "and the same one on the next swing"
	)


func test_the_hit_carries_the_suits_own_shape() -> void:
	var swords := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	var cups := _brain_for(Suit.Id.CUPS, Rank.Id.TWO)
	if swords == null or cups == null:
		return
	_drive_until(swords, Vector2(swords.stats().attack_radius * 0.5, 0.0), BlankBrain.State.ATTACK)
	var melee := swords.active_hit()
	if not assert_not_null(melee):
		return
	assert_eq(melee.kind, HitSpec.Kind.ENEMY_ATTACK, "an enemy swing is an enemy attack")
	assert_almost_eq(melee.arc_degrees, swords.stats().attack_arc_degrees, 0.001, "with its arc")
	assert_almost_eq(melee.radius, swords.stats().attack_radius, 0.001, "and its reach")
	assert_false(melee.applies_stagger, "and no Blank staggers the Fool: the launcher is the Fool's")
	_drive_until(cups, Vector2(_attack_distance(cups.stats()), 0.0), BlankBrain.State.ATTACK)
	var lob := cups.active_hit()
	if not assert_not_null(lob):
		return
	assert_almost_eq(lob.radius, cups.stats().projectile_radius, 0.001, "a lob hits with its own body")
	assert_almost_eq(lob.arc_degrees, 360.0, 0.001, "from whichever side it arrives")


# --- Suits ------------------------------------------------------------------------


func test_cups_keeps_its_range_and_lobs_from_it() -> void:
	# `combat.md`: "Fluid skirmishers and ranged lobbers - arcing, evasive, harass at
	# range and reposition." A Cups Blank the Fool has closed on walks AWAY.
	var brain := _brain_for(Suit.Id.CUPS, Rank.Id.TWO)
	if brain == null:
		return
	var stats := brain.stats()
	var too_close := Vector2(stats.preferred_range * 0.4, 0.0)
	_drive_until(brain, too_close, BlankBrain.State.APPROACH)
	brain.update(_perception, FRAME)
	assert_true(
		brain.movement_intent().x < 0.0,
		"a Cups Blank backs off a Fool who has closed inside its range"
	)
	assert_ne(brain.state(), BlankBrain.State.TELEGRAPH, "and does not swing at that distance")
	# Now from the range it wants: it stands and throws.
	var brain_at_range := _brain_for(Suit.Id.CUPS, Rank.Id.TWO)
	var good := Vector2(_attack_distance(stats), 0.0)
	_drive_until(brain_at_range, good, BlankBrain.State.TELEGRAPH)
	assert_eq(
		brain_at_range.state(), BlankBrain.State.TELEGRAPH, "and lobs from the range it likes"
	)


func test_swords_throws_a_string_and_the_others_throw_one_hit() -> void:
	# `combat.md`: Swords are "fast, precise duelists - tight strings, quick
	# punishes". One commitment, three hits, each follow-up telling faster than the
	# opener but never under the floor.
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	var target := Vector2(brain.stats().attack_radius * 0.5, 0.0)
	var hits: Array[int] = [0]
	brain.attack_started.connect(func(_spec: HitSpec) -> void:
		hits[0] += 1
	)
	# [opener, first follow-up].
	var told: Array[float] = [0.0, 0.0]
	brain.telegraph_started.connect(func(seconds: float) -> void:
		if told[0] <= 0.0:
			told[0] = seconds
		elif told[1] <= 0.0:
			told[1] = seconds
	)
	_drive_until(brain, target, BlankBrain.State.RECOVER)
	assert_eq(hits[0], brain.stats().string_length, "the whole string is one commitment")
	assert_true(told[1] < told[0], "and its follow-ups tell faster: %.3f after %.3f" % [
		told[1], told[0]
	])
	assert_true(told[1] >= EnemyRules.MIN_TELEGRAPH_SECONDS, "but never under the floor")
	var coins := _brain_for(Suit.Id.COINS, Rank.Id.TWO)
	if coins == null:
		return
	var coin_hits: Array[int] = [0]
	coins.attack_started.connect(func(_spec: HitSpec) -> void:
		coin_hits[0] += 1
	)
	_drive_until(coins, Vector2(coins.stats().attack_radius * 0.5, 0.0), BlankBrain.State.RECOVER)
	assert_eq(coin_hits[0], 1, "and a Coins Blank throws exactly one")


func test_coins_advances_behind_its_shield_and_drops_it_to_swing() -> void:
	# `combat.md`: "heavy shielded bruisers... built to be broken through rather than
	# out-traded". The shield is up while it closes and while it winds up, and down
	# while the swing and its recovery are happening - which is the window.
	var brain := _brain_for(Suit.Id.COINS, Rank.Id.TWO)
	if brain == null:
		return
	var target := Vector2(brain.stats().attack_radius * 0.5, 0.0)
	_drive_until(brain, target, BlankBrain.State.APPROACH)
	assert_true(brain.is_shield_raised(), "the shield is up on the way in")
	_drive_until(brain, target, BlankBrain.State.TELEGRAPH)
	assert_true(brain.is_shield_raised(), "and through the windup")
	_drive_until(brain, target, BlankBrain.State.ATTACK)
	assert_false(brain.is_shield_raised(), "and down while it swings")
	_drive_until(brain, target, BlankBrain.State.RECOVER)
	assert_false(brain.is_shield_raised(), "and through the recovery that pays for it")
	var swords := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if swords == null:
		return
	_drive_until(swords, Vector2(swords.stats().attack_radius * 0.5, 0.0), BlankBrain.State.APPROACH)
	assert_false(swords.is_shield_raised(), "nobody else has one to raise")


# --- Ranks --------------------------------------------------------------------------


func test_a_page_flees_toward_help_and_never_attacks() -> void:
	# `combat.md`: "Scout and alarm-raiser; flees to alert others rather than engaging
	# directly."
	var brain := _brain_for(Suit.Id.CUPS, Rank.Id.PAGE)
	if brain == null:
		return
	var attacked: Array[bool] = [false]
	brain.attack_started.connect(func(_spec: HitSpec) -> void:
		attacked[0] = true
	)
	# The Fool to the right, an ally up and to the left: the Page should end up going
	# somewhere between "away" and "toward help", never at the Fool.
	_perception.clear()
	_perception.self_position = Vector2.ZERO
	_perception.see_target(Vector2(120.0, 0.0))
	_perception.nearest_ally_position = Vector2(-300.0, -300.0)
	_perception.has_nearest_ally = true
	var frames := _drive(brain, BlankBrain.State.FLEE_TO_ALERT)
	assert_true(frames > 0, "the Page goes to flee rather than to approach")
	brain.update(_perception, FRAME)
	var run := brain.movement_intent()
	assert_true(run.x < 0.0, "it runs away from the Fool")
	assert_true(run.y < 0.0, "and toward the ally it is going to fetch")
	assert_false(attacked[0], "and never swings at anybody")
	# And a stagger does not turn it into a fighter. The Fool's charged heavy can catch
	# a Page mid-flight, and what it comes to as is the whole question: `combat.md`
	# gives the rank "flees to alert others rather than engaging directly", with no
	# exception for a Page that has just been knocked down. Driven with the Fool stood
	# exactly where this Page COULD hit them, so a brain that recovered into APPROACH
	# would tell and swing rather than merely walk.
	var caught := _brain_for(Suit.Id.CUPS, Rank.Id.PAGE)
	if caught == null:
		return
	var swung: Array[bool] = [false]
	caught.attack_started.connect(func(_spec: HitSpec) -> void:
		swung[0] = true
	)
	var visited: Array[int] = []
	caught.state_changed.connect(func(_from: BlankBrain.State, to: BlankBrain.State) -> void:
		visited.append(int(to))
	)
	_perception.clear()
	_perception.self_position = Vector2.ZERO
	_perception.see_target(Vector2(_attack_distance(caught.stats()), 0.0))
	_perception.nearest_ally_position = Vector2(-300.0, -300.0)
	_perception.has_nearest_ally = true
	_drive(caught, BlankBrain.State.FLEE_TO_ALERT)
	_perception.staggered = true
	caught.update(_perception, FRAME)
	assert_eq(
		caught.state(), BlankBrain.State.STAGGERED, "a charged heavy catches the Page mid-flight"
	)
	_perception.staggered = false
	# Fifteen seconds of it: long enough for any rota this brain could fall into to
	# have telegraphed several times over.
	for index in 900:
		_perception.self_position = caught.position()
		_perception.see_target(_perception.target_position, _perception.target_visible)
		caught.update(_perception, FRAME)
	assert_false(
		visited.has(int(BlankBrain.State.TELEGRAPH)),
		"a Page that comes to never winds up (states seen: %s)" % str(visited)
	)
	assert_false(visited.has(int(BlankBrain.State.ATTACK)), "and never opens a hit window")
	assert_false(swung[0], "so no hit ever leaves a Page, staggered or not")
	assert_eq(
		caught.state(), BlankBrain.State.FLEE_TO_ALERT, "it is back to running for help"
	)


func test_a_pages_alarm_wakes_the_idle_blanks_in_earshot_and_no_others() -> void:
	var page := _brain_for(Suit.Id.CUPS, Rank.Id.PAGE)
	if page == null:
		return
	var radius := page.stats().alert_radius
	var near := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	var far := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	near.place(Vector2(radius * 0.5, 0.0))
	far.place(Vector2(radius * 2.0, 0.0))
	var alarms: Array[Vector2] = []
	page.alert_raised.connect(func(from_position: Vector2) -> void:
		alarms.append(from_position)
	)
	_perception.clear()
	_perception.self_position = Vector2.ZERO
	_perception.see_target(Vector2(120.0, 0.0))
	_perception.nearest_ally_position = Vector2(-300.0, 0.0)
	_perception.has_nearest_ally = true
	# Long enough for the noticing beat and the run before the alarm.
	for index in int(ceil((page.stats().aware_seconds + page.stats().alert_seconds) / FRAME)) + 4:
		_perception.self_position = page.position()
		page.update(_perception, FRAME)
	assert_eq(alarms.size(), 1, "the alarm goes up once, not once a frame")
	assert_true(near.hear_alert(alarms[0], radius), "the Blank in earshot wakes")
	assert_ne(near.state(), BlankBrain.State.IDLE, "and is in the fight")
	assert_false(far.hear_alert(alarms[0], radius), "the one out of earshot does not")
	assert_eq(far.state(), BlankBrain.State.IDLE, "and is still in the grass")


func test_a_queen_buffs_the_allies_in_her_radius_and_no_others() -> void:
	# `combat.md`: "Commander; grants support auras to nearby Blanks (buffs, not
	# summons)." The parenthesis is why nothing here spawns anything.
	var queen := _brain_for(Suit.Id.WANDS, Rank.Id.QUEEN)
	if queen == null:
		return
	var radius := queen.stats().aura_radius
	var near := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	var far := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	var plain_damage := near.damage()
	var plain_telegraph := near.telegraph_seconds()
	# The Queen has to be in the fight before she commands anything.
	_perception.clear()
	_perception.self_position = Vector2.ZERO
	_perception.see_target(Vector2(200.0, 0.0))
	_perception.allies_nearby = 1
	_drive(queen, BlankBrain.State.COMMAND_AURA)
	assert_eq(queen.state(), BlankBrain.State.COMMAND_AURA, "she takes up her commanding stance")
	assert_true(queen.apply_aura_to(near, Vector2(radius * 0.5, 0.0)), "the ally in radius is buffed")
	assert_false(queen.apply_aura_to(far, Vector2(radius * 2.0, 0.0)), "the one outside it is not")
	assert_true(near.damage() > plain_damage, "a buffed Blank hits harder")
	assert_true(near.telegraph_seconds() < plain_telegraph, "and comes off the mark quicker")
	assert_eq(far.damage(), plain_damage, "an unbuffed one is exactly as it was")
	assert_eq(far.telegraph_seconds(), plain_telegraph)
	# And the buff dies with the commander: nothing keeps a dead Queen's aura.
	near.clear_aura_buff()
	queen.defeat()
	assert_false(queen.apply_aura_to(near, Vector2(radius * 0.5, 0.0)), "a defeated Queen commands nobody")
	assert_eq(near.damage(), plain_damage, "and her allies go back to their own numbers")


func test_a_buffed_blank_swings_a_buffed_spec_built_once() -> void:
	# The aura changes what a hit COSTS, and a spec is shared and immutable - so the
	# buffed one is a second instance, built at most once per distinct buff, never per
	# frame.
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	var target := Vector2(brain.stats().attack_radius * 0.5, 0.0)
	_drive_until(brain, target, BlankBrain.State.ATTACK)
	var plain := brain.active_hit()
	brain.set_aura_buff(1.5, 1.0)
	_drive_until(brain, target, BlankBrain.State.ATTACK)
	var buffed := brain.active_hit()
	if not assert_not_null(plain) or not assert_not_null(buffed):
		return
	assert_ne(buffed.get_instance_id(), plain.get_instance_id(), "the buffed hit is its own spec")
	assert_true(buffed.damage > plain.damage, "and costs more")
	var identity := buffed.get_instance_id()
	_drive_until(brain, target, BlankBrain.State.ATTACK)
	assert_eq(
		brain.active_hit().get_instance_id(), identity, "and is built once, not once a swing"
	)


# --- Engaging and losing interest ---------------------------------------------------


func test_a_blank_notices_inside_its_aggro_radius_and_not_outside_it() -> void:
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	var radius := brain.stats().aggro_radius
	_perception.clear()
	_perception.self_position = Vector2.ZERO
	_perception.see_target(Vector2(radius * 1.5, 0.0))
	for index in 10:
		brain.update(_perception, FRAME)
	assert_eq(brain.state(), BlankBrain.State.IDLE, "a distant Fool is not noticed")
	_perception.see_target(Vector2(radius * 0.5, 0.0))
	brain.update(_perception, FRAME)
	assert_eq(brain.state(), BlankBrain.State.AWARE, "a close one is")


func test_a_blank_gives_up_past_its_disengage_radius() -> void:
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	_drive_until(brain, Vector2(brain.stats().aggro_radius * 0.5, 0.0), BlankBrain.State.APPROACH)
	# A GDScript lambda captures a local by VALUE, so a counter it writes to has to be
	# something the capture shares: a one-element array is the reference the closure
	# and this function both hold. (Every accumulator below is one for the same reason.)
	var left: Array[bool] = [false]
	brain.disengaged.connect(func() -> void:
		left[0] = true
	)
	_perception.see_target(Vector2(brain.stats().disengage_radius * 2.0, 0.0))
	brain.update(_perception, FRAME)
	assert_eq(brain.state(), BlankBrain.State.IDLE, "it goes back to the grass")
	assert_true(left[0], "and says so once")


# --- Defeat ---------------------------------------------------------------------------


func test_defeat_is_a_card_fluttering_free_and_not_a_death() -> void:
	# `combat.md`: "A defeated Blank slumps and fades while the card it bore flutters
	# free - drifting off to raise a new bearer elsewhere later". The timer is the
	# presentation; the body is out of the fight the moment its pool empties.
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	var flutters: Array[int] = [0]
	brain.card_fluttered.connect(func() -> void:
		flutters[0] += 1
	)
	_drive_until(brain, Vector2(brain.stats().attack_radius * 0.5, 0.0), BlankBrain.State.ATTACK)
	brain.defeat()
	assert_eq(brain.state(), BlankBrain.State.DEFEATED, "the body goes down at once")
	assert_null(brain.active_hit(), "with no window left open")
	assert_eq(flutters[0], 0, "and the card is still on it")
	var frames := int(ceil(brain.stats().card_flutter_seconds / FRAME)) + 2
	for index in frames:
		brain.update(_perception, FRAME)
	assert_eq(flutters[0], 1, "the card comes free once, when its time is up")
	assert_true(brain.has_fluttered(), "and the body may go back to the pool")
	for index in 30:
		brain.update(_perception, FRAME)
	assert_eq(flutters[0], 1, "and never again")
	assert_true(brain.movement_intent().is_zero_approx(), "a slumped Blank does not walk")


func test_reset_makes_the_body_somebody_elses() -> void:
	# What pooling means from the card's point of view: a Blank raised by a new card
	# is a new Blank, with no timer, no buff, no string and no alarm left over.
	var brain := _brain_for(Suit.Id.SWORDS, Rank.Id.TWO)
	if brain == null:
		return
	_drive_until(brain, Vector2(brain.stats().attack_radius * 0.5, 0.0), BlankBrain.State.ATTACK)
	brain.set_aura_buff(2.0, 0.5)
	brain.defeat()
	brain.reset()
	assert_eq(brain.state(), BlankBrain.State.IDLE, "back in the grass")
	assert_false(brain.has_fluttered(), "with its card still to lose")
	assert_almost_eq(brain.aura_damage_multiplier(), 1.0, 0.0001, "and nobody's buff on it")
	assert_almost_eq(brain.aura_telegraph_multiplier(), 1.0, 0.0001)


# --- Helpers ----------------------------------------------------------------------------


## A distance the Fool can stand at and be attacked from: inside this suit's reach,
## outside a ranged suit's stand-off range, and always inside the aggro radius (a
## Cups Blank's lob out-ranges its own eyes, so the midpoint of its band is a place it
## would never notice the Fool from).
func _attack_distance(stats: EnemyStats) -> float:
	if stats.is_ranged:
		return minf((stats.preferred_range + stats.attack_radius) * 0.5, stats.aggro_radius * 0.9)
	return stats.attack_radius * 0.5


## A brain for one suit and rank, built the way the game builds one.
func _brain_for(suit: Suit.Id, rank: Rank.Id) -> BlankBrain:
	if _catalog == null or _rules == null:
		fail("the enemy data did not load")
		return null
	var definition := _catalog.find_blank(suit, rank)
	if definition == null:
		fail("no %s of %s in the catalog" % [Rank.name_key(rank), Suit.name_key(suit)])
		return null
	var stats := definition.stats(_rules)
	if stats == null:
		fail("%s has no stat block" % definition.id)
		return null
	return BlankBrain.new(stats)


## Drive a brain with the target standing still at `target`, until it reaches `state`.
## Returns how many frames that took, counted from the frame the previous state was
## entered on. Fails rather than hangs if the state never arrives.
func _drive_until(brain: BlankBrain, target: Vector2, state: BlankBrain.State) -> int:
	_perception.clear()
	_perception.self_position = brain.position()
	_perception.see_target(target)
	return _drive(brain, state)


## Drive with whatever is already in the perception, refreshing only the position the
## brain reports so a walking Blank really closes the distance.
func _drive(brain: BlankBrain, state: BlankBrain.State) -> int:
	var frames := 0
	while brain.state() != state:
		frames += 1
		if frames > FRAME_LIMIT:
			fail("the brain never reached state %d (stuck in %d)" % [int(state), int(brain.state())])
			return frames
		_perception.self_position = brain.position()
		if _perception.has_target:
			_perception.see_target(_perception.target_position, _perception.target_visible)
		brain.update(_perception, FRAME)
	return frames
