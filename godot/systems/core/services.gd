extends Node

## The composition root: the ONE autoload in Tarrock.
##
## It constructs the game's services in dependency order in `_ready()` and holds
## them as typed fields. Scenes reach into `Services`; services never reach into
## scenes. There is deliberately NO `register(name)` / `get_service(name)` string
## locator: every service is a named, typed field, so a typo is a parse error and
## the dependency order is readable top to bottom.
##
## Services are plain `RefCounted`s, constructible without a tree, so tests build
## them directly and only integration tests need this node at all
## (see `res://tests/README.md`).
##
## Rounds add fields here, in dependency order:
##   ## Round 2 adds `world_state: WorldStateService` (the only mutation path for WS_* flags)
##   ## Round 3 adds `save_service: SaveService` (versioned JSON, explicit migrations)
##   ## Round 4 adds `quests: QuestService`
##   ## Round 5 adds `dialogue: DialogueService`
## - see docs/gauntlet-systems/PROMPT.md for the full order.

## In-game elapsed time. Paused by menus; advanced here and nowhere else.
var clock: GameClock = null


func _ready() -> void:
	# Dependency order: each service is handed the ones above it, never looked up.
	clock = GameClock.new()

	# The clock ticks on process frames, not physics: one tick per rendered frame,
	# independent of the physics tick rate. The delta handed over is the engine's,
	# so `Engine.time_scale` scales in-game time along with everything else it
	# slows down - that is the contract, see `GameClock`'s class doc.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if clock != null:
		clock.advance(delta)
