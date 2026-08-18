extends SceneTree

## The shell in a real playthrough: MQ00's own conversation on screen, and the four
## pages opening on their own InputMap actions.
##
## Everything is driven the way a player drives it - the composition root starts the
## game, the quest runner raises MQ00's beats, and the pages are opened by PRESSING the
## actions `docs/design/technical.md` §Input actions lists, not by calling the shell.
## What is asserted is what the views SHOW.
##
## `docs/gauntlet-systems/PROMPT.md` row 13's cell is "Every visible string comes from a
## translation key", so the assertions are about keys throughout: the speaker plate
## carries `Speakers.name_key`'s key, the option rows carry the graph's own text keys,
## and each one is proved to have a CSV row behind it rather than showing as itself.

## Where this test's saves would go if anything wrote one. Nothing does; the directory
## is set anyway so a stray write cannot land in the player's own saves.
const SAVES_DIR := "user://test_ui_saves"

## And where its SETTINGS go, for the same reason and a stronger one: this test boots
## a real persistent layer, which builds a real `UiShell`, which loads the settings
## file and saves it again the moment anything is toggled. Left alone it would stand
## on the settings of whoever is at this keyboard, so the shell is pointed at a
## scratch file before the layer is instanced (`UiSettings.settings_path_override`).
const SETTINGS_PATH := "user://test_ui_settings/settings.cfg"

## A bark with a row behind it, for the fake pick in the last phase. It is a QUERENT
## line - the only bark any shipped doc holds (`docs/quests/main/MQ00-the-leap.md`
## §BARKS) - and the pick below hands it to a body on purpose: what is being proved is
## the wiring from `BarkService.bark_picked` to the slip on screen, not who says it.
const BARK_ID := &"BARK_CLIFF_QUERENT_IDLE_01"

## How many physics frames the Fool is given to walk while the camera frames him.
const WALK_FRAMES := 6

## Physics frames to let pass after a travel before the nodes are believed. The layer
## performs a swap when the frame's message queue flushes.
const SETTLE_FRAMES := 4

## The wooden dog's table: `docs/quests/main/MQ00-the-leap.md` §The Old Campsites gives
## the Fool three things to say about the whittled dog, and all of them may be
## exhausted.
const WOODEN_DOG_OPTIONS := 3

var _all_passed := true
var _phase := 0
var _phase_frame := 0
var _layer: PersistentLayer = null
var _shell: UiShell = null
var _walk_start: Vector2 = Vector2.ZERO
var _speaker_body: Node2D = null


func _initialize() -> void:
	# Before the layer, because the shell it carries loads the settings in `_ready`.
	UiSettings.settings_path_override = SETTINGS_PATH
	var packed: PackedScene = load("res://scenes/persistent_layer.tscn") as PackedScene
	_layer = packed.instantiate() as PersistentLayer
	_layer.boot_new_game_on_ready = false
	root.add_child(_layer)


func _physics_process(_delta: float) -> bool:
	_phase_frame += 1

	if _phase == 0:
		var services := root.get_node_or_null("Services")
		if not check(services != null, "the Services autoload is up"):
			return _fail()
		services.call(&"set_saves_dir", SAVES_DIR)
		_shell = _layer.get_node_or_null("UIRoot/UiShell") as UiShell
		if not check(_shell != null, "the persistent layer carries the UI shell under UIRoot"):
			return _fail()
		_check(_shell.layer() == _layer, "and the shell found the layer it hangs under")
		_check(
			_shell.settings().path() == SETTINGS_PATH,
			"and booted against this test's settings file, not the player's own"
		)
		_check(_shell.hud() != null, "the HUD is up before any playthrough is started")
		_check(
			_shell.hud().rose_meter().icon_count() == _rose().max_petals(),
			"and already drawing the world the composition root built at boot"
		)
		_check(not _shell.dialogue_frame().visible, "and no conversation on screen")
		_check(not _shell.state().any_menu_open(), "and no menu open")
		if not check(bool(services.call(&"new_game")), "the new game started"):
			return _fail()
		_advance()
		return false

	if _phase == 1:
		if _phase_frame < SETTLE_FRAMES:
			return false
		# --- The HUD found the playthrough -----------------------------------------
		var rose := _rose()
		_check(
			_shell.hud().rose_meter().icon_count() == rose.max_petals(),
			"the petal row is the Rose's capacity (%d)" % rose.max_petals()
		)
		_check(
			_shell.hud().rose_meter().lit_count() == rose.petals(),
			"and the petals the Fool still has are the lit ones - they ARE the health"
		)
		_check(
			_shell.map_screen().card_count() == 22,
			"the map dealt all 22 regions"
		)
		_check(
			_shell.map_screen().highlighted_region() == RegionIds.CLIFF,
			"and marked the Cliff, where the Fool woke up"
		)
		_check(
			not _shell.map_screen().card_for(RegionIds.CLIFF).is_face_up(),
			"every card is still face-down: nothing has been unbound"
		)

		# --- MQ00's opening line is on the parchment --------------------------------
		var dialogue := _dialogue()
		_check(dialogue.is_active(), "MQ00_WAKE is running")
		_check(_shell.dialogue_frame().visible, "so the dialogue frame is up")
		_check(
			_shell.dialogue_frame().speaker_key() == &"SPEAKER_QUERENT",
			"the plate carries the Querent's name KEY, not his name"
		)
		_check(
			_translated(_shell.dialogue_frame().speaker_key()) == "The Querent",
			"and that key has a row behind it"
		)
		_check(
			_shell.dialogue_frame().line_key() == &"DLG_MQ00_WAKE_01",
			"the parchment carries the line's key"
		)
		_check(
			not _shell.state().any_menu_open(),
			"a conversation is not a menu: art-audio.md wants no hard lock"
		)
		_check(not _clock().paused, "so the world is still running behind it")
		_advance()
		return false

	if _phase == 2:
		# Walk MQ00's opening beat off the screen the way a player does.
		_walk_conversation_out()
		_check(not _shell.dialogue_frame().visible, "the panel got out of the way")

		# --- Drive MQ00 to the wooden dog -------------------------------------------
		_quests().raise(QuestEvents.MQ00_BINDLE_TAKEN)
		_check(_quests().state_of(QuestIds.MQ00) == &"BINDLE_TAKEN", "the Bindle is taken")
		_walk_conversation_out()
		_quests().raise(QuestEvents.MQ00_KEEPSAKE_FOUND)
		_check(
			_quests().state_of(QuestIds.MQ00) == &"KEEPSAKE_FOUND",
			"Pip dug the wooden dog out"
		)
		_advance()
		return false

	if _phase == 3:
		# `MQ00_KEEPSAKE_GIVEN` chains into the wooden dog's choice table; walk the
		# Querent's lines until the Fool is the one being asked to speak.
		var frame := _shell.dialogue_frame()
		var steps := 0
		while _dialogue().is_active() and frame.option_count() == 0 and steps < 16:
			frame.advance()
			steps += 1
		_check(_dialogue().is_active(), "the wooden dog's table is on screen")
		_check(
			_dialogue().current_graph_id() == DialogueIds.MQ00_WOODEN_DOG,
			"and it is the wooden dog's own graph"
		)
		_check(
			frame.option_count() == WOODEN_DOG_OPTIONS,
			"the Fool has %d things to say (got %d)" % [WOODEN_DOG_OPTIONS, frame.option_count()]
		)
		_check(
			frame.is_leave_offered(),
			"and a '…' row, because all questions MAY be exhausted"
		)
		_check(
			frame.leave_button().text == String(UiKeys.DIALOGUE_LEAVE),
			"which is a key like everything else"
		)
		var first := frame.option_button(0)
		_check(first != null and first.text.begins_with("DLG_"), "every row is a text key")
		_check(not first.disabled, "and nothing has been asked yet")

		# Taking a row goes through the service, and the spent row comes back greyed.
		_check(frame.choose(0), "the Fool asks the first question")
		frame.advance()
		_check(frame.option_count() == WOODEN_DOG_OPTIONS, "the table comes back whole")
		_check(frame.is_option_used(0), "with the asked question greyed out")
		_check(not frame.is_option_used(1), "and the others still open")
		_check(frame.leave(), "the Fool may stop asking")
		_walk_conversation_out()
		_advance()
		return false

	if _phase == 4:
		# --- The pages open on their own actions ------------------------------------
		_press(InputActions.SPREAD)
		_advance()
		return false

	if _phase == 5:
		_check(_shell.spread_screen().visible, "`spread` laid the Pocket Spread out")
		_check(_clock().paused, "and a menu stops the clock (GameClock's own rule)")
		_press(InputActions.SPREAD)
		_advance()
		return false

	if _phase == 6:
		_check(not _shell.spread_screen().visible, "pressing it again put the Spread away")
		_check(not _clock().paused, "and the world runs again")
		_press(InputActions.ALMANACK)
		_advance()
		return false

	if _phase == 7:
		_check(_shell.almanack().visible, "`almanack` opened the journal")
		_check(_clock().paused, "which also stops the clock")
		_check(
			_shell.almanack().quest_title_keys().has(&"QUEST_MQ00_TITLE"),
			"and MQ00 is written in it by its title key"
		)
		_press(InputActions.ALMANACK)
		_advance()
		return false

	if _phase == 8:
		_check(not _shell.almanack().visible, "the page turned")
		_check(_shell.map_screen().visible, "onto the Spread dealt on the table")
		_press(InputActions.ALMANACK)
		_advance()
		return false

	if _phase == 9:
		_check(not _shell.map_screen().visible, "and turning again puts both down")
		_check(not _clock().paused, "so the world runs again")
		_press(InputActions.PAUSE)
		_advance()
		return false

	if _phase == 10:
		_check(_shell.pause_menu().visible, "`pause` opened the pause menu")
		_check(_clock().paused, "and stopped the clock")
		_press(InputActions.PAUSE)
		_advance()
		return false

	if _phase == 11:
		_check(not _shell.pause_menu().visible, "and pressing it again resumed")
		_check(not _clock().paused, "with the world running")

		# --- Resume means resume, with the settings open on top of the menu --------
		_shell.set_screen(UiShell.SCREEN_PAUSE, true)
		_shell.set_screen(UiShell.SCREEN_SETTINGS, true)
		_check(_shell.state().open_count() == 2, "the settings opened over the pause menu")
		_check(_clock().paused, "and the world is stopped behind both")
		_shell.pause_menu().resume_requested.emit()
		_check(not _shell.pause_menu().visible, "Resume put the pause menu down")
		_check(
			not _shell.settings_screen().visible,
			"and the settings page that was on top of it - nothing is left to press"
		)
		_check(not _shell.state().any_menu_open(), "so no menu is open")
		_check(not _clock().paused, "and the world runs again")

		# --- A toggle reaches the thing it toggles, not just the file --------------
		var wash := _shell.hud().vignette()
		_check(wash.flash_allowed(), "screen flash starts on")
		_shell.settings_screen().choose_screen_flash(false)
		_check(
			not wash.flash_allowed(),
			"and turning it off reaches the Fool's Chance wash at once, mid-play"
		)
		_shell.settings_screen().choose_screen_flash(true)
		_check(wash.flash_allowed(), "and back on again")
		_advance()
		return false

	if _phase == 12:
		# --- The conversation frames the camera, in play ---------------------------
		_check(not _shell.framing().is_framing(), "nothing is framed while the Fool walks")
		_check(_dialogue().start(DialogueIds.MQ00_WAKE), "the Querent starts talking")
		_check(_shell.dialogue_frame().visible, "the panel came up")
		_check(
			_shell.framing().is_framing(),
			"and the camera eased in with it (art-audio.md: no cut to a dialogue screen)"
		)
		var framed := _shell.framing().framed_nodes()
		_check(framed.has(_layer.fool()), "the Fool is in the frame")
		_check(
			framed.has(_layer.pip()),
			"and Pip, because the Querent is a voice with nobody to stand beside"
		)
		_check(not _clock().paused, "the world is not stopped for it")
		# Hold a movement key down: "No hard lock: the player keeps control."
		_walk_start = _layer.fool().global_position
		_hold(InputActions.MOVE_RIGHT)
		_advance()
		return false

	if _phase == 13:
		if _phase_frame < WALK_FRAMES:
			return false
		_release(InputActions.MOVE_RIGHT)
		_check(
			_layer.fool().global_position.x > _walk_start.x,
			"the Fool walked while being framed - the frame takes no input away"
		)
		_dialogue().end()
		_check(not _shell.framing().is_framing(), "and the frame let go with the conversation")
		_check(not _shell.dialogue_frame().visible, "the panel went with it")
		_advance()
		return false

	if _phase == 14:
		# --- A bark the service picked, over the body of whoever said it -----------
		_speaker_body = Node2D.new()
		_speaker_body.add_to_group(Speakers.FLICK)
		_speaker_body.global_position = _layer.fool().global_position + Vector2(120.0, 0.0)
		_layer.add_child(_speaker_body)
		var npc := _npc()
		if not check(npc != null, "the composition root built the bark service"):
			return _fail()
		npc.bark_picked.emit(Speakers.FLICK, BARK_ID, BarkLayer.GENERIC)
		var bubble := _shell.bark_bubble()
		_check(bubble.visible, "the slip is up over the speaker")
		_check(bubble.text_key() == BARK_ID, "carrying the bark's own text key")
		_check(bubble.speaker() == _speaker_body, "and following the body that said it")
		_check(
			_translated(bubble.text_key()) != String(bubble.text_key()),
			"and that key has a row behind it"
		)

		# A speaker with no body in the world gets no bubble: a bark is a slip over
		# somebody's head, and the Querent has no head (characters.md §The Querent).
		bubble.clear_bark()
		npc.bark_picked.emit(&"", BARK_ID, BarkLayer.GENERIC)
		_check(not bubble.visible, "a voice with no body says nothing on screen")

		_layer.remove_child(_speaker_body)
		_speaker_body.queue_free()
		_speaker_body = null
		_remove_saves_dir()
		_remove_settings()
		_finish()
		return true

	return false


# --- Driving ------------------------------------------------------------------------


## Press an action the way the input system delivers one, and let the frame carry it.
func _press(action_name: StringName) -> void:
	_hold(action_name)
	_release(action_name)


## Put an action down and leave it down - what a player does with a movement key.
func _hold(action_name: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	Input.parse_input_event(event)
	# Flushed by hand: `parse_input_event` only QUEUES, and a headless run's process
	# frames do not line up with the physics frames this test steps on, so an
	# unflushed press arrives some frames later or not at all.
	Input.flush_buffered_events()


## And let it up again.
func _release(action_name: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Advance whatever conversation is on screen until it runs out. A choice table stops
## it, which is what `MAX_ADVANCES` is really guarding against.
func _walk_conversation_out() -> void:
	var frame := _shell.dialogue_frame()
	var steps := 0
	while _dialogue().is_active() and steps < 32:
		if frame.option_count() > 0:
			if not frame.leave():
				frame.choose(0)
		else:
			frame.advance()
		steps += 1


# --- Reading the playthrough ---------------------------------------------------------


func _services() -> Node:
	return root.get_node_or_null("Services")


func _dialogue() -> DialogueService:
	return _services().get(&"dialogue") as DialogueService


func _quests() -> QuestService:
	return _services().get(&"quests") as QuestService


func _rose() -> WhiteRoseService:
	return _services().get(&"rose") as WhiteRoseService


func _clock() -> GameClock:
	return _services().get(&"clock") as GameClock


func _npc() -> BarkService:
	return _services().get(&"npc") as BarkService


func _translated(key: StringName) -> String:
	return TranslationServer.translate(key)


func _remove_saves_dir() -> void:
	if DirAccess.dir_exists_absolute(SAVES_DIR):
		DirAccess.remove_absolute(SAVES_DIR)


## Take the scratch settings file away again, and stop redirecting the shell.
func _remove_settings() -> void:
	UiSettings.settings_path_override = ""
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
	var directory := SETTINGS_PATH.get_base_dir()
	if DirAccess.dir_exists_absolute(directory):
		DirAccess.remove_absolute(directory)


func _advance() -> void:
	_phase += 1
	_phase_frame = 0


func _check(condition: bool, description: String) -> void:
	_all_passed = check(condition, description) and _all_passed


func check(condition: bool, description: String) -> bool:
	if condition:
		print("PASS: " + description)
		return true
	print("FAIL: " + description)
	return false


func _fail() -> bool:
	_all_passed = false
	_finish()
	return true


func _finish() -> void:
	if _all_passed:
		print("UI TEST: PASS")
		quit(0)
	else:
		print("UI TEST: FAIL")
		quit(1)
