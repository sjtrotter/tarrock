extends TarrockTest

## The generated Trump data, against the doc it was generated from.
##
## `godot/tools/gen_definitions.py` lifts every "**Trump N - Name.**" block out of
## `docs/design/arcana.md` into the `.tres` files under `res://data/trumps/`, the
## `TrumpIds` constants and the Trump-name translation table. This suite is the
## drift guard `docs/design/technical.md` §Testing asks for: the data loads, it says
## what `arcana.md` says, each Trump is granted by its own Arcana's unbinding flag,
## the Magician's hand-authored effects are linked and complete, and re-running the
## generator would change nothing.

const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const TRUMP_01_EFFECTS_PATH := "res://data/trumps/effects/TRUMP_01.tres"
const NAMES_CSV_PATH := "res://localization/trumps.csv"
const NAMES_TABLE_PATH := "res://localization/trumps.en.translation"
const GENERATOR_PATH := "res://tools/gen_definitions.py"

## Where `docs/` sits relative to the project. The docs are outside `res://` on
## purpose - they are the source, not shipped content.
const ARCANA_DOC_RELATIVE := "../docs/design/arcana.md"

## `arcana.md` XXI: "The World's card is not carried. It is turned." Twenty-one
## Arcana, twenty Trumps - restated here so deleting the sentence fails a test.
const DOCUMENTED_TRUMPS := 20

## The Magician's authored effect and burden ids, as `data/trumps/effects/` spells
## them. Named here so renaming one in the resource without meaning to fails.
const MANIFEST_PRESENT_EFFECT := &"CONJURED_HAND"
const MANIFEST_BURDEN := &"THE_TRICK_COSTS_THE_TRICKSTER"

## The one number `arcana.md` gives the Magician's burden: "each trigger nicks 5
## Fortune extra".
const MANIFEST_BURDEN_EXTRA_FORTUNE := 5.0

var _catalog: TrumpCatalog = null
var _world_states: WorldStateCatalog = null


func before_each() -> void:
	_catalog = load(TRUMP_CATALOG_PATH) as TrumpCatalog
	_world_states = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog


# --- The generated catalog ---------------------------------------------------


func test_the_catalog_loads_and_validates() -> void:
	if not assert_not_null(_catalog, "%s loads" % TRUMP_CATALOG_PATH):
		return
	assert_eq(
		_catalog.validate(_world_states),
		PackedStringArray(),
		"the generated Trumps are self-consistent and resolve every flag they name"
	)


func test_there_are_exactly_twenty_trumps() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(_catalog.entries.size(), DOCUMENTED_TRUMPS, "one Trump per card I..XX")
	var cards: Dictionary = {}
	for entry: TrumpDefinition in _catalog.entries:
		if not assert_not_null(entry, "no empty catalog entry"):
			continue
		assert_false(cards.has(entry.card_number), "card %d appears once" % entry.card_number)
		cards[entry.card_number] = entry.id
	for number: int in range(1, DOCUMENTED_TRUMPS + 1):
		assert_true(cards.has(number), "card %d has a Trump" % number)


func test_the_world_yields_no_trump() -> void:
	# `arcana.md` §XXI: the World's card is turned, not carried. A twenty-first
	# Trump would be a card the Fool could slot at the end of the world.
	if not assert_not_null(_catalog):
		return
	assert_null(_catalog.find_by_card(21), "the World has no Trump")
	assert_false(_catalog.has(&"TRUMP_21"), "and no id for one")


func test_every_trump_is_granted_by_its_own_arcanas_unbinding() -> void:
	if not assert_not_null(_catalog) or not assert_not_null(_world_states):
		return
	for entry: TrumpDefinition in _catalog.entries:
		var flag := _world_states.find(entry.granted_by_flag)
		if not assert_not_null(flag, "%s names a real flag" % entry.id):
			continue
		assert_true(flag.is_unbinding(), "%s is granted by an unbinding" % entry.id)
		assert_eq(flag.arcana_number, entry.card_number, "%s is granted by its own card" % entry.id)


func test_trump_names_come_from_the_doc_through_a_key() -> void:
	TranslationServer.set_locale("en")
	assert_eq(TranslationServer.translate(&"TRUMP_01_NAME"), "Manifest")
	assert_eq(TranslationServer.translate(&"TRUMP_12_NAME"), "Overturn")
	assert_eq(TranslationServer.translate(&"TRUMP_20_NAME"), "Reveille")


func test_every_trump_name_key_translates() -> void:
	if not assert_not_null(_catalog):
		return
	TranslationServer.set_locale("en")
	assert_true(ResourceLoader.exists(NAMES_TABLE_PATH), "%s is imported" % NAMES_TABLE_PATH)
	for entry: TrumpDefinition in _catalog.entries:
		var translated := TranslationServer.translate(entry.name_key)
		assert_ne(
			translated, String(entry.name_key), "%s translates to a name" % entry.name_key
		)


func test_the_summaries_are_the_docs_own_cells() -> void:
	# Verbatim, not paraphrased: `burden_summary` and the three slot summaries exist
	# so a reviewer can read the card without leaving the resource, and so this test
	# can compare them to the doc. A rewritten cell fails here.
	if not assert_not_null(_catalog):
		return
	var doc := _arcana_text()
	if not assert_true(doc.length() > 0, "the arcana doc is readable"):
		return
	for entry: TrumpDefinition in _catalog.entries:
		for summary: String in [entry.past_summary, entry.present_summary, entry.future_summary]:
			assert_true(
				doc.contains(summary), "%s carries a cell arcana.md does not have" % entry.id
			)
		assert_true(doc.contains(entry.burden_name), "%s names a burden arcana.md has" % entry.id)


func test_every_trump_cites_its_doc_section() -> void:
	if not assert_not_null(_catalog):
		return
	for entry: TrumpDefinition in _catalog.entries:
		assert_true(entry.doc_ref.begins_with("docs/design/arcana.md"), "%s cites arcana.md" % entry.id)
	var magician := _catalog.find(TrumpIds.TRUMP_01)
	if not assert_not_null(magician):
		return
	assert_eq(magician.doc_ref, "docs/design/arcana.md §I. The Magician")


# --- The generated constants -------------------------------------------------


func test_trump_ids_match_the_catalog() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(TrumpIds.ALL.size(), _catalog.entries.size(), "one constant per Trump")
	for entry: TrumpDefinition in _catalog.entries:
		assert_has(TrumpIds.ALL, entry.id, "%s has a constant" % entry.id)
	assert_eq(TrumpIds.TRUMP_01, &"TRUMP_01")
	assert_eq(TrumpIds.ALL[0], TrumpIds.TRUMP_01, "the constants are in card order")


func test_the_name_table_holds_one_row_per_trump() -> void:
	var lines := FileAccess.get_file_as_string(NAMES_CSV_PATH).split("\n", false)
	assert_eq(lines.size(), DOCUMENTED_TRUMPS + 1, "a header plus one row per Trump")
	assert_eq(lines[0], "keys,en", "the table is a Godot translation CSV")


# --- The hand-authored effects -----------------------------------------------


func test_the_magicians_effects_are_linked_and_complete() -> void:
	if not assert_not_null(_catalog):
		return
	var magician := _catalog.find(TrumpIds.TRUMP_01)
	if not assert_not_null(magician, "TRUMP_01 is in the catalog"):
		return
	if not assert_true(magician.has_effects(), "MQ01's Trump has authored effects"):
		return
	assert_eq(magician.effects.validate(), PackedStringArray(), "the six expressions validate")
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		for orientation: CardOrientation.Id in CardOrientation.ALL:
			var effect := magician.effect_for(slot, orientation)
			assert_not_null(effect, "%s %s is authored" % [
				SpreadSlot.name_key(slot), CardOrientation.name_key(orientation)
			])


func test_the_magicians_present_casts_cost_fortune_both_ways_up() -> void:
	# `progression.md` §Fortune: casts cost 20-50, and a reversed cast costs less
	# than its upright counterpart. The exact numbers are TBD placeholders; that
	# reversed is cheaper is not.
	var effects := load(TRUMP_01_EFFECTS_PATH) as TrumpEffects
	if not assert_not_null(effects, "%s loads" % TRUMP_01_EFFECTS_PATH):
		return
	var upright := effects.for_slot(SpreadSlot.Id.PRESENT, CardOrientation.Id.UPRIGHT)
	var reversed_effect := effects.for_slot(SpreadSlot.Id.PRESENT, CardOrientation.Id.REVERSED)
	if not assert_not_null(upright) or not assert_not_null(reversed_effect):
		return
	assert_true(upright.present_cost > 0, "an upright cast costs Fortune")
	assert_true(reversed_effect.present_cost > 0, "so does a reversed one")
	assert_true(
		reversed_effect.present_cost < upright.present_cost, "reversed costs less than upright"
	)
	assert_eq(upright.effect_id, MANIFEST_PRESENT_EFFECT, "both ways up run the same trick")
	assert_eq(reversed_effect.effect_id, MANIFEST_PRESENT_EFFECT)


func test_the_magicians_burden_carries_the_docs_one_number() -> void:
	var effects := load(TRUMP_01_EFFECTS_PATH) as TrumpEffects
	if not assert_not_null(effects) or not assert_not_null(effects.burden):
		return
	assert_eq(effects.burden.burden_id, MANIFEST_BURDEN)
	assert_almost_eq(
		effects.burden.param(&"extra_fortune_per_trigger", 0.0),
		MANIFEST_BURDEN_EXTRA_FORTUNE,
		0.0001,
		"arcana.md: each trigger nicks 5 Fortune extra"
	)


func test_a_reversed_expression_differs_from_its_upright_by_more_than_its_cost() -> void:
	# `arcana.md` design rule 5: one card, SIX expressions - reversed "strengthens its
	# effect in that slot" and attaches the burden. An authored reversed effect that
	# is the upright one with a smaller price tag has not been authored: it is the
	# upright expression wearing a discount, and the six-expression rule has been
	# under-implemented in exactly the way `technical.md` says the data shape exists
	# to prevent. So every authored file must differ in what the expression DOES -
	# its `effect_id` or its `params` - in all three slots, not only in its cost.
	#
	# Where the doc gives no number for the difference (the Magician's "bigger hand"),
	# the param is a TBD placeholder and its `notes` say so. A placeholder is the
	# honest answer; sameness is not.
	if not assert_not_null(_catalog):
		return
	var authored := 0
	for entry: TrumpDefinition in _catalog.entries:
		if entry == null or not entry.has_effects():
			continue
		authored += 1
		for slot: SpreadSlot.Id in SpreadSlot.ALL:
			var upright := entry.effect_for(slot, CardOrientation.Id.UPRIGHT)
			var reversed_effect := entry.effect_for(slot, CardOrientation.Id.REVERSED)
			if not assert_not_null(upright) or not assert_not_null(reversed_effect):
				continue
			assert_true(
				upright.effect_id != reversed_effect.effect_id
				or _params_differ(upright.params, reversed_effect.params),
				"%s %s reversed does something the upright one does not" % [
					entry.id, SpreadSlot.name_key(slot)
				]
			)
			assert_false(
				reversed_effect.notes.strip_edges().is_empty(),
				"%s %s reversed says where its difference came from" % [
					entry.id, SpreadSlot.name_key(slot)
				]
			)
	assert_true(authored > 0, "there is at least one authored effects file to check")


func test_every_other_trump_is_still_unauthored() -> void:
	# Not a wish: it is what makes `PocketSpreadService`'s "held and slottable, but
	# refuses to cast" path real rather than theoretical. When a later round authors
	# a second Trump, this test is the one that notices and gets narrowed.
	if not assert_not_null(_catalog):
		return
	var authored: Array[StringName] = []
	for entry: TrumpDefinition in _catalog.entries:
		if entry.has_effects():
			authored.append(entry.id)
	assert_eq(authored, [TrumpIds.TRUMP_01] as Array[StringName], "only the Magician so far")


# --- The hand-authored rules -------------------------------------------------


func test_the_spread_rules_load_and_validate() -> void:
	var rules := load(SPREAD_RULES_PATH) as SpreadRules
	if not assert_not_null(rules, "%s loads" % SPREAD_RULES_PATH):
		return
	assert_eq(rules.validate(), PackedStringArray(), "the authored numbers are usable")


# --- Drift -------------------------------------------------------------------


func test_regenerating_from_the_docs_would_change_nothing() -> void:
	# A Trump's table edited without regenerating is a failing test, not a card that
	# quietly does the old thing.
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


func test_the_generator_leaves_the_hand_authored_files_alone() -> void:
	# `--check` sweeps every generated directory for orphans. `spread_rules.tres`
	# lives in one and is authored by hand; a sweep that called it stale would put
	# the tree permanently red and invite somebody to delete it.
	var python := _python3()
	if python.is_empty():
		print("SKIP: python3 is not on PATH, so the stale sweep was not checked")
		return
	var output: Array = []
	OS.execute(python, [ProjectSettings.globalize_path(GENERATOR_PATH), "--check"], output, true)
	var text := "\n".join(PackedStringArray(output))
	assert_false(text.contains("spread_rules.tres"), "the authored rules are not swept")
	assert_false(text.contains("effects/"), "the authored effects are not swept")


# --- Wiring ------------------------------------------------------------------


func test_the_composition_root_owns_the_three_progression_services() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var spread: PocketSpreadService = services.get("spread")
	var fortune: FortuneService = services.get("fortune")
	var rose: WhiteRoseService = services.get("rose")
	if not assert_not_null(spread, "Services built its PocketSpreadService"):
		return
	assert_not_null(fortune, "Services built its FortuneService")
	if not assert_not_null(rose, "Services built its WhiteRoseService"):
		return
	assert_eq(spread.held_ids(), [] as Array[StringName], "a fresh boot holds no Trump")
	assert_eq(rose.petals(), 3, "the White Rose starts at three petals")


# --- Helpers -----------------------------------------------------------------


## True when two param dictionaries hold a different set of keys, or a different
## number under one of them.
##
## Spelled out rather than `!=`, because a param key may be authored as a String in a
## hand-written `.tres` and as a StringName by the editor (the reason
## `TrumpEffect.param()` tries both spellings), and two dictionaries that differ only
## in that are not two different expressions.
func _params_differ(left: Dictionary, right: Dictionary) -> bool:
	var flat_left := _flatten_params(left)
	var flat_right := _flatten_params(right)
	if flat_left.size() != flat_right.size():
		return true
	for key: String in flat_left:
		if not flat_right.has(key):
			return true
		if not is_equal_approx(float(flat_left[key]), float(flat_right[key])):
			return true
	return false


## A param dictionary as `String -> float`, so the two key spellings compare equal.
func _flatten_params(params: Dictionary) -> Dictionary:
	var flat: Dictionary = {}
	for key: Variant in params:
		var value: Variant = params[key]
		if (key is String or key is StringName) and (value is int or value is float):
			flat[String(key)] = float(value)
	return flat


## `docs/design/arcana.md`, read from outside `res://`.
func _arcana_text() -> String:
	var path := ProjectSettings.globalize_path("res://").path_join(
		ARCANA_DOC_RELATIVE
	).simplify_path()
	return FileAccess.get_file_as_string(path)


func _python3() -> String:
	for directory: String in OS.get_environment("PATH").split(":", false):
		var candidate := directory.path_join("python3")
		if FileAccess.file_exists(candidate):
			return candidate
	return ""
