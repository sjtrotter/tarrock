extends TarrockTest

## `SaveMigrations` and `SaveSchema`: the rule that a save is never guessed at.
##
## `docs/design/technical.md` §Save system (Godot): explicit `migrate_vN_to_vN+1`
## functions run in sequence, a missing intermediate migration is a **hard failure**,
## and each migration is tested against a checked-in fixture. Round 3 ships v1, so
## the production chain is empty by definition - which is exactly why the chain itself
## is tested here with injected steps, and why
## `test_the_production_chain_covers_every_version_below_current` exists to fail the
## day `CURRENT_SCHEMA_VERSION` moves without one.

## Where an injected step leaves its mark, so a test can prove the steps ran, in
## order, and that data flows through the chain rather than being rebuilt by it.
const TRAIL := "migration_trail"

## A field only the v1 fixture carries. It must still be there at v4.
const KEEPSAKE := "keepsake"


## A save at `version` with a keepsake and an empty trail.
func _save_at(version: int) -> Dictionary:
	return {SaveModel.FIELD_SCHEMA_VERSION: version, KEEPSAKE: "kept", TRAIL: []}


## One well-behaved step: bumps the version by one and signs the trail.
func _step(data: Dictionary, from_version: int) -> Dictionary:
	var next := data.duplicate(true)
	next[SaveModel.FIELD_SCHEMA_VERSION] = from_version + 1
	(next[TRAIL] as Array).append("v%d_to_v%d" % [from_version, from_version + 1])
	return next


func _v1_to_v2(data: Dictionary) -> Dictionary:
	return _step(data, 1)


func _v2_to_v3(data: Dictionary) -> Dictionary:
	return _step(data, 2)


func _v3_to_v4(data: Dictionary) -> Dictionary:
	return _step(data, 3)


## A step that forgets to write the new version - the classic migration bug.
func _forgets_to_bump(data: Dictionary) -> Dictionary:
	return data.duplicate(true)


## A step that skips a version, which would leave the next step reading data it was
## never written for.
func _bumps_too_far(data: Dictionary) -> Dictionary:
	var next := data.duplicate(true)
	next[SaveModel.FIELD_SCHEMA_VERSION] = 3
	return next


## A step that returns something that is not a save at all.
func _returns_nonsense(_data: Dictionary) -> Variant:
	return "not a dictionary"


# --- The trivial cases -------------------------------------------------------


func test_a_save_already_at_the_target_passes_through_untouched() -> void:
	var migrations := SaveMigrations.new()
	var result := migrations.migrate(_save_at(1), 1)
	assert_true(result.ok, "no steps are needed to get from 1 to 1")
	assert_eq(result.from_version, 1)
	assert_eq(result.errors.size(), 0)
	assert_eq(result.data[KEEPSAKE], "kept")
	assert_eq((result.data[TRAIL] as Array).size(), 0, "no step ran")


func test_a_save_with_no_version_is_refused() -> void:
	var result := SaveMigrations.new().migrate({KEEPSAKE: "kept"}, 1)
	assert_false(result.ok, "a file with no schema_version is not a save this build reads")
	assert_eq(result.from_version, -1)
	assert_eq(result.errors.size(), 1)


func test_a_version_that_is_not_a_whole_number_is_refused() -> void:
	assert_false(SaveMigrations.new().migrate({SaveModel.FIELD_SCHEMA_VERSION: "1"}, 1).ok)
	assert_false(SaveMigrations.new().migrate({SaveModel.FIELD_SCHEMA_VERSION: 1.5}, 1).ok)


func test_an_unreadable_version_is_reported_with_the_value_that_was_there() -> void:
	# read_version() flattens every unreadable version to -1, so the diagnostic is the
	# only place the offending value survives - and "1" and 1.5 are different bugs in
	# whatever wrote the file.
	var worded := SaveMigrations.new().migrate({SaveModel.FIELD_SCHEMA_VERSION: "one"}, 1)
	assert_true(str(worded.errors).contains("one"), "the value is named: %s" % str(worded.errors))
	var fractional := SaveMigrations.new().migrate({SaveModel.FIELD_SCHEMA_VERSION: 1.5}, 1)
	assert_true(
		str(fractional.errors).contains("1.5"), "the fraction is named: %s" % str(fractional.errors)
	)
	assert_eq(fractional.errors.size(), 1, "one problem, not a pile")


func test_an_integral_float_version_is_read_as_a_version() -> void:
	# Every version arriving from disk is a float: JSON has one number type.
	var result := SaveMigrations.new().migrate({SaveModel.FIELD_SCHEMA_VERSION: 1.0}, 1)
	assert_true(result.ok, "a JSON-parsed v1 save migrates")
	assert_eq(result.from_version, 1)


func test_a_save_newer_than_this_build_is_never_loaded() -> void:
	var result := SaveMigrations.new().migrate(_save_at(99), 1)
	assert_false(result.ok, "a v99 save was written by a build that knew more than this one")
	assert_eq(result.from_version, 99, "the result still reports what it found")
	assert_eq(result.errors.size(), 1)
	assert_true(str(result.errors).contains("99"), "the problem names the version: %s" % str(result.errors))


# --- The chain ---------------------------------------------------------------


func test_a_chain_runs_its_steps_in_order_and_carries_the_data_through() -> void:
	var migrations := SaveMigrations.new({1: _v1_to_v2, 2: _v2_to_v3, 3: _v3_to_v4})
	var result := migrations.migrate(_save_at(1), 4)
	assert_true(result.ok, "1 -> 4 with every step present: %s" % str(result.errors))
	assert_eq(result.from_version, 1)
	assert_eq(SaveModel.read_version(result.data), 4)
	assert_eq(result.data[TRAIL], ["v1_to_v2", "v2_to_v3", "v3_to_v4"], "in order, each exactly once")
	assert_eq(result.data[KEEPSAKE], "kept", "a field no step touched survives the whole chain")


func test_a_chain_starts_where_the_save_is_not_where_the_chain_starts() -> void:
	var migrations := SaveMigrations.new({1: _v1_to_v2, 2: _v2_to_v3, 3: _v3_to_v4})
	var result := migrations.migrate(_save_at(3), 4)
	assert_true(result.ok)
	assert_eq(result.data[TRAIL], ["v3_to_v4"], "a v3 save does not re-run v1 and v2")


func test_a_missing_step_is_a_hard_failure_naming_the_version() -> void:
	# The rule: half-migrated data is data whose meaning nobody wrote down.
	var migrations := SaveMigrations.new({1: _v1_to_v2})
	var result := migrations.migrate(_save_at(1), 3)
	assert_false(result.ok, "no v2 -> v3 step, so a v1 save does not load")
	assert_eq(result.from_version, 1)
	assert_true(str(result.errors).contains("2"), "the problem names version 2: %s" % str(result.errors))
	assert_false(migrations.has_step(2))


func test_a_missing_first_step_is_a_hard_failure() -> void:
	var result := SaveMigrations.new({2: _v2_to_v3}).migrate(_save_at(1), 3)
	assert_false(result.ok, "the chain cannot start")
	assert_true(str(result.errors).contains("1"), "the problem names version 1: %s" % str(result.errors))


func test_a_step_that_does_not_bump_the_version_is_an_error() -> void:
	var result := SaveMigrations.new({1: _forgets_to_bump}).migrate(_save_at(1), 2)
	assert_false(result.ok, "a step that leaves the version alone would loop forever")
	assert_eq(result.errors.size(), 1)


func test_a_step_that_bumps_too_far_is_an_error() -> void:
	var result := SaveMigrations.new({1: _bumps_too_far, 2: _v2_to_v3}).migrate(_save_at(1), 3)
	assert_false(result.ok, "each step advances by exactly one, or the next reads data it never saw")


func test_a_step_that_returns_something_else_is_an_error() -> void:
	var result := SaveMigrations.new({1: _returns_nonsense}).migrate(_save_at(1), 2)
	assert_false(result.ok, "GDScript cannot throw, so a broken step returns junk instead")
	assert_eq(result.errors.size(), 1)


func test_an_unusable_step_is_treated_as_missing() -> void:
	var result := SaveMigrations.new({1: "not a callable"}).migrate(_save_at(1), 2)
	assert_false(result.ok, "a table entry that is not a Callable is not a migration")


func test_migrating_never_modifies_the_callers_dictionary() -> void:
	var original := _save_at(1)
	var result := SaveMigrations.new({1: _v1_to_v2}).migrate(original, 2)
	assert_true(result.ok)
	assert_eq(SaveModel.read_version(original), 1, "the caller still holds its v1 save")
	assert_eq((original[TRAIL] as Array).size(), 0)


func test_a_failed_chain_reports_and_returns_nothing_loadable() -> void:
	var result := SaveMigrations.new({1: _v1_to_v2}).migrate(_save_at(1), 3)
	assert_false(result.ok)
	assert_true(result.errors.size() > 0, "a failure always says why")
	assert_ne(SaveModel.read_version(result.data), 3, "the half-migrated data is not at the target")


func test_the_chain_is_copied_so_it_cannot_change_underneath_a_migration() -> void:
	var steps := {1: _v1_to_v2}
	var migrations := SaveMigrations.new(steps)
	steps.erase(1)
	assert_true(migrations.has_step(1), "the chain kept its own copy of the table")


# --- The production chain ----------------------------------------------------


func test_the_production_chain_covers_every_version_below_current() -> void:
	# THE STRUCTURAL GUARD. The day someone bumps SaveModel.CURRENT_SCHEMA_VERSION,
	# this fails until they add the step that reads the version they left behind -
	# which is the whole "a missing migration is a test failure" rule, compiled.
	var steps := SaveSchema.production_steps()
	var migrations := SaveMigrations.new(steps)
	for version: int in range(1, SaveSchema.CURRENT_VERSION):
		assert_true(migrations.has_step(version), "no shipped migration from save version %d" % version)
	assert_eq(
		steps.size(),
		SaveSchema.CURRENT_VERSION - 1,
		"one step per version bump, and no orphans: %s" % str(steps.keys())
	)


func test_the_schema_version_is_the_models_version() -> void:
	assert_eq(SaveSchema.CURRENT_VERSION, SaveModel.CURRENT_SCHEMA_VERSION, "one number, one owner")


func test_a_current_save_needs_no_production_step_at_all() -> void:
	var migrations := SaveMigrations.new(SaveSchema.production_steps())
	var result := migrations.migrate(SaveModel.blank().to_dictionary(), SaveSchema.CURRENT_VERSION)
	assert_true(result.ok, "a save this build wrote loads without migrating: %s" % str(result.errors))
	assert_eq(result.from_version, SaveSchema.CURRENT_VERSION)
