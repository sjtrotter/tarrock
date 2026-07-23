---
id: MQ06
title: The Longest Engagement
type: main
status: outline
arcana: VI. The Lovers
region: The Divide
requires: []
fires: [WS_LOVERS_UNBOUND]
branches:
  - [WS_DIVIDE_EASTMARRIED, WS_DIVIDE_WESTMARRIED]
---

# MQ06 — The Longest Engagement

## Introduction

The player reaches the Divide, a canyon splitting two towns that have glared at each
other across an unfinished bridge for 300 years — joined by an engagement that was
never sealed. Every ferryman has an opinion about whose fault that is. At the bridge's
broken end wait the Betrothed, one duelist from each town, locked in a fight the Fool
cannot win with a weapon: the standstill only breaks when someone finally answers the
question the whole canyon has been refusing to ask. That someone is the Fool, and the
answer is permanent.

## Beats

1. Arrival at the Divide: two towns visible across a canyon, an unfinished bridge frozen
   mid-span, wedding bunting faded to the color of old bone on both sides.
2. Meet Ferryman Pell (canon, `characters.md` §Regional named NPCs), who rows the Fool across and gossips freely about both
   families and the ancient non-wedding, taking no side and enjoying every side of it.
3. Approach step: visiting the East town, meeting an elder of the bride's household who
   makes the case for their claim and their grief.
4. Approach step: visiting the West town, meeting an elder of the groom's household,
   making the opposite case with equal weight.
5. Approach step: reaching the bridge's broken end via a rope-and-scaffold traversal over
   the gorge, since no path there has been finished either.
6. Reading the stasis: the Betrothed stand at the bridge's edge in wedding clothes worn
   for 300 years, perfectly mirrored, unable to be harmed while mirrored.
7. The fight begins: attacking either duelist harms neither; separating them by terrain,
   tethers, or timing only makes them re-mirror, because the alternative is choosing.
8. Realization beat: damage cannot win this fight; the standstill itself forces open the
   choice dialog the canyon has avoided for three centuries.
9. CHOICE — the wedding happens East or West (see Choices & branches; both options ache).
10. The answer lands as the killing blow: the instant it is spoken, the mirror shatters.
11. Unbinding: the office cracks in both Betrothed at once; their names return to them in
    the same breath; together, they hand the Fool Trump VI.
12. Aftermath on the ground: the bridge completes overnight; foot and cart traffic replace
    the ferry; the losing town's grief plays out in a concrete scene (an empty chapel, an
    unlit hearth, a family packing to move across the canyon).
13. Mourner beat: Ferryman Pell watches his trade end with the ferry's obsolescence.
14. Closing: the Fool crosses the finished bridge on foot, the first person ever to do so.

## Key NPCs

- **The Lovers / the Betrothed** (freed names Elsbeth and Wystan, `characters.md` §VI) — two people
  frozen before a choice neither could make; three centuries of nearly-deciding turned
  devotion into an exquisite cowardice.
- **Ferryman Pell** (canon, `characters.md` §Regional named NPCs) — the
  Divide's neutral gossip and go-between, ferrying both towns' business for longer than
  either town's living memory reaches.

## Choices & branches

**CHOICE — the wedding happens East or West** *(first pick commits; confirm prompt)*

| Choice | Consequence |
|---|---|
| East | `WS_DIVIDE_EASTMARRIED`. The bride's family keeps her; their sea-facing chapel, blessed by generations of the town's own dead, finally rings its bell. But the groom leaves his family seat and title behind entirely, and the West town loses the wedding it spent 300 years preparing to host — its ancestral hall stands empty, its own dead unhonored by the ceremony they were owed. |
| West | `WS_DIVIDE_WESTMARRIED`. The groom's household finally hosts the ceremony its lineage was built around; the West town's long vigil ends in its own hall. But the bride leaves her home, her family's chapel by the sea falls permanently silent, and the East town — poorer, and counting on the wedding's trade and pilgrimage — loses the one thing it had left to look forward to. |

Both options are written to ache: whichever town "wins" the wedding still loses a
person, and whichever town "loses" still loses a future it had planned its whole
identity around.

## Mourning

**Ferryman Pell** mourns the unbinding: the bridge that finally lets the two towns meet
also ends the one trade — and the one vantage on both towns' business — that gave his
life its shape.

## [If CONFESSED] variants

- The Betrothed's framing of the Fool as "unwelcome witness" sharpens post-MQ13: they
  now know precisely what kind of ending a Fool who finishes their journey brings, and
  their reluctance to choose gains a second, heavier meaning.
- Ferryman Pell's gossip in the approach beats includes rumors of the Fool's true
  purpose, delivered as his usual dry aside rather than alarm.
- The family elders' pleas in beats 3–4 gain urgency if CONFESSED — pushing the Fool to
  decide "now, while there's still time for a wedding at all."

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion, East choice | `WS_LOVERS_UNBOUND`, `WS_DIVIDE_EASTMARRIED` | The Divide is bridged; the towns unite around the East chapel; ferry traffic replaced by bridge traffic. |
| Quest completion, West choice | `WS_LOVERS_UNBOUND`, `WS_DIVIDE_WESTMARRIED` | The Divide is bridged; the towns unite around the West hall; ferry traffic replaced by bridge traffic. |

## Consistency references

- `arcana.md` §VI. The Lovers — mirrored-duelist fight design, forced-choice unbinding, Trump VI.
- `world.md` §The Divide — region sketch (two towns, unfinished bridge, gossiping ferrymen).
- `world.md` §World-state matrix (`WS_LOVERS_UNBOUND`, branch flags) — exact world effects.
- `characters.md` §VI. The Lovers — personality, "unwelcome witness" framing.
- `narrative.md` §Themes (1, 3) — "both options must ache" is this quest's core brief.

## Open questions

- Should the East/West elders (beats 3–4) be new named NPCs of their own, or should
  Ferryman Pell's gossip stand in for their case to keep the NPC budget to one proposal?
  Current draft assumes unnamed elders to stay within the 1–2 new NPC guidance.
- Does either branch have downstream side-quest hooks (e.g., the losing town's elder
  seeking the Fool out later), or does this quest's ache stand alone?
