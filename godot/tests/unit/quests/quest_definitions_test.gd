extends TarrockTest

## The quest definition resources, on their own terms.
##
## These are the shape rules a `QuestDefinition`, a `QuestGraph` and a
## `QuestCatalog` enforce about themselves - built here out of synthetic resources,
## so each rule is provoked deliberately rather than hoped for. The *generated* data
## is checked against `docs/quests/` by `quest_data_test.gd`.

## Real flags, because `QuestCatalog.validate()` resolves ids against the generated
## world-state catalog and a made-up flag would prove nothing about the rule.
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"

var _world_states: WorldStateCatalog = null


func before_each() -> void:
	_world_states = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog


# --- Graphs ------------------------------------------------------------------


func test_a_linear_graph_validates() -> void:
	var graph := _linear_graph()
	assert_eq(graph.validate(), PackedStringArray(), "a start, a middle and an end is a graph")
	assert_true(graph.is_valid())
	assert_true(graph.has_state(&"DONE"))
	assert_true(graph.is_complete_state(&"DONE"))
	assert_false(graph.is_complete_state(&"START"))
	assert_eq(graph.event_ids(), [&"EVENT_ONE", &"EVENT_TWO"] as Array[StringName])


func test_a_graph_that_starts_nowhere_is_invalid() -> void:
	var graph := _linear_graph()
	graph.initial_state = &"NOWHERE"
	assert_false(graph.is_valid(), "a graph must start at one of its own states")


func test_a_graph_with_a_dangling_endpoint_is_invalid() -> void:
	var graph := _linear_graph()
	graph.transitions[1].to_state = &"NOWHERE"
	assert_false(graph.is_valid(), "an edge must arrive somewhere real")


func test_a_graph_nobody_can_finish_is_invalid() -> void:
	var graph := _linear_graph()
	graph.states[2].is_complete = false
	assert_false(graph.is_valid(), "a quest with no reachable end could never commit its fires")


func test_a_complete_state_nothing_reaches_is_invalid() -> void:
	var graph := _linear_graph()
	graph.transitions.remove_at(1)
	assert_false(graph.is_valid(), "an end nothing leads to is an end nobody reaches")


func test_two_edges_gated_the_same_way_are_invalid() -> void:
	var graph := _linear_graph()
	graph.states.append(_state(&"ELSEWHERE"))
	graph.transitions.append(_transition(&"START", &"ELSEWHERE", &"EVENT_ONE"))
	assert_false(graph.is_valid(), "one event from one state must not have two equal answers")


func test_two_edges_gated_differently_are_fine() -> void:
	var graph := _linear_graph()
	graph.states.append(_state(&"ELSEWHERE"))
	var alternative := _transition(&"START", &"ELSEWHERE", &"EVENT_ONE")
	alternative.requires_fired = [WorldStateIds.WS_MAGICIAN_UNBOUND] as Array[StringName]
	graph.transitions.append(alternative)
	assert_eq(graph.validate(), PackedStringArray(), "world state may fork one event two ways")


func test_a_transition_cannot_need_a_flag_both_ways() -> void:
	var transition := _transition(&"START", &"MIDDLE", &"EVENT_ONE")
	transition.requires_fired = [WorldStateIds.WS_SUN_UNBOUND] as Array[StringName]
	transition.requires_not_fired = [WorldStateIds.WS_SUN_UNBOUND] as Array[StringName]
	assert_false(transition.validate().is_empty(), "fired and unfired at once is nothing")


# --- Definitions -------------------------------------------------------------


func test_a_well_formed_definition_validates() -> void:
	var definition := _definition(&"MQ00")
	assert_eq(definition.validate(), PackedStringArray(), "%s" % str(definition.validate()))
	assert_true(definition.is_main())
	assert_true(definition.is_playable())


func test_a_side_quest_id_is_allowed_too() -> void:
	var definition := _definition(&"SQ-PRESTIGE-01")
	definition.type = QuestDefinition.Type.SIDE
	assert_eq(definition.validate(), PackedStringArray())
	assert_false(definition.is_main())


func test_an_id_outside_the_scheme_is_invalid() -> void:
	var definition := _definition(&"QUEST_ONE")
	assert_false(definition.is_valid(), "ids come from docs/quests/README.md's two shapes")


func test_a_title_that_is_not_a_key_is_invalid() -> void:
	var definition := _definition(&"MQ00")
	definition.title_key = &"The Leap"
	assert_false(definition.is_valid(), "a title is a translation key, never English")


func test_a_card_number_outside_the_deck_is_invalid() -> void:
	var definition := _definition(&"MQ00")
	definition.arcana_number = 22
	assert_false(definition.is_valid(), "there are 21 Major Arcana, forever")


func test_a_quest_with_no_region_or_doc_is_invalid() -> void:
	var definition := _definition(&"MQ00")
	definition.region_id = &""
	definition.doc_path = ""
	assert_eq(definition.validate().size(), 2, "both omissions are reported, not just the first")


func test_a_definition_linking_another_quests_graph_is_invalid() -> void:
	var definition := _definition(&"MQ00")
	definition.graph.quest_id = &"MQ01"
	assert_false(definition.is_valid(), "a graph belongs to the quest it says it belongs to")


func test_a_quest_without_a_graph_is_valid_but_not_playable() -> void:
	var definition := _definition(&"MQ00")
	definition.graph = null
	assert_eq(definition.validate(), PackedStringArray(), "a quest may be known before it is authored")
	assert_false(definition.is_playable())


func test_a_branch_group_needs_two_distinct_members() -> void:
	var group := QuestBranchGroup.new()
	group.group_id = &"MQ01_TROUPE"
	group.flags = [WorldStateIds.WS_TROUPE_TRAVELING] as Array[StringName]
	assert_false(group.validate().is_empty(), "a choice with one option is not a choice")
	group.flags = [
		WorldStateIds.WS_TROUPE_TRAVELING, WorldStateIds.WS_TROUPE_TRAVELING
	] as Array[StringName]
	assert_false(group.validate().is_empty(), "and the same option twice is not two options")


func test_a_definition_finds_the_group_a_flag_belongs_to() -> void:
	var definition := _definition(&"MQ01")
	definition.branch_groups = [_troupe_group()] as Array[QuestBranchGroup]
	assert_eq(definition.branch_group_ids(), [&"MQ01_TROUPE"] as Array[StringName])
	var group := definition.branch_group_for(WorldStateIds.WS_TROUPE_SETTLED)
	if not assert_not_null(group):
		return
	assert_eq(group.group_id, &"MQ01_TROUPE")
	assert_null(definition.branch_group_for(WorldStateIds.WS_SUN_UNBOUND))


# --- Catalogs ----------------------------------------------------------------


func test_a_catalog_of_one_good_quest_validates() -> void:
	var catalog := _catalog([_definition(&"MQ00")])
	assert_eq(catalog.validate(_world_states), PackedStringArray())
	assert_true(catalog.has(&"MQ00"))
	assert_false(catalog.has(&"MQ99"))
	assert_eq(catalog.ids(), [&"MQ00"] as Array[StringName])


func test_a_catalog_refuses_the_same_quest_twice() -> void:
	var catalog := _catalog([_definition(&"MQ00"), _definition(&"MQ00")])
	assert_false(catalog.is_valid(_world_states), "one id, one quest")


func test_a_requirement_that_is_neither_flag_nor_quest_is_reported() -> void:
	var definition := _definition(&"MQ01")
	definition.required_states = [&"WS_NOT_A_REAL_FLAG"] as Array[StringName]
	assert_false(_catalog([definition]).is_valid(_world_states))


func test_a_requirement_naming_another_quest_is_allowed() -> void:
	var required := _definition(&"MQ00")
	var dependent := _definition(&"MQ20")
	dependent.required_states = [&"MQ00"] as Array[StringName]
	assert_eq(_catalog([required, dependent]).validate(_world_states), PackedStringArray())


func test_firing_a_flag_the_matrix_never_defined_is_reported() -> void:
	var definition := _definition(&"MQ01")
	definition.fired_states = [&"WS_NOT_A_REAL_FLAG"] as Array[StringName]
	assert_false(_catalog([definition]).is_valid(_world_states))


func test_branching_on_an_unbinding_is_reported() -> void:
	var definition := _definition(&"MQ01")
	var group := QuestBranchGroup.new()
	group.group_id = &"MQ01_TROUPE"
	group.flags = [
		WorldStateIds.WS_MAGICIAN_UNBOUND, WorldStateIds.WS_TROUPE_SETTLED
	] as Array[StringName]
	definition.branch_groups = [group] as Array[QuestBranchGroup]
	assert_false(_catalog([definition]).is_valid(_world_states), "an unbinding is not a choice")


func test_a_group_the_matrix_files_elsewhere_is_reported() -> void:
	var definition := _definition(&"MQ01")
	var group := _troupe_group()
	group.group_id = &"MQ01_SOMETHING_ELSE"
	definition.branch_groups = [group] as Array[QuestBranchGroup]
	assert_false(_catalog([definition]).is_valid(_world_states), "the matrix owns the group id")


func test_a_graph_choosing_a_flag_the_quest_does_not_own_is_reported() -> void:
	var definition := _definition(&"MQ01")
	definition.graph.transitions[0].chooses_branch = WorldStateIds.WS_TROUPE_SETTLED
	assert_false(
		_catalog([definition]).is_valid(_world_states),
		"a graph may only record a choice its quest's frontmatter declares"
	)
	definition.branch_groups = [_troupe_group()] as Array[QuestBranchGroup]
	assert_eq(_catalog([definition]).validate(_world_states), PackedStringArray())


# --- Builders ----------------------------------------------------------------


func _state(state_id: StringName, is_complete: bool = false) -> QuestState:
	var state := QuestState.new()
	state.id = state_id
	state.is_complete = is_complete
	return state


func _transition(from_state: StringName, to_state: StringName, event: StringName) -> QuestTransition:
	var transition := QuestTransition.new()
	transition.from_state = from_state
	transition.to_state = to_state
	transition.on_event = event
	return transition


## START -EVENT_ONE-> MIDDLE -EVENT_TWO-> DONE(complete).
func _linear_graph(quest_id: StringName = &"MQ00") -> QuestGraph:
	var graph := QuestGraph.new()
	graph.quest_id = quest_id
	graph.initial_state = &"START"
	graph.states = [_state(&"START"), _state(&"MIDDLE"), _state(&"DONE", true)] as Array[QuestState]
	graph.transitions = [
		_transition(&"START", &"MIDDLE", &"EVENT_ONE"),
		_transition(&"MIDDLE", &"DONE", &"EVENT_TWO"),
	] as Array[QuestTransition]
	return graph


func _definition(quest_id: StringName) -> QuestDefinition:
	var definition := QuestDefinition.new()
	definition.id = quest_id
	definition.title_key = &"QUEST_TEST_TITLE"
	definition.type = QuestDefinition.Type.MAIN
	definition.arcana_number = 0
	definition.region_id = &"CLIFF"
	definition.doc_path = "docs/quests/main/MQ00-the-leap.md"
	definition.graph = _linear_graph(quest_id)
	return definition


func _troupe_group() -> QuestBranchGroup:
	var group := QuestBranchGroup.new()
	group.group_id = &"MQ01_TROUPE"
	group.flags = [
		WorldStateIds.WS_TROUPE_TRAVELING, WorldStateIds.WS_TROUPE_SETTLED
	] as Array[StringName]
	return group


func _catalog(entries: Array[QuestDefinition]) -> QuestCatalog:
	var catalog := QuestCatalog.new()
	catalog.entries = entries
	return catalog
