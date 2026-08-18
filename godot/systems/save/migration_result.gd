class_name MigrationResult
extends RefCounted

## What `SaveMigrations.migrate()` hands back: the raw save data at the current
## version, or the reasons it could not get there.
##
## A small typed carrier rather than a Dictionary of loose keys, so a caller that
## forgets to check `ok` is reading a field that does not exist rather than a `null`
## it can limp along with.

## True only when `data` reached the target version. False means `data` is whatever
## the migration got to before it stopped, and must not be loaded.
var ok: bool = false

## The raw save Dictionary at the target version when `ok`; otherwise untrustworthy.
var data: Dictionary = {}

## Every problem found, as developer diagnostics. Empty exactly when `ok`.
var errors: PackedStringArray = PackedStringArray()

## The schema version the data carried on the way in, for reporting and for
## `SaveReadResult.migrated_from`. -1 when it had no readable version at all.
var from_version: int = -1


## Build a result. Callers use `SaveMigrations.migrate()`; this constructor is public
## only because a test injecting its own migration chain wants to assert against one.
func _init(
	was_ok: bool = false,
	migrated_data: Dictionary = {},
	problems: PackedStringArray = PackedStringArray(),
	found_version: int = -1
) -> void:
	ok = was_ok
	data = migrated_data
	errors = problems
	from_version = found_version
