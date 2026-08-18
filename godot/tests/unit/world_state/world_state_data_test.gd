extends TarrockTest

## The generated world-state data, against the docs it was generated from.
##
## `godot/tools/gen_definitions.py` lifts `docs/design/world.md` §World-state matrix
## and §Global states, and `docs/design/progression.md` §Renown, into the `.tres`
## files under `res://data/`. This suite is the drift guard technical.md asks for:
## the data loads, it says what the matrix says, the generated `WorldStateIds`
## constants agree with it, every flag a quest names exists, and re-running the
## generator would change nothing.

const CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const GENERATOR_PATH := "res://tools/gen_definitions.py"

## Where `docs/` sits relative to the project. The docs are outside `res://` on
## purpose - they are the source, not shipped content.
const DOCS_QUESTS_RELATIVE := "../docs/quests"

## Frontmatter keys that may name world-state flags (`docs/quests/README.md`).
const QUEST_FLAG_KEYS: Array[String] = ["requires", "fires", "branches"]

## What the docs say, restated here so a silent doc edit fails a test rather than
## quietly retuning the game: world.md §Global states, progression.md §Renown.
const DOCUMENTED_ACT_II_MIN := 7
const DOCUMENTED_ACT_III_MIN := 15
const DOCUMENTED_TIER_NAMES: Array[String] = [
	"Stranger",
	"Known",
	"Welcome",
	"Honored",
	"Fabled",
]

var _catalog: WorldStateCatalog = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as WorldStateCatalog


# --- The generated catalog ---------------------------------------------------


func test_the_catalog_loads_and_validates() -> void:
	if not assert_not_null(_catalog, "%s loads" % CATALOG_PATH):
		return
	assert_eq(_catalog.validate(), PackedStringArray(), "the generated matrix is self-consistent")


func test_the_catalog_holds_every_arcana_exactly_once() -> void:
	if not assert_not_null(_catalog):
		return
	var unbinding := _catalog.unbinding_ids()
	assert_eq(unbinding.size(), WorldStateDefinition.LAST_ARCANA, "21 Major Arcana, forever")
	var numbers: Array[int] = []
	for state_id: StringName in unbinding:
		var definition := _catalog.find(state_id)
		assert_false(numbers.has(definition.arcana_number), "card %d twice" % definition.arcana_number)
		numbers.append(definition.arcana_number)
		assert_eq(
			definition.fired_by,
			StringName("MQ%02d" % definition.arcana_number),
			"%s is fired by the quest of its own card" % state_id
		)
		assert_ne(definition.effect_summary, "", "%s carries the matrix's Effect text" % state_id)
	numbers.sort()
	for index: int in numbers.size():
		assert_eq(numbers[index], index + WorldStateDefinition.FIRST_ARCANA)


func test_the_branch_flags_are_the_two_choices_the_matrix_names() -> void:
	if not assert_not_null(_catalog):
		return
	var branches: Array[StringName] = []
	var groups: Array[StringName] = []
	for entry: WorldStateDefinition in _catalog.entries:
		if entry.is_unbinding():
			continue
		branches.append(entry.id)
		if not groups.has(entry.branch_group):
			groups.append(entry.branch_group)
	assert_eq(branches.size(), 4, "MQ01's troupe and MQ06's Divide: %s" % str(branches))
	assert_eq(groups.size(), 2, "two choices, two groups: %s" % str(groups))
	for group: StringName in groups:
		assert_eq(
			_catalog.branch_group_members(group).size(), 2, "%s offers two options" % group
		)
	assert_has(branches, &"WS_TROUPE_TRAVELING")
	assert_has(branches, &"WS_TROUPE_SETTLED")
	assert_has(branches, &"WS_DIVIDE_EASTMARRIED")
	assert_has(branches, &"WS_DIVIDE_WESTMARRIED")


func test_a_branch_flag_summarises_no_effect_of_its_own() -> void:
	# The Effect cell that names a branch flag describes what the *unbinding* does.
	# Copied onto the branch, it would read as canon this flag asserts - that
	# settling the troupe reopens the eastern roads, say, when the doc says the
	# unbinding does. `doc_ref` still points at the row, for a reviewer.
	if not assert_not_null(_catalog):
		return
	for entry: WorldStateDefinition in _catalog.entries:
		if entry.is_unbinding():
			continue
		assert_eq(entry.effect_summary, "", "%s claims an effect of its own" % entry.id)
		assert_has(entry.doc_ref, "row)", "%s cites the row that names it" % entry.id)


func test_every_generated_flag_cites_the_doc_it_came_from() -> void:
	if not assert_not_null(_catalog):
		return
	for entry: WorldStateDefinition in _catalog.entries:
		assert_has(entry.doc_ref, "world.md", "%s says where it came from" % entry.id)


# --- The generated constants -------------------------------------------------


func test_the_generated_constants_match_the_catalog() -> void:
	if not assert_not_null(_catalog):
		return
	var catalog_ids: Array[StringName] = []
	for entry: WorldStateDefinition in _catalog.entries:
		catalog_ids.append(entry.id)
	assert_eq(WorldStateIds.ALL, catalog_ids, "WorldStateIds and the data are one generation")
	assert_eq(WorldStateIds.UNBINDING, _catalog.unbinding_ids())
	assert_eq(
		WorldStateIds.UNBINDING.size() + WorldStateIds.BRANCH.size(), WorldStateIds.ALL.size()
	)
	for state_id: StringName in WorldStateIds.ALL:
		assert_true(_catalog.has(state_id), "%s is a flag the catalog knows" % state_id)


func test_the_confession_flag_is_the_one_death_fires() -> void:
	# `is_confessed()` reads this constant; if the matrix ever renamed the row, the
	# service would silently answer "never confessed".
	if not assert_not_null(_catalog):
		return
	var death := _catalog.find(WorldStateIds.WS_DEATH_UNBOUND)
	if not assert_not_null(death, "the matrix still has a Death row"):
		return
	assert_eq(death.fired_by, &"MQ13")
	assert_eq(death.arcana_number, 13)


# --- The generated thresholds and ladder -------------------------------------


func test_the_act_thresholds_are_the_documented_ones() -> void:
	var thresholds: ActThresholds = load(ACT_THRESHOLDS_PATH) as ActThresholds
	if not assert_not_null(thresholds, "%s loads" % ACT_THRESHOLDS_PATH):
		return
	assert_eq(thresholds.validate(), PackedStringArray())
	assert_eq(thresholds.act_ii_min, DOCUMENTED_ACT_II_MIN, "world.md: Act II is 7-14 unbound")
	assert_eq(thresholds.act_iii_min, DOCUMENTED_ACT_III_MIN, "world.md: Act III is 15-21 unbound")


func test_the_renown_ladder_is_the_documented_one() -> void:
	var ladder: RenownLadder = load(RENOWN_LADDER_PATH) as RenownLadder
	if not assert_not_null(ladder, "%s loads" % RENOWN_LADDER_PATH):
		return
	assert_eq(ladder.validate(), PackedStringArray())
	assert_eq(ladder.tier_names.size(), RenownLadder.TIER_COUNT)
	for index: int in DOCUMENTED_TIER_NAMES.size():
		assert_eq(ladder.tier_names[index], DOCUMENTED_TIER_NAMES[index])
	assert_ne(ladder.notes, "", "the placeholder thresholds say so in the data")


func test_every_renown_tier_the_ladder_names_has_a_translation() -> void:
	# `renown_tier_name_key()` hands the UI a key and never a word (standing
	# decision 6). A key with no row in the string table shows on screen as
	# RENOWN_TIER_HONORED, so the table is part of the ladder's contract.
	var ladder: RenownLadder = load(RENOWN_LADDER_PATH) as RenownLadder
	if not assert_not_null(ladder, "%s loads" % RENOWN_LADDER_PATH):
		return
	TranslationServer.set_locale("en")
	for tier: int in range(RenownLadder.FIRST_TIER, RenownLadder.TIER_COUNT + RenownLadder.FIRST_TIER):
		var key := ladder.tier_name_key(tier)
		assert_ne(key, &"", "tier %d names a key" % tier)
		assert_ne(
			TranslationServer.translate(key),
			String(key),
			"%s has no row in localization/strings.csv" % key
		)


# --- Quests reference only flags that exist ----------------------------------


func test_every_flag_a_quest_names_exists_in_the_matrix() -> void:
	# docs/quests/README.md: requires/fires may only use flags that exist in the
	# world-state matrix. Proven against the real quest docs, not a fixture.
	if not assert_not_null(_catalog):
		return
	var quests_dir := _docs_path(DOCS_QUESTS_RELATIVE)
	if not DirAccess.dir_exists_absolute(quests_dir):
		print("SKIP: %s is not present, so quest frontmatter was not checked" % quests_dir)
		return
	var files := _markdown_files(quests_dir)
	assert_true(files.size() > 0, "there are quest docs to check in %s" % quests_dir)
	var checked := 0
	for path: String in files:
		for state_id: StringName in _frontmatter_flags(path):
			checked += 1
			assert_true(
				_catalog.has(state_id),
				"%s names %s, which no matrix row defines" % [path.get_file(), state_id]
			)
	assert_true(checked > 0, "quest frontmatter names world-state flags")


# --- Drift -------------------------------------------------------------------


func test_regenerating_from_the_docs_would_change_nothing() -> void:
	# The whole point of generating: a canon edit that never reached the data is a
	# failing test, not a bug someone finds in Act III.
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


func test_the_composition_root_owns_a_live_world_state_service() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var world_state: WorldStateService = services.get("world_state")
	if not assert_not_null(world_state, "Services built its WorldStateService in _ready"):
		return
	assert_false(
		world_state.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "a fresh boot has unbound nothing"
	)
	assert_eq(world_state.act(), WorldStateService.Act.ACT_I)
	assert_eq(world_state.renown_tier_name_key(Suit.Id.CUPS), &"RENOWN_TIER_STRANGER")


# --- Helpers -----------------------------------------------------------------


## An absolute path to something beside the Godot project, e.g. `docs/`.
func _docs_path(relative: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join(relative).simplify_path()


## `python3`'s absolute path, or "" when it is not installed. Found by walking PATH
## rather than by trying to run it: a failed `OS.execute` prints an engine error,
## and `run_all.sh` fails a stage that prints one.
func _python3() -> String:
	for directory: String in OS.get_environment("PATH").split(":", false):
		var candidate := directory.path_join("python3")
		if FileAccess.file_exists(candidate):
			return candidate
	return ""


## Every `.md` under `dir_path`, recursively.
func _markdown_files(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child := dir_path.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_markdown_files(child))
		elif entry.ends_with(".md"):
			found.append(child)
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found


## Every `WS_*` id named by this quest doc's `requires`/`fires`/`branches`.
func _frontmatter_flags(path: String) -> Array[StringName]:
	var flags: Array[StringName] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return flags
	var lines := file.get_as_text().split("\n")
	file.close()
	if lines.size() == 0 or lines[0].strip_edges() != "---":
		return flags  # not every doc in docs/quests/ is a quest (README, TEMPLATE)
	var pattern := RegEx.create_from_string("WS_[A-Z0-9_]+")
	var collecting := false
	for index: int in range(1, lines.size()):
		var line: String = lines[index]
		if line.strip_edges() == "---":
			break
		var code := line.split("#")[0]
		if code.strip_edges().is_empty():
			continue
		var continuation := code.begins_with(" ") or code.begins_with("\t")
		if not continuation:
			collecting = QUEST_FLAG_KEYS.has(code.split(":")[0].strip_edges())
		if not collecting:
			continue
		for found: RegExMatch in pattern.search_all(code):
			var state_id := StringName(found.get_string())
			if not flags.has(state_id):
				flags.append(state_id)
	return flags
