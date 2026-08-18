class_name DialogueIds
extends RefCounted

## Every dialogue graph id, as a constant.
##
## HAND-AUTHORED, unlike `QuestIds`: a graph is prose lifted out of a quest script
## by a person (`docs/design/technical.md` §Generated vs. hand-authored), so the ids
## are written here beside the `.tres` files they name. Code never types a graph id -
## scenes name one of these constants.
##
## Naming: `<QUEST>_<BEAT>`, one id per beat of the script, in script order.

## MQ00 - The Leap (`docs/quests/main/MQ00-the-leap.md`), in the order the script
## plays its beats.

## INT./EXT. VOID: Black Screen - the two lines dealt over a black screen, before
## the Cliff exists. Owned by the opening cut scene, not by the region.
const MQ00_WAKE := &"MQ00_WAKE"

## EXT. THE CLIFF: The High Meadow - "Go on, then", once the Bindle is taken.
const MQ00_MEADOW := &"MQ00_MEADOW"

## EXT. THE CLIFF: The Old Campsites - the Querent on everyone who woke here before.
const MQ00_CAMPSITES := &"MQ00_CAMPSITES"

## EXT. THE CLIFF: The Old Campsites - "Someone made that", when Pip brings the
## whittled wooden dog back. Chains into `MQ00_WOODEN_DOG`.
const MQ00_KEEPSAKE_GIVEN := &"MQ00_KEEPSAKE_GIVEN"

## CHOICE DIALOG - the wooden dog *(all questions may be exhausted)*.
const MQ00_WOODEN_DOG := &"MQ00_WOODEN_DOG"

## EXT. THE CLIFF: The Dead Tree - the one thing up here that dies.
const MQ00_DEAD_TREE := &"MQ00_DEAD_TREE"

## EXT. THE CLIFF: The Waystation Approach - the Querent mid-fight, easy.
const MQ00_WAYSTATION_AMBUSH := &"MQ00_WAYSTATION_AMBUSH"

## EXT. THE CLIFF: The Waystation Approach - the cards drifting off to new Blanks.
const MQ00_WAYSTATION_CLEARED := &"MQ00_WAYSTATION_CLEARED"

## EXT. THE CLIFF: The First Waystation - what a Waystation is, on the first rest.
const MQ00_WAYSTATION_REST := &"MQ00_WAYSTATION_REST"

## EXT. THE CLIFF: The First Waystation - the Random Lines for resting again.
const MQ00_WAYSTATION_REST_AGAIN := &"MQ00_WAYSTATION_REST_AGAIN"

## CHOICE DIALOG - questions at the edge *(all questions may be exhausted)*, with
## the four follow-up threads and the closing line at `[All versions pick up here:]`.
const MQ00_EDGE_QUESTIONS := &"MQ00_EDGE_QUESTIONS"

## EXT. THE CLIFF: The Edge of the World - the whole method, after Pip jumps.
const MQ00_LEAP_BEFORE := &"MQ00_LEAP_BEFORE"

## The skydive over the Spread, and Flick's first line off the haywain.
const MQ00_LANDING := &"MQ00_LANDING"

## Every authored graph id, in script order.
const ALL: Array[StringName] = [
	MQ00_WAKE,
	MQ00_MEADOW,
	MQ00_CAMPSITES,
	MQ00_KEEPSAKE_GIVEN,
	MQ00_WOODEN_DOG,
	MQ00_DEAD_TREE,
	MQ00_WAYSTATION_AMBUSH,
	MQ00_WAYSTATION_CLEARED,
	MQ00_WAYSTATION_REST,
	MQ00_WAYSTATION_REST_AGAIN,
	MQ00_EDGE_QUESTIONS,
	MQ00_LEAP_BEFORE,
	MQ00_LANDING,
]
