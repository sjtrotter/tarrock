extends TarrockTest

## `PipRules`, and the handful of things `docs/design/combat.md` §Pip actually fixes.
##
## The resource is hand-authored, so no generator drift test covers it. This is the
## mini drift check instead: it reads the doc and asserts that the few facts the data
## is not free to invent still say what the data says - three commands and no fourth,
## a Harry that reduces the enemy's aggression rather than sharpening it, and a Pip who
## cannot die but retreats, shakes it off and comes back. A doc edit that changes any
## of those fails here rather than shipping a dog who disagrees with his own design doc.
##
## Everything else is a TBD placeholder and is deliberately NOT pinned to the doc: §Pip
## states no figure at all. What IS checked for those is that they are internally
## coherent - `validate()`'s job.

const RULES_PATH := "res://data/pip/pip_rules.tres"
const COMBAT_DOC_RELATIVE := "../docs/design/combat.md"
const CHARACTERS_DOC_RELATIVE := "../docs/design/characters.md"

var _rules: PipRules = null
var _doc: String = ""
var _characters: String = ""


func before_each() -> void:
	_rules = load(RULES_PATH) as PipRules
	_doc = _read(COMBAT_DOC_RELATIVE)
	_characters = _read(CHARACTERS_DOC_RELATIVE)


# --- Drift against combat.md ---------------------------------------------------


func test_the_docs_are_where_this_test_thinks_they_are() -> void:
	assert_true(_doc.length() > 1000, "combat.md was read")
	assert_true(_characters.length() > 1000, "characters.md was read")


func test_the_wheel_holds_exactly_the_three_commands_the_doc_names() -> void:
	assert_true(_doc.contains("radial command wheel"), "combat.md gives Pip a radial wheel")
	assert_true(_doc.contains("**Fetch**"), "and names Fetch")
	assert_true(_doc.contains("**Harry**"), "and Harry")
	assert_true(_doc.contains("**Seek**"), "and Seek")
	assert_eq(PipCommand.ALL.size(), 3, "three commands, and no fourth invented in code")
	assert_eq(PipCommand.ALL[0], PipCommand.Id.FETCH, "in the doc table's own order")
	assert_eq(PipCommand.ALL[1], PipCommand.Id.HARRY)
	assert_eq(PipCommand.ALL[2], PipCommand.Id.SEEK)


func test_pip_cannot_die_and_the_retreat_is_real() -> void:
	assert_true(_doc.contains("Pip cannot die"), "combat.md §Pip says it in those words")
	assert_true(_doc.contains("short cooldown"), "and gives the return a cooldown")
	if not assert_not_null(_rules):
		return
	assert_true(_rules.retreat_distance > 0.0, "so he really leaves the fight")
	assert_true(_rules.retreat_cooldown_seconds > 0.0, "and is really gone for a while")


func test_harry_reduces_the_enemys_aggression_rather_than_sharpening_it() -> void:
	assert_true(
		_doc.contains("reducing its aggression toward the Fool"),
		"combat.md fixes the direction Harry moves an enemy in"
	)
	if not assert_not_null(_rules):
		return
	assert_true(
		_rules.harry_telegraph_multiplier > 1.0,
		"a harried enemy telegraphs for LONGER, which is what less aggression buys"
	)
	assert_true(_rules.harry_seconds > 0.0, "and the doc's 'briefly' is a real duration")


func test_seek_is_the_traversal_verb_and_carries_its_own_reach() -> void:
	assert_true(
		_doc.contains("Traversal/discovery utility"),
		"combat.md calls Seek traversal rather than combat"
	)
	if not assert_not_null(_rules):
		return
	assert_eq(
		_rules.radius_for(PipCommand.Id.SEEK), _rules.seek_radius, "so it has its own radius"
	)
	assert_eq(_rules.radius_for(PipCommand.Id.FETCH), _rules.command_radius)
	assert_eq(_rules.radius_for(PipCommand.Id.HARRY), _rules.command_radius)


func test_the_protection_rule_is_still_in_the_character_bible() -> void:
	# `characters.md` §Pip is the other half of "Pip cannot die", and the reason no
	# quest but MQ18 may threaten him. If it ever stops saying so, this round's whole
	# retreat design needs re-reading.
	assert_true(
		_characters.contains("Pip cannot be harmed permanently"),
		"characters.md §Pip carries the protection rule"
	)


# --- Internal coherence ---------------------------------------------------------


func test_the_authored_rules_validate() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(_rules.validate(), PackedStringArray(), "the shipped Pip numbers are coherent")


func test_the_rules_cite_their_doc() -> void:
	if not assert_not_null(_rules):
		return
	assert_true(_rules.doc_ref.begins_with("docs/design/combat.md"), "the rules cite the doc")
	assert_true(_rules.notes.contains("TBD"), "and list their placeholders")
	assert_eq(_rules.id, &"PIP_RULES")


func test_a_harry_that_sharpened_an_enemy_is_reported() -> void:
	if not assert_not_null(_rules):
		return
	var broken := _rules.duplicate() as PipRules
	broken.harry_telegraph_multiplier = 0.8
	assert_true(
		broken.validate().size() > 0, "Harry that made an enemy quicker is not what the doc says"
	)


func test_a_retreat_with_no_cooldown_is_reported() -> void:
	if not assert_not_null(_rules):
		return
	var broken := _rules.duplicate() as PipRules
	broken.retreat_cooldown_seconds = 0.0
	assert_true(broken.validate().size() > 0, "nothing was shaken off in no time at all")


func test_a_retreat_that_goes_nowhere_is_reported() -> void:
	if not assert_not_null(_rules):
		return
	var broken := _rules.duplicate() as PipRules
	broken.retreat_distance = 0.0
	assert_true(broken.validate().size() > 0, "a Pip who stays put never left the fight")


func test_a_dead_zone_outside_its_bounds_is_reported() -> void:
	if not assert_not_null(_rules):
		return
	var too_small := _rules.duplicate() as PipRules
	too_small.wheel_dead_zone = 0.0
	assert_true(too_small.validate().size() > 0, "a wheel with no dead-zone has no tap gesture")
	var too_big := _rules.duplicate() as PipRules
	too_big.wheel_dead_zone = 1.0
	assert_true(too_big.validate().size() > 0, "and one with nothing but dead-zone cannot be aimed")


func test_work_seconds_are_the_doc_s_two_timed_jobs() -> void:
	if not assert_not_null(_rules):
		return
	assert_eq(_rules.work_seconds_for(PipCommand.Id.SEEK), _rules.seek_reveal_seconds, "the dig")
	assert_eq(_rules.work_seconds_for(PipCommand.Id.HARRY), _rules.harry_seconds, "the pin")
	assert_almost_eq(
		_rules.work_seconds_for(PipCommand.Id.FETCH), 0.0, 0.0001, "a pickup is a mouthful"
	)


func test_the_other_half_of_seek_is_declared_unbuilt_rather_than_forgotten() -> void:
	# `combat.md` §Pip gives Seek two readings in one sentence and round 9 built one of
	# them: Pip runs to a hidden thing and digs it out. Pointing at "a trap, a secret,
	# a fog-hidden path" from a distance is the other, and it has no trap system and no
	# fog region to point at yet. `Seekable.approach` is where that decision will land;
	# what this pins is that it is honest - declared, defaulted to the built reading,
	# and read by nothing.
	assert_true(
		_doc.contains("points toward something hidden nearby"),
		"combat.md still asks for the half that is not built"
	)
	var hidden := Seekable.new()
	assert_true(hidden.approach, "every Seek in the game today is a run-to-it-and-dig")
	hidden.approach = false
	assert_true(
		hidden.reveal(),
		"and the flag changes nothing yet: a node authored the unbuilt way is still dug"
	)
	hidden.free()


func test_every_command_names_itself_in_the_string_table() -> void:
	# The wheel is drawn in round 13, but a key with no row shows on screen as
	# PIP_COMMAND_FETCH - so the rows are part of the vocabulary's contract, not part
	# of the UI's. The English is `combat.md`'s own three words.
	TranslationServer.set_locale("en")
	for command: int in PipCommand.ALL:
		var key := PipCommand.name_key(command)
		assert_ne(
			TranslationServer.translate(key),
			String(key),
			"%s has no row in localization/strings.csv" % key
		)
	assert_eq(TranslationServer.translate(&"PIP_COMMAND_FETCH"), "Fetch")
	assert_eq(TranslationServer.translate(&"PIP_COMMAND_HARRY"), "Harry")
	assert_eq(TranslationServer.translate(&"PIP_COMMAND_SEEK"), "Seek")


func test_every_command_has_a_translation_key_and_nothing_else_does() -> void:
	for command: int in PipCommand.ALL:
		assert_ne(PipCommand.name_key(command), &"", "every command names itself for the UI")
	assert_eq(PipCommand.name_key(PipCommand.NONE), &"", "and nothing else does")
	assert_eq(PipCommand.name_key(99), &"")
	assert_false(PipCommand.is_valid(PipCommand.NONE))
	assert_true(PipCommand.is_valid(PipCommand.Id.SEEK))


func _read(relative: String) -> String:
	return FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("res://").path_join(relative).simplify_path()
	)
