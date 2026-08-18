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
##   ## Round 4 adds `quests: QuestService`
##   ## Round 5 adds `dialogue: DialogueService`
## - see docs/gauntlet-systems/PROMPT.md for the full order.

## The generated definitions `world_state` is built over. Generated from the docs by
## `godot/tools/gen_definitions.py`; a drift test fails if they and `docs/` disagree.
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## In-game elapsed time. Paused by menus; advanced here and nowhere else.
var clock: GameClock = null

## The only mutation path for `WS_*` flags, Renown, the Fool's Reading, the Hermit's
## answer, named-NPC memory and quest state. Everything else reads and subscribes.
var world_state: WorldStateService = null

## Versioned JSON saves in `user://saves/`, with the explicit migration chain.
## It captures out of the services above it and applies back into them - which is why
## it is built last and holds them, rather than the other way round.
var save: SaveService = null


func _ready() -> void:
	# Dependency order: each service is handed the ones above it, never looked up.
	clock = GameClock.new()
	world_state = _build_world_state()
	save = SaveService.new(world_state, clock)

	# The clock ticks on process frames, not physics: one tick per rendered frame,
	# independent of the physics tick rate. The delta handed over is the engine's,
	# so `Engine.time_scale` scales in-game time along with everything else it
	# slows down - that is the contract, see `GameClock`'s class doc.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if clock != null:
		clock.advance(delta)


## Load the generated world-state definitions and build the service over them.
##
## The catalog is validated on the way in: a bad row here would mean the game
## disagrees with `docs/design/world.md` about what the world can remember, which is
## worth a loud error at boot rather than a wrong answer three hours in.
func _build_world_state() -> WorldStateService:
	var catalog: WorldStateCatalog = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	var thresholds: ActThresholds = load(ACT_THRESHOLDS_PATH) as ActThresholds
	var ladder: RenownLadder = load(RENOWN_LADDER_PATH) as RenownLadder
	if catalog != null:
		for problem: String in catalog.validate():
			push_error(problem)
	if thresholds != null:
		for problem: String in thresholds.validate():
			push_error(problem)
	if ladder != null:
		for problem: String in ladder.validate():
			push_error(problem)
	return WorldStateService.new(catalog, thresholds, ladder)
