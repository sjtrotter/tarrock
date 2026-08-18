class_name CombatRules
extends TarrockDefinition

## Every number the Bindle moveset, Focus, the dodges, Fool's Chance, the difficulty
## modes and the defeat loop run on.
##
## HAND-AUTHORED at `res://data/combat/combat_rules.tres`, from
## `docs/design/combat.md` (§The Bindle, §Focus, §Defense, §Defeat, §Difficulty
## modes, §Accessibility). Nothing in `systems/combat/` spells a number: it asks this
## resource, which is why a designer can retune the whole kit by editing one `.tres`
## and why a test can prove a rule is really read from data by retuning it in-test.
## Same contract as `SpreadRules` in the round before this one.
##
## **What is canon and what is a placeholder.** `combat.md` fixes the SHAPES and
## almost none of the numbers, and it says so itself: "Exact i-frame duration and the
## width of the 'perfect' timing window are tuning values, not design facts". The
## three numbers the doc does state are the light string's **three** hits, Fool's
## Chance's "roughly a 1.5-second" slow-motion window, and the grand backflip's
## "roughly 1.5 body-widths". Everything else here is a TBD placeholder, listed by
## name in `notes`, owned by the combat-tuning pass. They exist so the kit is
## playable and testable, not because anybody decided them.
##
## Fortune's own numbers are NOT here - they live in `SpreadRules` (the meter, the
## per-source earn amounts, the per-difficulty income multipliers). One fact, one
## place: this resource owns what difficulty does to *damage taken* and to *timing
## windows*, and nothing else about difficulty.
##
## **The Fool's health is not a number here.** Per the director's ruling on issue #11
## the White Rose's petals ARE the Fool's health, so the capacity lives in
## `SpreadRules` (3 petals, 8 with graftings) and the pool lives in
## `WhiteRoseService`. There is no `fool_max_health` and no `petal_heal`: there is no
## second pool to size and no heal button to price.

## How many hits the light string has. CANON: "Three-hit staff combo" (`combat.md`
## §The Bindle). The per-hit arrays below must all be this long.
const LIGHT_STRING_HITS := 3

## The backflip's distance, in body widths. CANON: "roughly 1.5 body-widths"
## (`combat.md` §Focus). A constant rather than an `@export` because it is the one
## distance in the kit the doc actually states.
const BACKFLIP_BODY_WIDTHS := 1.5

## The narrowest a perfect window may be once the tightest difficulty mode has
## multiplied it: three physics frames at 60 Hz.
##
## Not a tuning number - a floor under the tuning. A hit is resolved on a physics
## frame, so a window worth fewer than about three of them cannot be aimed at: the
## player would be pressing dodge into a one- or two-frame slot and reading the result
## as luck, which is the opposite of `combat.md` §Philosophy's "readable" combat.
## Trial "tightens timing windows"; it does not turn Fool's Chance into a coin toss.
## `validate()` enforces it against the SMALLEST timing multiplier in the table, so a
## retune that tightens Trial has to widen the window with it.
const MIN_PERFECT_WINDOW_SECONDS := 0.05

# --- The light string --------------------------------------------------------

## Windup seconds per hit of the light string, hit 1 first. TBD.
@export var light_windup_seconds: PackedFloat32Array = PackedFloat32Array([0.12, 0.10, 0.16])

## Active (hit-window) seconds per hit. TBD.
@export var light_active_seconds: PackedFloat32Array = PackedFloat32Array([0.08, 0.08, 0.10])

## Recovery seconds per hit; the third is longest, which is what makes the string a
## commitment rather than a mash. TBD.
@export var light_recovery_seconds: PackedFloat32Array = PackedFloat32Array([0.20, 0.22, 0.40])

## Damage per hit. TBD.
@export var light_damage: PackedInt32Array = PackedInt32Array([6, 6, 10])

## How long after a light hit STARTS the next light input may arrive and still chain
## (the window is armed on the hit's first frame, so it has to outlast that hit's
## windup, active and recovery for the string to survive the gap between them).
## Outside it the string resets to hit 1. TBD.
@export var light_combo_window_seconds: float = 0.45

## The light string's arc, in degrees, centred on the facing. TBD.
@export var light_arc_degrees: float = 80.0

## The light string's reach, in pixels. TBD.
@export var light_radius: float = 96.0

# --- The heavy sweep ---------------------------------------------------------

## Heavy windup. Long enough to read as a commitment. TBD.
@export var heavy_windup_seconds: float = 0.34

## Heavy active window. TBD.
@export var heavy_active_seconds: float = 0.16

## Heavy recovery. TBD.
@export var heavy_recovery_seconds: float = 0.50

## Heavy damage. TBD.
@export var heavy_damage: int = 14

## The heavy's arc. CANON in being WIDE - "the bundle end drags through the strike,
## hitting everything in an arc", the answer to groups (`combat.md` §The Bindle) -
## TBD in the number.
@export var heavy_arc_degrees: float = 200.0

## The heavy's reach. TBD.
@export var heavy_radius: float = 128.0

# --- The charged heavy, i.e. the stagger launcher ----------------------------

## How long the heavy must be held before the release is the stagger launcher rather
## than a plain heavy. TBD.
@export var charge_seconds: float = 0.70

## How fast the Fool may walk while charging, as a fraction of normal speed. TBD.
@export var charge_movement_multiplier: float = 0.40

## Charged-heavy windup. TBD.
@export var charged_heavy_windup_seconds: float = 0.22

## Charged-heavy active window. TBD.
@export var charged_heavy_active_seconds: float = 0.18

## Charged-heavy recovery. TBD.
@export var charged_heavy_recovery_seconds: float = 0.60

## Charged-heavy damage, before the stagger bonus (which cannot apply to the hit
## that causes the stagger). TBD.
@export var charged_heavy_damage: int = 18

## The charged heavy's arc. Tighter than the crowd sweep: it is an opener aimed at
## one target, not a group answer. TBD.
@export var charged_heavy_arc_degrees: float = 140.0

## The charged heavy's reach. TBD.
@export var charged_heavy_radius: float = 120.0

## How long a staggered target is helpless. CANON in existing ("a brief helpless
## stagger that opens bonus follow-ups"), TBD in length.
@export var stagger_seconds: float = 1.60

## Damage multiplier on a hit landed against a staggered target. CANON in existing
## ("bonus follow-ups"), TBD in size.
@export var stagger_bonus_multiplier: float = 1.50

# --- The running attack ------------------------------------------------------

## How fast the Fool must already be moving, as a fraction of top speed, for an
## attack input to come out as the lunge instead of the light string. TBD.
@export var running_attack_min_speed_fraction: float = 0.90

## How far the lunge carries the Fool forward. TBD.
@export var running_attack_lunge_distance: float = 120.0

## Running-attack windup. Short: the move exists to close distance and interrupt.
## TBD.
@export var running_attack_windup_seconds: float = 0.14

## Running-attack active window. TBD.
@export var running_attack_active_seconds: float = 0.12

## Running-attack recovery. TBD.
@export var running_attack_recovery_seconds: float = 0.40

## Running-attack damage. TBD.
@export var running_attack_damage: int = 12

## The lunge's hit box, as (width across the lunge, length along it). A box rather
## than an arc because a lunge is a line, not a sweep. TBD.
@export var running_attack_box_size: Vector2 = Vector2(64.0, 140.0)

# --- The Fool's body ---------------------------------------------------------

## One body width, in pixels: the unit `combat.md` measures the backflip in. TBD.
@export var body_width: float = 48.0

# --- Dodges (roll, side-hop, backflip) ---------------------------------------

## How long the dodge roll lasts. TBD (`combat.md`: i-frame numbers are explicitly
## tuning values).
@export var dodge_roll_seconds: float = 0.50

## How far the roll carries the Fool. TBD.
@export var dodge_roll_distance: float = 160.0

## When invincibility opens, in seconds from the start of ANY dodge. All three
## directional dodges "share the roll's i-frame rules" (`combat.md` §Focus). TBD.
@export var dodge_iframe_start_seconds: float = 0.06

## When invincibility closes, in seconds from the start of any dodge. The window is
## half-open: `[start, end)`. TBD.
@export var dodge_iframe_end_seconds: float = 0.34

## How long the Focus side-hop lasts. TBD.
@export var side_hop_seconds: float = 0.38

## How far the side-hop carries the Fool. TBD.
@export var side_hop_distance: float = 120.0

## How long the grand backflip lasts. Longer than the others: it is "theater as much
## as evasion". TBD.
@export var backflip_seconds: float = 0.60

# --- Block-step --------------------------------------------------------------

## How long the hop-guard lasts. TBD.
@export var block_step_seconds: float = 0.45

## How much of the hop-guard actually absorbs. Shorter than the state, so a block
## that is late still commits the Fool - `combat.md` gives it "no counter-window of
## its own", and a guard that covered its whole recovery would be one. TBD.
@export var block_step_guard_seconds: float = 0.30

## How far the hop-guard repositions the Fool, away from the facing. CANON in
## existing ("absorbs a hit and repositions slightly"), TBD in distance.
@export var block_step_reposition_distance: float = 64.0

# --- Fool's Chance -----------------------------------------------------------

## The last instant before a hit lands, in seconds: a dodge whose I-FRAMES opened
## within this long of being hit is perfect. Measured from `dodge_iframe_start_seconds`
## rather than from the dodge's first frame, because the frames before i-frames open
## are frames where the hit simply lands - see
## `MovesetController.perfect_dodge_started_within()`. `combat.md` calls this a tuning
## value in as many words, but `MIN_PERFECT_WINDOW_SECONDS` is the floor it may not be
## tuned under. TBD.
@export var perfect_window_seconds: float = 0.12

## `Engine.time_scale` while Fool's Chance runs. TBD; canon only in that the world
## slows and the Fool does not.
@export var slowmo_time_scale: float = 0.30

## How long Fool's Chance lasts in REAL seconds. CANON: "roughly a 1.5-second
## slow-motion window" (`combat.md` §Defense).
@export var slowmo_duration_real_seconds: float = 1.50

# --- Focus targeting ---------------------------------------------------------

## How far away a target may be and still be acquired by Focus. TBD.
@export var focus_max_range: float = 480.0

## How hard Focus prefers a candidate the Fool is already facing, over a nearer one
## off to the side. 0 = nearest wins outright. TBD.
@export var focus_cone_weight: float = 1.0

# --- Defeat ------------------------------------------------------------------

## How long the defeat fade takes before the Fool wakes at the last Waystation
## (`combat.md` §Defeat step 3, "a brief fade over the lick"). The scene plays it;
## this is the length it plays for. TBD.
@export var defeat_fade_seconds: float = 1.20

# --- Movement while committed ------------------------------------------------

## How fast the Fool may move during an attack's windup and active frames.
## `combat.md`: every action has "a clear windup, a clear active frame, and recovery
## the player can feel". TBD, though 0 is close to a design fact.
@export var attack_movement_multiplier: float = 0.0

## How fast the Fool may move during an attack's recovery. Not zero - recovery is
## felt, not frozen. TBD.
@export var recovery_movement_multiplier: float = 0.25

# --- Difficulty --------------------------------------------------------------

## Damage taken multiplier on Story. CANON in direction ("reduced damage taken"),
## TBD in size.
@export var damage_taken_multiplier_story: float = 0.50

## Damage taken multiplier on Journey, the tuned baseline the others are described
## against. CANON at 1.0 in that sense.
@export var damage_taken_multiplier_journey: float = 1.0

## Damage taken multiplier on Trial. CANON at 1.0: "no damage reduction".
@export var damage_taken_multiplier_trial: float = 1.0

## Timing-window multiplier on Story. CANON in direction ("generous timing
## windows"), TBD in size.
@export var timing_window_multiplier_story: float = 1.50

## Timing-window multiplier on Journey. The baseline.
@export var timing_window_multiplier_journey: float = 1.0

## Timing-window multiplier on Trial. CANON in direction ("tightened timing
## windows"), TBD in size.
@export var timing_window_multiplier_trial: float = 0.70


# --- Provenance ---------------------------------------------------------------

## The doc section these rules were authored from.
@export var doc_ref: String = ""

## Authoring notes: which of these numbers are canon and which are TBD placeholders,
## by name. Read by reviewers and by the mini drift test, never displayed.
@export var notes: String = ""


# --- Reading -----------------------------------------------------------------


## Windup seconds for light hit `index` (0-based). 0 for an index off the string.
func light_windup(index: int) -> float:
	return _float_at(light_windup_seconds, index)


## Active seconds for light hit `index`.
func light_active(index: int) -> float:
	return _float_at(light_active_seconds, index)


## Recovery seconds for light hit `index`.
func light_recovery(index: int) -> float:
	return _float_at(light_recovery_seconds, index)


## Damage for light hit `index`.
func light_damage_at(index: int) -> int:
	if index < 0 or index >= light_damage.size():
		return 0
	return light_damage[index]


## How far the grand backflip carries the Fool: `combat.md`'s 1.5 body-widths,
## resolved against this rules table's body width.
func backflip_distance() -> float:
	return body_width * BACKFLIP_BODY_WIDTHS


## The damage-taken multiplier for a difficulty mode (`combat.md` §Difficulty modes).
func damage_taken_multiplier(mode: DifficultyMode.Id) -> float:
	match mode:
		DifficultyMode.Id.STORY:
			return damage_taken_multiplier_story
		DifficultyMode.Id.TRIAL:
			return damage_taken_multiplier_trial
	return damage_taken_multiplier_journey


## The timing-window multiplier for a difficulty mode. Every window the player has
## to hit - the perfect-dodge window today, an enemy telegraph tomorrow - is scaled
## by this one number, so a mode widens or tightens combat coherently.
func timing_window_multiplier(mode: DifficultyMode.Id) -> float:
	match mode:
		DifficultyMode.Id.STORY:
			return timing_window_multiplier_story
		DifficultyMode.Id.TRIAL:
			return timing_window_multiplier_trial
	return timing_window_multiplier_journey


## Every problem with these rules; empty means the numbers are usable.
func validate() -> PackedStringArray:
	var errors := super()
	_check_string_length(errors, light_windup_seconds.size(), &"light_windup_seconds")
	_check_string_length(errors, light_active_seconds.size(), &"light_active_seconds")
	_check_string_length(errors, light_recovery_seconds.size(), &"light_recovery_seconds")
	_check_string_length(errors, light_damage.size(), &"light_damage")
	if light_combo_window_seconds <= 0.0:
		errors.append("%s gives the light string no combo window" % _describe())
	if heavy_arc_degrees <= light_arc_degrees:
		errors.append("%s sweeps %.0f degrees heavy, no wider than %.0f light" % [
			_describe(), heavy_arc_degrees, light_arc_degrees
		])
	if charge_seconds <= 0.0:
		errors.append("%s charges the heavy instantly" % _describe())
	if stagger_seconds <= 0.0:
		errors.append("%s staggers nobody: the launcher opens no window" % _describe())
	if stagger_bonus_multiplier <= 1.0:
		errors.append("%s pays %.2f against a staggered target, which is no bonus" % [
			_describe(), stagger_bonus_multiplier
		])
	if dodge_iframe_start_seconds < 0.0 or dodge_iframe_end_seconds <= dodge_iframe_start_seconds:
		errors.append("%s opens i-frames at %.3f and closes them at %.3f" % [
			_describe(), dodge_iframe_start_seconds, dodge_iframe_end_seconds
		])
	if dodge_iframe_end_seconds > dodge_roll_seconds:
		errors.append("%s keeps i-frames %.3f into a %.3f roll" % [
			_describe(), dodge_iframe_end_seconds, dodge_roll_seconds
		])
	if side_hop_seconds <= 0.0 or backflip_seconds <= 0.0 or dodge_roll_seconds <= 0.0:
		errors.append("%s has a dodge of no duration" % _describe())
	if block_step_guard_seconds <= 0.0 or block_step_guard_seconds > block_step_seconds:
		errors.append("%s guards for %.3f of a %.3f block-step" % [
			_describe(), block_step_guard_seconds, block_step_seconds
		])
	if perfect_window_seconds <= 0.0:
		errors.append("%s makes Fool's Chance unreachable" % _describe())
	if perfect_window_seconds > dodge_iframe_end_seconds - dodge_iframe_start_seconds:
		errors.append("%s has a perfect window of %.3f wider than its own i-frames" % [
			_describe(), perfect_window_seconds
		])
	var tightest_mode := minf(
		timing_window_multiplier_journey,
		minf(timing_window_multiplier_story, timing_window_multiplier_trial)
	)
	if perfect_window_seconds * tightest_mode < MIN_PERFECT_WINDOW_SECONDS:
		errors.append("%s leaves %.3f s of perfect window on its tightest mode, under the %.3f s floor" % [
			_describe(), perfect_window_seconds * tightest_mode, MIN_PERFECT_WINDOW_SECONDS
		])
	if slowmo_time_scale <= 0.0 or slowmo_time_scale >= 1.0:
		errors.append("%s slows the world to %.2f, which is not slow motion" % [
			_describe(), slowmo_time_scale
		])
	if slowmo_duration_real_seconds <= 0.0:
		errors.append("%s runs Fool's Chance for no time at all" % _describe())
	if body_width <= 0.0:
		errors.append("%s measures the backflip against a body of no width" % _describe())
	if running_attack_min_speed_fraction <= 0.0 or running_attack_min_speed_fraction > 1.0:
		errors.append("%s asks for %.2f of top speed before the lunge" % [
			_describe(), running_attack_min_speed_fraction
		])
	if damage_taken_multiplier_story > damage_taken_multiplier_journey:
		errors.append("%s takes more damage on Story than on Journey" % _describe())
	if damage_taken_multiplier_trial < damage_taken_multiplier_journey:
		errors.append("%s reduces damage on Trial, which has none" % _describe())
	if timing_window_multiplier_story <= timing_window_multiplier_journey:
		errors.append("%s is no more generous on Story than on Journey" % _describe())
	if timing_window_multiplier_trial >= timing_window_multiplier_journey:
		errors.append("%s does not tighten its windows on Trial" % _describe())
	if attack_movement_multiplier < 0.0 or attack_movement_multiplier > 1.0:
		errors.append("%s scales committed movement by %.2f" % [
			_describe(), attack_movement_multiplier
		])
	if recovery_movement_multiplier < attack_movement_multiplier:
		errors.append("%s moves slower in recovery than mid-swing" % _describe())
	if focus_max_range <= 0.0:
		errors.append("%s lets Focus reach nothing" % _describe())
	return errors


# --- Internals ---------------------------------------------------------------


## One entry of a per-hit float array, or 0 for an index off the end.
func _float_at(values: PackedFloat32Array, index: int) -> float:
	if index < 0 or index >= values.size():
		return 0.0
	return values[index]


## Every per-hit array has to be exactly as long as the string is hits, or a hit
## silently costs nothing and deals nothing.
func _check_string_length(errors: PackedStringArray, size: int, field: StringName) -> void:
	if size == LIGHT_STRING_HITS:
		return
	errors.append("%s has %d entries in %s, not %d" % [
		_describe(), size, field, LIGHT_STRING_HITS
	])
