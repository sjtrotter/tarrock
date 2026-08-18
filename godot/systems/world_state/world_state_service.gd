class_name WorldStateService
extends RefCounted

## The one mutation path for everything the world permanently remembers.
##
## `docs/design/world.md` §World-state matrix is canon: quests **fire** `WS_*` flags,
## nothing else may mutate them, and no unbinding is reversible.
## `docs/design/technical.md` §The WorldState service (Godot) compiles that rule into
## this shape, and this service is where it lives - flags, the act the world is in,
## the Fool's Reading, per-suit Renown, the Hermit's answer, named-NPC memory, and
## quest state. Everything else in the game *reads* it and *subscribes* to it.
##
## Three properties hold by construction rather than by discipline:
##
##   * **Permanence.** There is no method here that un-fires, clears, resets or
##     removes anything. `fire()` is the only way a flag changes, and it only ever
##     changes one way. `world_state_service_test.gd` proves it by reflection.
##   * **Order-independence.** Queries are per-flag booleans, never an ordered log,
##     so "Sun unbound AND Star unbound" is correct in either order (`world.md`'s
##     interaction rules). The Reading exists alongside those booleans, for content
##     that wants the *sequence* - it never gates a query.
##   * **Loading is not an event.** `restore_snapshot()` populates state directly and
##     emits nothing: a subscriber must not hear twenty unbindings the moment a save
##     is loaded. Only play emits.
##   * **A load is not a reset.** `restore_snapshot()` is refused by a service that
##     has already been played (`is_pristine()`), and it is all-or-nothing: a
##     snapshot with any problem in it commits nothing. So there is no public call
##     here that can blank a world in play, deliberately or by mistake.
##
## Writers: only quest state-machine transitions call `fire()`, `adjust_renown()`,
## `set_quest_state()` and friends. Combat, dialogue, UI and NPCs raise their own
## domain events; a quest transition responds and calls this service. Polling this
## service every frame is forbidden - connect to the signals.

## A flag became true. Emitted once, ever, per flag.
signal world_state_fired(flag_id: StringName)

## The world crossed an act threshold. Carries `Act` values.
signal act_changed(old_act: int, new_act: int)

## An unbinding was appended to the Fool's Reading, at `index`.
signal reading_appended(flag_id: StringName, index: int)

## A suit's Renown moved.
signal renown_changed(suit: Suit.Id, old_value: int, new_value: int)

## A suit's Renown crossed onto a different rung of the ladder. Tiers are 1..5.
signal renown_tier_changed(suit: Suit.Id, old_tier: int, new_tier: int)

## The Fool answered the Hermit. Emitted once, ever.
signal hermit_answer_set(answer_id: StringName)

## A named NPC learned something about the Fool.
signal npc_memory_flag_set(npc_id: StringName, flag: StringName)

## A quest moved to a new state.
signal quest_state_changed(quest_id: StringName, old_state: StringName, new_state: StringName)

## The three acts of `docs/design/world.md` §Global states, by unbound count.
enum Act {
	ACT_I,
	ACT_II,
	ACT_III,
}

## Snapshot keys. The save model (round 3) writes these verbatim, so they are
## constants rather than typed strings.
const SNAPSHOT_FIRED := "fired"
const SNAPSHOT_READING := "reading_order"
const SNAPSHOT_RENOWN := "renown"
const SNAPSHOT_HERMIT := "hermit_answer"
const SNAPSHOT_NPC_MEMORY := "npc_memory"
const SNAPSHOT_QUEST_STATES := "quest_states"

## The lowest Renown a suit can hold. Deeds may cost standing, but no suit's regard
## goes negative; there is no upper bound (progression.md §Renown sets none).
const RENOWN_FLOOR := 0

## The value `hermit_answer()` and `quest_state()` return when nothing was ever set.
const UNSET := &""

var _catalog: WorldStateCatalog = null
var _thresholds: ActThresholds = null
var _ladder: RenownLadder = null

## False from the first mutation - or the first successful load - onward. It is what
## makes `restore_snapshot()` a load rather than a reset: see `is_pristine()`.
var _pristine: bool = true

## `flag id -> definition`, flattened out of the catalog once so `is_fired()` is a
## single dictionary lookup and allocates nothing.
var _definitions: Dictionary = {}

## `flag id -> the quest that fired it`. Membership *is* firedness.
var _fired: Dictionary = {}

## The Fool's Reading: unbinding flags in the order they fired. Append-only.
var _reading: Array[StringName] = []

## Renown per suit, indexed by `Suit.Id`.
var _renown: PackedInt32Array = PackedInt32Array()

## How many unbinding flags have fired. Cached so `act()` costs nothing.
var _unbound_count: int = 0

var _hermit_answer: StringName = UNSET

## `npc id -> Array[StringName]` of that NPC's memory flags. Append-only per NPC.
var _npc_memory: Dictionary = {}

## `quest id -> state id`.
var _quest_states: Dictionary = {}


## Build the service over the generated definitions.
##
## `catalog` decides which flags exist at all - firing anything else is an error,
## not a new flag. `thresholds` and `ladder` supply the act boundaries and the
## Renown ladder, so no number in here is spelled in code.
func _init(
	catalog: WorldStateCatalog, thresholds: ActThresholds, ladder: RenownLadder
) -> void:
	_catalog = catalog
	_thresholds = thresholds
	_ladder = ladder
	if catalog == null or thresholds == null or ladder == null:
		push_error("WorldStateService was built without its definitions")
	_load_blank_state()
	if catalog != null:
		for entry: WorldStateDefinition in catalog.entries:
			if entry != null:
				_definitions[entry.id] = entry


# --- Flags -------------------------------------------------------------------


## Fire a world-state flag. Returns true only when **this call** fired it.
##
## A second call on an already-fired flag returns false and touches nothing: firing
## is idempotent, so a quest that completes twice cannot double-count. An id the
## catalog does not list is an error and fires nothing.
##
## `fired_by` names the quest doing the firing and is required: `fired_by()` answers
## `&""` for a flag that never fired, so an empty one would make the two cases
## indistinguishable. An empty `fired_by` is an error and fires nothing.
##
## Firing an unbinding appends it to the Fool's Reading; a branch flag never does,
## and never counts toward an act. Signals, in order: `world_state_fired`, then
## `reading_appended` if the Reading grew, then `act_changed` if the act moved.
func fire(flag_id: StringName, fired_by: StringName) -> bool:
	var definition := _definition(flag_id)
	if definition == null:
		return false
	if fired_by == UNSET:
		push_error("firing %s needs the id of the quest that fired it" % flag_id)
		return false
	if _fired.has(flag_id):
		return false
	var old_act := act()
	_pristine = false
	_fired[flag_id] = fired_by
	var appended_at := -1
	if definition.is_unbinding():
		_unbound_count += 1
		_reading.append(flag_id)
		appended_at = _reading.size() - 1
	world_state_fired.emit(flag_id)
	if appended_at >= 0:
		reading_appended.emit(flag_id, appended_at)
	var new_act := act()
	if new_act != old_act:
		act_changed.emit(old_act, new_act)
	return true


## True when this flag has fired. An id the catalog does not list is an error and
## reads as false.
func is_fired(flag_id: StringName) -> bool:
	if not _definitions.has(flag_id):
		push_error("no world-state flag with id %s" % flag_id)
		return false
	return _fired.has(flag_id)


## The quest that fired this flag, or `&""` when it has not fired.
func fired_by(flag_id: StringName) -> StringName:
	return _fired.get(flag_id, UNSET)


## How many Arcana have been unbound. Branch flags do not count.
func unbound_count() -> int:
	return _unbound_count


## The act the world is in, by unbound count (`world.md` §Global states).
func act() -> Act:
	if _thresholds == null:
		return Act.ACT_I
	if _unbound_count >= _thresholds.act_iii_min:
		return Act.ACT_III
	if _unbound_count >= _thresholds.act_ii_min:
		return Act.ACT_II
	return Act.ACT_I


## True once Death is unbound - the world knows what the Fool is.
##
## `world.md` §Global states calls this state CONFESSED and makes it independent of
## the act; every quest from MQ02 on carries `[If CONFESSED]` variants keyed to it.
func is_confessed() -> bool:
	return is_fired(WorldStateIds.WS_DEATH_UNBOUND)


## The Fool's Reading: the unbindings in the order they happened, as a copy.
##
## Append-only inside, and there is no public way to reorder or shorten it, so the
## Reading cannot drift from the flags (`technical.md` §The WorldState service).
func reading_order() -> Array[StringName]:
	return _reading.duplicate()


# --- Renown ------------------------------------------------------------------


## This suit's Renown. Every suit starts at 0 (progression.md §Renown).
func renown(suit: Suit.Id) -> int:
	if suit < 0 or suit >= _renown.size():
		push_error("no such suit: %d" % suit)
		return RENOWN_FLOOR
	return _renown[suit]


## This suit's rung on the five-tier ladder, 1..5.
func renown_tier(suit: Suit.Id) -> int:
	if _ladder == null:
		return RenownLadder.FIRST_TIER
	return _ladder.tier_for(renown(suit))


## The translation key for this suit's standing, e.g. `&"RENOWN_TIER_HONORED"`.
## Never the English word - the ladder's words exist to build the key.
func renown_tier_name_key(suit: Suit.Id) -> StringName:
	if _ladder == null:
		return UNSET
	return _ladder.tier_name_key(renown_tier(suit))


## Move a suit's Renown by `delta`, clamped at `RENOWN_FLOOR` and unbounded above.
##
## `reason` is the caller's audit trail - a deed id, a quest id - carried so a
## future save/telemetry pass can log *why* standing moved. Nothing is stored or
## emitted for it today, deliberately: the mutable state stays the numbers.
##
## A delta that changes nothing (0, or a drop already at the floor) emits nothing.
## Emits `renown_changed`, then `renown_tier_changed` when the rung moved.
@warning_ignore("unused_parameter")
func adjust_renown(suit: Suit.Id, delta: int, reason: StringName) -> void:
	if suit < 0 or suit >= _renown.size():
		push_error("no such suit: %d" % suit)
		return
	var old_value := _renown[suit]
	var new_value := maxi(RENOWN_FLOOR, old_value + delta)
	if new_value == old_value:
		return
	var old_tier := renown_tier(suit)
	_pristine = false
	_renown[suit] = new_value
	var new_tier := renown_tier(suit)
	renown_changed.emit(suit, old_value, new_value)
	if new_tier != old_tier:
		renown_tier_changed.emit(suit, old_tier, new_tier)


# --- The Hermit's answer -----------------------------------------------------


## Record the Fool's answer to the Hermit's one question. Returns true only the
## first time: a second call is refused, not an overwrite (`world.md` §Global
## states - `HERMIT_ANSWER` is set once, at MQ09's tea question).
func set_hermit_answer(answer_id: StringName) -> bool:
	if answer_id == UNSET:
		push_error("the Hermit answer needs an answer id")
		return false
	if _hermit_answer != UNSET:
		return false
	_pristine = false
	_hermit_answer = answer_id
	hermit_answer_set.emit(answer_id)
	return true


## The Fool's answer to the Hermit, or `&""` if the tea has not happened yet.
func hermit_answer() -> StringName:
	return _hermit_answer


# --- Named-NPC memory --------------------------------------------------------


## Record that a named NPC knows something about the Fool. Returns true only the
## first time: a memory flag is append-only per NPC (`npc-system.md` §Named vs.
## ambient NPCs). Ambient Minors have no memory and never appear here.
func npc_remember(npc_id: StringName, flag: StringName) -> bool:
	if npc_id == UNSET or flag == UNSET:
		push_error("a named-NPC memory needs both an npc id and a flag")
		return false
	var flags: Array[StringName] = _npc_memory.get(npc_id, [] as Array[StringName])
	if flags.has(flag):
		return false
	_pristine = false
	flags.append(flag)
	_npc_memory[npc_id] = flags
	npc_memory_flag_set.emit(npc_id, flag)
	return true


## True when this named NPC remembers this flag.
func npc_remembers(npc_id: StringName, flag: StringName) -> bool:
	var flags: Array[StringName] = _npc_memory.get(npc_id, [] as Array[StringName])
	return flags.has(flag)


## Everything this named NPC remembers, in the order they learned it, as a copy.
func npc_memory(npc_id: StringName) -> Array[StringName]:
	var flags: Array[StringName] = _npc_memory.get(npc_id, [] as Array[StringName])
	return flags.duplicate()


# --- Quest state -------------------------------------------------------------


## This quest's current state id, or `&""` when the quest has never started.
func quest_state(quest_id: StringName) -> StringName:
	return _quest_states.get(quest_id, UNSET)


## Move a quest to a new state. **Round 4's quest runner is the only intended
## caller**: quest state is the quest state machine's own business, kept here
## because it is save data and because barks and dialogue read it.
## Emits `quest_state_changed` when the state actually differs.
func set_quest_state(quest_id: StringName, state: StringName) -> void:
	if quest_id == UNSET:
		push_error("a quest state needs a quest id")
		return
	var old_state := quest_state(quest_id)
	if old_state == state:
		return
	_pristine = false
	_quest_states[quest_id] = state
	quest_state_changed.emit(quest_id, old_state, state)


# --- Save --------------------------------------------------------------------


## Everything the save file needs, as ids, ints and strings only.
##
## No resources, no objects, no enums-as-objects: the snapshot survives being
## written as JSON and read back by a later build (`technical.md` §Save system).
## The save service (round 3) owns versioning and migration; this is the payload.
func to_snapshot() -> Dictionary:
	var fired: Dictionary = {}
	for flag_id: StringName in _fired:
		fired[String(flag_id)] = String(_fired[flag_id])
	var reading: Array[String] = []
	for flag_id: StringName in _reading:
		reading.append(String(flag_id))
	var renown_by_suit: Dictionary = {}
	for suit: Suit.Id in Suit.ALL:
		renown_by_suit[String(Suit.name_key(suit))] = _renown[suit]
	var memory: Dictionary = {}
	for npc_id: StringName in _npc_memory:
		var flags: Array[String] = []
		for flag: StringName in _npc_memory[npc_id]:
			flags.append(String(flag))
		memory[String(npc_id)] = flags
	var quests: Dictionary = {}
	for quest_id: StringName in _quest_states:
		quests[String(quest_id)] = String(_quest_states[quest_id])
	return {
		SNAPSHOT_FIRED: fired,
		SNAPSHOT_READING: reading,
		SNAPSHOT_RENOWN: renown_by_suit,
		SNAPSHOT_HERMIT: String(_hermit_answer),
		SNAPSHOT_NPC_MEMORY: memory,
		SNAPSHOT_QUEST_STATES: quests,
	}


## True until this service is first mutated or first loaded into.
##
## A pristine service is a world nobody has played yet, which is the only kind
## `restore_snapshot()` will fill: see there for why.
func is_pristine() -> bool:
	return _pristine


## Load a snapshot into this service, returning every problem it found.
##
## **Emits nothing.** Loading a save is not twenty unbindings happening; a
## subscriber that heard them would replay three hundred years of world change in
## one frame (`technical.md` §The WorldState service).
##
## **Only into a pristine service.** A load is not a reset: a public call that
## blanked a world in play would be the un-fire this service exists to make
## impossible. Loading a save means building a service and filling it, so a service
## that has been played (or already loaded) refuses, reporting one problem and
## changing nothing. The caller keeps the world it has.
##
## **All or nothing.** The snapshot is parsed and validated in full before a single
## field is committed, so a save this build cannot read leaves a blank service
## rather than half a world: a flag without its place in the Reading, or a Reading
## without its flag, is a world whose own history disagrees with itself, and no
## later system could tell which half was true. Every problem found is returned -
## an unknown flag, a Reading that drifted from the flags, a field of the wrong
## shape - and the save service (round 3) decides what to tell the player.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _pristine:
		errors.append("restore_snapshot needs a fresh service; this world is already in play")
		return errors

	var fired: Dictionary = {}
	var reading: Array[StringName] = []
	var renown_by_suit := PackedInt32Array()
	renown_by_suit.resize(Suit.ALL.size())
	renown_by_suit.fill(RENOWN_FLOOR)
	var memory: Dictionary = {}
	var quests: Dictionary = {}
	var unbound := 0

	var stored_fired: Dictionary = _dictionary_field(data, SNAPSHOT_FIRED, errors)
	for key: Variant in stored_fired:
		var flag_id := _as_id(key)
		if not _definitions.has(flag_id):
			errors.append("snapshot fired a flag this build does not have: %s" % key)
			continue
		fired[flag_id] = _as_id(stored_fired[key])

	var stored_reading: Variant = data.get(SNAPSHOT_READING, [])
	if stored_reading is Array:
		for key: Variant in stored_reading as Array:
			var flag_id := _as_id(key)
			var definition: WorldStateDefinition = _definitions.get(flag_id)
			if definition == null or not definition.is_unbinding():
				errors.append("snapshot read an unbinding this build does not have: %s" % key)
				continue
			if not fired.has(flag_id):
				errors.append("snapshot read an unbinding whose flag never fired: %s" % key)
				continue
			if reading.has(flag_id):
				errors.append("snapshot read the same unbinding twice: %s" % key)
				continue
			reading.append(flag_id)
	else:
		errors.append("snapshot field %s is not an array" % SNAPSHOT_READING)

	for flag_id: StringName in fired:
		var definition: WorldStateDefinition = _definitions[flag_id]
		if not definition.is_unbinding():
			continue
		unbound += 1
		if not reading.has(flag_id):
			errors.append("snapshot fired an unbinding its Reading never recorded: %s" % flag_id)

	var stored_renown: Dictionary = _dictionary_field(data, SNAPSHOT_RENOWN, errors)
	for key: Variant in stored_renown:
		var suit := Suit.from_name_key(_as_id(key))
		var value: Variant = stored_renown[key]
		if suit == Suit.UNKNOWN:
			errors.append("snapshot named a suit this build does not have: %s" % key)
			continue
		if not (value is int or value is float):
			errors.append("snapshot renown for %s is not a number" % key)
			continue
		renown_by_suit[suit] = maxi(RENOWN_FLOOR, int(value))

	var hermit := _as_id(data.get(SNAPSHOT_HERMIT, UNSET))

	var stored_memory: Dictionary = _dictionary_field(data, SNAPSHOT_NPC_MEMORY, errors)
	for key: Variant in stored_memory:
		var stored: Variant = stored_memory[key]
		if not (stored is Array):
			errors.append("snapshot memory for %s is not an array" % key)
			continue
		var flags: Array[StringName] = []
		for flag: Variant in stored as Array:
			flags.append(_as_id(flag))
		memory[_as_id(key)] = flags

	var stored_quests: Dictionary = _dictionary_field(data, SNAPSHOT_QUEST_STATES, errors)
	for key: Variant in stored_quests:
		quests[_as_id(key)] = _as_id(stored_quests[key])

	if not errors.is_empty():
		return errors

	_fired = fired
	_reading = reading
	_renown = renown_by_suit
	_unbound_count = unbound
	_hermit_answer = hermit
	_npc_memory = memory
	_quest_states = quests
	_pristine = false
	return errors


# --- Internals ---------------------------------------------------------------


## The definition behind an id, or null (with an error) when there is none. The one
## place an unknown id is turned away, so `fire()` and `is_fired()` agree.
func _definition(flag_id: StringName) -> WorldStateDefinition:
	var definition: WorldStateDefinition = _definitions.get(flag_id)
	if definition == null:
		push_error("no world-state flag with id %s" % flag_id)
	return definition


## The starting position: nothing fired, nothing read, no standing anywhere.
##
## Called by `_init`, and by nothing else. A service is blanked exactly once, when
## it is built: `restore_snapshot()` only ever fills a service that is already in
## this state, so there is no code path here - public or private - that returns a
## world in play to nothing.
func _load_blank_state() -> void:
	_fired = {}
	_reading = []
	_unbound_count = 0
	_hermit_answer = UNSET
	_npc_memory = {}
	_quest_states = {}
	_renown = PackedInt32Array()
	_renown.resize(Suit.ALL.size())
	_renown.fill(RENOWN_FLOOR)


## A snapshot field that must be a Dictionary; anything else is a reported problem
## and an empty one.
func _dictionary_field(
	data: Dictionary, field: String, errors: PackedStringArray
) -> Dictionary:
	var value: Variant = data.get(field, {})
	if value is Dictionary:
		return value
	errors.append("snapshot field %s is not a dictionary" % field)
	return {}


## A snapshot value as an id. Anything that is not text reads as `&""`, which every
## caller then reports and skips: a corrupt save must not be able to crash a load.
func _as_id(value: Variant) -> StringName:
	if value is String or value is StringName:
		return StringName(value)
	return UNSET
