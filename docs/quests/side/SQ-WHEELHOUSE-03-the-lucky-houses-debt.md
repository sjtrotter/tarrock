---
id: SQ-WHEELHOUSE-03
title: The Lucky House's Debt
type: side
status: outline
arcana: none
region: The Wheelhouse
requires: []
fires: []
---

# SQ-WHEELHOUSE-03 — The Lucky House's Debt

## Introduction

On the eternally-lucky side of the Wheelhouse, Ostentation Pryce has lived three hundred
spectacular years entirely on credit, serenely certain that a luck which never runs out
never has to be repaid — and, technically, until the Wheel started threatening to turn, he
was right. This is a pre-turn quest: while the Wheel is still stopped, the mere *rumor*
that fortune might become real has done what three centuries of luxury never could, and
frightened him. The Fool can help him quietly square three hundred years of debt before
the wheel catches up with him, or back his instinct to gamble on his luck holding one more
day. It is dry, funny, and a little cruel, which is to say it is a very good Wheelhouse
story.

## Beats

1. **The hook.** In a gilded, quietly crumbling townhouse built entirely on IOUs, Pryce
   (canon, `characters.md` §Regional named NPCs)
   receives the Fool in a state of elegant panic. Word travels of unbindings elsewhere and
   of a Wheel that might spin; his creditors — all lucky-siders too, who never once pressed
   because everyone assumed luck simply held — are beginning to do sums.
2. **The complication.** Settling means one of two humiliations Pryce can barely face: a
   genuine reckoning, selling down absurd luxuries that (being lucky) keep landing him
   *more*; or staking everything on one last enormous wager that his luck lasts a day
   longer. His whole self was built on never having to choose.
3. **The inventory.** The Fool helps tally the debt — a comic tour of three centuries of
   never paying: a tab at every parlor, a "temporary" loan older than most families, a
   house whose deed is itself an unredeemed marker. Every entry is funnier and sadder than
   the last.
4. **The choice.** Help Pryce quietly settle — sell down, square accounts, the un-lucky
   and honest road — or back his final bet: stake him, coach him, or simply witness it. No
   combat, no wrong answer; the Wheelhouse doesn't grade you, it just deals.
5. **The ache and the laugh.** Theme 1 lands sideways: a luck that couldn't run out was
   never luck, it was a sentence, and the terror of the coming turn is the first real stake
   Pryce has felt in three hundred years — and he is, absurdly, almost grateful for it. The
   laugh: he insists on tipping the Fool with an IOU. The honest beat: he admits, without
   the flourish, that winning forever got very lonely.
6. **Closing beat.** Pryce's barks shift to match his choice — chastened-and-solvent, or
   still gloriously in hock and pretending otherwise. No `WS_*` flag is set.
7. **[If WS_FORTUNE_UNBOUND already: the window has closed.]** If the Fool unbinds the
   Wheel before finding Pryce, the choice is gone — the first real roll already made or
   unmade him. The quest becomes a short coda: the Fool meets a man either newly ruined or
   improbably, terrifyingly still-lucky, discovering for the first time that a roll can go
   the other way.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (settle or gamble) | none — NPC-level only | Pryce's barks and household shift per the chosen route; no `WS_*` flag is set. |

## Consistency references

- `world.md` §The Wheelhouse — the eternally-lucky side, absurd fortune, and the frozen
  Wheel whose turning is the threat hanging over the whole quest.
- `world.md` §World-state matrix (`WS_FORTUNE_UNBOUND`) — the coming change Pryce dreads;
  the `[If WS_FORTUNE_UNBOUND already]` coda handles the player who unbinds first.
- `characters.md` §The Minors: suit-cultures — Coins row informs the creditor culture and
  Pryce's own gilded patter (a bad Coins man is still a Coins man).
- `narrative.md` §Themes 1 (endings are a mercy; a thing that cannot lose was never truly
  playing) and §Dialogue style guide (one honest beat in the comedy; Fool lines ≤ 12 words
  with an earnest option).
- `progression.md` §Currency, §Renown — modest coins (a finder's cut if you help him
  settle); a sharp settlement bargain reads as Coins-shrewd (Renown up), a purely generous
  bailout as Cups-warm.

## Open questions

- Should backing Pryce's "final bet" have a diegetic outcome the player can influence (a
  card game, a die roll) or resolve entirely in narration? Recommend a single symbolic roll
  the player triggers but cannot rig — thematically correct for the Wheel.
- Confirm this quest is intended as a hard pre-turn window with only the coda afterward, or
  whether the coda should be fleshed to a full second route at script status.
