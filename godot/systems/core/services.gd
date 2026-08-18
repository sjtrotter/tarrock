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
## Rounds add fields here, in dependency order - see
## docs/gauntlet-systems/PROMPT.md for the full order.

## The generated definitions `world_state` is built over. Generated from the docs by
## `godot/tools/gen_definitions.py`; a drift test fails if they and `docs/` disagree.
const WORLD_STATE_CATALOG_PATH := "res://data/world_states/catalog.tres"
const ACT_THRESHOLDS_PATH := "res://data/world_states/act_thresholds.tres"
const RENOWN_LADDER_PATH := "res://data/progression/renown_ladder.tres"

## The generated quest definitions `quests` is built over. Generated from every
## `docs/quests/**/*.md` frontmatter block by the same tool.
const QUEST_CATALOG_PATH := "res://data/quests/catalog.tres"

## The hand-authored conversations `dialogue` is built over, lifted out of the quest
## scripts a beat at a time (docs/design/technical.md §Generated vs. hand-authored).
const DIALOGUE_CATALOG_PATH := "res://data/dialogue/catalog.tres"

## In-game elapsed time. Paused by menus; advanced here and nowhere else.
var clock: GameClock = null

## The only mutation path for `WS_*` flags, Renown, the Fool's Reading, the Hermit's
## answer, named-NPC memory and quest state. Everything else reads and subscribes.
var world_state: WorldStateService = null

## Versioned JSON saves in `user://saves/`, with the explicit migration chain.
## It captures out of the services above it and applies back into them - which is why
## it is built last and holds them, rather than the other way round.
var save: SaveService = null

## The quest state machines - and the ONLY writer of world state. Scenes, combat and
## dialogue raise events here; this is what turns one into a permanent change.
var quests: QuestService = null

## The conversation runner. It READS world state for its branch conditions and writes
## nothing: an `EVENT` node reaches `quests` only by way of the scene that started
## the conversation, which is why this field sits below `quests` and holds no
## reference to it.
var dialogue: DialogueService = null


func _ready() -> void:
	# Dependency order: each service is handed the ones above it, never looked up.
	clock = GameClock.new()
	world_state = _build_world_state()
	save = SaveService.new(world_state, clock)
	quests = _build_quests()
	dialogue = _build_dialogue()

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


## Load the generated quest definitions and build the runner over them.
##
## Validated on the way in for the same reason the world-state catalog is: a quest
## that names a flag the matrix does not define, or a graph that can never finish,
## is a content bug worth a loud error at boot rather than a quest that silently
## never completes. The world-state catalog is passed so the cross-references can be
## checked at all.
func _build_quests() -> QuestService:
	var catalog: QuestCatalog = load(QUEST_CATALOG_PATH) as QuestCatalog
	var world_states: WorldStateCatalog = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	if catalog != null:
		for problem: String in catalog.validate(world_states):
			push_error(problem)
	return QuestService.new(world_state, catalog)


## Load the authored dialogue graphs and build the runner over them.
##
## Validated on the way in for the same reason the other catalogs are, and with one
## extra question only this call can ask: `QuestEvents.ALL` is passed, so a graph
## that raises an event id nobody defined is a loud error at boot rather than a line
## of dialogue that silently changes nothing (`QuestService.raise()` ignores an
## unknown event by design).
func _build_dialogue() -> DialogueService:
	var catalog: DialogueCatalog = load(DIALOGUE_CATALOG_PATH) as DialogueCatalog
	if catalog != null:
		for problem: String in catalog.validate(QuestEvents.ALL):
			push_error(problem)
	return DialogueService.new(world_state, catalog)
