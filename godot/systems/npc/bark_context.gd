class_name BarkContext
extends RefCounted

## Who is about to speak, where they are standing, and what the caller can see that the
## services cannot.
##
## `docs/design/npc-system.md` §Bark layers: "A bark request (an NPC about to greet,
## comment, or idle-chatter near the Fool) is resolved against seven pools". This is
## that request.
##
## **It carries the SPEAKER, not the world.** Everything the world knows -
## which flags fired, which act it is, the Fool's Reading, Renown, quest state - is read
## by `BarkService` off `WorldStateService` at request time, so a caller cannot pass a
## stale world in and get a line that "ignores a transformed world" (§The pillar). What
## the caller supplies is what only the caller knows: who this NPC is, which region they
## are standing in, whether Pip is nearby, and what the sky is doing.
##
## **The sky is advisory.** `time_band` and `weather` are passed in, and the service
## ignores them entirely until `WS_SUN_UNBOUND` / `WS_TOWER_UNBOUND` have fired
## (§Bark layers, layer 6: "not evaluable at all until its prerequisite unbinding
## fires"). A caller that passes DUSK into a world with no sun gets the same answer as
## a caller that passes nothing.
##
## **A context is reusable.** It is a plain `RefCounted` with public fields precisely so
## a populated region can keep one per NPC and re-stamp it, rather than building one per
## bark per frame. `pool_key()` is built once and cached for exactly that reason - see
## its own doc, and `BarkService.request()`'s promise to allocate nothing.

## What kind of speaker this is.
var speaker_kind: BarkDefinition.SpeakerKind = BarkDefinition.SpeakerKind.AMBIENT_MINOR:
	set(value):
		speaker_kind = value
		_pool_key_dirty = true

## Which named NPC, when `speaker_kind` is `NAMED`. `&""` otherwise: an ambient Minor
## has no id and the Querent is not a person.
var speaker_id: StringName = &"":
	set(value):
		speaker_id = value
		_pool_key_dirty = true

## The speaker's suit (`Suit.Id`), or `Suit.UNKNOWN`. Half of how a crowd is read
## (§Named vs. ambient NPCs); the Querent has none.
var suit: int = Suit.UNKNOWN:
	set(value):
		suit = value
		_pool_key_dirty = true

## The speaker's Court rank (`NpcRank.Id`). The other half.
var npc_rank: int = NpcRank.Id.NONE:
	set(value):
		npc_rank = value
		_pool_key_dirty = true

## The region they are standing in.
var region_id: StringName = &"":
	set(value):
		region_id = value
		_pool_key_dirty = true

## The suit whose Renown a layer-5 line is measured against, or `Suit.UNKNOWN` to use
## the speaker's own.
##
## Normally the speaker's own - standing with Swords buys nothing in a Cups town, the
## same reading `EconomyService` makes of shop prices. The field exists for the case
## §Bark layers actually describes, "Renown tier for the Fool's **standing** suit": a
## scene where the suit being stood with is not the speaker's (a Coins factor greeting
## the Fool on behalf of a Cups house) can say so rather than mis-file the line.
var renown_suit: int = Suit.UNKNOWN

## True when Pip is close enough that a line to or about him would land.
##
## §Aware-of-Pip: Pip-directed lines are "texture... scattered lightly rather than
## universally - Pip is a recurring wonder, not a second protagonist NPCs address by
## default". So this OPENS a door and never forces one: a bark with `about_pip` is
## filtered out when Pip is not there, and nothing about this flag makes such a line
## more likely when he is.
var near_pip: bool = false

## The time of day the caller believes it is (`TimeBand.Id`), or `TimeBand.Id.NONE`.
## Advisory - see the class doc.
var time_band: TimeBand.Id = TimeBand.Id.NONE

## The weather the caller believes it is (`Weather.Id`). Advisory, same rule.
var weather: Weather.Id = Weather.Id.NONE

## The cached `pool_key()`, and whether one of the five fields it is built from has
## moved since it was built. See `pool_key()`.
var _pool_key: String = ""
var _pool_key_dirty: bool = true

## How many times `pool_key()` has actually built a string. A DIAGNOSTIC, and the only
## way the "`request()` allocates nothing" promise is observable from a test: a context
## re-asked a hundred times must still read 1. Nothing in the game reads it.
var _pool_key_builds: int = 0


## An ambient Minor of this suit and rank, standing here. The common case, in one call.
##
## THE SUIT IS REQUIRED, and `Suit.UNKNOWN` is refused rather than carried. Layer 7 is
## "**Generic** suit-culture baseline... Suit only... authored once per suit"
## (§Bark layers), so a suitless Minor is a speaker the evergreen floor cannot catch:
## every other layer could fall through and the request would come back empty, which
## §Bark layers says cannot happen ("the next layer down always has content, because
## layer 7 is mandatory and evergreen"). A crowd member with no suit is a caller bug,
## and it is made loud here rather than as a silent NPC three hours in.
static func ambient(
	of_suit: int, of_rank: int, in_region: StringName
) -> BarkContext:
	if of_suit < 0 or of_suit >= Suit.ALL.size():
		push_error("no such suit: %d" % of_suit)
		return null
	var context := BarkContext.new()
	context.speaker_kind = BarkDefinition.SpeakerKind.AMBIENT_MINOR
	context.suit = of_suit
	context.npc_rank = of_rank
	context.region_id = in_region
	return context


## A named NPC, standing here. Their suit and rank come off their profile, which
## `BarkService` looks up: a caller naming a person does not also describe them.
static func named(npc_id: StringName, in_region: StringName) -> BarkContext:
	var context := BarkContext.new()
	context.speaker_kind = BarkDefinition.SpeakerKind.NAMED
	context.speaker_id = npc_id
	context.region_id = in_region
	return context


## The Querent, speaking over this region. No suit, no rank, no memory.
static func querent(in_region: StringName) -> BarkContext:
	var context := BarkContext.new()
	context.speaker_kind = BarkDefinition.SpeakerKind.QUERENT
	context.suit = Suit.UNKNOWN
	context.npc_rank = NpcRank.ANY
	context.region_id = in_region
	return context


## The suit a layer-5 line is measured against for this speaker.
func standing_suit() -> int:
	return suit if renown_suit == Suit.UNKNOWN else renown_suit


## The key this speaker's recently-spent lines are remembered under.
##
## §Bark layers: "Each pool tracks recently-spent lines **per NPC (or per ambient
## context, for Minors sharing a pool)**". A named NPC is remembered as themselves; an
## ambient Minor is remembered as the description a crowd reads them by, which is
## exactly the granularity of the pool they draw from - two Knights of Swords in the
## same square share one pool and therefore share one no-repeat memory.
##
## **BUILT ONCE.** `BarkService.request()` asks for this on every call and a populated
## square makes several calls a second, so the string is cached and only rebuilt when
## one of the five fields it is made of moves (each of those fields has a setter that
## says so). A context that is re-stamped gets a new key; a context that is merely
## re-asked gets the same one back, with no allocation at all.
func pool_key() -> String:
	if _pool_key_dirty:
		_pool_key = _build_pool_key()
		_pool_key_builds += 1
		_pool_key_dirty = false
	return _pool_key


## How many times `pool_key()` has built its string. Diagnostic only: see
## `_pool_key_builds`.
func pool_key_builds() -> int:
	return _pool_key_builds


# --- Internals ---------------------------------------------------------------


func _build_pool_key() -> String:
	match speaker_kind:
		BarkDefinition.SpeakerKind.NAMED:
			return "NAMED|%s" % speaker_id
		BarkDefinition.SpeakerKind.QUERENT:
			return "QUERENT|%s" % region_id
	return "AMBIENT|%d|%d|%s" % [suit, npc_rank, region_id]
