extends TarrockTest

## `SaveModel`: the shape of one save file.
##
## The contract being proved is `docs/design/technical.md` §Save system (Godot): a
## save is versioned JSON of ids and plain values, it survives a round trip through
## `JSON.stringify`/`parse` unchanged, and anything wrong with it is *reported* rather
## than thrown, guessed at, or written to disk.
##
## The played model is built over the real generated definitions
## (`res://data/world_states/`), because "the world state travels verbatim" is only
## worth proving against a real snapshot.

const CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## Value types a JSON document can hold. Anything else in `to_dictionary()` would
## either fail to serialise or come back as something the reader cannot use.
const JSON_TYPES: Array[int] = [
	TYPE_NIL,
	TYPE_BOOL,
	TYPE_INT,
	TYPE_FLOAT,
	TYPE_STRING,
	TYPE_ARRAY,
	TYPE_DICTIONARY,
]

var _catalog: WorldStateCatalog = null
var _world_state: WorldStateService = null


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as WorldStateCatalog
	_world_state = WorldStateService.new(
		_catalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)


## A world with some history in it: three unbindings, a branch, standing in two
## suits, the Hermit answered, one NPC who remembers, two quests underway.
func _played_world() -> WorldStateService:
	_world_state.fire(WorldStateIds.WS_MAGICIAN_UNBOUND, &"MQ01")
	_world_state.fire(WorldStateIds.WS_TROUPE_TRAVELING, &"MQ01")
	_world_state.fire(WorldStateIds.WS_PRIESTESS_UNBOUND, &"MQ02")
	_world_state.fire(WorldStateIds.WS_EMPRESS_UNBOUND, &"MQ03")
	_world_state.adjust_renown(Suit.Id.CUPS, 12, &"MQ01")
	_world_state.adjust_renown(Suit.Id.WANDS, 5, &"MQ03")
	_world_state.set_hermit_answer(&"HERMIT_ANSWER_DONT_KNOW_YET")
	_world_state.npc_remember(&"FLICK", &"MET_THE_FOOL")
	_world_state.set_quest_state(&"MQ01", &"complete")
	_world_state.set_quest_state(&"MQ02", &"in_progress")
	return _world_state


## A model of that world, with everything else on it filled in too.
func _played_model() -> SaveModel:
	var model := SaveModel.blank()
	model.world_state = _played_world().to_snapshot()
	model.current_region_id = RegionIds.PRESTIGE
	model.last_waystation_id = RegionIds.WAYSTATION_PRESTIGE
	model.visited_waystations = [RegionIds.WAYSTATION_CLIFF, RegionIds.WAYSTATION_PRESTIGE]
	model.playtime_seconds = 4321.5
	model.difficulty_mode = DifficultyMode.Id.TRIAL
	return model


## A model's dictionary, put through the exact trip a save file takes.
func _through_json(model: SaveModel) -> Dictionary:
	var text := JSON.stringify(model.to_dictionary(), "\t")
	var json := JSON.new()
	if json.parse(text) != OK:
		fail("the model did not stringify into parsable JSON")
		return {}
	return json.data as Dictionary


# --- The blank model ---------------------------------------------------------


func test_blank_is_the_current_version_at_journey() -> void:
	var model := SaveModel.blank()
	assert_eq(model.schema_version, SaveModel.CURRENT_SCHEMA_VERSION)
	assert_eq(model.difficulty_mode, DifficultyMode.DEFAULT)
	assert_eq(model.world_state, {})
	assert_eq(model.current_region_id, SaveModel.UNSET)
	assert_almost_eq(model.playtime_seconds, 0.0)
	assert_eq(model.validate().size(), 0, "a blank model is writable")


func test_the_regions_section_is_one_object_in_the_file() -> void:
	# Where the Fool is travels as one section, not as loose fields beside the world
	# state: `RegionService` owns all three and reads them back together.
	var written := SaveModel.blank().to_dictionary()
	var regions: Dictionary = written[SaveModel.FIELD_REGIONS]
	assert_eq(regions[SaveModel.REGIONS_CURRENT], "")
	assert_eq(regions[SaveModel.REGIONS_LAST_WAYSTATION], "")
	assert_eq(regions[SaveModel.REGIONS_VISITED], [], "nowhere has been rested at yet")


func test_a_regions_section_of_the_wrong_shape_is_reported() -> void:
	var data := SaveModel.blank().to_dictionary()
	data[SaveModel.FIELD_REGIONS] = {
		SaveModel.REGIONS_CURRENT: 7,
		SaveModel.REGIONS_VISITED: "WAYSTATION_CLIFF",
	}
	var errors := SaveModel.validate_dictionary(data)
	assert_eq(errors.size(), 2, "both the id and the list are wrong: %s" % str(errors))


func test_the_reserved_containers_are_empty_but_present() -> void:
	# Round 6 fills the Pocket Spread and the progression round fills the inventory.
	# They ship empty in v1 so a v1 file already carries the field they will look for.
	var written := SaveModel.blank().to_dictionary()
	assert_eq(written[SaveModel.FIELD_POCKET_SPREAD], {})
	assert_eq(written[SaveModel.FIELD_INVENTORY], {})


# --- Round-tripping ----------------------------------------------------------


func test_a_blank_model_round_trips_through_json() -> void:
	var model := SaveModel.blank()
	var reloaded := SaveModel.from_dictionary(_through_json(model))
	assert_eq(reloaded.to_dictionary(), model.to_dictionary())


func test_a_played_model_round_trips_through_json() -> void:
	var model := _played_model()
	var reloaded := SaveModel.from_dictionary(_through_json(model))
	assert_true(
		_json_equal(reloaded.to_dictionary(), model.to_dictionary()),
		"every field survives the trip: %s" % str(reloaded.to_dictionary())
	)
	assert_true(
		_json_equal(reloaded.world_state, model.world_state),
		"the world-state snapshot travels verbatim: %s" % str(reloaded.world_state)
	)
	assert_eq(reloaded.current_region_id, RegionIds.PRESTIGE)
	assert_eq(reloaded.last_waystation_id, RegionIds.WAYSTATION_PRESTIGE)
	assert_eq(
		reloaded.visited_waystations,
		[RegionIds.WAYSTATION_CLIFF, RegionIds.WAYSTATION_PRESTIGE],
		"the visited Waystations survive the trip, in order"
	)
	assert_almost_eq(reloaded.playtime_seconds, 4321.5)
	assert_eq(reloaded.difficulty_mode, DifficultyMode.Id.TRIAL)


func test_json_turns_every_number_into_a_float_and_the_model_survives_it() -> void:
	# Godot 4.7's JSON parser has one number type: `1` comes back as `1.0`. Anything
	# that read `schema_version` with `is int` would reject every save ever written.
	var parsed := _through_json(SaveModel.blank())
	assert_false(parsed[SaveModel.FIELD_SCHEMA_VERSION] is int, "JSON hands back a float")
	assert_eq(SaveModel.read_version(parsed), SaveModel.CURRENT_SCHEMA_VERSION)
	assert_eq(SaveModel.validate_dictionary(parsed).size(), 0, "an integral float is a version")


func test_the_world_state_payload_widens_to_floats_and_that_is_the_services_problem() -> void:
	# Renown is an int in the snapshot and comes back a float. The save carries the
	# payload opaquely and does NOT re-narrow it - guessing which floats were "really"
	# ints would corrupt any genuinely fractional value a later payload holds.
	# `WorldStateService.restore_snapshot()` already accepts either, which is where
	# that decision belongs (save_service_test proves the Renown survives a real file).
	var reloaded := SaveModel.from_dictionary(_through_json(_played_model()))
	var renown: Dictionary = reloaded.world_state[WorldStateService.SNAPSHOT_RENOWN]
	assert_false(renown[String(Suit.name_key(Suit.Id.CUPS))] is int, "JSON widened it")
	assert_almost_eq(float(renown[String(Suit.name_key(Suit.Id.CUPS))]), 12.0)


func test_the_difficulty_is_written_as_a_key_never_as_an_ordinal() -> void:
	var model := SaveModel.blank()
	model.difficulty_mode = DifficultyMode.Id.STORY
	var written := model.to_dictionary()
	assert_eq(written[SaveModel.FIELD_DIFFICULTY_MODE], "STORY")
	assert_false(written[SaveModel.FIELD_DIFFICULTY_MODE] is int, "an ordinal would re-point later")
	assert_eq(SaveModel.from_dictionary(written).difficulty_mode, DifficultyMode.Id.STORY)


func test_the_written_dictionary_holds_only_json_types() -> void:
	var offenders := PackedStringArray()
	_collect_non_json_types(_played_model().to_dictionary(), "", offenders)
	assert_eq(offenders.size(), 0, "only ids, numbers and plain containers: %s" % str(offenders))


func test_nothing_in_a_save_names_a_resource_or_an_object() -> void:
	# "IDs only": a save that embedded a `res://` path or an object would break the
	# day that resource moved (technical.md, Save system).
	var text := JSON.stringify(_played_model().to_dictionary(), "\t")
	assert_false(text.contains("res://"), "a save never names a resource path")
	assert_false(text.contains("Object("), "a save never names an object")


func test_the_written_dictionary_is_a_copy() -> void:
	var model := _played_model()
	var written := model.to_dictionary()
	(written[SaveModel.FIELD_WORLD_STATE] as Dictionary).clear()
	assert_true(model.world_state.size() > 0, "writing a model must not empty it")


# --- Validation --------------------------------------------------------------


func test_validate_reports_every_missing_field() -> void:
	var errors := SaveModel.validate_dictionary({})
	assert_eq(errors.size(), SaveModel.REQUIRED_FIELDS.size(), "one problem per field: %s" % str(errors))


func test_validate_reports_a_missing_world_state() -> void:
	var data := SaveModel.blank().to_dictionary()
	data.erase(SaveModel.FIELD_WORLD_STATE)
	var errors := SaveModel.validate_dictionary(data)
	assert_eq(errors.size(), 1)
	assert_true(str(errors).contains(SaveModel.FIELD_WORLD_STATE), "the problem names the field")


func test_validate_reports_a_version_this_build_does_not_read() -> void:
	var data := SaveModel.blank().to_dictionary()
	data[SaveModel.FIELD_SCHEMA_VERSION] = 99
	assert_eq(SaveModel.validate_dictionary(data).size(), 1, "a v99 save is not writable here")


func test_validate_reports_a_version_that_is_not_a_whole_number() -> void:
	var data := SaveModel.blank().to_dictionary()
	data[SaveModel.FIELD_SCHEMA_VERSION] = "one"
	assert_eq(SaveModel.validate_dictionary(data).size(), 1)
	data[SaveModel.FIELD_SCHEMA_VERSION] = 1.5
	assert_eq(SaveModel.validate_dictionary(data).size(), 1)


func test_validate_reports_containers_of_the_wrong_shape() -> void:
	for field: String in [
		SaveModel.FIELD_WORLD_STATE,
		SaveModel.FIELD_POCKET_SPREAD,
		SaveModel.FIELD_INVENTORY,
		SaveModel.FIELD_REGIONS,
	]:
		var data := SaveModel.blank().to_dictionary()
		data[field] = [1, 2, 3]
		assert_eq(SaveModel.validate_dictionary(data).size(), 1, "%s must be a dictionary" % field)


func test_validate_reports_ids_and_numbers_of_the_wrong_type() -> void:
	var data := SaveModel.blank().to_dictionary()
	data[SaveModel.FIELD_REGIONS] = {
		SaveModel.REGIONS_CURRENT: 7,
		SaveModel.REGIONS_LAST_WAYSTATION: {},
	}
	data[SaveModel.FIELD_PLAYTIME_SECONDS] = "ages"
	assert_eq(SaveModel.validate_dictionary(data).size(), 3, "three fields, three problems")


func test_validate_reports_a_difficulty_this_build_does_not_have() -> void:
	var data := SaveModel.blank().to_dictionary()
	data[SaveModel.FIELD_DIFFICULTY_MODE] = "NIGHTMARE"
	var errors := SaveModel.validate_dictionary(data)
	assert_eq(errors.size(), 1)
	assert_true(str(errors).contains("NIGHTMARE"), "the problem names the mode it found")


func test_validate_lists_problems_rather_than_stopping_at_the_first() -> void:
	var errors := SaveModel.validate_dictionary({"schema_version": 42})
	assert_true(errors.size() > 1, "a bad save reports everything wrong with it: %s" % str(errors))


func test_validate_never_pushes_an_error_or_writes_anything() -> void:
	# A bad save is data. The caller decides what to say about it; validation just
	# reports. (If this ever push_error()ed, run_all.sh would fail the suite.)
	var model := SaveModel.blank()
	model.schema_version = 3
	assert_eq(model.validate().size(), 1)
	assert_eq(model.schema_version, 3, "validation does not repair the model")


# --- Reading back ------------------------------------------------------------


func test_from_dictionary_falls_back_rather_than_failing() -> void:
	# Reporting is validate()'s job; from_dictionary is total so that one bad field
	# cannot half-build a model. Callers validate first (SaveService.read_slot).
	var model := SaveModel.from_dictionary({})
	assert_eq(model.schema_version, SaveModel.CURRENT_SCHEMA_VERSION)
	assert_eq(model.world_state, {})
	assert_eq(model.difficulty_mode, DifficultyMode.DEFAULT)
	assert_eq(model.current_region_id, SaveModel.UNSET)


func test_from_dictionary_copies_the_containers_it_was_given() -> void:
	var data := SaveModel.blank().to_dictionary()
	var model := SaveModel.from_dictionary(data)
	(data[SaveModel.FIELD_WORLD_STATE] as Dictionary)["fired"] = {}
	assert_eq(model.world_state, {}, "the model does not alias the dictionary it read")


func test_read_version_reports_minus_one_for_a_save_with_no_version() -> void:
	assert_eq(SaveModel.read_version({}), -1)
	assert_eq(SaveModel.read_version({"schema_version": "1"}), -1)
	assert_eq(SaveModel.read_version({"schema_version": 1.0}), 1, "JSON's float is a version")


func test_a_version_that_is_only_nearly_whole_is_not_a_version() -> void:
	# A version is an identity, not a measurement. `1.0000000001` is a distinct float64
	# from 1.0 - a hand-edited file, or a number that went through a float32 - and a
	# tolerant comparison would read it as v1 and load the file as though this build had
	# written it. Exact or nothing.
	assert_eq(SaveModel.read_version({"schema_version": 1.0000000001}), -1, "nearly one is not one")
	assert_eq(SaveModel.read_version({"schema_version": 0.9999999999}), -1)
	var data := SaveModel.blank().to_dictionary()
	data[SaveModel.FIELD_SCHEMA_VERSION] = 1.0000000001
	assert_eq(SaveModel.validate_dictionary(data).size(), 1, "and validate says so")


func test_the_unset_id_is_the_one_the_rest_of_the_codebase_means() -> void:
	assert_eq(SaveModel.UNSET, WorldStateService.UNSET, "one empty id, not two that match today")


# --- Internals ---------------------------------------------------------------


## Walk a written dictionary and record anything JSON could not carry.
func _collect_non_json_types(value: Variant, path: String, offenders: PackedStringArray) -> void:
	if not JSON_TYPES.has(typeof(value)):
		offenders.append("%s is a %d" % [path, typeof(value)])
		return
	if value is Dictionary:
		for key: Variant in value as Dictionary:
			if not (key is String):
				offenders.append("%s has a non-string key" % path)
			_collect_non_json_types((value as Dictionary)[key], "%s/%s" % [path, str(key)], offenders)
	elif value is Array:
		var index := 0
		for entry: Variant in value as Array:
			_collect_non_json_types(entry, "%s[%d]" % [path, index], offenders)
			index += 1


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
