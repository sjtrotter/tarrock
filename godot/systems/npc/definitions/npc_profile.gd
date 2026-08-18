class_name NpcProfile
extends TarrockDefinition

## One named NPC: who they are to the world, what they can remember about the Fool, and
## where they stand at each hour.
##
## HAND-AUTHORED under `res://data/npc/profiles/`, from `docs/design/characters.md`
## §Recurring named NPCs - see `NpcIds` for why the section cannot be parsed. Ambient
## Minors have no profile at all and never will: `docs/design/npc-system.md` §Named vs.
## ambient NPCs gives them no memory and no name and reads them "by **visible suit +
## Court rank**", which a `BarkContext` carries directly.
##
## **Memory is a vocabulary here and a value in the save.** `memory_flags_known` is the
## set of things THIS person could ever learn; what they have actually learned lives in
## `WorldStateService.npc_memory` (round 2), because it is per-NPC save data. A bark
## that waits on a flag its speaker's profile does not list is caught by
## `BarkDefinition.validate_against()` - a line nobody could ever say, said by nobody.
##
## **Schedules are data only this round.** `ScheduleEntry` explains what does and does
## not exist yet.

## The translation key of this NPC's name. Never the name.
@export var name_key: StringName = &""

## True for everyone here, and the field exists so the answer is on the definition
## rather than in whoever is holding it. There is no ambient profile to set it false on.
@export var is_named: bool = true

## Their suit-culture (`Suit.Id`), or `Suit.UNKNOWN` when no doc says. Only Flick's is
## canon today ("a Page of Wands"); the rest are a content pass and are left unset
## rather than guessed.
@export var suit: int = Suit.UNKNOWN

## Their Court rank (`characters.md` §The Courts). `NONE` is the commons and is the
## right answer for most people, not a missing one.
@export var npc_rank: NpcRank.Id = NpcRank.Id.NONE

## The region they live in (`RegionIds`), or `&""` when no doc places them.
@export var home_region: StringName = &""

## The marker they sleep at. §Daily life's first anchor.
@export var home_anchor: StringName = &""

## The marker they work at. §Daily life's second anchor.
@export var work_anchor: StringName = &""

## The marker they gather at - "market, tavern, chapel, whatever fits the region".
@export var gathering_anchor: StringName = &""

## Their day, band by band. Empty is legal and common: an NPC with no schedule stands
## wherever the region scene put them, which is what every bound-region NPC does today.
@export var schedule: Array[ScheduleEntry] = []

## Everything this person could ever learn about the Fool (`NpcMemoryIds`). The
## vocabulary, not the memory.
@export var memory_flags_known: Array[StringName] = []

## True when this NPC bows to Pip on sight.
##
## `characters.md` §Pip: "NPCs of the Stillmarsh in particular bow to Pip on sight;
## write this as instinctive reverence, never spelled out in dialogue", and
## `npc-system.md` §Aware-of-Pip repeats it as a system rule: "this is canon and
## scripted, not a bark". So it is a FLAG ON THE PERSON and not a bark pool - there is
## no line to author, and a bark system that answered this would be manufacturing one.
@export var bows_to_pip: bool = false

## The doc bullet this profile was read from.
@export var doc_ref: String = ""

## The readings that had to be made where the bullet is silent. Doc text; never shown.
@export var notes: String = ""


## True when this NPC could ever learn this about the Fool.
func can_remember(flag: StringName) -> bool:
	return memory_flags_known.has(flag)


## The anchor this NPC holds when the world has no time of day - a bound region's
## tableau, and every region before `WS_SUN_UNBOUND` fires.
##
## The base entry filed under `TimeBand.Id.NONE` if there is one, then the home anchor,
## then the first anchor of any kind: a person always stands SOMEWHERE, and a schedule
## that answered `&""` would be an NPC the region could not draw.
func tableau_anchor() -> StringName:
	for entry: ScheduleEntry in schedule:
		if entry != null and entry.is_base() and entry.time_band == TimeBand.Id.NONE:
			return entry.anchor
	if home_anchor != &"":
		return home_anchor
	for entry: ScheduleEntry in schedule:
		if entry != null and entry.anchor != &"":
			return entry.anchor
	return &""


## Every entry for this band, base and variant alike, in authored order.
func entries_for(band: TimeBand.Id) -> Array[ScheduleEntry]:
	var found: Array[ScheduleEntry] = []
	for entry: ScheduleEntry in schedule:
		if entry != null and entry.time_band == band:
			found.append(entry)
	return found


## Every problem with this profile, one string per problem.
func validate() -> PackedStringArray:
	var errors := super()
	if name_key == &"":
		errors.append("%s has no name key" % id)
	if not is_named:
		errors.append("%s is a profile for an NPC with no name; ambient Minors have none" % id)
	if suit != Suit.UNKNOWN and (suit < 0 or suit >= Suit.ALL.size()):
		errors.append("%s names suit %d, which is no suit" % [id, suit])
	var seen: Dictionary = {}
	for index: int in schedule.size():
		var entry := schedule[index]
		if entry == null:
			errors.append("%s schedule entry %d is empty" % [id, index])
			continue
		errors.append_array(entry.validate())
		var key := "%d|%d" % [entry.time_band, entry.variant]
		if seen.has(key):
			errors.append("%s stands in two places at once at %s" % [
				id, TimeBand.name_key(entry.time_band)
			])
		seen[key] = true
	for flag: StringName in memory_flags_known:
		if flag == &"":
			errors.append("%s can remember something with no name" % id)
	return errors


## Every problem only the catalogs can find: a home region nobody has, or a Pip bow
## from somewhere that is not the Stillmarsh.
func validate_against(regions: RegionCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if regions != null and home_region != &"" and not regions.has(home_region):
		errors.append("%s lives in %s, which is no region" % [id, home_region])
	if bows_to_pip and home_region != RegionIds.STILLMARSH:
		errors.append("%s bows to Pip from outside the Stillmarsh" % id)
	return errors
