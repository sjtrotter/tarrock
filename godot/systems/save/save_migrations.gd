class_name SaveMigrations
extends RefCounted

## The migration chain: raw save data from an older build, walked up one version at a
## time until it is the shape this build reads.
##
## `docs/design/technical.md` §Save system (Godot) sets the rules, and they are all
## about refusing to guess:
##
##   * **Explicit steps only.** Each version bump ships its own function; there is no
##     generic "fill in whatever is missing" pass.
##   * **A missing intermediate step is a hard failure.** A v2 file with a v2->v3 step
##     but no v3->v4 step does not load - it is not migrated as far as it can go and
##     then hoped for. Half-migrated data is data whose meaning nobody wrote down.
##   * **A file newer than this build never loads.** It was written by a build that
##     knew fields this one does not; opening it and writing it back would silently
##     delete them.
##
## The steps are injected rather than looked up, so the production table
## (`SaveSchema.production_steps()`) and a test's synthetic chain run through exactly
## the same code.
##
## A step is a `Callable` taking the raw Dictionary at version N and returning it at
## version N+1, `schema_version` included. GDScript has no exceptions, so a step
## cannot throw; the two ways it can fail - returning something that is not a
## Dictionary, or returning one whose version did not advance by exactly one - are
## both checked after every call.

## `from_version -> Callable(Dictionary) -> Dictionary`, copied on the way in so a
## caller cannot change the chain under a migration that is already running.
var _steps: Dictionary = {}


## Build a chain over `steps`. `SaveService` passes `SaveSchema.production_steps()`;
## tests pass their own.
func _init(steps: Dictionary = {}) -> void:
	_steps = steps.duplicate()


## True when this chain knows how to move data off version `from_version`.
func has_step(from_version: int) -> bool:
	var step: Variant = _steps.get(from_version)
	return step is Callable and (step as Callable).is_valid()


## Walk `data` up to `target_version`, reporting rather than guessing.
##
## The caller's Dictionary is never modified: the chain works on a deep copy.
## `MigrationResult.ok` is true only when the data reached `target_version`; on any
## failure `data` on the result is whatever the chain reached and must not be loaded.
## Data already at the target is returned unchanged, and no step runs.
func migrate(data: Dictionary, target_version: int) -> MigrationResult:
	var errors := PackedStringArray()
	var from_version := SaveModel.read_version(data)
	if from_version < 0:
		# `read_version()` flattens every unreadable version to -1, which tells whoever
		# is holding the file nothing about what is wrong with it. The raw value goes in
		# the diagnostic instead: "1" and 1.5 and nothing at all are three different bugs.
		var raw: Variant = data.get(SaveModel.FIELD_SCHEMA_VERSION)
		errors.append("save has no readable schema_version: %s" % str(raw))
		return MigrationResult.new(false, {}, errors, from_version)
	if from_version > target_version:
		errors.append("save version %d is newer than this build reads (%d)" % [from_version, target_version])
		return MigrationResult.new(false, {}, errors, from_version)

	var current: Dictionary = data.duplicate(true)
	var version := from_version
	while version < target_version:
		if not has_step(version):
			errors.append("no migration from save version %d; this build cannot load it" % version)
			return MigrationResult.new(false, current, errors, from_version)
		var step: Callable = _steps.get(version)
		var produced: Variant = step.call(current)
		if not (produced is Dictionary):
			errors.append("the migration from save version %d returned no dictionary" % version)
			return MigrationResult.new(false, current, errors, from_version)
		current = produced as Dictionary
		var reached := SaveModel.read_version(current)
		if reached != version + 1:
			errors.append("the migration from save version %d left the save at version %d" % [version, reached])
			return MigrationResult.new(false, current, errors, from_version)
		version += 1

	return MigrationResult.new(true, current, errors, from_version)
