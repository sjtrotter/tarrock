class_name SaveModel
extends RefCounted

## The mutable state of one playthrough, as ids and plain values.
##
## `docs/design/technical.md` §Save system (Godot) is canon: versioned JSON, IDs only,
## explicit migrations. This class is the *shape* of one save file - a plain
## `RefCounted` holding nothing but Dictionaries, Strings, numbers and bools, so that
## `to_dictionary()` is JSON-safe by construction rather than by care. It never holds
## a definition `Resource`, a node, or a `Callable`: definitions are re-resolved from
## their ids at load, and a save that embedded one would break the day a definition
## changed.
##
## The world-state payload is carried **verbatim and opaque**: `world_state` is
## whatever `WorldStateService.to_snapshot()` produced, and this class neither reads
## its keys nor validates them - the service owns that contract on the way back in
## (`WorldStateService.restore_snapshot()`), and duplicating the rules here would
## give the game two places to disagree with itself.
##
## Versioning: `schema_version` is written into every file and checked on the way in.
## `SaveMigrations` moves an older file up to `CURRENT_SCHEMA_VERSION` before this
## class is asked to read it, so `from_dictionary()` only ever sees current-shaped
## data.
##
## **JSON has one number type.** `JSON.parse_string()` in Godot 4.7 hands back a
## `float` for *every* number, including `1`, so a round-tripped `schema_version` is
## `1.0` and not `1`. Everything here that reads a number therefore accepts an
## integral float and normalises it; `to_dictionary()` still writes ints as ints so a
## save file reads the way a human expects.

## The schema this build writes, and the only one it can load without migrating.
## Every bump ships a `migrate_vN_to_vN+1` step in `SaveSchema.production_steps()`,
## a fixture under `res://tests/fixtures/saves/`, and a test that migrates it.
const CURRENT_SCHEMA_VERSION := 1

## JSON field names. Spelled once here so the writer, the reader, the validator, the
## migrations and the fixtures cannot drift apart.
const FIELD_SCHEMA_VERSION := "schema_version"
const FIELD_WORLD_STATE := "world_state"
const FIELD_POCKET_SPREAD := "pocket_spread"
const FIELD_INVENTORY := "inventory"
const FIELD_REGIONS := "regions"
const FIELD_NPC := "npc"
const FIELD_PLAYTIME_SECONDS := "playtime_seconds"
const FIELD_DIFFICULTY_MODE := "difficulty_mode"

## Every field a valid save file carries, for the shape check.
const REQUIRED_FIELDS: Array[String] = [
	FIELD_SCHEMA_VERSION,
	FIELD_WORLD_STATE,
	FIELD_POCKET_SPREAD,
	FIELD_INVENTORY,
	FIELD_REGIONS,
	FIELD_NPC,
	FIELD_PLAYTIME_SECONDS,
	FIELD_DIFFICULTY_MODE,
]

## The three fields of the `regions` section: where the Fool is standing, the
## Waystation a defeat wakes them at (`docs/design/combat.md` §Defeat), and every
## Waystation they have rested at - the set fast travel reads (`progression.md`
## §Waystations). Spelled once here so `SaveService`, `RegionService` and the fixtures
## cannot drift apart.
const REGIONS_CURRENT := "current_region_id"
const REGIONS_LAST_WAYSTATION := "last_waystation_id"
const REGIONS_VISITED := "visited_waystations"

## The three sections of `pocket_spread`. Spelled once here so the save service, the
## services that fill them and the fixtures cannot drift apart.
const POCKET_SPREAD_SPREAD := "spread"
const POCKET_SPREAD_FORTUNE := "fortune"
const POCKET_SPREAD_ROSE := "rose"

## The id an unset region / waystation / answer carries. The same constant the rest of
## the codebase means by "nothing was ever set", referenced rather than restated so
## there is one empty id in the project and not two that happen to match today.
const UNSET := WorldStateService.UNSET

## The version this file was written at.
var schema_version: int = CURRENT_SCHEMA_VERSION

## `WorldStateService.to_snapshot()`, verbatim. Opaque to this class.
var world_state: Dictionary = {}

## The progression state of one playthrough, in three sections keyed by
## `POCKET_SPREAD_SPREAD` / `_FORTUNE` / `_ROSE`: what is slotted and what loadouts
## are saved (`PocketSpreadService.to_snapshot()`), the Fortune meter
## (`FortuneService`), and the White Rose's petals and graftings
## (`WhiteRoseService`).
##
## Carried verbatim and opaque, exactly as `world_state` is: each service owns the
## contract on the way back in, and restating its keys here would give the game two
## places to disagree with itself. Which Trumps are HELD is deliberately not in
## here - that is derived from the world-state flags this same file already carries.
##
## Still a plain empty Dictionary for a playthrough with no progression yet, and for
## a build wired without those services, so a v1 file written either way reads back
## the same.
var pocket_spread: Dictionary = {}

## What the Fool has: the purse, what is carried, the staff head on the Bindle and
## the Rose-grafting sources already taken (`EconomyService.to_snapshot()`, whose
## `SNAPSHOT_*` constants name the keys).
##
## Carried verbatim and opaque, exactly as `world_state` and `pocket_spread` are:
## `EconomyService` owns the contract on the way back in, and restating its keys here
## would give the game two places to disagree with itself. What a SHOP has sold is
## deliberately not in here - that is a fact about a shop between two rests, and the
## first rest after a load puts it right (`EconomyService.restock_on_rest()`).
##
## Still a plain empty Dictionary for a playthrough that has bought nothing, and for
## a build wired without that service, so a v1 file written either way reads back the
## same.
var inventory: Dictionary = {}

## Which main quests' news is travelling, and when each one was heard of
## (`BarkService.to_snapshot()`, which is `RumorService.to_snapshot()` verbatim - see
## `RumorService.SNAPSHOT_*` for the keys).
##
## Carried verbatim and opaque, exactly as `inventory` is: `BarkService` owns the
## contract on the way back in, and restating its keys here would give the game two
## places to disagree with itself. Only the rumour SEEDS are here - which main quests
## have completed and at what clock reading - because everything else the NPC round
## can do (which barks are said, which anchor an NPC stands at, which lines were
## recently spent) is either derived from world state already in the file or is
## transient by design (`npc-system.md` §Bark layers' repeat-decay memory is a fact
## about the last few picks, not about the playthrough).
##
## Still a plain empty Dictionary for a playthrough with no completed main quest, and
## for a build wired without that service, so a v1 file written either way reads back
## the same.
var npc: Dictionary = {}

## The region the Fool is standing in, as a `RegionIds` token. Serialised inside the
## `regions` section; typed here so the model stays a shape rather than a bag.
var current_region_id: StringName = UNSET

## The Waystation the Fool last rested at - where defeat returns them
## (`docs/design/combat.md` §Defeat, `progression.md` §Waystations).
var last_waystation_id: StringName = UNSET

## Every Waystation the Fool has rested at, in the order they were first used.
##
## APPEND-ONLY, like every other container in a save (`technical.md` §Save system):
## a Waystation, once found, is found. `SaveService.mark_waystation_visited()` is the
## only thing that adds to it and nothing anywhere removes from it.
var visited_waystations: Array[StringName] = []

## Bookkeeping only: seconds of play this file represents. Nothing reads it as game
## time (`GameClock` is world time and is not rewound by a load - see `SaveService`).
var playtime_seconds: float = 0.0

## The difficulty this playthrough is being played at (`combat.md` §Difficulty modes).
## Serialised as its `DifficultyMode.name_key`, never as an enum ordinal.
var difficulty_mode: DifficultyMode.Id = DifficultyMode.DEFAULT


## A save for a playthrough that has not happened yet: current version, blank world,
## nothing carried, Journey.
static func blank() -> SaveModel:
	return SaveModel.new()


## This model as a JSON-safe Dictionary: Dictionaries, Arrays, Strings, numbers and
## bools only, nested containers copied so the caller cannot reach back in and mutate
## the model afterwards.
func to_dictionary() -> Dictionary:
	return {
		FIELD_SCHEMA_VERSION: schema_version,
		FIELD_WORLD_STATE: world_state.duplicate(true),
		FIELD_POCKET_SPREAD: pocket_spread.duplicate(true),
		FIELD_INVENTORY: inventory.duplicate(true),
		FIELD_NPC: npc.duplicate(true),
		FIELD_REGIONS: {
			REGIONS_CURRENT: String(current_region_id),
			REGIONS_LAST_WAYSTATION: String(last_waystation_id),
			REGIONS_VISITED: _ids_as_strings(visited_waystations),
		},
		FIELD_PLAYTIME_SECONDS: playtime_seconds,
		FIELD_DIFFICULTY_MODE: String(DifficultyMode.name_key(difficulty_mode)),
	}


## A model read out of a Dictionary that has already passed `validate_dictionary()`.
##
## It is deliberately total: anything missing or of the wrong type falls back to the
## blank model's value rather than failing, because the *reporting* of bad data is
## `validate_dictionary()`'s job and doing it in two places would let the two answers
## drift. Callers validate first, then read (`SaveService.read_slot()`).
static func from_dictionary(data: Dictionary) -> SaveModel:
	var model := SaveModel.new()
	model.schema_version = _as_int(data.get(FIELD_SCHEMA_VERSION), CURRENT_SCHEMA_VERSION)
	model.world_state = _as_dictionary(data.get(FIELD_WORLD_STATE))
	model.pocket_spread = _as_dictionary(data.get(FIELD_POCKET_SPREAD))
	model.inventory = _as_dictionary(data.get(FIELD_INVENTORY))
	model.npc = _as_dictionary(data.get(FIELD_NPC))
	var regions := _as_dictionary(data.get(FIELD_REGIONS))
	model.current_region_id = _as_id(regions.get(REGIONS_CURRENT))
	model.last_waystation_id = _as_id(regions.get(REGIONS_LAST_WAYSTATION))
	model.visited_waystations = _as_ids(regions.get(REGIONS_VISITED))
	model.playtime_seconds = _as_float(data.get(FIELD_PLAYTIME_SECONDS), 0.0)
	var mode := DifficultyMode.from_name_key(_as_id(data.get(FIELD_DIFFICULTY_MODE)))
	model.difficulty_mode = DifficultyMode.DEFAULT if mode == DifficultyMode.UNKNOWN else mode as DifficultyMode.Id
	return model


## Every problem with this model, as developer diagnostics. Empty means writable.
##
## Nothing here throws or pushes an error: a bad save is data, not a crash, and the
## caller decides what to do about it (`SaveService.write_slot()` refuses to write;
## `read_slot()` refuses to load).
func validate() -> PackedStringArray:
	return validate_dictionary(to_dictionary())


## The schema version a raw save Dictionary carries, or -1 when it carries none this
## build can read (missing, not a number, or a number with a fraction).
##
## The one place a version is read out of raw JSON: `validate_dictionary()` and
## `SaveMigrations` both go through here, so "what version is this file" has exactly
## one answer.
static func read_version(data: Dictionary) -> int:
	var value: Variant = data.get(FIELD_SCHEMA_VERSION)
	if not _is_whole_number(value):
		return -1
	return int(value)


## Every problem with a raw save Dictionary: version, required fields, field types,
## and a difficulty key this build knows.
##
## This is the check that matters, because the thing arriving from disk is a
## Dictionary and not a model yet - `from_dictionary()` would happily paper over
## anything wrong with it. Integral floats pass the int checks: JSON has one number
## type (see the class doc).
static func validate_dictionary(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for field: String in REQUIRED_FIELDS:
		if not data.has(field):
			errors.append("save is missing the field %s" % field)
	if data.has(FIELD_SCHEMA_VERSION):
		var version := read_version(data)
		if version < 0:
			errors.append("save schema_version is not a whole number: %s" % str(data.get(FIELD_SCHEMA_VERSION)))
		elif version != CURRENT_SCHEMA_VERSION:
			errors.append("save schema_version is %d, this build reads %d" % [version, CURRENT_SCHEMA_VERSION])
	for field: String in [
		FIELD_WORLD_STATE, FIELD_POCKET_SPREAD, FIELD_INVENTORY, FIELD_NPC, FIELD_REGIONS
	]:
		if data.has(field) and not (data.get(field) is Dictionary):
			errors.append("save field %s is not a dictionary" % field)
	errors.append_array(_validate_regions(data))
	if data.has(FIELD_PLAYTIME_SECONDS) and not _is_number(data.get(FIELD_PLAYTIME_SECONDS)):
		errors.append("save field %s is not a number" % FIELD_PLAYTIME_SECONDS)
	if data.has(FIELD_DIFFICULTY_MODE):
		var key: Variant = data.get(FIELD_DIFFICULTY_MODE)
		if not _is_text(key):
			errors.append("save field %s is not a difficulty key" % FIELD_DIFFICULTY_MODE)
		elif DifficultyMode.from_name_key(StringName(key)) == DifficultyMode.UNKNOWN:
			errors.append("save names a difficulty this build does not have: %s" % str(key))
	return errors


## Every problem with the `regions` section: the two ids and the visited list.
##
## Checked here rather than in `RegionService` for the same reason every other field
## is: what arrives from disk is a Dictionary, and `from_dictionary()` would happily
## paper over anything wrong with it.
static func _validate_regions(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not data.has(FIELD_REGIONS) or not (data.get(FIELD_REGIONS) is Dictionary):
		return errors
	var regions: Dictionary = data.get(FIELD_REGIONS)
	for field: String in [REGIONS_CURRENT, REGIONS_LAST_WAYSTATION]:
		if regions.has(field) and not _is_text(regions.get(field)):
			errors.append("save field %s.%s is not an id" % [FIELD_REGIONS, field])
	if not regions.has(REGIONS_VISITED):
		return errors
	var visited: Variant = regions.get(REGIONS_VISITED)
	if not (visited is Array):
		errors.append("save field %s.%s is not a list" % [FIELD_REGIONS, REGIONS_VISITED])
		return errors
	for entry: Variant in visited as Array:
		if not _is_text(entry):
			errors.append("save field %s.%s holds something that is not an id: %s" % [
				FIELD_REGIONS, REGIONS_VISITED, str(entry)
			])
	return errors


# --- Internals ---------------------------------------------------------------


## True for anything JSON could have written as a number.
static func _is_number(value: Variant) -> bool:
	return value is int or value is float


## True for a number with nothing after the decimal point - what an `int` field looks
## like once JSON has been through it.
##
## EXACT, not approximate. A tolerant comparison would read `1.0000000001` - a hand-
## edited file, or a version that went through a float32 - as version 1 and load it as
## though this build had written it. A version is an identity, not a measurement:
## either the file says 1 or it does not say anything this build can use.
static func _is_whole_number(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return float(value) == floorf(float(value))
	return false


## True for a String or StringName - what an id looks like in JSON.
static func _is_text(value: Variant) -> bool:
	return value is String or value is StringName


static func _as_int(value: Variant, fallback: int) -> int:
	if _is_number(value):
		return int(value)
	return fallback


static func _as_float(value: Variant, fallback: float) -> float:
	if _is_number(value):
		return float(value)
	return fallback


static func _as_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


## A list of ids as plain Strings, for JSON.
static func _ids_as_strings(ids: Array[StringName]) -> Array:
	var found: Array = []
	for entry: StringName in ids:
		found.append(String(entry))
	return found


## A JSON list read back as ids. Anything that is not text is dropped; saying so is
## `validate_dictionary()`'s job (see `from_dictionary()`'s totality note).
static func _as_ids(value: Variant) -> Array[StringName]:
	var found: Array[StringName] = []
	if not (value is Array):
		return found
	for entry: Variant in value as Array:
		if _is_text(entry):
			found.append(StringName(entry))
	return found


static func _as_id(value: Variant) -> StringName:
	if _is_text(value):
		return StringName(value)
	return UNSET
