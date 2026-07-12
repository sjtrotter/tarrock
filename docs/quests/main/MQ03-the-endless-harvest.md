---
id: MQ03
title: The Endless Harvest
type: main
status: outline
arcana: III. The Empress
region: The Bower
requires: []
fires: [WS_EMPRESS_UNBOUND]
---

# MQ03 — The Endless Harvest

## Introduction

The player pushes into the Bower expecting a garden and finds a horror wearing a
garden's face: wheat gone to the horizon and never cut, orchard boughs bowed low enough
to weep sap onto the road, air thick with rot-sweet honey. Somewhere at the heart of it
sits the Empress, grown through by three centuries of her own abundance and unable to
rise. The player's task is not to kill anything that wants killing — it is to prune.

## Beats

1. Arrival at the Bower's border: an old cart road, swallowed to the axles in unharvested
   wheat, marks where three centuries of "later" began.
2. The Fool meets a hungry Coins-culture family at a roadside stall — bursting granaries
   they cannot legally touch until the Empress's harvest is called, establishing the
   abundance-as-famine irony.
3. Approach step: borrowing a billhook from the family to cut a passable path through
   the swallowed road into the orchard interior.
4. Approach step: meeting Gaffer Nettle (proposed) mid-prune, an old orchardman who has
   spent decades hand-trimming the throne's briars out of devotion, and who warns the
   Fool off — "she doesn't take kindly to help."
5. Approach step: following the attendants' tribute-path through the canopy, dodging
   pollen-drunk Blanks bloated on three centuries of unharvested fruit.
6. Reading the stasis: the Fool reaches the Briar Throne — the Empress grown through by
   root and bramble, still smiling, still offering fruit from a hand she can't move.
7. The fight begins: pruning, not damage — sever the crown-roses feeding the throne while
   she counterattacks with lash-vines and drunken Blanks.
8. Each crown-rose cut opens the choking canopy overhead; the arena brightens and the
   fight's terrain changes with the light.
9. Between phases she thanks the Fool for each cut, and it visibly costs her to say it —
   gratitude for being hurt is not a metaphor she enjoys, and the game doesn't play it
   as one either.
10. Final crown-rose severed: real daylight reaches the Briar Throne for the first time
    since the Stall.
11. Unbinding: the throne splits open like a seedpod; her name returns to her mid-breath;
    she hands the Fool Trump III personally, already fussing over whether they've eaten.
12. Aftermath on the ground: the Bower's stranglevines recede, opening the throne room and
    interior groves; overnight, Gaffer Nettle's orchard drops its fruit all at once.
13. Closing: the hungry family from beat 2 gets their harvest call at last, mid-scene, as
    the Fool passes back out the way they came.

## Key NPCs

- **The Empress** (freed name TBD, `characters.md` §III) — loved the Bower into being
  and cannot stop; genuinely wounded that the Fool wants to change anything about it.
- **Gaffer Nettle** (proposed — promote to characters.md before script status) — an
  elderly orchardman who has hand-pruned the throne's briars for decades out of pure
  devotion, convinced it was working.

## Choices & branches

- No hard branch. Minor choice: whether the Fool accepts Gaffer Nettle's warning and
  waits for an invitation, or presses past him — changes only his opening line at the
  Throne and a small approach-time difference, not the fight.
- Optional beat: the Fool may share food with the hungry family in beat 2 before moving
  on; a small kindness flag for later bark variance, not gating anything.

## Mourning

**Gaffer Nettle** mourns the unbinding: the endless pruning was the only job he'd ever
had, and a throne that no longer needs tending leaves him holding shears with nothing
left to cut.

## [If CONFESSED] variants

- Her thanks between phases gain a second layer post-MQ13: she is not only pained to be
  helped, she now knows precisely what "help" like this eventually adds up to, and the
  line reads as grief rather than surprise.
- Gaffer Nettle's warning in beat 4 gains a line, if CONFESSED, admitting he's heard what
  the Fool's journey means and has decided to keep pruning anyway, "for as long as there's
  a garden to prune."
- The hungry family's gratitude in the closing beat is quieter, tinged with the knowledge
  that this harvest, unlike all the ones before it, is not guaranteed to repeat forever.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_EMPRESS_UNBOUND` | Harvests complete across the Spread; food prices halve; Bower stranglevines recede, opening its interior; famine sidequests resolve. |

## Consistency references

- `arcana.md` §III. The Empress — pruning-fight design, "thanks between phases", Trump III.
- `world.md` §The Bower — region sketch (overripe abundance as horror-lite).
- `world.md` §World-state matrix (`WS_EMPRESS_UNBOUND`) — exact world effects.
- `characters.md` §III. The Empress — personality, "child to fuss over" framing.
- `narrative.md` §Themes (1, 3) and §Act II (`CONFESSED` variants).

## Open questions

- The Empress's freed name (`characters.md` marks it TBD) needs to be set before script
  status — she speaks it aloud at the unbinding.
- Should Gaffer Nettle survive as a recurring Bower NPC after this quest (a candidate for
  a short side quest about learning a new trade), or is his arc complete here?
- Does the "double food prices halve" world-state need a visible price-tag/vendor UI beat
  in-quest, or is that purely a systemic change owned by economy design?
