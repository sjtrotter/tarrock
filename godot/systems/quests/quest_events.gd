class_name QuestEvents
extends RefCounted

## The domain events quests listen for, as constants.
##
## HAND-AUTHORED, unlike `QuestIds`: an event is a thing that happens in a scene, in
## combat or in dialogue, and only the quest graph that listens for it knows it
## exists. Scenes, combat and dialogue **raise** these on `QuestService`; they never
## write world state themselves (`docs/design/technical.md` §The WorldState service
## (Godot)). An event nobody listens for is ignored, silently and by design.
##
## Naming: `<QUEST>_<WHAT HAPPENED>`, past tense, describing the world rather than the
## quest's bookkeeping - `MQ00_BINDLE_TAKEN`, not `MQ00_ADVANCE_2`.
##
## Rounds add their quests' events here as they author graphs.

## MQ00 - The Leap (`docs/quests/main/MQ00-the-leap.md`). The tutorial morning on
## the Cliff, in the order its GAMEPLAY blocks put it.

## The Fool picked up the Bindle beside the dead campfire (§The High Meadow).
const MQ00_BINDLE_TAKEN := &"MQ00_BINDLE_TAKEN"

## The whittled wooden dog came out of the disturbed earth (§The Old Campsites).
##
## Raised by `scripts/the_cliff.gd` when the `Seekable` at the disturbed earth reports
## itself found - which is when PIP has dug it out, on the Fool's Seek command
## (`docs/design/combat.md` §Pip; the quest's own tutorial prompt is "call Pip's Seek
## command"). MQ00's graph only answers it from `BINDLE_TAKEN`, so the dig site is
## authored NOT one-shot and an early Seek is a dog digging a hole rather than a
## soft-lock.
const MQ00_KEEPSAKE_FOUND := &"MQ00_KEEPSAKE_FOUND"

## The Fool came close enough to the one dead thing on the plateau (§The Dead Tree).
const MQ00_DEAD_TREE_SEEN := &"MQ00_DEAD_TREE_SEEN"

## The three Blanks on the Waystation path are down (§The Waystation Approach).
##
## Raised by `scripts/the_cliff.gd` when the `Encounter` between the standing stones
## reports itself cleared - which is when every one of the three Twos has gone down,
## never when the Fool walks in. MQ00's graph is linear canon order and only answers
## it from `DEAD_TREE_SEEN`, so a player who clears the ambush first has the event
## LATCHED by the scene and re-raised the moment the quest can hear it; see
## `the_cliff.gd`'s `_report_ambush_if_cleared()`.
const MQ00_AMBUSH_CLEARED := &"MQ00_AMBUSH_CLEARED"

## The Fool rested at the Cliff's Waystation (§The First Waystation).
const MQ00_RESTED := &"MQ00_RESTED"

## The Fool reached the lip where the meadow stops (§The Cliff's Edge).
const MQ00_EDGE_REACHED := &"MQ00_EDGE_REACHED"

## The Fool stepped off the Cliff (§The Edge of the World) - the game's opening move.
const MQ00_LEAP := &"MQ00_LEAP"

## Every event any authored graph listens for, for tests and tooling.
const ALL: Array[StringName] = [
	MQ00_BINDLE_TAKEN,
	MQ00_KEEPSAKE_FOUND,
	MQ00_DEAD_TREE_SEEN,
	MQ00_AMBUSH_CLEARED,
	MQ00_RESTED,
	MQ00_EDGE_REACHED,
	MQ00_LEAP,
]
