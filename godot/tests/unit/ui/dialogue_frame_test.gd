extends TarrockTest

## The conversation panel: what it shows, what it drives, and what it never does.
##
## `docs/design/art-audio.md` §UI/UX pillars, Conversational framing: the frame is a
## camera adjustment over the world, "rather than a cut to a separate dialogue screen
## ... No hard lock". `docs/design/narrative.md`'s tables are the Fool's options, and an
## exhaustible table lets the Fool leave with questions unasked - so the "…" row is
## offered on one kind of table and not on the other, which is the one thing the panel
## could not ask before this round added `DialogueService.can_leave()`.
##
## The graphs are fixtures, like `tests/unit/dialogue/dialogue_service_test.gd`'s: what
## the shipped MQ00 conversations do is that suite's and `res://tests/ui_test.gd`'s.

const DIALOGUE_SCENE := "res://scenes/ui/dialogue_frame.tscn"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

const GRAPH_LINES := &"TEST_UI_LINES"
const GRAPH_TABLE := &"TEST_UI_TABLE"
const GRAPH_COMMITS := &"TEST_UI_COMMITS"
const GRAPH_NAMED := &"TEST_UI_NAMED"

var _frame: DialogueFrame = null
var _dialogue: DialogueService = null
var _framing: CameraFraming = null
var _camera: Camera2D = null
var _bodies: Dictionary = {}
var _spawned: Array[Node] = []


func before_each() -> void:
	var world_state := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	_dialogue = DialogueService.new(world_state, _build_catalog())
	_frame = (load(DIALOGUE_SCENE) as PackedScene).instantiate() as DialogueFrame
	tree().root.add_child(_frame)


func after_each() -> void:
	if _frame != null and is_instance_valid(_frame):
		_frame.get_parent().remove_child(_frame)
		_frame.free()
	_frame = null
	for node: Node in _spawned:
		if node != null and is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.free()
	_spawned.clear()
	_bodies.clear()
	_framing = null
	_camera = null


func test_a_frame_with_no_runner_shows_nothing_and_does_not_error() -> void:
	assert_false(_frame.visible)
	assert_eq(_frame.speaker_key(), &"")
	assert_eq(_frame.option_count(), 0)
	_frame.advance()
	assert_false(_frame.choose(0))
	assert_false(_frame.leave())


func test_a_line_puts_the_speaker_on_the_plate_and_the_key_on_the_parchment() -> void:
	_frame.attach(_dialogue)
	assert_true(_dialogue.start(GRAPH_LINES))
	assert_true(_frame.visible)
	assert_eq(_frame.speaker_key(), &"SPEAKER_QUERENT", "Speakers.name_key, not a name")
	assert_eq(_frame.line_key(), &"DLG_TEST_UI_LINES_01")
	assert_eq(_frame.option_count(), 0, "a line offers nothing to say back")
	assert_false(_frame.is_leave_offered())


func test_advancing_moves_the_conversation_and_closing_it_hides_the_frame() -> void:
	_frame.attach(_dialogue)
	_dialogue.start(GRAPH_LINES)
	_frame.advance()
	assert_eq(_frame.line_key(), &"DLG_TEST_UI_LINES_02")
	_frame.advance()
	assert_false(_dialogue.is_active(), "the graph ran out")
	assert_false(_frame.visible, "and the panel got out of the way")


func test_a_table_draws_one_row_per_option_and_a_way_out() -> void:
	_frame.attach(_dialogue)
	_dialogue.start(GRAPH_TABLE)
	assert_eq(_frame.option_count(), 3)
	assert_eq(_frame.option_button(0).text, "DLG_TEST_UI_TABLE_Q1")
	assert_true(
		_frame.is_leave_offered(),
		"narrative.md: all questions MAY be exhausted, so the Fool may stop asking"
	)
	assert_eq(_frame.leave_button().text, String(UiKeys.DIALOGUE_LEAVE))


func test_a_row_already_taken_is_greyed_rather_than_removed() -> void:
	_frame.attach(_dialogue)
	_dialogue.start(GRAPH_TABLE)
	assert_false(_frame.is_option_used(0))
	assert_true(_frame.choose(0))
	# The answer plays, then the table comes back with that question spent.
	_frame.advance()
	assert_eq(_frame.option_count(), 3, "a spent question is still on the page")
	assert_true(_frame.is_option_used(0), "and it is greyed")
	assert_false(_frame.is_option_used(1))


func test_a_committing_table_offers_no_way_out() -> void:
	_frame.attach(_dialogue)
	_dialogue.start(GRAPH_COMMITS)
	assert_eq(_frame.option_count(), 1)
	assert_false(
		_frame.is_leave_offered(),
		"a *(first pick commits)* table has no early edge - the pick is the point"
	)
	assert_false(_frame.leave(), "and pressing it would do nothing, which is why it is not drawn")


func test_leaving_a_table_walks_to_the_pick_up_point() -> void:
	_frame.attach(_dialogue)
	_dialogue.start(GRAPH_TABLE)
	assert_true(_frame.leave())
	assert_eq(_frame.line_key(), &"DLG_TEST_UI_TABLE_PICKUP")
	assert_eq(_frame.option_count(), 0)


func test_pressing_a_row_takes_it_through_the_service() -> void:
	_frame.attach(_dialogue)
	_dialogue.start(GRAPH_TABLE)
	watch_signal(_dialogue, &"option_chosen")
	_frame.option_button(1).pressed.emit()
	assert_signal_emitted(_dialogue, &"option_chosen", 1)
	assert_eq(signal_arguments(_dialogue, &"option_chosen", 0)[2], 1)


# --- The conversational frame ------------------------------------------------------


func test_a_conversation_appearing_takes_the_camera_frame_and_ending_gives_it_back() -> void:
	# `art-audio.md` §UI/UX pillars: dialogue is "framed in-world by a slight camera
	# adjustment ... rather than a cut to a separate dialogue screen". Nothing used to
	# ASK for that adjustment in play: the panel released a frame it never took.
	_attach_with_framing()
	assert_false(_framing.is_framing(), "nothing is being framed yet")
	assert_true(_dialogue.start(GRAPH_LINES))
	assert_true(_frame.is_framing(), "the conversation came up, so the camera came in")
	assert_true(_framing.is_framing())
	_dialogue.end()
	assert_false(_framing.is_framing(), "the frame lets go with the conversation")
	assert_false(_frame.is_framing())


func test_the_querent_is_a_voice_so_the_frame_takes_the_fool_and_pip() -> void:
	# `art-audio.md`: "the shared space between the participants (the Fool and Pip
	# especially)". The Querent has no body (`characters.md` §The Querent), so the two
	# on screen are the pair the doc names.
	_attach_with_framing()
	_dialogue.start(GRAPH_LINES)
	var framed := _framing.framed_nodes()
	assert_eq(framed.size(), 2)
	assert_has(framed, _bodies[Speakers.FOOL])
	assert_has(framed, _bodies[DialogueFrame.PIP_NODE], "the Fool and his dog")


func test_a_speaker_with_a_body_in_the_world_is_framed_instead_of_pip() -> void:
	var flick := Node2D.new()
	tree().root.add_child(flick)
	_spawned.append(flick)
	_bodies[Speakers.FLICK] = flick
	_attach_with_framing()
	_dialogue.start(GRAPH_NAMED)
	var framed := _framing.framed_nodes()
	assert_eq(framed.size(), 2)
	assert_has(framed, flick, "the person the Fool is talking to")
	assert_false(framed.has(_bodies[DialogueFrame.PIP_NODE]))


func test_a_world_with_no_dog_frames_the_fool_alone_rather_than_nothing() -> void:
	# Pip is answered for and the answer is "nobody" - MQ18 is not the only hour of
	# the game he could be away for, and a frame is still taken on the Fool.
	_bodies[DialogueFrame.PIP_NODE] = null
	_attach_with_framing()
	_dialogue.start(GRAPH_LINES)
	assert_true(_framing.is_framing())
	var framed := _framing.framed_nodes()
	assert_eq(framed.size(), 1)
	assert_eq(framed[0], _bodies[Speakers.FOOL])


func test_a_panel_with_no_provider_at_all_shows_the_line_and_frames_nothing() -> void:
	_attach_with_framing(false)
	_dialogue.start(GRAPH_LINES)
	assert_true(_frame.visible, "the words still get on screen")
	assert_false(_framing.is_framing(), "there is simply nobody to point the camera at")


func test_the_frame_is_taken_once_and_not_grabbed_back_line_by_line() -> void:
	# No hard lock: a player who walks out of the frame is let go, and the next line
	# of the same conversation must not haul the camera back.
	_attach_with_framing()
	_dialogue.start(GRAPH_LINES)
	assert_true(_framing.is_framing())
	_framing.release()
	_frame.advance()
	assert_eq(_frame.line_key(), &"DLG_TEST_UI_LINES_02", "the conversation moved on")
	assert_false(_framing.is_framing(), "and the camera was left where the player put it")


func test_the_frame_a_panel_did_not_take_is_not_a_frame_it_gives_back() -> void:
	_attach_with_framing(false)
	var elsewhere := Node2D.new()
	tree().root.add_child(elsewhere)
	_spawned.append(elsewhere)
	assert_true(_framing.frame_conversation(elsewhere, null), "somebody else framed something")
	_dialogue.start(GRAPH_LINES)
	_dialogue.end()
	assert_true(_framing.is_framing(), "and this panel did not take it away from them")


func test_the_easing_stops_being_processed_once_the_camera_has_arrived() -> void:
	# One node running every frame of the game to lerp two values that are already
	# where they belong. It eases while there is easing to do and not otherwise.
	_attach_with_framing()
	assert_false(_framing.is_processing(), "nothing to ease before a conversation")
	_dialogue.start(GRAPH_LINES)
	assert_true(_framing.is_processing())
	_dialogue.end()
	assert_true(_framing.is_processing(), "the camera still has to ease home")
	for step: int in range(600):
		_framing._process(1.0 / 60.0)
		if not _framing.is_processing():
			break
	assert_false(_framing.is_processing(), "and once it is home it stops")
	assert_true(_framing.is_settled())
	assert_almost_eq(_camera.offset.length(), 0.0, 0.001)


## The panel, a camera to frame with, and the Fool and Pip standing apart in the
## world - which is what the shell hands over in play (`UiShell.speaker_node`).
func _attach_with_framing(with_provider: bool = true) -> void:
	_camera = Camera2D.new()
	tree().root.add_child(_camera)
	_spawned.append(_camera)
	_framing = CameraFraming.new()
	tree().root.add_child(_framing)
	_spawned.append(_framing)
	_framing.attach_camera(_camera)
	if with_provider:
		if not _bodies.has(Speakers.FOOL):
			_bodies[Speakers.FOOL] = _body(Vector2(0.0, 0.0))
		if not _bodies.has(DialogueFrame.PIP_NODE):
			_bodies[DialogueFrame.PIP_NODE] = _body(Vector2(90.0, -40.0))
		_frame.set_speaker_node_provider(_node_for)
	_frame.attach(_dialogue, _framing)


func _body(at: Vector2) -> Node2D:
	var node := Node2D.new()
	node.global_position = at
	tree().root.add_child(node)
	_spawned.append(node)
	return node


func _node_for(node_id: StringName) -> Node2D:
	return _bodies.get(node_id, null) as Node2D


func _build_catalog() -> DialogueCatalog:
	var catalog := DialogueCatalog.new()

	var lines := _graph(GRAPH_LINES, &"L01", [
		_line(&"L01", &"DLG_TEST_UI_LINES_01", &"L02"),
		_line(&"L02", &"DLG_TEST_UI_LINES_02", &"END"),
		_end(),
	])

	var table_options: Array[DialogueOption] = [
		_option(&"DLG_TEST_UI_TABLE_Q1", &"A1"),
		_option(&"DLG_TEST_UI_TABLE_Q2", &"A2"),
		_option(&"DLG_TEST_UI_TABLE_Q3", &"A3", true),
	]
	var table := _graph(GRAPH_TABLE, &"TABLE", [
		_choice(&"TABLE", table_options, &"PICKUP", DialogueNode.ChoiceMode.EXHAUST_ALL),
		_line(&"A1", &"DLG_TEST_UI_TABLE_A1", &"END"),
		_line(&"A2", &"DLG_TEST_UI_TABLE_A2", &"END"),
		_line(&"A3", &"DLG_TEST_UI_TABLE_A3", &"END"),
		_line(&"PICKUP", &"DLG_TEST_UI_TABLE_PICKUP", &"END"),
		_end(),
	])

	var commit_options: Array[DialogueOption] = [
		_option(&"DLG_TEST_UI_COMMITS_Q1", &"A1"),
	]
	var commits := _graph(GRAPH_COMMITS, &"TABLE", [
		_choice(&"TABLE", commit_options, &"", DialogueNode.ChoiceMode.FIRST_PICK_COMMITS),
		_line(&"A1", &"DLG_TEST_UI_COMMITS_A1", &"END"),
		_end(),
	])

	var named := _graph(GRAPH_NAMED, &"L01", [
		_named_line(&"L01", &"DLG_TEST_UI_NAMED_01", &"END"),
		_end(),
	])

	catalog.entries = [lines, table, commits, named]
	return catalog


## A line said by somebody who is standing there - `Speakers.FLICK`, the one named
## NPC any graph has a line for today.
func _named_line(node_id: StringName, text_key: StringName, next: StringName) -> DialogueNode:
	var node := _line(node_id, text_key, next)
	node.speaker = Speakers.FLICK
	return node


func _line(node_id: StringName, text_key: StringName, next: StringName) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.LINE
	node.speaker = Speakers.QUERENT
	node.text_key = text_key
	node.next = next
	return node


func _end() -> DialogueNode:
	var node := DialogueNode.new()
	node.id = &"END"
	node.kind = DialogueNode.Kind.END
	return node


func _option(
	text_key: StringName, next: StringName, earnest: bool = false
) -> DialogueOption:
	var option := DialogueOption.new()
	option.text_key = text_key
	option.next = next
	option.is_earnest = earnest
	return option


func _choice(
	node_id: StringName,
	options: Array[DialogueOption],
	after_all: StringName,
	mode: DialogueNode.ChoiceMode
) -> DialogueNode:
	var node := DialogueNode.new()
	node.id = node_id
	node.kind = DialogueNode.Kind.CHOICE
	node.options = options
	node.after_all = after_all
	node.mode = mode
	return node


func _graph(
	graph_id: StringName, start: StringName, nodes: Array[DialogueNode]
) -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.id = graph_id
	graph.quest_id = QuestIds.MQ00
	graph.source_ref = "tests/unit/ui/dialogue_frame_test.gd"
	graph.start_node = start
	graph.nodes = nodes
	return graph
