extends TarrockTest

## `TarrockDefinition`, the base every content resource inherits.


func test_a_definition_without_an_id_is_invalid() -> void:
	var definition := TarrockDefinition.new()
	var errors := definition.validate()
	assert_eq(errors.size(), 1, "an empty id is exactly one error")
	assert_has(errors[0], "empty id")
	assert_false(definition.is_valid())


func test_a_definition_with_an_id_is_valid() -> void:
	var definition := TarrockDefinition.new()
	definition.id = &"MQ00"
	assert_eq(definition.validate().size(), 0)
	assert_true(definition.is_valid())


func test_id_is_a_string_name() -> void:
	# IDs are StringNames so comparisons are pointer-cheap in hot loops and a
	# typo is visible at the call site rather than in a dictionary miss.
	var definition := TarrockDefinition.new()
	definition.id = &"the_cliff"
	assert_true(definition.id is StringName)
	assert_eq(definition.id, &"the_cliff")


func test_definitions_round_trip_through_a_resource_file() -> void:
	# Definitions are authored as .tres; a subclass that forgets @export loses
	# its data here rather than in a save file three rounds later.
	var definition := TarrockDefinition.new()
	definition.id = &"WS_EMPRESS_UNBOUND"
	var path := "user://definition_round_trip_test.tres"
	assert_eq(ResourceSaver.save(definition, path), OK)
	var loaded: TarrockDefinition = ResourceLoader.load(
		path, "", ResourceLoader.CACHE_MODE_IGNORE
	) as TarrockDefinition
	if not assert_not_null(loaded, "the saved definition loads back"):
		return
	assert_eq(loaded.id, &"WS_EMPRESS_UNBOUND")
	assert_true(loaded.is_valid())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_validate_reports_where_the_problem_is() -> void:
	var definition := TarrockDefinition.new()
	var errors := definition.validate()
	assert_true(
		errors[0].contains("TarrockDefinition") or errors[0].contains("res://"),
		"the error names the offending resource: %s" % errors[0]
	)
