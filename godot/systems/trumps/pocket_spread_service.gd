class_name PocketSpreadService
extends RefCounted

## The Fool's three cards: which Trumps are held, what is slotted, and what it costs.
##
## `docs/design/progression.md` §The Pocket Spread is canon:
##
##   * Three slots - Past (passive), Present (active, costs Fortune), Future
##     (triggered). Named for a three-card spread; nothing rewinds.
##   * **One copy of each Trump.** No duplicates, no upgrading one card.
##   * Slots unlock by how many Trumps are held: Present with the first, Past at 3,
##     Future at 7 - the pacing teaches one axis at a time.
##   * **Swapping is free anywhere, out of combat.** No cooldown, no cost.
##   * **Named loadouts are a Waystation privilege** - saving, naming and switching
##     whole configurations happens at a Waystation and nowhere else.
##
## **Held Trumps are derived, never stored.** A Trump is held exactly when its
## `granted_by_flag` has fired, and `WorldStateService` can never un-fire one, so
## there is no second list of "cards I own" that could disagree with the world.
## Nothing here writes world state; it subscribes to it.
##
## **What this round does not do.** Casting a Present spends Fortune and announces
## itself; running the effect, and applying a reversed card's burden, belong to the
## combat round (round 7). `present_cast` carries the Trump and the orientation, and
## `slotted_burden()` answers which burden is live, so the effect runner has
## everything it needs the day it exists. A Trump whose effects nobody has authored
## yet can still be held and slotted - only casting it refuses, with a reason.

## The Fool was handed a Trump (its unbinding fired). Not emitted by a load.
signal trump_gained(trump_id: StringName)

## A slot opened because the held count crossed its threshold.
signal slot_unlocked(slot: SpreadSlot.Id)

## A Trump was put in a slot, or its orientation was turned.
signal slot_assigned(slot: SpreadSlot.Id, trump_id: StringName, orientation: CardOrientation.Id)

## A slot was emptied.
signal slot_cleared(slot: SpreadSlot.Id)

## An assignment was refused. `reason` is one of the `REASON_*` constants.
signal assignment_refused(slot: SpreadSlot.Id, reason: StringName)

## A loadout was saved, at `index`.
signal loadout_saved(index: int)

## A loadout was applied.
signal loadout_applied(index: int)

## A loadout call was refused. `index` is -1 for a save (there is no index yet).
signal loadout_refused(index: int, reason: StringName)

## A Present cast was paid for. The effect runner (round 7) acts on this; the live
## burden, if the card is reversed, is `slotted_burden(SpreadSlot.Id.PRESENT)`.
signal present_cast(trump_id: StringName, orientation: CardOrientation.Id)

## A Present cast was refused. `reason` is one of the `REASON_*` constants.
signal present_cast_refused(reason: StringName)

## The catalog does not list this Trump at all.
const REASON_UNKNOWN_TRUMP := &"UNKNOWN_TRUMP"

## The Fool has not unbound the Arcana that grants this Trump.
const REASON_NOT_HELD := &"NOT_HELD"

## Too few Trumps held for this slot to be open yet.
const REASON_SLOT_LOCKED := &"SLOT_LOCKED"

## That Trump is already in another slot - there is only one copy of each.
const REASON_ALREADY_SLOTTED := &"ALREADY_SLOTTED"

## The Spread cannot be rebuilt mid-fight (`progression.md`: "anywhere, out of
## combat").
const REASON_IN_COMBAT := &"IN_COMBAT"

## Loadouts are a Waystation privilege.
const REASON_NOT_AT_WAYSTATION := &"NOT_AT_WAYSTATION"

## No loadout has been saved at that index.
const REASON_NO_SUCH_LOADOUT := &"NO_SUCH_LOADOUT"

## The slot holds nothing.
const REASON_EMPTY_SLOT := &"EMPTY_SLOT"

## Nobody has authored this Trump's six expressions yet.
const REASON_NO_EFFECTS := &"NO_EFFECTS"

## The effect is authored but no implementation stands behind its id yet.
const REASON_NOT_IMPLEMENTED := &"NOT_IMPLEMENTED"

## This Spread was built without a Fortune meter, so nothing can be paid for.
const REASON_NO_FORTUNE := &"NO_FORTUNE"

## Not enough Fortune, and no free cast armed.
const REASON_CANNOT_AFFORD := &"CANNOT_AFFORD"

## Snapshot keys. The save model writes these verbatim.
const SNAPSHOT_SLOTS := "slots"
const SNAPSHOT_LOADOUTS := "loadouts"
const SNAPSHOT_TRUMP := "trump_id"
const SNAPSHOT_ORIENTATION := "orientation"
const SNAPSHOT_LABEL := "label"

## What `save_loadout()` returns when it refused.
const NO_LOADOUT := -1

## `_held_count` before anything has counted, and the stamp that goes with it.
## Not a legal count, so it cannot be mistaken for "the Fool holds none".
const UNCOUNTED := -1

var _world_state: WorldStateService = null
var _trumps: TrumpCatalog = null
var _rules: SpreadRules = null
var _fortune: FortuneService = null

## One entry per `SpreadSlot.Id`, in `SpreadSlot.ALL` order. Never null, never
## resized: an open slot is an empty `SlotAssignment`.
var _slots: Array[SlotAssignment] = []

var _loadouts: Array[SpreadLoadout] = []

## Set by the caller. Combat owns the first (round 7), Regions the second (round
## 10); until then a scene sets them and the rules above are enforced all the same.
var _in_combat: bool = false
var _at_waystation: bool = false

var _pristine: bool = true

## The held count, cached, and the world reading it was counted at.
##
## Held Trumps are derived from the flags, so counting them means walking the whole
## catalog and querying twenty flags - on every `is_slot_unlocked()` call, which is
## three per `assign()` and one per `can_cast_present()`, and a HUD polls the latter
## every frame. The answer is therefore computed once and stamped with
## `WorldStateService.unbound_count()`, which is O(1) and moves whenever any
## unbinding flag fires **or a snapshot is restored** - a load emits nothing, so a
## cache invalidated by the signal alone would go stale exactly there.
##
## The stamp is sound because every Trump's `granted_by_flag` is its Arcana's
## unbinding flag (`TrumpDefinition`, and the drift test that pins it): no change to
## the set of held Trumps can leave the unbound count where it was.
var _held_count: int = UNCOUNTED
var _held_count_stamp: int = UNCOUNTED


## Build the Spread over world state (which Trumps are held), the Trump catalog and
## the tuning rules.
##
## `fortune` is optional only so a test - or a tool - can build a Spread to inspect
## slotting without a meter; a Spread without one refuses to cast, loudly and by
## reason code, rather than casting for free. The composition root always passes it.
func _init(
	world_state: WorldStateService,
	trumps: TrumpCatalog,
	rules: SpreadRules,
	fortune: FortuneService = null
) -> void:
	_world_state = world_state
	_trumps = trumps
	_rules = rules
	_fortune = fortune
	if world_state == null or trumps == null or rules == null:
		push_error("PocketSpreadService was built without its definitions")
	for _slot: SpreadSlot.Id in SpreadSlot.ALL:
		_slots.append(SlotAssignment.new())
	if world_state != null:
		world_state.world_state_fired.connect(_on_world_state_fired)


# --- Held Trumps -------------------------------------------------------------


## Every Trump the Fool holds, in card order. Derived from world state.
func held_ids() -> Array[StringName]:
	var found: Array[StringName] = []
	if _trumps == null:
		return found
	for entry: TrumpDefinition in _trumps.entries:
		if entry != null and _is_flag_fired(entry.granted_by_flag):
			found.append(entry.id)
	return found


## How many Trumps the Fool holds. What the slot unlocks are measured against.
##
## Cached against the world's unbound count (see `_held_count`), so the unlock check
## and the cast check are an int comparison rather than a walk of the catalog.
func held_count() -> int:
	var stamp := 0 if _world_state == null else _world_state.unbound_count()
	if _held_count == UNCOUNTED or _held_count_stamp != stamp:
		_held_count = _count_held()
		_held_count_stamp = stamp
	return _held_count


## True when the Fool holds this Trump. An id the catalog does not list is false.
func is_held(trump_id: StringName) -> bool:
	var definition := _definition(trump_id)
	if definition == null:
		return false
	return _is_flag_fired(definition.granted_by_flag)


## The Trump's definition, or `null` when the catalog does not list it.
func definition(trump_id: StringName) -> TrumpDefinition:
	return _definition(trump_id)


# --- Slots -------------------------------------------------------------------


## True when this slot has opened (`progression.md` §Slot unlock pacing).
##
## An unlock is a threshold on the held count, and held Trumps only ever accumulate,
## so an unlock never reverts.
func is_slot_unlocked(slot: SpreadSlot.Id) -> bool:
	if _rules == null:
		return false
	return held_count() >= _rules.held_required_for(slot)


## What is in a slot, as a copy. An empty `SlotAssignment` means the slot is open.
##
## This is the query for a caller that wants the pair - a UI drawing the Spread, a
## test. It allocates, deliberately: handing out the service's own `SlotAssignment`
## would let anyone change what is slotted without going through `assign()`, which
## is where the rules live. The read paths that run every frame use
## `slotted_trump_id()` / `slotted_orientation()` instead.
func slotted(slot: SpreadSlot.Id) -> SlotAssignment:
	if slot < 0 or slot >= _slots.size():
		return SlotAssignment.new()
	return _slots[slot].copy()


## The Trump in a slot, or `&""` when the slot is empty. Allocates nothing.
##
## A `StringName` is a value, so this hands out no object a caller could reach back
## through - which is what lets the hot paths (`present_cost()`, `can_cast_present()`,
## `slotted_burden()`) read a slot without building a copy per call. A HUD asking
## "can I cast?" every frame is the case this exists for.
func slotted_trump_id(slot: SpreadSlot.Id) -> StringName:
	if slot < 0 or slot >= _slots.size():
		return &""
	return _slots[slot].trump_id


## Which way up a slot's Trump is. Allocates nothing.
##
## Meaningless while the slot is empty (`slotted_trump_id()` answers `&""` then), the
## same contract `SlotAssignment.orientation` carries.
func slotted_orientation(slot: SpreadSlot.Id) -> CardOrientation.Id:
	if slot < 0 or slot >= _slots.size():
		return CardOrientation.Id.UPRIGHT
	return _slots[slot].orientation


## The slot this Trump currently sits in, or `SpreadSlot.UNKNOWN` (-1) when it is
## not slotted. The one-copy rule's query.
func slot_of(trump_id: StringName) -> int:
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		if _slots[slot].trump_id == trump_id:
			return slot
	return SpreadSlot.UNKNOWN


## Put a Trump in a slot, that way up. False when refused, having changed nothing.
##
## Refusals, in the order they are checked, each announced on `assignment_refused`:
## an id the catalog does not know, a fight in progress (the Spread is rebuilt
## between fights, never during one), a Trump the Fool has not been handed, a slot
## that has not opened yet, and the one-copy rule - the same card cannot sit in two
## slots at once.
##
## Re-assigning the Trump already in the slot is allowed and is how a card is turned
## upright or reversed.
func assign(
	slot: SpreadSlot.Id, trump_id: StringName, orientation: CardOrientation.Id
) -> bool:
	if slot < 0 or slot >= _slots.size():
		push_error("no such spread slot: %d" % slot)
		return false
	var definition := _definition(trump_id)
	if definition == null:
		return _refuse(slot, REASON_UNKNOWN_TRUMP)
	if _in_combat:
		return _refuse(slot, REASON_IN_COMBAT)
	if not _is_flag_fired(definition.granted_by_flag):
		return _refuse(slot, REASON_NOT_HELD)
	if not is_slot_unlocked(slot):
		return _refuse(slot, REASON_SLOT_LOCKED)
	var occupied := slot_of(trump_id)
	if occupied != SpreadSlot.UNKNOWN and occupied != slot:
		return _refuse(slot, REASON_ALREADY_SLOTTED)
	_pristine = false
	_slots[slot] = SlotAssignment.new(trump_id, orientation)
	slot_assigned.emit(slot, trump_id, orientation)
	return true


## Empty a slot. False when it was already empty or the Fool is mid-fight.
func clear(slot: SpreadSlot.Id) -> bool:
	if slot < 0 or slot >= _slots.size():
		push_error("no such spread slot: %d" % slot)
		return false
	if _in_combat:
		return _refuse(slot, REASON_IN_COMBAT)
	if _slots[slot].is_empty():
		return _refuse(slot, REASON_EMPTY_SLOT)
	_pristine = false
	_slots[slot] = SlotAssignment.new()
	slot_cleared.emit(slot)
	return true


## The burden a reversed card in this slot is carrying, or `null` - because the slot
## is empty, the card is upright, or nobody has authored its effects yet.
##
## `arcana.md` design rule 5: the burden attaches to whichever slot the reversed
## card occupies. Applying it is round 7's; naming it is this service's.
func slotted_burden(slot: SpreadSlot.Id) -> TrumpBurden:
	var trump_id := slotted_trump_id(slot)
	if trump_id == &"" or slotted_orientation(slot) != CardOrientation.Id.REVERSED:
		return null
	var definition := _definition(trump_id)
	if definition == null:
		return null
	return definition.burden()


# --- Combat and Waystation state ---------------------------------------------


## True while a fight is in progress, so the Spread is locked.
func in_combat() -> bool:
	return _in_combat


## Tell the Spread a fight has started or ended. Combat (round 7) owns this.
func set_in_combat(fighting: bool) -> void:
	_in_combat = fighting


## True while the Fool is at a Waystation, so loadouts are available.
func at_waystation() -> bool:
	return _at_waystation


## Tell the Spread the Fool is at a Waystation. Regions (round 10) owns this.
func set_at_waystation(resting: bool) -> void:
	_at_waystation = resting


# --- Loadouts ----------------------------------------------------------------


## Save the current spread under a player-typed name. Returns its index, or
## `NO_LOADOUT` (-1) when refused.
##
## Waystation only (`progression.md` §The Pocket Spread): free-form swapping covers
## moment-to-moment adaptation, loadouts cover deliberate builds.
##
## Refused mid-fight as well, for the same reason `assign()` and `apply_loadout()`
## are: `progression.md` puts every Spread operation "anywhere, out of combat", and a
## build saved from a Spread the player cannot currently change is a menu that opens
## in the middle of a boss. Waystation and combat are independent flags today - the
## Regions round sets one and combat the other - so neither implies the other and
## both are checked.
##
## `label` is user text and is stored verbatim - it is not a translation key and is
## never displayed through `tr()`.
func save_loadout(label: String) -> int:
	if _in_combat:
		loadout_refused.emit(NO_LOADOUT, REASON_IN_COMBAT)
		return NO_LOADOUT
	if not _at_waystation:
		loadout_refused.emit(NO_LOADOUT, REASON_NOT_AT_WAYSTATION)
		return NO_LOADOUT
	_pristine = false
	_loadouts.append(SpreadLoadout.new(label, _slots))
	var index := _loadouts.size() - 1
	loadout_saved.emit(index)
	return index


## Every saved loadout, as copies, in the order they were saved.
func loadouts() -> Array[SpreadLoadout]:
	var found: Array[SpreadLoadout] = []
	for entry: SpreadLoadout in _loadouts:
		found.append(entry.copy())
	return found


## How many loadouts are saved.
func loadout_count() -> int:
	return _loadouts.size()


## Switch the whole spread to a saved loadout. False when refused.
##
## Waystation only, and **every assignment is revalidated** rather than trusted: a
## loadout is data that survived a save file, and the world it was saved in is not
## always the world it is applied in. A loadout naming a Trump the Fool does not
## hold (a save edited, a fixture authored, a future build that renamed a card) is
## refused whole - applying half a build silently would be worse than refusing it.
##
## A slot the loadout leaves empty is emptied, so applying a loadout is a switch and
## not a merge.
func apply_loadout(index: int) -> bool:
	if index < 0 or index >= _loadouts.size():
		loadout_refused.emit(index, REASON_NO_SUCH_LOADOUT)
		return false
	if _in_combat:
		loadout_refused.emit(index, REASON_IN_COMBAT)
		return false
	if not _at_waystation:
		loadout_refused.emit(index, REASON_NOT_AT_WAYSTATION)
		return false
	var loadout := _loadouts[index]
	var seen: Dictionary = {}
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		var assignment := loadout.assignment(slot)
		if assignment.is_empty():
			continue
		var definition := _definition(assignment.trump_id)
		if definition == null:
			loadout_refused.emit(index, REASON_UNKNOWN_TRUMP)
			return false
		if not _is_flag_fired(definition.granted_by_flag):
			loadout_refused.emit(index, REASON_NOT_HELD)
			return false
		if not is_slot_unlocked(slot):
			loadout_refused.emit(index, REASON_SLOT_LOCKED)
			return false
		if seen.has(assignment.trump_id):
			loadout_refused.emit(index, REASON_ALREADY_SLOTTED)
			return false
		seen[assignment.trump_id] = true
	_pristine = false
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		var assignment := loadout.assignment(slot)
		var was_empty := _slots[slot].is_empty()
		_slots[slot] = assignment.copy()
		if assignment.is_empty():
			if not was_empty:
				slot_cleared.emit(slot)
			continue
		slot_assigned.emit(slot, assignment.trump_id, assignment.orientation)
	loadout_applied.emit(index)
	return true


## Forget a saved loadout. False when there is none at that index, or the Fool is
## mid-fight, or is not at a Waystation - deleting a build is part of respec, like
## saving one, and all three loadout verbs keep the same gate.
func delete_loadout(index: int) -> bool:
	if index < 0 or index >= _loadouts.size():
		loadout_refused.emit(index, REASON_NO_SUCH_LOADOUT)
		return false
	if _in_combat:
		loadout_refused.emit(index, REASON_IN_COMBAT)
		return false
	if not _at_waystation:
		loadout_refused.emit(index, REASON_NOT_AT_WAYSTATION)
		return false
	_pristine = false
	_loadouts.remove_at(index)
	return true


# --- Casting the Present slot ------------------------------------------------


## What the Present slot's Trump costs at this orientation, in Fortune.
##
## The authored `TrumpEffect` decides; a cost of 0 there means "take the default for
## this orientation" from `SpreadRules` (the per-Trump costs are TBD tuning -
## `progression.md` gives the 20-50 band and `arcana.md` sets no number). An empty
## Present slot costs 0, because there is nothing to cast.
func present_cost(orientation: CardOrientation.Id) -> int:
	var trump_id := slotted_trump_id(SpreadSlot.Id.PRESENT)
	if trump_id == &"" or _rules == null:
		return 0
	var definition := _definition(trump_id)
	if definition == null:
		return 0
	var effect := definition.effect_for(SpreadSlot.Id.PRESENT, orientation)
	if effect == null or effect.present_cost == SpreadRules.UNSET_COST:
		return _rules.default_present_cost(orientation)
	return effect.present_cost


## True when a Present cast would go through right now.
func can_cast_present() -> bool:
	return _cast_refusal() == &""


## Cast the Present slot: pay for it and announce it. False when refused.
##
## Paying is all this does. The effect itself is round 7's - `present_cast` carries
## the Trump and the orientation, and the burden of a reversed card is
## `slotted_burden(SpreadSlot.Id.PRESENT)`. An armed free cast is spent instead of
## Fortune (`combat.md` §Defense: a Fool's Chance makes the next Present cast free).
func cast_present() -> bool:
	var refusal := _cast_refusal()
	if refusal != &"":
		present_cast_refused.emit(refusal)
		return false
	var trump_id := slotted_trump_id(SpreadSlot.Id.PRESENT)
	var orientation := slotted_orientation(SpreadSlot.Id.PRESENT)
	if not _fortune.spend(present_cost(orientation)):
		present_cast_refused.emit(REASON_CANNOT_AFFORD)
		return false
	present_cast.emit(trump_id, orientation)
	return true


# --- Save --------------------------------------------------------------------


## True until this service is first mutated or first loaded into.
func is_pristine() -> bool:
	return _pristine


## Everything the save file needs: what is slotted and what is saved, as ids,
## strings and enum NAME KEYS - never ordinals, which would re-point at a different
## slot the day one is inserted.
##
## Held Trumps are NOT here: they are derived from the world-state snapshot, which
## the same save file already carries. Two records of the same fact are two records
## that can disagree.
func to_snapshot() -> Dictionary:
	var slots: Dictionary = {}
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		var assignment := _slots[slot]
		if assignment.is_empty():
			continue
		slots[String(SpreadSlot.name_key(slot))] = _assignment_snapshot(assignment)
	var saved: Array[Dictionary] = []
	for loadout: SpreadLoadout in _loadouts:
		var loadout_slots: Dictionary = {}
		for slot: SpreadSlot.Id in SpreadSlot.ALL:
			var assignment := loadout.assignment(slot)
			if assignment.is_empty():
				continue
			loadout_slots[String(SpreadSlot.name_key(slot))] = _assignment_snapshot(assignment)
		saved.append({
			SNAPSHOT_LABEL: loadout.label,
			SNAPSHOT_SLOTS: loadout_slots,
		})
	return {
		SNAPSHOT_SLOTS: slots,
		SNAPSHOT_LOADOUTS: saved,
	}


## Load a snapshot, returning every problem it found. Emits nothing.
##
## A fresh service only and all-or-nothing, the same contract `WorldStateService`
## keeps. **The world state must be restored first**: whether a slotted Trump is
## held is read from the flags, so a Spread filled before its world would reject
## every card in it. `SaveService.apply()` does them in that order.
##
## The slots are validated against the world exactly as `assign()` would - held,
## unlocked, one copy - because a save that slots a card the Fool cannot have is a
## save that would give them one.
##
## Saved LOADOUTS are validated for shape only: a loadout may legitimately name a
## Trump this playthrough has not been handed yet (an edited save, a build that
## renamed a card), and `apply_loadout()` is where that is caught, one loadout at a
## time, rather than making the whole file unreadable.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _pristine:
		errors.append("restore_snapshot needs a fresh Spread; this one is already in play")
		return errors

	var slots: Array[SlotAssignment] = []
	for _slot: SpreadSlot.Id in SpreadSlot.ALL:
		slots.append(SlotAssignment.new())
	var seen: Dictionary = {}
	var stored_slots: Variant = data.get(SNAPSHOT_SLOTS, {})
	if stored_slots is Dictionary:
		for key: Variant in stored_slots as Dictionary:
			var slot := SpreadSlot.from_name_key(_as_id(key))
			if slot == SpreadSlot.UNKNOWN:
				errors.append("snapshot names a spread slot this build does not have: %s" % str(key))
				continue
			var assignment := _read_assignment((stored_slots as Dictionary)[key], errors)
			if assignment == null:
				continue
			var definition := _definition_quietly(assignment.trump_id)
			if definition == null:
				errors.append("snapshot slots %s, which this build does not have" % assignment.trump_id)
				continue
			if not _is_flag_fired(definition.granted_by_flag):
				errors.append("snapshot slots %s, which the Fool does not hold" % assignment.trump_id)
				continue
			if not is_slot_unlocked(slot as SpreadSlot.Id):
				errors.append("snapshot fills the %s slot, which has not opened" % str(key))
				continue
			if seen.has(assignment.trump_id):
				errors.append("snapshot slots %s twice; there is one copy of each" % assignment.trump_id)
				continue
			seen[assignment.trump_id] = true
			slots[slot] = assignment
	else:
		errors.append("snapshot field %s is not a dictionary" % SNAPSHOT_SLOTS)

	var loadouts_read: Array[SpreadLoadout] = []
	var stored_loadouts: Variant = data.get(SNAPSHOT_LOADOUTS, [])
	if stored_loadouts is Array:
		for entry: Variant in stored_loadouts as Array:
			if not (entry is Dictionary):
				errors.append("snapshot holds a saved loadout that is not a dictionary")
				continue
			var loadout := _read_loadout(entry as Dictionary, errors)
			if loadout != null:
				loadouts_read.append(loadout)
	else:
		errors.append("snapshot field %s is not an array" % SNAPSHOT_LOADOUTS)

	if not errors.is_empty():
		return errors
	_slots = slots
	_loadouts = loadouts_read
	_pristine = false
	return errors


# --- Internals ---------------------------------------------------------------


## Why a Present cast would be refused, or `&""` when it would go through.
##
## Reads the slot through `slotted_trump_id()` / `slotted_orientation()` rather than
## `slotted()`, so `can_cast_present()` - which a HUD polls every frame - allocates
## no `SlotAssignment` per call. The suite asserts that, by counting `slotted()`.
func _cast_refusal() -> StringName:
	if not is_slot_unlocked(SpreadSlot.Id.PRESENT):
		return REASON_SLOT_LOCKED
	var trump_id := slotted_trump_id(SpreadSlot.Id.PRESENT)
	if trump_id == &"":
		return REASON_EMPTY_SLOT
	var definition := _definition(trump_id)
	if definition == null:
		return REASON_UNKNOWN_TRUMP
	if not definition.has_effects():
		return REASON_NO_EFFECTS
	var orientation := slotted_orientation(SpreadSlot.Id.PRESENT)
	var effect := definition.effect_for(SpreadSlot.Id.PRESENT, orientation)
	if effect == null or not effect.is_implemented():
		return REASON_NOT_IMPLEMENTED
	if _fortune == null:
		return REASON_NO_FORTUNE
	if not _fortune.has_free_cast() and not _fortune.can_afford(present_cost(orientation)):
		return REASON_CANNOT_AFFORD
	return &""


## Announce a refusal and answer false, so every refusing branch is one line.
func _refuse(slot: SpreadSlot.Id, reason: StringName) -> bool:
	assignment_refused.emit(slot, reason)
	return false


## A flag fired somewhere: if it grants a Trump, the Fool has just been handed a
## card, and a slot may have opened with it.
##
## The unlock is computed from the count before and after this one flag, so no
## "which slots have I announced" state exists to go stale - and a load, which
## emits nothing, silently arrives at the right unlock state for free.
func _on_world_state_fired(flag_id: StringName) -> void:
	if _trumps == null or _rules == null:
		return
	var definition := _trumps.find_by_flag(flag_id)
	if definition == null:
		return
	trump_gained.emit(definition.id)
	var now := held_count()
	var before := now - 1
	for slot: SpreadSlot.Id in SpreadSlot.ALL:
		var threshold := _rules.held_required_for(slot)
		if before < threshold and now >= threshold:
			slot_unlocked.emit(slot)


## The definition behind a Trump id, or null (with an error) when there is none.
func _definition(trump_id: StringName) -> TrumpDefinition:
	if _trumps == null:
		return null
	var definition := _trumps.find(trump_id)
	if definition == null:
		push_error("no Trump with id %s" % trump_id)
	return definition


## The same lookup, silent: a bad id in a save file is data to report, not an
## engine error to print.
func _definition_quietly(trump_id: StringName) -> TrumpDefinition:
	if _trumps == null:
		return null
	return _trumps.find(trump_id)


## Walk the catalog and count the Trumps whose granting flag has fired. Called once
## per invalidation by `held_count()`, never by anything else.
func _count_held() -> int:
	var count := 0
	if _trumps == null:
		return count
	for entry: TrumpDefinition in _trumps.entries:
		if entry != null and _is_flag_fired(entry.granted_by_flag):
			count += 1
	return count


## True when a flag has fired, without asking the service about an id it does not
## know (which would push an error).
func _is_flag_fired(flag_id: StringName) -> bool:
	if _world_state == null or flag_id == &"":
		return false
	return _world_state.is_fired(flag_id)


## One slot's snapshot: the Trump and the orientation's stable key.
func _assignment_snapshot(assignment: SlotAssignment) -> Dictionary:
	return {
		SNAPSHOT_TRUMP: String(assignment.trump_id),
		SNAPSHOT_ORIENTATION: String(CardOrientation.name_key(assignment.orientation)),
	}


## One slot's snapshot read back, or null with the problem recorded.
func _read_assignment(stored: Variant, errors: PackedStringArray) -> SlotAssignment:
	if not (stored is Dictionary):
		errors.append("snapshot holds a slot that is not a dictionary")
		return null
	var entry := stored as Dictionary
	var trump_id := _as_id(entry.get(SNAPSHOT_TRUMP, &""))
	if trump_id == &"":
		errors.append("snapshot holds a slot with no Trump in it")
		return null
	var orientation := CardOrientation.from_name_key(_as_id(entry.get(SNAPSHOT_ORIENTATION, &"")))
	if orientation == CardOrientation.UNKNOWN:
		errors.append("snapshot names an orientation this build does not have: %s" % str(
			entry.get(SNAPSHOT_ORIENTATION, "")
		))
		return null
	return SlotAssignment.new(trump_id, orientation as CardOrientation.Id)


## One saved loadout read back, or null with the problem recorded.
func _read_loadout(stored: Dictionary, errors: PackedStringArray) -> SpreadLoadout:
	var label: Variant = stored.get(SNAPSHOT_LABEL, "")
	if not (label is String or label is StringName):
		errors.append("snapshot holds a loadout whose name is not text")
		return null
	var slots: Array[SlotAssignment] = []
	for _slot: SpreadSlot.Id in SpreadSlot.ALL:
		slots.append(SlotAssignment.new())
	var stored_slots: Variant = stored.get(SNAPSHOT_SLOTS, {})
	if not (stored_slots is Dictionary):
		errors.append("snapshot holds a loadout whose slots are not a dictionary")
		return null
	for key: Variant in stored_slots as Dictionary:
		var slot := SpreadSlot.from_name_key(_as_id(key))
		if slot == SpreadSlot.UNKNOWN:
			errors.append("a saved loadout names a spread slot this build does not have: %s" % str(key))
			continue
		var assignment := _read_assignment((stored_slots as Dictionary)[key], errors)
		if assignment != null:
			slots[slot] = assignment
	return SpreadLoadout.new(String(label), slots)


## A snapshot value as an id. Anything that is not text reads as `&""`, which every
## caller then reports: a corrupt save must not be able to crash a load.
func _as_id(value: Variant) -> StringName:
	if value is String or value is StringName:
		return StringName(value)
	return &""
