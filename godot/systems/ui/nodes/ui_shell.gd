class_name UiShell
extends Control

## Every screen in the game, in one node under the persistent layer's `UIRoot`.
##
## `docs/design/technical.md` §Regions and the persistent layer: the UI root "lives
## above the swapped scene and is never freed by a region change", so the shell is
## built once, survives every journey, and is handed the new services each time the
## composition root rebuilds them (`Services.rebuilt` - THE REATTACH LIST).
##
## **The shell owns wiring, not behaviour.** Each view knows how to draw itself from a
## service; this node knows which service, which action opens which page, and which
## pages stop the clock. `docs/design/technical.md` §Project layout: "`ui` depends on
## the rest only through queries and signals, never the reverse" - nothing outside
## `systems/ui/` refers to a single class in it.
##
## **While the screen is talking, the world is not touched.** `interact` is both the
## key that advances a line and the key that picks a prop up, and the two halves of the
## input surface cannot see each other: `DialogueFrame` consumes the action as an event,
## `FoolBody` polls it. So the shell - the one node that knows both that a conversation
## is running and that a menu is up - suspends the Fool's world interaction for as long
## as either is true (`FoolBody.set_world_interaction_enabled()`), and gives it back
## when the last of them goes away. Still wiring, not behaviour: what a suspension means
## is the body's, and the dialogue frame's event handling is untouched.
##
## **No new input actions.** `technical.md` §Input actions fixes the list, so the map
## is reached by pressing `almanack` again: the Almanack, then the Spread laid out on
## the table, then closed - "menu navigation moves like laying out a hand"
## (`art-audio.md` §UI/UX pillars). A dedicated `map` action would be a change to that
## doc's list and is listed as owed in `res://systems/ui/README.md`.

## The composition root, looked up by path exactly as every other scene script does.
const SERVICES_PATH := "/root/Services"

## The hand-authored table the map deals its cards onto.
const MAP_LAYOUT_PATH := "res://data/ui/map_layout.tres"

## The generated catalogs the Almanack reads names out of.
const QUEST_CATALOG_PATH := "res://data/quests/catalog.tres"
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"

## Every page, as its own scene under `res://scenes/ui/`.
##
## A view is a SCENE with a script, and the scene is the ENTRY POINT: it names the
## root's type and its script, and every Control under it is built in the view's own
## `_ready()`. That is the honest description of what these files are - twelve
## one-node scenes - and it is deliberate: nearly everything on a page is counted out
## of the world at runtime (a petal per point of capacity, a card per region, a row
## per dialogue option, a rebinding row per action), and a page built half in a scene
## file and half in code would have its layout in two places. The strings that would
## otherwise be linted in the `.tscn` are protected instead by
## `res://tests/unit/ui/ui_strings_test.gd`, which builds every page and reads back
## every string it drew.
const HUD_SCENE := "res://scenes/ui/hud.tscn"
const DIALOGUE_SCENE := "res://scenes/ui/dialogue_frame.tscn"
const SPREAD_SCENE := "res://scenes/ui/pocket_spread_screen.tscn"
const ALMANACK_SCENE := "res://scenes/ui/almanack.tscn"
const MAP_SCENE := "res://scenes/ui/map_screen.tscn"
const PIP_WHEEL_SCENE := "res://scenes/ui/pip_wheel_overlay.tscn"
const PAUSE_SCENE := "res://scenes/ui/pause_menu.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_screen.tscn"
const DEFEAT_SCENE := "res://scenes/ui/defeat_overlay.tscn"
const BARK_SCENE := "res://scenes/ui/bark_bubble.tscn"
const TRANSITION_SCENE := "res://scenes/ui/card_transition.tscn"

## The screens `UiState` counts, and therefore the ones that stop the clock.
const SCREEN_SPREAD := &"SPREAD"
const SCREEN_ALMANACK := &"ALMANACK"
const SCREEN_MAP := &"MAP"
const SCREEN_PAUSE := &"PAUSE"
const SCREEN_SETTINGS := &"SETTINGS"

var _state: UiState = null
var _settings: UiSettings = null
var _scale: UiScale = null
var _framing: CameraFraming = null

var _hud: Hud = null
var _dialogue_frame: DialogueFrame = null
var _spread_screen: PocketSpreadScreen = null
var _almanack: Almanack = null
var _map: MapScreen = null
var _pip_wheel: PipWheelOverlay = null
var _pause: PauseMenu = null
var _settings_screen: SettingsScreen = null
var _defeat: DefeatOverlay = null
var _bark: BarkBubble = null
var _transition: CardTransition = null
var _npc: BarkService = null

## The dialogue service being listened to for "somebody is talking to the Fool", and
## the answer it last gave. See the class doc.
var _dialogue: DialogueService = null
var _in_dialogue := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	# `for_boot()` and not `new()`: it is the one call that knows the player's real
	# settings file may have been redirected to a scratch path by a test.
	_settings = UiSettings.for_boot()
	_settings.load_file()
	_settings.apply_bindings()
	_settings.changed.connect(apply_settings)
	_scale = UiScale.new()
	_scale.apply(_settings.text_scale)
	theme = _scale.theme()
	_state = UiState.new()
	_state.menu_changed.connect(_on_menu_changed)
	_build()
	var root := services()
	if root != null and not root.is_connected(&"rebuilt", _on_services_rebuilt):
		root.connect(&"rebuilt", _on_services_rebuilt)
	attach_services()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputActions.SPREAD):
		toggle_spread()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputActions.ALMANACK):
		turn_almanack_page()
		get_viewport().set_input_as_handled()


# --- What the shell holds ----------------------------------------------------------


## The composition root, or null.
func services() -> Node:
	return get_node_or_null(SERVICES_PATH)


## Which screens are up, and the clock that follows them.
func state() -> UiState:
	return _state


## The player's settings.
func settings() -> UiSettings:
	return _settings


## The text-size helper over the one theme.
func ui_scale() -> UiScale:
	return _scale


## The conversational camera framing.
func framing() -> CameraFraming:
	return _framing


## Petals, Fortune, prompts.
func hud() -> Hud:
	return _hud


## The conversation panel.
func dialogue_frame() -> DialogueFrame:
	return _dialogue_frame


## The Pocket Spread screen.
func spread_screen() -> PocketSpreadScreen:
	return _spread_screen


## The Almanack.
func almanack() -> Almanack:
	return _almanack


## The map.
func map_screen() -> MapScreen:
	return _map


## Pip's wheel.
func pip_wheel_overlay() -> PipWheelOverlay:
	return _pip_wheel


## The pause menu.
func pause_menu() -> PauseMenu:
	return _pause


## The settings screen.
func settings_screen() -> SettingsScreen:
	return _settings_screen


## The defeat fade.
func defeat_overlay() -> DefeatOverlay:
	return _defeat


## The bark slip.
func bark_bubble() -> BarkBubble:
	return _bark


## The region card-flip.
func card_transition() -> CardTransition:
	return _transition


# --- Opening and closing -----------------------------------------------------------


## Open or close the Pocket Spread.
func toggle_spread() -> void:
	set_screen(SCREEN_SPREAD, not _state.is_open(SCREEN_SPREAD))


## Open or close the pause menu. With the settings up, it is the settings that close:
## `pause` is the way back out of wherever the player got to.
func toggle_pause() -> void:
	if _state.is_open(SCREEN_SETTINGS):
		set_screen(SCREEN_SETTINGS, false)
		return
	if _state.is_open(SCREEN_PAUSE):
		resume()
		return
	set_screen(SCREEN_PAUSE, true)


## Put the Reading back down: both pause pages close and the world runs again.
##
## Both, because "Resume" means resume. The settings screen is opened FROM the pause
## menu and sits on top of it, so closing only the menu underneath would leave the
## player looking at the settings with the clock still stopped and nothing left to
## press.
func resume() -> void:
	set_screen(SCREEN_SETTINGS, false)
	set_screen(SCREEN_PAUSE, false)


## The Almanack action, pressed once more: journal, then the Spread on the table, then
## put both down. See the class doc for why the map has no action of its own.
func turn_almanack_page() -> void:
	if _state.is_open(SCREEN_ALMANACK):
		set_screen(SCREEN_ALMANACK, false)
		set_screen(SCREEN_MAP, true)
		return
	if _state.is_open(SCREEN_MAP):
		set_screen(SCREEN_MAP, false)
		return
	set_screen(SCREEN_ALMANACK, true)


## Show or hide one screen, and let the clock follow.
func set_screen(screen: StringName, open: bool) -> void:
	var view := _view_for(screen)
	if view == null:
		return
	view.visible = open
	if open and screen == SCREEN_ALMANACK and _almanack != null:
		_almanack.refresh()
	if open and screen == SCREEN_MAP and _map != null:
		_map.refresh()
	if open and screen == SCREEN_SPREAD and _spread_screen != null:
		_spread_screen.refresh()
	if open and screen == SCREEN_PAUSE and _pause != null:
		_pause.refresh()
	_state.set_open(screen, open)


## Close every screen. Used when a playthrough is thrown away.
func close_all_screens() -> void:
	for screen: StringName in [
		SCREEN_SPREAD, SCREEN_ALMANACK, SCREEN_MAP, SCREEN_PAUSE, SCREEN_SETTINGS
	]:
		set_screen(screen, false)


## Say one line over somebody's head (round 12's barks).
func say_bark(text_key: StringName, speaker: Node2D = null) -> void:
	if _bark != null:
		_bark.say(text_key, speaker)


## Draw the line `BarkService` just picked over the body of whoever said it.
##
## The service decides WHICH line and WHEN (`docs/design/npc-system.md` owns both);
## this turns its answer into the slip on screen. **A speaker with no body gets no
## bubble**: a bark is "a small chip above an NPC" (`BarkBubble`), and the one speaker
## the shipped catalog has - the Querent - is by canon a voice nobody sees
## (`characters.md` §The Querent). What to do with a Querent line instead is
## `art-audio.md`'s call and is listed as owed in `res://systems/ui/README.md`.
func say_bark_for(speaker: StringName, bark_id: StringName) -> bool:
	if _bark == null or _npc == null:
		return false
	var catalog := _npc.catalog()
	if catalog == null:
		return false
	var bark := catalog.find(bark_id)
	if bark == null:
		return false
	var body := speaker_node(speaker)
	if body == null:
		return false
	_bark.say(bark.text_key, body)
	return true


## Frame a conversation between two people, easing the camera in.
func frame_conversation(a: Node2D, b: Node2D) -> bool:
	return false if _framing == null else _framing.frame_conversation(a, b)


## The body a speaker has in the world, or null when they have none.
##
## THE SPEAKER-NODE PROVIDER. The shell is the one node that can answer this: the
## persistent layer beside it owns the Fool and Pip and never lets go of them
## (`technical.md` §Regions and the persistent layer), and a region scene above it
## owns its own people. A view is handed this as a `Callable` and never walks the tree
## itself, which is what keeps `systems/ui/` reaching outward through queries only
## (`technical.md` §Project layout).
##
## A named speaker is found by GROUP: a region scene's NPC joins the group named by
## the speaker id it answers to (`Speakers.FLICK` -> group `&"FLICK"`), which is how a
## scene registers a body without either side naming a node path. No shipped region
## scene has an NPC in it yet, so today this answers the Fool, Pip, and null.
func speaker_node(node_id: StringName) -> Node2D:
	if node_id == &"":
		return null
	var found := layer()
	if node_id == Speakers.FOOL:
		return null if found == null else found.fool()
	if node_id == DialogueFrame.PIP_NODE:
		return null if found == null else found.pip()
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(node_id):
		var body := node as Node2D
		if body != null:
			return body
	return null


## Push every setting that reaches a node or a service, again.
##
## Called at boot, after every `Services` rebuild, and on `UiSettings.changed` - which
## is what makes a toggle flipped in the settings screen land on the thing it toggles
## rather than only in the file. Everything here must be safe to do twice.
func apply_settings() -> void:
	if _scale != null:
		_scale.apply(_settings.text_scale)
	if _hud != null:
		_hud.vignette().set_flash_allowed(_settings.screen_flash)
	var root := services()
	var combat: CombatService = null if root == null else root.get(&"combat") as CombatService
	_settings.apply_to(combat, _fool_combat())


# --- Wiring ------------------------------------------------------------------------


## Hand every view the services as they stand now. Safe with no composition root at
## all, which is what a view test gets.
func attach_services() -> void:
	var root := services()
	var combat: CombatService = null if root == null else root.get(&"combat") as CombatService
	var rose: WhiteRoseService = null if root == null else root.get(&"rose") as WhiteRoseService
	var fortune: FortuneService = null if root == null else root.get(&"fortune") as FortuneService
	var spread: PocketSpreadService = (
		null if root == null else root.get(&"spread") as PocketSpreadService
	)
	var quests: QuestService = null if root == null else root.get(&"quests") as QuestService
	var dialogue: DialogueService = (
		null if root == null else root.get(&"dialogue") as DialogueService
	)
	var world_state: WorldStateService = (
		null if root == null else root.get(&"world_state") as WorldStateService
	)
	var enemies: EnemyService = null if root == null else root.get(&"enemies") as EnemyService
	var regions: RegionService = null if root == null else root.get(&"regions") as RegionService
	var save: SaveService = null if root == null else root.get(&"save") as SaveService
	var clock: GameClock = null if root == null else root.get(&"clock") as GameClock

	_state.attach_clock(clock)
	_attach_barks(null if root == null else root.get(&"npc") as BarkService)
	_attach_dialogue(dialogue)
	if _hud != null:
		_hud.attach(rose, fortune, combat)
	if _dialogue_frame != null:
		_dialogue_frame.attach(dialogue, _framing)
		_dialogue_frame.set_speaker_node_provider(speaker_node)
	if _spread_screen != null:
		_spread_screen.attach(spread)
	if _almanack != null:
		_almanack.attach(
			quests,
			world_state,
			spread,
			enemies,
			load(QUEST_CATALOG_PATH) as QuestCatalog,
			load(TRUMP_CATALOG_PATH) as TrumpCatalog
		)
	if _map != null:
		_map.attach(regions, world_state, load(MAP_LAYOUT_PATH) as MapLayout)
	if _pause != null:
		_pause.attach(save)
	if _transition != null:
		_transition.attach(regions)
	_attach_layer_nodes(combat)
	if _settings_screen != null:
		_settings_screen.attach(_settings, combat, _fool_combat(), _scale)
	apply_settings()


## Listen to the bark service for the line it just picked, and stop listening to the
## one a rebuild threw away.
func _attach_barks(npc: BarkService) -> void:
	if _npc == npc:
		return
	if _npc != null and _npc.bark_picked.is_connected(_on_bark_picked):
		_npc.bark_picked.disconnect(_on_bark_picked)
	_npc = npc
	if _npc != null and not _npc.bark_picked.is_connected(_on_bark_picked):
		_npc.bark_picked.connect(_on_bark_picked)


## The bark service that is being listened to, or null.
func barks() -> BarkService:
	return _npc


## Listen to the dialogue service for the conversation starting and ending, and stop
## listening to the one a rebuild threw away. The frame draws the words; this is only
## the shell noticing that somebody is talking (see the class doc).
func _attach_dialogue(dialogue: DialogueService) -> void:
	if _dialogue != dialogue:
		if _dialogue != null:
			if _dialogue.dialogue_started.is_connected(_on_dialogue_started):
				_dialogue.dialogue_started.disconnect(_on_dialogue_started)
			if _dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
				_dialogue.dialogue_ended.disconnect(_on_dialogue_ended)
		_dialogue = dialogue
		if _dialogue != null:
			if not _dialogue.dialogue_started.is_connected(_on_dialogue_started):
				_dialogue.dialogue_started.connect(_on_dialogue_started)
			if not _dialogue.dialogue_ended.is_connected(_on_dialogue_ended):
				_dialogue.dialogue_ended.connect(_on_dialogue_ended)
	_in_dialogue = _dialogue != null and _dialogue.is_active()


## The dialogue service that is being listened to, or null.
func dialogue_heard() -> DialogueService:
	return _dialogue


func _on_dialogue_started(_graph_id: StringName) -> void:
	_in_dialogue = true
	_update_world_interaction()


## A graph that chains into another (`DialogueGraph.next_graph_id`) ends before the next
## one starts, so this asks the service rather than assuming the talking is over.
func _on_dialogue_ended(_graph_id: StringName) -> void:
	_in_dialogue = _dialogue != null and _dialogue.is_active()
	_update_world_interaction()


func _on_menu_changed(_screen: StringName, _open: bool, _open_count: int) -> void:
	_update_world_interaction()


## True while the Fool's own hands are free: nobody is talking to him and no menu is up.
func world_interaction_allowed() -> bool:
	return not _in_dialogue and not _state.any_menu_open()


## The Fool's body on the persistent layer beside this shell, or null when there is no
## layer to look on - the same walk `speaker_node()` makes.
func fool_body() -> FoolBody:
	var found := layer()
	if found == null:
		return null
	return found.fool() as FoolBody


## Tell the Fool whether the world is his to touch right now.
func _update_world_interaction() -> void:
	var fool := fool_body()
	if fool != null:
		fool.set_world_interaction_enabled(world_interaction_allowed())


func _on_bark_picked(speaker: StringName, bark_id: StringName, _layer: int) -> void:
	say_bark_for(speaker, bark_id)


## The persistent layer this shell hangs under, or null when it hangs under nothing.
func layer() -> PersistentLayer:
	# `get_parent()` on the tree root is null, which is what ends the walk.
	var walker := get_parent()
	while walker != null:
		var found := walker as PersistentLayer
		if found != null:
			return found
		walker = walker.get_parent()
	return null


func _fool_combat() -> FoolCombat:
	var found := layer()
	if found == null:
		return null
	return found.get_node_or_null("Fool/FoolCombat") as FoolCombat


func _pip_companion() -> PipCompanion:
	var found := layer()
	if found == null:
		return null
	return found.get_node_or_null("Pip/PipCompanion") as PipCompanion


## Hand the views the nodes that live on the persistent layer beside this one: the
## camera the conversation frames, Pip's wheel, and the Fool's own body.
func _attach_layer_nodes(combat: CombatService) -> void:
	var found := layer()
	if _framing != null:
		_framing.attach_camera(null if found == null else found.camera())
	if _pip_wheel != null:
		_pip_wheel.attach(_pip_companion())
	if _defeat != null:
		_defeat.attach(combat, _pip_companion())
	if _hud != null and combat != null:
		_hud.health_meter().attach(combat.fool())
	# Last, because it is a state and not a wire: whatever is on screen right now
	# decides it, and a Fool found for the first time here has heard nothing yet.
	_update_world_interaction()


func _on_services_rebuilt() -> void:
	close_all_screens()
	attach_services()


func _build() -> void:
	_framing = CameraFraming.new()
	add_child(_framing)

	_hud = _instance(HUD_SCENE) as Hud
	add_child(_hud)

	_transition = _instance(TRANSITION_SCENE) as CardTransition
	add_child(_transition)

	_bark = _instance(BARK_SCENE) as BarkBubble
	add_child(_bark)

	_dialogue_frame = _instance(DIALOGUE_SCENE) as DialogueFrame
	_dialogue_frame.anchor_top = 1.0 - DialogueFrame.FRAME_HEIGHT_RATIO
	_dialogue_frame.anchor_bottom = 1.0
	_dialogue_frame.anchor_left = 0.0
	_dialogue_frame.anchor_right = 1.0
	add_child(_dialogue_frame)

	_pip_wheel = _instance(PIP_WHEEL_SCENE) as PipWheelOverlay
	add_child(_pip_wheel)

	_spread_screen = _instance(SPREAD_SCENE) as PocketSpreadScreen
	_spread_screen.close_requested.connect(set_screen.bind(SCREEN_SPREAD, false))
	add_child(_spread_screen)

	_almanack = _instance(ALMANACK_SCENE) as Almanack
	_almanack.close_requested.connect(set_screen.bind(SCREEN_ALMANACK, false))
	add_child(_almanack)

	_map = _instance(MAP_SCENE) as MapScreen
	_map.close_requested.connect(set_screen.bind(SCREEN_MAP, false))
	add_child(_map)

	_pause = _instance(PAUSE_SCENE) as PauseMenu
	_pause.resume_requested.connect(resume)
	_pause.settings_requested.connect(set_screen.bind(SCREEN_SETTINGS, true))
	_pause.save_requested.connect(_on_save_requested)
	_pause.load_requested.connect(_on_load_requested)
	_pause.quit_requested.connect(_on_quit_requested)
	add_child(_pause)

	_settings_screen = _instance(SETTINGS_SCENE) as SettingsScreen
	add_child(_settings_screen)

	_defeat = _instance(DEFEAT_SCENE) as DefeatOverlay
	add_child(_defeat)


## One page, out of its own scene file.
static func _instance(scene_path: String) -> Control:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("the UI shell cannot load %s" % scene_path)
		return null
	return packed.instantiate() as Control


func _on_save_requested(slot: int) -> void:
	var root := services()
	if root == null:
		return
	root.call(&"save_game", slot)
	if _pause != null:
		_pause.refresh()


func _on_load_requested(slot: int) -> void:
	var root := services()
	if root == null:
		return
	root.call(&"load_game", slot)


func _on_quit_requested() -> void:
	get_tree().quit()


func _view_for(screen: StringName) -> Control:
	match screen:
		SCREEN_SPREAD:
			return _spread_screen
		SCREEN_ALMANACK:
			return _almanack
		SCREEN_MAP:
			return _map
		SCREEN_PAUSE:
			return _pause
		SCREEN_SETTINGS:
			return _settings_screen
	return null
