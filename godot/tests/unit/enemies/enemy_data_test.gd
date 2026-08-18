extends TarrockTest

## The generated enemy data, against the doc it was generated from.
##
## `godot/tools/gen_definitions.py` lifts `docs/design/combat.md` §Enemies: the Blanks
## and §Other enemy families into the `.tres` files under `res://data/enemies/`, the
## `EnemyIds` constants and the catalog. This suite is the drift guard
## `docs/design/technical.md` §Testing asks for: the data loads, the whole four-by-
## thirteen grid is there exactly once, each definition carries the doc's own cells,
## the two family stubs name the flags the doc gives them, and re-running the
## generator would change nothing.
##
## It also guards the one thing generated identity plus hand-authored numbers can get
## wrong between them: `EnemyDefinition.stats()`. A Ten must be tougher than a Two
## because `combat.md` says the printed number is "a simple visual tell of toughness",
## and that is a property of the two halves multiplied together, which neither half
## can check alone.

const CATALOG_PATH := "res://data/enemies/catalog.tres"
const RULES_PATH := "res://data/enemies/enemy_rules.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const GENERATOR_PATH := "res://tools/gen_definitions.py"

## Where `docs/` sits relative to the project - outside `res://` on purpose.
const COMBAT_DOC_RELATIVE := "../docs/design/combat.md"

## Four suits x thirteen ranks. Restated here so deleting a row from the doc's table
## fails a test rather than quietly shrinking the roster.
const DOCUMENTED_SUITS := 4
const DOCUMENTED_RANKS := 13
const DOCUMENTED_BLANKS := DOCUMENTED_SUITS * DOCUMENTED_RANKS

## `combat.md` §Other enemy families: "Two smaller enemy families exist outside the
## Blanks". Two, not three.
const DOCUMENTED_OTHER_FAMILIES := 2

var _catalog: EnemyCatalog = null
var _rules: EnemyRules = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as EnemyCatalog
	_rules = load(RULES_PATH) as EnemyRules
	if _catalog == null:
		return
	# Definitions cache their solved stat block against the rules instance they were
	# solved for; a suite that retunes a table in place would otherwise be served the
	# previous test's answer.
	for entry: EnemyDefinition in _catalog.entries:
		if entry != null:
			entry.clear_stats_cache()


# --- The generated catalog -----------------------------------------------------


func test_the_catalog_loads_and_validates() -> void:
	if not assert_not_null(_catalog, "%s loads" % CATALOG_PATH):
		return
	var world_states := load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	assert_eq(
		_catalog.validate(world_states),
		PackedStringArray(),
		"the generated enemies are self-consistent and resolve every flag they name"
	)


func test_the_whole_suit_by_rank_grid_is_there_exactly_once() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(
		_catalog.of_family(EnemyFamily.Id.BLANK).size(),
		DOCUMENTED_BLANKS,
		"one definition per suit x rank (technical.md: one asset per combination)"
	)
	var seen: Dictionary = {}
	for suit: Suit.Id in Suit.ALL:
		for rank: Rank.Id in Rank.ALL:
			var found := _catalog.find_blank(suit, rank)
			if not assert_not_null(
				found, "the %s of %s exists" % [Rank.name_key(rank), Suit.name_key(suit)]
			):
				continue
			assert_false(seen.has(found.id), "%s appears once" % found.id)
			seen[found.id] = true
	assert_eq(seen.size(), DOCUMENTED_BLANKS, "and nothing else claims a square")


func test_there_are_exactly_two_other_families() -> void:
	if not assert_not_null(_catalog):
		return
	var others := 0
	for family: EnemyFamily.Id in EnemyFamily.ALL:
		if family == EnemyFamily.Id.BLANK:
			continue
		var found := _catalog.of_family(family)
		assert_eq(found.size(), 1, "exactly one %s stub" % EnemyFamily.name_key(family))
		others += found.size()
	assert_eq(others, DOCUMENTED_OTHER_FAMILIES, "combat.md names two, not three")


func test_the_catalog_is_the_whole_roster() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(
		_catalog.entries.size(),
		DOCUMENTED_BLANKS + DOCUMENTED_OTHER_FAMILIES,
		"fifty-two Blanks and the two family stubs, and nothing invented"
	)


func test_every_blank_shares_the_one_art_family() -> void:
	# `combat.md`: "One base art and animation family carries every suit and rank,
	# keeping the whole game's enemy roster simple and legible by design".
	if not assert_not_null(_catalog):
		return
	for entry: EnemyDefinition in _catalog.of_family(EnemyFamily.Id.BLANK):
		assert_eq(
			entry.sprite_family,
			EnemyDefinition.BLANK_SPRITE_FAMILY,
			"%s is drawn from the shared family" % entry.id
		)


func test_no_blank_carries_a_number() -> void:
	# The whole reason `EnemyRules` exists: `combat.md` gives the Blanks two tables of
	# ROLE and not one figure, so a definition that carried a stat block would be
	# carrying a number somebody invented. The check is structural - the class has no
	# stat fields at all - so this asserts the shape that replaced them instead.
	if not assert_not_null(_catalog) or not assert_not_null(_rules):
		return
	var swords_two := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.TWO)
	if not assert_not_null(swords_two):
		return
	assert_null(swords_two.stats(null), "with no rules there are no numbers")
	assert_not_null(swords_two.stats(_rules), "and every number comes from the rules")


func test_the_summaries_are_the_docs_own_cells() -> void:
	# Verbatim, not paraphrased: they exist so a reviewer can read what a suit is FOR
	# without leaving the resource, and so this test can compare them to the doc. A
	# rewritten cell fails here.
	if not assert_not_null(_catalog):
		return
	var doc := _combat_text()
	if not assert_true(doc.length() > 0, "the combat doc is readable"):
		return
	for entry: EnemyDefinition in _catalog.of_family(EnemyFamily.Id.BLANK):
		assert_true(
			doc.contains(entry.suit_role_summary),
			"%s carries a suit cell combat.md does not have" % entry.id
		)
		assert_true(
			doc.contains(entry.rank_role_summary),
			"%s carries a rank cell combat.md does not have" % entry.id
		)


func test_the_family_stubs_carry_the_docs_own_flags() -> void:
	# The two world-state rules §Other enemy families states, and the two the game
	# reads. A stub pointed at the wrong flag would be a Beast nothing ever calms.
	if not assert_not_null(_catalog):
		return
	var beast := _catalog.find(EnemyIds.BEAST)
	var fog_mask := _catalog.find(EnemyIds.FOG_MASK)
	if not assert_not_null(beast) or not assert_not_null(fog_mask):
		return
	assert_eq(beast.calming_flag, WorldStateIds.WS_STRENGTH_UNBOUND, "Strength calms the Beasts")
	assert_eq(beast.reveal_flag, &"", "and nothing reveals them")
	assert_eq(fog_mask.reveal_flag, WorldStateIds.WS_MOON_UNBOUND, "the Moon unmasks the Fog-masks")
	assert_eq(fog_mask.calming_flag, &"", "and nothing calms them")
	assert_true(
		beast.family_summary.contains("neutral-until-provoked"),
		"the Beast stub carries its own bullet"
	)
	assert_true(
		fog_mask.family_summary.contains("ambush advantage"),
		"and the Fog-mask stub carries its own"
	)


func test_every_definition_cites_its_doc_section() -> void:
	if not assert_not_null(_catalog):
		return
	for entry: EnemyDefinition in _catalog.entries:
		assert_true(entry.doc_ref.begins_with("docs/design/combat.md"), "%s cites combat.md" % entry.id)


# --- The generated constants ----------------------------------------------------


func test_enemy_ids_match_the_catalog() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(EnemyIds.ALL.size(), _catalog.entries.size(), "one constant per enemy")
	for entry: EnemyDefinition in _catalog.entries:
		assert_has(EnemyIds.ALL, entry.id, "%s has a constant" % entry.id)
	assert_eq(EnemyIds.BLANKS.size(), DOCUMENTED_BLANKS, "and one per Blank in BLANKS")
	assert_eq(EnemyIds.BLANK_SWORDS_TWO, &"BLANK_SWORDS_TWO")


func test_the_mq00_ambush_is_three_ids_the_catalog_holds() -> void:
	# `docs/quests/main/MQ00-the-leap.md` §The Waystation Approach: "each bearing a
	# faded tabard printed with a **2** and a suit mark - one Cups, one Swords, one
	# Wands". The Cliff's encounter names exactly these three.
	if not assert_not_null(_catalog):
		return
	for enemy_id: StringName in [
		EnemyIds.BLANK_CUPS_TWO, EnemyIds.BLANK_SWORDS_TWO, EnemyIds.BLANK_WANDS_TWO
	]:
		var found := _catalog.find(enemy_id)
		if not assert_not_null(found, "%s is in the catalog" % enemy_id):
			continue
		assert_eq(found.printed_number(), 2, "%s bears a printed 2" % enemy_id)


# --- The hand-authored rules -----------------------------------------------------


func test_the_rules_load_and_validate() -> void:
	if not assert_not_null(_rules, "%s loads" % RULES_PATH):
		return
	var combat_rules := load(COMBAT_RULES_PATH) as CombatRules
	assert_eq(
		_rules.validate_against(combat_rules),
		PackedStringArray(),
		"the authored numbers are usable on every difficulty"
	)


func test_no_telegraph_can_fall_under_the_floor() -> void:
	# `combat.md` §Encounter philosophy: "an enemy that hits without a tell is a bug,
	# not a difficulty knob". The floor is checked against the tightest stack the
	# roster can produce - the sharpest court rank, a duel string's follow-up, a
	# Queen's aura and Trial all at once.
	if not assert_not_null(_rules):
		return
	var combat_rules := load(COMBAT_RULES_PATH) as CombatRules
	if not assert_not_null(combat_rules):
		return
	for suit: Suit.Id in Suit.ALL:
		var tightest := _rules.tightest_telegraph_for_suit(suit, combat_rules)
		assert_true(
			tightest >= EnemyRules.MIN_TELEGRAPH_SECONDS,
			"%s telegraphs for %.3f s at its tightest, floor %.3f"
			% [Suit.name_key(suit), tightest, EnemyRules.MIN_TELEGRAPH_SECONDS]
		)


func test_the_rules_refuse_a_flat_rank_curve() -> void:
	# Mutation guard: `combat.md` makes the printed number "a simple visual tell of
	# toughness", so a curve that did not rise would make the number a lie - and the
	# rules have to say so rather than shipping a Ten that folds like a Two.
	if not assert_not_null(_rules):
		return
	var flat := _rules.duplicate() as EnemyRules
	flat.rank_health_per_pip = 0.0
	assert_false(flat.validate().is_empty(), "a flat toughness curve is refused")


func test_the_rules_refuse_a_suit_that_lost_its_shape() -> void:
	# Mutation guard on the other half: the four suits' shapes ARE the canon, so a
	# table where Coins is as quick as Swords is not a retune, it is a different doc.
	if not assert_not_null(_rules):
		return
	var flattened := _rules.duplicate() as EnemyRules
	flattened.suit_move_speed = PackedFloat32Array([150.0, 100.0, 130.0, 100.0])
	assert_false(flattened.validate().is_empty(), "Coins as quick as Swords is refused")
	var no_string := _rules.duplicate() as EnemyRules
	no_string.suit_string_length = PackedInt32Array([1, 1, 1, 1])
	assert_false(no_string.validate().is_empty(), "Swords without a string is refused")


func test_the_rules_refuse_a_page_that_is_not_the_frailest() -> void:
	# `enemy_rules.tres`' own notes and `systems/enemies/README.md` both call the Page
	# "the frailest" - which is a claim about the whole field, not about the court. A
	# Page authored tougher than a Two would quietly make both of them wrong, so the
	# table refuses it rather than a reviewer having to multiply two curves by hand.
	if not assert_not_null(_rules):
		return
	assert_true(
		_rules.health_multiplier_for_rank(Rank.Id.PAGE)
			<= _rules.health_multiplier_for_rank(Rank.Id.TWO),
		"the authored Page (%.2f) is no tougher than a Two (%.2f)"
		% [
			_rules.health_multiplier_for_rank(Rank.Id.PAGE),
			_rules.health_multiplier_for_rank(Rank.Id.TWO),
		]
	)
	var sturdy := _rules.duplicate() as EnemyRules
	var court := sturdy.court_health_multipliers.duplicate()
	court[Rank.court_index(Rank.Id.PAGE)] = (
		sturdy.health_multiplier_for_rank(Rank.Id.TWO) + 0.1
	)
	sturdy.court_health_multipliers = court
	assert_false(sturdy.validate().is_empty(), "a Page tougher than a Two is refused")


# --- Identity times tuning --------------------------------------------------------


func test_a_ten_is_a_real_fight_and_a_two_folds_fast() -> void:
	# `combat.md`: "the printed number on the Blank's back is a simple visual tell of
	# toughness - a Two folds fast, a Ten is a real fight". Monotone across every pip
	# rank, in every suit: not just the endpoints.
	if not assert_not_null(_catalog) or not assert_not_null(_rules):
		return
	for suit: Suit.Id in Suit.ALL:
		var previous := 0
		for rank: Rank.Id in Rank.PIPS:
			var found := _catalog.find_blank(suit, rank)
			if not assert_not_null(found):
				continue
			var stats := found.stats(_rules)
			if not assert_not_null(stats):
				continue
			assert_true(
				stats.max_health > previous,
				"%s is tougher than the rank below it (%d)" % [found.id, stats.max_health]
			)
			previous = stats.max_health


func test_the_court_ranks_are_roles_and_not_just_bigger_numbers() -> void:
	# `combat.md`'s Role table, as behaviour rather than as prose: the Page flees and
	# is frailest, the Knight is elite, the Queen commands, the King is a mini-boss.
	if not assert_not_null(_catalog) or not assert_not_null(_rules):
		return
	var ten := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.TEN).stats(_rules)
	var page := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.PAGE).stats(_rules)
	var knight := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.KNIGHT).stats(_rules)
	var queen := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.QUEEN).stats(_rules)
	var king := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.KING).stats(_rules)
	if not assert_not_null(ten) or not assert_not_null(king):
		return
	assert_true(page.flees_to_alert, "the Page is the alarm-raiser")
	assert_false(knight.flees_to_alert, "and nobody else is")
	assert_true(queen.grants_aura, "the Queen commands")
	assert_false(king.grants_aura, "and nobody else does")
	assert_true(page.move_speed > knight.move_speed, "the Page is the fastest thing here")
	var two := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.TWO).stats(_rules)
	assert_true(
		page.max_health <= two.max_health,
		"and the frailest: %d health against a Two's %d" % [page.max_health, two.max_health]
	)
	assert_true(knight.telegraph_seconds < ten.telegraph_seconds, "the Knight tells fastest")
	assert_true(king.max_health > ten.max_health, "the King is a set piece, not a bigger mook")


func test_each_suit_fights_the_way_the_doc_says() -> void:
	# One assertion per row of `combat.md`'s Combat role table, read off the solved
	# stat block rather than off the rules - because this is what a Blank actually
	# gets, identity and tuning multiplied together.
	if not assert_not_null(_catalog) or not assert_not_null(_rules):
		return
	var cups := _catalog.find_blank(Suit.Id.CUPS, Rank.Id.TWO).stats(_rules)
	var swords := _catalog.find_blank(Suit.Id.SWORDS, Rank.Id.TWO).stats(_rules)
	var wands := _catalog.find_blank(Suit.Id.WANDS, Rank.Id.TWO).stats(_rules)
	var coins := _catalog.find_blank(Suit.Id.COINS, Rank.Id.TWO).stats(_rules)
	if not assert_not_null(cups) or not assert_not_null(coins):
		return
	assert_true(cups.is_ranged, "Cups are ranged lobbers")
	assert_true(cups.preferred_range > 0.0, "and keep a stand-off range")
	assert_false(swords.is_ranged, "Swords are not")
	assert_eq(swords.string_length, 3, "Swords throw a tight string")
	assert_eq(cups.string_length, 1, "and nobody else does")
	assert_true(wands.attack_radius > swords.attack_radius, "Wands have polearm reach")
	assert_eq(wands.hit_tag, &"FIRE", "and tag their hits with fire")
	assert_eq(swords.hit_tag, &"", "which nobody else does")
	assert_true(coins.has_shield, "Coins carry a shield")
	assert_false(swords.has_shield, "and nobody else does")
	assert_true(coins.armour_multiplier < 1.0, "and are armoured under it")
	assert_true(coins.max_health > swords.max_health, "Coins are the bruiser")
	assert_true(coins.move_speed < swords.move_speed, "and the slow one")
	assert_true(swords.telegraph_seconds < coins.telegraph_seconds, "Swords are the fast one")


func test_the_stat_block_is_solved_once_per_definition() -> void:
	# `technical.md` §Performance guardrails: nothing per frame. A fight that spawns
	# fifty Blanks must solve fifty stat blocks once each, which is what the cache is
	# for - and the cache must not survive a different rules table.
	if not assert_not_null(_catalog) or not assert_not_null(_rules):
		return
	var found := _catalog.find_blank(Suit.Id.WANDS, Rank.Id.FIVE)
	if not assert_not_null(found):
		return
	var first := found.stats(_rules)
	assert_eq(found.stats(_rules), first, "the same rules give the same instance back")
	var retuned := _rules.duplicate() as EnemyRules
	retuned.suit_health = PackedInt32Array([100, 100, 100, 100])
	var second := found.stats(retuned)
	assert_ne(second, first, "a different rules table is solved again")
	assert_ne(second.max_health, first.max_health, "and really uses the new numbers")


# --- Drift -------------------------------------------------------------------------


func test_regenerating_from_the_docs_would_change_nothing() -> void:
	# A suit's row edited without regenerating is a failing test, not a Blank that
	# quietly keeps doing the old thing.
	var python := _python3()
	if python.is_empty():
		print("SKIP: python3 is not on PATH, so the generator drift check did not run")
		return
	var generator := ProjectSettings.globalize_path(GENERATOR_PATH)
	if not assert_true(FileAccess.file_exists(generator), "%s exists" % generator):
		return
	var output: Array = []
	var exit_code := OS.execute(python, [generator, "--check"], output, true)
	assert_eq(exit_code, 0, "gen_definitions.py --check:\n%s" % "\n".join(PackedStringArray(output)))


func test_the_generator_leaves_the_hand_authored_rules_alone() -> void:
	# `--check` sweeps every generated directory for orphans. `enemy_rules.tres` lives
	# in one and is authored by hand; a sweep that called it stale would put the tree
	# permanently red and invite somebody to delete every enemy number in the game.
	var python := _python3()
	if python.is_empty():
		print("SKIP: python3 is not on PATH, so the stale sweep was not checked")
		return
	var output: Array = []
	OS.execute(python, [ProjectSettings.globalize_path(GENERATOR_PATH), "--check"], output, true)
	var text := "\n".join(PackedStringArray(output))
	assert_false(text.contains("enemy_rules.tres"), "the authored enemy numbers are not swept")


# --- Wiring -------------------------------------------------------------------------


func test_the_composition_root_owns_the_enemy_service() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var enemies: EnemyService = services.get("enemies")
	if not assert_not_null(enemies, "Services built its EnemyService"):
		return
	assert_not_null(enemies.catalog(), "over the generated catalog")
	assert_not_null(enemies.rules(), "and the authored rules")
	assert_eq(enemies.alive_count(), 0, "with nothing standing on a fresh boot")
	assert_not_null(
		enemies.definition(EnemyIds.BLANK_SWORDS_TWO), "and it can find a Blank by id"
	)


# --- Helpers -------------------------------------------------------------------------


## `docs/design/combat.md`, read from outside `res://`.
func _combat_text() -> String:
	var path := ProjectSettings.globalize_path("res://").path_join(
		COMBAT_DOC_RELATIVE
	).simplify_path()
	return FileAccess.get_file_as_string(path)


func _python3() -> String:
	for directory: String in OS.get_environment("PATH").split(":", false):
		var candidate := directory.path_join("python3")
		if FileAccess.file_exists(candidate):
			return candidate
	return ""
