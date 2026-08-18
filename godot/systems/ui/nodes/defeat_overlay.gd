class_name DefeatOverlay
extends ColorRect

## Being put down, and getting back up: a gentle fade, and nothing else.
##
## `docs/design/combat.md` §Defeat is emphatic that this beat is warm rather than
## punishing - the Fool falls, **Pip licks his face**, and the Fool wakes at the last
## Waystation rested at. `systems/regions/README.md` and `CombatService` already own
## every mechanical part of that; this overlay owns only the picture, and it owns as
## little of it as it can:
##
##   * no desaturation, no red vignette, no "YOU DIED" - none of which any doc asks for
##     and all of which would say the wrong thing about a game where nothing dies;
##   * the fade waits for `PipCompanion.licked`, so the lick is seen and not fought
##     over. If no dog is attached it fades on its own after the same beat, because a
##     Fool who went down without Pip must still wake up.
##
## **The Querent's remark is NOT here, and no line is invented for it.** Canon gives a
## rotating, low-frequency pool of warm, dry remarks and gives not one of its words, so
## this round ships the graph id the writing lane will author into
## (`DEFEAT_QUERENT_REMARKS`) and plays nothing at all until it exists. Writing a
## Querent line to fill a hole would be inventing canon in a UI script.

## The dialogue graph the writing lane owns. Nothing starts it yet - there is no such
## graph in `res://data/dialogue/` and there must not be a guessed one.
const QUERENT_REMARKS_GRAPH := &"DEFEAT_QUERENT_REMARKS"

## How long the picture holds before it fades, in seconds - room for the lick.
const HOLD_SECONDS := 1.6

## How long the fade down and back up each take.
const FADE_SECONDS := 0.9

var _combat: CombatService = null
var _companion: PipCompanion = null
var _fading: bool = false
var _tween: Tween = null


func _ready() -> void:
	color = Color(UiFrames.GROUND.r, UiFrames.GROUND.g, UiFrames.GROUND.b, 0.0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## Watch this fight, and this dog. Either may be null.
func attach(combat: CombatService, companion: PipCompanion) -> void:
	_disconnect()
	_combat = combat
	_companion = companion
	_connect()


## True while the world is fading out or back in.
func is_fading() -> bool:
	return _fading


## The graph the Querent's remark will be authored into. Nothing plays it yet.
func querent_remarks_graph() -> StringName:
	return QUERENT_REMARKS_GRAPH


## Play the fade now. Called by the defeat signal; public so a test need not wait.
func play() -> void:
	if _fading:
		return
	_fading = true
	visible = true
	if not is_inside_tree():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"color:a", 1.0, FADE_SECONDS)
	_tween.tween_interval(HOLD_SECONDS)
	_tween.tween_property(self, ^"color:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(_finish)


func _connect() -> void:
	if _combat != null:
		_combat.fool_defeated.connect(_on_defeated)
		_combat.fool_revived.connect(_on_revived)
	if _companion != null:
		_companion.licked.connect(_on_licked)


func _disconnect() -> void:
	if _combat != null:
		_drop(_combat.fool_defeated, _on_defeated)
		_drop(_combat.fool_revived, _on_revived)
	if _companion != null:
		_drop(_companion.licked, _on_licked)


## Disconnect one handler if it is connected.
static func _drop(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		source.disconnect(target)


func _on_defeated(_defeat_count: int, _at_seconds: int) -> void:
	# With a dog present the fade waits for the lick; without one it starts here, so a
	# Fool who went down alone is not left lying on the floor.
	if _companion == null:
		play()


func _on_licked() -> void:
	play()


func _on_revived() -> void:
	_finish()


func _finish() -> void:
	_fading = false
	visible = false
	color = Color(UiFrames.GROUND.r, UiFrames.GROUND.g, UiFrames.GROUND.b, 0.0)
