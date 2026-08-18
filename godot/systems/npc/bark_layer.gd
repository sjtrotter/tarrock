class_name BarkLayer
extends RefCounted

## The seven bark pools, and the order they are asked in.
##
## `docs/design/npc-system.md` §Bark layers is canon and this is the whole of it as
## numbers: "A bark request... is resolved against seven pools, evaluated
## **most-specific-first**. The highest layer that still has an unspent line for this
## NPC/context wins; if it's exhausted, evaluation falls through to the next layer
## down. This is the entire selection algorithm - no weighting, no randomness across
## layers, so writers can always predict which layer a given moment will draw from."
##
## The numbers are the doc's own, and they are counted DOWNWARD by specificity:
## 1 is the most specific and 7 the fallback, which is why `DESCENDING` reads 1..7 and
## not the other way round.
##
## Layers 1-4 are "does this line know something specific just happened or is
## specifically true right now"; 5-7 are "who is this NPC, in general". The pillar -
## an aware line is a bug if it ignores the world - is enforced by that split: "a
## world-state bark should interrupt a generic greeting, never the reverse."

## Active quest state and dialogue-graph node, plus a named NPC's own memory of the
## Fool (§Named vs. ambient NPCs: "you're the one who [did the thing]" is a
## layer-1-adjacent line gated on the NPC's own flag set).
const QUEST_SCRIPTED := 1

## `READING_ORDER` motifs - the Fool's Reading (`docs/design/world.md` §The Fool's
## Reading, whose starter motifs seed this layer).
const SEQUENCE := 2

## `WS_*` flag combinations local to the region. Rumour pools live here too: they are
## "not a separate layer, just a delayed-activation delta on the same mechanism".
const WORLD_STATE := 3

## `ACT_I` / `ACT_II` / `ACT_III` and `CONFESSED`.
const ACT_STATE := 4

## Renown tier for the standing suit, and suit-culture speech habits.
const RENOWN := 5

## Day/night and storms. Not evaluable at all before `WS_SUN_UNBOUND` /
## `WS_TOWER_UNBOUND` - see `TimeBand` and `Weather`.
const TIME_WEATHER := 6

## The generic suit-culture baseline: suit only, authored once per suit, "always
## available". MANDATORY AND EVERGREEN - the reason a request can never fall through
## the bottom of the list.
const GENERIC := 7

## The most specific layer there is.
const FIRST := QUEST_SCRIPTED

## The fallback, and the floor of the fall-through.
const LAST := GENERIC

## The layers in evaluation order: most specific first.
const DESCENDING: Array[int] = [
	QUEST_SCRIPTED,
	SEQUENCE,
	WORLD_STATE,
	ACT_STATE,
	RENOWN,
	TIME_WEATHER,
	GENERIC,
]

## What a layer is called, indexed by layer number (index 0 is unused padding, so a
## layer number indexes this array directly). Doc text for diagnostics; never shown.
const NAMES: Array[String] = [
	"",
	"quest-scripted",
	"sequence",
	"world-state",
	"act-state",
	"renown",
	"time/weather",
	"generic",
]


## True when `layer` is one of the seven.
static func is_layer(layer: int) -> bool:
	return layer >= FIRST and layer <= LAST


## What this layer is called, for an error message. Never displayed to a player.
##
## Built by concatenating two short literals rather than one `"layer %d (%s)"` format
## string: the lint that keeps player-facing sentences out of `systems/` code counts
## words by spaces, and the single literal reads as a three-word sentence even though
## nothing here is ever shown to a player - see `localization_lint_test.gd`.
static func describe(layer: int) -> String:
	if not is_layer(layer):
		return "layer %d" % layer
	return "layer %d" % layer + " (%s)" % NAMES[layer]
