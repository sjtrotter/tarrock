extends TarrockTest

## The generated region data, against the docs it was generated from.
##
## `godot/tools/gen_definitions.py` lifts `docs/design/world.md` §Regions (one bullet
## per region) and §Intended difficulty bands into the `.tres` files under
## `res://data/regions/`, the `RegionIds` constants and the region-name translation
## table. This suite is the drift guard `docs/design/technical.md` §Testing asks for:
## the data loads, all twenty-two regions are there exactly once, each carries the
## card, band and unbinding flag its doc row gives it, every name resolves through the
## CSV, and re-running the generator would change nothing.
##
## The ADJACENCY is not tested here - it is hand-authored and has its own suite
## (`region_graph_test.gd`), for the reason `RegionGraph`'s class doc gives.

const CATALOG_PATH := "res://data/regions/catalog.tres"
const GRAPH_PATH := "res://data/regions/region_graph.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const GENERATOR_PATH := "res://tools/gen_definitions.py"

## Where `docs/` sits relative to the project - outside `res://` on purpose.
const WORLD_DOC_RELATIVE := "../docs/design/world.md"
const GLOSSARY_DOC_RELATIVE := "../docs/GLOSSARY.md"

## `world.md` §The Spread: "21 regions arranged in a wheel around the Axis, with the
## Cliff hanging off the south-east rim". Restated here so a region deleted from the
## doc fails a test rather than quietly shrinking the world.
const DOCUMENTED_ARCANA_REGIONS := 21
const DOCUMENTED_REGIONS := DOCUMENTED_ARCANA_REGIONS + 1

## `progression.md` §Waystations: "one per region and along the Longroad". The
## Longroad's network is four placeholders (`gen_definitions.py`), which is a TBD
## count and pinned here so changing it is a decision somebody makes on purpose.
const LONGROAD_WAYSTATIONS := 4

var _catalog: RegionCatalog = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as RegionCatalog


# --- The generated catalog -----------------------------------------------------


func test_the_catalog_loads_and_validates() -> void:
	if not assert_not_null(_catalog, "%s loads" % CATALOG_PATH):
		return
	var world_states := load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	assert_eq(
		_catalog.validate(world_states),
		PackedStringArray(),
		"the generated regions are self-consistent and resolve every flag they name"
	)


func test_every_card_from_zero_to_twenty_one_is_a_region_exactly_once() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(_catalog.entries.size(), DOCUMENTED_REGIONS, "the Cliff plus I-XXI")
	var seen: Dictionary = {}
	for entry: RegionDefinition in _catalog.entries:
		assert_false(seen.has(entry.card_number), "card %d appears once" % entry.card_number)
		seen[entry.card_number] = entry.id
	for card: int in range(0, DOCUMENTED_REGIONS):
		assert_true(seen.has(card), "some region carries card %d" % card)


func test_the_cliff_is_card_zero_outside_the_spread() -> void:
	if not assert_not_null(_catalog):
		return
	var cliff := _catalog.find(RegionIds.CLIFF)
	if not assert_not_null(cliff, "the Cliff is in the catalog"):
		return
	assert_eq(cliff.card_number, 0)
	assert_true(cliff.is_the_cliff())
	# `world.md` §The Cliff: no Arcana, no unbinding - which is exactly why the White
	# Rose never regrows there (`progression.md` §The White Rose, "does not regrow at
	# all in still-bound regions").
	assert_eq(cliff.unbinding_flag, &"", "the Cliff has no Arcana to unbind")
	assert_eq(cliff.difficulty_band, DifficultyBand.Id.NONE, "and no difficulty band")


func test_every_arcana_region_names_its_own_unbinding_flag() -> void:
	if not assert_not_null(_catalog):
		return
	# The flag with the region's own card number, and no other: a region awakened by
	# the wrong Arcana's flag would regrow the Rose at the wrong moment of the game,
	# and nothing else would notice.
	for card: int in range(1, DOCUMENTED_REGIONS):
		var region := _catalog.find_by_card(card)
		if region == null:
			continue
		assert_eq(
			region.unbinding_flag,
			WorldStateIds.UNBINDING[card - 1],
			"%s is awake once card %d is unbound" % [region.id, card]
		)


func test_the_bands_are_the_docs_own_lists() -> void:
	if not assert_not_null(_catalog):
		return
	# `world.md` §Intended difficulty bands, restated: five entry, eight developing,
	# six committed, two finale. Twenty-one regions in bands, the Cliff in none.
	assert_eq(_catalog.of_band(DifficultyBand.Id.ENTRY).size(), 5)
	assert_eq(_catalog.of_band(DifficultyBand.Id.DEVELOPING).size(), 8)
	assert_eq(_catalog.of_band(DifficultyBand.Id.COMMITTED).size(), 6)
	assert_eq(_catalog.of_band(DifficultyBand.Id.FINALE).size(), 2)
	assert_eq(_catalog.of_band(DifficultyBand.Id.NONE).size(), 1, "only the Cliff")
	var prestige := _catalog.find(RegionIds.PRESTIGE)
	assert_eq(prestige.difficulty_band, DifficultyBand.Id.ENTRY, "the intended first region")
	var hollows := _catalog.find(RegionIds.HOLLOWS)
	assert_eq(hollows.difficulty_band, DifficultyBand.Id.FINALE, "the gated finale region")


func test_a_band_is_never_a_gate() -> void:
	# `world.md` §Intended difficulty bands is headed "soft, never enforced", and the
	# doc spells out why: "A Band 3 region at hour two should feel like Hyrule Castle
	# at hour two: survivable by the brilliant". So nothing in the region system may
	# refuse a journey for a band, and the only place that could is the refusal list.
	var reasons := PackedStringArray()
	for band: DifficultyBand.Id in DifficultyBand.ALL:
		reasons.append(String(DifficultyBand.key(band)))
	for refusal: StringName in [
		RegionService.REASON_NO_SUCH_REGION,
		RegionService.REASON_NO_SCENE,
		RegionService.REASON_NOT_ADJACENT,
		RegionService.REASON_GATE_CLOSED,
		RegionService.REASON_ALREADY_THERE,
		RegionService.REASON_NO_SWAPPER,
		RegionService.REASON_NO_SUCH_WAYSTATION,
		RegionService.REASON_NOT_AT_WAYSTATION,
		RegionService.REASON_NO_FAST_TRAVEL,
		RegionService.REASON_NOT_VISITED,
		RegionService.REASON_NOT_HERE,
	]:
		assert_false(
			reasons.has(String(refusal)),
			"%s is not a reason to refuse travel; a band is a tuning label" % refusal
		)


func test_every_region_has_a_waystation_and_the_longroad_has_a_network() -> void:
	if not assert_not_null(_catalog):
		return
	# `progression.md` §Waystations: "Wayside shrines, one per region and along the
	# Longroad, are the game's rest points".
	for entry: RegionDefinition in _catalog.entries:
		assert_false(entry.waystation_ids.is_empty(), "%s has a Waystation" % entry.id)
	assert_eq(
		_catalog.find(RegionIds.LONGROAD).waystation_ids.size(),
		LONGROAD_WAYSTATIONS,
		"the Longroad carries a network, not a shrine (count is a placeholder)"
	)
	assert_eq(
		_catalog.waystation_ids().size(),
		DOCUMENTED_REGIONS + LONGROAD_WAYSTATIONS - 1,
		"one per region, plus the Longroad's extra three"
	)


func test_a_waystation_id_resolves_back_to_its_region() -> void:
	if not assert_not_null(_catalog):
		return
	# The lookup fast travel and the defeat loop both run on: an id is all a save file
	# carries.
	assert_eq(_catalog.find_by_waystation(RegionIds.WAYSTATION_CLIFF).id, RegionIds.CLIFF)
	assert_eq(
		_catalog.find_by_waystation(RegionIds.WAYSTATION_LONGROAD_W).id, RegionIds.LONGROAD
	)
	assert_null(_catalog.find_by_waystation(&"WAYSTATION_NOWHERE"))


func test_the_cliff_and_the_prestige_have_scenes_and_the_rest_do_not_yet() -> void:
	if not assert_not_null(_catalog):
		return
	# Two of twenty-two are built. That is not a failure - `has_scene()` is what makes
	# an unbuilt region a refusal instead of a crash - but it IS a fact worth pinning,
	# so the day a third region ships somebody updates this number on purpose.
	var built: Array[StringName] = []
	for entry: RegionDefinition in _catalog.entries:
		if entry.has_scene():
			built.append(entry.id)
	assert_eq(built, [RegionIds.CLIFF, RegionIds.PRESTIGE] as Array[StringName])
	assert_eq(
		_catalog.find(RegionIds.CLIFF).scene_path,
		"res://scenes/the_cliff.tscn",
		"the Cliff keeps the path the art lane knows"
	)


func test_every_region_name_resolves_through_the_translation_table() -> void:
	if not assert_not_null(_catalog):
		return
	# `technical.md` §Localization: the CSV is the only place the English lives. A key
	# that resolves to itself is a key with no row, which is how a missing translation
	# looks at runtime.
	var glossary := _glossary_text()
	for entry: RegionDefinition in _catalog.entries:
		var name_text := tr(entry.name_key)
		assert_ne(name_text, String(entry.name_key), "%s translates" % entry.name_key)
		assert_true(name_text.begins_with("The "), "%s keeps its article" % name_text)
		assert_true(
			glossary.contains("**%s**" % name_text),
			"%s is the glossary's own spelling" % name_text
		)


func test_the_region_ids_constants_match_the_catalog() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(RegionIds.ALL, _catalog.ids(), "one constant per region, in card order")
	assert_eq(RegionIds.WAYSTATIONS, _catalog.waystation_ids())


func test_the_summaries_are_the_docs_own_bullets() -> void:
	if not assert_not_null(_catalog):
		return
	var doc := _world_text()
	for entry: RegionDefinition in _catalog.entries:
		if not assert_ne(entry.summary, "", "%s carries its bullet" % entry.id):
			continue
		# The bullet is dewrapped into one line, so the doc is compared on its first
		# sentence - enough to catch a summary that drifted from the row it came from.
		var opening := entry.summary.split(".")[0]
		assert_true(
			doc.contains(opening.substr(0, 40)),
			"%s's summary opens with the doc's own words: %s" % [entry.id, opening]
		)


# --- Drift ----------------------------------------------------------------------


func test_regenerating_from_the_docs_would_change_nothing() -> void:
	# A region bullet edited without regenerating is a failing test, not a Spread that
	# quietly keeps the old shape.
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


func test_the_generator_leaves_the_hand_authored_graph_alone() -> void:
	# `--check` sweeps every generated directory for orphans. `region_graph.tres` lives
	# in one and is authored by hand; a sweep that called it stale would put the tree
	# permanently red and invite somebody to delete the whole adjacency of the world.
	var python := _python3()
	if python.is_empty():
		print("SKIP: python3 is not on PATH, so the stale sweep was not checked")
		return
	var output: Array = []
	OS.execute(python, [ProjectSettings.globalize_path(GENERATOR_PATH), "--check"], output, true)
	var text := "\n".join(PackedStringArray(output))
	assert_false(text.contains("region_graph.tres"), "the authored adjacency is not swept")
	assert_true(
		FileAccess.file_exists(ProjectSettings.globalize_path(GRAPH_PATH)),
		"and it is still there"
	)


# --- Wiring -------------------------------------------------------------------------


func test_the_composition_root_owns_the_region_service() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var regions: RegionService = services.get("regions")
	if not assert_not_null(regions, "Services built its RegionService"):
		return
	assert_not_null(regions.catalog(), "over the generated catalog")
	assert_not_null(regions.graph(), "and the authored adjacency")
	assert_not_null(
		regions.definition(RegionIds.PRESTIGE), "and it can find a region by id"
	)


# --- Helpers -------------------------------------------------------------------------


func _world_text() -> String:
	return _doc_text(WORLD_DOC_RELATIVE)


func _glossary_text() -> String:
	return _doc_text(GLOSSARY_DOC_RELATIVE)


## One of the docs, read from outside `res://`.
func _doc_text(relative: String) -> String:
	var path := ProjectSettings.globalize_path("res://").path_join(relative).simplify_path()
	return FileAccess.get_file_as_string(path)


func _python3() -> String:
	for directory: String in OS.get_environment("PATH").split(":", false):
		var candidate := directory.path_join("python3")
		if FileAccess.file_exists(candidate):
			return candidate
	return ""
