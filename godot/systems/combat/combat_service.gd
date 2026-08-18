class_name CombatService
extends RefCounted

## Everything about a fight that outlives one swing: Fool's Chance, the Fortune a
## fight earns, the difficulty, the accessibility slider, and the defeat loop.
##
## The division of labour across the combat round is worth stating once:
##
##   * `MovesetController` knows what the Fool is doing this frame, and nothing else.
##   * `Combatant` knows how to lose health, and nothing else.
##   * **This** knows what a fight is. It is the only thing that touches
##     `Engine.time_scale`, the only thing that hands the Fool their White Rose to
##     bleed, and the only thing that says a fight has started, so
##     `PocketSpreadService` can lock the Spread ("Swapping is free anywhere, out of
##     combat", `progression.md`).
##
## `docs/design/combat.md` is canon for all of it:
##
##   * §Defense - Fool's Chance is "roughly a 1.5-second slow-motion window, during
##     which the Fool moves at normal speed relative to a slowed world, **and** the
##     next Present-slot Trump cast is free". Both halves are here: the time scale,
##     and `FortuneService.on_fools_chance()` which arms the free cast.
##   * §Fortune in combat - Fortune trickles from landed hits and pays
##     disproportionately for a Fool's Chance. The amounts are `SpreadRules`', not
##     this service's: one fact, one place.
##   * §Difficulty modes - Story takes less damage and gets more generous windows,
##     Trial gets tighter windows and no damage reduction. Fortune income by mode is
##     `FortuneService`'s, and `set_difficulty()` hands it on so one call moves the
##     whole difficulty rather than half of it.
##   * §Accessibility - the Fool's Chance timing-window slider is "independent of
##     difficulty mode", so it is an additive bonus applied AFTER the mode's
##     multiplier, and a player on Story and a player on Trial who set the same slider
##     get the same number of extra milliseconds.
##   * §Defeat - fall, Pip's beat, fade, wake at the last Waystation with the Rose
##     regrown, no penalty. This service owns the *state* half of that loop (the
##     signals, the health, the Rose) and none of the presentation; which Waystation
##     the Fool wakes at is the Regions round's fact, and the scene that plays the
##     beat is what teleports.
##
## **Petals are the health** (director ruling, issue #11). There is no second pool and
## no heal button: `register_fool()` hands the Fool's `Combatant` a `RoseVitality`, so
## every hit that gets past the defence tears quarter petals off `WhiteRoseService`,
## and `combat.md` §Defeat's "the Fool at zero petals" is literally the Rose going
## bare. The only healing in the game is the Rose growing back - slowly in an unbound
## region, whole at a Waystation - which is `progression.md` §The White Rose's rule
## and this service never touches it.

## Fool's Chance began. `real_seconds` is how long it will run in real time, which is
## deliberately not in-game seconds: the world is what slows down.
signal fools_chance_started(real_seconds: float)

## Fool's Chance ended and time is back to normal.
signal fools_chance_ended()

## A fight started or ended, by the engaged-enemy count crossing zero.
signal in_combat_changed(fighting: bool)

## The Fool's last petal is gone. The scene plays `combat.md` §Defeat's four beats;
## `defeat_count` and `at_seconds` are what a Querent line pool needs to remark
## "occasionally" rather than every time.
signal fool_defeated(defeat_count: int, at_seconds: int)

## The Fool is back on their feet at a Waystation, White Rose regrown.
signal fool_revived()

## The smallest time scale `tick()` will divide by, so a paused game (`time_scale` 0)
## cannot turn one frame into an infinite number of real seconds.
const MIN_TIME_SCALE := 0.01

## Normal time.
const NORMAL_TIME_SCALE := 1.0

var _rules: CombatRules = null
var _fortune: FortuneService = null
var _spread: PocketSpreadService = null
var _rose: WhiteRoseService = null
var _clock: GameClock = null

var _difficulty: DifficultyMode.Id = DifficultyMode.DEFAULT

## The accessibility slider, in seconds added to the perfect window.
var _perfect_window_bonus: float = 0.0

var _fool: Combatant = null

## Enemies that have announced themselves. A fight is "in progress" exactly while
## this is not empty.
var _engaged: Array[Combatant] = []

## Real seconds left of Fool's Chance, or 0.
var _fools_chance_left: float = 0.0

var _defeat_count: int = 0
var _defeated: bool = false


## Build the service over its rules and the progression services it spends into.
func _init(
	rules: CombatRules,
	fortune: FortuneService,
	spread: PocketSpreadService,
	rose: WhiteRoseService,
	clock: GameClock
) -> void:
	_rules = rules
	_fortune = fortune
	_spread = spread
	_rose = rose
	_clock = clock
	if rules == null:
		push_error("CombatService was built without its rules")


# --- Difficulty and accessibility --------------------------------------------


## The difficulty being played.
func difficulty() -> DifficultyMode.Id:
	return _difficulty


## Change the difficulty. Fortune income is handed on to `FortuneService` here so one
## call moves the whole mode: a build where combat is on Trial and the meter is still
## earning at Journey rates is not a difficulty setting, it is a bug.
func set_difficulty(mode: DifficultyMode.Id) -> void:
	_difficulty = mode
	if _fortune != null:
		_fortune.set_difficulty(mode)


## Seconds the accessibility slider adds to the perfect window.
func perfect_window_bonus_seconds() -> float:
	return _perfect_window_bonus


## Set the slider (`combat.md` §Accessibility). Negative values are refused: the
## slider widens the window, it never narrows it - narrowing is what Trial is for.
func set_perfect_window_bonus_seconds(seconds: float) -> void:
	_perfect_window_bonus = maxf(0.0, seconds)


## How long before a hit lands a dodge still counts as perfect.
##
## The rules' window, scaled by the difficulty's timing multiplier, PLUS the slider.
## The order is the canon: the slider is "independent of difficulty mode", so it adds
## the same number of seconds whatever mode is on - if it were inside the multiplier,
## Story would silently get more slider than Trial from the same setting.
func perfect_window_seconds() -> float:
	if _rules == null:
		return _perfect_window_bonus
	var scaled := _rules.perfect_window_seconds * _rules.timing_window_multiplier(_difficulty)
	return scaled + _perfect_window_bonus


## What incoming damage to the Fool is multiplied by, on this difficulty.
func damage_taken_multiplier() -> float:
	if _rules == null:
		return 1.0
	return _rules.damage_taken_multiplier(_difficulty)


## The rules this service and the Fool's moveset share.
func rules() -> CombatRules:
	return _rules


# --- The Fool ----------------------------------------------------------------


## Register the Fool's `Combatant`. Its health is pointed at the White Rose, and its
## `died` is what the defeat loop hangs on.
##
## This is the ONE place the ruling on issue #11 is wired: nothing sizes a pool for
## the Fool, because there is no pool to size. The Rose is the pool, and a
## `RoseVitality` is the seam that lets a `Combatant` spend it without knowing what a
## Trump or a Waystation is (see `Vitality`).
func register_fool(combatant: Combatant) -> void:
	if _fool == combatant:
		return
	if _fool != null and is_instance_valid(_fool):
		if _fool.died.is_connected(_on_fool_died):
			_fool.died.disconnect(_on_fool_died)
		_fool.vitality = null
	_fool = combatant
	_defeated = false
	if combatant == null:
		return
	if _rose != null:
		combatant.vitality = RoseVitality.new(_rose)
	if not combatant.died.is_connected(_on_fool_died):
		combatant.died.connect(_on_fool_died)


## The Fool's Combatant, or `null` before one is registered.
func fool() -> Combatant:
	return _fool


## True between the Fool's fall and the return leg of the defeat loop.
func is_defeated() -> bool:
	return _defeated


## How many times the Fool has fallen this session. What a "rotating low-frequency"
## Querent pool counts against (`combat.md` §Defeat, beat 4).
func defeat_count() -> int:
	return _defeat_count


## The White Rose the Fool is fighting on, or null before one is handed over.
func rose() -> WhiteRoseService:
	return _rose


## The return leg of the defeat loop: the Rose regrown, back on their feet.
##
## `combat.md` §Defeat: the Fool "wakes at the last Waystation rested at, White Rose
## regrown... No currency loss, no corpse run, no penalty beyond the walk back". WHICH
## Waystation is a fact the Regions round owns, and the scene that plays the fall, the
## lick and the fade is what actually moves the Fool there; this restores the state
## that has to be true when they open their eyes, and says so.
##
## The Rose is rested directly as well as through the body, because the two are not
## the same call when there is no Fool registered yet - and because a rest is what a
## reader of this function should see, rather than having to follow a `Vitality` to
## find it. Resting a whole Rose changes nothing, so doing it twice costs nothing.
func revive_at_waystation() -> void:
	if _fool == null or not is_instance_valid(_fool):
		return
	end_fools_chance()
	if _rose != null:
		_rose.rest()
	_fool.restore_full_health()
	_defeated = false
	fool_revived.emit()


# --- The fight ---------------------------------------------------------------


## An enemy has joined the fight. Idempotent; a dead enemy leaves on its own.
func enemy_engaged(combatant: Combatant) -> void:
	if combatant == null or not is_instance_valid(combatant) or _engaged.has(combatant):
		return
	_engaged.append(combatant)
	var bound := _on_enemy_died.bind(combatant)
	if not combatant.died.is_connected(bound):
		combatant.died.connect(bound)
	if _engaged.size() == 1:
		_set_in_combat(true)


## An enemy has left the fight (killed, lost interest, despawned).
func enemy_disengaged(combatant: Combatant) -> void:
	var index := _engaged.find(combatant)
	if index < 0:
		return
	_engaged.remove_at(index)
	if combatant != null and is_instance_valid(combatant):
		var bound := _on_enemy_died.bind(combatant)
		if combatant.died.is_connected(bound):
			combatant.died.disconnect(bound)
	if _engaged.is_empty():
		_set_in_combat(false)


## True while at least one enemy is engaged.
func is_in_combat() -> bool:
	return not _engaged.is_empty()


## How many enemies are engaged.
func engaged_count() -> int:
	return _engaged.size()


## The engaged enemies. The service's own array, handed out read-only by convention
## so `FoolCombat` can fill its Focus candidate buffer without allocating one here
## every time the player taps Focus.
func engaged() -> Array[Combatant]:
	return _engaged


## Everybody goes home. Used when a scene unloads or an encounter is scripted shut.
##
## An open Fool's Chance ends with the fight it belonged to. This service is the only
## thing in the game that writes `Engine.time_scale`, so a scene that tore its fight
## down mid-slow-motion and left the window running would leave the whole game at
## 0.3x with nothing on screen to explain it - and the next scene would load slowed.
func clear_engagements() -> void:
	for combatant: Combatant in _engaged:
		if combatant != null and is_instance_valid(combatant):
			var bound := _on_enemy_died.bind(combatant)
			if combatant.died.is_connected(bound):
				combatant.died.disconnect(bound)
	_engaged.clear()
	end_fools_chance()
	_set_in_combat(false)


# --- Fortune ------------------------------------------------------------------


## One of the Fool's hits landed: the baseline Fortune trickle (`combat.md` §Fortune
## in combat, "rewarding staying in the fight rather than turtling"). The amount is
## `SpreadRules.fortune_per_hit`, scaled by the difficulty's income multiplier, and
## neither number is spelled here.
##
## The trickle does not yet depend on WHAT was hit or WITH what, so both arguments go
## unread - but callers pass the real spec and the real `Combatant` anyway, never
## `null`: the day a rank of Blank is worth more than a Beast, or the heavy pays
## differently from a light, this is the function that grows the rule, and a caller
## that had been passing nothing would be a silent hole in it.
func on_fool_hit_landed(_spec: HitSpec, _target: Combatant) -> int:
	if _fortune == null:
		return 0
	return _fortune.earn(FortuneService.EarnSource.HIT)


## The Fool evaded an incoming hit. A perfectly-timed one is Fool's Chance; an
## ordinary one earns **nothing**.
##
## That silence is deliberate and it is the rule the whole defensive economy hangs on.
## `combat.md` §Defense makes Fool's Chance the reward for "a dodge timed to the final
## instant before a hit lands", and §Fortune in combat rewards "staying in the fight
## rather than turtling". Paying Fortune for an ordinary dodge would do the opposite:
## a plain dodge is one button, available on every telegraph, so at
## `SpreadRules.fortune_per_daring` it would out-earn landing hits for a player who
## simply rolled early and often - the exact behaviour Fool's Chance exists NOT to
## reward. The perfect dodge's own free Present cast is the reward for reading the
## telegraph; an early roll gets to keep its health, and that is payment enough.
##
## `FortuneService.EarnSource.DARING` is untouched by this and still has its job:
## `progression.md` §Fortune earns it for "near-miss dodges and surviving high falls",
## and it stays the source for those beats OUTSIDE a fight - the high fall the Fool
## walks away from, the near-miss on the road - paid by whichever system owns them.
## It is simply not what a dodge inside a fight pays, and `SpreadRules.notes` says so
## from the data side.
func on_incoming_hit_dodged(perfect: bool) -> void:
	if perfect:
		trigger_fools_chance()


# --- Fool's Chance ------------------------------------------------------------


## Start (or restart) Fool's Chance: the world slows, and the next Present cast is
## free.
##
## Re-triggering while the window is open RESETS it rather than stacking - a second
## perfect dodge inside a slow-motion window is a second full window, not a longer
## one, and it still pays its Fortune.
func trigger_fools_chance() -> void:
	if _rules == null:
		return
	var was_active := is_fools_chance_active()
	_fools_chance_left = _rules.slowmo_duration_real_seconds
	Engine.time_scale = _rules.slowmo_time_scale
	if _fortune != null:
		_fortune.on_fools_chance()
	if not was_active:
		fools_chance_started.emit(_fools_chance_left)


## True while the world is slowed.
func is_fools_chance_active() -> bool:
	return _fools_chance_left > 0.0


## Real seconds of Fool's Chance left.
func fools_chance_seconds_left() -> float:
	return _fools_chance_left


## Cut the window short and put time back. Used by the defeat loop and by anything
## that has to stop the world being slow right now (a cutscene, a scene change).
func end_fools_chance() -> void:
	if not is_fools_chance_active():
		return
	_fools_chance_left = 0.0
	Engine.time_scale = NORMAL_TIME_SCALE
	fools_chance_ended.emit()


## Advance the service one frame. Called by the composition root with the engine's
## own delta, exactly as `GameClock.advance` is.
##
## The delta arrives ALREADY SCALED by `Engine.time_scale`, so it is divided back out:
## Fool's Chance is "roughly a 1.5-second" window in REAL seconds
## (`combat.md` §Defense), and a window measured in slowed seconds would last
## 1.5 / slowmo_time_scale as long as the doc says. Real time is recovered from the
## engine's own delta rather than read off a wall clock, which is also what makes it
## testable: a test feeds deltas and gets the same answer every run.
func tick(delta: float) -> void:
	if delta <= 0.0 or not is_fools_chance_active():
		return
	var real_seconds := delta / maxf(Engine.time_scale, MIN_TIME_SCALE)
	_fools_chance_left -= real_seconds
	if _fools_chance_left > 0.0:
		return
	_fools_chance_left = 0.0
	Engine.time_scale = NORMAL_TIME_SCALE
	fools_chance_ended.emit()


# --- Internals ---------------------------------------------------------------


## Tell the Pocket Spread whether a fight is on, and announce it.
func _set_in_combat(fighting: bool) -> void:
	if _spread != null:
		_spread.set_in_combat(fighting)
	in_combat_changed.emit(fighting)


## The Rose went bare and the Fool fell. Beat 1 of `combat.md` §Defeat; the scene
## plays beats 2 to 4.
func _on_fool_died() -> void:
	if _defeated:
		return
	_defeated = true
	_defeat_count += 1
	end_fools_chance()
	fool_defeated.emit(_defeat_count, 0 if _clock == null else _clock.whole_seconds())


## An engaged enemy reached zero, so it is out of the fight whatever the scene does
## with the body afterwards.
func _on_enemy_died(combatant: Combatant) -> void:
	enemy_disengaged(combatant)
