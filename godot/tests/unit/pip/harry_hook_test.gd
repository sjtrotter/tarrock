extends TarrockTest

## The Harry hook: round 9's one addition to round 8's enemy brain.
##
## `docs/design/combat.md` §Pip: Harry "pins or distracts one target enemy, holding its
## attention and briefly reducing its aggression toward the Fool". The two halves are
## split across the enemy system's own seam - `Blank.set_distraction()` swaps who the
## perception is filled from (the attention), `BlankBrain.set_distraction()` lengthens
## the telegraphs (the aggression) - and this covers the brain half. The body half is
## `tests/pip_test.gd`, in a real scene with a real Blank.
##
## It lives under `tests/unit/pip/` rather than beside the round-8 brain tests because
## the behaviour is Pip's: the day Harry changes, this is the file that has to change
## with it, and it should be in the folder somebody reads when it does.

const CATALOG_PATH := "res://data/enemies/catalog.tres"
const ENEMY_RULES_PATH := "res://data/enemies/enemy_rules.tres"
const PIP_RULES_PATH := "res://data/pip/pip_rules.tres"

## One physics frame at 60 Hz.
const FRAME := 1.0 / 60.0

var _catalog: EnemyCatalog = null
var _enemy_rules: EnemyRules = null
var _pip_rules: PipRules = null
var _perception: BlankPerception = BlankPerception.new()


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_enemy_rules = load(ENEMY_RULES_PATH) as EnemyRules
	_pip_rules = load(PIP_RULES_PATH) as PipRules
	if _catalog == null:
		return
	for entry: EnemyDefinition in _catalog.entries:
		if entry != null:
			entry.clear_stats_cache()


func test_a_brain_starts_undistracted() -> void:
	var brain := _brain()
	if brain == null:
		return
	assert_false(brain.is_distracted(), "nothing has Pip's enemy by the ankle yet")
	assert_almost_eq(brain.distraction_seconds_left(), 0.0, 0.0001)


func test_a_harried_enemy_telegraphs_for_longer() -> void:
	var brain := _brain()
	if brain == null:
		return
	var plain := brain.telegraph_seconds()
	brain.set_distraction(_pip_rules.harry_seconds, _pip_rules.harry_telegraph_multiplier)
	assert_true(brain.is_distracted(), "Pip has it")
	assert_almost_eq(
		brain.telegraph_seconds(),
		plain * _pip_rules.harry_telegraph_multiplier,
		0.0001,
		"which is what combat.md's 'reducing its aggression toward the Fool' buys"
	)
	assert_true(
		brain.telegraph_seconds() > plain, "a harried enemy is SLOWER to commit, never faster"
	)


func test_a_harry_can_never_sharpen_an_enemy_whatever_it_is_handed() -> void:
	# `PipRules.validate()` refuses a table below 1.0, but a table is not the only way
	# in: this method is public and a caller can pass anything. `combat.md` §Pip only
	# ever REDUCES the harried enemy's aggression toward the Fool, so the floor is here
	# too, and a multiplier that would quicken the tell is spent as no change at all.
	var brain := _brain()
	if brain == null:
		return
	var plain := brain.telegraph_seconds()
	brain.set_distraction(_pip_rules.harry_seconds, 0.5)
	assert_true(brain.is_distracted(), "the pin still holds - the attention half is unaffected")
	assert_almost_eq(
		brain.telegraph_seconds(),
		plain,
		0.0001,
		"but the tell is its own length: a harry never makes an enemy quicker"
	)
	brain.set_distraction(_pip_rules.harry_seconds, -4.0)
	assert_true(
		brain.telegraph_seconds() >= plain, "and a negative multiplier cannot invert one either"
	)


func test_the_distraction_lapses_on_its_own() -> void:
	var brain := _brain()
	if brain == null:
		return
	brain.set_distraction(0.5, _pip_rules.harry_telegraph_multiplier)
	var frames := int(floorf(0.5 / FRAME)) - 2
	for _frame: int in frames:
		brain.update(_perception, FRAME)
	assert_true(brain.is_distracted(), "it holds for the duration it was given")
	for _frame: int in 4:
		brain.update(_perception, FRAME)
	assert_false(
		brain.is_distracted(),
		"then lapses - a dog who was removed mid-pin cannot leave an enemy staring forever"
	)
	assert_almost_eq(brain.aura_telegraph_multiplier(), 1.0, 0.0001, "and the tell is its own again")


func test_clearing_a_distraction_puts_the_attention_straight_back() -> void:
	var brain := _brain()
	if brain == null:
		return
	var plain := brain.telegraph_seconds()
	brain.set_distraction(_pip_rules.harry_seconds, _pip_rules.harry_telegraph_multiplier)
	brain.clear_distraction()
	assert_false(brain.is_distracted())
	assert_almost_eq(brain.telegraph_seconds(), plain, 0.0001)


func test_a_distraction_of_no_duration_is_no_distraction() -> void:
	var brain := _brain()
	if brain == null:
		return
	brain.set_distraction(0.0, _pip_rules.harry_telegraph_multiplier)
	assert_false(brain.is_distracted(), "a pin with no time in it never happened")


func test_a_body_going_back_to_the_pool_forgets_it_was_harried() -> void:
	var brain := _brain()
	if brain == null:
		return
	brain.set_distraction(_pip_rules.harry_seconds, _pip_rules.harry_telegraph_multiplier)
	brain.reset()
	assert_false(brain.is_distracted(), "a Blank raised by a new card is a new Blank")


func test_the_telegraph_floor_still_holds_under_a_harry() -> void:
	# `combat.md` §Encounter philosophy: "an enemy that hits without a tell is a bug,
	# not a difficulty knob". Harry lengthens tells, so it can never reach the floor -
	# but the floor is asserted here anyway, because the next hook might not.
	var brain := _brain()
	if brain == null:
		return
	brain.set_distraction(_pip_rules.harry_seconds, _pip_rules.harry_telegraph_multiplier)
	assert_true(brain.telegraph_seconds() >= EnemyRules.MIN_TELEGRAPH_SECONDS)


func _brain() -> BlankBrain:
	if _catalog == null or _enemy_rules == null or _pip_rules == null:
		fail("the enemy or Pip data did not load")
		return null
	var definition := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.TWO)
	if definition == null:
		fail("no Two of Swords in the catalog")
		return null
	var stats := definition.stats(_enemy_rules)
	if stats == null:
		fail("the Two of Swords has no stat block")
		return null
	return BlankBrain.new(stats)
