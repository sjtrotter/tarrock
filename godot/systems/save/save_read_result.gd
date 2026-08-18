class_name SaveReadResult
extends RefCounted

## What `SaveService.read_slot()` hands back: a loadable model, or the reasons there
## isn't one.
##
## Reading a save is the one place in the game where hostile input is normal - a file
## from an older build, a half-written file from a power cut, a file somebody edited.
## None of those may crash or half-load, so every failure arrives here as data.

## True only when `model` is a save this build can apply.
var ok: bool = false

## The loaded model when `ok`; null otherwise.
var model: SaveModel = null

## Every problem found, as developer diagnostics. Empty exactly when `ok`.
var errors: PackedStringArray = PackedStringArray()

## The `schema_version` the file on disk carried, before any migration - so a caller
## can say "this save came from an older build" and a test can assert the chain ran.
## -1 when the file had no readable version (missing, unparsable, or not a save).
var migrated_from: int = -1


## Build a result. `SaveService.read_slot()` is the intended caller.
func _init(
	was_ok: bool = false,
	loaded: SaveModel = null,
	problems: PackedStringArray = PackedStringArray(),
	found_version: int = -1
) -> void:
	ok = was_ok
	model = loaded
	errors = problems
	migrated_from = found_version
