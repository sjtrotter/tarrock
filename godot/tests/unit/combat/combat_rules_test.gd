extends TarrockTest

## `CombatRules`, and the handful of things in it `docs/design/combat.md` actually
## fixes.
##
## The resource is hand-authored, so no generator drift test covers it. This is the
## mini drift check instead: it reads the doc and asserts that the few facts the data
## is not free to invent still say what the data says - the three-hit string, the
## "roughly a 1.5-second" Fool's Chance, the backflip's "roughly 1.5 body-widths", and
## the direction each difficulty mode moves damage and timing in. A doc edit that
## retunes any of those fails here rather than shipping a kit that disagrees with its
## own design doc.
##
## Everything else is a TBD placeholder and is deliberately NOT pinned to the doc: the
## doc sets no number for it, and says so ("Exact i-frame duration and the width of
## the 'perfect' timing window are tuning values, not design facts"). What IS checked
## for those is that they are internally coherent - `validate()`'s job.

const RULES_PATH := "res://data/combat/combat_rules.tres"
const COMBAT_DOC_RELATIVE := "../docs/design/combat.md"

var _rules: CombatRules = null
var _doc: String = ""


func before_each() -> void:
	_rules = load(RULES_PATH) as CombatRules
	_doc = FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("res://").path_join(COMBAT_DOC_RELATIVE).simplify_path()
	)


# --- Drift against combat.md --------------------------------------------------


func test_the_doc_is_where_this_test_thinks_it_is() -> void:
	assert_true(_doc.length() > 1000, "combat.md was read")


func test_the_light_string_is_three_hits() -> void:
	assert_true(_doc.contains("Three-hit staff combo"), "combat.md fixes the string at three")
	assert_eq(CombatRules.LIGHT_STRING_HITS, 3)
	if not assert_not_null(_rules):
		return
	assert_eq(_rules.light_windup_seconds.size(), 3, "so every per-hit table is three long")
	assert_eq(_rules.light_active_seconds.size(), 3)
	assert_eq(_rules.light_recovery_seconds.size(), 3)
	assert_eq(_rules.light_damage.size(), 3)


func test_fools_chance_runs_for_the_doc_s_second_and_a_half() -> void:
	assert_true(
		_doc.contains("roughly a 1.5-second"), "combat.md sizes the Fool's Chance window"
	)
	if not assert_not_null(_rules):
		return
	assert_almost_eq(_rules.slowmo_duration_real_seconds, 1.5, 0.0001)


func test_the_backflip_carries_the_doc_s_body_widths() -> void:
	assert_true(_doc.contains("1.5 body-widths"), "combat.md measures the grand backflip")
	assert_almost_eq(CombatRules.BACKFLIP_BODY_WIDTHS, 1.5, 0.0001)
	if not assert_not_null(_rules):
		return
	assert_almost_eq(_rules.backflip_distance(), _rules.body_width * 1.5, 0.0001)


func test_the_difficulty_table_moves_the_way_the_doc_says() -> void:
	assert_true(_doc.contains("reduced damage taken"), "Story")
	assert_true(_doc.contains("generous timing windows"), "Story again")
	assert_true(_doc.contains("Tightened timing windows"), "Trial")
	assert_true(_doc.contains("no damage reduction"), "Trial again")
	if not assert_not_null(_rules):
		return
	assert_true(
		_rules.damage_taken_multiplier(DifficultyMode.Id.STORY)
		< _rules.damage_taken_multiplier(DifficultyMode.Id.JOURNEY),
		"Story takes less"
	)
	assert_almost_eq(
		_rules.damage_taken_multiplier(DifficultyMode.Id.TRIAL),
		1.0,
		0.0001,
		"Trial reduces nothing"
	)
	assert_true(
		_rules.timing_window_multiplier(DifficultyMode.Id.STORY) > 1.0, "Story is generous"
	)
	assert_true(
		_rules.timing_window_multiplier(DifficultyMode.Id.TRIAL) < 1.0, "Trial is tight"
	)


func test_the_heavy_is_the_wider_sweep() -> void:
	assert_true(
		_doc.contains("Wide crowd sweep"), "combat.md: the heavy is the answer to groups"
	)
	if not assert_not_null(_rules):
		return
	assert_true(_rules.heavy_arc_degrees > _rules.light_arc_degrees)


func test_the_charged_heavy_is_the_stagger_launcher() -> void:
	assert_true(_doc.contains("stagger launcher"), "combat.md names it")
	if not assert_not_null(_rules):
		return
	assert_true(_rules.stagger_seconds > 0.0, "there is a helpless window")
	assert_true(_rules.stagger_bonus_multiplier > 1.0, "and it opens bonus follow-ups")


# --- Internal coherence --------------------------------------------------------


func test_the_authored_rules_validate() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(
		_rules.validate(), PackedStringArray(), "the shipped combat numbers are self-consistent"
	)


func test_the_rules_cite_their_doc() -> void:
	if not assert_not_null(_rules):
		return
	assert_true(_rules.doc_ref.begins_with("docs/design/combat.md"), "the rules cite the doc")
	assert_true(_rules.notes.contains("TBD"), "and list their placeholders")
	assert_eq(_rules.id, &"COMBAT_RULES")


func test_iframes_that_close_before_they_open_are_reported() -> void:
	var broken := (_rules.duplicate() as CombatRules)
	broken.dodge_iframe_end_seconds = broken.dodge_iframe_start_seconds - 0.01
	assert_true(broken.validate().size() > 0, "a dodge with no i-frames is a kit that cannot dodge")


func test_a_perfect_window_wider_than_the_iframes_is_reported() -> void:
	var broken := (_rules.duplicate() as CombatRules)
	broken.perfect_window_seconds = broken.dodge_iframe_end_seconds + 1.0
	assert_true(
		broken.validate().size() > 0,
		"a perfect window the i-frames cannot contain is a Fool's Chance nobody can hit"
	)


func test_the_perfect_window_survives_the_tightest_difficulty() -> void:
	# The floor under the tuning: a hit is resolved on a physics frame, so a window
	# worth fewer than about three of them is not a window the player can aim at, it is
	# a coin toss. Trial tightens timing; it does not turn Fool's Chance into luck.
	if not assert_not_null(_rules):
		return
	var trial_band := _rules.perfect_window_seconds * _rules.timing_window_multiplier_trial
	assert_true(
		trial_band >= CombatRules.MIN_PERFECT_WINDOW_SECONDS,
		"Trial leaves %.3f s of perfect window, under the %.3f s floor"
		% [trial_band, CombatRules.MIN_PERFECT_WINDOW_SECONDS]
	)
	assert_almost_eq(
		CombatRules.MIN_PERFECT_WINDOW_SECONDS, 3.0 / 60.0, 0.0001, "three physics frames at 60 Hz"
	)


func test_a_perfect_window_under_the_frame_floor_is_reported() -> void:
	var broken := (_rules.duplicate() as CombatRules)
	broken.perfect_window_seconds = CombatRules.MIN_PERFECT_WINDOW_SECONDS * 0.5
	assert_true(
		broken.validate().size() > 0,
		"a window under three physics frames on Journey is under it on Trial too"
	)
	var tightened := (_rules.duplicate() as CombatRules)
	tightened.timing_window_multiplier_trial = 0.1
	assert_true(
		tightened.validate().size() > 0,
		"and tightening Trial without widening the window is the same finding"
	)


func test_a_string_table_of_the_wrong_length_is_reported() -> void:
	var broken := (_rules.duplicate() as CombatRules)
	broken.light_damage = PackedInt32Array([1, 2])
	assert_true(broken.validate().size() > 0, "a hit that deals nothing is not a hit")


func test_trial_reducing_damage_is_reported() -> void:
	var broken := (_rules.duplicate() as CombatRules)
	broken.damage_taken_multiplier_trial = 0.5
	assert_true(broken.validate().size() > 0, "combat.md gives Trial no damage reduction at all")


func test_a_heavy_no_wider_than_the_light_string_is_reported() -> void:
	var broken := (_rules.duplicate() as CombatRules)
	broken.heavy_arc_degrees = broken.light_arc_degrees
	assert_true(broken.validate().size() > 0)
