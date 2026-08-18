class_name WhiteRoseService
extends RefCounted

## The White Rose at the Fool's belt: healing charges, and where they come back.
##
## `docs/design/progression.md` §The White Rose is canon:
##
##   * 3 petals to start, 8 at most, raised in between by **graftings**.
##   * One petal is one fast heal, on a dedicated button.
##   * It **fully regrows at a Waystation**, on rest.
##   * It **regrows slowly** while the Fool is in a region that has been unbound.
##   * It **does not regrow at all in a still-bound region** - "stasis means nothing
##     grows, including the Fool's own healing".
##
## That last rule is the one that makes this a world-state system rather than a
## resource bar, and it is why this service holds `WorldStateService`: a region is
## unbound exactly when its Arcana's unbinding flag has fired, and flags never
## un-fire, so the regrowth rule is a one-way door per region.
##
## **The Cliff never regrows.** It has no Arcana and no unbinding of its own
## (`world.md` §The Cliff), so it is outside the Spread's unbinding entirely - the
## scene passes `&""` as its unbinding flag and the Rose stays still there. That is
## also what MQ00's Waystation beat wants: the tutorial rest is the *first* time the
## player sees petals come back, and a plateau that quietly refilled them beforehand
## would spend the lesson early.
##
## **The Rose spends charges; it does not heal.** `use_petal()` costs a petal and
## announces it. How much health a petal restores is combat's number (round 7), and
## this service deliberately does not know it.

## Petals changed, for any reason.
signal petals_changed(old_petals: int, new_petals: int)

## The maximum changed - a grafting was taken.
signal max_petals_changed(old_max: int, new_max: int)

## A petal was spent on a heal.
signal petal_used()

## A petal grew back on its own (never on a rest - `rest()` emits `petals_changed`).
signal regrown()

## Snapshot keys. The save model writes these verbatim.
const SNAPSHOT_PETALS := "petals"
const SNAPSHOT_GRAFTINGS := "graftings"

## The region id and unbinding flag a Rose that has been told nothing carries.
const UNSET := &""

var _world_state: WorldStateService = null
var _rules: SpreadRules = null

var _petals: int = 0
var _graftings: int = 0

## Where the Fool is, and the flag that would mean this place is awake. The Regions
## round (round 10) owns setting both; until then a scene does it in `_ready`.
var _region_id: StringName = UNSET
var _region_unbinding_flag: StringName = UNSET

## Whether this region's flag has fired. Cached rather than queried every tick: a
## flag can never un-fire, so the cache only ever flips one way, and the service
## subscribes to catch the moment it does.
var _region_is_unbound: bool = false

## Seconds of regrowth banked toward the next petal. Reset by a rest and by leaving
## for a region that does not regrow.
var _regrow_seconds: float = 0.0

var _pristine: bool = true


## Build the Rose over world state (which regions are awake) and its tuning data.
func _init(world_state: WorldStateService, rules: SpreadRules) -> void:
	_world_state = world_state
	_rules = rules
	if world_state == null or rules == null:
		push_error("WhiteRoseService was built without world state or rules")
	_petals = 0 if rules == null else rules.rose_start_petals
	if world_state != null:
		world_state.world_state_fired.connect(_on_world_state_fired)


# --- Reading -----------------------------------------------------------------


## Petals the Rose is holding.
func petals() -> int:
	return _petals


## Petals it can hold: the starting capacity plus one per grafting, capped at the
## doc's maximum of 8.
func max_petals() -> int:
	if _rules == null:
		return 0
	return mini(_rules.rose_start_petals + _graftings, _rules.rose_max_petals)


## How many graftings the Fool has found.
func graftings() -> int:
	return _graftings


## How many graftings could still be taken before the cap.
func graftings_remaining() -> int:
	if _rules == null:
		return 0
	return maxi(0, _rules.rose_max_petals - _rules.rose_start_petals - _graftings)


## The region the Rose believes it is in.
func region_id() -> StringName:
	return _region_id


## True when this region is unbound, so the Rose regrows here.
func regrows_here() -> bool:
	return _region_is_unbound


## True until this service is first mutated or first loaded into.
func is_pristine() -> bool:
	return _pristine


# --- Spending and growing ----------------------------------------------------


## Spend a petal on a heal. False when there is none to spend.
func use_petal() -> bool:
	if _petals <= 0:
		return false
	_set_petals(_petals - 1)
	petal_used.emit()
	return true


## Take a grafting: one more petal of capacity, up to the doc's maximum of 8.
##
## The new petal arrives grown - a grafting found in the world is a flower, not a
## promise of one - so the Rose gains a petal along with the capacity.
func add_grafting() -> bool:
	if _rules == null or graftings_remaining() <= 0:
		return false
	var old_max := max_petals()
	_pristine = false
	_graftings += 1
	max_petals_changed.emit(old_max, max_petals())
	_set_petals(_petals + 1)
	return true


## Rest at a Waystation: every petal, instantly (`progression.md` §Waystations).
##
## A rest is a mutation even when it changes no number. Resting a Rose that is
## already full still spends the Waystation beat, so the service stops being
## pristine and a save can no longer be loaded into it - `_set_petals()` alone would
## have left an already-full Rose looking untouched (see `is_pristine()` and
## `SaveService.apply()`).
func rest() -> void:
	_pristine = false
	_regrow_seconds = 0.0
	_set_petals(max_petals())


## Tell the Rose where the Fool is.
##
## `unbinding_flag` is the flag that would mean this region is awake - the region's
## own Arcana's `WS_*_UNBOUND`. `&""` means the region has no unbinding at all and
## therefore never regrows: the Cliff is the only such place today
## (see the class doc). The Regions round owns calling this.
##
## Banked regrowth does not travel: walking out of a living region and back does not
## resume a petal that was nearly grown somewhere else. Only that banked time is
## behind the "did anything change" check - **the unbound flag is recomputed every
## time**, because a call that repeats the region the Rose is already standing in is
## exactly what happens after a load: `WorldStateService.restore_snapshot()` emits
## nothing, so `_on_world_state_fired()` never runs and this is the only moment the
## Rose can notice that its region came back already awake.
func set_region(region_id_value: StringName, unbinding_flag: StringName) -> void:
	var moved := region_id_value != _region_id or unbinding_flag != _region_unbinding_flag
	_region_id = region_id_value
	_region_unbinding_flag = unbinding_flag
	if moved:
		_regrow_seconds = 0.0
	_region_is_unbound = unbinding_flag != UNSET and _world_state != null and _world_state.is_fired(unbinding_flag)


## Advance regrowth by one frame. Allocates nothing.
##
## A petal comes back every `SpreadRules.rose_regrow_seconds_per_petal` seconds, and
## ONLY in a region whose unbinding flag has fired. In a bound region - and on the
## Cliff, which has no unbinding - this does nothing at all, which is the doc's
## "stasis means nothing grows".
func tick(delta: float) -> void:
	if delta <= 0.0 or _rules == null or not _region_is_unbound:
		return
	if _petals >= max_petals():
		_regrow_seconds = 0.0
		return
	_regrow_seconds += delta
	var per_petal := _rules.rose_regrow_seconds_per_petal
	if per_petal <= 0.0:
		return
	while _regrow_seconds >= per_petal and _petals < max_petals():
		_regrow_seconds -= per_petal
		_set_petals(_petals + 1)
		regrown.emit()
	if _petals >= max_petals():
		_regrow_seconds = 0.0


# --- Save --------------------------------------------------------------------


## Everything the save file needs: petals and graftings, as ints.
##
## Where the Fool is standing is not saved here - `SaveModel.current_region_id`
## already carries it, and the Regions round tells the Rose again on load.
func to_snapshot() -> Dictionary:
	return {
		SNAPSHOT_PETALS: _petals,
		SNAPSHOT_GRAFTINGS: _graftings,
	}


## Load a snapshot, returning every problem it found. Emits nothing.
##
## A fresh service only, all-or-nothing - the same contract `WorldStateService`
## and `FortuneService` keep, and for the same reason.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _pristine:
		errors.append("restore_snapshot needs a fresh White Rose; this one is in play")
		return errors
	var stored_graftings: Variant = data.get(SNAPSHOT_GRAFTINGS, 0)
	var stored_petals: Variant = data.get(SNAPSHOT_PETALS, 0)
	if not (stored_graftings is int or stored_graftings is float):
		errors.append("snapshot graftings are not a number")
	if not (stored_petals is int or stored_petals is float):
		errors.append("snapshot petals are not a number")
	if not errors.is_empty():
		return errors
	var graftings_value := int(stored_graftings)
	var petals_value := int(stored_petals)
	var most_graftings := 0 if _rules == null else _rules.rose_max_petals - _rules.rose_start_petals
	if graftings_value < 0 or graftings_value > most_graftings:
		errors.append("snapshot has %d graftings, outside 0..%d" % [graftings_value, most_graftings])
	if petals_value < 0:
		errors.append("snapshot has %d petals" % petals_value)
	if not errors.is_empty():
		return errors
	var restored_max := 0 if _rules == null else mini(
		_rules.rose_start_petals + graftings_value, _rules.rose_max_petals
	)
	if petals_value > restored_max:
		errors.append("snapshot has %d petals, more than the %d its graftings allow" % [
			petals_value, restored_max
		])
		return errors
	_graftings = graftings_value
	_petals = petals_value
	_regrow_seconds = 0.0
	_pristine = false
	return errors


# --- Internals ---------------------------------------------------------------


## A flag fired somewhere: if it is this region's, the place has just woken up and
## the Rose starts growing again where it stands.
func _on_world_state_fired(flag_id: StringName) -> void:
	if flag_id != _region_unbinding_flag or _region_unbinding_flag == UNSET:
		return
	_region_is_unbound = true
	_regrow_seconds = 0.0


## The one place petals change: clamped to the capacity, announced when they moved.
func _set_petals(new_petals: int) -> void:
	var clamped := clampi(new_petals, 0, max_petals())
	if clamped == _petals:
		return
	var old_petals := _petals
	_pristine = false
	_petals = clamped
	petals_changed.emit(old_petals, clamped)
