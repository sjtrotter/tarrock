extends TarrockTest

## `SpreadRules`, and the numbers in it that `docs/design/progression.md` actually
## fixes.
##
## The rules resource is hand-authored, so no generator drift test covers it. This
## suite is the mini drift check instead: it reads the doc and asserts the canon
## numbers - the 1/3/7 slot pacing, the meter of roughly 100, the 3-petal start and
## 8-petal cap, the 20-50 cost band - still say what the resource says. A doc edit
## that retunes any of them fails here rather than shipping a game that disagrees
## with its own design doc.
##
## Everything else in the resource is a TBD placeholder and is deliberately NOT
## pinned to the doc: the doc sets no number for it (see `SpreadRules.notes`).

const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const PROGRESSION_DOC_RELATIVE := "../docs/design/progression.md"

var _rules: SpreadRules = null
var _doc: String = ""


func before_each() -> void:
	_rules = load(SPREAD_RULES_PATH) as SpreadRules
	_doc = FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("res://").path_join(PROGRESSION_DOC_RELATIVE).simplify_path()
	)


# --- Drift against progression.md --------------------------------------------


func test_the_slot_pacing_matches_the_doc() -> void:
	if not assert_not_null(_rules):
		return
	assert_true(
		_doc.contains("| **Present** | With the first Trump acquired"),
		"progression.md still opens the Present slot with the first Trump"
	)
	assert_eq(_rules.present_unlock_at_held, 1, "so the rules open it at one Trump held")
	assert_eq(_first_number("\\*\\*Past\\*\\* \\| Upon holding (\\d+) Trumps"), 3, "the doc says 3")
	assert_eq(_rules.past_unlock_at_held, 3)
	assert_eq(_first_number("\\*\\*Future\\*\\* \\| Upon holding (\\d+) Trumps"), 7, "the doc says 7")
	assert_eq(_rules.future_unlock_at_held, 7)


func test_the_meter_matches_the_doc() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(_first_number("roughly (\\d+) units"), 100, "progression.md sizes the meter at 100")
	assert_eq(_rules.fortune_max, 100)


func test_the_present_costs_sit_in_the_docs_band() -> void:
	if not assert_not_null(_rules):
		return
	var low := _first_number("casts cost roughly (\\d+)")
	var high := _first_number("casts cost roughly \\d+\\D+(\\d+) units")
	assert_eq(low, 20, "progression.md's lower bound")
	assert_eq(high, 50, "progression.md's upper bound")
	for cost: int in [_rules.default_present_cost_upright, _rules.default_present_cost_reversed]:
		assert_true(cost >= low and cost <= high, "%d sits inside the doc's band" % cost)


func test_the_white_rose_matches_the_doc() -> void:
	if not assert_not_null(_rules):
		return
	assert_true(
		_doc.contains("Starting capacity: 3 petals. Maximum: 8"),
		"progression.md still starts the Rose at 3 and caps it at 8"
	)
	assert_eq(_rules.rose_start_petals, 3)
	assert_eq(_rules.rose_max_petals, 8)


func test_the_placeholders_say_they_are_placeholders() -> void:
	# The TBD numbers are the ones a reviewer must not mistake for canon, so the
	# resource names every one of them in `notes`.
	if not assert_not_null(_rules):
		return
	for field: String in [
		"favor_overfill",
		"favor_window_seconds",
		"favor_decay_per_second",
		"fortune_per_hit",
		"fortune_per_fools_chance",
		"fortune_per_discovery",
		"fortune_per_daring",
		"earn_multiplier_story",
		"earn_multiplier_trial",
		"rose_regrow_seconds_per_petal",
		"default_present_cost_upright",
		"default_present_cost_reversed",
	]:
		assert_true(_rules.notes.contains(field), "%s is listed as a TBD placeholder" % field)
	assert_true(_rules.doc_ref.begins_with("docs/design/progression.md"), "the rules cite the doc")


# --- The rules as a lookup surface -------------------------------------------


func test_each_slot_reports_its_own_threshold() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(_rules.held_required_for(SpreadSlot.Id.PRESENT), _rules.present_unlock_at_held)
	assert_eq(_rules.held_required_for(SpreadSlot.Id.PAST), _rules.past_unlock_at_held)
	assert_eq(_rules.held_required_for(SpreadSlot.Id.FUTURE), _rules.future_unlock_at_held)


func test_the_default_cost_depends_on_the_orientation() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(
		_rules.default_present_cost(CardOrientation.Id.UPRIGHT), _rules.default_present_cost_upright
	)
	assert_eq(
		_rules.default_present_cost(CardOrientation.Id.REVERSED),
		_rules.default_present_cost_reversed
	)


func test_journey_is_the_baseline_at_exactly_one() -> void:
	# combat.md describes Story and Trial *against* Journey ("earns faster",
	# "reduced Fortune income"), which only means anything if Journey multiplies
	# Fortune income by one. It is the one earn number that is not a TBD placeholder,
	# and `SpreadRules.notes` deliberately does not list it as one.
	if not assert_not_null(_rules):
		return
	assert_almost_eq(_rules.earn_multiplier_journey, 1.0, 0.0001, "Journey is the baseline")
	assert_almost_eq(
		_rules.earn_multiplier(DifficultyMode.Id.JOURNEY),
		1.0,
		0.0001,
		"and the lookup agrees, for the default mode a new playthrough starts in"
	)
	assert_false(
		_rules.notes.contains("earn_multiplier_journey"),
		"so it is not listed among the TBD placeholders"
	)


func test_story_earns_faster_and_trial_earns_less() -> void:
	# combat.md §Difficulty modes: Story "Fortune earns faster", Trial "reduced
	# Fortune income". Journey is the baseline both are described against.
	if not assert_not_null(_rules):
		return
	assert_true(
		_rules.earn_multiplier(DifficultyMode.Id.STORY)
		> _rules.earn_multiplier(DifficultyMode.Id.JOURNEY)
	)
	assert_true(
		_rules.earn_multiplier(DifficultyMode.Id.TRIAL)
		< _rules.earn_multiplier(DifficultyMode.Id.JOURNEY)
	)


func test_a_ladder_that_opens_future_before_past_is_invalid() -> void:
	# The pacing exists to teach one axis at a time; a rules file that swapped two
	# thresholds would teach them out of order and nothing else would notice.
	var broken := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	if not assert_not_null(broken):
		return
	broken.future_unlock_at_held = 2
	assert_true(broken.validate().size() > 0, "an out-of-order unlock is a problem")


func test_a_reversed_cast_that_costs_more_is_invalid() -> void:
	var broken := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	if not assert_not_null(broken):
		return
	broken.default_present_cost_reversed = broken.default_present_cost_upright + 1
	assert_true(broken.validate().size() > 0, "progression.md: reversed casts cost less")


func test_a_rose_capped_below_its_start_is_invalid() -> void:
	var broken := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	if not assert_not_null(broken):
		return
	broken.rose_max_petals = 2
	assert_true(broken.validate().size() > 0, "a cap below the starting petals is a problem")


# --- Helpers -----------------------------------------------------------------


## The first capture group of `pattern` in the doc, as an int; -1 when it is absent.
func _first_number(pattern: String) -> int:
	var regex := RegEx.new()
	regex.compile(pattern)
	var found := regex.search(_doc)
	if found == null:
		fail("progression.md no longer matches %s" % pattern)
		return -1
	return found.get_string(1).to_int()
