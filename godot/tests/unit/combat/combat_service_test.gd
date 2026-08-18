extends TarrockTest

## What a fight is: Fool's Chance, the difficulty modes, the accessibility slider,
## the White Rose's heals and the defeat loop.
##
## `docs/design/combat.md` §Defense, §Difficulty modes, §Accessibility and §Defeat are
## the canon; `docs/design/progression.md` §Fortune and §The White Rose own the
## numbers this service spends.
##
## **`Engine.time_scale` is a global, and this suite moves it.** `after_each` puts it
## back to 1.0 whatever the test did, because a suite that left the engine at 0.3
## would quietly slow every later test's idea of a second - and would not say why.
##
## Nothing here waits: Fool's Chance is advanced by feeding `tick()` deltas, exactly
## as the composition root does with the engine's own.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"

var _rules: CombatRules = null
var _spread_rules: SpreadRules = null
var _world_state: WorldStateService = null
var _fortune: FortuneService = null
var _spread: PocketSpreadService = null
var _rose: WhiteRoseService = null
var _clock: GameClock = null
var _service: CombatService = null
var _fool: Combatant = null


func before_each() -> void:
	_rules = (load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules
	_spread_rules = (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_world_state = WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_fortune = FortuneService.new(_spread_rules)
	_spread = PocketSpreadService.new(
		_world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, _spread_rules, _fortune
	)
	_rose = WhiteRoseService.new(_world_state, _spread_rules)
	_clock = GameClock.new()
	_service = CombatService.new(_rules, _fortune, _spread, _rose, _clock)
	_fool = Combatant.new()
	_fool.faction = Faction.Id.FOOL
	_service.register_fool(_fool)


func after_each() -> void:
	# The slow-motion tests move a global. Anything left at 0.3 would halve every
	# later test's idea of a second.
	Engine.time_scale = 1.0
	if _fool != null and is_instance_valid(_fool):
		_fool.free()
	_fool = null


# --- Difficulty and the accessibility slider ---------------------------------


func test_the_perfect_window_is_the_rules_scaled_by_the_mode() -> void:
	_service.set_difficulty(DifficultyMode.Id.JOURNEY)
	assert_almost_eq(_service.perfect_window_seconds(), _rules.perfect_window_seconds)
	_service.set_difficulty(DifficultyMode.Id.STORY)
	assert_almost_eq(
		_service.perfect_window_seconds(),
		_rules.perfect_window_seconds * _rules.timing_window_multiplier_story,
		0.0001,
		"combat.md: Story gets generous timing windows"
	)
	_service.set_difficulty(DifficultyMode.Id.TRIAL)
	assert_almost_eq(
		_service.perfect_window_seconds(),
		_rules.perfect_window_seconds * _rules.timing_window_multiplier_trial,
		0.0001,
		"and Trial tightens them"
	)


func test_the_slider_is_independent_of_difficulty() -> void:
	# combat.md §Accessibility: the Fool's Chance timing-window slider is "independent
	# of difficulty mode". The same setting must buy the same milliseconds on every
	# mode, which is only true if it is added after the multiplier, not inside it.
	var bonus := 0.05
	_service.set_perfect_window_bonus_seconds(bonus)
	_service.set_difficulty(DifficultyMode.Id.STORY)
	var story := _service.perfect_window_seconds()
	_service.set_difficulty(DifficultyMode.Id.TRIAL)
	var trial := _service.perfect_window_seconds()
	_service.set_perfect_window_bonus_seconds(0.0)
	var trial_bare := _service.perfect_window_seconds()
	_service.set_difficulty(DifficultyMode.Id.STORY)
	var story_bare := _service.perfect_window_seconds()
	assert_almost_eq(story - story_bare, bonus, 0.0001, "the slider buys 50 ms on Story")
	assert_almost_eq(trial - trial_bare, bonus, 0.0001, "and exactly 50 ms on Trial too")


func test_the_slider_never_narrows_the_window() -> void:
	_service.set_perfect_window_bonus_seconds(-1.0)
	assert_almost_eq(_service.perfect_window_bonus_seconds(), 0.0, 0.0001, "tightening is Trial's job")


func test_the_damage_multiplier_follows_the_mode() -> void:
	_service.set_difficulty(DifficultyMode.Id.STORY)
	assert_almost_eq(_service.damage_taken_multiplier(), _rules.damage_taken_multiplier_story)
	_service.set_difficulty(DifficultyMode.Id.TRIAL)
	assert_almost_eq(
		_service.damage_taken_multiplier(), 1.0, 0.0001, "combat.md: Trial has no damage reduction"
	)


func test_one_call_moves_the_whole_difficulty() -> void:
	_service.set_difficulty(DifficultyMode.Id.TRIAL)
	assert_eq(_fortune.difficulty(), DifficultyMode.Id.TRIAL, "Fortune income moved with it")


# --- Fool's Chance ------------------------------------------------------------


func test_a_perfect_dodge_slows_the_world_and_arms_the_free_cast() -> void:
	watch_signal(_service, &"fools_chance_started")
	watch_signal(_fortune, &"free_cast_armed")
	_service.on_incoming_hit_dodged(true)
	assert_almost_eq(Engine.time_scale, _rules.slowmo_time_scale, 0.0001, "the world slows")
	assert_true(_service.is_fools_chance_active())
	assert_true(_fortune.has_free_cast(), "combat.md: the next Present cast is free")
	assert_true(_fortune.value() > 0, "and a Fool's Chance pays disproportionately")
	assert_signal_emitted(_service, &"fools_chance_started", 1)
	assert_signal_emitted(_fortune, &"free_cast_armed", 1)


func test_the_window_lasts_its_authored_real_seconds() -> void:
	watch_signal(_service, &"fools_chance_ended")
	_service.trigger_fools_chance()
	# Deltas arrive already scaled by the engine, so a real second is
	# `slowmo_time_scale` of one. Feeding scaled deltas is exactly what the
	# composition root does.
	var scaled_step := 0.1 * _rules.slowmo_time_scale
	for _index: int in 14:
		_service.tick(scaled_step)
	assert_true(_service.is_fools_chance_active(), "1.4 real seconds of a 1.5 second window")
	_service.tick(scaled_step)
	_service.tick(scaled_step)
	assert_false(_service.is_fools_chance_active())
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001, "and time goes back to normal")
	assert_signal_emitted(_service, &"fools_chance_ended", 1)


func test_a_second_perfect_dodge_resets_the_window_rather_than_stacking() -> void:
	watch_signal(_service, &"fools_chance_started")
	_service.trigger_fools_chance()
	_service.tick(1.0 * _rules.slowmo_time_scale)
	_service.trigger_fools_chance()
	assert_almost_eq(
		_service.fools_chance_seconds_left(),
		_rules.slowmo_duration_real_seconds,
		0.0001,
		"a second perfect dodge is a second full window"
	)
	assert_signal_emitted(_service, &"fools_chance_started", 1, "but it is still one window")


func test_an_ordinary_dodge_slows_nothing_and_earns_nothing() -> void:
	# combat.md: Fool's Chance is the reward for the dodge timed to the final instant,
	# and §Fortune in combat rewards staying in the fight rather than turtling. A plain
	# dodge is one button on every telegraph: paying it fortune_per_daring would make
	# rolling early and often out-earn landing hits, which is the exact behaviour the
	# perfect-dodge window exists NOT to reward. DARING is still spent - out of combat,
	# on the beats progression.md names.
	var before := _fortune.value()
	_service.on_incoming_hit_dodged(false)
	assert_false(_service.is_fools_chance_active())
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001)
	assert_false(_fortune.has_free_cast(), "dodging early and often is not the route to power")
	assert_eq(_fortune.value(), before, "and neither is it a Fortune income")


func test_a_plain_dodge_never_out_earns_a_landed_hit() -> void:
	# The finding this test pins: at the authored numbers a DARING payout is worth
	# several landed hits, so an in-combat dodge that paid it would invert the whole
	# in-fight economy.
	var start := _fortune.value()
	for _index: int in 5:
		_service.on_incoming_hit_dodged(false)
	assert_eq(_fortune.value(), start, "five dodges are worth nothing")
	_service.on_fool_hit_landed(null, _fool)
	assert_true(_fortune.value() > start, "one landed hit is worth more than all of them")


func test_ending_the_window_early_puts_time_back() -> void:
	_service.trigger_fools_chance()
	_service.end_fools_chance()
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001)
	assert_false(_service.is_fools_chance_active())


# --- Fortune from the fight ---------------------------------------------------


func test_a_landed_hit_trickles_fortune() -> void:
	var before := _fortune.value()
	var gained := _service.on_fool_hit_landed(null, null)
	assert_eq(gained, _spread_rules.fortune_per_hit, "the amount is SpreadRules', not combat's")
	assert_eq(_fortune.value(), before + gained)


func test_the_fight_locks_and_unlocks_the_pocket_spread() -> void:
	watch_signal(_service, &"in_combat_changed")
	var first := _enemy()
	var second := _enemy()
	_service.enemy_engaged(first)
	assert_true(_spread.in_combat(), "progression.md: the Spread is rebuilt out of combat only")
	_service.enemy_engaged(second)
	_service.enemy_disengaged(first)
	assert_true(_spread.in_combat(), "one enemy left means the fight is not over")
	_service.enemy_disengaged(second)
	assert_false(_spread.in_combat())
	assert_signal_emitted(_service, &"in_combat_changed", 2, "on and off, once each")
	first.free()
	second.free()


func test_an_enemy_that_falls_leaves_the_fight_by_itself() -> void:
	var enemy := _enemy()
	enemy.set_max_health(5)
	_service.enemy_engaged(enemy)
	assert_true(_service.is_in_combat())
	enemy.take_hit(
		HitEvent.new(
			Faction.Id.FOOL,
			HitSpec.new(HitSpec.Kind.LIGHT, 10, HitSpec.Shape.ARC, 90.0, 100.0),
			Vector2.ZERO,
			Vector2.RIGHT,
			0.0
		)
	)
	assert_false(_service.is_in_combat(), "nobody has to remember to say so")
	enemy.free()


func test_clearing_the_engagements_ends_any_slow_motion() -> void:
	# A scene that tears its fight down mid-Fool's-Chance (an encounter scripted shut,
	# a region unloading) must not leave the engine at 0.3x with nothing on screen to
	# explain it. This service is the only writer of Engine.time_scale, so it is the
	# only thing that can put it back.
	watch_signal(_service, &"fools_chance_ended")
	var enemy := _enemy()
	_service.enemy_engaged(enemy)
	_service.trigger_fools_chance()
	assert_true(_service.is_fools_chance_active())
	_service.clear_engagements()
	assert_false(_service.is_in_combat(), "everybody went home")
	assert_false(_service.is_fools_chance_active(), "and the window went with them")
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001, "time is back")
	assert_signal_emitted(_service, &"fools_chance_ended", 1)
	enemy.free()


# --- The White Rose ------------------------------------------------------------


func test_a_petal_is_one_fast_heal() -> void:
	watch_signal(_service, &"rose_used")
	_hurt_fool(50)
	var petals := _rose.petals()
	assert_true(_service.use_rose())
	assert_eq(_rose.petals(), petals - 1, "one petal, one heal")
	assert_eq(_fool.health(), _rules.fool_max_health - 50 + _rules.petal_heal)
	assert_eq(signal_arguments(_service, &"rose_used", 0), [_rules.petal_heal, _rose.petals()])


func test_a_petal_is_refused_at_full_health() -> void:
	watch_signal(_service, &"rose_refused")
	var petals := _rose.petals()
	assert_false(_service.use_rose())
	assert_eq(_rose.petals(), petals, "a scarce resource is not thrown away by a mistimed button")
	assert_eq(signal_arguments(_service, &"rose_refused", 0), [CombatService.REASON_AT_FULL_HEALTH])


func test_a_rose_with_no_petals_refuses() -> void:
	watch_signal(_service, &"rose_refused")
	while _rose.petals() > 0:
		_rose.use_petal()
	_hurt_fool(50)
	assert_false(_service.use_rose())
	assert_eq(signal_arguments(_service, &"rose_refused", 0), [CombatService.REASON_NO_PETALS])


func test_healing_never_overfills_the_pool() -> void:
	_hurt_fool(10)
	_service.use_rose()
	assert_eq(_fool.health(), _rules.fool_max_health, "capped, not overfilled")


# --- The defeat loop -----------------------------------------------------------


func test_the_fool_at_zero_falls_and_the_scene_is_told() -> void:
	watch_signal(_service, &"fool_defeated")
	_clock.advance(42.0)
	_hurt_fool(_rules.fool_max_health)
	assert_true(_service.is_defeated())
	assert_signal_emitted(_service, &"fool_defeated", 1)
	assert_eq(
		signal_arguments(_service, &"fool_defeated", 0),
		[1, 42],
		"the count and the hour, for a Querent line that remarks only occasionally"
	)


func test_a_defeat_ends_any_slow_motion() -> void:
	_service.trigger_fools_chance()
	_hurt_fool(_rules.fool_max_health)
	assert_almost_eq(Engine.time_scale, 1.0, 0.0001, "the world does not stay slow over a body")


func test_the_return_leg_restores_health_and_the_rose() -> void:
	watch_signal(_service, &"fool_revived")
	_rose.use_petal()
	_hurt_fool(_rules.fool_max_health)
	_service.revive_at_waystation()
	assert_eq(_fool.health(), _rules.fool_max_health, "combat.md: no penalty beyond the walk back")
	assert_eq(_rose.petals(), _rose.max_petals(), "and the White Rose regrown")
	assert_false(_service.is_defeated())
	assert_signal_emitted(_service, &"fool_revived", 1)


func test_a_petal_cannot_be_spent_on_a_fallen_fool() -> void:
	watch_signal(_service, &"rose_refused")
	_hurt_fool(_rules.fool_max_health)
	assert_false(_service.use_rose())
	assert_eq(signal_arguments(_service, &"rose_refused", 0), [CombatService.REASON_DEFEATED])


func test_defeats_are_counted() -> void:
	_hurt_fool(_rules.fool_max_health)
	_service.revive_at_waystation()
	_hurt_fool(_rules.fool_max_health)
	assert_eq(_service.defeat_count(), 2)


# --- Helpers -------------------------------------------------------------------


## Take `amount` off the Fool through the real hit path, so the difficulty multiplier
## and the defeat signal are exercised rather than bypassed.
func _hurt_fool(amount: int) -> void:
	_fool.take_hit(
		HitEvent.new(
			Faction.Id.BLANK,
			HitSpec.new(HitSpec.Kind.ENEMY_ATTACK, amount, HitSpec.Shape.ARC, 180.0, 100.0),
			Vector2.ZERO,
			Vector2.RIGHT,
			0.0
		)
	)


## A bare enemy Combatant. Freed by the test that made it.
func _enemy() -> Combatant:
	var enemy := Combatant.new()
	enemy.faction = Faction.Id.BLANK
	enemy.set_max_health(40)
	return enemy
