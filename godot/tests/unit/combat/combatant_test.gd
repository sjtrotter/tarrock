extends TarrockTest

## A body that can be hit: the hit rule, the stagger the launcher opens, and the
## sides.
##
## `docs/design/combat.md` §Defense is the order under test - evasion beats
## everything, the guard beats damage, and only what is left costs health - and
## §The Bindle is the stagger: "the target is lifted off its feet into a brief
## helpless stagger that opens bonus follow-ups".
##
## Nothing here needs a scene: a `Combatant` is a `Node2D`, but a bare one answers
## every question this suite asks, which is what keeps the hit rule testable without
## a physics frame anywhere near it.

const RULES_PATH := "res://data/combat/combat_rules.tres"

var _rules: CombatRules = null
var _combatant: Combatant = null


func before_each() -> void:
	_rules = load(RULES_PATH) as CombatRules
	_combatant = Combatant.new()
	_combatant.faction = Faction.Id.BLANK
	_combatant.set_max_health(100)


func after_each() -> void:
	if _combatant != null and is_instance_valid(_combatant):
		_combatant.free()
	_combatant = null


# --- Damage ------------------------------------------------------------------


func test_a_hit_costs_health() -> void:
	watch_signal(_combatant, &"damaged")
	var result := _combatant.take_hit(_event(10))
	assert_eq(result, HitResult.Id.DAMAGED)
	assert_eq(_combatant.health(), 90)
	assert_eq(signal_arguments(_combatant, &"damaged", 0), [10, 90])


func test_a_hit_that_takes_nothing_off_does_not_kill_a_full_pool() -> void:
	# The zero-damage path: a spec of 0 damage, or a multiplier that rounds one away.
	# It must read the pool the same way every other path does - a Combatant built in
	# code and never `_ready` has an unfilled field until something asks, and asking is
	# what fills it.
	watch_signal(_combatant, &"died")
	var fresh := Combatant.new()
	fresh.faction = Faction.Id.BLANK
	fresh.max_health = 40
	var harmless := _event(0)
	assert_eq(fresh.take_hit(harmless), HitResult.Id.DAMAGED, "it landed, it just cost nothing")
	assert_eq(fresh.health(), 40, "and a body that was never readied is not dead of it")
	assert_true(fresh.is_alive())
	fresh.free()
	assert_eq(_combatant.take_hit(_event(0)), HitResult.Id.DAMAGED)
	assert_signal_emitted(_combatant, &"died", 0, "nobody died of a hit that took nothing")


func test_emptying_the_pool_is_reported_once() -> void:
	watch_signal(_combatant, &"died")
	_combatant.set_max_health(10)
	assert_eq(_combatant.take_hit(_event(15)), HitResult.Id.KILLED)
	assert_eq(_combatant.health(), 0, "health never goes negative")
	assert_signal_emitted(_combatant, &"died", 1)


func test_nothing_is_hit_by_its_own_side() -> void:
	var friendly := _event(50)
	friendly.attacker_faction = Faction.Id.BLANK
	assert_eq(
		_combatant.take_hit(friendly),
		HitResult.Id.IGNORED,
		"a swing from a friend is IGNORED, not BLOCKED: nobody spent a guard on it"
	)
	assert_eq(_combatant.health(), 100, "Blanks do not fight Blanks")
	assert_false(HitResult.was_landed(HitResult.Id.IGNORED), "so it earns nothing")
	assert_false(HitResult.was_evaded(HitResult.Id.IGNORED), "and nobody evaded anything")


func test_a_friendly_swing_never_reaches_the_defence() -> void:
	# The block-step's absorb is spent on a BLOCKED result. If a same-side hit still
	# reported itself as blocked, walking through a friend mid-guard would eat the
	# guard the Fool was holding for the enemy.
	var stub := _StubDefense.new(false, true, false, 1.0)
	stub.last_result = HitResult.Id.STAGGERED_HIT
	_combatant.defense = stub
	var friendly := _event(50)
	friendly.attacker_faction = Faction.Id.BLANK
	_combatant.take_hit(friendly)
	assert_eq(stub.last_result, HitResult.Id.STAGGERED_HIT, "the defence was never told")
	assert_eq(stub.resolved_count, 0)


func test_an_event_with_no_spec_behind_it_is_ignored() -> void:
	assert_eq(_combatant.take_hit(null), HitResult.Id.IGNORED)
	assert_eq(_combatant.health(), 100)


func test_the_fool_and_every_enemy_family_are_hostile_to_each_other() -> void:
	for enemy: Faction.Id in [Faction.Id.BLANK, Faction.Id.BEAST, Faction.Id.FOG_MASK]:
		assert_true(Faction.is_hostile(Faction.Id.FOOL, enemy))
		assert_true(Faction.is_hostile(enemy, Faction.Id.FOOL))
	assert_false(
		Faction.is_hostile(Faction.Id.BEAST, Faction.Id.BLANK),
		"the Stall froze the world; it did not start a civil war in it"
	)


# --- Defence -----------------------------------------------------------------


func test_i_frames_refuse_the_hit_entirely() -> void:
	_combatant.defense = _StubDefense.new(true, false, false, 1.0)
	assert_eq(_combatant.take_hit(_event(40)), HitResult.Id.DODGED)
	assert_eq(_combatant.health(), 100)


func test_a_dodge_inside_the_perfect_window_reads_as_the_fools_chance() -> void:
	_combatant.defense = _StubDefense.new(true, false, true, 1.0)
	assert_eq(_combatant.take_hit(_event(40)), HitResult.Id.DODGED_PERFECT)
	assert_eq(_combatant.health(), 100)


func test_the_guard_absorbs_the_hit() -> void:
	_combatant.defense = _StubDefense.new(false, true, false, 1.0)
	assert_eq(_combatant.take_hit(_event(40)), HitResult.Id.BLOCKED)
	assert_eq(_combatant.health(), 100, "combat.md: the block-step absorbs a hit")


func test_the_damage_multiplier_is_applied() -> void:
	_combatant.defense = _StubDefense.new(false, false, false, 0.5)
	_combatant.take_hit(_event(40))
	assert_eq(_combatant.health(), 80, "Story's reduced damage taken, as a multiplier")


func test_the_defence_is_told_what_became_of_the_hit() -> void:
	var stub := _StubDefense.new(true, false, true, 1.0)
	_combatant.defense = stub
	_combatant.take_hit(_event(40))
	assert_eq(stub.last_result, HitResult.Id.DODGED_PERFECT, "which is what triggers Fool's Chance")


# --- Stagger -----------------------------------------------------------------


func test_the_launcher_staggers_and_the_next_hit_pays_the_bonus() -> void:
	watch_signal(_combatant, &"staggered")
	var launcher := _event(10)
	launcher.spec = HitSpec.new(
		HitSpec.Kind.CHARGED_HEAVY, 10, HitSpec.Shape.ARC, 140.0, 120.0, true, 1.5, 2.0
	)
	assert_eq(_combatant.take_hit(launcher), HitResult.Id.DAMAGED, "the launcher itself is a hit")
	assert_true(_combatant.is_staggered())
	assert_eq(_combatant.health(), 90, "and it cannot pay the bonus for a stagger it just caused")
	assert_signal_emitted(_combatant, &"staggered", 1)
	var follow_up := _event(10)
	follow_up.spec.bonus_vs_staggered = 2.0
	assert_eq(_combatant.take_hit(follow_up), HitResult.Id.STAGGERED_HIT)
	assert_eq(_combatant.health(), 70, "the follow-up pays double into a helpless target")


func test_a_stagger_runs_out() -> void:
	watch_signal(_combatant, &"recovered")
	_combatant.apply_stagger(0.5)
	_combatant.advance(0.3)
	assert_true(_combatant.is_staggered())
	_combatant.advance(0.3)
	assert_false(_combatant.is_staggered())
	assert_signal_emitted(_combatant, &"recovered", 1)


func test_a_second_launcher_refreshes_the_stagger_rather_than_stacking_it() -> void:
	_combatant.apply_stagger(1.0)
	_combatant.advance(0.6)
	_combatant.apply_stagger(1.0)
	assert_almost_eq(_combatant.stagger_seconds_left(), 1.0, 0.001, "refreshed, not 1.4")


func test_a_body_at_zero_is_not_staggered() -> void:
	_combatant.set_max_health(5)
	var launcher := _event(50)
	launcher.spec = HitSpec.new(
		HitSpec.Kind.CHARGED_HEAVY, 50, HitSpec.Shape.ARC, 140.0, 120.0, true, 1.5, 1.5
	)
	assert_eq(_combatant.take_hit(launcher), HitResult.Id.KILLED)
	assert_false(_combatant.is_staggered())


# --- Healing -----------------------------------------------------------------


func test_healing_is_capped_at_the_pool() -> void:
	_combatant.take_hit(_event(10))
	assert_eq(_combatant.heal(50), 10, "only the missing ten could be given back")
	assert_eq(_combatant.health(), 100)
	assert_eq(_combatant.heal(50), 0, "and a full pool takes nothing")


func test_restoring_full_health_clears_the_stagger_too() -> void:
	_combatant.take_hit(_event(60))
	_combatant.apply_stagger(2.0)
	_combatant.restore_full_health()
	assert_eq(_combatant.health(), 100)
	assert_false(_combatant.is_staggered(), "the Fool wakes at the Waystation whole")


func test_the_rules_size_the_fools_pool() -> void:
	if not assert_not_null(_rules):
		return
	_combatant.set_max_health(_rules.fool_max_health)
	assert_eq(_combatant.health(), _rules.fool_max_health)
	assert_almost_eq(_combatant.health_fraction(), 1.0)


# --- Helpers -----------------------------------------------------------------


## A plain hostile hit for `damage`.
func _event(damage: int) -> HitEvent:
	return HitEvent.new(
		Faction.Id.FOOL,
		HitSpec.new(HitSpec.Kind.LIGHT, damage, HitSpec.Shape.ARC, 90.0, 100.0),
		Vector2.ZERO,
		Vector2.RIGHT,
		0.0
	)


## A defence with fixed answers, so the hit rule can be driven through every branch
## without a moveset.
class _StubDefense:
	extends CombatDefense

	var invulnerable: bool = false
	var blocking: bool = false
	var perfect: bool = false
	var multiplier: float = 1.0
	var last_result: HitResult.Id = HitResult.Id.DAMAGED

	## How many times the defence was told anything at all.
	var resolved_count: int = 0

	func _init(
		is_invulnerable_value: bool,
		is_blocking_value: bool,
		is_perfect_value: bool,
		damage_multiplier_value: float
	) -> void:
		invulnerable = is_invulnerable_value
		blocking = is_blocking_value
		perfect = is_perfect_value
		multiplier = damage_multiplier_value

	func is_invulnerable() -> bool:
		return invulnerable

	func is_blocking() -> bool:
		return blocking

	func is_perfect_dodge() -> bool:
		return perfect

	func damage_multiplier() -> float:
		return multiplier

	func on_hit_resolved(result: HitResult.Id, _event_value: HitEvent) -> void:
		last_result = result
		resolved_count += 1
