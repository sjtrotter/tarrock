class_name SaveService
extends RefCounted

## Saving and loading a playthrough: capture the live services into a `SaveModel`,
## write it as versioned JSON, read it back through the migration chain.
##
## `docs/design/technical.md` §Save system (Godot) is canon. The properties that
## matter, and where each one is enforced:
##
##   * **Versioned JSON, ids only.** `SaveModel` is the shape; nothing here writes a
##     resource path or an object.
##   * **A save newer than this build never loads, and a missing migration is a hard
##     failure.** `SaveMigrations`.
##   * **A write is atomic, and the temp file is checked before it is promoted.** The
##     file is written to `<path>.tmp`, the stream's error is read, the bytes on disk
##     are counted against the payload, and only then is it renamed over the real one.
##     A power cut, a full disk or a short write leaves the previous save intact rather
##     than a half-written file that reads as a corrupt playthrough.
##   * **A load is not a reset.** `apply()` refuses any world that has already been
##     played: `WorldStateService.restore_snapshot()` only fills a pristine service,
##     because a public call that could blank a world in play would be the un-fire the
##     whole design exists to make impossible.
##   * **Bad input is data, not a crash.** Every failure comes back as a
##     `PackedStringArray` of developer diagnostics or a `SaveReadResult`; nothing here
##     pushes an error or asserts on a file a player's disk handed it. Two exceptions,
##     both about *this build* being wired wrong rather than about a player's disk:
##     `capture()` with no world state pushes an error and returns null, and the engine
##     itself may log when creating the save directory genuinely fails - `write_slot()`
##     only asks for the directory when it is not already there, so the ordinary path
##     is silent, but a `make_dir_recursive_absolute()` that fails logs from inside the
##     engine and no caller can mute it.
##
## OWED TO THE REGIONS ROUND (round 10): loading from the title screen means building
## a *fresh* `WorldStateService` (and the rest) and applying the model to that, then
## swapping the persistent layer over to it - `apply()` deliberately cannot rescue an
## already-played service. The composition root has no "restart the world" call yet;
## the round that owns the persistent layer and scene switching writes it.
##
## OWED TO LATER ROUNDS: `current_region_id`, `last_waystation_id` and the difficulty
## mode live here as plain settable fields for now. The Regions round owns where the
## Fool actually is, and the combat/settings rounds own the difficulty; when they
## exist, `capture()` asks them instead and the setters go away.

## A slot was written to disk.
signal slot_written(slot: int)

## A slot was read and is loadable.
signal slot_read(slot: int)

## A slot could not be written or read. Carries the same diagnostics the call
## returned, for a debug overlay or a log sink that is not the caller.
signal slot_failed(slot: int, errors: PackedStringArray)

## Where saves live when nobody says otherwise (`technical.md`: `user://saves/`).
const DEFAULT_SAVES_DIR := "user://saves"

## `slot_<n>.json` - the whole file-naming scheme, spelled once.
const SLOT_PREFIX := "slot_"
const SLOT_EXTENSION := ".json"

## The half-written file an atomic write renames from. Deliberately NOT `.json`, so a
## crashed write cannot be mistaken for a slot by `list_slots()`.
const TEMP_EXTENSION := ".tmp"

## Save files are indented so a human can read one in a bug report.
const JSON_INDENT := "\t"

var _world_state: WorldStateService = null
var _clock: GameClock = null
var _saves_dir: String = DEFAULT_SAVES_DIR
var _migrations: SaveMigrations = null

var _current_region_id: StringName = SaveModel.UNSET
var _last_waystation_id: StringName = SaveModel.UNSET
var _difficulty_mode: DifficultyMode.Id = DifficultyMode.DEFAULT

## Seconds of play carried in from the loaded save. `GameClock` is world time and is
## never rewound by a load, so total playtime is this plus the clock *since the load*
## (see `capture()` and `_playtime_baseline`).
var loaded_playtime_seconds: float = 0.0

## The clock reading at the moment the loaded save's playtime was adopted. Only the
## seconds after this one belong to this session: a player who sat on the title screen
## for ten minutes before pressing Continue did not play for ten minutes, and without
## this baseline those minutes would be added to the save's counter on the next write.
var _playtime_baseline: float = 0.0


## Build the service over the live world state and clock.
##
## `saves_dir` is a parameter so a test can write into a scratch directory instead of
## the player's; `migrations` is a parameter so a test can inject a synthetic chain.
## The defaults are the shipping configuration, and an explicit null for `migrations`
## falls back to them too: a service with no chain at all could not read any save, and
## silently reading nothing is worse than ignoring a caller's null.
func _init(
	world_state: WorldStateService,
	clock: GameClock,
	saves_dir: String = DEFAULT_SAVES_DIR,
	migrations: SaveMigrations = null
) -> void:
	_world_state = world_state
	_clock = clock
	_saves_dir = saves_dir
	_migrations = migrations if migrations != null else SaveMigrations.new(SaveSchema.production_steps())


## The directory this service reads and writes.
func saves_dir() -> String:
	return _saves_dir


## The file one slot lives in.
func slot_path(slot: int) -> String:
	return _saves_dir.path_join("%s%d%s" % [SLOT_PREFIX, slot, SLOT_EXTENSION])


# --- Capturing and applying --------------------------------------------------


## The live game as a save model, ready to write - or null when there is no game.
##
## A service with no world state cannot describe a playthrough, and returning a blank
## model would write an empty world over a real save. That is a wiring bug in this
## build rather than a bad file on a player's disk, so it is the one capture failure
## that pushes an error: it must not be swallowed and it must not be written.
##
## `playtime_seconds` is `loaded_playtime_seconds` plus the seconds the clock has run
## *since the load* (`_playtime_baseline`), so it accumulates across sessions rather
## than restarting at each load, and does not bill the player for a title screen they
## left open. It is bookkeeping and nothing reads it as game time: `GameClock` is
## *world* time, scaled by `Engine.time_scale` (see its class doc), so this counter
## drifts from wall-clock play during slow-motion. A true wall-clock playtime counter,
## if the Almanack ever wants one, is owed and belongs to whoever adds that screen.
func capture() -> SaveModel:
	if _world_state == null:
		push_error("this save service has no world state to capture a save from")
		return null
	var model := SaveModel.new()
	model.schema_version = SaveModel.CURRENT_SCHEMA_VERSION
	model.world_state = _world_state.to_snapshot()
	model.current_region_id = _current_region_id
	model.last_waystation_id = _last_waystation_id
	model.difficulty_mode = _difficulty_mode
	model.playtime_seconds = loaded_playtime_seconds + _session_seconds()
	return model


## Restore a model into the live services. Returns every problem; empty means loaded.
##
## Refused, changing nothing, unless the world state is pristine - a world nobody has
## played yet. A load builds a fresh service and fills it; it never overwrites a world
## in play (see the class doc, and `WorldStateService.restore_snapshot()`).
##
## The world state goes in all-or-nothing: if the snapshot has any problem in it,
## nothing at all is applied - not the flags, not the difficulty, not the region - so
## a rejected save leaves the game exactly as it was.
##
## The clock is NOT rewound. In-game time runs forward through a load; the save's
## playtime is bookkeeping and lands in `loaded_playtime_seconds`, with the clock's
## reading at this moment kept as the baseline the next `capture()` counts from.
func apply(model: SaveModel) -> PackedStringArray:
	var errors := PackedStringArray()
	if model == null:
		errors.append("there is no model to apply")
		return errors
	if _world_state == null:
		errors.append("this save service has no world state to apply a save to")
		return errors
	if not _world_state.is_pristine():
		errors.append("a save loads into a fresh world; this one has already been played")
		return errors
	var problems := _world_state.restore_snapshot(model.world_state)
	if not problems.is_empty():
		errors.append_array(problems)
		return errors
	_current_region_id = model.current_region_id
	_last_waystation_id = model.last_waystation_id
	_difficulty_mode = model.difficulty_mode
	loaded_playtime_seconds = model.playtime_seconds
	_playtime_baseline = 0.0 if _clock == null else _clock.elapsed_seconds
	return errors


# --- The fields the later rounds will take over ------------------------------


## The region the Fool is in, as `capture()` will record it.
func current_region_id() -> StringName:
	return _current_region_id


## Record which region the Fool is in. The Regions round takes this over.
func set_current_region(region_id: StringName) -> void:
	_current_region_id = region_id


## The Waystation the Fool last rested at, as `capture()` will record it.
func last_waystation_id() -> StringName:
	return _last_waystation_id


## Record which Waystation the Fool last rested at. The Regions round takes this over.
func set_last_waystation(waystation_id: StringName) -> void:
	_last_waystation_id = waystation_id


## The difficulty this playthrough is being played at.
func difficulty() -> DifficultyMode.Id:
	return _difficulty_mode


## Set the difficulty mode. The combat/settings rounds take this over.
func set_difficulty(mode: DifficultyMode.Id) -> void:
	_difficulty_mode = mode


# --- Slots on disk -----------------------------------------------------------


## Write a model to a slot. Returns every problem; empty means written.
##
## The model is validated first: an invalid model is never written, because the moment
## it is on disk it is indistinguishable from a save the player earned.
##
## The write is atomic *and checked*. The payload goes to a temp file; the stream's
## error is read before the handle closes and the bytes that landed are counted against
## the bytes the payload holds; only a temp file that is whole is renamed over the slot.
## Every failure removes the temp file and returns, so the save the player already
## earned survives a disk that filled up, a path something else is sitting on, and a
## write the OS only half took - the three ways this can go wrong that a bare
## `store_string()` reports by saying nothing at all.
func write_slot(slot: int, model: SaveModel) -> PackedStringArray:
	var errors := PackedStringArray()
	if model == null:
		errors.append("there is no model to write")
		return _failed(slot, errors)
	if slot < 0:
		errors.append("a save slot is never negative: %d" % slot)
		return _failed(slot, errors)
	errors.append_array(model.validate())
	if not errors.is_empty():
		return _failed(slot, errors)

	# Asked for only when it is missing: the engine logs from inside
	# `make_dir_recursive_absolute()` when it fails, and the ordinary save - into a
	# directory that has been there since the first write - must not go near it.
	if not DirAccess.dir_exists_absolute(_saves_dir):
		var made := DirAccess.make_dir_recursive_absolute(_saves_dir)
		if made != OK and not DirAccess.dir_exists_absolute(_saves_dir):
			errors.append("cannot create the save directory %s (error %d)" % [_saves_dir, made])
			return _failed(slot, errors)

	var path := slot_path(slot)
	var temp_path := path + TEMP_EXTENSION
	var payload := JSON.stringify(model.to_dictionary(), JSON_INDENT)
	var expected_bytes := payload.to_utf8_buffer().size()

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		errors.append("cannot write %s (error %d)" % [temp_path, FileAccess.get_open_error()])
		return _failed(slot, errors)
	file.store_string(payload)
	var stored := file.get_error()
	file.close()
	if stored != OK:
		DirAccess.remove_absolute(temp_path)
		errors.append("cannot write %s (error %d)" % [temp_path, stored])
		return _failed(slot, errors)

	var written_bytes := _file_length(temp_path)
	if written_bytes != expected_bytes:
		DirAccess.remove_absolute(temp_path)
		errors.append("%s holds %d bytes, not the %d the save needs" % [temp_path, written_bytes, expected_bytes])
		return _failed(slot, errors)

	var renamed := DirAccess.rename_absolute(temp_path, path)
	if renamed != OK:
		DirAccess.remove_absolute(temp_path)
		errors.append("cannot move %s onto %s (error %d)" % [temp_path, path, renamed])
		return _failed(slot, errors)
	slot_written.emit(slot)
	return errors


## Read a slot: the file, then JSON, then the migration chain, then validation.
##
## Never crashes and never half-loads. A missing file, a file of gibberish, a file
## from a newer build and a file this build has no migration for all come back as a
## `SaveReadResult` with `ok` false and the reasons in `errors`.
func read_slot(slot: int) -> SaveReadResult:
	var errors := PackedStringArray()
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		errors.append("there is no save at %s" % path)
		return _read_failed(slot, errors, -1)
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		errors.append("cannot read %s (error %d)" % [path, FileAccess.get_open_error()])
		return _read_failed(slot, errors, -1)

	var json := JSON.new()
	if json.parse(text) != OK:
		errors.append("%s is not valid JSON on line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return _read_failed(slot, errors, -1)
	if not (json.data is Dictionary):
		errors.append("%s does not hold a save object" % path)
		return _read_failed(slot, errors, -1)

	var result := _migrations.migrate(json.data as Dictionary, SaveSchema.CURRENT_VERSION)
	if not result.ok:
		errors.append_array(result.errors)
		return _read_failed(slot, errors, result.from_version)
	errors.append_array(SaveModel.validate_dictionary(result.data))
	if not errors.is_empty():
		return _read_failed(slot, errors, result.from_version)

	var model := SaveModel.from_dictionary(result.data)
	slot_read.emit(slot)
	return SaveReadResult.new(true, model, errors, result.from_version)


## True when a slot has a save file. Says nothing about whether this build can read it.
func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Every slot with a save file, ascending. A `.tmp` file left by an interrupted write
## is not a slot and never appears here, and neither is anything else this service
## would not have written (see `_slot_from_file_name()`).
##
## THE INVARIANT: every id this returns opens with `read_slot()`. A listing that
## reported ids `slot_path()` could never produce would send a save menu to a file
## that is not there - or, worse, to a *different* player's slot.
func list_slots() -> PackedInt32Array:
	var slots := PackedInt32Array()
	var dir := DirAccess.open(_saves_dir)
	if dir == null:
		return slots
	for file_name: String in dir.get_files():
		var slot := _slot_from_file_name(file_name)
		if slot < 0:
			continue
		slots.append(slot)
	slots.sort()
	return slots


## Delete a slot's file. True when a file was there and is now gone.
##
## Deleting a save file un-fires nothing: it throws away one record of a playthrough,
## and the world inside any *other* save is untouched. The permanence rule is about
## what a running world can do to its own history (`WorldStateService`), and no call
## here can reach into that.
func delete_slot(slot: int) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK


# --- Internals ---------------------------------------------------------------


## The slot a file name names, or -1 when this service would never have written it.
##
## Round-tripped rather than parsed: the name must be exactly the one `slot_path()`
## builds for the number it parses to. That is what rejects `slot_007.json` (parses to
## 7, whose real file is `slot_7.json`), `slot_-1.json` (a negative slot, which
## `write_slot()` refuses) and `slot_.json` (no number at all) - three names an editor,
## a sync tool or a hand-copied backup can leave in the directory.
static func _slot_from_file_name(file_name: String) -> int:
	if not file_name.begins_with(SLOT_PREFIX) or not file_name.ends_with(SLOT_EXTENSION):
		return -1
	var digits := file_name.substr(
		SLOT_PREFIX.length(), file_name.length() - SLOT_PREFIX.length() - SLOT_EXTENSION.length()
	)
	if not digits.is_valid_int():
		return -1
	var slot := digits.to_int()
	if slot < 0 or file_name != "%s%d%s" % [SLOT_PREFIX, slot, SLOT_EXTENSION]:
		return -1
	return slot


## The size of a file on disk in bytes, or -1 when it cannot be opened to be measured.
## Used to check a temp file really holds the whole payload before it is promoted.
static func _file_length(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var length := int(file.get_length())
	file.close()
	return length


## Seconds the clock has run since the loaded save's playtime was adopted.
##
## Clamped at zero because `GameClock.reset()` exists: a clock put back to zero after a
## load would otherwise subtract a baseline that is now in its future and report a
## playtime that went backwards.
func _session_seconds() -> float:
	if _clock == null:
		return 0.0
	return maxf(0.0, _clock.elapsed_seconds - _playtime_baseline)


## Announce a failed write and hand the diagnostics back to the caller unchanged.
func _failed(slot: int, errors: PackedStringArray) -> PackedStringArray:
	slot_failed.emit(slot, errors)
	return errors


## Announce a failed read and wrap the diagnostics in a result.
func _read_failed(slot: int, errors: PackedStringArray, from_version: int) -> SaveReadResult:
	slot_failed.emit(slot, errors)
	return SaveReadResult.new(false, null, errors, from_version)
