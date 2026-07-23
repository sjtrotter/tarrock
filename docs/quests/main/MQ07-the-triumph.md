---
id: MQ07
title: The Triumph
type: main
status: outline
arcana: VII. The Chariot
region: The Longroad
requires: []
fires: [WS_CHARIOT_UNBOUND]
---

# MQ07 — The Triumph

## Introduction

The player reaches the Longroad, the great ring-causeway circling the Axis, and finds
a war-train still marching a triumph three centuries after its war ended: banners
bleached, trumpets dented, momentum long since curdled past the point of meaning
anything. To unbind the Chariot the Fool must catch the procession, board it at a
gallop, and fight the length of it — not to defeat the Charioteer, but to reach his
hands and take the reins.

## Beats

1. Arrival at the Longroad: the ring-causeway stretches in both directions, and in the
   distance the war-train's dust cloud circles the Axis exactly as it has for 300 years.
2. Meet Corporal Pike (canon, `characters.md` §Regional named NPCs), a marching soldier resting at a toll-fort, who
   explains: the procession never stops, never arrives, and no one marching it remembers
   what it won.
3. Approach step: a chase along the causeway on foot — cutting switchbacks, vaulting
   toll-gates — to catch the procession's tail before it passes the toll-fort entirely.
   (No mounts exist before this quest; the Chariot IS the game's first mount.)
4. Approach step: timing a leap onto the moving train from a toll-fort's gate-arm,
   narrowly missing on the first attempt before catching a rigging line on the second.
5. Reading the stasis while boarding: banners bleached white, trumpets dented past tune,
   parade-armored Blanks patrolling the carriage roofs on a march with nowhere left to go.
6. The fight begins: battling up the train's length — carriage roofs, banner rigging,
   parade-armored Blanks — toward the Charioteer at the head of the procession.
7. The Charioteer fights one-handed, reins gripped fast in the other; the fight is as
   much about closing distance against a moving target as it is about damage.
8. Realization beat: he cannot be defeated outright by the sword; the only way through
   is to seize the reins directly from his one free hand.
9. Taking the reins: a sustained pull against the procession's own three centuries of
   momentum, an escalating tug that the Fool only barely wins.
10. The halt: dust settling, banners folding, three centuries of momentum dying in one
    long skid down the causeway.
11. Unbinding: the office cracks mid-skid; his name returns to him with the train still
    moving; he hands the Fool Trump VII personally, reins still warm in both their hands.
12. Aftermath on the ground: the Waystation network activates as fast travel across the
    Spread; the Chariot answers as a summonable mount via Trump VII's Past slot
    (`arcana.md` §VII); the first merchant caravan in three centuries rolls safely down
    the now-quiet Longroad.
13. Mourner beat: Widow Tallow's roadside inn, built entirely around feeding a parade
    that will never pass her door again, stands unnervingly quiet for the first time.
14. Closing: Corporal Pike, still standing at his toll-fort, salutes a war that has
    finally, formally, ended.

## Key NPCs

- **The Chariot** (freed name Cassian, `characters.md` §VII) — once the Longroad's
  conquering hero, quietly horrified at how long "just a little further" has lasted.
- **Corporal Pike** (canon, `characters.md` §Regional named NPCs) — a
  weary marching soldier who has served the endless procession so long he no longer
  remembers what victory it was meant to be celebrating.
- **Widow Tallow** (canon, `characters.md` §Regional named NPCs) — keeper
  of a roadside inn whose entire trade was built on feeding and housing the eternal
  procession's marchers.

## Choices & branches

- No hard branch. Minor choice: the Fool can spend a beat encouraging Corporal Pike to
  finally leave his post in the closing scene, or leave him to decide on his own —
  colors his closing line, no mechanical effect.

## Mourning

**Widow Tallow** mourns the unbinding: new caravans will come down the safe road
eventually, but the specific parade she built her life around — the marching band every
evening, the same weary faces at her door — is gone the moment the procession halts.

## [If CONFESSED] variants

- The Chariot's quiet horror, per `characters.md`, becomes explicit post-MQ13: he
  already knows the Fool is "the only soldier still capable of stopping" in both the
  literal and cosmic sense, and says so once the reins are taken.
- Corporal Pike's weary bark shifts from resigned to grateful-and-afraid — relieved the
  march is over, unsettled by what its ending is part of.
- Widow Tallow's mourning line, if CONFESSED, acknowledges she knows exactly why the road
  is closing to her particular parade, and grieves it with open eyes rather than surprise.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_CHARIOT_UNBOUND` | Procession ends; Waystation fast travel activates; Chariot mount granted; Longroad becomes a safe trade route with merchant caravans spawning. |

## Consistency references

- `arcana.md` §VII. The Chariot — moving-train chase/fight design, "take the reins" unbinding, Trump VII.
- `world.md` §The Longroad — region sketch (procession, toll-forts, Waystation network).
- `world.md` §World-state matrix (`WS_CHARIOT_UNBOUND`) — exact world effects, incl. fast travel.
- `characters.md` §VII. The Chariot — personality, "recruit, then only soldier" framing.
- `narrative.md` §Themes (1, 3) and §Act II (`CONFESSED` variants).

## Open questions

- Encounter tier is L (setpiece) per `arcana.md` — does the "take the reins" tug-of-war need
  its own bespoke input rig, or can it reuse an existing QTE/grapple system from another
  Trump (e.g. Bargain's chain-tether) for scope?
- Should Widow Tallow's inn get a small post-quest bark update reflecting new caravan
  trade, to soften (not resolve) her mourning per the "don't resolve them" theme rule?
