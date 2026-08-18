extends TarrockTest

## The conversation runner, over synthetic graphs.
##
## The graphs are built in the test rather than loaded, so each rule of the runner
## can be exercised on its own: a branch on a flag, a branch on CONFESSED, a branch
## on the act, an exhaustible table, a committing table, a pool. What the shipped
## MQ00 conversations do is `dialogue_data_test.gd`; what the Cliff scene does with
## them is `res://tests/cliff_test.gd`.
##
## The **flags** are real ones from `docs/design/world.md` §World-state matrix,
## because `WorldStateService` refuses to fire anything the generated catalog does
## not list and a made-up flag would prove nothing.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## A seed, so a `POOL` picks the same line every run.
const SEED := 20260817

const GRAPH_LINES := &"TEST_LINES"
const GRAPH_TABLE := &"TEST_TABLE"
const GRAPH_COMMITS := &"TEST_COMMITS"
const GRAPH_BRANCH := &"TEST_BRANCH"
const GRAPH_EVENT := &"TEST_EVENT"
const GRAPH_POOL := &"TEST_POOL"
const GRAPH_NESTED := &"TEST_NESTED"
const GRAPH_CHAIN_FROM := &"TEST_CHAIN_FROM"
const GRAPH_COMMITS_AGAIN := &"TEST_COMMITS_AGAIN"
const GRAPH_LOOP := &"TEST_LOOP"

var _flags: WorldStateCatalog = null
var _world_state: WorldStateService = null
var _catalog: DialogueCatalog = null
var _dialogue: DialogueService = null


func before_each() -> void:
	_flags = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	var thresholds := load(ACT_THRESHOLDS_PATH) as ActThresholds
	var ladder := load(RENOWN_LADDER_PATH) as RenownLadder
	_world_state = WorldStateService.new(_flags, thresholds, ladder)
	_catalog = _build_catalog()
	_dialogue = DialogueService.new(_world_state, _catalog, SEED)


# --- Starting and stopping ---------------------------------------------------


func test_the_catalog_that_backs_these_tests_is_valid() -> void:
	assert_eq(
		_catalog.validate(QuestEvents.ALL).size(), 0, "the fixtures are legal graphs"
	)


func test_starting_presents_the_first_line() -> void:
	watch_signal(_dialogue, &"dialogue_started")
	watch_signal(_dialogue, &"node_presented")
	assert_true(_dialogue.start(GRAPH_LINES), "the conversation starts")
	assert_true(_dialogue.is_active(), "and is active")
	assert_eq(_dialogue.current_graph_id(), GRAPH_LINES, "and knows which one it is")
	assert_signal_emitted(_dialogue, &"dialogue_started", 1)
	assert_signal_emitted(_dialogue, &"node_presented", 1)
	var view := _dialogue.current()
	if not assert_not_null(view, "something is on screen"):
		return
	assert_eq(view.node_id, &"L01", "the graph's start node")
	assert_eq(view.text_key, &"DLG_TEST_LINES_01", "with its key, never a sentence")
	assert_eq(view.speaker, Speakers.QUERENT, "and its speaker")
	assert_eq(view.speaker_name_key(), &"SPEAKER_QUERENT", "whose name is a key too")


func test_a_line_waits_and_advance_moves() -> void:
	_dialogue.start(GRAPH_LINES)
	assert_eq(_dialogue.current().node_id, &"L01", "a line waits to be advanced past")
	assert_eq(_dialogue.current().node_id, &"L01", "and waits again")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"L02", "advance moves one line on")


func test_a_conversation_ends_when_it_runs_out() -> void:
	watch_signal(_dialogue, &"dialogue_ended")
	_dialogue.start(GRAPH_LINES)
	_dialogue.advance()
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "the last line's advance ends it")
	assert_null(_dialogue.current(), "and nothing is on screen")
	assert_signal_emitted(_dialogue, &"dialogue_ended", 1)
	assert_eq(signal_arguments(_dialogue, &"dialogue_ended", 0)[0], GRAPH_LINES)


func test_starting_while_active_is_refused() -> void:
	_dialogue.start(GRAPH_LINES)
	assert_false(_dialogue.start(GRAPH_TABLE), "one conversation at a time")
	assert_eq(_dialogue.current_graph_id(), GRAPH_LINES, "and the first one is untouched")


func test_starting_an_unknown_graph_is_refused() -> void:
	var started: bool = _quietly(func() -> bool: return _dialogue.start(&"NOT_A_GRAPH"))
	assert_false(started, "the catalog is the whole vocabulary")
	assert_false(_dialogue.is_active(), "and nothing began")


func test_end_stops_the_conversation_where_it_is() -> void:
	watch_signal(_dialogue, &"dialogue_ended")
	_dialogue.start(GRAPH_LINES)
	_dialogue.end()
	assert_false(_dialogue.is_active(), "ended")
	assert_signal_emitted(_dialogue, &"dialogue_ended", 1)
	_dialogue.end()
	assert_signal_emitted(_dialogue, &"dialogue_ended", 1, "ending twice says it once")


func test_advance_on_nothing_is_harmless() -> void:
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "advancing an idle service does nothing")


# --- Branching on world state ------------------------------------------------


func test_a_branch_takes_the_else_side_when_its_flag_has_not_fired() -> void:
	_dialogue.start(GRAPH_BRANCH)
	assert_eq(_dialogue.current().node_id, &"UNBOUND", "a world nobody has changed")


func test_a_branch_takes_the_then_side_once_its_flag_has_fired() -> void:
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	_dialogue.start(GRAPH_BRANCH)
	assert_eq(_dialogue.current().node_id, &"BOUND", "the branch read the world state")


func test_a_branch_is_never_presented() -> void:
	watch_signal(_dialogue, &"node_presented")
	_dialogue.start(GRAPH_BRANCH)
	assert_signal_emitted(
		_dialogue, &"node_presented", 1, "the branch resolved without a frame of dialogue"
	)


func test_a_branch_reads_confessed() -> void:
	var node := DialogueNode.new()
	node.id = &"B"
	node.kind = DialogueNode.Kind.BRANCH
	node.requires_confessed = DialogueNode.CONFESSED_YES
	assert_false(node.conditions_met(_world_state), "CONFESSED is not the default state")
	_world_state.fire(WorldStateIds.WS_DEATH_UNBOUND, QuestIds.MQ13)
	assert_true(node.conditions_met(_world_state), "Death unbound is CONFESSED")
	node.requires_confessed = DialogueNode.CONFESSED_NO
	assert_false(node.conditions_met(_world_state), "and the other way round")


func test_a_branch_reads_the_act() -> void:
	var node := DialogueNode.new()
	node.id = &"B"
	node.kind = DialogueNode.Kind.BRANCH
	node.min_act = WorldStateService.Act.ACT_II
	assert_false(node.conditions_met(_world_state), "the world opens in Act I")
	_unbind(7)
	assert_eq(_world_state.act(), WorldStateService.Act.ACT_II, "seven unbindings is Act II")
	assert_true(node.conditions_met(_world_state), "so the branch opens")


func test_a_branch_excludes_a_flag_it_must_not_see() -> void:
	var node := DialogueNode.new()
	node.id = &"B"
	node.kind = DialogueNode.Kind.BRANCH
	node.requires_not_fired = [WorldStateIds.WS_EMPRESS_UNBOUND]
	assert_true(node.conditions_met(_world_state), "unfired, so the condition holds")
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	assert_false(node.conditions_met(_world_state), "fired, so it does not")


func test_a_loop_of_branches_fails_loudly_instead_of_hanging_the_game() -> void:
	# `DialogueGraph.validate()` deliberately does not look for cycles, so this bound
	# is the only thing between a graph that walks for ever and a frozen game. Two
	# branches pointing at each other present nothing, so nothing would ever stop.
	watch_signal(_dialogue, &"dialogue_ended")
	var started: bool = _quietly(func() -> bool: return _dialogue.start(GRAPH_LOOP))
	assert_true(started, "the conversation begins")
	assert_false(_dialogue.is_active(), "and the bounded walk gave up rather than spinning")
	assert_null(_dialogue.current(), "with nothing left on screen")
	assert_signal_emitted(_dialogue, &"dialogue_ended", 1, "and it ended once")


# --- Events ------------------------------------------------------------------


func test_an_event_node_raises_and_walks_on() -> void:
	watch_signal(_dialogue, &"event_raised")
	_dialogue.start(GRAPH_EVENT)
	assert_signal_emitted(_dialogue, &"event_raised", 1, "the event went out")
	assert_eq(
		signal_arguments(_dialogue, &"event_raised", 0)[0],
		QuestEvents.MQ00_RESTED,
		"as the id the graph names"
	)
	assert_eq(_dialogue.current().node_id, &"AFTER", "and the conversation carried on")


func test_an_option_can_raise_an_event() -> void:
	watch_signal(_dialogue, &"event_raised")
	_dialogue.start(GRAPH_COMMITS)
	assert_true(_dialogue.choose(0), "the committing option is taken")
	assert_signal_emitted(_dialogue, &"event_raised", 1, "and raised its event")


# --- Exhaustible tables ------------------------------------------------------


func test_a_table_presents_every_row_with_its_earnest_marking() -> void:
	_dialogue.start(GRAPH_TABLE)
	var view := _dialogue.current()
	if not assert_not_null(view, "the table is on screen"):
		return
	assert_true(view.is_choice(), "and it is a choice")
	assert_eq(view.options.size(), 3, "with all three rows")
	assert_eq(view.options[0].text_key, &"DLG_TEST_TABLE_Q1", "keys, never sentences")
	assert_false(view.options[0].is_earnest, "the first row is a plain question")
	assert_true(view.options[2].is_earnest, "the third is the earnest one")
	assert_false(view.options[0].is_used, "and nothing has been asked yet")


func test_choosing_walks_the_thread_and_comes_back_with_the_row_spent() -> void:
	watch_signal(_dialogue, &"option_chosen")
	_dialogue.start(GRAPH_TABLE)
	assert_true(_dialogue.choose(0), "the first question is asked")
	assert_signal_emitted(_dialogue, &"option_chosen", 1)
	var arguments := signal_arguments(_dialogue, &"option_chosen", 0)
	assert_eq(arguments[0], GRAPH_TABLE, "the graph")
	assert_eq(arguments[1], &"TABLE", "the table")
	assert_eq(arguments[2], 0, "and which row")
	assert_eq(_dialogue.current().node_id, &"A1", "the answer plays")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"TABLE", "and the table comes back")
	assert_true(_dialogue.current().options[0].is_used, "with that row spent")
	assert_false(_dialogue.current().options[1].is_used, "and the others still open")


func test_a_spent_row_cannot_be_asked_again() -> void:
	_dialogue.start(GRAPH_TABLE)
	_dialogue.choose(0)
	_dialogue.advance()
	assert_false(_dialogue.choose(0), "asked and answered")
	assert_eq(_dialogue.current().node_id, &"TABLE", "and the table is still on screen")


func test_exhausting_every_row_falls_through_to_the_pickup_point() -> void:
	_dialogue.start(GRAPH_TABLE)
	for index: int in 3:
		assert_true(_dialogue.choose(index), "row %d is asked" % index)
		_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"PICKUP", "[All versions pick up here:]")
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "and then the conversation is over")


func test_leaving_a_table_early_goes_to_the_pickup_point() -> void:
	_dialogue.start(GRAPH_TABLE)
	_dialogue.choose(0)
	_dialogue.advance()
	assert_true(_dialogue.leave(), "the Fool may stop asking")
	assert_eq(_dialogue.current().node_id, &"PICKUP", "and picks up with everyone else")


func test_leaving_with_nothing_asked_is_allowed() -> void:
	_dialogue.start(GRAPH_TABLE)
	assert_true(_dialogue.leave(), "a Fool with no questions is a Fool")
	assert_eq(_dialogue.current().node_id, &"PICKUP", "the pickup point is the same edge")


func test_a_choice_cannot_be_advanced_past() -> void:
	_dialogue.start(GRAPH_TABLE)
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"TABLE", "a table moves by being chosen from")


func test_choosing_on_a_line_is_refused() -> void:
	_dialogue.start(GRAPH_LINES)
	assert_false(_dialogue.choose(0), "there is nothing to choose")
	assert_eq(_dialogue.current().node_id, &"L01", "and nothing moved")


func test_choosing_a_row_that_is_not_a_row_is_refused() -> void:
	_dialogue.start(GRAPH_TABLE)
	assert_false(_dialogue.choose(-1), "below the table")
	assert_false(_dialogue.choose(3), "past the table")
	assert_eq(_dialogue.current().node_id, &"TABLE", "and the table is untouched")


# --- Committing tables -------------------------------------------------------


func test_a_first_pick_commits_table_carries_straight_on() -> void:
	_dialogue.start(GRAPH_COMMITS)
	assert_true(_dialogue.choose(0), "the pick is taken")
	assert_eq(_dialogue.current().node_id, &"A1", "the thread plays")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"AFTER", "and continues on, never returning")
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "to the end of the conversation")


func test_a_first_pick_commits_table_cannot_be_left() -> void:
	_dialogue.start(GRAPH_COMMITS)
	assert_false(_dialogue.leave(), "the pick is the point")
	assert_eq(_dialogue.current().node_id, &"TABLE", "and the table is still on screen")


func test_a_committed_table_is_never_offered_again() -> void:
	# "the table is never offered again" is the mode's whole contract
	# (`DialogueNode.ChoiceMode`), and a thread that leads back to the table is the
	# only way to ask it. Re-offering it would let the Fool take a second first pick.
	_dialogue.start(GRAPH_COMMITS_AGAIN)
	assert_true(_dialogue.choose(0), "the pick is taken")
	assert_eq(_dialogue.current().node_id, &"A1", "the thread plays")
	_dialogue.advance()
	assert_eq(
		_dialogue.current().node_id,
		&"PICKUP",
		"and coming back round to the table walks through it to its continuation"
	)
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "then the conversation is over")


# --- Nested tables -----------------------------------------------------------


func test_a_follow_up_table_inside_a_thread_returns_to_its_own_table_first() -> void:
	_dialogue.start(GRAPH_NESTED)
	assert_true(_dialogue.choose(0), "the outer question is asked")
	assert_eq(_dialogue.current().node_id, &"A1", "the answer plays")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"FOLLOW", "and opens a follow-up table")
	assert_true(_dialogue.choose(0), "the follow-up is asked")
	assert_eq(_dialogue.current().node_id, &"A1_F1", "and answered")
	_dialogue.advance()
	assert_eq(_dialogue.current().node_id, &"TABLE", "then the outer table comes back")
	assert_true(_dialogue.current().options[0].is_used, "with the outer row spent")


func test_leaving_a_follow_up_table_returns_to_the_outer_one() -> void:
	_dialogue.start(GRAPH_NESTED)
	_dialogue.choose(0)
	_dialogue.advance()
	assert_true(_dialogue.leave(), "the follow-up may be left")
	assert_eq(_dialogue.current().node_id, &"TABLE", "and the outer table is where we land")


# --- Pools -------------------------------------------------------------------


func test_a_pool_picks_one_of_its_own_lines() -> void:
	_dialogue.start(GRAPH_POOL)
	var view := _dialogue.current()
	if not assert_not_null(view, "the pool presented something"):
		return
	assert_true(
		view.text_key in [&"DLG_TEST_POOL_01", &"DLG_TEST_POOL_02", &"DLG_TEST_POOL_03"],
		"and it came out of the pool"
	)


func test_a_seeded_pool_is_deterministic() -> void:
	var first := PackedStringArray()
	for run: int in 5:
		var service := DialogueService.new(_world_state, _catalog, SEED)
		service.start(GRAPH_POOL)
		first.append(String(service.current().text_key))
	for key: String in first:
		assert_eq(key, first[0], "the same seed picks the same line every time")


func test_a_pool_advances_like_a_line() -> void:
	_dialogue.start(GRAPH_POOL)
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "one Random Line, then out")


# --- Nothing persists --------------------------------------------------------


func test_a_replayed_conversation_forgets_which_rows_were_spent() -> void:
	_dialogue.start(GRAPH_TABLE)
	_dialogue.choose(0)
	_dialogue.advance()
	_dialogue.leave()
	_dialogue.advance()
	assert_false(_dialogue.is_active(), "the first run is over")
	_dialogue.start(GRAPH_TABLE)
	assert_false(_dialogue.current().options[0].is_used, "the row is open again")


func test_a_fresh_service_knows_nothing_about_an_earlier_one() -> void:
	_dialogue.start(GRAPH_TABLE)
	_dialogue.choose(0)
	var other := DialogueService.new(_world_state, _catalog, SEED)
	other.start(GRAPH_TABLE)
	assert_false(other.current().options[0].is_used, "nothing here is save data")
	assert_false(other.is_option_used(0), "and the query agrees")


# --- Chaining ----------------------------------------------------------------


func test_a_graph_that_names_a_successor_starts_it_the_moment_it_ends() -> void:
	watch_signal(_dialogue, &"dialogue_ended")
	watch_signal(_dialogue, &"dialogue_started")
	_dialogue.start(GRAPH_CHAIN_FROM)
	_dialogue.advance()
	assert_true(_dialogue.is_active(), "the chained conversation picked up")
	assert_eq(_dialogue.current_graph_id(), GRAPH_TABLE, "and it is the one named")
	assert_signal_emitted(_dialogue, &"dialogue_ended", 1, "the first one ended first")
	assert_signal_emitted(_dialogue, &"dialogue_started", 2, "then the second began")


func test_an_interrupted_conversation_does_not_chain() -> void:
	_dialogue.start(GRAPH_CHAIN_FROM)
	_dialogue.end()
	assert_false(_dialogue.is_active(), "an interruption stops at the interruption")


# --- Helpers -----------------------------------------------------------------


## Run `action` with the engine's error printing muted, and hand back its result.
## Starting an unknown graph is *meant* to `push_error`; `run_all.sh` fails any
## stage whose log holds an engine error line, so a provoked one must not print.
func _quietly(action: Callable) -> Variant:
	var was_printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Variant = action.call()
	Engine.print_error_messages = was_printing
	return result


## Fire the first `count` unbindings in card order, as a playthrough would.
func _unbind(count: int) -> void:
	var ids := _flags.unbinding_ids()
	for index: int in count:
		_world_state.fire(ids[index], _flags.find(ids[index]).fired_by)


func _line(
	node_id: StringName, text_key: StringName, next: StringName,
	speaker: StringName = Speakers.QUERENT
) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.LINE
	node.speaker = speaker
	node.text_key = text_key
	node.next = next
	return node


func _end(node_id: StringName = &"END") -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.END
	return node


func _option(
	text_key: StringName, next: StringName, earnest: bool = false,
	event: StringName = &""
) -> DialogueOption:
	var option := DialogueOption.new()
	option.text_key = text_key
	option.next = next
	option.is_earnest = earnest
	option.raises_event = event
	return option


func _choice(
	node_id: StringName, options: Array[DialogueOption], after_all: StringName,
	mode: DialogueNode.ChoiceMode = DialogueNode.ChoiceMode.EXHAUST_ALL
) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.CHOICE
	node.options = options
	node.after_all = after_all
	node.mode = mode
	return node


func _graph(
	graph_id: StringName, start: StringName, nodes: Array[DialogueNode],
	next_graph: StringName = &""
) -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.id = graph_id
	graph.quest_id = QuestIds.MQ00
	graph.source_ref = "tests/unit/dialogue/dialogue_service_test.gd"
	graph.start_node = start
	graph.nodes = nodes
	graph.next_graph_id = next_graph
	return graph


## Every fixture graph, in one catalog. Each one exercises exactly one rule of the
## runner, and none of them is a shipped conversation.
func _build_catalog() -> DialogueCatalog:
	var catalog := DialogueCatalog.new()

	var lines := _graph(GRAPH_LINES, &"L01", [
		_line(&"L01", &"DLG_TEST_LINES_01", &"L02"),
		_line(&"L02", &"DLG_TEST_LINES_02", &"END"),
		_end(),
	])

	var table_options: Array[DialogueOption] = [
		_option(&"DLG_TEST_TABLE_Q1", &"A1"),
		_option(&"DLG_TEST_TABLE_Q2", &"A2"),
		_option(&"DLG_TEST_TABLE_Q3", &"A3", true),
	]
	var table := _graph(GRAPH_TABLE, &"TABLE", [
		_choice(&"TABLE", table_options, &"PICKUP"),
		_line(&"A1", &"DLG_TEST_TABLE_A1", &"END"),
		_line(&"A2", &"DLG_TEST_TABLE_A2", &"END"),
		_line(&"A3", &"DLG_TEST_TABLE_A3", &"END"),
		_line(&"PICKUP", &"DLG_TEST_TABLE_PICKUP", &"END"),
		_end(),
	])

	var commit_options: Array[DialogueOption] = [
		_option(&"DLG_TEST_COMMITS_Q1", &"A1", false, QuestEvents.MQ00_RESTED),
	]
	var commits := _graph(GRAPH_COMMITS, &"TABLE", [
		_choice(&"TABLE", commit_options, &"", DialogueNode.ChoiceMode.FIRST_PICK_COMMITS),
		_line(&"A1", &"DLG_TEST_COMMITS_A1", &"AFTER"),
		_line(&"AFTER", &"DLG_TEST_COMMITS_AFTER", &"END"),
		_end(),
	])

	var branch := DialogueNode.new()
	branch.id = &"B01"
	branch.kind = DialogueNode.Kind.BRANCH
	branch.requires_fired = [WorldStateIds.WS_EMPRESS_UNBOUND]
	branch.then_node = &"BOUND"
	branch.else_node = &"UNBOUND"
	var branching := _graph(GRAPH_BRANCH, &"B01", [
		branch,
		_line(&"BOUND", &"DLG_TEST_BRANCH_BOUND", &"END"),
		_line(&"UNBOUND", &"DLG_TEST_BRANCH_UNBOUND", &"END"),
		_end(),
	])

	var event := DialogueNode.new()
	event.id = &"E01"
	event.kind = DialogueNode.Kind.EVENT
	event.event = QuestEvents.MQ00_RESTED
	event.next = &"AFTER"
	var eventful := _graph(GRAPH_EVENT, &"E01", [
		event,
		_line(&"AFTER", &"DLG_TEST_EVENT_AFTER", &"END"),
		_end(),
	])

	var pool := DialogueNode.new()
	pool.id = &"P01"
	pool.kind = DialogueNode.Kind.POOL
	pool.speaker = Speakers.QUERENT
	pool.text_keys = PackedStringArray([
		"DLG_TEST_POOL_01", "DLG_TEST_POOL_02", "DLG_TEST_POOL_03"
	])
	pool.next = &"END"
	var pooled := _graph(GRAPH_POOL, &"P01", [pool, _end()])

	# Two rows on the outer table on purpose: with one, spending it inside the
	# follow-up thread would exhaust the outer table too and fall straight through
	# to the pickup point, which is correct behaviour but proves nothing about
	# returning to a table that still has questions in it.
	var nested_outer: Array[DialogueOption] = [
		_option(&"DLG_TEST_NESTED_Q1", &"A1"),
		_option(&"DLG_TEST_NESTED_Q2", &"A2", true),
	]
	var nested_inner: Array[DialogueOption] = [_option(&"DLG_TEST_NESTED_Q1_F1", &"A1_F1")]
	var nested := _graph(GRAPH_NESTED, &"TABLE", [
		_choice(&"TABLE", nested_outer, &"PICKUP"),
		_line(&"A1", &"DLG_TEST_NESTED_A1", &"FOLLOW"),
		_line(&"A2", &"DLG_TEST_NESTED_A2", &"END"),
		_choice(&"FOLLOW", nested_inner, &"END"),
		_line(&"A1_F1", &"DLG_TEST_NESTED_A1_F1", &"END"),
		_line(&"PICKUP", &"DLG_TEST_NESTED_PICKUP", &"END"),
		_end(),
	])

	# A committing table whose thread comes back round to it: the only way to ask
	# whether a spent one is offered a second time.
	var commits_again_options: Array[DialogueOption] = [
		_option(&"DLG_TEST_COMMITS_AGAIN_Q1", &"A1"),
	]
	var commits_again := _graph(GRAPH_COMMITS_AGAIN, &"TABLE", [
		_choice(
			&"TABLE", commits_again_options, &"PICKUP",
			DialogueNode.ChoiceMode.FIRST_PICK_COMMITS
		),
		_line(&"A1", &"DLG_TEST_COMMITS_AGAIN_A1", &"TABLE"),
		_line(&"PICKUP", &"DLG_TEST_COMMITS_AGAIN_PICKUP", &"END"),
		_end(),
	])

	# Two branches pointing at each other. Legal data - `validate()` does not look
	# for cycles - and unwalkable, which is what `MAX_WALK_STEPS` is for.
	var loop_first := DialogueNode.new()
	loop_first.id = &"B01"
	loop_first.kind = DialogueNode.Kind.BRANCH
	loop_first.then_node = &"B02"
	loop_first.else_node = &"B02"
	var loop_second := DialogueNode.new()
	loop_second.id = &"B02"
	loop_second.kind = DialogueNode.Kind.BRANCH
	loop_second.then_node = &"B01"
	loop_second.else_node = &"B01"
	var looping := _graph(GRAPH_LOOP, &"B01", [loop_first, loop_second])

	var chain_from := _graph(GRAPH_CHAIN_FROM, &"L01", [
		_line(&"L01", &"DLG_TEST_CHAIN_01", &"END"),
		_end(),
	], GRAPH_TABLE)

	catalog.entries = [
		lines, table, commits, commits_again, branching, eventful, pooled, nested,
		looping, chain_from
	]
	return catalog
