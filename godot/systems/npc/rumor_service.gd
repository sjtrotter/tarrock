class_name RumorService
extends RefCounted

## News travelling: which completed main quests the world has heard about, and where it
## has got to.
##
## `docs/design/npc-system.md` §"The world talks about you" is canon and this is the
## whole of it: "Deeds don't announce themselves only where they happened. Completing a
## main quest seeds a rumour bark pool that spreads outward on a delay, so news reads as
## *traveling* rather than teleporting" - adjacent regions after a short in-game-time
## delay, world-wide after a longer one, "phrased through that region's own suit-culture
## voice", and "Rumor lines slot into **layer 3**... they are not a separate layer, just
## a delayed-activation delta on the same mechanism."
##
## So this service holds no lines and picks nothing. It answers one question -
## `has_reached(quest_id, region_id)` - and `BarkService` uses that answer as one more
## condition on a layer-3 bark. The suit-culture phrasing is not this service's either:
## a region hears the news in the voice of whoever says it, which is the bark's own
## `suit` condition doing the work it already does.
##
## **The delay is measured against the clock, never the wall.** A seed records the
## `GameClock` reading at the moment the quest completed, and eligibility is that
## reading plus a delay compared to the clock now. In-game time is what the doc asks
## for ("hours, not seconds - long enough that a player who fast-travels immediately
## still beats the news") and it is also the only honest measure: `GameClock` stops for
## menus and stretches under `Engine.time_scale`, and news that travelled while the game
## was paused would be news that travelled while nobody was playing.
##
## **`QuestService` is held WEAKLY**, for the reason `EconomyService` holds
## `RegionService` weakly: the save captures this service and `QuestService` would close
## a `RefCounted` cycle nothing collects, which Godot reports at exit as `ERROR: N
## resources still in use` and which fails the whole test stage.

## A completed main quest was heard of for the first time - the seed was planted.
## Carries the clock reading it was planted at.
signal rumor_seeded(quest_id: StringName, at_seconds: float)

## The keys of the save file's `npc` section. Spelled once here, because this service
## owns that section's contract exactly as `EconomyService` owns `inventory`'s.
const SNAPSHOT_RUMORS := "rumors"
const SNAPSHOT_RUMOR_QUEST := "quest_id"
const SNAPSHOT_RUMOR_AT := "completed_at_seconds"

var _rules: NpcRules = null
var _quests_catalog: QuestCatalog = null
var _graph: RegionGraph = null
var _clock: GameClock = null

## `quest id -> the clock reading it completed at`. Append-only: a quest completes once
## and news, once out, is out.
var _seeds: Dictionary = {}

## The quest service this is listening to, weakly. See the class doc.
var _quests: WeakRef = null

## False from the first seed - or the first successful load - onward. The same
## fresh-only contract every other snapshotting service keeps.
var _pristine: bool = true


## Build the service over the tuning table, the quest catalog and the map.
##
## `quests_catalog` answers "is this a MAIN quest" and "which region is it about"; the
## doc seeds rumours from main-quest completion only, and spreads them from "the quest's
## home region". `graph` is the adjacency `world.md` §Layout draws and round 10
## authored - the doc's own "per `world.md` §Layout's adjacency" - and it is the
## RESOURCE rather than `RegionService`, so nothing here can reach the save that holds
## this service.
func _init(
	rules: NpcRules,
	quests_catalog: QuestCatalog = null,
	graph: RegionGraph = null,
	clock: GameClock = null
) -> void:
	_rules = rules
	_quests_catalog = quests_catalog
	_graph = graph
	_clock = clock


## Listen for main quests completing, so their news starts travelling.
##
## Called by the composition root once `QuestService` exists. The subscription lives
## here rather than in `Services` because what a completion means to a rumour is this
## service's business and the composition root's job is only the introduction.
func attach_quests(quests: QuestService) -> void:
	var attached := attached_quests()
	if attached == quests:
		return
	if attached != null and attached.quest_completed.is_connected(_on_quest_completed):
		attached.quest_completed.disconnect(_on_quest_completed)
	_quests = null if quests == null else weakref(quests)
	if quests != null and not quests.quest_completed.is_connected(_on_quest_completed):
		quests.quest_completed.connect(_on_quest_completed)


## The quest service this is listening to, or `null`. Weakly held: see `_quests`.
func attached_quests() -> QuestService:
	if _quests == null:
		return null
	return _quests.get_ref() as QuestService


## Plant the seed for a completed main quest. True only the first time.
##
## Public so a test - and a quest runner that is not wired through the signal - can say
## so directly. A quest the catalog does not call MAIN seeds nothing: §"The world talks
## about you" spreads main-quest completions and nothing else, and a side quest whose
## news crossed the Spread would be the world over-reacting.
##
## NAMED `seed_rumor` AND NOT `seed`: `seed(base: int)` is a `@GlobalScope` global
## function (the deterministic-RNG one), and a member method of the same name does not
## shadow it cleanly - `godot --check-only` refuses the call at the bottom of this file
## with "Invalid argument for 'seed()' function: argument 1 should be 'int' but is
## 'StringName'", resolving to the builtin instead of this method. A 4.7 surprise, not a
## design choice.
func seed_rumor(quest_id: StringName) -> bool:
	if quest_id == &"":
		return false
	if _seeds.has(quest_id):
		return false
	if _quests_catalog != null:
		var definition := _quests_catalog.find(quest_id)
		if definition == null or not definition.is_main():
			return false
	var at := 0.0 if _clock == null else _clock.elapsed_seconds
	_pristine = false
	_seeds[quest_id] = at
	rumor_seeded.emit(quest_id, at)
	return true


## True when this quest's news has been heard of at all.
func is_seeded(quest_id: StringName) -> bool:
	return _seeds.has(quest_id)


## The clock reading this quest completed at, or -1.0 when it has not.
func seeded_at(quest_id: StringName) -> float:
	return _seeds.get(quest_id, -1.0)


## Every quest whose news is travelling, in the order it was seeded.
func seeded_quests() -> Array[StringName]:
	var found: Array[StringName] = []
	for quest_id: StringName in _seeds:
		found.append(quest_id)
	return found


## The region the news starts in: the quest's own. `&""` when the catalog has no
## opinion, which makes every other region "not adjacent" and leaves only the long delay.
func home_region_of(quest_id: StringName) -> StringName:
	if _quests_catalog == null:
		return &""
	var definition := _quests_catalog.find(quest_id)
	return &"" if definition == null else definition.region_id


## How long this region has to wait, in seconds of in-game time, before it hears.
##
## Three answers, and they are the doc's three: the region it happened in knows at once,
## the regions bordering it wait the short delay, everywhere else waits the long one.
func delay_for(quest_id: StringName, region_id: StringName) -> float:
	if _rules == null:
		return 0.0
	var home := home_region_of(quest_id)
	if home != &"" and home == region_id:
		return 0.0
	var adjacent := _graph != null and home != &"" and _graph.is_adjacent(home, region_id)
	return _rules.rumor_delay_seconds(adjacent)


## True when this region has heard about this quest yet.
##
## The one question `BarkService` asks. False for a quest nobody has completed, and
## false in a region the news has not reached: both are "there is no rumour to tell
## here", which is the same silence from a bark's point of view.
func has_reached(quest_id: StringName, region_id: StringName) -> bool:
	if not _seeds.has(quest_id):
		return false
	var now := 0.0 if _clock == null else _clock.elapsed_seconds
	var since: float = now - float(_seeds[quest_id])
	return since >= delay_for(quest_id, region_id)


# --- Save --------------------------------------------------------------------


## The seeds as ids and numbers only: the save file's `npc` section.
##
## Only the completion TIMES are stored, because everything else is derived. Which
## regions have heard is `delay_for()` over the map and the tuning table, and storing it
## would freeze a tuning number into a save file - a rumour delay retuned between builds
## would then be wrong in every existing playthrough, and right in none.
func to_snapshot() -> Dictionary:
	var rumors: Array = []
	for quest_id: StringName in _seeds:
		rumors.append({
			SNAPSHOT_RUMOR_QUEST: String(quest_id),
			SNAPSHOT_RUMOR_AT: float(_seeds[quest_id]),
		})
	return {SNAPSHOT_RUMORS: rumors}


## Load a snapshot, returning every problem it found. Emits nothing.
##
## A fresh service only, all-or-nothing - the same contract `WorldStateService` and
## `EconomyService` keep, and for the same reason: a load is not a reset, and half the
## world's news is not a playthrough.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _pristine:
		errors.append("restore_snapshot needs a fresh rumor service; this one is in play")
		return errors
	var stored: Variant = data.get(SNAPSHOT_RUMORS, [])
	if not (stored is Array):
		errors.append("snapshot field %s is not a list" % SNAPSHOT_RUMORS)
		return errors
	var seeds: Dictionary = {}
	for entry: Variant in stored as Array:
		if not (entry is Dictionary):
			errors.append("a stored rumor is not a dictionary")
			continue
		var row: Dictionary = entry
		var quest_id: Variant = row.get(SNAPSHOT_RUMOR_QUEST)
		var at: Variant = row.get(SNAPSHOT_RUMOR_AT)
		if not (quest_id is String or quest_id is StringName):
			errors.append("a stored rumor names no quest")
			continue
		if not (at is int or at is float):
			errors.append("the rumor of %s was not completed at a time" % str(quest_id))
			continue
		var id := StringName(quest_id)
		if _quests_catalog != null and not _quests_catalog.has(id):
			errors.append("snapshot carries news of %s, which is no quest" % id)
			continue
		if seeds.has(id):
			errors.append("snapshot carries the news of %s twice" % id)
			continue
		seeds[id] = maxf(0.0, float(at))
	if not errors.is_empty():
		return errors
	_seeds = seeds
	_pristine = false
	return errors


## True until this service is first seeded or first loaded into.
func is_pristine() -> bool:
	return _pristine


# --- Internals ---------------------------------------------------------------


func _on_quest_completed(quest_id: StringName) -> void:
	seed_rumor(quest_id)
