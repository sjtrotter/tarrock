extends TarrockTest

## The dialogue definitions' own rules, one provoked bad case at a time.
##
## Everything here is built in the test rather than loaded, so each rule can be
## broken on its own without touching the shipped MQ00 graphs (those are
## `dialogue_data_test.gd`'s subject). The good-case graph is rebuilt for every
## method, so one method's sabotage cannot leak into the next.


func before_each() -> void:
	pass


# --- Nodes -------------------------------------------------------------------


func test_a_line_needs_a_speaker_a_key_and_somewhere_to_go() -> void:
	var node := DialogueNode.new()
	node.kind = DialogueNode.Kind.LINE
	var problems := node.validate()
	assert_eq(problems.size(), 4, "an empty line reports its id, speaker, key and exit")
	node.id = &"L01"
	node.speaker = Speakers.QUERENT
	node.text_key = &"DLG_TEST_01"
	node.next = &"END"
	assert_eq(node.validate().size(), 0, "a complete line validates")


func test_a_line_with_no_next_is_a_dead_end() -> void:
	var node := _line(&"L01", &"DLG_TEST_01", &"")
	assert_eq(node.validate().size(), 1, "a line that leads nowhere is one problem")


func test_a_choice_must_offer_something() -> void:
	var node := DialogueNode.new()
	node.id = &"TABLE"
	node.kind = DialogueNode.Kind.CHOICE
	node.after_all = &"END"
	assert_eq(node.validate().size(), 1, "a table with no rows is a problem")


func test_a_choice_of_two_needs_an_earnest_option_or_an_exemption() -> void:
	var node := _choice(&"TABLE", [_option(&"DLG_A", &"A"), _option(&"DLG_B", &"B")], &"END")
	assert_eq(node.validate().size(), 1, "two options and no earnest one is a problem")
	assert_false(node.has_earnest_option(), "and the query agrees")
	node.earnest_exempt = true
	assert_eq(node.validate().size(), 1, "an exemption without a reason is still a problem")
	node.notes = "the earnest option of this beat lives on the parent table"
	assert_eq(node.validate().size(), 0, "an exemption with a recorded reason is allowed")


func test_a_choice_of_one_is_not_asked_for_an_earnest_option() -> void:
	var node := _choice(&"TABLE", [_option(&"DLG_A", &"A")], &"END")
	assert_true(node.has_earnest_option(), "a single row has nothing to be earnest against")
	assert_eq(node.validate().size(), 0, "and validates")


func test_an_earnest_option_satisfies_the_rule() -> void:
	var earnest := _option(&"DLG_B", &"B")
	earnest.is_earnest = true
	var node := _choice(&"TABLE", [_option(&"DLG_A", &"A"), earnest], &"END")
	assert_eq(node.validate().size(), 0, "a table with an earnest option validates")


func test_an_exhaustible_choice_needs_somewhere_to_pick_up_afterwards() -> void:
	var node := _choice(&"TABLE", [_option(&"DLG_A", &"A")], &"")
	assert_eq(node.validate().size(), 1, "no after_all is a problem for an exhaustible table")
	node.mode = DialogueNode.ChoiceMode.FIRST_PICK_COMMITS
	assert_eq(node.validate().size(), 0, "a committing table never returns, so it needs none")


func test_an_option_needs_a_key_and_a_thread() -> void:
	var option := DialogueOption.new()
	assert_eq(option.validate().size(), 2, "an empty option reports its key and its thread")


func test_a_branch_needs_both_ways_out() -> void:
	var node := DialogueNode.new()
	node.id = &"B01"
	node.kind = DialogueNode.Kind.BRANCH
	assert_eq(node.validate().size(), 2, "a branch with neither exit is two problems")
	node.then_node = &"A"
	node.else_node = &"B"
	assert_eq(node.validate().size(), 0, "with both, it validates")


func test_a_branch_cannot_need_a_flag_both_fired_and_unfired() -> void:
	var node := _branch(&"B01", &"A", &"B")
	node.requires_fired = [WorldStateIds.WS_SUN_UNBOUND]
	node.requires_not_fired = [WorldStateIds.WS_SUN_UNBOUND]
	assert_eq(node.validate().size(), 1, "a contradiction is caught in the definition")


func test_a_branch_rejects_a_confessed_value_that_is_not_a_confessed_value() -> void:
	var node := _branch(&"B01", &"A", &"B")
	node.requires_confessed = 7
	assert_eq(node.validate().size(), 1, "only -1, 0 and 1 mean anything")


func test_an_event_node_needs_an_event_and_an_exit() -> void:
	var node := DialogueNode.new()
	node.id = &"E01"
	node.kind = DialogueNode.Kind.EVENT
	assert_eq(node.validate().size(), 2, "an event node with neither is two problems")


func test_a_pool_needs_a_speaker_lines_and_an_exit() -> void:
	var node := DialogueNode.new()
	node.id = &"P01"
	node.kind = DialogueNode.Kind.POOL
	assert_eq(node.validate().size(), 3, "an empty pool reports speaker, lines and exit")
	node.speaker = Speakers.QUERENT
	node.text_keys = PackedStringArray(["DLG_TEST_01", ""])
	node.next = &"END"
	assert_eq(node.validate().size(), 1, "an empty key inside a pool is still a problem")


func test_an_end_node_needs_nothing_but_an_id() -> void:
	var node := DialogueNode.new()
	node.id = &"END"
	node.kind = DialogueNode.Kind.END
	assert_eq(node.validate().size(), 0, "an END is just a stop")


# --- Graphs ------------------------------------------------------------------


func test_a_good_graph_validates() -> void:
	assert_eq(_good_graph().validate().size(), 0, "the fixture graph is valid")


func test_a_graph_must_name_a_quest_and_cite_its_script() -> void:
	var graph := _good_graph()
	graph.quest_id = &""
	graph.source_ref = ""
	assert_eq(graph.validate().size(), 2, "a graph belongs to a quest and cites a section")


func test_a_graph_must_start_somewhere_real() -> void:
	var graph := _good_graph()
	graph.start_node = &"NOWHERE"
	assert_eq(graph.validate().size(), 1, "a start node that is not a node is a problem")
	graph.start_node = &""
	assert_eq(graph.validate().size(), 1, "and so is no start node at all")


func test_a_graph_rejects_two_nodes_with_one_id() -> void:
	var graph := _good_graph()
	graph.nodes.append(_line(&"L01", &"DLG_TEST_01", &"END"))
	assert_eq(graph.validate().size(), 1, "one id, one node")


func test_every_exit_must_resolve() -> void:
	var graph := _good_graph()
	graph.nodes[0].next = &"NOWHERE"
	assert_eq(graph.validate().size(), 1, "a line into thin air is caught")


func test_every_option_thread_must_resolve() -> void:
	var graph := _choice_graph()
	graph.nodes[0].options[0].next = &"NOWHERE"
	assert_eq(graph.validate().size(), 1, "an option's thread is an exit like any other")


func test_a_branch_s_two_ways_out_must_resolve() -> void:
	var graph := _good_graph()
	var branch := _branch(&"B01", &"L01", &"NOWHERE")
	graph.nodes.append(branch)
	assert_eq(graph.validate().size(), 1, "the else side is checked too")


func test_a_graph_reports_the_events_it_raises() -> void:
	var graph := _good_graph()
	var event := DialogueNode.new()
	event.id = &"E01"
	event.kind = DialogueNode.Kind.EVENT
	event.event = &"MQ00_NOT_AN_EVENT"
	event.next = &"END"
	graph.nodes.append(event)
	assert_eq(graph.validate().size(), 0, "the shape is fine; only the id is wrong")
	var unknown := graph.unknown_events(QuestEvents.ALL)
	assert_eq(unknown.size(), 1, "an event QuestEvents does not define is caught")
	event.event = QuestEvents.MQ00_RESTED
	assert_eq(graph.unknown_events(QuestEvents.ALL).size(), 0, "a real event passes")


func test_an_option_s_event_is_checked_too() -> void:
	var graph := _choice_graph()
	graph.nodes[0].options[0].raises_event = &"MQ00_NOT_AN_EVENT"
	assert_eq(graph.unknown_events(QuestEvents.ALL).size(), 1, "options raise events too")


func test_a_graph_lists_every_key_it_can_show() -> void:
	var graph := _choice_graph()
	var keys := graph.text_keys()
	assert_true(keys.has("DLG_TEST_Q1"), "a choice option's key is listed")
	assert_true(keys.has("DLG_TEST_A1"), "an answer's key is listed")


# --- Catalogs ----------------------------------------------------------------


func test_a_catalog_finds_by_id_and_refuses_what_it_does_not_hold() -> void:
	var catalog := DialogueCatalog.new()
	catalog.entries = [_good_graph()]
	assert_not_null(catalog.find(&"TEST_GRAPH"), "the graph it holds resolves")
	assert_null(catalog.find(&"NOT_A_GRAPH"), "and one it does not, does not")
	assert_false(catalog.has(&"NOT_A_GRAPH"), "has() agrees")


func test_a_catalog_rejects_the_same_id_twice() -> void:
	var catalog := DialogueCatalog.new()
	catalog.entries = [_good_graph(), _good_graph()]
	assert_eq(catalog.validate(QuestEvents.ALL).size(), 1, "one id, one graph")


func test_a_catalog_rejects_an_empty_slot() -> void:
	var catalog := DialogueCatalog.new()
	catalog.entries = [null]
	assert_eq(catalog.validate(QuestEvents.ALL).size(), 1, "an empty entry is a problem")


func test_a_chain_must_lead_to_a_graph_the_catalog_holds() -> void:
	var graph := _good_graph()
	graph.next_graph_id = &"NOT_A_GRAPH"
	var catalog := DialogueCatalog.new()
	catalog.entries = [graph]
	assert_eq(catalog.validate(QuestEvents.ALL).size(), 1, "a chain into nothing is caught")


func test_a_graph_cannot_chain_into_itself() -> void:
	var graph := _good_graph()
	graph.next_graph_id = graph.id
	var catalog := DialogueCatalog.new()
	catalog.entries = [graph]
	assert_eq(catalog.validate(QuestEvents.ALL).size(), 1, "a self-chain would never end")


func test_a_ring_of_chains_is_caught_however_long_it_is() -> void:
	# `DialogueService._finish()` starts `next_graph_id` the instant a graph ends, so
	# A -> B -> A is an endless conversation exactly as A -> A is - and neither graph
	# looks wrong on its own, which is why the whole chain has to be followed.
	var first := _good_graph()
	var second := _good_graph()
	second.id = &"TEST_GRAPH_B"
	first.next_graph_id = second.id
	second.next_graph_id = first.id
	var catalog := DialogueCatalog.new()
	catalog.entries = [first, second]
	var problems := catalog.validate(QuestEvents.ALL)
	assert_eq(problems.size(), 1, "one ring is one problem, not one per graph: %s" % problems)
	assert_true(problems[0].contains("TEST_GRAPH_B"), "and it names the ring: %s" % problems)


func test_a_longer_ring_is_caught_too() -> void:
	var first := _good_graph()
	var second := _good_graph()
	second.id = &"TEST_GRAPH_B"
	var third := _good_graph()
	third.id = &"TEST_GRAPH_C"
	first.next_graph_id = second.id
	second.next_graph_id = third.id
	third.next_graph_id = first.id
	var catalog := DialogueCatalog.new()
	catalog.entries = [first, second, third]
	assert_eq(catalog.validate(QuestEvents.ALL).size(), 1, "three graphs, one ring")


func test_a_chain_that_ends_is_not_a_ring() -> void:
	var first := _good_graph()
	var second := _good_graph()
	second.id = &"TEST_GRAPH_B"
	var third := _good_graph()
	third.id = &"TEST_GRAPH_C"
	first.next_graph_id = second.id
	second.next_graph_id = third.id
	var catalog := DialogueCatalog.new()
	catalog.entries = [first, second, third]
	assert_eq(catalog.validate(QuestEvents.ALL).size(), 0, "a chain is allowed to be long")


func test_a_catalog_groups_graphs_by_quest() -> void:
	var catalog := DialogueCatalog.new()
	catalog.entries = [_good_graph()]
	assert_eq(catalog.graphs_for_quest(QuestIds.MQ00).size(), 1, "MQ00 owns the fixture")
	assert_eq(catalog.graphs_for_quest(QuestIds.MQ13).size(), 0, "and MQ13 owns nothing")


# --- Fixtures ----------------------------------------------------------------


func _line(node_id: StringName, text_key: StringName, next: StringName) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.LINE
	node.speaker = Speakers.QUERENT
	node.text_key = text_key
	node.next = next
	return node


func _end(node_id: StringName = &"END") -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.END
	return node


func _option(text_key: StringName, next: StringName) -> DialogueOption:
	var option := DialogueOption.new()
	option.text_key = text_key
	option.next = next
	return option


func _choice(
	node_id: StringName, options: Array, after_all: StringName
) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.CHOICE
	for entry: DialogueOption in options:
		node.options.append(entry)
	node.after_all = after_all
	return node


func _branch(node_id: StringName, then_node: StringName, else_node: StringName) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.BRANCH
	node.then_node = then_node
	node.else_node = else_node
	return node


## A minimal valid graph: one line and a stop.
func _good_graph() -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.id = &"TEST_GRAPH"
	graph.quest_id = QuestIds.MQ00
	graph.source_ref = "tests/unit/dialogue/dialogue_definitions_test.gd"
	graph.start_node = &"L01"
	graph.nodes = [_line(&"L01", &"DLG_TEST_01", &"END"), _end()]
	return graph


## A minimal valid graph with an exhaustible table in it.
func _choice_graph() -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.id = &"TEST_CHOICE_GRAPH"
	graph.quest_id = QuestIds.MQ00
	graph.source_ref = "tests/unit/dialogue/dialogue_definitions_test.gd"
	graph.start_node = &"TABLE"
	graph.nodes = [
		_choice(&"TABLE", [_option(&"DLG_TEST_Q1", &"A1")], &"END"),
		_line(&"A1", &"DLG_TEST_A1", &"END"),
		_end(),
	]
	return graph
