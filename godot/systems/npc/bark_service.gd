class_name BarkService
extends RefCounted

## The seven-layer bark selector: the whole of `docs/design/npc-system.md` §Bark layers,
## and the service the NPC round is for.
##
## §The pillar is the reason this exists: "**NPCs are aware.** Wherever possible, an NPC
## line should reflect the current state of the world - what has been unbound, in what
## order, what the player chose, who the player is to this suit. A canned line that
## ignores a transformed world... is a **bug**, not flavor". And the second half of that
## section is the reason it is layered rather than bespoke: "This doc exists to make
## that pillar affordable: a layered bark system that lets writers aim specificity at the
## moments that earn it, and fall back gracefully everywhere else."
##
## THE SELECTION ALGORITHM, VERBATIM: "A bark request... is resolved against seven
## pools, evaluated **most-specific-first**. The highest layer that still has an unspent
## line for this NPC/context wins; if it's exhausted, evaluation falls through to the
## next layer down. This is the entire selection algorithm - **no weighting, no
## randomness across layers**, so writers can always predict which layer a given moment
## will draw from."
##
## Read that carefully, because it says two different things about randomness. There is
## none ACROSS layers - layer 3 having one eligible line means layer 7 is never asked,
## full stop. WITHIN a layer there has to be some, or a pool of ten lines would be a
## pool of one; so the choice among a layer's eligible, non-recent lines is made by a
## SEEDED rng this service owns, which makes it reproducible for tests and unpredictable
## for players. Seed it identically and it answers identically, forever.
##
## **Repeats decay, per pool key.** §Bark layers: "Each pool tracks recently-spent lines
## per NPC (or per ambient context, for Minors sharing a pool) and excludes them from
## the next few picks." `BarkContext.pool_key()` is that granularity, `NpcRules.
## recent_pick_memory` is "the next few", and the memory is deliberately TRANSIENT - it
## is not in the save, because which line a farmer said last is not a fact about the
## playthrough.
##
## **Layer 6 is not evaluable before its unbindings.** A caller may pass a time band and
## a storm into a world with no sun and no Tower; it is ignored, and layer 6 is skipped
## whole. §Bark layers: "Layer 6 is **not evaluable at all** until its prerequisite
## unbinding fires - before `WS_SUN_UNBOUND`, there is no day/night, so there is nothing
## for a time-of-day pool to query".
##
## **Nothing here can produce a line for Pip.** §Aware-of-Pip: "Pip never answers, in
## dialogue or bark". There is no Pip speaker kind and no Pip id, so the rule is kept by
## the shape of the data rather than by a check that could be removed - see
## `BarkDefinition` and `NpcIds`.
##
## **`request()` allocates nothing on the ordinary path.** It is called whenever an NPC
## is about to speak, which in a populated square is several times a second, so the
## candidate buffer, the per-key recent rings and the returned `BarkPick` are all reused
## (see `BarkPick`), the pool key is built once per context rather than once per call
## (see `BarkContext.pool_key()`), and a key that has spent nothing yet is answered with
## the shared empty `NO_RECENT` rather than a fresh ring.
##
## Three things still allocate, and each one is paid for by an actual event rather than
## by the beat: a pool key the first time a context is stamped or re-stamped, a recent
## ring the first time a pool key spends a line, and the Fool's Reading - which
## `WorldStateService.reading_order()` hands back as a duplicate - the first time a
## request weighs a layer-2 line that names a motif. That last one is read LAZILY for
## exactly this reason; a request that never reaches layer 2 never asks for it.

## A line was chosen. `speaker` is the named NPC's id, or `&""` for an ambient Minor or
## the Querent - the same thing `BarkContext.speaker_id` carries.
signal bark_picked(speaker: StringName, bark_id: StringName, layer: int)

## A request found nothing at any layer. For a complete catalog this cannot happen (see
## `BarkPick`), so it is a content bug made audible rather than an expected outcome.
signal bark_missing(speaker: StringName, region_id: StringName)

## The ring a pool key that has spent nothing yet is answered with. A constant, so the
## empty case allocates nothing and is read-only for the same reason `BarkCatalog`'s
## layer buckets are: a caller cannot spend a line by appending to it.
const NO_RECENT: Array[StringName] = []

var _barks: BarkCatalog = null
var _motifs: MotifCatalog = null
var _profiles: NpcCatalog = null
var _rules: NpcRules = null
var _world_state: WorldStateService = null

## News travelling, for the layer-3 rumour condition. Built here and owned here.
var _rumors: RumorService = null

## Where an NPC stands, and the day the world is having. Built here and owned here.
var _schedules: ScheduleService = null

## `pool key -> Array[StringName]` of the last few bark ids that key spent, oldest
## first. Transient: see the class doc.
var _recent: Dictionary = {}

## The one buffer `request()` filters into. Cleared, never reallocated.
var _candidates: Array[BarkDefinition] = []

## The one result `request()` hands back. Re-stamped, never reallocated - see `BarkPick`.
var _pick: BarkPick = BarkPick.new()

## The choice within a layer. Seeded, so a test gets the same answer every run.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## The Reading, re-read at most once per request and only when a layer-2 line asks for
## it. A field so the array `WorldStateService` hands back is stored rather than passed
## around, and reused across the layer-2 filter.
var _reading: Array[StringName] = []

## True once this request has read the Reading. Reset at the top of every `request()`;
## see `_reading_order()`.
var _reading_read: bool = false


## Build the service over its content and the world it reads.
##
## `quests_catalog` and `graph` go to the rumour service, `regions` to the schedule
## service; both are CATALOGS and not services, deliberately, so nothing in this graph
## can reach the save that captures it (see `RumorService`'s class doc on the cycle).
##
## `rng_seed` of 0 means "seed from the system", which is the shipping configuration; a
## test passes a number and gets the same sequence every run.
func _init(
	barks: BarkCatalog,
	motifs: MotifCatalog = null,
	profiles: NpcCatalog = null,
	rules: NpcRules = null,
	world_state: WorldStateService = null,
	quests_catalog: QuestCatalog = null,
	graph: RegionGraph = null,
	regions: RegionCatalog = null,
	clock: GameClock = null,
	rng_seed: int = 0
) -> void:
	_barks = barks
	_motifs = motifs
	_profiles = profiles
	_rules = rules
	_world_state = world_state
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed
	_rumors = RumorService.new(rules, quests_catalog, graph, clock)
	_schedules = ScheduleService.new(rules, world_state, regions)


## News travelling. The rumour half of §"The world talks about you".
func rumors() -> RumorService:
	return _rumors


## Anchor schedules. The §Daily life half.
func schedules() -> ScheduleService:
	return _schedules


## The catalog this service picks from.
func catalog() -> BarkCatalog:
	return _barks


## The tuning table.
func rules() -> NpcRules:
	return _rules


## Listen for main quests completing, so their news starts travelling. Delegated to the
## rumour service, which is what actually holds the subscription.
func attach_quests(quests: QuestService) -> void:
	_rumors.attach_quests(quests)


## Pick a line for this speaker, in this moment.
##
## Layers 1 through 7, most specific first; the first layer with an eligible,
## non-recently-spent line wins and the rest are never asked. THE PICK IS REUSED - read
## it before the next call (see `BarkPick`).
func request(context: BarkContext) -> BarkPick:
	_pick.clear()
	if context == null or _barks == null:
		return _pick
	_reading_read = false
	var profile: NpcProfile = null
	if context.speaker_kind == BarkDefinition.SpeakerKind.NAMED and _profiles != null:
		profile = _profiles.find(context.speaker_id)
	# Asked ONCE and carried, not asked again at the bottom: `pool_key()` is cached on
	# the context, but a local is still the honest way to say that one request spends
	# out of exactly one pool.
	var pool_key := context.pool_key()
	var recent := _recent_for(pool_key)
	for layer: int in BarkLayer.DESCENDING:
		if not _is_layer_evaluable(layer):
			continue
		_candidates.clear()
		for bark: BarkDefinition in _barks.of_layer(layer):
			if recent.has(bark.id):
				continue
			if not _is_eligible(bark, context, profile):
				continue
			_candidates.append(bark)
		if _candidates.is_empty():
			continue
		var chosen := _candidates[_rng.randi_range(0, _candidates.size() - 1)]
		_remember(pool_key, chosen.id)
		_pick.fill(chosen, layer)
		bark_picked.emit(context.speaker_id, chosen.id, layer)
		return _pick
	bark_missing.emit(context.speaker_id, context.region_id)
	return _pick


## Forget what this speaker recently said, so their whole pool is eligible again.
##
## For a scene that wants a fresh mouth - a region reloaded, a conversation restarted.
## An empty key forgets everybody.
func forget_recent(pool_key: String = "") -> void:
	if pool_key == "":
		_recent.clear()
		return
	_recent.erase(pool_key)


## The bark ids this pool key has spent lately, oldest first, as a copy.
func recent_picks(pool_key: String) -> Array[StringName]:
	return _recent_for(pool_key).duplicate()


## Every pool key that has actually spent a line, in first-spend order.
##
## `recent_picks()`'s other half, and the observable side of the no-allocation rule: a
## key earns a ring by SPENDING, never by being asked. A square of fifty faces that
## have not spoken yet is fifty requests and no rings at all.
func remembered_pool_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for key: String in _recent:
		keys.append(key)
	return keys


# --- Save --------------------------------------------------------------------


## The save file's `npc` section: the rumour seeds, and nothing else.
##
## Recently-spent lines are deliberately NOT in it. §Bark layers makes repeat decay a
## property of the last few picks, which is a fact about the last minute of play and not
## about the playthrough; a save that restored it would restore an NPC's short-term
## memory of a conversation the player has forgotten.
func to_snapshot() -> Dictionary:
	return _rumors.to_snapshot()


## Load the `npc` section. Fresh service only, all-or-nothing; emits nothing.
func restore_snapshot(data: Dictionary) -> PackedStringArray:
	return _rumors.restore_snapshot(data)


## True until the rumour seeds are first written or first loaded into.
func is_pristine() -> bool:
	return _rumors.is_pristine()


# --- Internals ---------------------------------------------------------------


## True when this layer can be asked at all in the world as it stands.
##
## Only layer 6 can answer false, and §Bark layers is the reason: before
## `WS_SUN_UNBOUND` there is no day/night and before `WS_TOWER_UNBOUND` no storm
## rotation, so "there is nothing for a time-of-day pool to query". The layer is skipped
## whole rather than filtered line by line, because a pool that cannot be queried is not
## a pool with no matches - it is not there.
func _is_layer_evaluable(layer: int) -> bool:
	if layer != BarkLayer.TIME_WEATHER:
		return true
	if _world_state == null:
		return false
	return _world_state.is_fired(WorldStateIds.WS_SUN_UNBOUND) \
		or _world_state.is_fired(WorldStateIds.WS_TOWER_UNBOUND)


## True when every condition on this bark holds for this speaker in this moment.
##
## The order is cheapest-first and the checks are the doc's own Queries column, one per
## layer, applied uniformly: a condition a bark does not carry is not a condition, so a
## layer-7 line with nothing but a suit falls through all of this in four comparisons.
func _is_eligible(
	bark: BarkDefinition, context: BarkContext, profile: NpcProfile
) -> bool:
	if not _matches_speaker(bark, context, profile):
		return false
	if bark.region_id != &"" and bark.region_id != context.region_id:
		return false
	if bark.about_pip and not context.near_pip:
		return false
	if not _matches_world_state(bark):
		return false
	if not _matches_act(bark):
		return false
	if not _matches_renown(bark, context, profile):
		return false
	if not _matches_motif(bark):
		return false
	if not _matches_quest(bark):
		return false
	if not _matches_memory(bark, context):
		return false
	if not _matches_sky(bark, context):
		return false
	if not _matches_rumor(bark, context):
		return false
	return true


## Who may say this line: the kind of speaker, and - for the crowd - the suit and Court
## rank they are read by (§Named vs. ambient NPCs).
func _matches_speaker(
	bark: BarkDefinition, context: BarkContext, profile: NpcProfile
) -> bool:
	if bark.speaker_kind != context.speaker_kind:
		return _is_the_speakers_baseline(bark, context, profile)
	if bark.speaker_kind == BarkDefinition.SpeakerKind.NAMED:
		return bark.speaker_id == context.speaker_id
	if bark.suit != Suit.UNKNOWN and bark.suit != _suit_of(context, profile):
		return false
	if bark.npc_rank != NpcRank.ANY and bark.npc_rank != _rank_of(context, profile):
		return false
	return true


## The one line a speaker may say that was not authored for their KIND: a NAMED NPC
## falling through to their own suit's layer-7 baseline.
##
## §Bark layers' layer 7 is "Suit only... authored once per suit, always available", and
## `BarkDefinition._validate_generic()` refuses a layer-7 line with a named speaker for
## exactly that reason - a per-person floor is not a floor for the suit. Which leaves
## named NPCs with nothing at the bottom of the fall-through unless they draw the
## crowd's, so here they do, and the promise that "the next layer down always has
## content" holds for a person as well as for a face in a market.
##
## There is no "and only if nothing more specific exists" test, because there does not
## need to be one: this is reachable only at layer 7, which is asked last, after every
## more specific layer has already declined. And it is the only cross-kind match there
## is - a Querent's baseline is a Querent line keyed by region (the Cliff's four idle
## lines), and an ambient Minor is the crowd layer 7 was written for.
func _is_the_speakers_baseline(
	bark: BarkDefinition, context: BarkContext, profile: NpcProfile
) -> bool:
	if bark.layer != BarkLayer.GENERIC:
		return false
	if context.speaker_kind != BarkDefinition.SpeakerKind.NAMED:
		return false
	if bark.speaker_kind != BarkDefinition.SpeakerKind.AMBIENT_MINOR:
		return false
	# Suit only: a layer-7 line carrying a Court rank is refused by validation, and an
	# unvalidated one is not this person's baseline either.
	if bark.npc_rank != NpcRank.ANY:
		return false
	var suit := _suit_of(context, profile)
	return suit != Suit.UNKNOWN and bark.suit == suit


## Layer 3's own question, and the pillar's: every flag this line waits on has fired,
## and none of the flags it waits to be spared has.
func _matches_world_state(bark: BarkDefinition) -> bool:
	if not bark.has_world_state_condition():
		return true
	if _world_state == null:
		return false
	for flag: StringName in bark.requires_fired:
		if not _world_state.is_fired(flag):
			return false
	for flag: StringName in bark.requires_not_fired:
		if _world_state.is_fired(flag):
			return false
	return true


## Layer 4: the act, and `CONFESSED` - which `world.md` §Global states makes
## independent of the act, so they are two questions and not one.
func _matches_act(bark: BarkDefinition) -> bool:
	if bark.act == BarkDefinition.ANY and bark.requires_confessed == BarkDefinition.ANY:
		return true
	if _world_state == null:
		return false
	if bark.act != BarkDefinition.ANY and _world_state.act() != bark.act:
		return false
	if bark.requires_confessed != BarkDefinition.ANY:
		var confessed := _world_state.is_confessed()
		if confessed != (bark.requires_confessed == BarkDefinition.CONFESSED):
			return false
	return true


## Layer 5: the Fool's standing with the suit this speaker stands for.
func _matches_renown(
	bark: BarkDefinition, context: BarkContext, profile: NpcProfile
) -> bool:
	if bark.renown_tier_min == BarkDefinition.ANY_TIER \
			and bark.renown_tier_max == BarkDefinition.ANY_TIER:
		return true
	if _world_state == null:
		return false
	var standing := context.standing_suit()
	if standing == Suit.UNKNOWN:
		standing = _suit_of(context, profile)
	if standing == Suit.UNKNOWN:
		return false
	var tier := _world_state.renown_tier(standing)
	if bark.renown_tier_min != BarkDefinition.ANY_TIER and tier < bark.renown_tier_min:
		return false
	if bark.renown_tier_max != BarkDefinition.ANY_TIER and tier > bark.renown_tier_max:
		return false
	return true


## Layer 2: the shape of the Fool's Reading (`world.md` §The Fool's Reading).
func _matches_motif(bark: BarkDefinition) -> bool:
	if bark.motif == &"":
		return true
	if _motifs == null:
		return false
	var motif := _motifs.find(bark.motif)
	if motif == null:
		return false
	return motif.matches(_reading_order())


## Layer 1: what the quest this line belongs to is doing right now. Quest state lives on
## `WorldStateService` because it is save data, which is why no quest SERVICE is held.
func _matches_quest(bark: BarkDefinition) -> bool:
	if bark.quest_id == &"":
		return true
	if _world_state == null:
		return false
	return _world_state.quest_state(bark.quest_id) == bark.quest_state


## Layer 1-2's narrower gate: this named NPC's own memory of the Fool.
func _matches_memory(bark: BarkDefinition, context: BarkContext) -> bool:
	if bark.npc_memory_flag == &"":
		return true
	if _world_state == null or context.speaker_id == &"":
		return false
	return _world_state.npc_remembers(context.speaker_id, bark.npc_memory_flag)


## Layer 6's conditions, once the layer is evaluable at all. The two halves are gated
## separately because their unbindings are separate: a world with a sun and no Tower has
## a dusk and no storms.
func _matches_sky(bark: BarkDefinition, context: BarkContext) -> bool:
	if _world_state == null:
		return bark.time_band == TimeBand.ANY and bark.weather == Weather.ANY
	if bark.time_band != TimeBand.ANY:
		if not _world_state.is_fired(WorldStateIds.WS_SUN_UNBOUND):
			return false
		if bark.time_band != context.time_band:
			return false
	if bark.weather != Weather.ANY:
		if not _world_state.is_fired(WorldStateIds.WS_TOWER_UNBOUND):
			return false
		if bark.weather != context.weather:
			return false
	return true


## Layer 3's delayed-activation delta: has the news got this far yet.
func _matches_rumor(bark: BarkDefinition, context: BarkContext) -> bool:
	if not bark.is_rumor():
		return true
	return _rumors.has_reached(bark.rumor_of_quest, context.region_id)


## The speaker's suit: the context's, or their profile's when a named NPC's context did
## not bother to say.
func _suit_of(context: BarkContext, profile: NpcProfile) -> int:
	if context.suit != Suit.UNKNOWN:
		return context.suit
	return Suit.UNKNOWN if profile == null else profile.suit


## The speaker's Court rank, on the same rule.
func _rank_of(context: BarkContext, profile: NpcProfile) -> int:
	if context.speaker_kind == BarkDefinition.SpeakerKind.NAMED and profile != null:
		return profile.npc_rank
	return context.npc_rank


## The Fool's Reading, read at most once per request and only when something asks.
##
## `WorldStateService.reading_order()` hands back a DUPLICATE of its own array, so
## asking for one per request would be an allocation on every beat of every NPC in the
## square - and seven requests in eight never reach a line that names a motif. So the
## read is deferred to `_matches_motif()`, which is the only caller, and the answer is
## kept for the rest of the request.
##
## NOT a ternary: `[] if _world_state == null else _world_state.reading_order()` parses
## fine but fails at RUN TIME - "Trying to assign an array of type 'Array' to a variable
## of type 'Array[StringName]'" - because the `[]` branch's static type is the untyped
## `Array`, and Godot 4.7 does not widen it to match the other branch when the whole
## expression lands in a typed field. A 4.7 surprise, not a design choice; see
## `bark_service_test.gd`'s Cliff-pool test, which builds a service with no world state
## at all.
func _reading_order() -> Array[StringName]:
	if _reading_read:
		return _reading
	_reading_read = true
	if _world_state == null:
		_reading.clear()
	else:
		_reading = _world_state.reading_order()
	return _reading


## This pool key's ring of recently-spent lines - THE RING ITSELF, and `NO_RECENT` when
## this key has never spent one.
##
## A LOOKUP, deliberately: the old version created the ring on read, which meant a
## `Dictionary.get()` with a fresh `[] as Array[StringName]` default evaluated on every
## call whether or not it was needed - an allocation per request, in the one method
## `request()`'s class doc promises does not have any. Creating is `_ring_for()`'s job
## and only a line actually being spent asks for it.
func _recent_for(pool_key: String) -> Array[StringName]:
	if not _recent.has(pool_key):
		return NO_RECENT
	var ring: Array[StringName] = _recent[pool_key]
	return ring


## This pool key's ring, created if this is the first line it has ever spent.
func _ring_for(pool_key: String) -> Array[StringName]:
	if _recent.has(pool_key):
		var existing: Array[StringName] = _recent[pool_key]
		return existing
	var ring: Array[StringName] = []
	_recent[pool_key] = ring
	return ring


## Spend a line: push it onto this key's ring and drop the oldest past the memory.
##
## A memory of zero remembers nothing, and creates nothing to remember it in: a ring
## that already exists is emptied, and a key that has none does not get one.
func _remember(pool_key: String, bark_id: StringName) -> void:
	var depth := 0 if _rules == null else maxi(0, _rules.recent_pick_memory)
	if depth == 0:
		if _recent.has(pool_key):
			var existing: Array[StringName] = _recent[pool_key]
			existing.clear()
		return
	var ring := _ring_for(pool_key)
	ring.append(bark_id)
	while ring.size() > depth:
		ring.remove_at(0)
