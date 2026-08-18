class_name BarkDefinition
extends TarrockDefinition

## One bark: a line key, the layer it belongs to, and every condition that has to hold
## before it may be said.
##
## HAND-AUTHORED under `res://data/npc/barks/`, lifted out of the BARKS sections of
## quest and region docs. `docs/design/npc-system.md` §Consistency note is explicit
## that the system doc "owns **no line of dialogue and no specific pool**", so this
## class is the SHAPE of a bark and the docs hold the content.
##
## **The line itself is never here.** `text_key` is a translation key resolved through
## `res://localization/`, per standing decision 6 (no player-facing literal in code or
## content). A definition holding English would be a definition no localiser could
## reach.
##
## **The conditions are data, never a branch in code.** `npc-system.md` §Bark layers
## lists what each layer queries - quest state, `READING_ORDER` motifs, `WS_*`
## combinations, act and `CONFESSED`, Renown tier, day/night and storms, suit - and
## every one of those is a field here, so `BarkService` evaluates one uniform filter
## and a writer can read a pool's whole gating off its `.tres` files.
##
## **The pillar lives in `validate()`.** §The pillar: "a canned line that ignores a
## transformed world... is a **bug**". A system cannot check whether a LINE ignores the
## world, but it can check that a line filed in an aware layer actually carries the
## awareness that layer is for - a layer-3 bark with no world-state condition is a
## generic line wearing a world-state badge, and it is refused here.
##
## **There is no Pip speaker, structurally.** `SpeakerKind` has three members and none
## of them is Pip; `NpcIds` has no Pip id. §Aware-of-Pip: "Pip never answers, in
## dialogue or bark - that silence is the character rule and the bark system must never
## manufacture a line that breaks it." `about_pip` is the opposite thing: a line SOMEONE
## ELSE says about the dog.

## Who says a bark. Three kinds, and the split is `npc-system.md` §Named vs. ambient
## NPCs' own.
enum SpeakerKind {
	## The population: no id, no memory, read "by **visible suit + Court rank**", and
	## sharing suit/region pools with everyone else who reads the same way.
	AMBIENT_MINOR,
	## A person from `characters.md` §Recurring named NPCs (or a quest-promoted one),
	## with persistent memory. `speaker_id` names them.
	NAMED,
	## The unseen narrator-guide voice (`characters.md` §The Querent). NOT AN NPC and
	## not a Minor: the Querent has no suit, no rank and no memory, and speaks over a
	## region rather than standing in it. The Cliff's idle lines are this kind.
	QUERENT,
}

## `requires_confessed` and `act`: this bark does not care.
const ANY := -1

## `requires_confessed`: only before Death is unbound.
const NOT_CONFESSED := 0

## `requires_confessed`: only once `CONFESSED` (`world.md` §Global states).
const CONFESSED := 1

## `renown_tier_min` / `renown_tier_max`: unbounded on that side. Tiers are 1..5
## (`docs/design/progression.md` §Renown), so 0 can never be a real bound.
const ANY_TIER := 0

## What a translation key looks like. The localization lint enforces the same shape on
## the other side of the fence; checking it here means a bad key fails the data-drift
## test too, before anyone opens the game.
const TEXT_KEY_PATTERN := "^[A-Z0-9_]+$"

## Compiled once for the whole class, as `QuestDefinition` does: `validate()` runs over
## every bark in the catalog at boot, and building the same matcher per line would be a
## regex compiled a few hundred times to answer the same question.
static var _text_key_regex: RegEx = RegEx.create_from_string(TEXT_KEY_PATTERN)

## Which of the seven pools this line is in. `BarkLayer`'s constants, never a number.
@export var layer: int = BarkLayer.GENERIC

## The translation key of the line. Never the line.
@export var text_key: StringName = &""

## What kind of speaker says it.
@export var speaker_kind: SpeakerKind = SpeakerKind.AMBIENT_MINOR

## Which named NPC says it (`NpcIds`). `&""` for every other kind - an ambient Minor
## has no id to put here and the Querent is not a person.
@export var speaker_id: StringName = &""

## The region this line may be said in, or `&""` for anywhere.
@export var region_id: StringName = &""

## The speaker's suit (`Suit.Id`), or `Suit.UNKNOWN` (-1) for any suit. Layer 7 is
## authored per suit and nothing else, so this is the layer-7 pool's only key.
@export var suit: int = Suit.UNKNOWN

## The speaker's Court rank (`NpcRank.Id`), or `NpcRank.ANY` (-1). Half of how a crowd
## is read (§Named vs. ambient NPCs), and a bark condition for that reason.
@export var npc_rank: int = NpcRank.ANY

## `WS_*` flags that must ALL have fired.
@export var requires_fired: Array[StringName] = []

## `WS_*` flags that must NOT have fired. The pillar's other half: a famine line is
## wrong once the famine ended, and this is where a writer says so.
@export var requires_not_fired: Array[StringName] = []

## `CONFESSED`, `NOT_CONFESSED`, or `ANY`.
@export var requires_confessed: int = ANY

## The act this line belongs to (`WorldStateService.Act`), or `ANY`.
@export var act: int = ANY

## The lowest Renown tier (1..5) with the speaker's suit that may say it, or `ANY_TIER`.
@export var renown_tier_min: int = ANY_TIER

## The highest Renown tier that may say it, or `ANY_TIER`.
@export var renown_tier_max: int = ANY_TIER

## The `ReadingMotif` id this line waits on (layer 2), or `&""`.
@export var motif: StringName = &""

## The quest whose state gates this line (layer 1), or `&""`.
@export var quest_id: StringName = &""

## The state that quest must be in. Meaningless without `quest_id`.
@export var quest_state: StringName = &""

## The memory flag the NAMED speaker must hold (`NpcMemoryIds`), or `&""`. §Named vs.
## ambient NPCs: "'you're the one who [did the thing]' is a layer-1-adjacent line gated
## on the NPC's own flag set, not on global world-state."
@export var npc_memory_flag: StringName = &""

## The time of day this line wants (`TimeBand.Id`), or `TimeBand.ANY`. Layer 6 only,
## and never evaluable before `WS_SUN_UNBOUND`.
@export var time_band: int = TimeBand.ANY

## The weather this line wants (`Weather.Id`), or `Weather.ANY`. Layer 6 only, and
## never evaluable before `WS_TOWER_UNBOUND`.
@export var weather: int = Weather.ANY

## The main quest whose news this line carries (layer 3), or `&""`. A rumour is
## "not a separate layer, just a delayed-activation delta on the same mechanism"
## (§"The world talks about you"), and this field is that delta: the line is eligible
## only once the news has had time to travel to the region it is being said in.
@export var rumor_of_quest: StringName = &""

## True when the line is to or about Pip. TEXTURE ONLY - it changes no selection rule.
## §Aware-of-Pip: Pip-directed lines are "scattered lightly rather than universally",
## which is an authoring instruction, so this field exists to let a reviewer count them
## rather than to let the system ration them.
@export var about_pip: bool = false

## The doc and BARKS section this line was lifted from.
@export var source_ref: String = ""

## Authoring notes. Doc text; never displayed.
@export var notes: String = ""


## True when a named NPC says this line.
func is_named() -> bool:
	return speaker_kind == SpeakerKind.NAMED


## True when this line carries the news of a completed main quest.
func is_rumor() -> bool:
	return rumor_of_quest != &""


## True when this bark waits on some `WS_*` flag, in either direction - the condition
## layer 3 exists for, and the one a rumour satisfies by carrying news instead.
func has_world_state_condition() -> bool:
	return not requires_fired.is_empty() or not requires_not_fired.is_empty()


## True when this line IS the evergreen floor for its suit: a layer-7 ambient baseline
## with a suit and no other condition of any kind.
##
## §Bark layers' promise is precise - "the next layer down always has content, because
## layer 7 is mandatory and evergreen" - and it is only true of a line that can never
## be filtered out. A layer-7 line with a Court rank, a region, a flag or a nearby dog
## is a line that CAN be, so it is not a floor, and `BarkCatalog.suits_without_baseline()`
## does not count it as one. `validate()` refuses most of these outright; this reads the
## same rule as a question rather than as an error list, so the catalog can ask it of a
## set that has not been validated yet.
func is_suit_baseline() -> bool:
	return layer == BarkLayer.GENERIC \
		and speaker_kind == SpeakerKind.AMBIENT_MINOR \
		and suit != Suit.UNKNOWN \
		and npc_rank == NpcRank.ANY \
		and region_id == &"" \
		and not about_pip \
		and not has_world_state_condition() \
		and act == ANY \
		and requires_confessed == ANY \
		and renown_tier_min == ANY_TIER \
		and renown_tier_max == ANY_TIER \
		and quest_id == &"" \
		and npc_memory_flag == &"" \
		and motif == &"" \
		and rumor_of_quest == &"" \
		and time_band == TimeBand.ANY \
		and weather == Weather.ANY


## Every problem with this bark, one string per problem.
##
## Two families of check: the fields make sense at all, and the line is filed in a
## layer it actually belongs to (see the class doc on the pillar).
func validate() -> PackedStringArray:
	var errors := super()
	if not BarkLayer.is_layer(layer):
		errors.append("%s is filed at layer %d; there are seven" % [id, layer])
	if text_key == &"":
		errors.append("%s has no line key" % id)
	elif _text_key_regex.search(String(text_key)) == null:
		errors.append("%s has a line key that is not a translation key: %s" % [id, text_key])
	errors.append_array(_validate_speaker())
	errors.append_array(_validate_conditions())
	errors.append_array(_validate_layer_fit())
	return errors


## Every problem only the catalogs can find: a flag, a region, a quest, a motif or a
## named speaker this bark waits on that nothing else in the game defines.
##
## Every argument is optional so a test can check the half it cares about; the
## composition root passes them all, and a bark waiting on something nobody defines is
## a line that could never be said - the exact silence this check exists to make loud.
func validate_against(
	world_states: WorldStateCatalog = null,
	regions: RegionCatalog = null,
	quests: QuestCatalog = null,
	motifs: MotifCatalog = null,
	profiles: NpcCatalog = null
) -> PackedStringArray:
	var errors := PackedStringArray()
	if world_states != null:
		for flag: StringName in requires_fired + requires_not_fired:
			if world_states.find(flag) == null:
				errors.append("%s waits on %s, which no world-state row defines" % [id, flag])
	if regions != null and region_id != &"" and not regions.has(region_id):
		errors.append("%s is said in %s, which is no region" % [id, region_id])
	if quests != null:
		for named_quest: StringName in [quest_id, rumor_of_quest]:
			if named_quest != &"" and not quests.has(named_quest):
				errors.append("%s names %s, which is no quest" % [id, named_quest])
		var rumored := quests.find(rumor_of_quest) if rumor_of_quest != &"" else null
		if rumored != null and not rumored.is_main():
			errors.append("%s carries the news of %s, which is no main quest" % [
				id, rumor_of_quest
			])
	if motifs != null and motif != &"" and not motifs.has(motif):
		errors.append("%s waits on %s, which is no reading motif" % [id, motif])
	if profiles != null and speaker_id != &"":
		var profile := profiles.find(speaker_id)
		if profile == null:
			errors.append("%s is said by %s, who has no profile" % [id, speaker_id])
		else:
			if npc_memory_flag != &"" and not profile.can_remember(npc_memory_flag):
				errors.append("%s waits on %s remembering %s, which they never learn" % [
					id, speaker_id, npc_memory_flag
				])
			# A named speaker's suit is their PROFILE's - "Identity read... by name and
			# characterization" (§Named vs. ambient NPCs) - and the bark's own `suit`
			# is the crowd's key, not a second opinion about a person. Two different
			# answers would send this line to a Renown tier or a layer-7 pool the
			# speaker does not stand in, so the disagreement is refused rather than
			# resolved. A profile with no canon suit (`Suit.UNKNOWN`, which is six of
			# the nine today) has no opinion to contradict.
			if suit != Suit.UNKNOWN and profile.suit != Suit.UNKNOWN and suit != profile.suit:
				errors.append("%s puts %s in %s; their profile says %s" % [
					id, speaker_id, Suit.name_key(suit), Suit.name_key(profile.suit)
				])
	return errors


# --- Internals ----------------------------------------------------------------


## The speaker's own fields: an id exactly where an id belongs, and never anywhere else.
func _validate_speaker() -> PackedStringArray:
	var errors := PackedStringArray()
	match speaker_kind:
		SpeakerKind.NAMED:
			if speaker_id == &"":
				errors.append("%s is said by a named NPC with no id" % id)
		SpeakerKind.AMBIENT_MINOR:
			if speaker_id != &"":
				errors.append("%s names a speaker but is an ambient line" % id)
			if suit == Suit.UNKNOWN and layer == BarkLayer.GENERIC:
				errors.append("%s is a generic ambient line with no suit" % id)
		SpeakerKind.QUERENT:
			if speaker_id != &"":
				errors.append("%s names a speaker but the Querent is not a person" % id)
			if suit != Suit.UNKNOWN:
				errors.append("%s gives the Querent a suit; the Querent is no Minor" % id)
			if npc_rank != NpcRank.ANY:
				errors.append("%s gives the Querent a Court rank" % id)
	if npc_memory_flag != &"" and speaker_kind != SpeakerKind.NAMED:
		errors.append("%s gates on a memory only a named NPC could hold" % id)
	if suit != Suit.UNKNOWN and (suit < 0 or suit >= Suit.ALL.size()):
		errors.append("%s names suit %d, which is no suit" % [id, suit])
	if not NpcRank.is_condition(npc_rank):
		errors.append("%s names Court rank %d, which is no rank" % [id, npc_rank])
	return errors


## The conditions that have to make sense whatever layer they are on.
func _validate_conditions() -> PackedStringArray:
	var errors := PackedStringArray()
	if requires_confessed != ANY and requires_confessed != CONFESSED \
			and requires_confessed != NOT_CONFESSED:
		errors.append("%s carries a CONFESSED condition of %d" % [id, requires_confessed])
	if act != ANY and (act < WorldStateService.Act.ACT_I or act > WorldStateService.Act.ACT_III):
		errors.append("%s belongs to act %d; there are three" % [id, act])
	for tier: int in [renown_tier_min, renown_tier_max]:
		if tier != ANY_TIER and (tier < RenownLadder.FIRST_TIER or tier > RenownLadder.TIER_COUNT):
			errors.append("%s names Renown tier %d; the ladder has %d rungs" % [
				id, tier, RenownLadder.TIER_COUNT
			])
	if renown_tier_min != ANY_TIER and renown_tier_max != ANY_TIER \
			and renown_tier_min > renown_tier_max:
		errors.append("%s wants Renown between %d and %d" % [
			id, renown_tier_min, renown_tier_max
		])
	if not TimeBand.is_condition(time_band):
		errors.append("%s names time band %d, which is no band" % [id, time_band])
	if time_band == TimeBand.Id.NONE:
		errors.append("%s waits for a time of day the world does not have" % id)
	if not Weather.is_condition(weather):
		errors.append("%s names weather %d, which is no weather" % [id, weather])
	if weather == Weather.Id.NONE:
		errors.append("%s waits for weather that is not weather" % id)
	if quest_id == &"" and quest_state != &"":
		errors.append("%s waits for a quest state with no quest" % id)
	if quest_id != &"" and quest_state == &"":
		errors.append("%s waits on %s being in no particular state" % [id, quest_id])
	for flag: StringName in requires_fired:
		if requires_not_fired.has(flag):
			errors.append("%s waits for %s to have fired and not to have" % [id, flag])
	return errors


## The line is in a layer it belongs to. `npc-system.md` §Bark layers' Queries column,
## read as a rule: a pool is defined by what it queries, so a line that queries none of
## its layer's things is in the wrong pool - and, at layer 7, a line that queries
## anything at all is.
func _validate_layer_fit() -> PackedStringArray:
	var errors := PackedStringArray()
	match layer:
		BarkLayer.QUEST_SCRIPTED:
			if quest_id == &"" and npc_memory_flag == &"":
				errors.append("%s is quest-scripted but waits on no quest and no memory" % id)
		BarkLayer.SEQUENCE:
			if motif == &"":
				errors.append("%s is a sequence bark and names no motif" % id)
		BarkLayer.WORLD_STATE:
			if not has_world_state_condition() and not is_rumor():
				errors.append("%s is a world-state bark and waits on no world state" % id)
		BarkLayer.ACT_STATE:
			if act == ANY and requires_confessed == ANY:
				errors.append("%s is an act bark and names no act and no CONFESSED" % id)
		BarkLayer.RENOWN:
			if renown_tier_min == ANY_TIER and renown_tier_max == ANY_TIER:
				errors.append("%s is a Renown bark and names no tier" % id)
			if suit == Suit.UNKNOWN:
				errors.append("%s is a Renown bark and names no suit to stand with" % id)
		BarkLayer.TIME_WEATHER:
			if time_band == TimeBand.ANY and weather == Weather.ANY:
				errors.append("%s is a time/weather bark and names neither" % id)
		BarkLayer.GENERIC:
			errors.append_array(_validate_generic())
	if layer != BarkLayer.SEQUENCE and motif != &"":
		errors.append("%s names a motif outside layer %d" % [id, BarkLayer.SEQUENCE])
	if layer != BarkLayer.TIME_WEATHER \
			and (time_band != TimeBand.ANY or weather != Weather.ANY):
		errors.append("%s names a time or weather outside layer %d" % [
			id, BarkLayer.TIME_WEATHER
		])
	if layer != BarkLayer.WORLD_STATE and is_rumor():
		errors.append("%s carries news outside layer %d" % [id, BarkLayer.WORLD_STATE])
	return errors


## Layer 7 is "**Generic** suit-culture baseline... Suit only... authored once per
## suit, always available" and "never region-specific". So the evergreen floor is held
## to being evergreen: any condition at all would let it run out, and a layer the
## fall-through can exhaust is a layer that can fail to answer.
##
## THE QUERENT IS THE ONE EXCEPTION, and it is the doc's own: the Querent has no suit
## to be generic for and speaks over one region rather than everywhere. So a Querent
## line trades the suit key for a region key and keeps the rest of the rule - no world
## state, no act, no Renown, no memory. That is what the Cliff's four idle lines are.
##
## **SUIT ONLY** is the rest of the rule, and it is refused two more ways here. A COURT
## RANK is a condition like any other: the Queries column for layer 7 reads "Suit only",
## so a baseline authored for Knights of Swords leaves the Pages of Swords with no floor
## at all. And a NAMED SPEAKER cannot hold a baseline either: layer 7 is "authored once
## per suit", which is a pool a whole suit shares, and a per-person layer-7 line would
## be an evergreen floor that exists for exactly one NPC and is missing for every other
## member of their suit. A named NPC draws their suit's baseline instead - see
## `BarkService._matches_speaker()`, which is where that fall-through lives.
func _validate_generic() -> PackedStringArray:
	var errors := PackedStringArray()
	if speaker_kind == SpeakerKind.QUERENT:
		if region_id == &"":
			errors.append("%s is a Querent baseline said nowhere in particular" % id)
	elif speaker_kind == SpeakerKind.NAMED:
		errors.append("%s is a baseline for one person; layer %d is per suit" % [
			id, BarkLayer.GENERIC
		])
	else:
		if region_id != &"":
			errors.append("%s is a generic baseline pinned to %s" % [id, region_id])
		# The Querent's rank is `_validate_speaker()`'s to refuse, and a named speaker
		# has already been refused above; only the crowd reaches this.
		if npc_rank != NpcRank.ANY:
			errors.append("%s is a baseline line that waits on a Court rank" % id)
	if has_world_state_condition():
		errors.append("%s is a baseline line that waits on a world state" % id)
	if act != ANY or requires_confessed != ANY:
		errors.append("%s is a baseline line that waits on an act" % id)
	if renown_tier_min != ANY_TIER or renown_tier_max != ANY_TIER:
		errors.append("%s is a baseline line that waits on Renown" % id)
	if quest_id != &"" or npc_memory_flag != &"":
		errors.append("%s is a baseline line that waits on a quest or a memory" % id)
	return errors
