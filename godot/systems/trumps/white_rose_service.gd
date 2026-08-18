class_name WhiteRoseService
extends RefCounted

## The White Rose at the Fool's belt: the Fool's vitality, and where it comes back.
##
## **The petals ARE the health** (director ruling, issue #11). There is no second
## pool and no heal button: a hit tears petals off the Rose, and the Rose growing
## back IS healing. `docs/design/art-audio.md` §UI/UX pillars calls the HUD's health
## "health (White Rose petals)"; `docs/design/combat.md` §Defeat is "the Fool at zero
## petals"; and `docs/design/arcana.md`'s Trump effects are written in petals
## throughout - "survive at 1 petal", "when your last petal is spent", "at zero petals
## the Rose reblossoms", Death's burden cutting the MAXIMUM. Every one of those reads
## this service and nothing else.
##
## `docs/design/progression.md` §The White Rose is canon for the shape:
##
##   * 3 petals to start, 8 at most, raised in between by **graftings**.
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
## **Quarters are the resolution; petals are the reading.** Three petals is a very
## short bar to spend a whole combat kit against: a Two and a King would land on the
## same integer, Story's halved damage would round away to nothing, and a Blank rank
## curve would mean nothing at all. So the pool is counted internally in QUARTER
## petals - the Zelda quarter-heart - and drawn as petals with a partial one at the
## end (`RoseMeter`). Everything public that a doc talks in is still petals:
## `petals()`, `max_petals()`, `last_petal_reached`, `bared`.

## The Rose's petals moved, for any reason. Both arguments are in QUARTERS, because
## a hit that costs a quarter is a change a meter has to draw and a whole-petal
## signal would hide.
signal petals_changed(old_quarters: int, new_quarters: int)

## The maximum changed - a grafting was taken (or, one day, Death's burden cut it).
## Both arguments are in whole petals: capacity is only ever whole petals.
signal max_petals_changed(old_max: int, new_max: int)

## The Rose has one petal left. `arcana.md`'s "at one petal remaining" hooks hang
## here. Emitted on the crossing only, never once a frame.
signal last_petal_reached()

## Every petal is gone: the Fool falls. `combat.md` §Defeat's first beat, and
## `arcana.md`'s "when your last petal is spent" / "at zero petals the Rose
## reblossoms". What happens next is `CombatService`'s, never this service's.
signal bared()

## A quarter petal grew back on its own (never on a rest - `rest()` emits
## `petals_changed`).
signal regrown()

## How finely a petal is counted. Four, the quarter-heart: fine enough that a
## difficulty multiplier and a rank curve both survive the rounding, coarse enough
## that the row of petals is still what the player reads.
const QUARTERS_PER_PETAL := 4

## Snapshot keys. The save model writes these verbatim.
const SNAPSHOT_QUARTERS := "quarters"
const SNAPSHOT_GRAFTINGS := "graftings"

## The region id and unbinding flag a Rose that has been told nothing carries.
const UNSET := &""

var _world_state: WorldStateService = null
var _rules: SpreadRules = null

var _quarters: int = 0
var _graftings: int = 0

## Where the Fool is, and the flag that would mean this place is awake. The Regions
## round (round 10) owns setting both; until then a scene does it in `_ready`.
var _region_id: StringName = UNSET
var _region_unbinding_flag: StringName = UNSET

## Whether this region's flag has fired. Cached rather than queried every tick: a
## flag can never un-fire, so the cache only ever flips one way, and the service
## subscribes to catch the moment it does.
var _region_is_unbound: bool = false

## Seconds of regrowth banked toward the next quarter. Reset by a rest and by leaving
## for a region that does not regrow.
var _regrow_seconds: float = 0.0

var _pristine: bool = true


## Build the Rose over world state (which regions are awake) and its tuning data.
func _init(world_state: WorldStateService, rules: SpreadRules) -> void:
	_world_state = world_state
	_rules = rules
	if world_state == null or rules == null:
		push_error("WhiteRoseService was built without world state or rules")
	_quarters = 0 if rules == null else rules.rose_start_petals * QUARTERS_PER_PETAL
	if world_state != null:
		world_state.world_state_fired.connect(_on_world_state_fired)


# --- Reading -----------------------------------------------------------------


## Quarter petals left. The resolution damage and healing are counted in.
func quarters() -> int:
	return _quarters


## Quarter petals the Rose can hold: its capacity in petals, times four.
func max_quarters() -> int:
	return max_petals() * QUARTERS_PER_PETAL


## Petals still on the Rose, rounded UP: a petal half torn is still a petal the
## player can see, and it is the reading `arcana.md`'s "at one petal remaining"
## wants - one quarter left is one petal left, not none.
func petals() -> int:
	return ceili(float(_quarters) / float(QUARTERS_PER_PETAL))


## Petals left as a fraction, for a meter that draws quarter fills.
func petals_left() -> float:
	return float(_quarters) / float(QUARTERS_PER_PETAL)


## Petals it can hold: the starting capacity plus one per grafting, capped at the
## doc's maximum of 8.
func max_petals() -> int:
	if _rules == null:
		return 0
	return mini(_rules.rose_start_petals + _graftings, _rules.rose_max_petals)


## True when the Rose is bare: no petals at all, which is the Fool falling.
func is_bare() -> bool:
	return _quarters <= 0


## True when the Rose is down to its last petal - `arcana.md`'s "at 1 petal" hooks.
func is_on_last_petal() -> bool:
	return _quarters > 0 and _quarters <= QUARTERS_PER_PETAL


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


## Seconds one quarter petal takes to grow back in an unbound region.
##
## Derived rather than authored: `SpreadRules` states the rate the doc talks in - a
## whole petal - and a second number beside it would be two sources for one fact and
## a way for the two to disagree. TBD in size, like the number it divides.
func regrow_seconds_per_quarter() -> float:
	if _rules == null:
		return 0.0
	return _rules.rose_regrow_seconds_per_petal / float(QUARTERS_PER_PETAL)


# --- Losing and growing petals -----------------------------------------------


## Tear `amount` quarter petals off the Rose. Returns how many were actually taken,
## which is less than asked for when the Rose ran out first.
##
## This is the ONLY way the Fool loses health. `Combatant` reaches it through
## `RoseVitality`, so the whole hit rule - i-frames, the hop-guard, the difficulty's
## damage multiplier - is applied before anything gets here.
func take_damage(amount: int) -> int:
	if amount <= 0 or _quarters <= 0:
		return 0
	var taken := mini(amount, _quarters)
	_set_quarters(_quarters - taken)
	return taken


## Grow `amount` quarter petals back. Returns how many were actually restored, which
## is 0 on a whole Rose and 0 on a bare one - a bare Rose is a fallen Fool, and the
## defeat loop is what brings them back, not a trickle (`combat.md` §Defeat).
func heal(amount: int) -> int:
	if amount <= 0 or _quarters <= 0:
		return 0
	var before := _quarters
	_set_quarters(_quarters + amount)
	return _quarters - before


## Take a grafting: one more petal of capacity, up to the doc's maximum of 8.
##
## The new petal arrives grown - a grafting found in the world is a flower, not a
## promise of one - so the Rose gains four quarters along with the capacity.
func add_grafting() -> bool:
	if _rules == null or graftings_remaining() <= 0:
		return false
	var old_max := max_petals()
	_pristine = false
	_graftings += 1
	max_petals_changed.emit(old_max, max_petals())
	_set_quarters(_quarters + QUARTERS_PER_PETAL)
	return true


## Rest at a Waystation: every petal, instantly (`progression.md` §Waystations).
##
## A rest is a mutation even when it changes no number. Resting a Rose that is
## already full still spends the Waystation beat, so the service stops being
## pristine and a save can no longer be loaded into it - `_set_quarters()` alone
## would have left an already-full Rose looking untouched (see `is_pristine()` and
## `SaveService.apply()`).
##
## It is also the return leg of the defeat loop: a bare Rose is filled from here and
## from nowhere else.
func rest() -> void:
	_pristine = false
	_regrow_seconds = 0.0
	_set_quarters(max_quarters())


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
## A QUARTER petal comes back every `regrow_seconds_per_quarter()` seconds, and ONLY
## in a region whose unbinding flag has fired. In a bound region - and on the Cliff,
## which has no unbinding - this does nothing at all, which is the doc's "stasis means
## nothing grows".
##
## A bare Rose grows nothing either: the Fool is down, and `combat.md` §Defeat brings
## them back at a Waystation rather than by standing still in a friendly field.
func tick(delta: float) -> void:
	if delta <= 0.0 or _rules == null or not _region_is_unbound or _quarters <= 0:
		return
	if _quarters >= max_quarters():
		_regrow_seconds = 0.0
		return
	_regrow_seconds += delta
	var per_quarter := regrow_seconds_per_quarter()
	if per_quarter <= 0.0:
		return
	while _regrow_seconds >= per_quarter and _quarters < max_quarters():
		_regrow_seconds -= per_quarter
		_set_quarters(_quarters + 1)
		regrown.emit()
	if _quarters >= max_quarters():
		_regrow_seconds = 0.0


# --- Save --------------------------------------------------------------------


## Everything the save file needs: quarter petals and graftings, as ints.
##
## Where the Fool is standing is not saved here - `SaveModel.current_region_id`
## already carries it, and the Regions round tells the Rose again on load.
func to_snapshot() -> Dictionary:
	return {
		SNAPSHOT_QUARTERS: _quarters,
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
	var stored_quarters: Variant = data.get(SNAPSHOT_QUARTERS, 0)
	if not (stored_graftings is int or stored_graftings is float):
		errors.append("snapshot graftings are not a number")
	if not (stored_quarters is int or stored_quarters is float):
		errors.append("snapshot quarters are not a number")
	if not errors.is_empty():
		return errors
	var graftings_value := int(stored_graftings)
	var quarters_value := int(stored_quarters)
	var most_graftings := 0 if _rules == null else _rules.rose_max_petals - _rules.rose_start_petals
	if graftings_value < 0 or graftings_value > most_graftings:
		errors.append("snapshot has %d graftings, outside 0..%d" % [graftings_value, most_graftings])
	if quarters_value < 0:
		errors.append("snapshot has %d quarter petals" % quarters_value)
	if not errors.is_empty():
		return errors
	var restored_max := 0 if _rules == null else mini(
		_rules.rose_start_petals + graftings_value, _rules.rose_max_petals
	) * QUARTERS_PER_PETAL
	if quarters_value > restored_max:
		errors.append("snapshot has %d quarter petals, more than the %d its graftings allow" % [
			quarters_value, restored_max
		])
		return errors
	_graftings = graftings_value
	_quarters = quarters_value
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


## The one place quarters change: clamped to the capacity, announced when they moved.
##
## The two threshold signals are emitted on the CROSSING and after the change, so an
## effect that reads the Rose from inside one sees the number that fired it. Neither
## repeats while the Rose sits at the threshold - `arcana.md`'s hooks read "when your
## last petal is spent", not "while it is spent".
func _set_quarters(new_quarters: int) -> void:
	var clamped := clampi(new_quarters, 0, max_quarters())
	if clamped == _quarters:
		return
	var old_quarters := _quarters
	_pristine = false
	_quarters = clamped
	petals_changed.emit(old_quarters, clamped)
	if clamped <= 0:
		bared.emit()
	elif clamped <= QUARTERS_PER_PETAL and old_quarters > QUARTERS_PER_PETAL:
		last_petal_reached.emit()
