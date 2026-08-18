extends TarrockTest

## The Blank pool: `docs/design/technical.md` §Performance guardrails' "**Pooling**
## for Blanks and for repeated VFX - never instance/free on the hot path".
##
## This is one of the few unit tests that needs the tree, and it says so: an
## `EnemyPool` owns scene instances, so there has to be a scene to own them in.
## Everything it adds to the root is freed in `after_each()`.
##
## The rule under test is not "acquiring is fast" - it is that a fight takes no new
## bodies at all. `grew_by()` is how that is proven: an encounter whose pool was
## preallocated correctly finishes with zero, and one that ran out says so in a number
## rather than in a frame spike nobody profiled.

const CATALOG_PATH := "res://data/enemies/catalog.tres"
const RULES_PATH := "res://data/enemies/enemy_rules.tres"

## How many bodies the pool under test preallocates.
const POOL_SIZE := 4

var _catalog: EnemyCatalog = null
var _rules: EnemyRules = null
var _pool: EnemyPool = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_rules = load(RULES_PATH) as EnemyRules
	_pool = EnemyPool.new()
	_pool.name = "TestEnemyPool"
	tree().root.add_child(_pool)
	_pool.configure(POOL_SIZE)


func after_each() -> void:
	if _pool != null and is_instance_valid(_pool):
		tree().root.remove_child(_pool)
		_pool.queue_free()
	_pool = null


func test_the_pool_preallocates_and_starts_asleep() -> void:
	assert_eq(_pool.instance_count(), POOL_SIZE, "the bodies exist before the fight does")
	assert_eq(_pool.available_count(), POOL_SIZE, "and every one of them is asleep")
	assert_eq(_pool.live_count(), 0, "with nothing standing in the world")
	assert_eq(_pool.grew_by(), 0, "and nothing has been made in anger yet")
	for blank: Blank in _pool.instances():
		assert_false(blank.is_awake(), "a pooled body is asleep")
		assert_false(blank.visible, "invisible")
		assert_eq(blank.collision_layer, 0, "and colliding with nothing")


func test_a_whole_fight_instances_nothing() -> void:
	# The guardrail itself, stated as a number: three Blanks are raised, fought and
	# released, and the pool ends the fight owning exactly the bodies it started with.
	var definition := _definition(EnemyIds.BLANK_SWORDS_TWO)
	if definition == null:
		return
	var before := _pool.instance_count()
	var raised: Array[Blank] = []
	for index in 3:
		var blank := _pool.acquire(definition, _rules)
		if not assert_not_null(blank, "the pool has a body to give"):
			return
		raised.append(blank)
	assert_eq(_pool.live_count(), 3, "three are out in the world")
	assert_eq(_pool.available_count(), POOL_SIZE - 3, "and the rest are still asleep")
	for blank: Blank in raised:
		_pool.release(blank)
	assert_eq(_pool.instance_count(), before, "the fight instanced nothing")
	assert_eq(_pool.grew_by(), 0, "and needed nothing new")
	assert_eq(_pool.available_count(), POOL_SIZE, "and every body is back")


func test_a_released_body_is_handed_out_again() -> void:
	# What pooling means from the card's point of view (`combat.md` §Enemies: the card
	# "flutters free - drifting off to raise a new bearer elsewhere later"). The bearer
	# is the same body, wearing a different card.
	var swords := _definition(EnemyIds.BLANK_SWORDS_TWO)
	var coins := _definition(EnemyIds.BLANK_COINS_TEN)
	if swords == null or coins == null:
		return
	var first := _pool.acquire(swords, _rules)
	if not assert_not_null(first):
		return
	assert_eq(first.definition().id, EnemyIds.BLANK_SWORDS_TWO, "it rose as a Two of Swords")
	_pool.release(first)
	var second := _pool.acquire(coins, _rules)
	assert_eq(second, first, "the same body is raised again")
	assert_eq(second.definition().id, EnemyIds.BLANK_COINS_TEN, "by a different card")
	assert_true(
		second.combatant().health_capacity() > 1,
		"and it is that card's Blank now, numbers and all"
	)
	assert_not_null(second.shield(), "a Coins Blank raised over a Swords one has a shield")


func test_releasing_twice_is_not_two_bodies() -> void:
	# It happens: a defeat and an encounter shutting down both tidy up. A pool that
	# counted the same body twice would hand it out to two fights at once.
	var definition := _definition(EnemyIds.BLANK_WANDS_TWO)
	if definition == null:
		return
	var blank := _pool.acquire(definition, _rules)
	_pool.release(blank)
	_pool.release(blank)
	assert_eq(_pool.available_count(), POOL_SIZE, "one body went back, not two")


func test_running_out_grows_the_pool_and_counts_it() -> void:
	# A fight that lost an enemy because a pool was authored one too small would be
	# worse than a frame spent instancing - so the pool grows, and says how often, so
	# an encounter's `pool_size` can be corrected rather than guessed at.
	var definition := _definition(EnemyIds.BLANK_CUPS_TWO)
	if definition == null:
		return
	for index in POOL_SIZE + 2:
		assert_not_null(_pool.acquire(definition, _rules), "every request is answered")
	assert_eq(_pool.grew_by(), 2, "and the two it did not have are counted")
	assert_eq(_pool.instance_count(), POOL_SIZE + 2)


func test_release_all_puts_the_whole_fight_away() -> void:
	var definition := _definition(EnemyIds.BLANK_SWORDS_TWO)
	if definition == null:
		return
	for index in 3:
		_pool.acquire(definition, _rules)
	_pool.release_all()
	assert_eq(_pool.live_count(), 0, "a scene unload leaves nothing standing")
	assert_eq(_pool.instance_count(), POOL_SIZE, "and frees nothing")


func test_a_pooled_body_carries_its_definitions_numbers() -> void:
	# The seam this test exists for: identity comes from the catalog, numbers come from
	# the rules, and `configure()` is where they meet on a real body.
	var ten := _definition(EnemyIds.BLANK_COINS_TEN)
	var two := _definition(EnemyIds.BLANK_COINS_TWO)
	if ten == null or two == null:
		return
	var big := _pool.acquire(ten, _rules)
	var small := _pool.acquire(two, _rules)
	if not assert_not_null(big) or not assert_not_null(small):
		return
	assert_true(
		big.combatant().health_capacity() > small.combatant().health_capacity(),
		"a Ten really is a real fight next to a Two"
	)
	assert_eq(
		big.combatant().faction, Faction.Id.BLANK, "and both fight for the side the doc gives them"
	)


# --- Helpers ---------------------------------------------------------------------


func _definition(enemy_id: StringName) -> EnemyDefinition:
	if _catalog == null or _rules == null:
		fail("the enemy data did not load")
		return null
	var found := _catalog.find(enemy_id)
	if found == null:
		fail("no %s in the catalog" % enemy_id)
		return null
	found.clear_stats_cache()
	return found
