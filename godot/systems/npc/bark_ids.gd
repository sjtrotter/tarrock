class_name BarkIds
extends RefCounted

## Every shipped bark, as a constant.
##
## HAND-AUTHORED, one per `.tres` under `res://data/npc/barks/`. `npc-system.md`
## §Consistency note is explicit that the system doc "owns **no line of dialogue and
## no specific pool**" - bark content is authored per region in that region's quest
## docs' BARKS sections, and eventually in a `barks/` content folder - so this list
## grows a region at a time as those sections are lifted, and it is short today on
## purpose.
##
## Today it is the Cliff's four idle lines and nothing else, because the Cliff's BARKS
## section (`docs/quests/main/MQ00-the-leap.md` §BARKS - The Cliff) is the only bark
## content any shipped doc holds. Everything else the system can do is proved against
## synthetic catalogs in `res://tests/unit/npc/`, which is where a made-up line
## belongs.
##
## Code never types a bark id: it names one of these, or reads one off a
## `BarkDefinition`.

## The Querent's four idle lines on the Cliff, in the order MQ00's Random Lines block
## writes them. `SpeakerKind.QUERENT`, layer 7, region `CLIFF`.
const CLIFF_QUERENT_IDLE_01 := &"BARK_CLIFF_QUERENT_IDLE_01"
const CLIFF_QUERENT_IDLE_02 := &"BARK_CLIFF_QUERENT_IDLE_02"
const CLIFF_QUERENT_IDLE_03 := &"BARK_CLIFF_QUERENT_IDLE_03"
const CLIFF_QUERENT_IDLE_04 := &"BARK_CLIFF_QUERENT_IDLE_04"

## The Cliff's whole idle pool, in doc order.
const CLIFF_QUERENT_IDLE: Array[StringName] = [
	CLIFF_QUERENT_IDLE_01,
	CLIFF_QUERENT_IDLE_02,
	CLIFF_QUERENT_IDLE_03,
	CLIFF_QUERENT_IDLE_04,
]
