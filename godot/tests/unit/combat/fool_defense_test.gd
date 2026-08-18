extends TarrockTest

## The Fool's answer to an incoming hit, with the real moveset behind it.
##
## `combat_defense.gd` is asked three questions on the hit path - i-frames, the
## hop-guard, and whether the dodge was perfect - and the interesting part is not any
## one answer but what an answer COSTS. `docs/design/combat.md` §Defense:
##
##   * the block-step "absorbs a hit and repositions", one hit, so the guard is spent
##     by the first swing it eats and the second one lands;
##   * Fool's Chance is "a dodge timed to the final instant before a hit lands", and
##     the instant is measured from the moment i-frames open - the frames before that
##     are frames where the hit simply lands.
##
## Nothing here waits: the moveset is driven by hand-fed deltas, exactly as
## `moveset_controller_test` drives it, and the hits are thrown through the real
## `Combatant` path so the defence is asked rather than bypassed.
##
## **`Engine.time_scale` is a global and a perfect dodge moves it.** `after_each` puts
## it back whatever the test did.

const RULES_PATH := "res://data/combat/combat_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## A frame short enough to land inside any phase in the table.
const TINY := 0.01

var _rules: CombatRules = null
var _controller: MovesetController = null
var _service: CombatService = null
var _fortune: FortuneService = null
var _defense: FoolDefense = null
var _fool: Combatant = null


func before_each() -> void:
	_rules = (load(RULES_PATH) as CombatRules).duplicate() as CombatRules
	var spread_rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	var world_state := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_fortune = FortuneService.new(spread_rules)
	var spread := PocketSpreadService.new(
		world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, spread_rules, _fortune
	)
	_service = CombatService.new(
		_rules, _fortune, spread, WhiteRoseService.new(world_state, spread_rules), GameClock.new()
	)
	_controller = MovesetController.new(_rules)
	_defense = FoolDefense.new(_controller, _service)
	_fool = Combatant.new()
	_fool.faction = Faction.Id.FOOL
	_fool.defense = _defense
	_service.register_fool(_fool)


func after_each() -> void:
	Engine.time_scale = 1.0
	if _fool != null and is_instance_valid(_fool):
		_fool.free()
	_fool = null


# --- The hop-guard ------------------------------------------------------------


func test_the_guard_absorbs_one_hit_and_the_next_one_lands() -> void:
	# combat.md §Defense: the block-step "absorbs a hit and repositions", singular. A
	# guard that ate every swing arriving inside its window would be a free panic
	# button against a pair of enemies, and it would be the block-step - which has no
	# counter-window and is priced as a commitment - doing the job of a dodge.
	_press_block()
	assert_true(_defense.is_blocking(), "the guard is up on the frame the hop starts")
	assert_eq(_hit(20), HitResult.Id.BLOCKED, "the first swing is absorbed")
	assert_eq(_fool.health(), _fool.health_capacity(), "for nothing")
	assert_false(_defense.is_blocking(), "and the guard is spent")
	assert_eq(_hit(20), HitResult.Id.DAMAGED, "so the second swing lands")
	assert_eq(_fool.health(), _fool.health_capacity() - 20)


func test_the_second_hit_lands_even_deep_inside_the_guard_window() -> void:
	# Not a timing accident: both hits arrive well inside block_step_guard_seconds.
	_press_block()
	assert_eq(_hit(10), HitResult.Id.BLOCKED)
	_advance(_rules.block_step_guard_seconds * 0.25)
	assert_true(
		_controller.state() == MovesetController.State.BLOCK_STEP, "still mid-hop"
	)
	assert_eq(_hit(10), HitResult.Id.DAMAGED, "the window is open; the guard is not")


func test_a_fresh_block_step_guards_again() -> void:
	_press_block()
	assert_eq(_hit(10), HitResult.Id.BLOCKED)
	_advance(_rules.block_step_seconds)
	assert_eq(_controller.state(), MovesetController.State.IDLE, "the hop is over")
	_press_block()
	assert_eq(_hit(10), HitResult.Id.BLOCKED, "a new hop is a new absorb")


# --- The perfect window --------------------------------------------------------


func test_the_whole_window_is_perfect_from_the_moment_iframes_open() -> void:
	# The band a player actually has: it opens with the i-frames and lasts the
	# authored window. Measured from the dodge's first frame instead, the usable part
	# would be short by dodge_iframe_start_seconds on every difficulty.
	_service.set_difficulty(DifficultyMode.Id.JOURNEY)
	_press_dodge()
	_advance(_rules.dodge_iframe_start_seconds)
	assert_eq(_hit(20), HitResult.Id.DODGED_PERFECT, "the first frame of i-frames is perfect")
	_service.end_fools_chance()
	_controller.reset()
	_press_dodge()
	_advance(_rules.dodge_iframe_start_seconds + _service.perfect_window_seconds() - 0.001)
	assert_eq(_hit(20), HitResult.Id.DODGED_PERFECT, "and so is the last instant of the window")
	_service.end_fools_chance()


func test_a_dodge_older_than_the_window_is_a_plain_dodge() -> void:
	_service.set_difficulty(DifficultyMode.Id.JOURNEY)
	_press_dodge()
	_advance(_rules.dodge_iframe_start_seconds + _service.perfect_window_seconds() + 0.01)
	assert_true(_controller.is_invulnerable(), "i-frames are still up, so the hit is evaded")
	assert_eq(_hit(20), HitResult.Id.DODGED, "but the read was early: no Fool's Chance")
	assert_false(_service.is_fools_chance_active())


func test_trial_still_leaves_a_band_a_player_can_hit() -> void:
	# Trial "tightens timing windows"; CombatRules.validate() holds the tightened
	# window to three physics frames, and this is that floor reaching the hit path.
	_service.set_difficulty(DifficultyMode.Id.TRIAL)
	assert_true(
		_service.perfect_window_seconds() >= CombatRules.MIN_PERFECT_WINDOW_SECONDS,
		"Trial's band is %.3f s" % _service.perfect_window_seconds()
	)
	_press_dodge()
	_advance(_rules.dodge_iframe_start_seconds + CombatRules.MIN_PERFECT_WINDOW_SECONDS - 0.001)
	assert_eq(
		_hit(20),
		HitResult.Id.DODGED_PERFECT,
		"three physics frames after i-frames open, on Trial, is still perfect"
	)
	_service.end_fools_chance()


func test_a_perfect_dodge_still_pays_and_a_plain_one_still_does_not() -> void:
	var before := _fortune.value()
	_press_dodge()
	_advance(_rules.dodge_iframe_start_seconds + _service.perfect_window_seconds() + 0.01)
	assert_eq(_hit(20), HitResult.Id.DODGED)
	assert_eq(_fortune.value(), before, "a plain dodge earns nothing inside a fight")
	_controller.reset()
	_press_dodge()
	_advance(_rules.dodge_iframe_start_seconds)
	assert_eq(_hit(20), HitResult.Id.DODGED_PERFECT)
	assert_true(_fortune.value() > before, "the read is what pays")
	assert_true(_fortune.has_free_cast(), "combat.md: and arms the next Present cast")


# --- Helpers -------------------------------------------------------------------


## One frame of nothing, `seconds` long.
func _advance(seconds: float) -> void:
	_controller.update(null, seconds)


## Press the block-step on a frame of no consequence.
func _press_block() -> void:
	var input := CombatInput.new()
	input.block_pressed = true
	_controller.update(input, TINY)


## Press the dodge on a frame of no consequence.
func _press_dodge() -> void:
	var input := CombatInput.new()
	input.dodge_pressed = true
	_controller.update(input, TINY)


## Throw an enemy hit at the Fool through the real `Combatant` path.
func _hit(damage: int) -> HitResult.Id:
	return _fool.take_hit(
		HitEvent.new(
			Faction.Id.BLANK,
			HitSpec.new(HitSpec.Kind.ENEMY_ATTACK, damage, HitSpec.Shape.ARC, 180.0, 200.0),
			Vector2.ZERO,
			Vector2.RIGHT,
			0.0
		)
	)
