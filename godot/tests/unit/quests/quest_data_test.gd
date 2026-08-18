extends TarrockTest

## The generated quest data, against the docs it was generated from.
##
## `godot/tools/gen_definitions.py` lifts every `docs/quests/**/*.md` frontmatter
## block into the `.tres` files under `res://data/quests/`, the `QuestIds` constants
## and the quest-title translation table. This suite is the drift guard
## `docs/design/technical.md` §Testing asks for: the data loads, it says what the
## quest docs say, the constants agree with it, MQ00's hand-authored graph is linked
## and sane, and re-running the generator would change nothing.

const QUEST_CATALOG_PATH := "res://data/quests/catalog.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const MQ00_GRAPH_PATH := "res://data/quests/graphs/MQ00.tres"
const TITLES_CSV_PATH := "res://localization/quest_titles.csv"
const TITLES_TABLE_PATH := "res://localization/quest_titles.en.translation"
const GENERATOR_PATH := "res://tools/gen_definitions.py"

## Where `docs/` sits relative to the project. The docs are outside `res://` on
## purpose - they are the source, not shipped content.
const DOCS_QUESTS_RELATIVE := "../docs/quests"

## What `docs/quests/README.md` says, restated so a silent doc edit fails a test:
## the number is the card, and there are exactly 22 main quests, forever.
const DOCUMENTED_MAIN_QUESTS := 22

## MQ00's authored beats, in the order `docs/quests/main/MQ00-the-leap.md` plays them.
const MQ00_STATES: Array[StringName] = [
	&"WAKING",
	&"BINDLE_TAKEN",
	&"KEEPSAKE_FOUND",
	&"DEAD_TREE_SEEN",
	&"AMBUSH_CLEARED",
	&"RESTED",
	&"EDGE_REACHED",
	&"COMPLETE",
]

var _catalog: QuestCatalog = null
var _world_states: WorldStateCatalog = null


func before_each() -> void:
	_catalog = load(QUEST_CATALOG_PATH) as QuestCatalog
	_world_states = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog


# --- The generated catalog ---------------------------------------------------


func test_the_catalog_loads_and_validates() -> void:
	if not assert_not_null(_catalog, "%s loads" % QUEST_CATALOG_PATH):
		return
	assert_eq(
		_catalog.validate(_world_states),
		PackedStringArray(),
		"the generated quests are self-consistent and resolve every id they name"
	)


func test_the_catalog_holds_every_quest_doc() -> void:
	if not assert_not_null(_catalog):
		return
	var documented := _documented_quest_ids()
	assert_true(documented.size() > 0, "there are quest docs to check")
	assert_eq(
		_catalog.entries.size(),
		documented.size(),
		"one definition per quest doc's frontmatter"
	)
	for quest_id: StringName in documented:
		assert_true(_catalog.has(quest_id), "%s has no generated definition" % quest_id)


func test_there_are_exactly_twenty_two_main_quests() -> void:
	if not assert_not_null(_catalog):
		return
	var main := 0
	var numbers: Dictionary = {}
	for entry: QuestDefinition in _catalog.entries:
		if not entry.is_main():
			continue
		main += 1
		assert_false(numbers.has(entry.arcana_number), "two main quests claim one card")
		numbers[entry.arcana_number] = entry.id
	assert_eq(main, DOCUMENTED_MAIN_QUESTS, "MQ00 plus one per card, forever")


func test_every_main_quests_number_is_its_card() -> void:
	if not assert_not_null(_catalog):
		return
	for entry: QuestDefinition in _catalog.entries:
		if not entry.is_main():
			continue
		var number := int(String(entry.id).substr(2))
		assert_eq(entry.arcana_number, number, "%s's arcana is not its number" % entry.id)


func test_every_side_quest_id_carries_a_known_token() -> void:
	if not assert_not_null(_catalog):
		return
	var regions: Dictionary = {}
	for entry: QuestDefinition in _catalog.entries:
		regions[entry.region_id] = true
	# The suit-culture quests (`SQ-CUPS-01`) are homed to a region, not to a suit,
	# so no id token leaks into `region_id` (docs/quests/README.md §ID scheme).
	for suit: StringName in [&"CUPS", &"SWORDS", &"WANDS", &"COINS"] as Array[StringName]:
		assert_false(regions.has(suit), "%s is a suit, not a region" % suit)
	assert_true(regions.has(&"CLIFF"), "the Cliff is a region a quest is homed to")
	assert_true(regions.has(&"SPREAD"), "the world-spanning quests are homed to the Spread")


func test_the_generated_constants_match_the_catalog() -> void:
	if not assert_not_null(_catalog):
		return
	assert_eq(QuestIds.ALL, _catalog.ids(), "QuestIds and the catalog are one list")
	assert_eq(QuestIds.MAIN.size() + QuestIds.SIDE.size(), QuestIds.ALL.size())
	assert_eq(QuestIds.MAIN.size(), DOCUMENTED_MAIN_QUESTS)
	assert_eq(QuestIds.MQ00, &"MQ00")
	assert_true(QuestIds.SIDE.has(QuestIds.SQ_PRESTIGE_01))


# --- MQ00's authored graph ---------------------------------------------------


func test_mq00_links_its_hand_authored_graph() -> void:
	if not assert_not_null(_catalog):
		return
	var mq00 := _catalog.find(QuestIds.MQ00)
	if not assert_not_null(mq00, "MQ00 is in the catalog"):
		return
	assert_true(mq00.is_playable(), "MQ00's graph is linked, not merely on disk")
	assert_eq(mq00.graph.resource_path, MQ00_GRAPH_PATH)
	assert_eq(mq00.graph.quest_id, QuestIds.MQ00)
	assert_eq(mq00.graph.validate(), PackedStringArray(), "%s" % str(mq00.graph.validate()))


func test_mq00_walks_the_scripts_beats_in_order() -> void:
	var graph := load(MQ00_GRAPH_PATH) as QuestGraph
	if not assert_not_null(graph):
		return
	var state_ids: Array[StringName] = []
	for state: QuestState in graph.states:
		state_ids.append(state.id)
		assert_false(state.notes.is_empty(), "%s cites no slugline" % state.id)
	assert_eq(state_ids, MQ00_STATES, "the graph is the morning the script writes")
	assert_eq(graph.initial_state, MQ00_STATES[0])
	assert_true(graph.is_complete_state(MQ00_STATES[MQ00_STATES.size() - 1]))


func test_mq00_listens_only_for_events_that_exist() -> void:
	var graph := load(MQ00_GRAPH_PATH) as QuestGraph
	if not assert_not_null(graph):
		return
	for event: StringName in graph.event_ids():
		assert_has(QuestEvents.ALL, event, "%s is not a QuestEvents constant" % event)
	assert_eq(graph.event_ids().size(), QuestEvents.ALL.size(), "every MQ00 event is used")


func test_mq00_fires_nothing() -> void:
	if not assert_not_null(_catalog):
		return
	var mq00 := _catalog.find(QuestIds.MQ00)
	if not assert_not_null(mq00):
		return
	# `docs/quests/main/MQ00-the-leap.md` §World-state changes: no flag fires.
	# Completing MQ00 opens the world by putting the Fool in it, nothing more.
	assert_eq(mq00.fired_states, [] as Array[StringName])
	assert_eq(mq00.required_states, [] as Array[StringName])
	assert_eq(mq00.branch_groups.size(), 0)


# --- Titles ------------------------------------------------------------------


func test_every_quest_title_is_a_key_with_english_behind_it() -> void:
	if not assert_not_null(_catalog):
		return
	TranslationServer.set_locale("en")
	var keys := _csv_keys()
	for entry: QuestDefinition in _catalog.entries:
		assert_true(keys.has(String(entry.title_key)), "%s is not in the title table" % entry.title_key)
		assert_ne(
			TranslationServer.translate(entry.title_key),
			String(entry.title_key),
			"%s translates to nothing" % entry.title_key
		)
	assert_eq(TranslationServer.translate(&"QUEST_MQ00_TITLE"), "The Leap")


func test_the_title_table_is_registered_and_imported() -> void:
	var configured: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray()
	)
	assert_has(configured, TITLES_TABLE_PATH, "project.godot must load the quest titles")
	assert_true(ResourceLoader.exists(TITLES_TABLE_PATH), "%s is missing - run --import" % TITLES_TABLE_PATH)


func test_a_title_with_a_comma_survives_the_csv() -> void:
	# `SQ-ASSIZE-01` is called "The Longest Wait, Decided"; a naive writer would have
	# split it into two columns and silently truncated the title.
	TranslationServer.set_locale("en")
	assert_eq(TranslationServer.translate(&"QUEST_SQ_ASSIZE_01_TITLE"), "The Longest Wait, Decided")


# --- Drift -------------------------------------------------------------------


func test_regenerating_from_the_docs_would_change_nothing() -> void:
	# A quest doc's frontmatter edited without regenerating is a failing test, not a
	# quest that never becomes available.
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


# --- Wiring ------------------------------------------------------------------


func test_the_composition_root_owns_a_live_quest_service() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var quests: QuestService = services.get("quests")
	if not assert_not_null(quests, "Services built its QuestService in _ready"):
		return
	assert_true(quests.is_available(QuestIds.MQ00), "MQ00 requires nothing, so it is available")
	assert_eq(quests.active_quest_ids(), [] as Array[StringName], "a fresh boot has started nothing")


# --- Helpers -----------------------------------------------------------------


## Every quest id `docs/quests/` declares, read out of the docs themselves.
func _documented_quest_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	var quests_dir := ProjectSettings.globalize_path("res://").path_join(
		DOCS_QUESTS_RELATIVE
	).simplify_path()
	for path: String in _markdown_files(quests_dir):
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with("id:"):
				found.append(StringName(line.substr(3).strip_edges()))
				break
			if line.begins_with("#"):
				break  # past the frontmatter: a doc about quests, not a quest
	found.sort()
	return found


func _markdown_files(directory: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var child := directory.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_markdown_files(child))
		elif entry.ends_with(".md"):
			found.append(child)
		entry = dir.get_next()
	dir.list_dir_end()
	return found


## Every key in the generated title CSV.
func _csv_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var file := FileAccess.open(TITLES_CSV_PATH, FileAccess.READ)
	if file == null:
		fail("%s is missing" % TITLES_CSV_PATH)
		return keys
	file.get_csv_line()  # the header
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 1 and not row[0].is_empty():
			keys.append(row[0])
	return keys


## `python3`'s absolute path, or "" when it is not installed. Found by walking PATH
## rather than by trying to run it: a failed `OS.execute` prints an engine error,
## and `run_all.sh` fails a stage that prints one.
func _python3() -> String:
	for directory: String in OS.get_environment("PATH").split(":", false):
		var candidate := directory.path_join("python3")
		if FileAccess.file_exists(candidate):
			return candidate
	return ""
