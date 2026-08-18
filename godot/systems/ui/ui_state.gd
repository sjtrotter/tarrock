class_name UiState
extends RefCounted

## Which full-screen menus are open, and what that means for the world underneath.
##
## `GameClock`'s own class doc fixes the rule this enforces: "Time does not pass while
## `paused` is true - menus, dialogue, and the Pocket Spread all stop the clock, so
## 'in-game seconds' means seconds of play." So the shell does not each-decide; it
## opens and closes screens through here, and the clock follows.
##
## Dialogue is deliberately NOT a menu. `docs/design/art-audio.md` §UI/UX pillars:
## conversational framing is "an easing zoom into the shared space between the
## participants ... No hard lock: the player keeps control". A conversation frames the
## camera; it does not pause the world and it does not take the sticks away.

## A screen opened or closed; `open_count` is how many are up afterwards.
signal menu_changed(screen: StringName, open: bool, open_count: int)

var _open: Dictionary = {}
var _clock: GameClock = null


func _init(clock: GameClock = null) -> void:
	_clock = clock


## Watch this clock from now on. Handed the composition root's clock by the shell,
## again after every rebuild.
func attach_clock(clock: GameClock) -> void:
	_clock = clock
	_sync_clock()


## True while any menu is up.
func any_menu_open() -> bool:
	return not _open.is_empty()


## How many menus are up.
func open_count() -> int:
	return _open.size()


## True while this particular screen is up.
func is_open(screen: StringName) -> bool:
	return _open.has(screen)


## Record a screen as open or closed, and pause or unpause the clock to match.
func set_open(screen: StringName, open: bool) -> void:
	var was := _open.has(screen)
	if open == was:
		return
	if open:
		_open[screen] = true
	else:
		_open.erase(screen)
	_sync_clock()
	menu_changed.emit(screen, open, _open.size())


## Close everything. Used when a playthrough is thrown away and rebuilt.
func close_all() -> void:
	for screen: StringName in _open.keys():
		set_open(screen, false)


func _sync_clock() -> void:
	if _clock != null:
		_clock.paused = not _open.is_empty()
