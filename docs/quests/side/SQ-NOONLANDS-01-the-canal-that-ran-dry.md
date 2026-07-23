---
id: SQ-NOONLANDS-01
title: The Canal That Ran Dry
type: side
status: outline
arcana: none
region: The Noonlands
requires: []
fires: []
---

# SQ-NOONLANDS-01 — The Canal That Ran Dry

## Introduction

The Noonlands blame the drought creeping in at their western edge on the Sun himself —
three centuries of noon burning the fields dry from overhead. It is the obvious story,
and it is wrong. This is a walking-and-looking quest with no fight in it: the Fool (and
Pip's nose) follow the region's one irrigation canal upstream against the grain of the
region's proudest complaint, and find the real culprit is a stone that fell before the
Stall and was never cleared, because nothing here needs clearing when nothing here can
change. Clearing it doesn't cure the Noonlands. It saves one farm, now, honestly — which
is the whole point.

## Beats

1. **The hook.** Farmer Thatch Corley (characters.md §Regional named NPCs), whose
   western fields are browning while the rest of the Noonlands still stands gold, is sure
   the sun is finally burning his land to nothing. He's half-resigned, half-furious, and
   entirely certain there's nothing a mortal can do about a nailed-up sky.
2. **Reading the land as land.** The Fool walks the canal upstream. Per world.md's
   hydrology rule, the water begins high and should flow all the way down — but the
   channel runs dry partway along, well short of Thatch's fields, with dust where a
   current should be.
3. **The find.** At the dry break sits a collapsed culvert, silted solid for three
   hundred years. Pip digs it out. The drought at Thatch's farm was never the sky; it was
   a blocked pipe nobody fixed, because in a stopped world a slow problem never gets
   worse enough to force the shovel.
4. **The work.** A short, physical clearing task — shift the fallen stone, break the silt
   plug, re-set the channel. Water rejoins the lower canal and runs, visibly, down to the
   western fields for the first time in living memory.
5. **The ache and the laugh.** Thatch is flooded with relief and a little mortified — 300
   years cursing the heavens over a clogged culvert. The honest beat: the Noonlands' wider
   drought *is* real and this fixes none of it; one farm is saved, not a region. The
   laugh: Thatch, dry as any Coins man, allows that it's a comfort to finally have a
   trouble a body can *mend with a shovel*, for once.
6. **`[If WS_SUN_UNBOUND]`.** With the first sunset come and the region cooling, the
   broader drought is already lifting on its own (world.md §matrix — the Sun's unbinding
   resolves the drought sidequests). The culvert is still physically blocked and still
   worth clearing — reframed now as restoration for the seasons ahead rather than rescue
   from ruin, and Thatch's relief is calmer, less desperate.
7. **Closing beat.** Thatch's field greens at the edges; his barks shift from doom to a
   grudging, grateful practicality. A modest reward: coins and a lift of Coins Renown for
   doing right by the plains-folk with honest work.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | Thatch's western field recovers; his barks soften from fatalism to practicality; no `WS_*` flag is set, and no other quest reads this outcome. |

## Consistency references

- `design/world.md` §The Noonlands — the region's cheerful-surface drought, the fields,
  the blamed-upon nailed noon.
- `design/world.md` §Hydrology rule — waterways begin high, flow down, end somewhere
  real; the canal puzzle is built on and rewards exactly this rule.
- `design/world.md` §World-state matrix (`WS_SUN_UNBOUND`) — the Sun's unbinding
  resolves the Noonlands' drought sidequests, which this quest is one of.
- `design/characters.md` §Regional named NPCs — Thatch Corley (being promoted in the
  parallel change); §Pip — Pip's nose as the diegetic search tool.
- `design/narrative.md` §Dialogue style guide — the melancholy rule (one honest beat in
  the comic relief); Fool lines kept ≤ 12 words.
- `design/progression.md` §Renown — Coins Renown for honest work on the plains; §Currency
  — modest coin reward.

## Open questions

- Should completing the culvert clearing flip whatever internal flag `WS_SUN_UNBOUND`
  reads as a "drought sidequest resolved," so the region doesn't later auto-resolve a
  quest the player already finished by hand? (Recommend yes — a per-farm resolution the
  Sun's unbinding can safely no-op.)
- Exact reward tuning (coin amount, Renown tier movement) — a content-pass decision.
