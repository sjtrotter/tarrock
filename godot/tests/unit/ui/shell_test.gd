extends TarrockTest

## The pieces the shell wires but no page owns: which screens stop the clock, the Pip
## wheel overlay, the defeat fade, a bark, and the card-flip between regions.
##
## `GameClock`'s class doc is the canon for the first: "Time does not pass while
## `paused` is true - menus, dialogue, and the Pocket Spread all stop the clock". Note
## the exception this round makes explicit and tests: DIALOGUE does not, because
## `art-audio.md` §UI/UX pillars says a conversation is a camera adjustment over the
## running world, with no hard lock.

const PIP_WHEEL_SCENE := "res://scenes/ui/pip_wheel_overlay.tscn"
const DEFEAT_SCENE := "res://scenes/ui/defeat_overlay.tscn"
const BARK_SCENE := "res://scenes/ui/bark_bubble.tscn"
const TRANSITION_SCENE := "res://scenes/ui/card_transition.tscn"
const PIP_SCENE := "res://scenes/pip.tscn"
const PIP_RULES_PATH := "res://data/pip/pip_rules.tres"
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## A bark key with a real row, so the slip can be proved to draw words.
const BARK_KEY := &"BARK_CLIFF_QUERENT_IDLE_01"

var _spawned: Array[Node] = []


func before_each() -> void:
	TranslationServer.set_locale("en")
	_spawned = []


func after_each() -> void:
	for node: Node in _spawned:
		if node != null and is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.free()
	_spawned.clear()


# --- Menus and the clock -----------------------------------------------------------


func test_a_menu_stops_the_clock_and_closing_it_starts_it_again() -> void:
	var clock := GameClock.new()
	var state := UiState.new(clock)
	assert_false(clock.paused)
	state.set_open(UiShell.SCREEN_SPREAD, true)
	assert_true(clock.paused, "the Pocket Spread stops the clock")
	assert_true(state.any_menu_open())
	state.set_open(UiShell.SCREEN_SPREAD, false)
	assert_false(clock.paused)


func test_two_menus_up_at_once_only_start_the_clock_when_both_are_down() -> void:
	var clock := GameClock.new()
	var state := UiState.new(clock)
	state.set_open(UiShell.SCREEN_PAUSE, true)
	state.set_open(UiShell.SCREEN_SETTINGS, true)
	assert_eq(state.open_count(), 2)
	state.set_open(UiShell.SCREEN_PAUSE, false)
	assert_true(clock.paused, "the settings are still up")
	state.set_open(UiShell.SCREEN_SETTINGS, false)
	assert_false(clock.paused)


func test_opening_a_screen_twice_is_not_two_screens() -> void:
	var clock := GameClock.new()
	var state := UiState.new(clock)
	watch_signal(state, &"menu_changed")
	state.set_open(UiShell.SCREEN_MAP, true)
	state.set_open(UiShell.SCREEN_MAP, true)
	assert_eq(state.open_count(), 1)
	assert_signal_emitted(state, &"menu_changed", 1)


func test_closing_everything_lets_the_world_run_again() -> void:
	var clock := GameClock.new()
	var state := UiState.new(clock)
	state.set_open(UiShell.SCREEN_ALMANACK, true)
	state.set_open(UiShell.SCREEN_MAP, true)
	state.close_all()
	assert_false(state.any_menu_open())
	assert_false(clock.paused)


func test_a_clock_attached_late_is_brought_up_to_date() -> void:
	var state := UiState.new(null)
	state.set_open(UiShell.SCREEN_PAUSE, true)
	var clock := GameClock.new()
	state.attach_clock(clock)
	assert_true(clock.paused, "a rebuild must not resume a world behind an open menu")


# --- Pip's wheel -------------------------------------------------------------------


func test_the_wheel_overlay_is_up_only_while_the_wheel_is_held() -> void:
	var overlay := _spawn(PIP_WHEEL_SCENE) as PipWheelOverlay
	assert_false(overlay.visible, "an unattached overlay draws nothing")
	var companion := _spawn_pip()
	overlay.attach(companion)
	overlay.refresh()
	assert_false(overlay.visible, "the wheel is not open")

	companion.wheel().update(true, Vector2(0.0, 1.0), 0.1)
	companion.wheel_view().refresh(companion.wheel(), companion.service())
	overlay.refresh()
	assert_true(overlay.visible)
	assert_eq(overlay.highlighted(), PipCommand.Id.SEEK, "down is Seek")


func test_every_command_gets_a_sector_and_an_unavailable_one_is_drawn_faint() -> void:
	var overlay := _spawn(PIP_WHEEL_SCENE) as PipWheelOverlay
	var companion := _spawn_pip()
	overlay.attach(companion)
	for command: int in PipCommand.ALL:
		var label := overlay.sector_label(command)
		assert_not_null(label, "sector %d is drawn" % command)
		assert_eq(label.text, String(PipCommand.NAME_KEYS[command]))
	companion.wheel_view().refresh(companion.wheel(), companion.service())
	overlay.refresh()
	assert_true(overlay.is_sector_available(PipCommand.Id.FETCH))

	# Pip retreated: nothing he is asked for can be obeyed until he is back.
	companion.service().on_pip_health_zero()
	companion.wheel_view().refresh(companion.wheel(), companion.service())
	overlay.refresh()
	assert_false(overlay.is_sector_available(PipCommand.Id.FETCH))


# --- Defeat ------------------------------------------------------------------------


func test_the_defeat_fade_waits_for_pips_lick() -> void:
	var overlay := _spawn(DEFEAT_SCENE) as DefeatOverlay
	var combat := _build_combat()
	var companion := _spawn_pip()
	overlay.attach(combat, companion)
	assert_false(overlay.is_fading())
	combat.fool_defeated.emit(1, 0)
	assert_false(overlay.is_fading(), "combat.md: the lick comes first")
	companion.licked.emit()
	assert_true(overlay.is_fading())


func test_a_fool_who_went_down_with_no_dog_still_wakes_up() -> void:
	var overlay := _spawn(DEFEAT_SCENE) as DefeatOverlay
	var combat := _build_combat()
	overlay.attach(combat, null)
	combat.fool_defeated.emit(1, 0)
	assert_true(overlay.is_fading())


func test_no_querent_line_is_invented_for_the_defeat_beat() -> void:
	# Canon gives a rotating pool of warm, dry remarks and none of its words. The
	# graph id is shipped; the lines are the writing lane's.
	var overlay := _spawn(DEFEAT_SCENE) as DefeatOverlay
	assert_eq(overlay.querent_remarks_graph(), &"DEFEAT_QUERENT_REMARKS")
	var catalog: DialogueCatalog = load("res://data/dialogue/catalog.tres") as DialogueCatalog
	assert_null(
		catalog.find(overlay.querent_remarks_graph()),
		"a guessed graph would be invented canon"
	)


# --- Barks -------------------------------------------------------------------------


func test_a_bark_shows_a_key_over_a_speaker_and_goes_away_again() -> void:
	var bubble := _spawn(BARK_SCENE) as BarkBubble
	assert_false(bubble.visible)
	var speaker := Node2D.new()
	tree().root.add_child(speaker)
	_spawned.append(speaker)
	bubble.say(BARK_KEY, speaker, 1.0)
	assert_true(bubble.visible)
	assert_eq(bubble.text_key(), BARK_KEY)
	assert_eq(bubble.speaker(), speaker)
	assert_ne(bubble.bark_text(), String(BARK_KEY), "the bark's key has a row")
	bubble._process(2.0)
	assert_false(bubble.visible, "a bark is a one-liner, not a conversation")
	assert_eq(bubble.text_key(), &"")


# --- Region travel -----------------------------------------------------------------


func test_a_region_change_turns_a_card_over() -> void:
	var transition := _spawn(TRANSITION_SCENE) as CardTransition
	assert_false(transition.is_flipping())
	transition.play()
	assert_true(transition.is_flipping())
	assert_true(transition.visible)


func _spawn(scene_path: String) -> Control:
	var node := (load(scene_path) as PackedScene).instantiate() as Control
	tree().root.add_child(node)
	_spawned.append(node)
	return node


func _spawn_pip() -> PipCompanion:
	var pip := (load(PIP_SCENE) as PackedScene).instantiate()
	tree().root.add_child(pip)
	_spawned.append(pip)
	var companion := pip.get_node_or_null("PipCompanion") as PipCompanion
	if companion != null:
		companion.attach_service(
			PipService.new(load(PIP_RULES_PATH) as PipRules, _build_combat())
		)
	return companion


func _build_combat() -> CombatService:
	var rules := (load(SPREAD_RULES_PATH) as SpreadRules).duplicate() as SpreadRules
	var world_state := WorldStateService.new(
		load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog,
		load(ACT_THRESHOLDS_PATH) as ActThresholds,
		load(RENOWN_LADDER_PATH) as RenownLadder
	)
	var fortune := FortuneService.new(rules)
	var spread := PocketSpreadService.new(
		world_state, load(TRUMP_CATALOG_PATH) as TrumpCatalog, rules, fortune
	)
	return CombatService.new(
		(load(COMBAT_RULES_PATH) as CombatRules).duplicate() as CombatRules,
		fortune,
		spread,
		WhiteRoseService.new(world_state, rules),
		GameClock.new()
	)
