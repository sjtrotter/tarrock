class_name SaveSchema
extends RefCounted

## The production migration table: the one place a shipped save format's history is
## written down.
##
## `docs/design/technical.md` §Save system (Godot): "each version bump ships an
## explicit `migrate_v3_to_v4`-style function, run in sequence on load until the save
## reaches the current version. A missing intermediate migration is a hard failure,
## never a best-effort guess, and each migration is tested against a checked-in
## fixture save."
##
## EVERY VERSION BUMP ADDS THREE THINGS, TOGETHER, IN ONE CHANGE:
##
##   1. `migrate_vN_to_vN_plus_1` here, registered in `production_steps()` under key
##      N, taking the raw Dictionary at version N and returning it at version N+1
##      (including setting `schema_version` - the chain checks that it did).
##   2. A fixture `res://tests/fixtures/saves/vN_*.json` written by the *old* build's
##      format, checked in and never edited afterwards.
##   3. A test in `res://tests/unit/save/` that migrates that fixture all the way to
##      `SaveModel.CURRENT_SCHEMA_VERSION` and asserts the fields it carried.
##
## `save_migrations_test.gd` fails the day someone bumps `CURRENT_SCHEMA_VERSION`
## without adding the step for the version they left behind.

## The version every save in `user://saves/` is migrated up to. The one number; the
## model owns it because the model is the shape it describes.
const CURRENT_VERSION := SaveModel.CURRENT_SCHEMA_VERSION


## `from_version -> Callable(Dictionary) -> Dictionary`, one entry per version bump.
##
## EMPTY ON PURPOSE: v1 is the first schema Tarrock ever shipped, so there is nothing
## older to migrate from. The first entry appears with v2 (see the class doc).
static func production_steps() -> Dictionary:
	return {}
