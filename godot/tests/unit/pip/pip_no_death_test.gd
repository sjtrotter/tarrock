extends TarrockTest

## **Pip cannot die**, enforced over the surface rather than in the prose.
##
## `docs/design/combat.md` §Pip: "Pip cannot die. If reduced to zero health he yelps,
## retreats out of the fight, shakes it off, and returns after a short cooldown. This is
## not a difficulty concession - it is canon", and `docs/design/characters.md` §Pip adds
## the protection rule: he "cannot be harmed permanently, and the game never threatens
## him for drama", with MQ18's illusion the single scoped exception.
##
## A rule that lives only in a comment is a rule the next round breaks by accident. So
## this reflects over every script in `systems/pip/` - the same instrument
## `tests/unit/world_state/world_state_service_test.gd` points at "no unbinding is
## reversible" - and fails on any method, signal, property or constant whose NAME
## carries a word for ending. `Combatant.died` is round 7's name for a pool reaching
## zero and stays where it is (its own class doc is explicit that it is not a death);
## what this guards is that nothing on Pip's side of the wiring ever repeats it.

## The folder this reflects over. Every `.gd` under it is swept, found rather than
## listed: a hand-written list is a list somebody adds a script beside, and the one
## script nobody added is exactly where a word for ending would survive.
const PIP_ROOT := "res://systems/pip"

## How many scripts the sweep must find before it is believed. The folder held eight
## the day this was written; a sweep that suddenly finds one is a broken walk, not a
## deleted system, and it must fail rather than pass over nothing.
const MIN_PIP_SCRIPTS := 8

## The one name fragment that carries a word for ending and means nothing of the kind:
## a stick's DEAD ZONE is the standard input term for the rest area at its centre, and
## `PipRules.wheel_dead_zone` is that and only that. Exempted by name rather than by
## dropping "dead" from the list, so a real `is_dead` still fails.
const DEAD_ZONE_TERMS: Array[String] = ["dead_zone", "deadzone"]

## Name fragments that would mean Pip can end. Lower-cased before matching.
const ENDING_WORDS: Array[String] = [
	"die",
	"died",
	"dead",
	"death",
	"kill",
	"perish",
	"slain",
	"corpse",
	"grave",
	"respawn",
]

## "revive" is deliberately NOT on that list. `CombatService.fool_revived` is round 7's
## name for `combat.md` §Defeat step 3 - the Fool waking at the Waystation - and a
## handler has to be named for the signal it handles. It is the FOOL's word, about
## standing back up rather than about ending, and Pip has no equivalent: he retreats and
## returns, which is what `pip_retreated` and `pip_returned` are called.

## Every public method `PipService` is allowed to have.
##
## The word list above catches the obvious way in; this catches the rest, by refusing
## anything new. "Pip cannot die", "nothing reaches him while he is out" and "a command
## is refused rather than half-run" are properties of the SURFACE: they hold only while
## the surface is this and no more, so adding a public method is a decision taken here,
## in review, and not a side effect of writing one.
const SERVICE_PUBLIC_METHODS: Array[String] = [
	"active_command",
	"begin_defeat_beat",
	"command",
	"command_radius",
	"detach",
	"is_available",
	"on_pip_health_zero",
	"phase",
	"report_arrived",
	"reset",
	"retreat_point",
	"rules",
	"state",
	"state_seconds",
	"target",
	"tick",
	"work_seconds_left",
]


func test_no_name_in_the_pip_api_is_a_word_for_ending() -> void:
	var scripts := _scripts_under(PIP_ROOT)
	assert_true(
		scripts.size() >= MIN_PIP_SCRIPTS,
		"the sweep found %d scripts under %s, which cannot be all of them"
		% [scripts.size(), PIP_ROOT]
	)
	var offenders := PackedStringArray()
	for path: String in scripts:
		var script: Script = load(path) as Script
		if not assert_not_null(script, "%s loads" % path):
			continue
		for name_found: String in _named_members(script):
			if _is_dead_zone(name_found.to_lower()):
				continue
			for word: String in ENDING_WORDS:
				if not _carries_word(name_found.to_lower(), word):
					continue
				offenders.append("%s: %s" % [path, name_found])
				break
	assert_eq(
		offenders,
		PackedStringArray(),
		"combat.md §Pip: Pip cannot die, and nothing in systems/pip/ may say he can (%s)"
		% str(offenders)
	)


func test_the_service_surface_is_the_reviewed_one() -> void:
	var script: Script = load("res://systems/pip/pip_service.gd") as Script
	if not assert_not_null(script, "PipService loads"):
		return
	var found := PackedStringArray()
	for entry: Dictionary in script.get_script_method_list():
		var method_name := String(entry["name"])
		if method_name.begins_with("_") or found.has(method_name):
			continue
		found.append(method_name)
	found.sort()
	var expected := PackedStringArray(SERVICE_PUBLIC_METHODS)
	expected.sort()
	var unexpected := PackedStringArray()
	for method_name: String in found:
		if not expected.has(method_name):
			unexpected.append(method_name)
	var missing := PackedStringArray()
	for method_name: String in expected:
		if not found.has(method_name):
			missing.append(method_name)
	assert_eq(
		found,
		expected,
		"unreviewed public methods %s; reviewed methods that vanished %s"
		% [str(unexpected), str(missing)]
	)


func test_the_retreat_really_is_a_round_trip_and_not_an_exit() -> void:
	# The behavioural half of the same rule, so deleting the guard in `_finish()` fails
	# something: a Pip put to zero must come back to exactly where he started, in mode
	# and in availability, with no state left over.
	var rules := load("res://data/pip/pip_rules.tres") as PipRules
	if not assert_not_null(rules, "the Pip rules load"):
		return
	var service := PipService.new(rules)
	service.on_pip_health_zero(Vector2.ZERO)
	assert_eq(service.state(), PipService.State.RETREATED, "he is out of the fight")
	service.report_arrived()
	for _frame: int in int(rules.retreat_cooldown_seconds * 60.0) + 8:
		service.tick(1.0 / 60.0)
	service.report_arrived()
	assert_eq(service.state(), PipService.State.FOLLOWING, "and back at the Fool's heel")
	for command: int in PipCommand.ALL:
		assert_true(service.is_available(command), "with every command reaching him again")


## Every `.gd` under `root`, folders and all, sorted so a failure names the same file
## every run.
func _scripts_under(root: String) -> PackedStringArray:
	var found := PackedStringArray()
	var directory := DirAccess.open(root)
	if directory == null:
		fail("%s cannot be opened: the sweep has nothing to reflect over" % root)
		return found
	for file_name: String in directory.get_files():
		if file_name.ends_with(".gd"):
			found.append(root.path_join(file_name))
	for sub_directory: String in directory.get_directories():
		found.append_array(_scripts_under(root.path_join(sub_directory)))
	found.sort()
	return found


## Every method, signal, property and constant `script` declares by name.
func _named_members(script: Script) -> PackedStringArray:
	var names := PackedStringArray()
	for entry: Dictionary in script.get_script_method_list():
		names.append(String(entry["name"]))
	for entry: Dictionary in script.get_script_signal_list():
		names.append(String(entry["name"]))
	for entry: Dictionary in script.get_script_property_list():
		names.append(String(entry["name"]))
	for constant_name: Variant in script.get_script_constant_map().keys():
		names.append(String(constant_name))
	return names


## True when this name is the input term rather than a word about ending.
func _is_dead_zone(lowered: String) -> bool:
	for term: String in DEAD_ZONE_TERMS:
		if lowered.contains(term):
			return true
	return false


## True when `haystack` carries `word` as a word rather than inside another one, so
## `is_available` is not read as a death because of some substring accident.
func _carries_word(haystack: String, word: String) -> bool:
	for part: String in haystack.split("_", false):
		if part == word or part.begins_with(word):
			return true
	return false
