---
id: SQ-BOWER-03
title: The Hoarder's Ledger
type: side
status: outline
arcana: none
region: The Bower
requires: [WS_EMPRESS_UNBOUND]
fires: []
---

# SQ-BOWER-03 — The Hoarder's Ledger

## Introduction

For three hundred years the Bower's "famine" was run like a private fiefdom, and Marchpane
Boll ran it. A Coins-culture grain broker, he built a quiet fortune on rationing,
favor-trading, and the careful management of a scarcity that was never really scarcity at
all — just the Stall wearing famine's mask, granaries bursting behind locks only he held
the terms to. Then the Fool unbinds the Empress, every harvest completes, food prices
halve across the Spread overnight, and Marchpane's whole trade — and half his self-regard
— evaporates by morning. The player finds him at the far end of the only power he ever
had. He is not quite a villain: he kept households fed who would otherwise have starved on
principle alone, and he knows exactly how thin that excuse has worn. This quest is
available only after MQ03 ("The Endless Harvest"); it is one of the famine sidequests the
Empress's unbinding resolves.

## Beats

1. **The hook.** In a warehouse of suddenly worthless grain, Marchpane Boll (canon, `characters.md` §Regional named NPCs) is doing the one
   thing a Coins broker cannot bear to stop doing: taking inventory. Prices have halved,
   his contracts are so much paper, and he greets the Fool with the driest possible account
   of his own ruin — measured, transactional, and only just holding.
2. **The ledger.** Boll's books tell the real history of the Bower's "famine": three
   centuries of who ate and who waited, priced and favor-traded down to the ounce. It is
   damning. It is also, read closely, a record of several households he quietly kept
   alive — fed at a loss, off the books, because a broker with no market left is still, it
   turns out, a neighbour (theme 2: the office ate the man, but did not quite finish him).
3. **The complication.** With the flag fired (`WS_EMPRESS_UNBOUND`), there is nothing left
   to broker; abundance has made his life's whole cunning obsolete in an afternoon (theme
   3). He is not being punished by anyone — the world simply moved on and left his
   expertise behind. The question the quest actually poses is what the Fool does with the
   ledger, and what Boll does with a self that was ninety percent scarcity.
4. **The ache and the laugh.** Routes are NPC-level: the Fool can bring the ledger into the
   open (the households he gouged learn it — and so do the ones he saved), let him retire
   quietly with his conscience and his hoard, or nudge him toward honest trade in a Bower
   that suddenly has more grain than anyone knows how to move. The dry laugh: Boll prices
   his own guilt aloud, itemised, and cannot help offering the Fool a fair rate on it. The
   honest beat: he asks, genuinely, whether feeding people badly is better or worse than
   not feeding them at all, and does not pretend to know.
5. **Closing beat.** However it resolves, no world-state turns on it — the Fool's choice
   shifts Boll's standing and barks at NPC level, and moves his hoard into the open, into
   retirement, or into honest circulation. A middling man on the far side of the only power
   he ever had, learning whether there is a person under the broker.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (any route) | none — NPC-level only | Boll's future barks and neighbourhood standing shift per whether the Fool exposed the ledger, let him retire, or set him to honest trade; the hoarded grain moves accordingly. No `WS_*` flag is set; no other quest reads this outcome. |

## Consistency references

- `design/world.md` §The Bower — abundance-as-famine, the granaries no one may lawfully
  touch until the harvest is called; Boll is the man who worked that gap.
- `design/world.md` §World-state matrix (`WS_EMPRESS_UNBOUND`) — harvests completing, food
  prices halving, and "famine sidequests resolve"; this quest hard-requires that flag and
  is explicitly one of those famine sidequests.
- `design/characters.md` §Regional named NPCs — Marchpane Boll (canon), the grain
  broker this quest promotes.
- `design/characters.md` §The Minors: suit-cultures (Coins row — measured, transactional,
  prices everything fondly, the driest jokes in the game) — Boll's entire voice.
- `design/characters.md` §III. The Empress — the region's abundance the unbinding unleashes
  against his trade (the Empress herself does not appear here).
- `design/narrative.md` §Themes (2, offices eat people; 3, every unbinding hurts someone
  ordinary — show them, don't resolve them) — Boll embodies both; the quest declines to
  declare him villain or redeemed.
- `design/narrative.md` §Dialogue style guide — the melancholy rule (one dry laugh in the
  hard scene, beat 4) and Fool lines ≤ 12 words with an earnest option.
- `design/progression.md` §Renown, §Currency — any reward kept to legal coins / Coins
  Renown, and shop pricing reading `WS_EMPRESS_UNBOUND` as owned by economy design.

## Open questions

- The MQ03 "hungry Coins-culture family at a roadside stall" (its beat 2) is a natural
  thread to tie Boll to — as one of the households he gouged, or one he quietly fed.
  Decide at script status whether to cross-link them or keep both self-contained.
- Reward: exposing vs. sparing Boll could plausibly move Coins Renown in opposite
  directions (shrewdness prized vs. a cold bargain); confirm the intended Renown reactions
  against `progression.md`'s deed table before script status.
- Whether Boll gets a living-world successor role (honest grain factor in the post-harvest
  Bower economy) if the Fool steers him to honest trade, or is left deliberately adrift
  per theme 3.
