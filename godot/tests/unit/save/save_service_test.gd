extends TarrockTest

## `SaveService`: capture, write, read, apply - and everything it refuses to do.
##
## `docs/design/technical.md` §Save system (Godot) is the contract. The properties
## this file exists to pin:
##
##   * a save written by this build reads back as the same playthrough;
##   * a write is atomic and leaves no debris;
##   * a save from a newer build, a corrupt file, a missing file and a file with a
##     field gone all fail as *data* - no crash, no half-load;
##   * a load fills a fresh world and refuses a world in play (a load is not a reset);
##   * what lands on disk is ids and values, never a resource path or an object.
##
## Every test writes into its own `user://test_saves_*` directory and removes it
## afterwards, so a failing run cannot leave a fixture behind that the next one reads.

const CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

const FIXTURE_DIR := "res://tests/fixtures/saves"
const FIXTURE_BLANK := "v1_blank.json"
const FIXTURE_PLAYED := "v1_played.json"
const FIXTURE_FUTURE := "v99_future.json"
const FIXTURE_CORRUPT := "corrupt.json"
const FIXTURE_NO_WORLD_STATE := "v1_missing_world_state.json"

var _catalog: WorldStateCatalog = null
var _thresholds: ActThresholds = null
var _ladder: RenownLadder = null
var _world_state: WorldStateService = null
var _clock: GameClock = null
var _service: SaveService = null
var _saves_dir: String = ""


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as WorldStateCatalog
	_thresholds = load(ACT_THRESHOLDS_PATH) as ActThresholds
	_ladder = load(RENOWN_LADDER_PATH) as RenownLadder
	_world_state = _fresh_world()
	_clock = GameClock.new()
	_saves_dir = "user://test_saves_%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	_service = SaveService.new(_world_state, _clock, _saves_dir)


func after_each() -> void:
	var dir := DirAccess.open(_saves_dir)
	if dir == null:
		return
	for file_name: String in dir.get_files():
		DirAccess.remove_absolute(_saves_dir.path_join(file_name))
	DirAccess.remove_absolute(_saves_dir)


## A world nobody has played yet, built over the real generated definitions.
func _fresh_world() -> WorldStateService:
	return WorldStateService.new(_catalog, _thresholds, _ladder)


## Put a checked-in fixture into a slot, exactly as it sits in the repo.
func _install_fixture(file_name: String, slot: int) -> void:
	DirAccess.make_dir_recursive_absolute(_saves_dir)
	var text := FileAccess.get_file_as_string(FIXTURE_DIR.path_join(file_name))
	var file := FileAccess.open(_service.slot_path(slot), FileAccess.WRITE)
	if file == null:
		fail("could not install the fixture %s" % file_name)
		return
	file.store_string(text)
	file.close()


## Run `action` with the engine's error printing muted, and hand back its result.
##
## `capture()` on a service with no world state is *meant* to push an error - that is
## how a mis-wired composition root surfaces. But `run_all.sh` fails any stage whose
## log holds an engine error line, so a test that provokes one deliberately must not
## print it.
func _quietly(action: Callable) -> Variant:
	var was_printing := Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Variant = action.call()
	Engine.print_error_messages = was_printing
	return result


## Three unbindings, a branch, standing, the Hermit, an NPC, two quests.
func _play_a_while() -> void:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	_world_state.fire(WorldStateIds.WS_TROUPE_TRAVELING, &"MQ01")
	_world_state.fire(WorldStateIds.WS_PRIESTESS_UNBOUND, &"MQ02")
	_world_state.adjust_renown(Suit.Id.CUPS, 12, &"MQ01")
	_world_state.set_hermit_answer(&"HERMIT_ANSWER_DONT_KNOW_YET")
	_world_state.npc_remember(&"FLICK", &"MET_THE_FOOL")
	_world_state.set_quest_state(&"MQ01", &"complete")


# --- Capture -----------------------------------------------------------------


func test_capture_reflects_the_live_world_state() -> void:
	_play_a_while()
	var model := _service.capture()
	assert_eq(model.schema_version, SaveModel.CURRENT_SCHEMA_VERSION)
	assert_eq(model.world_state, _world_state.to_snapshot(), "the snapshot travels verbatim")
	var fired: Dictionary = model.world_state[WorldStateService.SNAPSHOT_FIRED]
	assert_has(fired, String(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_has(fired, String(WorldStateIds.WS_TROUPE_TRAVELING))
	assert_eq(model.world_state[WorldStateService.SNAPSHOT_READING].size(), 2, "branch flags do not read")


func test_capture_carries_the_clock_and_the_fields_this_round_owns() -> void:
	_clock.advance(90.0)
	_service.loaded_playtime_seconds = 10.0
	_service.set_current_region(RegionIds.PRESTIGE)
	_service.set_last_waystation(RegionIds.WAYSTATION_PRESTIGE)
	assert_true(_service.mark_waystation_visited(RegionIds.WAYSTATION_CLIFF))
	assert_false(
		_service.mark_waystation_visited(RegionIds.WAYSTATION_CLIFF),
		"a Waystation is visited once, however often it is rested at"
	)
	_service.set_difficulty(DifficultyMode.Id.TRIAL)
	var model := _service.capture()
	assert_eq(model.visited_waystations, [RegionIds.WAYSTATION_CLIFF])
	assert_almost_eq(model.playtime_seconds, 100.0, 0.001, "playtime accumulates across sessions")
	assert_eq(model.current_region_id, RegionIds.PRESTIGE)
	assert_eq(model.last_waystation_id, RegionIds.WAYSTATION_PRESTIGE)
	assert_eq(model.difficulty_mode, DifficultyMode.Id.TRIAL)


func test_a_new_playthrough_captures_as_journey() -> void:
	assert_eq(_service.capture().difficulty_mode, DifficultyMode.DEFAULT)


# --- Writing -----------------------------------------------------------------


func test_a_written_slot_reads_back_as_the_same_playthrough() -> void:
	_play_a_while()
	_service.set_current_region(RegionIds.PRESTIGE)
	_service.set_difficulty(DifficultyMode.Id.STORY)
	var written := _service.capture()
	assert_eq(_service.write_slot(0, written).size(), 0, "a valid model writes")

	var result := _service.read_slot(0)
	if not assert_true(result.ok, "the slot reads back: %s" % str(result.errors)):
		return
	assert_eq(result.migrated_from, SaveModel.CURRENT_SCHEMA_VERSION)
	assert_true(
		_json_equal(result.model.to_dictionary(), written.to_dictionary()),
		"the file is the playthrough: %s" % str(result.model.to_dictionary())
	)


func test_writing_leaves_no_temp_file_behind() -> void:
	_service.write_slot(1, _service.capture())
	var dir := DirAccess.open(_saves_dir)
	if not assert_not_null(dir, "the save directory was created"):
		return
	var names := PackedStringArray(dir.get_files())
	assert_eq(names.size(), 1, "one slot, one file: %s" % str(names))
	assert_eq(names[0], "slot_1.json")


func test_writing_the_same_slot_twice_replaces_it() -> void:
	_service.write_slot(0, _service.capture())
	_play_a_while()
	assert_eq(_service.write_slot(0, _service.capture()).size(), 0, "an existing slot is overwritten")
	var result := _service.read_slot(0)
	if not assert_true(result.ok, "%s" % str(result.errors)):
		return
	assert_eq(result.model.world_state[WorldStateService.SNAPSHOT_READING].size(), 2, "the newer save won")


func test_an_invalid_model_is_never_written() -> void:
	var model := _service.capture()
	model.schema_version = 99
	var errors := _service.write_slot(0, model)
	assert_true(errors.size() > 0, "a model this build could not read back is refused")
	assert_false(_service.slot_exists(0), "and nothing reached the disk")


func test_a_refused_write_leaves_the_previous_save_whole() -> void:
	# Validation happens before a single byte moves, and the write is a rename over
	# the top: the save the player already earned survives a save that cannot be made.
	_play_a_while()
	var good := _service.capture()
	_service.write_slot(0, good)
	var bad := _service.capture()
	bad.difficulty_mode = 99 as DifficultyMode.Id
	assert_true(_service.write_slot(0, bad).size() > 0, "an unwritable model is refused")
	var result := _service.read_slot(0)
	if not assert_true(result.ok, "the earlier save is still there: %s" % str(result.errors)):
		return
	assert_true(_json_equal(result.model.to_dictionary(), good.to_dictionary()), "and it is unchanged")


func test_a_write_that_cannot_reach_its_temp_file_leaves_the_previous_save_byte_for_byte() -> void:
	# The atomicity rule, tested from the failure side: the slot is only ever replaced
	# by a rename of a temp file that was written whole. Block the temp path with a
	# DIRECTORY - a real thing a crashed sync tool or an unlucky editor can leave - and
	# the write must fail with the earlier save untouched down to the byte, not
	# half-overwritten by a writer that fell back to the slot itself.
	_play_a_while()
	assert_eq(_service.write_slot(3, _service.capture()).size(), 0, "the first save is written")
	var before := FileAccess.get_file_as_bytes(_service.slot_path(3))
	if not assert_true(before.size() > 0, "there is a save on disk to protect"):
		return

	var blocker := _service.slot_path(3) + SaveService.TEMP_EXTENSION
	if not assert_eq(DirAccess.make_dir_recursive_absolute(blocker), OK, "the temp path is blocked"):
		return

	_world_state.fire(WorldStateIds.WS_EMPEROR_UNBOUND, &"MQ04")
	var later := _service.capture()
	assert_false(
		before.get_string_from_utf8().contains(String(WorldStateIds.WS_EMPEROR_UNBOUND)),
		"the second model really is a different playthrough from the one on disk"
	)
	var problems: PackedStringArray = _quietly(
		func() -> PackedStringArray: return _service.write_slot(3, later)
	)
	assert_true(problems.size() > 0, "a write that cannot make its temp file is refused")
	assert_eq(
		FileAccess.get_file_as_bytes(_service.slot_path(3)),
		before,
		"and the save already on disk is byte-identical"
	)
	DirAccess.remove_absolute(blocker)


func test_a_negative_slot_is_refused() -> void:
	assert_true(_service.write_slot(-1, _service.capture()).size() > 0)


func test_what_lands_on_disk_is_ids_and_values_only() -> void:
	_play_a_while()
	_service.write_slot(0, _service.capture())
	var text := FileAccess.get_file_as_string(_service.slot_path(0))
	assert_false(text.contains("res://"), "a save never names a resource path")
	assert_false(text.contains("Object("), "a save never names an object")
	assert_true(text.contains(String(WorldStateIds.WS_MAGICIAN_UNBOUND)), "it names flags by id")
	assert_true(text.contains("\n"), "the file is indented so a human can read a bug report")


# --- Slots on disk -----------------------------------------------------------


func test_list_slots_is_sorted_and_ignores_everything_else() -> void:
	for slot: int in [3, 0, 11]:
		_service.write_slot(slot, _service.capture())
	# Debris an interrupted write or a stray editor file could leave.
	DirAccess.make_dir_recursive_absolute(_saves_dir)
	var stray := FileAccess.open(_saves_dir.path_join("slot_7.json.tmp"), FileAccess.WRITE)
	if stray != null:
		stray.store_string("{}")
		stray.close()
	assert_eq(_service.list_slots(), PackedInt32Array([0, 3, 11]), "ascending, and no .tmp")


func test_list_slots_only_reports_ids_that_read_back() -> void:
	# THE INVARIANT: every id list_slots() returns opens with read_slot(). Names that
	# parse as integers but are not the names slot_path() writes are not slots - a save
	# menu offered `slot_007.json` as slot 7 would open a file that is not there.
	for slot: int in [0, 2]:
		_service.write_slot(slot, _service.capture())
	DirAccess.make_dir_recursive_absolute(_saves_dir)
	for decoy: String in ["slot_007.json", "slot_-1.json", "slot_.json"]:
		var file := FileAccess.open(_saves_dir.path_join(decoy), FileAccess.WRITE)
		if file == null:
			fail("could not plant the decoy %s" % decoy)
			continue
		file.store_string("{}")
		file.close()

	var slots := _service.list_slots()
	assert_eq(slots, PackedInt32Array([0, 2]), "the decoys are not slots: %s" % str(slots))
	for slot: int in slots:
		assert_true(_service.read_slot(slot).ok, "every listed slot reads back: %d" % slot)


func test_slot_exists_and_delete_slot() -> void:
	assert_false(_service.slot_exists(2), "nothing is saved yet")
	_service.write_slot(2, _service.capture())
	assert_true(_service.slot_exists(2))
	assert_true(_service.delete_slot(2), "the file was there and is gone")
	assert_false(_service.slot_exists(2))
	assert_eq(_service.list_slots().size(), 0)


func test_deleting_a_slot_that_is_not_there_is_false_not_an_error() -> void:
	assert_false(_service.delete_slot(5))


func test_deleting_a_save_un_fires_nothing() -> void:
	# Permanence is a property of a running world, not of the file cabinet: deleting
	# one record leaves the world it was written from exactly as it was.
	_play_a_while()
	_service.write_slot(0, _service.capture())
	_service.delete_slot(0)
	assert_true(_world_state.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "the live world is untouched")


# --- Reading the hostile cases ----------------------------------------------


func test_reading_a_slot_that_is_not_there_is_an_error() -> void:
	var result := _service.read_slot(4)
	assert_false(result.ok)
	assert_null(result.model)
	assert_eq(result.errors.size(), 1)
	assert_eq(result.migrated_from, -1)


func test_a_corrupt_file_fails_as_data_not_as_a_crash() -> void:
	_install_fixture(FIXTURE_CORRUPT, 0)
	var result := _service.read_slot(0)
	assert_false(result.ok, "gibberish is not a save")
	assert_null(result.model)
	assert_true(result.errors.size() > 0)


func test_a_save_from_a_newer_build_is_refused() -> void:
	_install_fixture(FIXTURE_FUTURE, 0)
	var result := _service.read_slot(0)
	assert_false(result.ok, "a v99 save is never loaded, migrated, or written back")
	assert_eq(result.migrated_from, 99, "the result still reports what was on disk")
	assert_true(str(result.errors).contains("99"), "the problem names the version: %s" % str(result.errors))


func test_a_save_with_a_field_missing_is_refused() -> void:
	_install_fixture(FIXTURE_NO_WORLD_STATE, 0)
	var result := _service.read_slot(0)
	assert_false(result.ok, "a save missing a required field does not half-load")
	assert_true(str(result.errors).contains(SaveModel.FIELD_WORLD_STATE))


func test_the_blank_fixture_reads_as_a_blank_model() -> void:
	_install_fixture(FIXTURE_BLANK, 0)
	var result := _service.read_slot(0)
	if not assert_true(result.ok, "%s" % str(result.errors)):
		return
	assert_eq(result.model.to_dictionary(), SaveModel.blank().to_dictionary())
	assert_eq(result.migrated_from, 1)


# --- Applying ----------------------------------------------------------------


func test_the_played_fixture_reads_and_restores_a_whole_playthrough() -> void:
	_install_fixture(FIXTURE_PLAYED, 0)
	var result := _service.read_slot(0)
	if not assert_true(result.ok, "the fixture reads: %s" % str(result.errors)):
		return

	# A load fills a FRESH world; the service that read the file is not required to be
	# the one that applies it (see SaveService's class doc on what the Regions round owes).
	var world := _fresh_world()
	var loader := SaveService.new(world, GameClock.new(), _saves_dir)
	var problems := loader.apply(result.model)
	if not assert_eq(problems.size(), 0, "the fixture applies cleanly: %s" % str(problems)):
		return

	assert_true(world.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND))
	assert_true(world.is_fired(WorldStateIds.WS_PRIESTESS_UNBOUND))
	assert_true(world.is_fired(WorldStateIds.WS_EMPRESS_UNBOUND))
	assert_true(world.is_fired(WorldStateIds.WS_TROUPE_TRAVELING), "the branch flag came back too")
	assert_false(world.is_fired(WorldStateIds.WS_TROUPE_SETTLED), "and the branch not taken did not")
	assert_eq(world.fired_by(WorldStateIds.WS_PRIESTESS_UNBOUND), &"MQ02")
	assert_eq(
		world.reading_order(),
		[
			WorldStateIds.WS_MAGICIAN_UNBOUND,
			WorldStateIds.WS_PRIESTESS_UNBOUND,
			WorldStateIds.WS_EMPRESS_UNBOUND
		],
		"the Fool's Reading came back in order"
	)
	assert_eq(world.unbound_count(), 3, "the branch flag does not count toward the act")
	assert_eq(world.renown(Suit.Id.CUPS), 12)
	assert_eq(world.renown(Suit.Id.WANDS), 5)
	assert_eq(world.renown(Suit.Id.SWORDS), 0)
	assert_eq(world.hermit_answer(), &"HERMIT_ANSWER_DONT_KNOW_YET")
	assert_true(world.npc_remembers(&"FLICK", &"MET_THE_FOOL"))
	assert_true(world.npc_remembers(&"FLICK", &"SAW_THE_SHOW_END"))
	assert_eq(world.quest_state(&"MQ01"), &"complete")
	assert_eq(world.quest_state(&"MQ02"), &"in_progress")

	assert_eq(loader.difficulty(), DifficultyMode.Id.TRIAL)
	assert_eq(loader.current_region_id(), RegionIds.PRESTIGE)
	assert_eq(loader.last_waystation_id(), RegionIds.WAYSTATION_PRESTIGE)
	assert_true(loader.has_visited_waystation(RegionIds.WAYSTATION_CLIFF))
	assert_eq(loader.visited_waystations().size(), 2, "both visited Waystations load")
	assert_almost_eq(loader.loaded_playtime_seconds, 4321.5, 0.001)


func test_a_load_does_not_rewind_the_clock() -> void:
	_install_fixture(FIXTURE_PLAYED, 0)
	var result := _service.read_slot(0)
	if not assert_true(result.ok, "%s" % str(result.errors)):
		return
	var clock := GameClock.new()
	clock.advance(7.0)
	var loader := SaveService.new(_fresh_world(), clock, _saves_dir)
	loader.apply(result.model)
	assert_almost_eq(clock.elapsed_seconds, 7.0, 0.001, "world time runs forward through a load")
	assert_almost_eq(loader.loaded_playtime_seconds, 4321.5, 0.001, "playtime is bookkeeping, not the clock")
	# The seven seconds were on the title screen, before the load. They are world time
	# and the clock keeps them; they are not play, and the save must not bill for them.
	assert_almost_eq(
		loader.capture().playtime_seconds, 4321.5, 0.001, "the seconds before the load are not playtime"
	)
	clock.advance(11.0)
	assert_almost_eq(
		loader.capture().playtime_seconds, 4332.5, 0.001, "and the seconds after it are"
	)


func test_applying_to_a_world_already_in_play_is_refused_and_changes_nothing() -> void:
	_install_fixture(FIXTURE_PLAYED, 0)
	var result := _service.read_slot(0)
	if not assert_true(result.ok, "%s" % str(result.errors)):
		return
	# This service's world has been played: firing anything makes it non-pristine.
	_world_state.fire(WorldStateIds.WS_JUSTICE_UNBOUND, &"MQ11")
	_service.set_difficulty(DifficultyMode.Id.STORY)

	var problems := _service.apply(result.model)
	assert_eq(problems.size(), 1, "a load is not a reset: %s" % str(problems))
	# The save service refuses on its own, BEFORE it hands anything to the world
	# state - which has its own refusal underneath (differently worded, so this
	# assertion tells the two apart). Belt and braces on the one rule that, if it
	# ever broke, would let a load blank a world in play.
	assert_true(str(problems).contains("fresh world"), "the save service's own guard: %s" % str(problems))
	assert_true(_world_state.is_fired(WorldStateIds.WS_JUSTICE_UNBOUND), "the world in play is untouched")
	assert_false(_world_state.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "and nothing from the save leaked in")
	assert_eq(_service.difficulty(), DifficultyMode.Id.STORY, "not even the difficulty moved")
	assert_eq(_world_state.reading_order().size(), 1)


func test_a_snapshot_this_build_cannot_read_applies_nothing() -> void:
	var model := SaveModel.blank()
	model.world_state = {
		WorldStateService.SNAPSHOT_FIRED: {"WS_NOT_A_REAL_FLAG": "MQ01"},
		WorldStateService.SNAPSHOT_READING: [],
	}
	model.difficulty_mode = DifficultyMode.Id.TRIAL
	var problems := _service.apply(model)
	assert_true(problems.size() > 0, "the world state's own all-or-nothing rule is surfaced")
	assert_eq(_service.difficulty(), DifficultyMode.DEFAULT, "a rejected save sets no field at all")


func test_applying_nothing_is_an_error_not_a_crash() -> void:
	assert_true(_service.apply(null).size() > 0)


func test_capturing_without_a_world_state_is_a_loud_nothing() -> void:
	# The mirror of apply()'s refusal, and for the same reason: a service with no world
	# state cannot describe a playthrough, and a blank model returned quietly here would
	# be written over a real save as an empty world. It is a wiring bug in this build,
	# not a bad file, so it is loud - and it is null, so nothing can write it.
	var service := SaveService.new(null, _clock, _saves_dir)
	var model: Variant = _quietly(func() -> Variant: return service.capture())
	assert_null(model, "a service with no world has no playthrough to capture")
	var problems: PackedStringArray = service.write_slot(0, model as SaveModel)
	assert_true(problems.size() > 0, "and what came back is refused by the writer")
	assert_false(service.slot_exists(0), "so nothing reached the disk")


# --- Construction ------------------------------------------------------------


func test_a_null_migration_chain_falls_back_to_the_shipping_one() -> void:
	# The default argument only applies when the parameter is omitted. A caller that
	# passes null explicitly must not end up with a service that can read nothing.
	var service := SaveService.new(_world_state, _clock, _saves_dir, null)
	assert_eq(service.write_slot(0, service.capture()).size(), 0, "it writes")
	assert_true(service.read_slot(0).ok, "and it reads back through a real chain")


# --- Signals -----------------------------------------------------------------


func test_a_write_and_a_read_announce_themselves() -> void:
	watch_signal(_service, &"slot_written")
	watch_signal(_service, &"slot_read")
	_service.write_slot(0, _service.capture())
	_service.read_slot(0)
	assert_signal_emitted(_service, &"slot_written", 1)
	assert_eq(signal_arguments(_service, &"slot_written", 0), [0], "the signal carries the slot")
	assert_signal_emitted(_service, &"slot_read", 1)


func test_a_failure_announces_itself_with_its_diagnostics() -> void:
	watch_signal(_service, &"slot_failed")
	watch_signal(_service, &"slot_read")
	_service.read_slot(9)
	assert_signal_emitted(_service, &"slot_failed", 1)
	assert_signal_emitted(_service, &"slot_read", 0, "a failed read is not a read")
	var arguments := signal_arguments(_service, &"slot_failed", 0)
	assert_eq(arguments[0], 9)
	assert_true((arguments[1] as PackedStringArray).size() > 0, "the signal carries the reasons")


# --- Wiring ------------------------------------------------------------------


func test_the_services_autoload_owns_a_save_service() -> void:
	var services := tree().root.get_node_or_null("Services")
	if not assert_not_null(services, "the Services autoload exists"):
		return
	var save: SaveService = services.get("save")
	if not assert_not_null(save, "Services constructed its SaveService in _ready"):
		return
	assert_eq(save.saves_dir(), SaveService.DEFAULT_SAVES_DIR, "the shipping directory")
	assert_eq(save.slot_path(0), "user://saves/slot_0.json")


## Deep equality for two JSON documents, comparing numbers numerically.
##
## `Dictionary ==` compares values by exact type, and a save that has been through
## JSON carries `12.0` where the model wrote `12` - Godot 4.7's parser has one number
## type (see `SaveModel`'s class doc). Numeric equality is the right comparison for
## two save *documents*; the strict one would only be asserting that JSON is JSON.
func _json_equal(actual: Variant, expected: Variant) -> bool:
	if actual is Dictionary and expected is Dictionary:
		var actual_dictionary := actual as Dictionary
		var expected_dictionary := expected as Dictionary
		if actual_dictionary.size() != expected_dictionary.size():
			return false
		for key: Variant in actual_dictionary:
			if not expected_dictionary.has(key):
				return false
			if not _json_equal(actual_dictionary[key], expected_dictionary[key]):
				return false
		return true
	if actual is Array and expected is Array:
		var actual_array := actual as Array
		var expected_array := expected as Array
		if actual_array.size() != expected_array.size():
			return false
		for index: int in actual_array.size():
			if not _json_equal(actual_array[index], expected_array[index]):
				return false
		return true
	if (actual is int or actual is float) and (expected is int or expected is float):
		return is_equal_approx(float(actual), float(expected))
	return actual == expected


# --- The progression services (round 6) --------------------------------------
#
# `SaveModel.pocket_spread` stopped being a reserved empty field: it carries the
# Pocket Spread, the Fortune meter and the White Rose. The properties worth pinning
# are that all three make the round trip, that the ORDER holds (which Trumps are
# held is derived from the world state, so the world has to land first), and that a
# save service built without them still writes the v1 shape.


## The generated Trumps and the authored tuning numbers the three services need.
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"


## A save service over a fresh world and a full set of progression services.
##
## Returns them all, because a test that applies a save has to look at what landed
## in each one: `[SaveService, WorldStateService, PocketSpreadService,
## FortuneService, WhiteRoseService]`.
func _progression_service(directory: String) -> Array:
	var world := _fresh_world()
	var rules := load(SPREAD_RULES_PATH) as SpreadRules
	var trumps := load(TRUMP_CATALOG_PATH) as TrumpCatalog
	var fortune := FortuneService.new(rules)
	var spread := PocketSpreadService.new(world, trumps, rules, fortune)
	var rose := WhiteRoseService.new(world, rules)
	var service := SaveService.new(world, GameClock.new(), directory, null, spread, fortune, rose)
	return [service, world, spread, fortune, rose]


func test_capture_gathers_the_spread_the_fortune_and_the_rose() -> void:
	var built := _progression_service(_saves_dir)
	var service: SaveService = built[0]
	var world: WorldStateService = built[1]
	var spread: PocketSpreadService = built[2]
	var fortune: FortuneService = built[3]
	var rose: WhiteRoseService = built[4]
	world.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	fortune.earn(FortuneService.EarnSource.DISCOVERY, 40)
	rose.use_petal()
	var model := service.capture()
	if not assert_not_null(model, "a wired service captures"):
		return
	assert_has(model.pocket_spread, SaveModel.POCKET_SPREAD_SPREAD)
	assert_has(model.pocket_spread, SaveModel.POCKET_SPREAD_FORTUNE)
	assert_has(model.pocket_spread, SaveModel.POCKET_SPREAD_ROSE)
	var stored_rose: Dictionary = model.pocket_spread[SaveModel.POCKET_SPREAD_ROSE]
	assert_eq(stored_rose[WhiteRoseService.SNAPSHOT_PETALS], 2, "the petal spent is remembered")


func test_a_service_without_the_progression_services_writes_the_v1_shape() -> void:
	# `_service` is built the way every test above it builds one: world state and a
	# clock. A save from it must still be a legal, writable v1 file.
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	var model := _service.capture()
	if not assert_not_null(model):
		return
	assert_eq(model.pocket_spread, {}, "no progression services, no progression section")
	assert_eq(model.validate(), PackedStringArray(), "and it is still a writable save")


func test_the_whole_playthrough_makes_the_round_trip() -> void:
	var written := _progression_service(_saves_dir)
	var writer: SaveService = written[0]
	var world: WorldStateService = written[1]
	var spread: PocketSpreadService = written[2]
	var fortune: FortuneService = written[3]
	var rose: WhiteRoseService = written[4]
	world.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	world.fire(WorldStateIds.WS_PRIESTESS_UNBOUND, QuestIds.MQ02)
	world.fire(WorldStateIds.WS_EMPRESS_UNBOUND, QuestIds.MQ03)
	spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.REVERSED)
	spread.assign(SpreadSlot.Id.PAST, TrumpIds.TRUMP_02, CardOrientation.Id.UPRIGHT)
	spread.set_at_waystation(true)
	spread.save_loadout("the honest build")
	fortune.earn(FortuneService.EarnSource.DISCOVERY, 40)
	rose.add_grafting()
	rose.use_petal()
	assert_eq(writer.write_slot(0, writer.capture()), PackedStringArray())

	var loaded := _progression_service(_saves_dir)
	var reader: SaveService = loaded[0]
	var read_spread: PocketSpreadService = loaded[2]
	var read_fortune: FortuneService = loaded[3]
	var read_rose: WhiteRoseService = loaded[4]
	var result := reader.read_slot(0)
	if not assert_true(result.ok, "the save reads back: %s" % str(result.errors)):
		return
	assert_eq(reader.apply(result.model), PackedStringArray(), "and applies")
	assert_eq(read_spread.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)
	assert_eq(
		read_spread.slotted(SpreadSlot.Id.PRESENT).orientation, CardOrientation.Id.REVERSED
	)
	assert_eq(read_spread.slotted(SpreadSlot.Id.PAST).trump_id, TrumpIds.TRUMP_02)
	assert_eq(read_spread.loadout_count(), 1, "the saved build came back too")
	assert_eq(read_fortune.value(), 40)
	assert_eq(read_rose.petals(), 3)
	assert_eq(read_rose.graftings(), 1)


func test_the_played_fixture_carries_a_whole_playthrough() -> void:
	# The checked-in fixture is a file from before this change plus the progression
	# section, and it has to load into the real services - which is what proves the
	# key names in it are the ones the services actually write.
	_install_fixture(FIXTURE_PLAYED, 2)
	var loaded := _progression_service(_saves_dir)
	var reader: SaveService = loaded[0]
	var spread: PocketSpreadService = loaded[2]
	var fortune: FortuneService = loaded[3]
	var rose: WhiteRoseService = loaded[4]
	var result := reader.read_slot(2)
	if not assert_true(result.ok, "the fixture reads: %s" % str(result.errors)):
		return
	var problems := reader.apply(result.model)
	if not assert_eq(problems, PackedStringArray(), "the fixture applies"):
		return
	assert_eq(spread.held_count(), 3, "three Arcana unbound is three Trumps held")
	assert_eq(spread.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)
	assert_eq(fortune.value(), 40)
	assert_eq(rose.petals(), 2)


func test_the_world_lands_before_the_spread_that_reads_it() -> void:
	# The Spread refuses to slot a Trump the Fool does not hold, and holding is read
	# out of the flags. If `apply()` filled the Spread first, this save would be
	# unloadable - so this test is the ordering, not a nicety.
	var written := _progression_service(_saves_dir)
	var writer: SaveService = written[0]
	var world: WorldStateService = written[1]
	var spread: PocketSpreadService = written[2]
	world.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var model := writer.capture()
	var loaded := _progression_service(_saves_dir)
	var reader: SaveService = loaded[0]
	var read_spread: PocketSpreadService = loaded[2]
	assert_eq(reader.apply(model), PackedStringArray())
	assert_eq(read_spread.slotted(SpreadSlot.Id.PRESENT).trump_id, TrumpIds.TRUMP_01)


func test_a_played_spread_refuses_the_load_before_anything_is_applied() -> void:
	# "A load is not a reset" has to hold for all four services or for none: a world
	# loaded into a Spread that refused would be half a playthrough.
	var written := _progression_service(_saves_dir)
	var writer: SaveService = written[0]
	var world: WorldStateService = written[1]
	var spread: PocketSpreadService = written[2]
	world.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	var model := writer.capture()

	var loaded := _progression_service(_saves_dir)
	var reader: SaveService = loaded[0]
	var read_world: WorldStateService = loaded[1]
	var read_spread: PocketSpreadService = loaded[2]
	read_spread.set_at_waystation(true)
	read_spread.save_loadout("already playing")
	var problems := reader.apply(model)
	assert_true(problems.size() > 0, "the load is refused")
	assert_true(read_world.is_pristine(), "and the world was never touched")


func test_a_failing_section_stops_the_apply_where_it_stands() -> void:
	# The contract `apply()` documents, pinned. The world lands first (the Spread
	# derives holding from the flags), so by the time a section fails the world is
	# already in - and nothing can take it out again. What must NOT happen is the
	# apply carrying on and filling the two services after the one that failed out of
	# a file this build has already judged unreadable.
	var written := _progression_service(_saves_dir)
	var writer: SaveService = written[0]
	var world: WorldStateService = written[1]
	var spread: PocketSpreadService = written[2]
	var fortune: FortuneService = written[3]
	var rose: WhiteRoseService = written[4]
	world.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, QuestIds.MQ01)
	spread.assign(SpreadSlot.Id.PRESENT, TrumpIds.TRUMP_01, CardOrientation.Id.UPRIGHT)
	fortune.earn(FortuneService.EarnSource.DISCOVERY, 40)
	rose.use_petal()
	var model := writer.capture()
	if not assert_not_null(model):
		return
	# A save whose Spread section a player's disk (or a bad edit) mangled. Fortune and
	# the Rose beside it are perfectly good, and are exactly what must not be applied.
	var progression: Dictionary = model.pocket_spread
	progression[SaveModel.POCKET_SPREAD_SPREAD] = {
		PocketSpreadService.SNAPSHOT_SLOTS: "the whole hand",
	}
	model.pocket_spread = progression

	var loaded := _progression_service(_saves_dir)
	var reader: SaveService = loaded[0]
	var read_world: WorldStateService = loaded[1]
	var read_spread: PocketSpreadService = loaded[2]
	var read_fortune: FortuneService = loaded[3]
	var read_rose: WhiteRoseService = loaded[4]
	var problems := reader.apply(model)
	assert_true(problems.size() > 0, "the malformed section is reported")
	assert_true(read_world.is_fired(WorldStateIds.WS_MAGICIAN_UNBOUND), "the world landed first")
	assert_true(read_spread.slotted(SpreadSlot.Id.PRESENT).is_empty(), "the Spread did not")
	assert_true(read_fortune.is_pristine(), "and the apply stopped: Fortune is untouched")
	assert_eq(read_fortune.value(), 0)
	assert_true(read_rose.is_pristine(), "so is the White Rose")
	assert_eq(read_rose.petals(), 3, "still the petals it was built with")


func test_a_broken_progression_section_is_reported_as_data() -> void:
	var loaded := _progression_service(_saves_dir)
	var reader: SaveService = loaded[0]
	var model := SaveModel.blank()
	model.pocket_spread = {SaveModel.POCKET_SPREAD_FORTUNE: "quite a lot"}
	var problems := reader.apply(model)
	assert_true(problems.size() > 0, "a bad section is a problem, not a crash")
