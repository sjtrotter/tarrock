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
##
## **A playthrough is a set of services, and starting one throws the old set away.**
## `new_game()` and `load_game()` call `rebuild()`, which constructs every service
## again from scratch. That is not tidiness: `SaveService.apply()` refuses to load
## into a world that has already been played (a fired flag can never be un-fired), so
## the only honest way to load from a title screen is to build a fresh world and fill
## it. The old services are dropped, and everything connected to them - their signals
## included - goes with them.
##
## **A world nobody has played is not thrown away, though**, and that is the same rule
## read the other way. `_ready()` builds the services once; the boot's `new_game()`
## then finds a world where nothing has fired, nothing has been asked and no quest has
## moved, and plays in it rather than building a second one a millisecond later and
## dropping the first. The question asked is `WorldStateService.is_pristine()` - the
## very question `apply()` asks - so "may this playthrough reuse these services" and
## "may a save be loaded into them" can never drift apart. Every boot therefore loads
## and validates the generated catalogs exactly ONCE, which is the whole cost being
## saved; every later new game or load is a fresh world, as before.
##
## THE REATTACH LIST. Two things outlive a rebuild, because they live in the
## persistent layer rather than in a region scene: the Fool and Pip. Their components
## hold a service reference each and must be handed the new one, or a new game would
## be played by a Fool still reporting into the previous playthrough's fight:
##
##   * `Fool/FoolCombat.attach_service(combat)` - and through it the Fool's
##     `Combatant` re-registers with the new `CombatService`;
##   * `Pip/PipCompanion.attach_service(pip)`;
##   * anything a later round adds to the layer with an `attach_*` of its own.
##
## `rebuilt` is emitted for exactly that, and `PersistentLayer` is what listens: this
## node knows the services, the layer knows the nodes, and neither reaches into the
## other's half (`docs/design/technical.md` §Architecture principles (Godot), 5).

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

## The generated Trumps `spread` is built over, one per `**Trump N - Name.**` block
## in `docs/design/arcana.md`, and the hand-authored numbers the Spread, Fortune and
## the White Rose all run on (`docs/design/progression.md`).
const TRUMP_CATALOG_PATH := "res://data/trumps/catalog.tres"
const SPREAD_RULES_PATH := "res://data/progression/spread_rules.tres"

## The hand-authored numbers the Bindle moveset, the dodges, Fool's Chance, the
## difficulty modes and the defeat loop run on (`docs/design/combat.md`).
const COMBAT_RULES_PATH := "res://data/combat/combat_rules.tres"

## The generated enemies `enemies` is built over - one per suit x rank from
## `docs/design/combat.md` §Enemies, plus the two other-family stubs - and the
## hand-authored numbers every one of them runs on. The definitions hold no figures
## because the doc holds none; the rules table is the one tuning place.
const ENEMY_CATALOG_PATH := "res://data/enemies/catalog.tres"
const ENEMY_RULES_PATH := "res://data/enemies/enemy_rules.tres"

## The hand-authored numbers Pip's command wheel, his three commands and his retreat
## run on (`docs/design/combat.md` §Pip).
const PIP_RULES_PATH := "res://data/pip/pip_rules.tres"

## The generated regions `regions` is built over - one per `docs/design/world.md`
## §Regions bullet - and the HAND-AUTHORED adjacency, which is a reading of that
## doc's §Layout diagram rather than a table anything could generate
## (`RegionGraph`).
const REGION_CATALOG_PATH := "res://data/regions/catalog.tres"
const REGION_GRAPH_PATH := "res://data/regions/region_graph.tres"

## The first quest of the game, started by `new_game()` and by nothing else, and the
## conversation that plays over the black screen before the Cliff is drawn
## (`docs/quests/main/MQ00-the-leap.md`).
const FIRST_QUEST := QuestIds.MQ00
const FIRST_DIALOGUE := DialogueIds.MQ00_WAKE

## Where a new playthrough begins: the Cliff, on its own spawn marker.
## `docs/design/world.md` §The Cliff - the tutorial plateau outside the Spread.
const FIRST_REGION := RegionIds.CLIFF

## Every service was thrown away and built again: a new game, or a load. Whoever holds
## a service reference across it re-reads its field (see THE REATTACH LIST above).
signal rebuilt()

## In-game elapsed time. Paused by menus; advanced here and nowhere else.
var clock: GameClock = null

## The only mutation path for `WS_*` flags, Renown, the Fool's Reading, the Hermit's
## answer, named-NPC memory and quest state. Everything else reads and subscribes.
var world_state: WorldStateService = null

## The Fortune meter: the one resource a Present-slot Trump spends. Built before the
## Spread because the Spread pays for its casts out of it.
var fortune: FortuneService = null

## The Fool's three cards. Which Trumps are held is DERIVED from `world_state`, so
## this service reads it and writes nothing back.
var spread: PocketSpreadService = null

## The White Rose: healing charges, and the region rule that decides where they come
## back. Reads `world_state` to know which regions are awake.
var rose: WhiteRoseService = null

## The fight: Fool's Chance and the time scale it slows the world by, the Fortune a
## fight earns, the White Rose's heals, the difficulty modes, and the defeat loop.
## Built after the three above because it spends into all of them and owns none of
## their numbers.
var combat: CombatService = null

## The enemy roster: the generated catalog, the one tuning table, who is standing
## right now, and the card that flutters free when one goes down. Built after
## `combat` because a fight is `CombatService`'s and this is only who is in it.
var enemies: EnemyService = null

## Pip: the command wheel (Fetch / Harry / Seek), and the retreat that is not a death.
## Built after `combat` because a retreat runs away from whoever is engaged in the
## fight, and because the defeat beat (`combat.md` §Defeat, 2) hangs on the fight's
## own `fool_defeated`.
var pip: PipService = null

## Where the Fool is, where they may go, what a Waystation does, and the one service
## allowed to load or free a region scene. Built after `save`, which is where the
## Fool's position actually lives, and after `combat`, whose `fool_defeated` closes
## the defeat loop back onto the last Waystation rested at.
var regions: RegionService = null

## Versioned JSON saves in `user://saves/`, with the explicit migration chain.
## It captures out of the services above it and applies back into them - which is why
## it is built last and holds them, rather than the other way round.
var save: SaveService = null

## The swapper the persistent layer registered, kept across a rebuild because the
## layer is not rebuilt with the services under it.
var _region_swapper: RegionSwapper = null

## Where saves are read and written. A field rather than the constant so a test can
## point a whole composition root at a scratch directory.
var _saves_dir: String = SaveService.DEFAULT_SAVES_DIR


## The quest state machines - and the ONLY writer of world state. Scenes, combat and
## dialogue raise events here; this is what turns one into a permanent change.
var quests: QuestService = null

## The conversation runner. It READS world state for its branch conditions and writes
## nothing: an `EVENT` node reaches `quests` only by way of the scene that started
## the conversation, which is why this field sits below `quests` and holds no
## reference to it.
var dialogue: DialogueService = null


func _ready() -> void:
	rebuild()

	# The clock ticks on process frames, not physics: one tick per rendered frame,
	# independent of the physics tick rate. The delta handed over is the engine's,
	# so `Engine.time_scale` scales in-game time along with everything else it
	# slows down - that is the contract, see `GameClock`'s class doc.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Build - or rebuild - every service, in dependency order.
##
## Called once at boot and again for every new game and every load that finds a world
## somebody has already played in; see the class doc for why such a world cannot be
## reused, and `rebuild_if_played()` for the question. Emits `rebuilt` at the end,
## which is the persistent layer's cue to re-attach the Fool and Pip (THE REATTACH
## LIST).
func rebuild() -> void:
	# Dependency order: each service is handed the ones above it, never looked up.
	clock = GameClock.new()
	world_state = _build_world_state()
	var rules := _load_spread_rules()
	fortune = FortuneService.new(rules)
	spread = _build_spread(rules)
	rose = WhiteRoseService.new(world_state, rules)
	combat = CombatService.new(_load_combat_rules(), fortune, spread, rose, clock)
	enemies = _build_enemies(combat.rules())
	pip = PipService.new(_load_pip_rules(), combat)
	save = SaveService.new(world_state, clock, _saves_dir, null, spread, fortune, rose)
	# The chosen difficulty is save data (`SaveModel.difficulty_mode`), so combat is
	# told once the save service exists to be asked. A settings screen that changes it
	# mid-play calls `combat.set_difficulty()` itself - that wiring is the UI round's,
	# and `SaveService` has no signal to hang it on today.
	combat.set_difficulty(save.difficulty())
	quests = _build_quests()
	dialogue = _build_dialogue()
	regions = _build_regions()
	# The layer registered its swapper before any of this was rebuilt, and it is the
	# same layer either way: the scene above the services outlives the services.
	regions.set_swapper(_region_swapper)
	rebuilt.emit()


func _process(delta: float) -> void:
	if clock != null:
		clock.advance(delta)
	# Fool's Chance is measured in REAL seconds while the world it happens in is
	# slowed, so the service is handed the same already-scaled delta the clock gets
	# and divides the scale back out itself (see `CombatService.tick`).
	if combat != null:
		combat.tick(delta)


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


## Load the hand-authored tuning numbers the progression services share.
##
## Validated on the way in for the same reason the catalogs are: a Spread whose
## Future slot opened before its Past, or a White Rose capped below its own starting
## petals, is a rule that disagrees with `docs/design/progression.md` and is worth a
## loud error at boot rather than a strange playthrough.
func _load_spread_rules() -> SpreadRules:
	var rules: SpreadRules = load(SPREAD_RULES_PATH) as SpreadRules
	if rules != null:
		for problem: String in rules.validate():
			push_error(problem)
	return rules


## Load the hand-authored combat numbers.
##
## Validated on the way in for the same reason the rest are: a rules table whose
## i-frames close before they open, or whose perfect window is wider than the i-frames
## it has to fall inside, is a kit that cannot be played as `docs/design/combat.md`
## describes it, and that is worth a loud error at boot rather than a dodge that never
## triggers Fool's Chance.
func _load_combat_rules() -> CombatRules:
	var rules: CombatRules = load(COMBAT_RULES_PATH) as CombatRules
	if rules != null:
		for problem: String in rules.validate():
			push_error(problem)
	return rules


## Load the hand-authored numbers Pip runs on.
##
## Validated on the way in for the same reason the rest are: a table that harried an
## enemy into telegraphing FASTER, or that returned Pip from a retreat instantly, would
## be a Pip who disagrees with `docs/design/combat.md` §Pip, and that is worth a loud
## error at boot rather than a command wheel that quietly does the wrong thing.
func _load_pip_rules() -> PipRules:
	var rules: PipRules = load(PIP_RULES_PATH) as PipRules
	if rules != null:
		for problem: String in rules.validate():
			push_error(problem)
	return rules


## Load the generated enemies and the hand-authored numbers, and build the roster.
##
## Validated on the way in for the same reason the other catalogs are, and with two
## cross-references only this call can make: the world-state catalog resolves the two
## flags `combat.md` §Other enemy families names (a Beast calmed by a flag the matrix
## does not define would be a Beast nothing ever calms), and the combat rules let the
## enemy rules check that no telegraph falls under `EnemyRules.MIN_TELEGRAPH_SECONDS`
## on the tightest difficulty - "an enemy that hits without a tell is a bug".
func _build_enemies(combat_rules: CombatRules) -> EnemyService:
	var catalog: EnemyCatalog = load(ENEMY_CATALOG_PATH) as EnemyCatalog
	var rules: EnemyRules = load(ENEMY_RULES_PATH) as EnemyRules
	var world_states: WorldStateCatalog = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	if catalog != null:
		for problem: String in catalog.validate(world_states):
			push_error(problem)
	if rules != null:
		for problem: String in rules.validate_against(combat_rules):
			push_error(problem)
	return EnemyService.new(catalog, rules)


## Load the generated Trumps and build the Pocket Spread over them.
##
## The world-state catalog is passed to `validate()` so the one cross-reference only
## it can check is checked: every Trump is granted by the UNBINDING flag of its own
## card. A Trump wired to the wrong Arcana's flag would be a card handed over by the
## wrong person, and nothing else in the game would notice.
func _build_spread(rules: SpreadRules) -> PocketSpreadService:
	var catalog: TrumpCatalog = load(TRUMP_CATALOG_PATH) as TrumpCatalog
	var world_states: WorldStateCatalog = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	if catalog != null:
		for problem: String in catalog.validate(world_states):
			push_error(problem)
	return PocketSpreadService.new(world_state, catalog, rules, fortune)


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


# --- Starting and loading a playthrough --------------------------------------


## Register the persistent layer's scene swapper. Called once, by the layer.
##
## Held here rather than only on `RegionService`, because the service is thrown away
## and rebuilt for every new game and every load while the layer above it is not:
## this is the one reference that has to survive the rebuild.
func set_region_swapper(swapper: RegionSwapper) -> void:
	_region_swapper = swapper
	if regions != null:
		regions.set_swapper(swapper)


## Where this composition root reads and writes saves.
func saves_dir() -> String:
	return _saves_dir


## Point the whole composition root at another save directory, and rebuild onto it.
## For a test that must not write into the player's saves; never called in play.
func set_saves_dir(directory: String) -> void:
	_saves_dir = directory
	rebuild()


## Build every service again, unless the ones standing are a world nobody has played.
##
## The one question `new_game()` and `load_game()` ask before they start, and it is
## `SaveService.apply()`'s own: a played world can never be un-played (a fired flag
## cannot be un-fired), so it is thrown away and built fresh; a pristine one is exactly
## what a rebuild would have produced, so it is kept, and the boot stops loading and
## validating every generated catalog twice.
##
## True when the services were rebuilt.
func rebuild_if_played() -> bool:
	if world_state != null and world_state.is_pristine():
		return false
	rebuild()
	return true


## Start a new playthrough. True when the Fool is on the Cliff with MQ00 running.
##
## The whole opening of the game, in the order it happens:
##
##   1. every service is built again unless the ones standing are still untouched, so
##      a new game is always played in a world nobody has touched (see the class doc
##      and `rebuild_if_played()`);
##   2. the Fool is placed on the Cliff - `RegionService` asks the layer to instance
##      the region scene, and the layer does it as the frame ends;
##   3. MQ00 starts. This used to be the Cliff scene's own doing, which meant the
##      tutorial region carried the "begin the game" verb; a second region would have
##      inherited the same wiring. It belongs here, where there is one of it.
##   4. the Querent says the first lines. `MQ00_WAKE` plays over a black screen
##      "before the region loads" (`docs/quests/main/MQ00-the-leap.md`), which is why
##      the region never started it and why nothing here waits for it to end.
func new_game() -> bool:
	rebuild_if_played()
	if regions == null or quests == null:
		return false
	if not regions.place_at(FIRST_REGION, RegionService.DEFAULT_ARRIVAL):
		return false
	quests.start(FIRST_QUEST)
	if dialogue != null:
		dialogue.start(FIRST_DIALOGUE)
	return true


## Write the playthrough to a save slot. True when the file is on disk.
##
## The counterpart of `load_game()`, and the reason both live here: capturing a
## playthrough is a question for the composition root, which is what holds every
## service the answer is assembled from. A caller (a save menu, a Waystation, a test)
## names a slot and gets a yes or a no; the diagnostics go to the log, because a save
## that failed to write is not a thing a player can be asked to fix.
func save_game(slot: int) -> bool:
	if save == null:
		return false
	var model := save.capture()
	if model == null:
		return false
	var problems := save.write_slot(slot, model)
	for problem: String in problems:
		push_error(problem)
	return problems.is_empty()


## Load a playthrough from a save slot. True when the world and the Fool are back.
##
## Rebuild, read, apply, then travel: the fresh world `SaveService.apply()` insists on
## is the one standing after `rebuild_if_played()` - either just built, or never played
## in - and the region the file names is where the Fool stood. The arrival is the Waystation they last rested at when the save has
## one - `combat.md` §Defeat's "last Waystation rested at" is also the right place to
## put someone opening the game again - and the region's own spawn marker otherwise.
func load_game(slot: int) -> bool:
	rebuild_if_played()
	if save == null or regions == null:
		return false
	var result := save.read_slot(slot)
	if not result.ok:
		return false
	var problems := save.apply(result.model)
	if not problems.is_empty():
		for problem: String in problems:
			push_error(problem)
		return false
	var region_id := save.current_region_id()
	if region_id == RegionService.UNSET:
		region_id = FIRST_REGION
	var arrival := save.last_waystation_id()
	var target := regions.definition(region_id)
	if arrival == RegionService.UNSET or target == null or not target.has_waystation(arrival):
		arrival = RegionService.DEFAULT_ARRIVAL
	# A placement, not a journey: `apply()` has already told the save where the Fool
	# was standing, so there is nowhere to travel FROM (see `RegionService.place_at`).
	return regions.place_at(region_id, arrival)


## Load the generated regions and the hand-authored adjacency, and build the service.
##
## Validated on the way in for the same reason the other catalogs are, and with the
## cross-references only this call can make: the world-state catalog resolves every
## region's unbinding flag and every gate flag on the graph (a door that waits on a
## flag the matrix never defines is a door that never opens), and the Trump catalog
## resolves the "true light" the Mirrormarsh asks for.
func _build_regions() -> RegionService:
	var catalog: RegionCatalog = load(REGION_CATALOG_PATH) as RegionCatalog
	var graph: RegionGraph = load(REGION_GRAPH_PATH) as RegionGraph
	var world_states: WorldStateCatalog = load(WORLD_STATE_CATALOG_PATH) as WorldStateCatalog
	var trump_catalog: TrumpCatalog = load(TRUMP_CATALOG_PATH) as TrumpCatalog
	if catalog != null:
		for problem: String in catalog.validate(world_states):
			push_error(problem)
	if graph != null:
		for problem: String in graph.validate(catalog, world_states, trump_catalog):
			push_error(problem)
	return RegionService.new(catalog, graph, world_state, save, rose, spread, combat)


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
