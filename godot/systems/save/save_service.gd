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
##   * **The whole game is captured, not just the world.** The Pocket Spread, the
##     Fortune meter and the White Rose go into `SaveModel.pocket_spread`, and come
##     back in that order *after* the world state, because which Trumps are held is
##     derived from the flags rather than stored beside them. A section this build
##     cannot read stops the apply where it stands, leaving the services partly
##     loaded - `apply()` spells out what a caller owes then.
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
## WHERE THE FOOL IS: `current_region_id`, `last_waystation_id` and the Waystations
## visited are held here as fields and written through the setters below, by
## `RegionService` and by nothing else. They are not duplicated in that service: the
## save model is the one home for the fact, so a playthrough and its save cannot
## disagree about where the Fool was standing. They travel as one `regions` section of
## the file (`SaveModel.FIELD_REGIONS`).
##
## OWED TO A LATER ROUND: the difficulty mode is still a plain settable field here;
## the settings round owns it, and when it exists `capture()` asks it instead.

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
var _spread: PocketSpreadService = null
var _fortune: FortuneService = null
var _rose: WhiteRoseService = null
var _saves_dir: String = DEFAULT_SAVES_DIR
var _migrations: SaveMigrations = null

var _current_region_id: StringName = SaveModel.UNSET
var _last_waystation_id: StringName = SaveModel.UNSET
var _visited_waystations: Array[StringName] = []
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
##
## The three progression services are optional in the same spirit: a test that only
## cares about the world state builds a save service without them, and the
## `pocket_spread` field then stays the empty Dictionary a v1 file has always
## carried. The composition root always passes all three.
func _init(
	world_state: WorldStateService,
	clock: GameClock,
	saves_dir: String = DEFAULT_SAVES_DIR,
	migrations: SaveMigrations = null,
	spread: PocketSpreadService = null,
	fortune: FortuneService = null,
	rose: WhiteRoseService = null
) -> void:
	_world_state = world_state
	_clock = clock
	_saves_dir = saves_dir
	_migrations = migrations if migrations != null else SaveMigrations.new(SaveSchema.production_steps())
	_spread = spread
	_fortune = fortune
	_rose = rose


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
	model.pocket_spread = _capture_progression()
	model.current_region_id = _current_region_id
	model.last_waystation_id = _last_waystation_id
	model.visited_waystations = _visited_waystations.duplicate()
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
## **The progression sections are NOT all-or-nothing, and cannot be.** The world
## lands first, because the Spread derives which Trumps are held from the flags and a
## Spread filled before its world would reject every card in it. By the time a
## progression section is read, the world is already in these services and no public
## call can take it out again (a flag never un-fires). So this is the contract, and
## the reason the four services are not one transaction:
##
##   * every service is checked for pristineness BEFORE anything is applied, so the
##     ordinary "you are already playing" refusal still changes nothing at all;
##   * but a save whose *contents* a progression section rejects - a malformed
##     section, a slot naming a Trump the flags do not grant - stops the apply at the
##     first section that failed. The world is loaded, the earlier sections are
##     loaded, the later ones are untouched, and the errors say which;
##   * **a caller that gets a non-empty result must throw these services away and
##     rebuild the composition root before retrying.** Applying a second model on top
##     is refused anyway (nothing here is pristine any more), and a partly-loaded set
##     of services is not a playthrough. The Regions round (round 10), which owns
##     building a fresh world for a load from the title screen, is where that rebuild
##     lives; until then a caller has one attempt.
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
	errors.append_array(_progression_not_pristine())
	if not errors.is_empty():
		return errors
	var problems := _world_state.restore_snapshot(model.world_state)
	if not problems.is_empty():
		errors.append_array(problems)
		return errors
	errors.append_array(_apply_progression(model.pocket_spread))
	if not errors.is_empty():
		return errors
	_current_region_id = model.current_region_id
	_last_waystation_id = model.last_waystation_id
	_visited_waystations = model.visited_waystations.duplicate()
	_difficulty_mode = model.difficulty_mode
	loaded_playtime_seconds = model.playtime_seconds
	_playtime_baseline = 0.0 if _clock == null else _clock.elapsed_seconds
	return errors


## The Spread, the Fortune meter and the White Rose, in one JSON-safe Dictionary.
##
## A service this build was not given contributes nothing rather than an empty
## section, so a save written without them is byte-identical to the v1 files that
## predate this round.
func _capture_progression() -> Dictionary:
	var progression: Dictionary = {}
	if _spread != null:
		progression[SaveModel.POCKET_SPREAD_SPREAD] = _spread.to_snapshot()
	if _fortune != null:
		progression[SaveModel.POCKET_SPREAD_FORTUNE] = _fortune.to_snapshot()
	if _rose != null:
		progression[SaveModel.POCKET_SPREAD_ROSE] = _rose.to_snapshot()
	return progression


## Every progression service that has already been played, as problems.
##
## Checked BEFORE anything is restored, alongside the world state's own pristine
## rule: "a load is not a reset" has to hold for all four services or for none, and
## finding out halfway through would leave a world loaded into a Spread that is not.
func _progression_not_pristine() -> PackedStringArray:
	var errors := PackedStringArray()
	if _spread != null and not _spread.is_pristine():
		errors.append("a save loads into a fresh Spread; this one has already been played")
	if _fortune != null and not _fortune.is_pristine():
		errors.append("a save loads into a fresh Fortune meter; this one is already in play")
	if _rose != null and not _rose.is_pristine():
		errors.append("a save loads into a fresh White Rose; this one is already in play")
	return errors


## Restore the three progression sections, stopping at the first one that fails.
##
## Order matters: the Spread reads which Trumps are held out of the world state, so
## `apply()` restores the world first and this runs after it. A save with no
## `pocket_spread` sections at all - every v1 file written before this round - is a
## playthrough with no progression yet, not a problem.
##
## A section that reports a problem STOPS the apply. Carrying on would fill the
## remaining services out of a file this build has already judged unreadable, and
## would bury the one section that actually failed under whatever the next two made
## of it. The services are left partly loaded on purpose, and `apply()`'s doc says
## what the caller owes in that case: rebuild, do not retry.
func _apply_progression(progression: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if _spread != null and progression.has(SaveModel.POCKET_SPREAD_SPREAD):
		errors.append_array(
			_spread.restore_snapshot(_section(progression, SaveModel.POCKET_SPREAD_SPREAD, errors))
		)
		if not errors.is_empty():
			return errors
	if _fortune != null and progression.has(SaveModel.POCKET_SPREAD_FORTUNE):
		errors.append_array(
			_fortune.restore_snapshot(_section(progression, SaveModel.POCKET_SPREAD_FORTUNE, errors))
		)
		if not errors.is_empty():
			return errors
	if _rose != null and progression.has(SaveModel.POCKET_SPREAD_ROSE):
		errors.append_array(
			_rose.restore_snapshot(_section(progression, SaveModel.POCKET_SPREAD_ROSE, errors))
		)
	return errors


## One section of the progression payload; an empty one, with the problem recorded,
## when the file holds something that is not a Dictionary there.
func _section(progression: Dictionary, key: String, errors: PackedStringArray) -> Dictionary:
	var value: Variant = progression.get(key, {})
	if value is Dictionary:
		return value
	errors.append("save field pocket_spread.%s is not a dictionary" % key)
	return {}


# --- Where the Fool is (the `regions` section) --------------------------------


## The region the Fool is, as `capture()` will record it.
func current_region_id() -> StringName:
	return _current_region_id


## Record which region the Fool is in. Called by `RegionService` and by nothing else:
## the Fool's position is one fact, it lives in the save model, and the region service
## drives it (see that service's class doc).
func set_current_region(region_id: StringName) -> void:
	_current_region_id = region_id


## The Waystation the Fool last rested at, as `capture()` will record it.
func last_waystation_id() -> StringName:
	return _last_waystation_id


## Record which Waystation the Fool last rested at - where a defeat wakes them
## (`docs/design/combat.md` §Defeat). Called by `RegionService.rest_at()`.
func set_last_waystation(waystation_id: StringName) -> void:
	_last_waystation_id = waystation_id


## Every Waystation the Fool has rested at, in the order they were first used.
func visited_waystations() -> Array[StringName]:
	return _visited_waystations.duplicate()


## True when the Fool has rested at this Waystation at least once - the condition fast
## travel reads (`docs/design/progression.md` §Waystations).
func has_visited_waystation(waystation_id: StringName) -> bool:
	return _visited_waystations.has(waystation_id)


## Remember that the Fool rested here. True only when **this call** added it.
##
## APPEND-ONLY, exactly like the fired-flag set and the Reading
## (`docs/design/technical.md` §Save system): there is `mark_waystation_visited` and
## there is no call anywhere that takes a Waystation back out. A shrine the Fool has
## slept at is a place they know, and knowing it is not a thing the world can undo.
func mark_waystation_visited(waystation_id: StringName) -> bool:
	if waystation_id == SaveModel.UNSET or _visited_waystations.has(waystation_id):
		return false
	_visited_waystations.append(waystation_id)
	return true


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
