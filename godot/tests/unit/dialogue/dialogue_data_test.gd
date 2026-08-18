extends TarrockTest

## MQ00's shipped conversations: the data, not the runner.
##
## This is where `docs/quests/main/MQ00-the-leap.md` and the game are held to each
## other. Every rule that can be checked against the script without a human reading
## it is checked here: every graph validates, every line has English behind it,
## every Fool line is inside the style guide's ceiling, nobody speaks who should not,
## and the two choice tables play exactly the threads the script writes.
##
## What the runner does in general is `dialogue_service_test.gd`; what the Cliff
## scene does with these graphs is `res://tests/cliff_test.gd`.

const CATALOG_PATH := "res://data/dialogue/catalog.tres"
const CSV_PATH := "res://localization/dialogue_mq00.csv"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## Pip. `docs/design/characters.md` §Pip: "Never speaks, never explained." There is
## no `Speakers` id for him; this is the id a graph would have to invent to try.
const PIP_SPEAKER := &"PIP"

var _catalog: DialogueCatalog = null
var _world_state: WorldStateService = null
var _dialogue: DialogueService = null


func before_each() -> void:
	TranslationServer.set_locale("en")
	_catalog = load(CATALOG_PATH) as DialogueCatalog
	var flags := load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	var thresholds := load(ACT_THRESHOLDS_PATH) as ActThresholds
	var ladder := load(RENOWN_LADDER_PATH) as RenownLadder
	_world_state = WorldStateService.new(flags, thresholds, ladder)
	_dialogue = DialogueService.new(_world_state, _catalog, 1)


# --- The catalog -------------------------------------------------------------


func test_the_catalog_loads() -> void:
	assert_not_null(_catalog, "%s must load" % CATALOG_PATH)


func test_every_shipped_graph_validates() -> void:
	if not assert_not_null(_catalog, "the catalog loaded"):
		return
	var problems := _catalog.validate(QuestEvents.ALL)
	assert_eq(problems.size(), 0, "the shipped dialogue must be valid: %s" % str(problems))


func test_the_catalog_holds_exactly_the_ids_the_constants_name() -> void:
	assert_eq(_catalog.ids(), DialogueIds.ALL, "DialogueIds and the catalog agree")


func test_every_graph_belongs_to_mq00_and_cites_the_script() -> void:
	for graph: DialogueGraph in _catalog.entries:
		assert_eq(graph.quest_id, QuestIds.MQ00, "%s belongs to MQ00" % graph.id)
		assert_true(
			graph.source_ref.begins_with("docs/quests/main/MQ00-the-leap.md"),
			"%s cites the quest doc it came from" % graph.id
		)


func test_mq00_owns_every_conversation_in_the_catalog() -> void:
	assert_eq(
		_catalog.graphs_for_quest(QuestIds.MQ00).size(),
		_catalog.entries.size(),
		"round 5 ships MQ00's dialogue and nothing else"
	)


# --- Localization ------------------------------------------------------------


func test_the_dialogue_translation_is_registered() -> void:
	var configured: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray()
	)
	assert_has(
		configured,
		"res://localization/dialogue_mq00.en.translation",
		"project.godot must load MQ00's dialogue table"
	)


func test_every_line_in_every_graph_has_english_behind_it() -> void:
	var missing := PackedStringArray()
	for graph: DialogueGraph in _catalog.entries:
		for key: String in graph.text_keys():
			if TranslationServer.translate(StringName(key)) == key:
				missing.append("%s/%s" % [graph.id, key])
	assert_eq(missing.size(), 0, "every key needs a line: %s" % str(missing))


func test_every_speaker_has_a_display_name() -> void:
	for speaker: StringName in Speakers.ALL:
		var key := Speakers.name_key(speaker)
		assert_ne(
			TranslationServer.translate(key), String(key), "%s needs a name" % speaker
		)


func test_no_line_in_the_table_is_orphaned() -> void:
	var used: Dictionary = {}
	for graph: DialogueGraph in _catalog.entries:
		for key: String in graph.text_keys():
			used[key] = true
	for speaker: StringName in Speakers.ALL:
		used[String(Speakers.name_key(speaker))] = true
	var orphans := PackedStringArray()
	for key: String in _csv_keys():
		if not used.has(key):
			orphans.append(key)
	assert_eq(
		orphans.size(), 0, "English nothing can show is dead weight: %s" % str(orphans)
	)


# --- Style guide -------------------------------------------------------------


func test_every_shipped_choice_table_obeys_the_style_guide() -> void:
	var problems := PackedStringArray()
	for graph: DialogueGraph in _catalog.entries:
		problems.append_array(DialogueStyle.violations(graph, _translate))
	assert_eq(problems.size(), 0, "narrative.md's lintable rules: %s" % str(problems))


func test_each_top_level_table_marks_one_earnest_option() -> void:
	for graph_id: StringName in [DialogueIds.MQ00_WOODEN_DOG, DialogueIds.MQ00_EDGE_QUESTIONS]:
		var graph := _catalog.find(graph_id)
		var table := graph.find_node(&"TABLE")
		if not assert_not_null(table, "%s has its table" % graph_id):
			continue
		var earnest := 0
		for option: DialogueOption in table.options:
			if option.is_earnest:
				earnest += 1
		assert_eq(earnest, 1, "%s marks exactly one *(earnest)* row" % graph_id)


func test_the_one_exempt_table_records_why() -> void:
	var exempt := PackedStringArray()
	for graph: DialogueGraph in _catalog.entries:
		for node: DialogueNode in graph.choice_nodes():
			if not node.earnest_exempt:
				continue
			exempt.append("%s/%s" % [graph.id, node.id])
			assert_false(node.notes.is_empty(), "%s/%s records a reason" % [graph.id, node.id])
	assert_eq(
		exempt.size(), 1, "one waiver in MQ00, and it is a known one: %s" % str(exempt)
	)


# --- Canon -------------------------------------------------------------------


func test_pip_never_speaks() -> void:
	for graph: DialogueGraph in _catalog.entries:
		assert_false(
			graph.speaker_ids().has(PIP_SPEAKER),
			"characters.md: Pip never speaks, and %s must not give him a line" % graph.id
		)


func test_every_speaker_is_one_the_constants_declare() -> void:
	for graph: DialogueGraph in _catalog.entries:
		for speaker: StringName in graph.speaker_ids():
			assert_true(
				Speakers.ALL.has(speaker), "%s gives a line to %s" % [graph.id, speaker]
			)


func test_mq00_raises_no_quest_event_from_dialogue() -> void:
	# Nothing in MQ00's script gates a beat on a conversation: every transition is
	# the Fool doing something. The wiring is proved on synthetic graphs instead
	# (`dialogue_service_test.gd`); inventing an event here would be inventing canon.
	for graph: DialogueGraph in _catalog.entries:
		assert_eq(graph.event_ids().size(), 0, "%s raises nothing" % graph.id)


func test_the_keepsake_line_chains_into_the_wooden_dog_table() -> void:
	var given := _catalog.find(DialogueIds.MQ00_KEEPSAKE_GIVEN)
	if not assert_not_null(given, "the keepsake beat exists"):
		return
	assert_eq(
		given.next_graph_id,
		DialogueIds.MQ00_WOODEN_DOG,
		"the script puts the table straight after the line"
	)


func test_only_that_one_beat_chains() -> void:
	var chained := PackedStringArray()
	for graph: DialogueGraph in _catalog.entries:
		if graph.next_graph_id != &"":
			chained.append(String(graph.id))
	assert_eq(chained.size(), 1, "one chain in MQ00: %s" % str(chained))


# --- Playing the shipped conversations ---------------------------------------


func test_the_wooden_dog_table_plays_every_question_and_picks_up_afterwards() -> void:
	assert_true(_dialogue.start(DialogueIds.MQ00_KEEPSAKE_GIVEN), "the beat starts")
	assert_eq(_dialogue.current().text_key, &"DLG_MQ00_KEEPSAKE_GIVEN_01", "with the line")
	_dialogue.advance()
	assert_eq(
		_dialogue.current_graph_id(),
		DialogueIds.MQ00_WOODEN_DOG,
		"which chains into the table"
	)
	var view := _dialogue.current()
	if not assert_not_null(view, "the table is on screen"):
		return
	assert_true(view.is_choice(), "and it is a table")
	assert_eq(view.options.size(), 3, "with the script's three questions")
	for index: int in 3:
		assert_true(_dialogue.choose(index), "question %d is asked" % index)
		assert_eq(
			_dialogue.current().text_key,
			StringName("DLG_MQ00_WOODEN_DOG_A%d" % (index + 1)),
			"and answered in order"
		)
		_dialogue.advance()
	assert_false(
		_dialogue.is_active(),
		"[All versions pick up here:] is narration only, so the table simply ends"
	)


func test_the_edge_questions_play_every_thread() -> void:
	assert_true(_dialogue.start(DialogueIds.MQ00_EDGE_QUESTIONS), "the table opens")
	assert_eq(_dialogue.current().options.size(), 4, "the script's four questions")

	# "Who are you?" - answer, then a one-row follow-up table.
	assert_true(_dialogue.choose(0), "who are you?")
	assert_eq(_dialogue.current().text_key, &"DLG_MQ00_EDGE_QUESTIONS_A1")
	_dialogue.advance()
	assert_true(_dialogue.current().is_choice(), "the follow-up table opens")
	assert_true(_dialogue.choose(0), "will you tell me eventually?")
	assert_eq(_dialogue.current().text_key, &"DLG_MQ00_EDGE_QUESTIONS_A1_F1")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"TABLE", "and the edge table comes back")

	# "What am I?" - the thread the brief calls out: two Fool lines, two Querent.
	_assert_what_am_i_thread()

	# "What's wrong with the world?" - answer, then a two-row follow-up table.
	assert_true(_dialogue.choose(2), "what's wrong with the world?")
	assert_eq(_dialogue.current().text_key, &"DLG_MQ00_EDGE_QUESTIONS_A3")
	_dialogue.advance()
	assert_true(_dialogue.current().is_choice(), "the stuck-how table opens")
	assert_eq(_dialogue.current().options.size(), 2, "with both follow-ups")
	assert_true(_dialogue.choose(0), "stuck how?")
	_dialogue.advance()
	assert_true(_dialogue.choose(1), "can I fix it?")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"TABLE", "then back to the edge table")

	# "Why me?" - the earnest one, and the last row.
	assert_true(_dialogue.choose(3), "why me?")
	assert_eq(_dialogue.current().text_key, &"DLG_MQ00_EDGE_QUESTIONS_A4")
	_dialogue.advance()
	assert_eq(
		_dialogue.current().text_key,
		&"DLG_MQ00_EDGE_QUESTIONS_01",
		"every row spent, so [All versions pick up here:] plays"
	)
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "and the conversation is over")


func test_the_edge_questions_can_be_left_after_one_answer() -> void:
	_dialogue.start(DialogueIds.MQ00_EDGE_QUESTIONS)
	_dialogue.choose(3)
	_dialogue.advance()
	assert_true(_dialogue.leave(), "all questions MAY be exhausted, not must")
	assert_eq(
		_dialogue.current().text_key,
		&"DLG_MQ00_EDGE_QUESTIONS_01",
		"and the same closing line plays"
	)


func test_the_wink_sits_in_the_what_am_i_thread() -> void:
	# narrative.md allows the Querent exactly one fourth-wall wink per quest; MQ00
	# spends it here. The rule is not lintable - this pins where the one is, so a
	# later edit that adds a second has to explain itself against this test.
	var graph := _catalog.find(DialogueIds.MQ00_EDGE_QUESTIONS)
	var node := graph.find_node(&"A2_03")
	if not assert_not_null(node, "the wink line is where it was authored"):
		return
	assert_true(node.notes.contains("wink"), "and is marked as the one wink")


func test_the_rest_again_pool_holds_the_scripts_three_random_lines() -> void:
	var graph := _catalog.find(DialogueIds.MQ00_WAYSTATION_REST_AGAIN)
	var pool := graph.find_node(&"P01")
	if not assert_not_null(pool, "the Random Lines are a pool"):
		return
	assert_eq(pool.text_keys.size(), 3, "the script writes three")
	_dialogue.start(DialogueIds.MQ00_WAYSTATION_REST_AGAIN)
	var picked := String(_dialogue.current().text_key)
	assert_true(pool.text_keys.has(picked), "and the pick came out of them: %s" % picked)


func test_every_graph_can_be_walked_to_its_end() -> void:
	for graph_id: StringName in DialogueIds.ALL:
		assert_true(_dialogue.start(graph_id), "%s starts" % graph_id)
		var steps := 0
		while _dialogue.is_active() and steps < 200:
			steps += 1
			var view := _dialogue.current()
			if view == null:
				break
			if view.is_choice():
				var picked := false
				for index: int in view.options.size():
					if not view.options[index].is_used:
						picked = _dialogue.choose(index)
						break
				if not picked:
					_dialogue.leave()
			else:
				_dialogue.advance()
		assert_false(_dialogue.is_active(), "%s reaches an end (%d steps)" % [graph_id, steps])


func test_every_table_row_is_answered_before_the_fool_is_played_back() -> void:
	# The script writes a choice table as the Fool's line and the Querent's response;
	# a thread that opens on a FOOL line has dropped that response somewhere between
	# the doc and the data - which is exactly what happened to "What am I?", whose
	# row answer went missing under the longer thread that follows it. A thread that
	# opens on a follow-up table is not the same thing: the table IS the answer.
	var problems := PackedStringArray()
	for graph: DialogueGraph in _catalog.entries:
		for table: DialogueNode in graph.choice_nodes():
			for option: DialogueOption in table.options:
				if option == null:
					continue
				if _first_voice_in_thread(graph, option.next) != Speakers.FOOL:
					continue
				problems.append("%s/%s: %s is played back before anyone answers it" % [
					graph.id, table.id, option.text_key
				])
	assert_eq(problems.size(), 0, "every row gets its response: %s" % str(problems))


# --- Helpers -----------------------------------------------------------------


## Who speaks first in the thread starting at `start`, or `&""` when nothing is said
## before the thread ends or opens a table of its own.
##
## `BRANCH` and `EVENT` are walked through the way the runner walks them; a `BRANCH`
## is followed down its `then` side, which is enough for a shipped graph that has
## none. The visited set is the same guard `DialogueService.MAX_WALK_STEPS` is: a
## broken graph must fail rather than hang the suite.
func _first_voice_in_thread(graph: DialogueGraph, start: StringName) -> StringName:
	var at := start
	var seen: Dictionary = {}
	while at != &"" and not seen.has(at):
		seen[at] = true
		var node := graph.find_node(at)
		if node == null:
			return &""
		match node.kind:
			DialogueNode.Kind.LINE, DialogueNode.Kind.POOL:
				return node.speaker
			DialogueNode.Kind.EVENT:
				at = node.next
			DialogueNode.Kind.BRANCH:
				at = node.then_node
			_:
				return &""
	return &""


## The lookup `DialogueStyle` lints against: the real translation table.
func _translate(key: StringName) -> String:
	return TranslationServer.translate(key)


## Walk the "What am I?" thread and assert its exact shape - the table row's own
## answer first, then the one thread in MQ00 the script writes out as alternating
## lines instead of a table row.
func _assert_what_am_i_thread() -> void:
	assert_true(_dialogue.choose(1), "what am I?")
	var expected: Array[StringName] = [
		&"DLG_MQ00_EDGE_QUESTIONS_A2",
		&"DLG_MQ00_EDGE_QUESTIONS_A2_01",
		&"DLG_MQ00_EDGE_QUESTIONS_A2_02",
		&"DLG_MQ00_EDGE_QUESTIONS_A2_03",
		&"DLG_MQ00_EDGE_QUESTIONS_A2_04",
	]
	var speakers: Array[StringName] = [
		Speakers.QUERENT, Speakers.FOOL, Speakers.QUERENT, Speakers.QUERENT, Speakers.FOOL
	]
	for index: int in expected.size():
		assert_eq(_dialogue.current().text_key, expected[index], "line %d of the thread" % index)
		assert_eq(_dialogue.current().speaker, speakers[index], "spoken by the right voice")
		_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"TABLE", "the thread returns to the table")


## Every key in the authored CSV, in file order. Keys never contain a comma, so the
## first field is everything before the first one - no CSV parser needed.
func _csv_keys() -> PackedStringArray:
	var found := PackedStringArray()
	var lines := FileAccess.get_file_as_string(CSV_PATH).split("\n", false)
	for index: int in range(1, lines.size()):
		var line := lines[index]
		var comma := line.find(",")
		if comma <= 0:
			continue
		found.append(line.substr(0, comma).strip_edges())
	return found
