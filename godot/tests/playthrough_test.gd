extends SceneTree

## THE PROOF SLICE: MQ00 played from the black screen to a shop in the Prestige, in
## one process, through the game's own input actions.
##
## Every other legacy scene test proves one system against a fixture. This one proves
## the SLICE - that the thirteen systems built over rounds 0-13 hold hands for the
## length of a real playthrough: the boot starts a quest, a conversation, a region and
## a Fool; a prop answers the interact key; a dog answers the command wheel; three
## Blanks answer the Bindle; a shrine answers the same interact key and regrows the
## White Rose; the lip of the world answers a Fool who has finished the tutorial; and a
## stall in the next region takes Coins for popcorn. Then the whole of it is written to
## a slot, thrown away, read back, and asserted equal.
##
## **What "the real input path" means here, exactly.** Walking, attacking, dodging,
## interacting, healing and Pip's wheel are all driven by pressing the InputMap actions
## `docs/design/technical.md` §Input actions lists - never by calling the controller,
## the companion or the prop. Presses go through `Input.parse_input_event()` with an
## `InputEventAction` and are flushed by hand, because that reaches BOTH halves of the
## input surface: the polled one (`player.gd`, `FoolCombat`, `PipCompanion` all read
## `Input.is_action_pressed` / `get_vector`) and the event one (`DialogueFrame` and
## `UiShell` answer `_unhandled_input`). A tap is held for two physics frames, for the
## reason `tests/combat_test.gd` spells out.
##
## **Teleports.** The Cliff is roughly 3,000 px corner to corner and the Fool walks at
## 200 px/s, so crossing it four times would be four fifths of the suite's whole time
## budget for nothing. The Fool (and Pip with him) is therefore SET DOWN at a stand-off
## outside the next beat's own trigger and WALKS IN from there under the move actions.
## No teleport ever lands inside a trigger, inside an encounter volume, inside a
## Waystation's circle or on the leap point: every beat is entered on the Fool's legs.
##
## **The two beats this cannot drive through an InputMap action, and why.** They are
## findings rather than failures and are named here so the report and the test agree:
##
##   1. **A dialogue CHOICE row.** `DialogueFrame` builds the Fool's options as
##      `Button`s and there is no `choose the second option` action in the map - the
##      row is taken with focus navigation and `ui_accept`, and `ui_accept` shares its
##      default key with `dodge` (round 0's logged debt), so pressing it here would
##      roll the Fool instead of asking the question. The row is taken through
##      `DialogueFrame.choose()`, which is the same call its own button handler makes.
##      Advancing a LINE *is* an action (`interact`) and is pressed.
##   2. **Buying at the Prestige stall.** The Prestige is a marked greybox
##      (`scenes/regions/README.md`): it has a Ground, three markers and a Waystation,
##      and no shop node. There is nothing in the world to walk up to, so the purchase
##      goes through `EconomyService.buy()` - the call a shop node would make. Coins are
##      granted by the test for the same reason: `systems/progression/README.md` records
##      that nothing in the game hands the Fool a Coin yet.
##
## **One coupling this test found, and the fix that came of it.** `player.gd` polls
## `Input.is_action_just_pressed(interact)` every physics frame, while `DialogueFrame`
## consumes the same action as an EVENT and calls `set_input_as_handled()`. Handling an
## event does not stop a poll, so **advancing a line of dialogue also acted on whatever
## prop was in reach**. It was not theoretical on the Cliff: a new game stands the Fool
## on the DEFAULT marker 184 px from the `BindleTrigger`, whose own circle is 90 px and
## whose finder is the Fool's 96 px sensor - 184 < 186, so the trigger is in reach at
## spawn, and the FIRST press that advanced the Querent's waking line picked the Bindle
## up before the tutorial had asked for it. It was visible at the Waystation too, where
## advancing the rest conversation rested again (harmlessly - a rest is idempotent).
##
## Fixed by SUSPENSION rather than by making the action consumable: while a conversation
## is on screen or a menu is up, `UiShell` puts the Fool's world interaction down
## (`FoolBody.set_world_interaction_enabled()`), and `DialogueFrame`'s event handling is
## exactly as it was. Phase 1 is the proof and no longer works around it - the opening
## conversation is walked out ON the spawn marker, with the Bindle's trigger in reach
## the whole time, and the Bindle has to still be lying there when the talking stops.

# --- Where this test's files go -----------------------------------------------------

## This test writes a real save to a real slot; it must never be the player's.
const SAVES_DIR := "user://test_playthrough_saves"

## And the shell writes settings the moment anything touches them, so it is pointed at
## a scratch file before the layer is instanced (`UiSettings.settings_path_override`,
## and see `tests/ui_test.gd`, which found the bug this prevents).
const SETTINGS_PATH := "user://test_playthrough_settings/settings.cfg"

## A slot no playthrough uses, written and deleted here.
const SLOT := 8

# --- Timing -------------------------------------------------------------------------

## Physics frames to let pass after a placement before overlaps are believed.
const SETTLE_FRAMES := 5

## The frame budget every phase is held to unless `PHASE_BUDGETS` names another. A
## phase that overruns FAILS by name rather than running the suite into the harness's
## 120 s timeout, where the diagnosis would be "something hung".
const DEFAULT_PHASE_BUDGET := 400

## How many physics frames one conversation may take to walk out.
const DIALOGUE_BUDGET := 400

# --- The Cliff, beat by beat --------------------------------------------------------
#
# Trigger geometry is `scenes/the_cliff.tscn`'s own: the dead tree's approach is a
# 220 px circle, the cliff edge's a 110 px one, the ambush volume 200 px, the leap
# point 150 px and the Waystation's near-zone 260 px. Every stand-off below is outside
# the circle it belongs to, so walking in is what enters it.

const BINDLE_POSITION := Vector2(3660, 2470)
## Where a new game puts the Fool down: the Cliff's own DEFAULT marker, out in the
## meadow with the dead campfire. No teleport is needed for the first beat.
const MEADOW_SPAWN := Vector2(3820, 2560)

## Every quest trigger on the Cliff carries the same 90 px circle
## (`scenes/the_cliff.tscn`, `CircleShape2D_trigger`). With the Fool's own 96 px sensor
## that is a 186 px reach, which is what puts the `BindleTrigger` inside the Fool's
## grasp at the spawn marker 184 px away - the geometry phase 1 stands on.
const TRIGGER_RADIUS := 90.0

const EARTH_POSITION := Vector2(3090, 2230)
const EARTH_STANDOFF := Vector2(3330, 2350)

const DEAD_TREE_POSITION := Vector2(2250, 1250)
const DEAD_TREE_STANDOFF := Vector2(2560, 1560)

const AMBUSH_POSITION := Vector2(1655, 1240)
const AMBUSH_STANDOFF := Vector2(2000, 1300)

const WAYSTATION_POSITION := Vector2(1430, 1000)
const WAYSTATION_STANDOFF := Vector2(1750, 980)

const CLIFF_EDGE_POSITION := Vector2(1280, 800)
const LEAP_POSITION := Vector2(1150, 650)

## How close the Fool has to get to a walk target before the leg is over. Larger than a
## single frame's travel (3.3 px) so the walk cannot oscillate about the point.
const ARRIVE_RADIUS := 24.0

## How close the Fool has to be to act on a prop. `FoolBody.INTERACT_REACH` is 96.
const INTERACT_RADIUS := 60.0

## Physics frames to let pass after a press before the world is believed to have heard
## it. `player.gd` POLLS `interact` in its own `_physics_process`, one frame behind an
## event this script flushed, so a "the prop was not touched" assertion made in the
## same frame as the press would pass whether the prop was protected or not.
const POLL_FRAMES := 3

## A walk that has not closed on its target in this many frames is stuck - a collision
## nobody expected - and fails by name with the position it is stuck at.
const WALK_STALL_FRAMES := 240

# --- The fight -----------------------------------------------------------------------

## How far from a Blank the Fool stands to swing. Inside the Bindle's light reach
## (`CombatRules.light_radius`, 96) with room for a body that is still moving.
const SWING_DISTANCE := 62.0

## How close the Fool walks before the move actions are let go: near enough that the
## last thing he faced is the body he is standing against.
const CONTACT_DISTANCE := 30.0

## The accessibility slider used for the perfect dodge, in seconds - the same value and
## the same reason as `tests/enemies_test.gd`: wide enough that a one-frame difference
## in when a press is seen cannot decide the test, and it proves the slider reaches a
## real Blank's hit. Independent of difficulty (`combat.md` §Accessibility).
const SLIDER_SECONDS := 0.10

## How long before a Blank's hit lands the dodge is pressed.
const PERFECT_DODGE_LEAD := 0.14

## At or below this the Fool spends a petal, through the `rose` action. Sized against
## the two facts either side of it: a petal restores `CombatRules.petal_heal` (40) of a
## 100-point pool, so healing much above this throws most of one away, and the three
## Twos land 7-10 a hit, so this is reached after two or three of them - which they
## always manage in a fight this long.
const ROSE_AT_HEALTH := 80

## The fight's own budget: three Twos at roughly one light string each, plus the dodge
## attempts, one Fool's Chance window and the walk after the Cups Blank, which keeps its
## distance and has to be run down.
const FIGHT_BUDGET := 1400

## Pip's Seek: the run out, `PipRules.seek_reveal_seconds` of digging, and the trot home,
## with room to spare.
const SEEK_BUDGET := 900

# --- The Prestige ---------------------------------------------------------------------

## Coins granted for the popcorn. Nothing in the game hands the Fool a Coin yet
## (`systems/progression/README.md`), so the test is the quest that would.
const COINS_GRANTED := 40

## Why the purse moved, for the signal a shop keeper would give.
const COINS_REASON := &"PLAYTHROUGH_TEST"

# --- Phases ---------------------------------------------------------------------------

## Every phase, in order, by the beat it plays. The timeline printed at the end is this
## list against the frames each one took.
const PHASE_NAMES: PackedStringArray = [
	"boot",
	"wake",
	"bindle",
	"seek",
	"wooden dog",
	"dead tree",
	"ambush walk-in",
	"the fight",
	"waystation",
	"cliff edge",
	"the leap",
	"the prestige",
	"save",
	"load",
]

## The phases whose budget is not `DEFAULT_PHASE_BUDGET`.
const PHASE_BUDGETS: Dictionary = {
	1: DIALOGUE_BUDGET,
	3: SEEK_BUDGET,
	4: DIALOGUE_BUDGET,
	7: FIGHT_BUDGET,
	9: DIALOGUE_BUDGET,
}

var _all_passed := true
var _phase := 0
var _phase_frame := 0
var _step := 0
var _frame := 0

## Phase name -> frames it took, in order, printed at the end.
var _timeline: PackedStringArray = PackedStringArray()

var _layer: PersistentLayer = null
var _shell: UiShell = null
var _cliff: RegionScene = null

## What the fight and the Rose announced, so a signal is what is asserted rather than a
## poll that happened to be looking at the right moment.
var _fools_chance_count := 0
var _petals_spent := 0
var _flutters := 0
var _defeats := 0

## Every option row the Fool took, by its own text key, so "all four threads" is a set
## of keys from the script rather than a count that a nested follow-up table inflates.
var _picked_keys: PackedStringArray = PackedStringArray()

## How many times Pip's Seek dug the earth out.
var _digs := 0

## The line on the parchment before an `interact` was pressed at it, so "the press
## reached the conversation" is an assertion rather than an assumption.
var _line_before: StringName = &""

## The phase frame that press went out on, so the poll it would have reached can be
## given its frames before anything is believed about the world (`POLL_FRAMES`).
var _pressed_on_frame := 0

## The actions currently held down, so a hold is not re-stamped every frame (which
## would make `is_action_just_pressed` true forever).
var _held: Array[StringName] = []

## Taps waiting to be released, one frame's worth each - the two-frame protocol.
var _release_now: Array[StringName] = []
var _release_next: Array[StringName] = []

## Where the walk being driven is heading, and how it is going.
var _walk_target := Vector2.ZERO
var _walk_best := INF
var _walk_stall := 0

## What the playthrough looked like the instant before it was saved, so the load can be
## compared against something taken from the living world rather than from the file.
var _before: Dictionary = {}

## True once the verdict has been printed, so a phase that fails inside a helper and
## then falls through to its own failure line does not print two verdicts.
var _finished := false



func _initialize() -> void:
	# Before the layer, because the shell it carries loads the settings in `_ready`.
	UiSettings.settings_path_override = SETTINGS_PATH
	var packed: PackedScene = load("res://scenes/persistent_layer.tscn") as PackedScene
	_layer = packed.instantiate() as PersistentLayer
	# The boot is taken over so the saves directory can be pointed somewhere scratch
	# before a playthrough exists to write (see `tests/README.md`).
	_layer.boot_new_game_on_ready = false
	root.add_child(_layer)


func _physics_process(_delta: float) -> bool:
	_release_taps()
	_frame += 1
	_phase_frame += 1
	if _phase_frame > _budget():
		_check(false, "%s finished inside its %d-frame budget" % [_phase_name(), _budget()])
		return _finish()
	match _phase:
		0:
			return _phase_boot()
		1:
			return _phase_wake()
		2:
			return _phase_bindle()
		3:
			return _phase_seek()
		4:
			return _phase_wooden_dog()
		5:
			return _phase_dead_tree()
		6:
			return _phase_ambush_walk_in()
		7:
			return _phase_the_fight()
		8:
			return _phase_waystation()
		9:
			return _phase_cliff_edge()
		10:
			return _phase_the_leap()
		11:
			return _phase_the_prestige()
		12:
			return _phase_save()
		13:
			return _phase_load()
	return _finish()


# --- Phase 0: the composition root, pointed somewhere scratch ------------------------


func _phase_boot() -> bool:
	var services := root.get_node_or_null("Services")
	if not check(services != null, "the Services autoload is up"):
		return _fail()
	services.call(&"set_saves_dir", SAVES_DIR)
	_shell = _layer.get_node_or_null("UIRoot/UiShell") as UiShell
	if not check(_shell != null, "the persistent layer carries the UI shell"):
		return _fail()
	_check(
		_shell.settings().path() == SETTINGS_PATH,
		"which booted against this test's settings file, not the player's own"
	)
	_check(
		_save_service() != null and _save_service().saves_dir() == SAVES_DIR,
		"and the composition root writes into this test's scratch saves directory"
	)
	if not check(_layer.new_game(), "a new game starts"):
		return _fail()
	_advance()
	return false


# --- Phase 1: the black screen, and the Querent waking the Fool ----------------------


func _phase_wake() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES:
				return false
			if not check(_layer.region() != null, "the boot instanced a region"):
				return _fail()
			_cliff = _layer.region()
			_check(_cliff.region_id == RegionIds.CLIFF, "and a new game opens on the Cliff")
			_check(
				_quests().is_started(QuestIds.MQ00), "with MQ00 running - the boot starts it"
			)
			_check(_quest_state() == &"WAKING", "at WAKING, beside the dead campfire")
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_WAKE,
				"and the Querent waking the Fool over the black screen"
			)
			_check(_shell.dialogue_frame().visible, "which the dialogue frame is showing")
			_check(
				_shell.dialogue_frame().speaker_key() == &"SPEAKER_QUERENT",
				"under the Querent's own name key"
			)
			# Wire the two signals the fight and the Rose are asserted through, and the
			# dig site, before anything can emit one.
			_combat().fools_chance_started.connect(_on_fools_chance)
			_combat().rose_used.connect(_on_rose_used)
			_combat().fool_defeated.connect(_on_fool_defeated)
			_enemies().card_fluttered.connect(_on_card_fluttered)
			var earth := _earth()
			if earth != null:
				earth.found.connect(_on_earth_found)
			_check(
				_layer.fool().global_position.distance_to(MEADOW_SPAWN) <= 1.0,
				"with the Fool on the Cliff's own spawn marker"
			)
			# NOT stepped clear of the props first, which is the point of this phase:
			# the Bindle's trigger is inside the Fool's reach from the spawn marker,
			# and the whole conversation is walked out standing in it. See the class
			# doc for the bug that geometry used to produce.
			var at_spawn := _bindle_trigger()
			var reach := FoolBody.INTERACT_REACH + TRIGGER_RADIUS
			_check(
				at_spawn != null and _fool_distance_to(at_spawn) < reach,
				"and the Bindle's own trigger already within reach of him (%.0f px < %.0f)" % [
					_fool_distance_to(at_spawn), reach
				]
			)
			_line_before = _shell.dialogue_frame().line_key()
			_step = 1
		1:
			# One press of `interact`: the conversation's, and only the conversation's.
			_press(InputActions.INTERACT)
			_pressed_on_frame = _phase_frame
			_step = 2
		2:
			# Held until the Fool's own poll has certainly run. `DialogueFrame` sees the
			# press as an event, the moment it is flushed from this script; `player.gd`
			# reads the same action in its `_physics_process`, and a press parsed out of
			# a `SceneTree` callback does not read as `just_pressed` there until the
			# frame after. Asserting any sooner would assert nothing.
			if _phase_frame - _pressed_on_frame < POLL_FRAMES:
				return false
			_check(
				_shell.dialogue_frame().line_key() != _line_before,
				"pressing `interact` advances the Querent's line"
			)
			var after_one_press := _bindle_trigger()
			_check(
				after_one_press != null and not after_one_press.is_spent(),
				"and leaves the Bindle's trigger unspent under the Fool's feet"
			)
			_check(_quest_state() == &"WAKING", "so MQ00 has not skipped to BINDLE_TAKEN")
			_check(_bindle_is_in_the_meadow(), "and the Bindle is still lying in the meadow")
			_step = 3
		3:
			# Walked out on the `interact` action, which is what `DialogueFrame`
			# answers - the same key the Fool picks the Bindle up with.
			if not _walk_conversation_out():
				return false
			_check(not _dialogue().is_active(), "the opening line is walked out on `interact`")
			_check(not _shell.dialogue_frame().visible, "and the parchment goes away with it")
			_pressed_on_frame = _phase_frame
			_step = 4
		4:
			# The same wait again, and for the sharper half of the fix: the press that
			# DISMISSED the last line is still held down when the world is handed back,
			# and the poll it reaches a frame later must not act on anything either.
			if _phase_frame - _pressed_on_frame < POLL_FRAMES:
				return false
			_check(_quest_state() == &"WAKING", "and saying it moved no quest")
			var after_the_talk := _bindle_trigger()
			_check(
				after_the_talk != null
				and not after_the_talk.is_spent()
				and _bindle_is_in_the_meadow(),
				"nor picked the Bindle up: the press that ends a conversation is the "
				+ "conversation's"
			)
			_advance()
	return false


## The Bindle's quest trigger, the one the Fool stands inside through the waking line.
func _bindle_trigger() -> Interactable:
	if _cliff == null:
		return null
	return _cliff.get_node_or_null("World/QuestTriggers/BindleTrigger") as Interactable


## True while the Bindle is still drawn where it was left.
func _bindle_is_in_the_meadow() -> bool:
	var bindle := null if _cliff == null else _cliff.get_node_or_null("World/Props/Bindle")
	var sprite := bindle as Node2D
	return sprite != null and sprite.visible


## How far the Fool is from a node right now.
func _fool_distance_to(node: Node2D) -> float:
	var fool := _layer.fool()
	if fool == null or node == null:
		return INF
	return fool.global_position.distance_to(node.global_position)


# --- Phase 2: the Bindle ---------------------------------------------------------------


func _phase_bindle() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES:
				return false
			_start_walk(BINDLE_POSITION)
			_step = 1
		1:
			if not _walk_step(INTERACT_RADIUS):
				return false
			_step = 2
		2:
			_press(InputActions.INTERACT)
			_step = 3
		3:
			if _quest_state() == &"WAKING":
				return false
			_check(
				_quest_state() == &"BINDLE_TAKEN",
				"pressing `interact` at the Bindle advances MQ00 (state %s)" % _quest_state()
			)
			var bindle := _cliff.get_node_or_null("World/Props/Bindle") as Node2D
			_check(
				bindle != null and not bindle.visible,
				"and the Bindle is gone from the meadow once taken"
			)
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_MEADOW,
				"the Querent's meadow line starts on the beat"
			)
			_step = 4
		4:
			if not _walk_conversation_out():
				return false
			_set_down(EARTH_STANDOFF)
			_advance()
	return false


# --- Phase 3: Pip's Seek at the disturbed earth ------------------------------------------


## `docs/quests/main/MQ00-the-leap.md` §The Old Campsites writes this tutorial prompt as
## "call Pip's Seek command", so the beat is the WHEEL: hold `pip_wheel`, aim the move
## vector down (`PipWheel`'s Seek sector), let go. Nothing here calls `issue()`.
func _open_the_seek_wheel() -> void:
	_hold(InputActions.PIP_WHEEL)
	_hold(InputActions.MOVE_DOWN)


func _phase_seek() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES:
				return false
			var pip := _layer.pip()
			_check(
				pip != null and pip.global_position.distance_to(EARTH_POSITION) <= _seek_radius(),
				"Pip is inside Seek's own reach of the disturbed earth"
			)
			_open_the_seek_wheel()
			_step = 1
		1:
			# Three frames of the wheel open with the stick down: the companion reads
			# the sector every frame it is held.
			if _phase_frame < SETTLE_FRAMES + 3:
				return false
			var companion := _companion()
			if not check(companion != null, "Pip carries his command wheel"):
				return _fail()
			_check(
				companion.wheel().highlighted() == int(PipCommand.Id.SEEK),
				"holding the wheel with the stick down lights the Seek sector"
			)
			_let_go(InputActions.PIP_WHEEL)
			_step = 2
		2:
			_let_go(InputActions.MOVE_DOWN)
			_check(
				_pip_service().state() == PipService.State.SEEKING,
				"and letting go sends him (state %d)" % int(_pip_service().state())
			)
			_check(_digs == 0, "with nothing found the instant he is sent")
			_step = 3
		3:
			if _digs == 0:
				return false
			_check(_digs == 1, "Pip digs the whittled wooden dog out")
			_check(
				_quest_state() == &"KEEPSAKE_FOUND",
				"which advances MQ00 (state %s)" % _quest_state()
			)
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_KEEPSAKE_GIVEN,
				"and starts the Querent's line about it"
			)
			_advance()
	return false


# --- Phase 4: the wooden dog's three questions -------------------------------------------


func _phase_wooden_dog() -> bool:
	match _step:
		0:
			# The keepsake line chains into the table (`DialogueGraph.next_graph_id`),
			# so the lines are advanced until the Fool is the one being asked to speak.
			if _shell.dialogue_frame().option_count() == 0:
				if not _dialogue().is_active():
					_check(false, "the wooden dog's table came up")
					return _finish()
				_advance_a_line()
				return false
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_WOODEN_DOG,
				"the keepsake line chains into the wooden dog's own table"
			)
			_check(
				_shell.dialogue_frame().option_count() == 3,
				"offering the script's three questions (%d)"
					% _shell.dialogue_frame().option_count()
			)
			_check(
				_shell.dialogue_frame().is_leave_offered(),
				"with a row to stop asking on, because all of them MAY be exhausted"
			)
			_step = 1
		1:
			# Every option, then the leave row: the whole table, exhausted.
			if not _walk_conversation_out():
				return false
			_asked_them_all(
				PackedStringArray([
					"DLG_MQ00_WOODEN_DOG_Q1",
					"DLG_MQ00_WOODEN_DOG_Q2",
					"DLG_MQ00_WOODEN_DOG_Q3",
				]),
				"the Fool asks all three of the script's questions about the dog"
			)
			_check(not _dialogue().is_active(), "and the table closes")
			_set_down(DEAD_TREE_STANDOFF)
			_advance()
	return false


# --- Phase 5: the dead tree ----------------------------------------------------------------


func _phase_dead_tree() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES:
				return false
			_check(
				_quest_state() == &"KEEPSAKE_FOUND",
				"the Fool is set down outside the dead tree's approach with the quest unmoved"
			)
			_start_walk(DEAD_TREE_POSITION)
			_step = 1
		1:
			if _quest_state() == &"KEEPSAKE_FOUND":
				if not _walk_step(ARRIVE_RADIUS):
					return false
				_check(false, "walking in reached the dead tree's approach trigger")
				return _finish()
			_stop_walking()
			_check(
				_quest_state() == &"DEAD_TREE_SEEN",
				"walking into the dead tree's own circle advances MQ00 (state %s)"
					% _quest_state()
			)
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_DEAD_TREE,
				"and starts the Querent on the one thing up here that dies"
			)
			_step = 2
		2:
			if not _walk_conversation_out():
				return false
			_set_down(AMBUSH_STANDOFF)
			_advance()
	return false


# --- Phase 6: the standing stones -----------------------------------------------------------


func _phase_ambush_walk_in() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES:
				return false
			var ambush := _ambush()
			if not check(ambush != null, "the Cliff holds the Waystation ambush"):
				return _fail()
			_check(not ambush.is_engaged(), "which nothing has raised yet")
			# The slider, set before the fight rather than during it.
			_combat().set_perfect_window_bonus_seconds(SLIDER_SECONDS)
			_start_walk(AMBUSH_POSITION)
			_step = 1
		1:
			if not _ambush().is_engaged():
				if not _walk_step(ARRIVE_RADIUS):
					return false
				_check(false, "walking in raised the ambush")
				return _finish()
			_stop_walking()
			var ambush := _ambush()
			_check(
				ambush.standing_count() == 3,
				"walking between the standing stones raises three figures (%d)"
					% ambush.standing_count()
			)
			_check(not ambush.is_cleared(), "and walking in has cleared nothing")
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_WAYSTATION_AMBUSH,
				"the Querent's mid-fight line plays over it"
			)
			_check(
				_quest_state() == &"DEAD_TREE_SEEN",
				"and the quest waits at the dead tree until they are down"
			)
			_step = 2
		2:
			# Said and done with before the swinging starts, so the beat that lands when
			# they fall is not queued behind it.
			if not _walk_conversation_out():
				return false
			_advance()
	return false


# --- Phase 7: the fight -------------------------------------------------------------------


## Three Twos, taken down with the Bindle's own light string, through the `attack_light`
## action - and one dodge timed against a real telegraph, which is Fool's Chance.
##
## The Fool WALKS at whoever is still standing (Cups keeps its distance and lobs, so
## there is a walk to make) and swings when the moveset is free. Nothing here repositions
## a body and nothing throws a hit: `Blank.time_until_hit()` is the one fixture
## affordance, exactly as `tests/enemies_test.gd` uses it, so no beat waits on a clock.
func _phase_the_fight() -> bool:
	var ambush := _ambush()
	# The NEAREST one still standing, not the first: a Cups Blank keeps its distance
	# and lobs (`combat.md` §Enemies), so a Fool who always walked at the first member
	# would spend the fight chasing one suit around while the other two trailed him.
	var target := _nearest_standing(ambush)
	if target == null:
		_stop_walking()
		# The flutter is a timer (`EnemyRules.card_flutter_seconds`), so the cards are
		# waited for rather than asserted on the frame of the last defeat.
		if _flutters < 3 and _phase_frame < _budget() - 1:
			return false
		_check(ambush.is_cleared(), "the three Twos fall and the ambush is cleared")
		_check(
			_flutters == 3,
			"and every one of their cards flutters free (%d) - nobody was killed" % _flutters
		)
		_check(_fools_chance_count >= 1, "a dodge timed against a real telegraph was a Fool's Chance")
		_check(_petals_spent >= 1, "and the Fool spent a White Rose petal on the `rose` action")
		_check(_defeats == 0, "without going down (combat.md §Defeat never played)")
		_check(
			_quest_state() == &"AMBUSH_CLEARED",
			"clearing the fight from the dead tree advances MQ00 (state %s)" % _quest_state()
		)
		_set_down(WAYSTATION_STANDOFF)
		_advance()
		return false

	# The White Rose, on its own action, whenever a petal would not be wasted. Three
	# Twos at the placeholder numbers really do put the Fool in trouble, and healing is
	# the answer the kit gives them (`combat.md` §Defense: a petal is a manual heal).
	var combatant := _fool_combatant()
	if combatant != null and combatant.health() <= ROSE_AT_HEALTH:
		if _rose().petals() > 0 and _is_fool_idle():
			_press(InputActions.ROSE)
			return false

	# One perfect dodge. While the Fool has not had one, a melee Blank winding up is
	# worth more than a swing: the Fool STANDS STILL and answers the tell, which is the
	# offer `combat.md` §Encounter philosophy says every telegraph is. `time_until_hit()`
	# is the fixture affordance the press is timed against - never a clock.
	if _fools_chance_count == 0:
		var swinger := _melee_blank_telegraphing(ambush)
		if swinger != null:
			_stop_walking()
			if swinger.time_until_hit() <= PERFECT_DODGE_LEAD and _is_fool_idle():
				_press(InputActions.DODGE)
			return false

	# Walk at whoever is nearest and swing when they are inside the Bindle's reach. The
	# move actions are held almost to contact on purpose: the Fool faces the way he
	# WALKS (`player.gd`), so a Fool who stopped at reach and waited would keep facing
	# wherever the Blank used to be and swing at the air it left.
	var distance := _layer.fool().global_position.distance_to(target.global_position)
	if distance > CONTACT_DISTANCE:
		_walk_at(target.global_position)
	else:
		_stop_walking()
	if distance <= SWING_DISTANCE and _may_swing():
		_press(InputActions.ATTACK_LIGHT)
	return false


# --- Phase 8: the first Waystation -----------------------------------------------------------


func _phase_waystation() -> bool:
	match _step:
		0:
			if _phase_frame < SETTLE_FRAMES:
				return false
			# The Querent's line about where the cleared cards went was queued behind
			# the fight; it plays before the shrine is reached.
			if not _walk_conversation_out():
				return false
			_check(
				_regions().at_waystation_id() == RegionService.UNSET,
				"the Fool is set down outside the shrine's circle"
			)
			_check(
				not _spread().at_waystation(),
				"so the Pocket Spread's loadouts are not offered out here"
			)
			_check(
				_rose().petals() < _rose().max_petals(),
				"and the Rose is short the petal the fight spent (%d of %d)"
					% [_rose().petals(), _rose().max_petals()]
			)
			_start_walk(WAYSTATION_POSITION)
			_step = 1
		1:
			if not _walk_step(INTERACT_RADIUS):
				return false
			_check(
				_regions().at_waystation_id() == RegionIds.WAYSTATION_CLIFF,
				"walking into the shrine's circle puts the Fool at the Waystation"
			)
			_check(
				_spread().at_waystation(),
				"which is what makes loadouts available (progression.md §The Pocket Spread)"
			)
			_press(InputActions.INTERACT)
			_step = 2
		2:
			if _quest_state() == &"AMBUSH_CLEARED":
				return false
			_check(
				_quest_state() == &"RESTED",
				"pressing `interact` at the shrine rests, and advances MQ00 (state %s)"
					% _quest_state()
			)
			_check(
				_rose().petals() == _rose().max_petals(),
				"the White Rose is whole again (%d of %d)"
					% [_rose().petals(), _rose().max_petals()]
			)
			_check(
				_regions().last_waystation_id() == RegionIds.WAYSTATION_CLIFF,
				"and this is where a defeat would wake the Fool"
			)
			_check(
				_regions().has_visited(RegionIds.WAYSTATION_CLIFF),
				"marked visited, which is what fast travel later reads"
			)
			_check(
				_ambush() != null and _ambush().is_cleared(),
				"and the fight cleared on the way up stays cleared through the rest"
			)
			var index := _spread().save_loadout("proof slice")
			_check(
				index == 0,
				"a loadout saves at the Waystation and nowhere else (index %d)" % index
			)
			_check(_spread().loadout_count() == 1, "and the Spread holds it")
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_WAYSTATION_REST,
				"the Querent explains what a Waystation is"
			)
			_step = 3
		3:
			if not _walk_conversation_out():
				return false
			_advance()
	return false


# --- Phase 9: the questions at the edge ---------------------------------------------------------


func _phase_cliff_edge() -> bool:
	match _step:
		0:
			_start_walk(CLIFF_EDGE_POSITION)
			_step = 1
		1:
			if _quest_state() == &"RESTED":
				if not _walk_step(ARRIVE_RADIUS):
					return false
				_check(false, "walking on reached the cliff edge's approach trigger")
				return _finish()
			_stop_walking()
			_check(
				_quest_state() == &"EDGE_REACHED",
				"walking to the lip advances MQ00 (state %s)" % _quest_state()
			)
			_check(
				_dialogue().current_graph_id() == DialogueIds.MQ00_EDGE_QUESTIONS,
				"and opens the Querent's questions"
			)
			_check(
				_shell.dialogue_frame().option_count() == 4,
				"offering the script's four threads (%d)" % _shell.dialogue_frame().option_count()
			)
			_step = 2
		2:
			if not _walk_conversation_out():
				return false
			_asked_them_all(
				PackedStringArray([
					"DLG_MQ00_EDGE_QUESTIONS_Q1",
					"DLG_MQ00_EDGE_QUESTIONS_Q2",
					"DLG_MQ00_EDGE_QUESTIONS_Q3",
					"DLG_MQ00_EDGE_QUESTIONS_Q4",
				]),
				"the Fool asks all four of the questions at the edge"
			)
			_asked_them_all(
				PackedStringArray([
					"DLG_MQ00_EDGE_QUESTIONS_Q1_F1",
					"DLG_MQ00_EDGE_QUESTIONS_Q3_F1",
					"DLG_MQ00_EDGE_QUESTIONS_Q3_F2",
				]),
				"and the three follow-up threads two of them open"
			)
			_advance()
	return false


# --- Phase 10: the leap ---------------------------------------------------------------------------


func _phase_the_leap() -> bool:
	match _step:
		0:
			_check(
				_regions().current_region_id() == RegionIds.CLIFF,
				"the Fool is still standing on the Cliff"
			)
			_start_walk(LEAP_POSITION)
			_step = 1
		1:
			if _regions().current_region_id() == RegionIds.CLIFF:
				if not _walk_step(ARRIVE_RADIUS):
					return false
				_check(false, "walking off the lip took the leap")
				return _finish()
			_stop_walking()
			_check(
				_quest_state() == &"COMPLETE", "stepping off completes MQ00 (state %s)" % _quest_state()
			)
			_check(_quests().is_complete(QuestIds.MQ00), "MQ00 reports itself complete")
			_check(_quests().active_quest_ids().is_empty(), "and is no longer active")
			var fired: Dictionary = _world_state().to_snapshot().get(
				WorldStateService.SNAPSHOT_FIRED, {}
			)
			_check(fired.is_empty(), "MQ00 fired no world-state flag, exactly as its doc says")
			_check(
				_regions().current_region_id() == RegionIds.PRESTIGE,
				"and the leap of faith carries the Fool off the Cliff to the Prestige"
			)
			_step = 2
		2:
			if _phase_frame < SETTLE_FRAMES:
				return false
			var prestige := _layer.region()
			if not check(prestige != null, "a region is standing under the layer"):
				return _fail()
			_check(prestige.region_id == RegionIds.PRESTIGE, "the Prestige is instanced under it")
			_check(not is_instance_valid(_cliff), "and the Cliff was freed, not left running")
			_check_on_marker(prestige, RegionService.LEAP_ARRIVAL)
			_step = 3
		3:
			if not _walk_conversation_out():
				return false
			_advance()
	return false


# --- Phase 11: the stall in the Prestige ---------------------------------------------------------------


## The shop is a definition with no body: the Prestige is a marked greybox with no shop
## node in it, so this goes through `EconomyService.buy()` - the call the node would
## make - and says so in the class doc. What is proved is the economy end to end: a
## price read out of the world rather than stored, a purse that moves, a Bindle that
## carries what was bought, and a deed that moves Renown in two directions at once.
func _phase_the_prestige() -> bool:
	var economy := _economy()
	if not check(economy != null, "the composition root built the economy"):
		return _fail()
	_check(economy.coins() == 0, "the Fool arrives with an empty purse (progression.md)")
	economy.add_coins(COINS_GRANTED, COINS_REASON)
	var price := economy.price_of(ShopIds.SHOP_PRESTIGE, ItemIds.ITEM_POPCORN)
	_check(price > 0, "the Prestige's stall prices its popcorn (%d Coins)" % price)
	_check(
		economy.stock_remaining(ShopIds.SHOP_PRESTIGE, ItemIds.ITEM_POPCORN) > 0,
		"and has some on the shelf"
	)
	_check(economy.buy(ShopIds.SHOP_PRESTIGE, ItemIds.ITEM_POPCORN), "the Fool buys a bag")
	_check(economy.count(ItemIds.ITEM_POPCORN) == 1, "which is in the Bindle")
	_check(
		economy.coins() == COINS_GRANTED - price,
		"and paid for out of the purse (%d left)" % economy.coins()
	)

	# A deed is what moves Renown, and it moves four suits four ways
	# (`progression.md` §Renown - Renown is not a morality meter).
	var cups_before := _world_state().renown(Suit.Id.CUPS)
	var coins_before := _world_state().renown(Suit.Id.COINS)
	_check(economy.record_deed(DeedIds.DEED_SHARP_BARGAIN), "a sharp bargain is recorded as a deed")
	_check(
		_world_state().renown(Suit.Id.COINS) > coins_before,
		"which Coins prizes (%d -> %d)" % [coins_before, _world_state().renown(Suit.Id.COINS)]
	)
	# Cups reads the same bargain as cold (`progression.md` §Renown's own cell), which
	# is the whole point of four opinions and no total - but the ladder has a floor and
	# the Fool starts on it, so a slight down from nothing is nothing. What is asserted
	# is that the deed did NOT move Cups the way it moved Coins.
	_check(
		_world_state().renown(Suit.Id.CUPS) <= cups_before,
		"while Cups, who finds it cold, gains nothing by it (%d -> %d)"
			% [cups_before, _world_state().renown(Suit.Id.CUPS)]
	)
	_check(
		_world_state().renown(Suit.Id.SWORDS) == 0 and _world_state().renown(Suit.Id.WANDS) == 0,
		"and the two suits with no opinion are untouched - Renown is not a morality meter"
	)
	_advance()
	return false


# --- Phase 12: writing the playthrough out ---------------------------------------------------------


func _phase_save() -> bool:
	_before = _snapshot_of_the_playthrough()
	_check(_layer.save_game(SLOT), "the whole playthrough writes to a slot")
	_check(
		_save_service().list_slots().has(SLOT), "and the slot is listed as one this build wrote"
	)
	_advance()
	return false


# --- Phase 13: reading it back ---------------------------------------------------------------------


func _phase_load() -> bool:
	match _step:
		0:
			_check(_layer.load_game(SLOT), "the slot loads back into a freshly built world")
			_step = 1
		1:
			if _phase_frame < SETTLE_FRAMES:
				return false
			var after := _snapshot_of_the_playthrough()
			for key: String in _before:
				_check(
					after.get(key) == _before[key],
					"%s survives the round trip (%s)" % [key, str(after.get(key))]
				)
			var region := _layer.region()
			_check(
				region != null and region.region_id == RegionIds.PRESTIGE,
				"the Prestige is standing under the layer again"
			)
			_check(
				_layer.fool() != null and is_instance_valid(_layer.fool()),
				"and the Fool himself was never rebuilt"
			)
			_save_service().delete_slot(SLOT)
			_clean_up()
			return _finish()
	return false


## Everything about the playthrough that a save file is supposed to carry, as plain
## values, so "identical" is a comparison a reader can check line by line.
func _snapshot_of_the_playthrough() -> Dictionary:
	var found: Dictionary = {
		"region": _regions().current_region_id(),
		"last waystation": _regions().last_waystation_id(),
		"visited waystations": _regions().visited_waystations(),
		"MQ00 state": _quest_state(),
		"MQ00 complete": _quests().is_complete(QuestIds.MQ00),
		"spread loadouts": _spread().loadout_count(),
		"Trumps held": _spread().held_count(),
		"rose petals": _rose().petals(),
		"rose capacity": _rose().max_petals(),
		"coins": _economy().coins(),
		"popcorn carried": _economy().count(ItemIds.ITEM_POPCORN),
		"fired flags": _world_state().unbound_count(),
	}
	for suit: Suit.Id in Suit.ALL:
		found["renown %s" % Suit.name_key(suit)] = _world_state().renown(suit)
	return found


# --- Driving the Fool ----------------------------------------------------------------------------------


## Start a walk. The leg is stepped one frame at a time by `_walk_step()`.
func _start_walk(target: Vector2) -> void:
	_walk_target = target
	_walk_best = INF
	_walk_stall = 0


## One frame of walking toward the current target, on the move actions. True when the
## Fool is inside `arrive_radius` of it.
##
## A leg that stops closing for `WALK_STALL_FRAMES` fails by name: the Cliff has a real
## collision rim and a walk into it would otherwise show up as a phase budget overrun,
## which reads as "something hung" rather than "the Fool is stuck on the boundary".
func _walk_step(arrive_radius: float) -> bool:
	var fool := _layer.fool()
	if fool == null:
		return true
	var distance := fool.global_position.distance_to(_walk_target)
	if distance <= arrive_radius:
		_stop_walking()
		return true
	if distance < _walk_best - 1.0:
		_walk_best = distance
		_walk_stall = 0
	else:
		_walk_stall += 1
		if _walk_stall > WALK_STALL_FRAMES:
			_check(
				false,
				"the walk to %s closed rather than sticking at %s"
					% [str(_walk_target), str(fool.global_position)]
			)
			_finish()
			return true
	_aim(_walk_target - fool.global_position)
	return false


## Point the move actions at a place, with no arrival test. What the fight walks on.
func _walk_at(target: Vector2) -> void:
	var fool := _layer.fool()
	if fool == null:
		return
	_aim(target - fool.global_position)


## Hold whichever of the four move actions point the way, and let the rest up.
func _aim(direction: Vector2) -> void:
	var unit := direction.normalized()
	_set_action(InputActions.MOVE_LEFT, unit.x < -0.25)
	_set_action(InputActions.MOVE_RIGHT, unit.x > 0.25)
	_set_action(InputActions.MOVE_UP, unit.y < -0.25)
	_set_action(InputActions.MOVE_DOWN, unit.y > 0.25)


func _stop_walking() -> void:
	_set_action(InputActions.MOVE_LEFT, false)
	_set_action(InputActions.MOVE_RIGHT, false)
	_set_action(InputActions.MOVE_UP, false)
	_set_action(InputActions.MOVE_DOWN, false)


## Set the Fool - and Pip beside him - down at a stand-off between two beats. See the
## class doc: never inside a trigger, and never in place of a mechanic.
func _set_down(position: Vector2) -> void:
	_stop_walking()
	var fool := _layer.fool()
	if fool != null:
		fool.global_position = position
		fool.velocity = Vector2.ZERO
	var pip := _layer.pip()
	if pip != null:
		pip.global_position = position + PersistentLayer.PIP_OFFSET


# --- Driving the conversation ------------------------------------------------------------------------


## One frame of walking whatever is being said out. True when nothing is on screen.
##
## LINE nodes are advanced by pressing `interact`, which is what `DialogueFrame`
## answers. CHOICE rows are taken through the frame's own `choose()` - there is no
## InputMap action for a row, see the class doc - and each one is counted, so "every
## option was taken" is a number rather than an assumption.
func _walk_conversation_out() -> bool:
	if not _dialogue().is_active():
		return true
	var frame := _shell.dialogue_frame()
	if frame.option_count() > 0:
		var index := _first_unused(frame)
		if index >= 0:
			_remember_choice(frame, index)
			frame.choose(index)
		else:
			frame.leave()
		return false
	_advance_a_line()
	return false


## Press `interact` once, and only once the previous tap has finished being a tap.
func _advance_a_line() -> void:
	if not _release_now.is_empty() or not _release_next.is_empty():
		return
	_press(InputActions.INTERACT)


## The first question the Fool has not asked, or -1 when the table is exhausted.
func _first_unused(frame: DialogueFrame) -> int:
	for index: int in frame.option_count():
		if not frame.is_option_used(index):
			return index
	return -1


## Remember which row was taken, by the text key the script gave it. A follow-up
## thread is a table of its own under the same graph id, so a bare count would say
## seven where the script writes four questions and three follow-ups; the keys say
## which.
func _remember_choice(frame: DialogueFrame, index: int) -> void:
	var button := frame.option_button(index)
	if button != null:
		_picked_keys.append(button.text)


## True when every key was taken. Names the missing one when it was not.
func _asked_them_all(keys: PackedStringArray, description: String) -> void:
	var missing := PackedStringArray()
	for key: String in keys:
		if not _picked_keys.has(key):
			missing.append(key)
	if missing.is_empty():
		_check(true, "%s (%d rows)" % [description, keys.size()])
		return
	_check(false, "%s - never asked %s" % [description, str(missing)])


# --- Reading the fight ---------------------------------------------------------------------------------


## The member of the ambush still on its feet nearest the Fool, or `null` when they
## are all down.
func _nearest_standing(ambush: Encounter) -> Blank:
	if ambush == null or _layer.fool() == null:
		return null
	var nearest: Blank = null
	var nearest_distance := INF
	for member: Blank in ambush.members():
		if member == null or not is_instance_valid(member):
			continue
		if not member.is_awake() or not member.is_alive():
			continue
		var distance := _layer.fool().global_position.distance_to(member.global_position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest = member
	return nearest


## A melee Blank in the middle of its telegraph, or `null`.
##
## Melee only: a Cups lob leaves its thrower's hand and travels, so its hit lands on
## the projectile's schedule and not the thrower's - timing a dodge against the
## THROWER's tell would be timing it against the wrong thing.
func _melee_blank_telegraphing(ambush: Encounter) -> Blank:
	if ambush == null:
		return null
	for member: Blank in ambush.members():
		if member == null or not is_instance_valid(member) or not member.is_alive():
			continue
		if not member.is_awake() or member.brain() == null:
			continue
		if member.brain().stats() == null or member.brain().stats().is_ranged:
			continue
		if member.brain().state() != BlankBrain.State.TELEGRAPH:
			continue
		return member
	return null


## True while the Fool is standing free, so a new action would actually come out.
func _is_fool_idle() -> bool:
	var combat := _fool_combat()
	return combat != null and combat.controller().state() == MovesetController.State.IDLE


## True when a light press right now would actually produce a swing.
##
## Two moments and no others: the Fool standing free, and the RECOVERY tail of a light
## hit that has a hit left in it, which is where `MovesetController._may_chain()` lets
## the string continue. Pressing anywhere else is mashing - and mashing here is not
## merely wasteful, it is destructive: a press during a hit's ACTIVE phase chains
## straight into the next hit and takes the live hit window away with it, so a test
## that held the button down would swing five times and land once. (It did, before
## this; that is what this comment is for.)
func _may_swing() -> bool:
	var combat := _fool_combat()
	if combat == null:
		return false
	var controller := combat.controller()
	if controller.state() == MovesetController.State.IDLE:
		return true
	if controller.phase() != MovesetController.Phase.RECOVERY:
		return false
	return (
		controller.state() == MovesetController.State.LIGHT_1
		or controller.state() == MovesetController.State.LIGHT_2
	)


# --- Signals -------------------------------------------------------------------------------------------


func _on_fools_chance(_real_seconds: float) -> void:
	_fools_chance_count += 1


func _on_rose_used(_restored: int, _petals_left: int) -> void:
	_petals_spent += 1


func _on_fool_defeated(_defeat_count: int, _at_seconds: int) -> void:
	_defeats += 1


func _on_card_fluttered(_suit: int, _rank: int, _from_position: Vector2) -> void:
	_flutters += 1


func _on_earth_found() -> void:
	_digs += 1


# --- Input ----------------------------------------------------------------------------------------------


## Tap an action: pressed now, released two frames on, for the reason
## `tests/combat_test.gd` gives - which frame an edge is seen on depends on the order
## the engine walks the main loop and the nodes in.
##
## `parse_input_event` rather than `action_press`, because it reaches BOTH halves of the
## input surface: the polled state every gameplay script reads AND `_unhandled_input`,
## which is where `DialogueFrame` and `UiShell` listen. It only QUEUES, so it is flushed
## by hand - a headless run's process frames do not line up with the physics frames this
## test steps on (`tests/ui_test.gd`).
func _press(action: StringName) -> void:
	_send(action, true)
	if not _release_next.has(action):
		_release_next.append(action)


## Put an action down and leave it down.
func _hold(action: StringName) -> void:
	if _held.has(action):
		return
	_held.append(action)
	_send(action, true)
	_release_now.erase(action)
	_release_next.erase(action)


## And let it up again.
func _let_go(action: StringName) -> void:
	_held.erase(action)
	_send(action, false)
	_release_now.erase(action)
	_release_next.erase(action)


## Hold or release an action to match a wanted state, without re-stamping a hold that
## is already down (which would make `is_action_just_pressed` true every frame).
func _set_action(action: StringName, wanted: bool) -> void:
	if wanted == _held.has(action):
		return
	if wanted:
		_hold(action)
	else:
		_let_go(action)


## Retire the taps whose two frames are up, before anything else this frame.
func _release_taps() -> void:
	for action: StringName in _release_now:
		_send(action, false)
	_release_now = _release_next
	_release_next = []


func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


# --- The composition root ---------------------------------------------------------------------------------


## A node lookup rather than the bare `Services` global: `run_all.sh`'s lint stage loads
## every script with `--check-only`, a pure static parse that never runs the SceneTree
## bootstrap that wires an autoload's name into the language as a global identifier.
func _service(field: StringName) -> Object:
	var services := root.get_node_or_null("Services")
	if services == null:
		return null
	return services.get(field)


func _quests() -> QuestService:
	return _service(&"quests") as QuestService


func _dialogue() -> DialogueService:
	return _service(&"dialogue") as DialogueService


func _regions() -> RegionService:
	return _service(&"regions") as RegionService


func _rose() -> WhiteRoseService:
	return _service(&"rose") as WhiteRoseService


func _spread() -> PocketSpreadService:
	return _service(&"spread") as PocketSpreadService


func _combat() -> CombatService:
	return _service(&"combat") as CombatService


func _enemies() -> EnemyService:
	return _service(&"enemies") as EnemyService


func _economy() -> EconomyService:
	return _service(&"economy") as EconomyService


func _world_state() -> WorldStateService:
	return _service(&"world_state") as WorldStateService


func _save_service() -> SaveService:
	return _service(&"save") as SaveService


func _pip_service() -> PipService:
	return _service(&"pip") as PipService


func _quest_state() -> StringName:
	var quests := _quests()
	return &"<no runner>" if quests == null else quests.state_of(QuestIds.MQ00)


# --- The scene ---------------------------------------------------------------------------------------------


func _fool_combat() -> FoolCombat:
	return _layer.get_node_or_null(PersistentLayer.FOOL_COMBAT) as FoolCombat


func _fool_combatant() -> Combatant:
	var combat := _fool_combat()
	return null if combat == null else combat.combatant()


func _companion() -> PipCompanion:
	return _layer.get_node_or_null(PersistentLayer.PIP_COMPANION) as PipCompanion


func _seek_radius() -> float:
	var service := _pip_service()
	return 0.0 if service == null else service.command_radius(PipCommand.Id.SEEK)


func _earth() -> Seekable:
	if _cliff == null or not is_instance_valid(_cliff):
		return null
	return _cliff.get_node_or_null("World/Seekables/DisturbedEarth") as Seekable


func _ambush() -> Encounter:
	if _cliff == null or not is_instance_valid(_cliff):
		return null
	return _cliff.get_node_or_null("World/Encounters/WaystationAmbush") as Encounter


## The Fool stands on a marker, and Pip a step to the side of it.
func _check_on_marker(region: RegionScene, arrival: StringName) -> void:
	var marker := region.marker(arrival)
	if marker == null:
		_check(false, "the Prestige carries a %s marker" % arrival)
		return
	var fool := _layer.fool()
	var pip := _layer.pip()
	var fool_distance := 0.0 if fool == null else fool.global_position.distance_to(
		marker.global_position
	)
	_check(fool_distance <= 1.0, "the Fool lands on the crossroads marker (%.1f px off)" % fool_distance)
	var pip_distance := 0.0 if pip == null else pip.global_position.distance_to(
		marker.global_position
	)
	_check(
		pip_distance <= PersistentLayer.PIP_OFFSET.length() + 1.0,
		"with Pip already beside him (%.1f px)" % pip_distance
	)


# --- Plumbing -------------------------------------------------------------------------------------------------


func _budget() -> int:
	return int(PHASE_BUDGETS.get(_phase, DEFAULT_PHASE_BUDGET))


func _phase_name() -> String:
	if _phase < 0 or _phase >= PHASE_NAMES.size():
		return "phase %d" % _phase
	return PHASE_NAMES[_phase]


func _advance() -> void:
	_timeline.append("%-16s %4d frames" % [_phase_name(), _phase_frame])
	_phase += 1
	_phase_frame = 0
	_step = 0


## Take the scratch files away again, and stop redirecting the shell.
func _clean_up() -> void:
	UiSettings.settings_path_override = ""
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
	var settings_dir := SETTINGS_PATH.get_base_dir()
	if DirAccess.dir_exists_absolute(settings_dir):
		DirAccess.remove_absolute(settings_dir)
	if DirAccess.dir_exists_absolute(SAVES_DIR):
		DirAccess.remove_absolute(SAVES_DIR)


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
	return _finish()


func _finish() -> bool:
	if _finished:
		return true
	_finished = true
	Engine.time_scale = 1.0
	_timeline.append("%-16s %4d frames" % [_phase_name(), _phase_frame])
	print("--- playthrough timeline (%d physics frames total)" % _frame)
	for line: String in _timeline:
		print("    " + line)
	print(
		"--- the fight: %d cards fluttered, %d Fool's Chance, %d petals spent, %d defeats"
			% [_flutters, _fools_chance_count, _petals_spent, _defeats]
	)
	if _all_passed:
		print("PLAYTHROUGH TEST: PASS")
		quit(0)
	else:
		print("PLAYTHROUGH TEST: FAIL")
		quit(1)
	return true
