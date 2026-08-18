extends TarrockTest

## The Coins shield: `docs/design/combat.md` §Enemies' "heavy shielded bruisers -
## slow, armored, built to be broken through rather than out-traded", as a
## `CombatDefense`.
##
## Two halves, and the second is the interesting one. **Shielded** is easy: a hit that
## arrives while the shield is up and the threat is in front of it is `BLOCKED`, and
## the Fool takes nothing off and earns no Fortune for it. **Broken through** is the
## design: the shield is a wedge held in a direction, so the answer is to get behind
## it, and this suite proves the wedge really has a back.
##
## The hits are thrown through the real `Combatant.take_hit()` path rather than by
## asking the defence directly, so what is being proven is what a swing would
## actually meet.

const RULES_PATH := "res://data/enemies/enemy_rules.tres"
const CATALOG_PATH := "res://data/enemies/catalog.tres"

var _rules: EnemyRules = null
var _catalog: EnemyCatalog = null
var _stats: EnemyStats = null

## Every bare `Combatant` this suite built, so none of them leaks: a `Node2D` that was
## never added to the tree is freed by hand or reported at shutdown.
var _built: Array[Combatant] = []


func before_each() -> void:
	_rules = load(RULES_PATH) as EnemyRules
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_stats = null
	if _catalog == null or _rules == null:
		return
	var definition := _catalog.find_blank(Suit.Id.COINS, Rank.Id.TWO)
	if definition == null:
		return
	definition.clear_stats_cache()
	_stats = definition.stats(_rules)


func after_each() -> void:
	for combatant: Combatant in _built:
		if combatant != null and is_instance_valid(combatant):
			combatant.free()
	_built.clear()


func test_a_shield_held_toward_the_fool_absorbs_the_hit() -> void:
	var combatant := _shielded_combatant()
	if combatant == null:
		return
	var shield := combatant.defense as CoinsShield
	shield.set_raised(true)
	shield.aim(Vector2.RIGHT, Vector2.RIGHT * 100.0)
	var before := combatant.health()
	assert_eq(
		combatant.take_hit(_fool_hit(10)),
		HitResult.Id.BLOCKED,
		"a hit from the front meets the shield"
	)
	assert_eq(combatant.health(), before, "and costs the Coins Blank nothing")


func test_a_hit_from_behind_gets_past_it() -> void:
	# "built to be broken through rather than out-traded" - walking round the back is
	# the answer the doc describes, so the wedge has to have a back to walk round.
	var combatant := _shielded_combatant()
	if combatant == null:
		return
	var shield := combatant.defense as CoinsShield
	shield.set_raised(true)
	shield.aim(Vector2.RIGHT, Vector2.LEFT * 100.0)
	var before := combatant.health()
	assert_ne(
		combatant.take_hit(_fool_hit(10)),
		HitResult.Id.BLOCKED,
		"a hit from behind is not blocked"
	)
	assert_true(combatant.health() < before, "and costs the Coins Blank health")


func test_the_wedge_is_exactly_the_arc_the_rules_authored() -> void:
	# Not "roughly frontal": the half-angle is the rules' number, so a retune moves
	# where a player has to stand and this test moves with it.
	if _stats == null:
		fail("no Coins stat block")
		return
	var shield := CoinsShield.new(_stats)
	shield.set_raised(true)
	var half := deg_to_rad(_stats.block_arc_degrees) * 0.5
	# Just inside the edge, both ways round.
	for sign_of: float in [1.0, -1.0]:
		shield.aim(Vector2.RIGHT, Vector2.RIGHT.rotated(sign_of * (half - 0.02)) * 100.0)
		assert_true(shield.covers_threat(), "just inside the edge is covered")
		shield.aim(Vector2.RIGHT, Vector2.RIGHT.rotated(sign_of * (half + 0.02)) * 100.0)
		assert_false(shield.covers_threat(), "just outside it is not")


func test_a_dropped_shield_blocks_nothing() -> void:
	# The window: `BlankBrain` puts the shield down while the Coins Blank is swinging,
	# staggered or defeated, and this is what that costs it.
	var combatant := _shielded_combatant()
	if combatant == null:
		return
	var shield := combatant.defense as CoinsShield
	shield.aim(Vector2.RIGHT, Vector2.RIGHT * 100.0)
	shield.set_raised(false)
	var before := combatant.health()
	assert_ne(combatant.take_hit(_fool_hit(10)), HitResult.Id.BLOCKED, "a shield down blocks nothing")
	assert_true(combatant.health() < before, "and the swing lands")


func test_the_armour_applies_whether_or_not_the_shield_is_up() -> void:
	# The plate is worn, not held: "slow, **armored**" is the half a player cannot
	# side-step, and it is what keeps a Coins Blank a bruiser once the shield is down.
	if _stats == null:
		fail("no Coins stat block")
		return
	var combatant := _shielded_combatant()
	if combatant == null:
		return
	var shield := combatant.defense as CoinsShield
	shield.set_raised(false)
	shield.aim(Vector2.RIGHT, Vector2.RIGHT * 100.0)
	var damage := 20
	var before := combatant.health()
	combatant.take_hit(_fool_hit(damage))
	var taken := before - combatant.health()
	assert_eq(
		taken,
		int(roundf(float(damage) * _stats.armour_multiplier)),
		"armour cuts what gets through by the rules' multiplier"
	)
	assert_true(taken < damage, "so a Coins Blank is worn down rather than traded with")


func test_an_unshielded_suit_has_no_shield_at_all() -> void:
	if _catalog == null or _rules == null:
		fail("the enemy data did not load")
		return
	var swords := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.TWO)
	if not assert_not_null(swords):
		return
	swords.clear_stats_cache()
	var shield := CoinsShield.new(swords.stats(_rules))
	shield.set_raised(true)
	shield.aim(Vector2.RIGHT, Vector2.RIGHT * 100.0)
	assert_false(shield.covers_threat(), "a shield built from a suit that has none covers nothing")
	assert_false(shield.is_blocking(), "and blocks nothing")
	assert_almost_eq(shield.damage_multiplier(), 1.0, 0.0001, "and armours nothing")


func test_a_block_chance_below_certain_is_seeded_and_repeatable() -> void:
	# The authored chance is 1.0, which draws no random number at all - the shield is
	# deterministic and a telegraph-and-answer fight stays honest. A retune below 1.0
	# must still be a fight that runs the same way twice, which is what the seed is
	# for; nothing in Tarrock may depend on an unseeded roll.
	if _stats == null:
		fail("no Coins stat block")
		return
	assert_almost_eq(
		_stats.block_chance, CoinsShield.CERTAIN, 0.0001, "the authored shield is certain"
	)
	# Built by hand rather than copied: `EnemyStats` is a `RefCounted`, so there is no
	# `duplicate()`, and only the shield's own three fields matter here.
	var chancy := EnemyStats.new()
	chancy.has_shield = true
	chancy.block_arc_degrees = _stats.block_arc_degrees
	chancy.armour_multiplier = _stats.armour_multiplier
	chancy.block_chance = 0.5
	var first := _roll_blocks(chancy, 12345, 40)
	var again := _roll_blocks(chancy, 12345, 40)
	assert_eq(first, again, "the same seed gives the same fight")
	assert_true(first > 0 and first < 40, "and half a chance is neither never nor always")


# --- Helpers ---------------------------------------------------------------------


## A Coins Blank's health pool with its shield on it, built the way `Blank` builds one.
func _shielded_combatant() -> Combatant:
	if _stats == null:
		fail("no Coins stat block")
		return null
	var combatant := Combatant.new()
	combatant.faction = Faction.Id.BLANK
	combatant.set_max_health(_stats.max_health)
	combatant.defense = CoinsShield.new(_stats)
	_built.append(combatant)
	return combatant


## A swing from the Fool, through the real hit path.
func _fool_hit(damage: int) -> HitEvent:
	return HitEvent.new(
		Faction.Id.FOOL,
		HitSpec.new(HitSpec.Kind.LIGHT, damage, HitSpec.Shape.ARC, 90.0, 100.0),
		Vector2.ZERO,
		Vector2.RIGHT,
		0.0
	)


## How many of `attempts` frontal hits a shield with this stat block stops.
func _roll_blocks(stats: EnemyStats, seed_value: int, attempts: int) -> int:
	var shield := CoinsShield.new(stats)
	shield.seed_rng(seed_value)
	shield.set_raised(true)
	shield.aim(Vector2.RIGHT, Vector2.RIGHT * 100.0)
	var blocked := 0
	for index in attempts:
		if shield.is_blocking():
			blocked += 1
	return blocked
