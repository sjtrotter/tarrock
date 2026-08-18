extends TarrockTest

## `RumorService`: which main quests' news is travelling, and how far it has got.
##
## `docs/design/npc-system.md` §"The world talks about you": adjacent regions hear
## after a short in-game delay, everywhere hears after a longer one, and both are
## measured against `GameClock`, never the wall. A synthetic map and quest keep the
## delay arithmetic legible - three regions (home, one road away, and one nothing
## connects to) and one MAIN quest that lives in the first.

const HOME := &"TEST_HOME"
const ADJACENT := &"TEST_ADJACENT"
const FAR := &"TEST_FAR"
const MAIN_QUEST := &"MQ_TEST"
const SIDE_QUEST := &"SQ-TEST-01"

var _clock: GameClock = null
var _service: RumorService = null


func before_each() -> void:
	_clock = GameClock.new()
	_service = RumorService.new(_rules(), _quests(), _graph(), _clock)


# --- Delay arithmetic ------------------------------------------------------------


func test_the_home_region_has_always_heard() -> void:
	_service.seed_rumor(MAIN_QUEST)
	assert_true(_service.has_reached(MAIN_QUEST, HOME), "news does not travel to announce itself")


func test_the_adjacent_region_waits_the_short_delay() -> void:
	_service.seed_rumor(MAIN_QUEST)
	assert_false(_service.has_reached(MAIN_QUEST, ADJACENT), "not yet - the news has not travelled")
	_clock.advance(_rules().rumor_delay_seconds(true) - 1.0)
	assert_false(_service.has_reached(MAIN_QUEST, ADJACENT), "still short of the delay")
	_clock.advance(2.0)
	assert_true(_service.has_reached(MAIN_QUEST, ADJACENT), "and now it has")


func test_a_non_adjacent_region_waits_the_long_delay_not_the_short_one() -> void:
	_service.seed_rumor(MAIN_QUEST)
	_clock.advance(_rules().rumor_delay_seconds(true) + 1.0)
	assert_false(
		_service.has_reached(MAIN_QUEST, FAR),
		"the short delay has passed, but Far is not adjacent to Home"
	)
	_clock.advance(_rules().rumor_delay_seconds(false))
	assert_true(_service.has_reached(MAIN_QUEST, FAR), "the long delay finishes the job")


func test_an_unseeded_quest_has_reached_nowhere() -> void:
	assert_false(_service.has_reached(MAIN_QUEST, HOME), "nothing completed it yet")
	assert_false(_service.is_seeded(MAIN_QUEST))
	assert_eq(_service.seeded_at(MAIN_QUEST), -1.0)


func test_a_side_quest_seeds_nothing() -> void:
	assert_false(
		_service.seed_rumor(SIDE_QUEST),
		"npc-system.md: main-quest completions only, or the world over-reacts"
	)
	assert_false(_service.is_seeded(SIDE_QUEST))


func test_seeding_twice_only_plants_once() -> void:
	assert_true(_service.seed_rumor(MAIN_QUEST))
	_clock.advance(100.0)
	assert_false(_service.seed_rumor(MAIN_QUEST), "already out; the second call changes nothing")
	assert_eq(_service.seeded_at(MAIN_QUEST), 0.0, "the ORIGINAL completion time survives")


# --- Save round-trip ---------------------------------------------------------


func test_snapshot_round_trips_the_seeds() -> void:
	_service.seed_rumor(MAIN_QUEST)
	_clock.advance(123.0)
	var snapshot := _service.to_snapshot()

	var reader := RumorService.new(_rules(), _quests(), _graph(), GameClock.new())
	var errors := reader.restore_snapshot(snapshot)
	assert_eq(errors, PackedStringArray())
	assert_true(reader.is_seeded(MAIN_QUEST))
	assert_eq(reader.seeded_at(MAIN_QUEST), 0.0, "the ORIGINAL clock reading, not the reader's own")
	assert_false(reader.is_pristine())


func test_restore_refuses_a_service_already_in_play() -> void:
	_service.seed_rumor(MAIN_QUEST)
	var errors := _service.restore_snapshot({})
	assert_true(errors.size() > 0, "a fresh service only - this one has already been seeded")


func test_restore_refuses_a_snapshot_naming_no_such_quest() -> void:
	var reader := RumorService.new(_rules(), _quests(), _graph(), GameClock.new())
	var errors := reader.restore_snapshot({
		RumorService.SNAPSHOT_RUMORS: [
			{
				RumorService.SNAPSHOT_RUMOR_QUEST: "MQ_NOBODY",
				RumorService.SNAPSHOT_RUMOR_AT: 0.0,
			}
		]
	})
	assert_true(errors.size() > 0)
	assert_true(reader.is_pristine(), "a rejected snapshot commits nothing")


func test_is_pristine_until_the_first_seed() -> void:
	assert_true(_service.is_pristine())
	_service.seed_rumor(MAIN_QUEST)
	assert_false(_service.is_pristine())


# --- Internals -----------------------------------------------------------------


func _rules() -> NpcRules:
	var rules := NpcRules.new()
	rules.id = &"NPC_RULES_TEST"
	rules.recent_pick_memory = 3
	rules.rumor_adjacent_delay_hours = 6.0
	rules.rumor_world_delay_hours = 48.0
	rules.seconds_per_in_game_hour = 1.0
	return rules


func _quests() -> QuestCatalog:
	var main_quest := QuestDefinition.new()
	main_quest.id = MAIN_QUEST
	main_quest.type = QuestDefinition.Type.MAIN
	main_quest.region_id = HOME
	var side_quest := QuestDefinition.new()
	side_quest.id = SIDE_QUEST
	side_quest.type = QuestDefinition.Type.SIDE
	side_quest.region_id = HOME
	var catalog := QuestCatalog.new()
	catalog.entries = [main_quest, side_quest]
	return catalog


func _graph() -> RegionGraph:
	var edge := RegionEdge.new()
	edge.a = HOME
	edge.b = ADJACENT
	edge.kind = RegionEdge.Kind.ROAD
	var graph := RegionGraph.new()
	graph.edges = [edge]
	return graph
