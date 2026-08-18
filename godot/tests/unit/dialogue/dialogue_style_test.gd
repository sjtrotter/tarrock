extends TarrockTest

## The style-guide lint itself, proved on graphs written to break it.
##
## `docs/design/narrative.md` §Dialogue style guide gives the Fool's selectable
## lines a hard ceiling ("≤ 12 words ... it is the character's soul") and asks every
## choice table for an earnest option. `DialogueStyle` is those two rules as code;
## this is the test that the code really does fail them, so the green run over the
## shipped MQ00 graphs (`dialogue_data_test.gd`) means something.
##
## The English here is supplied by a dictionary rather than by the translation
## table, precisely so a deliberately awful line never has to be written into the
## shipped CSV to prove the lint works.

## Thirteen words: one past the ceiling, and nothing else wrong with it.
const TOO_LONG := "one two three four five six seven eight nine ten eleven twelve thirteen"

## Twelve words: exactly the ceiling, which is allowed.
const EXACTLY_LONG_ENOUGH := "one two three four five six seven eight nine ten eleven twelve"


func test_the_ceiling_is_the_one_the_style_guide_names() -> void:
	assert_eq(DialogueStyle.MAX_FOOL_WORDS, 12, "narrative.md says twelve")


func test_words_are_counted_the_way_a_reader_counts_them() -> void:
	assert_eq(DialogueStyle.word_count("Who carved this?"), 3)
	assert_eq(DialogueStyle.word_count("Why me?"), 2)
	assert_eq(DialogueStyle.word_count(""), 0, "an empty line is no words")
	assert_eq(DialogueStyle.word_count(TOO_LONG), 13)


func test_a_tab_or_a_newline_separates_two_words_like_a_space_does() -> void:
	# A CSV line can hold a tab or a wrapped newline as readily as a space. Counting
	# only spaces would read "Who\tcarved this?" as two words and let a line over the
	# ceiling through the lint on a typography accident.
	assert_eq(DialogueStyle.word_count("Who\tcarved this?"), 3, "a tab separates words")
	assert_eq(DialogueStyle.word_count("Who carved\nthis?"), 3, "so does a newline")
	assert_eq(DialogueStyle.word_count("Who  carved   this?"), 3, "so does a run of spaces")
	assert_eq(DialogueStyle.word_count("  Who carved this?\n"), 3, "and the edges are trimmed")
	assert_eq(DialogueStyle.word_count("\t\n  "), 0, "whitespace alone is no words")


func test_a_line_over_the_ceiling_fails_the_lint() -> void:
	var graph := _graph_with_option(&"DLG_LINT_LONG", false)
	var problems := DialogueStyle.violations(graph, _lookup)
	assert_eq(problems.size(), 1, "the long line is reported")
	assert_true(problems[0].contains("13 words"), "and the report says how long: %s" % problems)


func test_a_line_exactly_at_the_ceiling_passes() -> void:
	var graph := _graph_with_option(&"DLG_LINT_TWELVE", false)
	assert_eq(DialogueStyle.violations(graph, _lookup).size(), 0, "twelve is allowed")


func test_a_table_of_two_with_no_earnest_option_fails_the_lint() -> void:
	var graph := _graph_with_two_options(false, false)
	var problems := DialogueStyle.violations(graph, _lookup)
	assert_eq(problems.size(), 1, "a table that offers no honest answer is reported")
	assert_true(problems[0].contains("earnest"), "and says so: %s" % problems)


func test_an_earnest_option_satisfies_the_lint() -> void:
	var graph := _graph_with_two_options(false, true)
	assert_eq(DialogueStyle.violations(graph, _lookup).size(), 0, "one earnest row is enough")


func test_a_recorded_exemption_satisfies_the_lint() -> void:
	var graph := _graph_with_two_options(false, false)
	graph.nodes[0].earnest_exempt = true
	graph.nodes[0].notes = "the earnest option of this beat lives on the parent table"
	assert_eq(
		DialogueStyle.violations(graph, _lookup).size(), 0,
		"a waiver with a recorded reason is a review decision, not a violation"
	)


func test_a_key_with_no_english_behind_it_is_not_reported_here() -> void:
	var graph := _graph_with_option(&"DLG_LINT_MISSING", false)
	assert_eq(
		DialogueStyle.violations(graph, _lookup).size(), 0,
		"a missing line belongs to the localization test, and is not reported twice"
	)


func test_a_graph_with_no_choice_table_has_nothing_to_lint() -> void:
	var graph := DialogueGraph.new()
	graph.id = &"TEST_LINT_EMPTY"
	assert_eq(DialogueStyle.violations(graph, _lookup).size(), 0, "no tables, no findings")
	assert_eq(DialogueStyle.violations(null, _lookup).size(), 0, "and no graph is no findings")


# --- Fixtures ----------------------------------------------------------------


## The English the fixtures are linted against. `DLG_LINT_MISSING` is deliberately
## absent, so the lookup returns the key - Godot's own behaviour for a missing key.
func _lookup(key: StringName) -> String:
	var table := {
		&"DLG_LINT_LONG": TOO_LONG,
		&"DLG_LINT_TWELVE": EXACTLY_LONG_ENOUGH,
		&"DLG_LINT_SHORT": "Who carved this?",
	}
	return table.get(key, String(key))


func _option(text_key: StringName, earnest: bool) -> DialogueOption:
	var option := DialogueOption.new()
	option.text_key = text_key
	option.next = &"END"
	option.is_earnest = earnest
	return option


func _table(options: Array[DialogueOption]) -> DialogueGraph:
	var node := DialogueNode.new()
	node.id = &"TABLE"
	node.kind = DialogueNode.Kind.CHOICE
	node.options = options
	node.after_all = &"END"
	var stop := DialogueNode.new()
	stop.id = &"END"
	stop.kind = DialogueNode.Kind.END
	var graph := DialogueGraph.new()
	graph.id = &"TEST_LINT_GRAPH"
	graph.quest_id = QuestIds.MQ00
	graph.source_ref = "tests/unit/dialogue/dialogue_style_test.gd"
	graph.start_node = &"TABLE"
	graph.nodes.append(node)
	graph.nodes.append(stop)
	return graph


func _graph_with_option(text_key: StringName, earnest: bool) -> DialogueGraph:
	var options: Array[DialogueOption] = [_option(text_key, earnest)]
	return _table(options)


func _graph_with_two_options(first_earnest: bool, second_earnest: bool) -> DialogueGraph:
	var options: Array[DialogueOption] = [
		_option(&"DLG_LINT_SHORT", first_earnest),
		_option(&"DLG_LINT_TWELVE", second_earnest),
	]
	return _table(options)
