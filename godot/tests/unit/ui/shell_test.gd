extends TarrockTest

## The pieces the shell wires but no page owns: which screens stop the clock, whether
## the Fool may touch the world while the screen is talking, the Pip wheel overlay, the
## defeat fade, a bark, and the card-flip between regions.
##
## `GameClock`'s class doc is the canon for the first: "Time does not pass while
## `paused` is true - menus, dialogue, and the Pocket Spread all stop the clock". Note
## the exception this round makes explicit and tests: DIALOGUE does not, because
## `art-audio.md` §UI/UX pillars says a conversation is a camera adjustment over the
## running world, with no hard lock.
##
## What a conversation DOES take away is the interact key. `interact` advances a line
## and picks a prop up, and the two halves of the input surface cannot see each other -
## `DialogueFrame` consumes the action as an event, `FoolBody` polls it - so the shell
## suspends the Fool's world interaction while anything is on screen. See
## `res://tests/README.md` §The proof slice for the Bindle it used to lift by itself.

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

## The shell itself, and the two things it needs beside it before it can find the Fool:
## something for `UiShell.layer()` to walk up to, and the Fool under it.
const SHELL_SCENE := "res://scenes/ui/ui_shell.tscn"
const FOOL_SCENE := "res://scenes/fool.tscn"

## Where a shell built here keeps its settings. `UiShell._ready()` loads the settings
## file, so without the override it would stand on the settings of whoever is at this
## keyboard - the same reason `tests/ui_test.gd` redirects it. `ui_settings_test.gd`
## asserts nothing leaks out of a suite, so `after_each()` puts it back.
const SCRATCH_SETTINGS := "user://test_shell_settings/settings.cfg"

## A graph id for a conversation that never runs: what is being proved here is what the
## shell does when the dialogue service says a conversation started, not the graph.
const FAKE_GRAPH := &"A_CONVERSATION"

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
	UiSettings.settings_path_override = ""
	_clean_up_settings()
	_forget_the_layer_swapper()


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


# --- The Fool's hands, while the screen is talking ---------------------------------


func test_a_conversation_takes_the_fools_hands_off_the_world() -> void:
	var shell := _spawn_shell_over_a_fool()
	var fool := shell.fool_body()
	if not assert_not_null(fool, "the shell finds the Fool on the layer beside it"):
		return
	assert_true(fool.world_interaction_enabled(), "nobody is talking to him yet")

	# The handlers `DialogueService.dialogue_started` / `dialogue_ended` are wired to:
	# a conversation, faked, so no graph or catalog has to exist for this.
	shell._on_dialogue_started(FAKE_GRAPH)
	assert_false(shell.world_interaction_allowed(), "the parchment owns `interact` now")
	assert_false(fool.world_interaction_enabled(), "which the Fool has been told")
	assert_null(fool.try_interact(), "so the verb answers nothing, poll or call")

	shell._on_dialogue_ended(FAKE_GRAPH)
	assert_true(shell.world_interaction_allowed())
	assert_true(fool.world_interaction_enabled(), "and the world comes back with the quiet")


func test_a_menu_that_is_still_up_keeps_the_world_out_of_reach() -> void:
	var shell := _spawn_shell_over_a_fool()
	var fool := shell.fool_body()
	if not assert_not_null(fool):
		return
	shell._on_dialogue_started(FAKE_GRAPH)
	shell.set_screen(UiShell.SCREEN_PAUSE, true)
	shell._on_dialogue_ended(FAKE_GRAPH)
	assert_false(
		fool.world_interaction_enabled(), "the conversation ended behind an open pause menu"
	)
	shell.set_screen(UiShell.SCREEN_PAUSE, false)
	assert_true(fool.world_interaction_enabled(), "and both are down")


func test_a_menu_on_its_own_suspends_him_too() -> void:
	var shell := _spawn_shell_over_a_fool()
	var fool := shell.fool_body()
	if not assert_not_null(fool):
		return
	shell.toggle_spread()
	assert_false(fool.world_interaction_enabled(), "the Pocket Spread is up")
	shell.toggle_spread()
	assert_true(fool.world_interaction_enabled())


## A shell with a Fool under the same layer, which is the arrangement it looks for:
## `UiShell.layer()` walks up to the `PersistentLayer` and asks it for the Fool.
## Nothing here plays a game - the layer is told not to boot one.
func _spawn_shell_over_a_fool() -> UiShell:
	UiSettings.settings_path_override = SCRATCH_SETTINGS
	var layer := PersistentLayer.new()
	layer.name = "PersistentLayer"
	layer.boot_new_game_on_ready = false
	var fool := (load(FOOL_SCENE) as PackedScene).instantiate()
	fool.name = PersistentLayer.FOOL
	layer.add_child(fool)
	var ui_root := CanvasLayer.new()
	ui_root.name = "UIRoot"
	layer.add_child(ui_root)
	var shell := (load(SHELL_SCENE) as PackedScene).instantiate() as UiShell
	ui_root.add_child(shell)
	tree().root.add_child(layer)
	# The layer alone: freeing it frees the shell and the Fool with it.
	_spawned.append(layer)
	return shell


## A `PersistentLayer` hands itself to the composition root as the node that swaps
## regions, and the composition root here is the runner's own autoload, which outlives
## this suite. Hand it back nothing, so no later test can find a swapper pointing at a
## layer this one freed.
func _forget_the_layer_swapper() -> void:
	var root := tree().root.get_node_or_null("Services")
	if root != null:
		root.call(&"set_region_swapper", null)


## And take the scratch settings file away again if a shell wrote one.
func _clean_up_settings() -> void:
	if FileAccess.file_exists(SCRATCH_SETTINGS):
		DirAccess.remove_absolute(SCRATCH_SETTINGS)
	var directory := SCRATCH_SETTINGS.get_base_dir()
	if DirAccess.dir_exists_absolute(directory):
		DirAccess.remove_absolute(directory)


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


# --- On screen, not merely in the tree ---------------------------------------------
# The first playtest saw NO HUD: the shell's root Control had a zero-size rect (anchors
# set without offsets), so its children hung at (0,0) or below the window, and the
# safe-area insets were read in global screen coordinates on a two-monitor desk. A view
# that is `visible` but outside the viewport is invisible to a player, so these assert
# where things are, in the runner's real 1280x720 viewport.

func test_the_shell_and_the_hud_fill_the_viewport() -> void:
	var shell := _spawn_shell_over_a_fool()
	await tree().process_frame
	await tree().process_frame
	var viewport := tree().root.get_visible_rect()
	assert_eq(shell.get_global_rect(), viewport, "the shell root is the whole viewport, not a zero-size strip")
	var hud := shell.find_child("Hud", true, false) as Control
	if not assert_not_null(hud, "the HUD exists"):
		return
	assert_eq(hud.get_global_rect(), viewport, "the HUD fills the viewport")
	var meters := hud.find_child("Meters", true, false) as Control
	if not assert_not_null(meters, "the meters row exists"):
		return
	var rect := meters.get_global_rect()
	assert_true(viewport.encloses(rect), "the petals and Fortune are inside the window (%s)" % str(rect))
	assert_true(rect.position.y < viewport.size.y * 0.5, "the meters sit in the top band, clear of the dialogue frame")


func test_the_dialogue_frame_sits_inside_the_bottom_of_the_viewport() -> void:
	var shell := _spawn_shell_over_a_fool()
	await tree().process_frame
	var frame := shell.find_child("DialogueFrame", true, false) as Control
	if not assert_not_null(frame, "the dialogue frame exists"):
		return
	var viewport := tree().root.get_visible_rect()
	var rect := frame.get_global_rect()
	assert_true(rect.size.y > 100.0, "the frame has a height of its own (%s)" % str(rect))
	assert_true(viewport.encloses(rect), "the frame is inside the window, grown upward from the bottom edge (%s)" % str(rect))
	assert_almost_eq(rect.end.y, viewport.size.y, 0.5, "and it rests on the bottom edge")


func test_safe_area_insets_are_never_read_as_global_screen_coordinates() -> void:
	var container := MarginContainer.new()
	tree().root.add_child(container)
	_spawned.append(container)
	Hud.apply_safe_area(container)
	var screen := DisplayServer.screen_get_size()
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		var margin := container.get_theme_constant(side)
		assert_true(margin >= Hud.EDGE_MARGIN, "%s keeps the edge margin" % side)
		var axis := screen.x if side == &"margin_left" or side == &"margin_right" else screen.y
		if axis > 0:
			assert_true(
				margin <= maxi(Hud.EDGE_MARGIN, int(axis * Hud.MAX_SAFE_AREA_FRACTION)),
				"%s is a sliver of the screen, never a monitor offset (%d)" % [side, margin]
			)
