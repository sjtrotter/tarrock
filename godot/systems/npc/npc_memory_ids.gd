class_name NpcMemoryIds
extends RefCounted

## The vocabulary of things a NAMED NPC can remember about the Fool.
##
## HAND-AUTHORED. `docs/design/npc-system.md` §Named vs. ambient NPCs gives the shape
## and not the list: a named NPC's memory is "a small flag set recording notable
## dealings with the Fool (helped/wronged them, quest outcomes that touched them,
## whether they've met the Fool at all)". These four are that sentence, minted as ids;
## the quest-outcome memories are per-NPC and belong to the quest that causes them,
## which is why `NpcProfile.memory_flags_known` is a per-NPC vocabulary rather than
## this list being the whole of it.
##
## Stored in `WorldStateService.npc_memory` (round 2), which is where they persist and
## which already carries `SAW_THE_SHOW_END` in the checked-in save fixture. They are
## NOT `WS_*` flags: `world.md`'s matrix is the world's memory and this is one
## person's, "scoped deliberately, since it's per-NPC save data".

## This NPC has met the Fool at all. The floor of every other memory.
const MET_THE_FOOL := &"MET_THE_FOOL"

## The Fool did this NPC a good turn.
const HELPED := &"HELPED"

## The Fool wronged this NPC.
const WRONGED := &"WRONGED"

## Flick was there when the Troupe's show ended (MQ01). A quest-outcome memory, and
## the one already written into `res://tests/fixtures/saves/v1_played.json`.
const SAW_THE_SHOW_END := &"SAW_THE_SHOW_END"

## The three memories any named NPC may hold. `SAW_THE_SHOW_END` is deliberately out:
## it is one quest's outcome and belongs to the profiles that name it.
const UNIVERSAL: Array[StringName] = [MET_THE_FOOL, HELPED, WRONGED]
