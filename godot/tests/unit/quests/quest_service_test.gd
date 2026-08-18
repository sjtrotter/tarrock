extends TarrockTest

## The quest runner, over synthetic quests.
##
## The catalog here is built in the test rather than loaded, so each rule can be
## provoked on its own: a quest that requires another quest, a quest with a branch
## group, a quest whose edge is gated on a flag. The **flags** are real ones from
## `docs/design/world.md` §World-state matrix, because `WorldStateService` refuses
## to fire anything the generated catalog does not list, and a made-up flag would
## prove nothing.
##
## What the shipped data does is `quest_data_test.gd`; what the Cliff scene does with
## it is `res://tests/cliff_test.gd`.

const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## Synthetic quest ids, shaped like the real ones so the definitions validate.
const SIMPLE := &"MQ00"
const GATED := &"MQ19"
const FOLLOWER := &"MQ20"
const BRANCHING := &"MQ01"
const UNKNOWN_QUEST := &"MQ99"

## Round 4-B regression fixtures: never added to `_build_catalog()`, so each builds
## its own tiny catalog and never risks another test's state.
const TWO_GROUP := &"TEST_TWO_GROUP_QUEST"
const GROUP_A := &"TEST_GROUP_A"
const GROUP_B := &"TEST_GROUP_B"
const GHOST_QUEST := &"TEST_GHOST_QUEST"
const ORDER_FIRST := &"TEST_ORDER_FIRST"
const ORDER_SECOND := &"TEST_ORDER_SECOND"

## Synthetic states and events.
const START := &"START"
const MIDDLE := &"MIDDLE"
const CHOSEN := &"CHOSEN"
const DONE := &"DONE"
const EVENT_ONE := &"TEST_EVENT_ONE"
const EVENT_TWO := &"TEST_EVENT_TWO"
const EVENT_GO := &"TEST_EVENT_GO"
const EVENT_CHOOSE_TRAVELING := &"TEST_EVENT_CHOOSE_TRAVELING"
const EVENT_CHOOSE_SETTLED := &"TEST_EVENT_CHOOSE_SETTLED"
const EVENT_CHOOSE_B := &"TEST_EVENT_CHOOSE_B"
const EVENT_FINISH := &"TEST_EVENT_FINISH"
const EVENT_NOBODY_WANTS := &"TEST_EVENT_NOBODY_WANTS"

var _flags: WorldStateCatalog = null
var _thresholds: ActThresholds = null
var _ladder: RenownLadder = null
var _world_state: WorldStateService = null
var _catalog: QuestCatalog = null
var _quests: QuestService = null


func before_each() -> void:
	_flags = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	_thresholds = load(ACT_THRESHOLDS_PATH) as ActThresholds
	_ladder = load(RENOWN_LADDER_PATH) as RenownLadder
	_world_state = WorldStateService.new(_flags, _thresholds, _ladder)
	_catalog = _build_catalog()
	_quests = QuestService.new(_world_state, _catalog)


# --- The synthetic catalog is itself sound -----------------------------------


func test_the_test_catalog_is_valid() -> void:
	assert_eq(
		_catalog.validate(_flags),
		PackedStringArray(),
		"the fixtures must be legal quests or nothing below proves anything"
	)


# --- Availability ------------------------------------------------------------


func test_a_quest_that_requires_nothing_is_available() -> void:
	assert_true(_quests.is_available(SIMPLE))
	assert_false(_quests.is_started(SIMPLE))
	assert_false(_quests.is_complete(SIMPLE))
	assert_eq(_quests.state_of(SIMPLE), &"")


func test_a_quest_waits_for_the_flag_it_requires() -> void:
	assert_false(_quests.is_available(GATED), "the Sun is still nailed at noon")
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, &"MQ19")
	assert_true(_quests.is_available(GATED), "the flag it named has fired")


func test_a_quest_waits_for_the_quest_it_requires() -> void:
	assert_false(_quests.is_available(FOLLOWER), "MQ00 has not been played")
	_quests.start(SIMPLE)
	assert_false(_quests.is_available(FOLLOWER), "started is not finished")
	_quests.raise(EVENT_ONE)
	_quests.raise(EVENT_TWO)
	assert_true(_quests.is_complete(SIMPLE))
	assert_true(_quests.is_available(FOLLOWER), "the quest it named is complete")


func test_an_unknown_quest_is_an_error_and_is_unavailable() -> void:
	var available: bool = _quietly(func() -> bool: return _quests.is_available(UNKNOWN_QUEST))
	assert_false(available)
	var started: bool = _quietly(func() -> bool: return _quests.start(UNKNOWN_QUEST))
	assert_false(started)


# --- Starting ----------------------------------------------------------------


func test_starting_puts_a_quest_in_its_initial_state() -> void:
	watch_signal(_world_state, &"quest_state_changed")
	watch_signal(_quests, &"quest_started")
	assert_true(_quests.start(SIMPLE), "the first call starts it")
	assert_eq(_quests.state_of(SIMPLE), START)
	assert_true(_quests.is_started(SIMPLE))
	assert_signal_emitted(_quests, &"quest_started", 1)
	assert_signal_emitted(_world_state, &"quest_state_changed", 1)


func test_starting_twice_is_refused() -> void:
	_quests.start(SIMPLE)
	watch_signal(_quests, &"quest_started")
	assert_false(_quests.start(SIMPLE), "a second start would rewind the quest")
	assert_eq(_quests.state_of(SIMPLE), START)
	assert_signal_emitted(_quests, &"quest_started", 0)


func test_an_unavailable_quest_does_not_start() -> void:
	assert_false(_quests.start(GATED))
	assert_false(_quests.is_started(GATED))


func test_a_quest_with_no_graph_does_not_start() -> void:
	var definition := _catalog.find(SIMPLE)
	definition.graph = null
	var started: bool = _quietly(func() -> bool: return _quests.start(SIMPLE))
	assert_false(started, "a quest nobody has authored cannot be played")


# --- Raising events ----------------------------------------------------------


func test_an_event_moves_only_the_quest_listening_from_its_current_state() -> void:
	_quests.start(SIMPLE)
	watch_signal(_quests, &"quest_advanced")
	_quests.raise(EVENT_TWO)
	assert_eq(_quests.state_of(SIMPLE), START, "EVENT_TWO belongs to a state we are not in")
	_quests.raise(EVENT_ONE)
	assert_eq(_quests.state_of(SIMPLE), MIDDLE)
	assert_signal_emitted(_quests, &"quest_advanced", 1)
	assert_eq(signal_arguments(_quests, &"quest_advanced", 0), [SIMPLE, START, MIDDLE])


func test_an_event_nobody_listens_for_is_ignored() -> void:
	_quests.start(SIMPLE)
	watch_signal(_quests, &"quest_advanced")
	_quests.raise(EVENT_NOBODY_WANTS)
	assert_eq(_quests.state_of(SIMPLE), START)
	assert_signal_emitted(_quests, &"quest_advanced", 0)


func test_an_event_does_nothing_to_a_quest_that_never_started() -> void:
	_quests.raise(EVENT_ONE)
	assert_eq(_quests.state_of(SIMPLE), &"", "events do not start quests")


func test_an_edge_waits_for_the_flag_it_requires() -> void:
	_world_state.fire(WorldStateIds.WS_SUN_UNBOUND, &"MQ19")
	_quests.start(GATED)
	_quests.raise(EVENT_GO)
	assert_eq(_quests.state_of(GATED), START, "the Moon is still bound, so the edge is shut")
	_world_state.fire(WorldStateIds.WS_MOON_UNBOUND, &"MQ18")
	_quests.raise(EVENT_GO)
	assert_eq(_quests.state_of(GATED), DONE, "with both flags fired the edge opens")


func test_an_edge_closes_once_the_flag_it_excludes_fires() -> void:
	_quests.start(SIMPLE)
	_catalog.find(SIMPLE).graph.transitions[0].requires_not_fired = [
		WorldStateIds.WS_DEATH_UNBOUND
	] as Array[StringName]
	_world_state.fire(WorldStateIds.WS_DEATH_UNBOUND, &"MQ13")
	_quests.raise(EVENT_ONE)
	assert_eq(_quests.state_of(SIMPLE), START, "the world has confessed; that door is shut")


func test_a_finished_quest_stops_listening() -> void:
	_quests.start(SIMPLE)
	_quests.raise(EVENT_ONE)
	_quests.raise(EVENT_TWO)
	assert_true(_quests.is_complete(SIMPLE))
	watch_signal(_quests, &"quest_advanced")
	_quests.raise(EVENT_ONE)
	assert_eq(_quests.state_of(SIMPLE), DONE)
	assert_signal_emitted(_quests, &"quest_advanced", 0)


func test_active_quests_are_the_started_and_unfinished_ones() -> void:
	assert_eq(_quests.active_quest_ids(), [] as Array[StringName])
	_quests.start(SIMPLE)
	assert_eq(_quests.active_quest_ids(), [SIMPLE] as Array[StringName])
	_quests.raise(EVENT_ONE)
	_quests.raise(EVENT_TWO)
	assert_eq(_quests.active_quest_ids(), [] as Array[StringName], "a finished quest is not active")


# --- Completion and firing ---------------------------------------------------


func test_nothing_fires_until_the_quest_completes() -> void:
	watch_signal(_world_state, &"world_state_fired")
	_quests.start(BRANCHING)
	_quests.raise(EVENT_CHOOSE_TRAVELING)
	assert_eq(_quests.state_of(BRANCHING), CHOSEN, "the quest moved")
	assert_eq(_world_state.unbound_count(), 0, "and the world has not changed")
	assert_false(_world_state.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_false(_world_state.is_fired(WorldStateIds.WS_TROUPE_TRAVELING))
	assert_signal_emitted(_world_state, &"world_state_fired", 0)


func test_completing_fires_the_quests_flags_and_its_chosen_branch() -> void:
	watch_signal(_quests, &"quest_completed")
	_quests.start(BRANCHING)
	_quests.raise(EVENT_CHOOSE_TRAVELING)
	_quests.raise(EVENT_FINISH)
	assert_eq(_quests.state_of(BRANCHING), DONE)
	assert_true(_quests.is_complete(BRANCHING))
	assert_true(_world_state.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "the fires committed")
	assert_true(_world_state.is_fired(WorldStateIds.WS_TROUPE_TRAVELING), "so did the choice")
	assert_false(_world_state.is_fired(WorldStateIds.WS_TROUPE_SETTLED), "and only the choice")
	assert_eq(_world_state.fired_by(WorldStateIds.WS_MAGICIAN_UNBOUND), BRANCHING)
	assert_eq(_world_state.fired_by(WorldStateIds.WS_TROUPE_TRAVELING), BRANCHING)
	assert_eq(_world_state.unbound_count(), 1, "a branch flag is not an unbinding")
	assert_signal_emitted(_quests, &"quest_completed", 1)


func test_a_quest_that_owes_a_choice_refuses_to_complete() -> void:
	watch_signal(_quests, &"quest_completion_refused")
	watch_signal(_quests, &"quest_completed")
	_quests.start(BRANCHING)
	_quietly(func() -> void: _quests.raise(EVENT_FINISH))
	assert_eq(_quests.state_of(BRANCHING), START, "the quest stayed exactly where it was")
	assert_false(_quests.is_complete(BRANCHING))
	assert_false(_world_state.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "and fired nothing")
	assert_signal_emitted(_quests, &"quest_completion_refused", 1)
	assert_signal_emitted(_quests, &"quest_completed", 0)
	assert_eq(
		signal_arguments(_quests, &"quest_completion_refused", 0),
		[BRANCHING, QuestService.REFUSED_BRANCH_UNCHOSEN],
		"the refusal says which rule stopped it"
	)


func test_a_refused_completion_can_still_be_earned_afterwards() -> void:
	_quests.start(BRANCHING)
	_quietly(func() -> void: _quests.raise(EVENT_FINISH))
	_quests.raise(EVENT_CHOOSE_SETTLED)
	_quests.raise(EVENT_FINISH)
	assert_true(_quests.is_complete(BRANCHING), "the choice made, the quest finishes")
	assert_true(_world_state.is_fired(WorldStateIds.WS_TROUPE_SETTLED))
	assert_false(_world_state.is_fired(WorldStateIds.WS_TROUPE_TRAVELING))


func test_a_choice_cannot_be_changed_once_made() -> void:
	_quests.start(BRANCHING)
	_quests.raise(EVENT_CHOOSE_TRAVELING)
	watch_signal(_quests, &"quest_advanced")
	_quietly(func() -> void: _quests.raise(EVENT_CHOOSE_SETTLED))
	assert_eq(
		_world_state.quest_choice(BRANCHING, &"MQ01_TROUPE"),
		WorldStateIds.WS_TROUPE_TRAVELING,
		"the troupe travels; the second offer changed nothing"
	)
	assert_signal_emitted(_quests, &"quest_advanced", 0, "and the edge was not taken")


func test_completing_a_quest_that_fires_nothing_changes_no_flags() -> void:
	watch_signal(_world_state, &"world_state_fired")
	_quests.start(SIMPLE)
	_quests.raise(EVENT_ONE)
	_quests.raise(EVENT_TWO)
	assert_true(_quests.is_complete(SIMPLE))
	assert_signal_emitted(_world_state, &"world_state_fired", 0, "MQ00 fires nothing, ever")


# --- Saving ------------------------------------------------------------------


func test_a_quest_resumes_where_a_save_left_it() -> void:
	_quests.start(BRANCHING)
	_quests.raise(EVENT_CHOOSE_TRAVELING)
	var snapshot := _world_state.to_snapshot()

	var loaded := WorldStateService.new(_flags, _thresholds, _ladder)
	assert_eq(loaded.restore_snapshot(snapshot), PackedStringArray(), "the save reads back clean")
	var resumed := QuestService.new(loaded, _build_catalog())
	assert_eq(resumed.state_of(BRANCHING), CHOSEN, "the quest is where the player left it")
	assert_true(resumed.is_started(BRANCHING))
	assert_false(resumed.is_complete(BRANCHING))
	assert_eq(resumed.active_quest_ids(), [BRANCHING] as Array[StringName])

	resumed.raise(EVENT_FINISH)
	assert_true(resumed.is_complete(BRANCHING), "and it finishes without being told twice")
	assert_true(loaded.is_fired(WorldStateIds.WS_TROUPE_TRAVELING), "with the choice it had made")


# --- Round 4-B regressions ----------------------------------------------------


## A completing transition that chooses group A while group B is still unchosen must
## refuse *without* burning A's set-once choice - otherwise the quest can never
## complete at all: A is spent, and B was never offered.
func test_a_completing_transition_does_not_burn_its_own_choice_on_refusal() -> void:
	var quests := QuestService.new(_world_state, _two_group_catalog())
	quests.start(TWO_GROUP)
	watch_signal(quests, &"quest_completion_refused")
	watch_signal(quests, &"quest_advanced")
	watch_signal(quests, &"quest_completed")

	_quietly(func() -> void: quests.raise(EVENT_FINISH))
	assert_eq(quests.state_of(TWO_GROUP), START, "refused: the quest stayed put")
	assert_signal_emitted(quests, &"quest_advanced", 0, "and never moved")
	assert_signal_emitted(quests, &"quest_completion_refused", 1)
	assert_eq(
		_world_state.quest_choice(TWO_GROUP, GROUP_A),
		&"",
		"group A's choice must not be burned by a refusal group B caused"
	)

	# Chosen afterwards, in a separate move: group B is no longer unchosen.
	quests.raise(EVENT_CHOOSE_B)
	assert_eq(_world_state.quest_choice(TWO_GROUP, GROUP_B), WorldStateIds.WS_DIVIDE_EASTMARRIED)
	assert_eq(quests.state_of(TWO_GROUP), START, "choosing B alone does not finish the quest")

	# The same edge that was refused now finishes the quest, choosing A on the way.
	quests.raise(EVENT_FINISH)
	assert_true(quests.is_complete(TWO_GROUP), "with both groups chosen, it finishes")
	assert_eq(_world_state.quest_choice(TWO_GROUP, GROUP_A), WorldStateIds.WS_TROUPE_TRAVELING)
	assert_true(_world_state.is_fired(WorldStateIds.WS_TROUPE_TRAVELING))
	assert_true(_world_state.is_fired(WorldStateIds.WS_DIVIDE_EASTMARRIED))
	assert_signal_emitted(quests, &"quest_completed", 1)


## `_apply()` must not write a `to_state` its own graph does not have - a graph built
## without going through `QuestGraph.validate()` (as generated content always is, but
## a bad hand-edit of a `graphs/*.tres` file would not be) must be refused, not crash
## or silently strand the quest in an unknown state.
func test_a_transition_to_an_unknown_state_is_refused() -> void:
	var graph := QuestGraph.new()
	graph.quest_id = GHOST_QUEST
	graph.initial_state = START
	graph.states = [_state(START)] as Array[QuestState]
	graph.transitions = [_transition(START, &"NOWHERE", EVENT_GO)] as Array[QuestTransition]
	var catalog := _catalog_of([_definition(GHOST_QUEST, graph)])

	var quests := QuestService.new(_world_state, catalog)
	quests.start(GHOST_QUEST)
	watch_signal(quests, &"quest_advanced")

	_quietly(func() -> void: quests.raise(EVENT_GO))
	assert_eq(quests.state_of(GHOST_QUEST), START, "an edge to nowhere real must not be taken")
	assert_signal_emitted(quests, &"quest_advanced", 0)


## Determinism: two started quests both answering one event must move, and emit, in
## the catalog's own order - never the order they happen to be iterated some other way.
func test_two_quests_answering_one_event_advance_in_catalog_order() -> void:
	var first_graph := QuestGraph.new()
	first_graph.quest_id = ORDER_FIRST
	first_graph.initial_state = START
	first_graph.states = [_state(START), _state(DONE, true)] as Array[QuestState]
	first_graph.transitions = [_transition(START, DONE, EVENT_GO)] as Array[QuestTransition]

	var second_graph := QuestGraph.new()
	second_graph.quest_id = ORDER_SECOND
	second_graph.initial_state = START
	second_graph.states = [_state(START), _state(DONE, true)] as Array[QuestState]
	second_graph.transitions = [_transition(START, DONE, EVENT_GO)] as Array[QuestTransition]

	var catalog := _catalog_of([
		_definition(ORDER_FIRST, first_graph), _definition(ORDER_SECOND, second_graph)
	])
	var quests := QuestService.new(_world_state, catalog)
	quests.start(ORDER_FIRST)
	quests.start(ORDER_SECOND)
	watch_signal(quests, &"quest_advanced")

	quests.raise(EVENT_GO)

	assert_signal_emitted(quests, &"quest_advanced", 2, "one raise moves both listeners")
	assert_eq(
		signal_arguments(quests, &"quest_advanced", 0),
		[ORDER_FIRST, START, DONE],
		"the first catalog entry advances - and is heard - first"
	)
	assert_eq(
		signal_arguments(quests, &"quest_advanced", 1),
		[ORDER_SECOND, START, DONE],
		"the second catalog entry advances - and is heard - second"
	)


# --- Builders ----------------------------------------------------------------


## Run `action` with the engine's error printing muted, and hand back its result.
##
## A refused completion and a re-chosen branch are *meant* to `push_error` - they are
## content bugs, and that is how an author finds one. But `run_all.sh` fails any
## stage whose log holds an engine error line, so a test that provokes one must not
## print it.
func _quietly(action: Callable) -> Variant:
	var was_printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Variant = action.call()
	Engine.print_error_messages = was_printing
	return result


func _state(state_id: StringName, is_complete: bool = false) -> QuestState:
	var state := QuestState.new()
	state.id = state_id
	state.is_complete = is_complete
	return state


func _transition(
	from_state: StringName, to_state: StringName, event: StringName
) -> QuestTransition:
	var transition := QuestTransition.new()
	transition.from_state = from_state
	transition.to_state = to_state
	transition.on_event = event
	return transition


func _definition(quest_id: StringName, graph: QuestGraph) -> QuestDefinition:
	var definition := QuestDefinition.new()
	definition.id = quest_id
	definition.title_key = &"QUEST_TEST_TITLE"
	definition.type = QuestDefinition.Type.MAIN
	definition.arcana_number = 0
	definition.region_id = &"CLIFF"
	definition.doc_path = "docs/quests/main/MQ00-the-leap.md"
	definition.graph = graph
	return definition


## Four quests: one plain, one gated on flags, one gated on another quest, and one
## with a branch group to choose from.
func _build_catalog() -> QuestCatalog:
	var simple := QuestGraph.new()
	simple.quest_id = SIMPLE
	simple.initial_state = START
	simple.states = [_state(START), _state(MIDDLE), _state(DONE, true)] as Array[QuestState]
	simple.transitions = [
		_transition(START, MIDDLE, EVENT_ONE),
		_transition(MIDDLE, DONE, EVENT_TWO),
	] as Array[QuestTransition]

	var gated_graph := QuestGraph.new()
	gated_graph.quest_id = GATED
	gated_graph.initial_state = START
	gated_graph.states = [_state(START), _state(DONE, true)] as Array[QuestState]
	var gated_edge := _transition(START, DONE, EVENT_GO)
	gated_edge.requires_fired = [WorldStateIds.WS_MOON_UNBOUND] as Array[StringName]
	gated_graph.transitions = [gated_edge] as Array[QuestTransition]

	var follower_graph := QuestGraph.new()
	follower_graph.quest_id = FOLLOWER
	follower_graph.initial_state = START
	follower_graph.states = [_state(START), _state(DONE, true)] as Array[QuestState]
	follower_graph.transitions = [_transition(START, DONE, EVENT_GO)] as Array[QuestTransition]

	var branching_graph := QuestGraph.new()
	branching_graph.quest_id = BRANCHING
	branching_graph.initial_state = START
	branching_graph.states = [
		_state(START), _state(CHOSEN), _state(DONE, true)
	] as Array[QuestState]
	var travels := _transition(START, CHOSEN, EVENT_CHOOSE_TRAVELING)
	travels.chooses_branch = WorldStateIds.WS_TROUPE_TRAVELING
	var settles := _transition(START, CHOSEN, EVENT_CHOOSE_SETTLED)
	settles.chooses_branch = WorldStateIds.WS_TROUPE_SETTLED
	# The edge that lets the runner be asked to finish a quest that owes a choice,
	# and the one that tries to change a choice already made.
	var rechoose := _transition(CHOSEN, CHOSEN, EVENT_CHOOSE_SETTLED)
	rechoose.chooses_branch = WorldStateIds.WS_TROUPE_SETTLED
	branching_graph.transitions = [
		travels,
		settles,
		rechoose,
		_transition(START, DONE, EVENT_FINISH),
		_transition(CHOSEN, DONE, EVENT_FINISH),
	] as Array[QuestTransition]

	var gated := _definition(GATED, gated_graph)
	gated.required_states = [WorldStateIds.WS_SUN_UNBOUND] as Array[StringName]
	var follower := _definition(FOLLOWER, follower_graph)
	follower.required_states = [SIMPLE] as Array[StringName]
	var branching := _definition(BRANCHING, branching_graph)
	branching.fired_states = [WorldStateIds.WS_MAGICIAN_UNBOUND] as Array[StringName]
	var group := QuestBranchGroup.new()
	group.group_id = &"MQ01_TROUPE"
	group.flags = [
		WorldStateIds.WS_TROUPE_TRAVELING, WorldStateIds.WS_TROUPE_SETTLED
	] as Array[StringName]
	branching.branch_groups = [group] as Array[QuestBranchGroup]

	var catalog := QuestCatalog.new()
	catalog.entries = [
		_definition(SIMPLE, simple), gated, follower, branching
	] as Array[QuestDefinition]
	return catalog


## A quest with two branch groups, real flags: EVENT_FINISH completes it and chooses
## group A; EVENT_CHOOSE_B is a separate, non-completing move that records group B.
## Built fresh per test (never folded into `_build_catalog()`) so
## `test_a_completing_transition_does_not_burn_its_own_choice_on_refusal` cannot
## disturb, or be disturbed by, any other test's quest state.
func _two_group_catalog() -> QuestCatalog:
	var graph := QuestGraph.new()
	graph.quest_id = TWO_GROUP
	graph.initial_state = START
	graph.states = [_state(START), _state(DONE, true)] as Array[QuestState]
	var finish := _transition(START, DONE, EVENT_FINISH)
	finish.chooses_branch = WorldStateIds.WS_TROUPE_TRAVELING
	var choose_b := _transition(START, START, EVENT_CHOOSE_B)
	choose_b.chooses_branch = WorldStateIds.WS_DIVIDE_EASTMARRIED
	graph.transitions = [finish, choose_b] as Array[QuestTransition]

	var definition := _definition(TWO_GROUP, graph)
	var group_a := QuestBranchGroup.new()
	group_a.group_id = GROUP_A
	group_a.flags = [
		WorldStateIds.WS_TROUPE_TRAVELING, WorldStateIds.WS_TROUPE_SETTLED
	] as Array[StringName]
	var group_b := QuestBranchGroup.new()
	group_b.group_id = GROUP_B
	group_b.flags = [
		WorldStateIds.WS_DIVIDE_EASTMARRIED, WorldStateIds.WS_DIVIDE_WESTMARRIED
	] as Array[StringName]
	definition.branch_groups = [group_a, group_b] as Array[QuestBranchGroup]

	var catalog := QuestCatalog.new()
	catalog.entries = [definition] as Array[QuestDefinition]
	return catalog


## A one-off catalog over exactly the definitions given, for a test that needs its own
## small graph rather than anything `_build_catalog()` offers.
func _catalog_of(entries: Array[QuestDefinition]) -> QuestCatalog:
	var catalog := QuestCatalog.new()
	catalog.entries = entries
	return catalog
