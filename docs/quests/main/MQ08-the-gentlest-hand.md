---
id: MQ08
title: The Gentlest Hand
type: main
status: outline
arcana: VIII. Strength
region: The Maw
requires: []
fires: [WS_STRENGTH_UNBOUND]
---

# MQ08 — The Gentlest Hand

## Introduction

The player climbs into the Maw expecting the game's wilds region to test them with
claws and crags, and it does — but the quest's real lesson arrives at the top of the
climb, where a woman has held a lion's jaws open for three centuries, not by force but
by patience, and asks the Fool for the one thing nobody has offered her since the Stall:
a turn. The fight that follows is won by calm, not damage.

## Beats

1. Arrival at the Maw's border: savage limestone highlands, hunting camps, vertical
   crags, the wilds-region houses a whole culture of monster hunts and taming.
2. The Fool meets Coz Yarrow (proposed), a hide-hunter working the border camps, who
   explains the local trade — and points out the tableau on the far ridge: a woman,
   frozen, holding a lion's jaws.
3. Approach step: a spooked mountain cat blocks a narrow crag path — the tutorial for
   "gentleness prompts," where the wrong input (attacking) makes everything worse.
4. Approach step: the Fool finds Coz Yarrow's cull-trap set for a wounded bear and
   chooses to free it gently rather than fight past the hunters guarding it — mercy
   over force, made mechanical, and it visibly annoys Coz Yarrow.
5. Approach step: the final climb to the tableau itself, past older, cruder shrines
   left by pilgrims who came only to look.
6. Reading the stasis: up close, her exhaustion shows — empty hands would shake, if she
   could move them. She speaks (no personal name, no "I") and asks one thing: hold it
   for me.
7. The encounter, exactly per `arcana.md` §VIII: a grapple-duel with the lion — stamina
   wrestling, break-away timing, gentleness prompts where attacking is the mistake.
   Damage is not the win condition; calm is.
8. She watches with empty hands for the first time in three hundred years, and it is
   nearly worse for her than the holding was.
9. The lion settles. Calm holds.
10. Unbinding: the office cracks; her name returns to her mid-breath; she hands the
    Fool Trump VIII personally, and touches the lion's mane once, like a goodbye.
11. Aftermath: wild beasts across the Spread turn neutral-until-provoked; the lion
    becomes a roaming, friendly landmark; Maw hunts change from cull to rescue.
12. Mourning: Coz Yarrow's trade empties overnight — there is nothing left in the Maw
    that needs culling.
13. Closing beat: the Fool passes Coz Yarrow on the road days later, spear still on his
    back, unslung, watching the lion amble by without reaching for it. He doesn't say
    why. Neither does the game.

## Key NPCs

- **Strength** (freed name Maud, `characters.md` §VIII) — has held the lion through
  patience alone for 300 years; regards the Fool as someone who doesn't yet understand
  that mercy can be exhausting.
- **The Lion of the Maw** (canon, `characters.md`) — a beast, not a talker; becomes a
  recurring friendly landmark after unbinding.
- **Coz Yarrow** (proposed — promote to `characters.md` before script status) — a
  hide-hunter whose livelihood is culling; this quest's mourning NPC.

## Mourning

**Coz Yarrow** mourns the unbinding: culling was his whole trade, and a Maw where
beasts are neutral until provoked leaves him with a spear and no reason to carry it.

## [If CONFESSED] variants

- Strength's request in beat 6 gains a resigned undertone: she already senses larger
  endings are coming, and is glad to lay this one down before the rest arrive.
- Coz Yarrow's mourning bark (beat 12) shifts — he's heard what the Fool's journey
  means, and half-jokes that at least the beasts get to go first.
- Coz Yarrow's introduction (beat 2) gains a line acknowledging the Fool's growing
  reputation, delivered as wary respect rather than simple welcome.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_STRENGTH_UNBOUND` | Wild beasts world-wide become neutral-until-provoked; the lion becomes a roaming friendly landmark; Maw hunts change from cull to rescue. |

## Consistency references

- `arcana.md` §VIII. Strength — grapple-duel design, gentleness prompts, Trump VIII.
- `world.md` §The Maw — region sketch (wilds-region: monster hunts, taming, vertical crags).
- `world.md` §World-state matrix (`WS_STRENGTH_UNBOUND`) — exact world effects.
- `characters.md` §VIII. Strength; §Recurring named NPCs (The Lion of the Maw).
- `narrative.md` §Themes (1, 2, 3), §Act II (`CONFESSED` variants).

## Open questions

- Should Coz Yarrow recur as a Maw side-quest NPC learning the rescue trade, or is his
  arc complete at this quest's closing beat?
- The exact gentleness-prompt input scheme (timing window vs. hold-and-release) needs
  confirmation from `combat.md`/`progression.md` before script status.
