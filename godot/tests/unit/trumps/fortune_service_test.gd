extends TarrockTest

## The Fortune meter: earning, the cap, Fortune's Favor, and the free cast.
##
## `docs/design/progression.md` §Fortune and `docs/design/combat.md` §Defense /
## §Fortune in combat / §Difficulty modes are the canon. Every number is read from
## a *retuned* copy of `SpreadRules`, so a service that spelled one in code would
## fail here rather than pass by coincidence.
##
## Nothing in this suite waits on the wall clock: `tick(delta)` is fed exact deltas.

const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"

var _rules: SpreadRules = null
var _fortune: FortuneService = null


func before_each() -> void:
	# A duplicate, not the shared resource: retuning the loaded one would leak into
	# every other suite that loads it.
	_rules = (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	_fortune = FortuneService.new(_rules)


# --- Earning -----------------------------------------------------------------


func test_a_new_meter_is_empty() -> void:
	assert_eq(_fortune.value(), 0, "the Fool starts with nothing to spend")
	assert_eq(_fortune.max_value(), _rules.fortune_max)
	assert_false(_fortune.has_free_cast())
	assert_true(_fortune.is_pristine())


func test_each_source_pays_its_own_row_of_the_table() -> void:
	_rules.fortune_per_hit = 3
	_rules.fortune_per_discovery = 11
	_rules.fortune_per_daring = 7
	assert_eq(_fortune.earn(FortuneService.EarnSource.HIT), 3)
	assert_eq(_fortune.earn(FortuneService.EarnSource.DISCOVERY), 11)
	assert_eq(_fortune.earn(FortuneService.EarnSource.DARING), 7)
	assert_eq(_fortune.value(), 21, "the meter is the sum of what was earned")


func test_a_fools_chance_pays_more_than_a_hit() -> void:
	# combat.md: "a disproportionate reward per trigger" - mastering the perfect
	# dodge is meant to be the fastest route to power.
	assert_true(_rules.fortune_per_fools_chance > _rules.fortune_per_hit)


func test_earning_is_announced() -> void:
	watch_signal(_fortune, &"fortune_changed")
	_fortune.earn(FortuneService.EarnSource.HIT)
	assert_signal_emitted(_fortune, &"fortune_changed", 1)
	assert_eq(signal_arguments(_fortune, &"fortune_changed", 0), [0, _rules.fortune_per_hit])


func test_story_earns_faster_and_trial_earns_less() -> void:
	_rules.fortune_per_hit = 10
	_rules.earn_multiplier_story = 1.5
	_rules.earn_multiplier_trial = 0.7
	var story := FortuneService.new(_rules, DifficultyMode.Id.STORY)
	var journey := FortuneService.new(_rules, DifficultyMode.Id.JOURNEY)
	var trial := FortuneService.new(_rules, DifficultyMode.Id.TRIAL)
	assert_eq(story.earn(FortuneService.EarnSource.HIT), 15, "Story earns faster")
	assert_eq(journey.earn(FortuneService.EarnSource.HIT), 10, "Journey is the baseline")
	assert_eq(trial.earn(FortuneService.EarnSource.HIT), 7, "Trial earns less")


func test_the_difficulty_can_change_mid_playthrough() -> void:
	_rules.fortune_per_hit = 10
	_fortune.set_difficulty(DifficultyMode.Id.TRIAL)
	assert_eq(_fortune.difficulty(), DifficultyMode.Id.TRIAL)
	assert_eq(_fortune.earn(FortuneService.EarnSource.HIT), 7)


func test_an_override_still_takes_the_difficulty_multiplier() -> void:
	_rules.earn_multiplier_trial = 0.5
	var trial := FortuneService.new(_rules, DifficultyMode.Id.TRIAL)
	assert_eq(trial.earn(FortuneService.EarnSource.DISCOVERY, 40), 20, "income scales, not sources")


func test_earning_stops_at_the_cap() -> void:
	_rules.fortune_max = 30
	_rules.fortune_per_discovery = 25
	_fortune.earn(FortuneService.EarnSource.DISCOVERY)
	assert_eq(_fortune.earn(FortuneService.EarnSource.DISCOVERY), 5, "only the room that was left")
	assert_eq(_fortune.value(), 30)
	assert_eq(_fortune.earn(FortuneService.EarnSource.DISCOVERY), 0, "a full meter earns nothing")


# --- Fortune's Favor ---------------------------------------------------------


func test_a_fools_chance_overfills_the_meter() -> void:
	# progression.md: "immediately after a Fool's Chance, the meter can briefly hold
	# *more* than its normal maximum".
	_rules.fortune_max = 50
	_rules.favor_overfill = 20
	_rules.fortune_per_fools_chance = 40
	_rules.fortune_per_discovery = 45
	_fortune.earn(FortuneService.EarnSource.DISCOVERY)
	assert_eq(_fortune.value(), 45)
	watch_signal(_fortune, &"favor_opened")
	watch_signal(_fortune, &"free_cast_armed")
	_fortune.on_fools_chance()
	assert_signal_emitted(_fortune, &"favor_opened", 1)
	assert_signal_emitted(_fortune, &"free_cast_armed", 1)
	assert_eq(_fortune.value(), 70, "the overfill window let the meter pass its cap")
	assert_true(_fortune.is_favor_open())
	assert_true(_fortune.has_free_cast())


func test_the_overfill_never_exceeds_the_windows_own_ceiling() -> void:
	_rules.fortune_max = 50
	_rules.favor_overfill = 10
	_rules.fortune_per_fools_chance = 500
	_fortune.on_fools_chance()
	assert_eq(_fortune.value(), 60, "cap plus overfill and no further")
	assert_eq(_fortune.ceiling(), 60)


func test_the_overfill_drains_back_to_the_cap_after_the_window() -> void:
	_rules.fortune_max = 50
	_rules.favor_overfill = 20
	_rules.fortune_per_fools_chance = 70
	_rules.favor_window_seconds = 2.0
	_rules.favor_decay_per_second = 10.0
	_fortune.on_fools_chance()
	assert_eq(_fortune.value(), 70)
	watch_signal(_fortune, &"favor_closed")
	_fortune.tick(1.0)
	assert_eq(_fortune.value(), 70, "nothing drains while the window is open")
	assert_signal_emitted(_fortune, &"favor_closed", 0)
	_fortune.tick(1.0)
	assert_signal_emitted(_fortune, &"favor_closed", 1, "the window closed on time")
	assert_eq(_fortune.value(), 70, "the closing frame had no time left to drain with")
	_fortune.tick(1.0)
	assert_eq(_fortune.value(), 60, "ten per second, drained")
	_fortune.tick(5.0)
	assert_eq(_fortune.value(), 50, "and it stops at the cap, not below it")
	_fortune.tick(5.0)
	assert_eq(_fortune.value(), 50)


func test_a_long_frame_drains_with_the_time_left_over() -> void:
	# The drain must not depend on the frame rate: a frame that both closes the
	# window and overruns it drains with its own remainder.
	_rules.fortune_max = 50
	_rules.favor_overfill = 20
	_rules.fortune_per_fools_chance = 70
	_rules.favor_window_seconds = 1.0
	_rules.favor_decay_per_second = 10.0
	_fortune.on_fools_chance()
	_fortune.tick(1.5)
	assert_eq(_fortune.value(), 65, "half a second of drain after the window closed")


func test_spending_inside_the_window_keeps_the_overfill() -> void:
	# The overfill exists to be spent: "encouraging the player to actually spend the
	# free cast's momentum rather than bank it forever".
	_rules.fortune_max = 50
	_rules.favor_overfill = 20
	_rules.fortune_per_fools_chance = 70
	_fortune.on_fools_chance()
	assert_true(_fortune.spend(30), "the free cast pays for the first one")
	assert_eq(_fortune.value(), 70, "a free cast costs no Fortune")
	assert_true(_fortune.spend(65), "and the overfill really is spendable")
	assert_eq(_fortune.value(), 5)


# --- The free cast -----------------------------------------------------------


func test_the_free_cast_is_spent_instead_of_fortune() -> void:
	# combat.md §Defense: after a Fool's Chance "the next Present-slot Trump cast is
	# free (no Fortune cost)".
	_fortune.on_fools_chance()
	var banked := _fortune.value()
	watch_signal(_fortune, &"free_cast_consumed")
	assert_true(_fortune.spend(30))
	assert_signal_emitted(_fortune, &"free_cast_consumed", 1)
	assert_eq(_fortune.value(), banked, "the meter did not move")
	assert_false(_fortune.has_free_cast(), "and it is spent, once")


func test_a_second_fools_chance_does_not_stack_free_casts() -> void:
	_fortune.on_fools_chance()
	_fortune.on_fools_chance()
	assert_true(_fortune.spend(30))
	assert_false(_fortune.has_free_cast(), "one free cast, not two")


func test_spending_more_than_the_meter_holds_is_refused() -> void:
	_fortune.earn(FortuneService.EarnSource.HIT)
	var held := _fortune.value()
	assert_false(_fortune.can_afford(held + 1))
	assert_false(_fortune.spend(held + 1), "an unaffordable cast changes nothing")
	assert_eq(_fortune.value(), held)
	assert_true(_fortune.spend(held), "exactly affordable is affordable")
	assert_eq(_fortune.value(), 0)


func test_a_negative_cost_is_refused() -> void:
	assert_false(_fortune.spend(-10), "a cast never pays the Fool")
	assert_eq(_fortune.value(), 0)


# --- Save --------------------------------------------------------------------


func test_a_snapshot_round_trips() -> void:
	_rules.fortune_per_discovery = 40
	_fortune.earn(FortuneService.EarnSource.DISCOVERY)
	_fortune.on_fools_chance()
	var snapshot := _fortune.to_snapshot()
	var loaded := FortuneService.new(_rules)
	assert_eq(loaded.restore_snapshot(snapshot), PackedStringArray())
	assert_eq(loaded.value(), _fortune.value(), "the meter came back")
	assert_true(loaded.has_free_cast(), "so did the free cast the player earned")
	assert_false(loaded.is_favor_open(), "the Favor window is transient and does not")


func test_a_snapshot_survives_json() -> void:
	# JSON has one number type: everything comes back as a float.
	_fortune.earn(FortuneService.EarnSource.HIT)
	var parsed: Variant = JSON.parse_string(JSON.stringify(_fortune.to_snapshot()))
	if not assert_true(parsed is Dictionary, "the snapshot is JSON-safe"):
		return
	var loaded := FortuneService.new(_rules)
	assert_eq(loaded.restore_snapshot(parsed as Dictionary), PackedStringArray())
	assert_eq(loaded.value(), _fortune.value())


func test_a_played_meter_refuses_a_load() -> void:
	_fortune.earn(FortuneService.EarnSource.HIT)
	var problems := _fortune.restore_snapshot({FortuneService.SNAPSHOT_VALUE: 99})
	assert_eq(problems.size(), 1, "a load is not a reset")
	assert_ne(_fortune.value(), 99, "and it changed nothing")


func test_a_nonsense_snapshot_is_reported_rather_than_loaded() -> void:
	var loaded := FortuneService.new(_rules)
	var problems := loaded.restore_snapshot({FortuneService.SNAPSHOT_VALUE: "lots"})
	assert_eq(problems.size(), 1)
	assert_eq(loaded.value(), 0, "nothing was committed")
	assert_true(loaded.is_pristine(), "a refused load leaves a fresh meter fresh")


func test_a_snapshot_above_this_builds_ceiling_is_refused() -> void:
	var loaded := FortuneService.new(_rules)
	var problems := loaded.restore_snapshot({
		FortuneService.SNAPSHOT_VALUE: _rules.fortune_max + _rules.favor_overfill + 1
	})
	assert_eq(problems.size(), 1, "a save cannot hand this build a meter it cannot hold")
