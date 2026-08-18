class_name SpreadRules
extends TarrockDefinition

## Every number the Pocket Spread, Fortune and the White Rose run on.
##
## HAND-AUTHORED at `res://data/progression/spread_rules.tres`, from
## `docs/design/progression.md` (§The Pocket Spread, §Fortune, §The White Rose).
## Nothing in the three services spells a number: they ask this resource, which is
## why a designer can retune the whole system by editing one `.tres` and why a test
## can prove a rule is really read from data by retuning it in-test.
##
## **What is canon and what is a placeholder.** The doc fixes: the slot unlock
## pacing (Present with the first Trump, Past at 3, Future at 7), the meter's rough
## size (100), the Present cost band (20-50), the Rose's 3 starting petals and cap
## of 8, and every rule about *when* Fortune is earned and the Rose regrows. The doc
## fixes NO exact number for a per-Trump cost, an earn amount, the overfill size or
## window, a difficulty multiplier, or a regrowth rate - `arcana.md` sets none
## either. Those fields carry TBD placeholders, listed by name in `notes`, and the
## combat-tuning pass owns them. They are here so the system is playable and
## testable, not because anybody decided them.

## The number a field carries when it defers to another rule (a `TrumpEffect` with
## `present_cost` 0 takes the default for its orientation).
const UNSET_COST := 0

## Trumps the Fool must hold before the Present slot opens. Canon: "with the first
## Trump acquired" (progression.md §Slot unlock pacing).
@export var present_unlock_at_held: int = 1

## Trumps held before the Past slot opens. Canon: "Upon holding 3 Trumps".
@export var past_unlock_at_held: int = 3

## Trumps held before the Future slot opens. Canon: "Upon holding 7 Trumps".
@export var future_unlock_at_held: int = 7

## The Fortune meter's size. Canon: "roughly 100 units baseline".
@export var fortune_max: int = 100

## What a Present cast costs upright when its `TrumpEffect` names no cost. TBD:
## the doc gives the 20-50 band, not the number.
@export var default_present_cost_upright: int = 30

## What a Present cast costs reversed when its `TrumpEffect` names no cost. TBD,
## and canon only in being *less* than upright (progression.md §Fortune).
@export var default_present_cost_reversed: int = 20

## How far above `fortune_max` the meter may hold during Fortune's Favor. TBD.
@export var favor_overfill: int = 25

## How long the Favor window stays open after a Fool's Chance. TBD.
@export var favor_window_seconds: float = 6.0

## How fast the overfill drains once the window closes, in Fortune per second. TBD.
## The doc says the overfill "empties back down to the cap if unspent" and sets no
## rate; a rate rather than an instant clamp is what makes the emptying visible.
@export var favor_decay_per_second: float = 10.0

## Fortune for landing a hit. TBD (combat.md §Fortune in combat calls it "the
## baseline trickle" and sets no number).
@export var fortune_per_hit: int = 4

## Fortune for a Fool's Chance. TBD, and canon only in being "a disproportionate
## reward per trigger" (combat.md).
@export var fortune_per_fools_chance: int = 25

## Fortune for finding a new location or a secret. TBD (progression.md §Fortune
## calls it "a flat Fortune bonus").
@export var fortune_per_discovery: int = 15

## Fortune for daring - a near-miss dodge, surviving a high fall. TBD.
@export var fortune_per_daring: int = 10

## Fortune income multiplier on Story. TBD; canon only in that Story "earns
## faster" (combat.md §Difficulty modes).
@export var earn_multiplier_story: float = 1.5

## Fortune income multiplier on Journey, the tuned default. Canon at 1.0 in the
## sense that Journey *is* the baseline the others are described against.
@export var earn_multiplier_journey: float = 1.0

## Fortune income multiplier on Trial. TBD; canon only in being "reduced".
@export var earn_multiplier_trial: float = 0.7

## Petals the White Rose starts with. Canon: "Starting capacity: 3 petals".
@export var rose_start_petals: int = 3

## Petals the White Rose can reach with graftings. Canon: "Maximum: 8".
@export var rose_max_petals: int = 8

## Seconds to regrow one petal in an unbound region. TBD; the doc says "slowly" and
## sets no rate.
@export var rose_regrow_seconds_per_petal: float = 90.0

## The doc section these rules were authored from.
@export var doc_ref: String = ""

## Authoring notes: which of these numbers are canon and which are TBD placeholders.
@export var notes: String = ""


## How many Trumps must be held before `slot` opens.
func held_required_for(slot: SpreadSlot.Id) -> int:
	match slot:
		SpreadSlot.Id.PAST:
			return past_unlock_at_held
		SpreadSlot.Id.PRESENT:
			return present_unlock_at_held
		SpreadSlot.Id.FUTURE:
			return future_unlock_at_held
	return 0


## The Fortune a Present cast costs at this orientation when the effect names none.
func default_present_cost(orientation: CardOrientation.Id) -> int:
	if orientation == CardOrientation.Id.REVERSED:
		return default_present_cost_reversed
	return default_present_cost_upright


## The Fortune income multiplier for a difficulty mode.
func earn_multiplier(mode: DifficultyMode.Id) -> float:
	match mode:
		DifficultyMode.Id.STORY:
			return earn_multiplier_story
		DifficultyMode.Id.TRIAL:
			return earn_multiplier_trial
	return earn_multiplier_journey


## Every problem with these rules; empty means the numbers are usable.
func validate() -> PackedStringArray:
	var errors := super()
	if present_unlock_at_held < 1:
		errors.append("%s opens the Present slot at %d Trumps held" % [
			_describe(), present_unlock_at_held
		])
	if past_unlock_at_held <= present_unlock_at_held:
		errors.append("%s opens Past at %d, not after Present at %d" % [
			_describe(), past_unlock_at_held, present_unlock_at_held
		])
	if future_unlock_at_held <= past_unlock_at_held:
		errors.append("%s opens Future at %d, not after Past at %d" % [
			_describe(), future_unlock_at_held, past_unlock_at_held
		])
	if fortune_max <= 0:
		errors.append("%s has a Fortune meter of %d" % [_describe(), fortune_max])
	if default_present_cost_upright <= 0:
		errors.append("%s has a free upright Present cast" % _describe())
	if default_present_cost_reversed <= 0:
		errors.append("%s has a free reversed Present cast" % _describe())
	if default_present_cost_reversed >= default_present_cost_upright:
		errors.append("%s costs %d reversed, not less than %d upright" % [
			_describe(), default_present_cost_reversed, default_present_cost_upright
		])
	if favor_overfill <= 0:
		errors.append("%s allows no overfill during Fortune's Favor" % _describe())
	if favor_window_seconds <= 0.0:
		errors.append("%s opens no Favor window" % _describe())
	if favor_decay_per_second <= 0.0:
		errors.append("%s never drains the Favor overfill" % _describe())
	for amount: int in [
		fortune_per_hit, fortune_per_fools_chance, fortune_per_discovery, fortune_per_daring
	]:
		if amount < 0:
			errors.append("%s has a negative earn amount: %d" % [_describe(), amount])
	if fortune_per_fools_chance <= fortune_per_hit:
		errors.append("%s pays %d for a Fool's Chance, no more than %d for a hit" % [
			_describe(), fortune_per_fools_chance, fortune_per_hit
		])
	for multiplier: float in [
		earn_multiplier_story, earn_multiplier_journey, earn_multiplier_trial
	]:
		if multiplier <= 0.0:
			errors.append("%s has an earn multiplier of %f" % [_describe(), multiplier])
	if earn_multiplier_story <= earn_multiplier_journey:
		errors.append("%s does not earn faster on Story than on Journey" % _describe())
	if earn_multiplier_trial >= earn_multiplier_journey:
		errors.append("%s does not reduce Fortune income on Trial" % _describe())
	if rose_start_petals <= 0:
		errors.append("%s starts the White Rose with %d petals" % [
			_describe(), rose_start_petals
		])
	if rose_max_petals < rose_start_petals:
		errors.append("%s caps the White Rose at %d, below its %d starting petals" % [
			_describe(), rose_max_petals, rose_start_petals
		])
	if rose_regrow_seconds_per_petal <= 0.0:
		errors.append("%s regrows a petal in %f seconds" % [
			_describe(), rose_regrow_seconds_per_petal
		])
	return errors
