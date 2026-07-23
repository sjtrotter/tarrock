---
id: SQ-STILLMARSH-03
title: The Candle That Won't Gutter
type: side
status: outline
arcana: none
region: The Stillmarsh
requires: []
fires: []
---

# SQ-STILLMARSH-03 — The Candle That Won't Gutter

## Introduction

A quiet pre-unbinding piece, played while Death still holds the Stillmarsh. In a window
above the wetlands, one candle has burned since the night before the Stall — unconsumed,
never dripping, never guttering. Widower Corse Millbank tends it for his late wife and
knows exactly what it means and tends it anyway. The quest offers the Fool no puzzle to
solve and nothing to mend; the candle cannot be fixed because it is not broken. What it
offers is company, a running feud with a tallow merchant, and an ending the quest itself
refuses to reach for — undecided by design, per the Stillmarsh's whole character. Kind,
never grim.

## Beats

1. **The candle.** The Fool finds Corse Millbank (canon, `characters.md` §Regional named NPCs)
   at his window, tending a flame that has not eaten a thread of its wick in three hundred
   years. He is unsurprised to be asked about it and unhurried in answering. He bows to
   Pip on sight, as everyone here does (`characters.md` §Pip), and offers the Fool the
   good chair.
2. **What he knows.** Corse knows precisely what the candle is: his wife is among the
   Stillmarsh's waiting, and the flame will burn exactly as long as nothing here is
   allowed to end — which is to say, until the Fool changes that. He tends it not out of
   confusion but out of love, and he'd thank the Fool not to explain it to him.
3. **The feud (the comic scene, with its honest beat).** Down the lane, a tallow
   merchant has lost three centuries of business to this one candle that never needs
   replacing, and comes round weekly to say so at length. Corse relishes the argument
   enormously. The honest beat underneath: the merchant keeps a stub of his own, for his
   own dead, that he cannot bring himself to light — and comes to argue because arguing is
   easier than grieving next to someone.
4. **The "help."** Whatever chore the Fool imagines — trim the wick, catch the drip,
   relight it — there is nothing to do; the candle needs none of it. The actual help Corse
   wants is someone to sit while he tells one story about her. The Fool can be earnest or
   dry — "Tell me about her." / "That's a great deal of unspent wax." (≤12 words, one
   earnest option) — and either way, he tells it.
5. **The ache.** Corse does not want the candle explained, mended, or ended. He wants it
   left, and he wants to have been heard once. The quest grants exactly that and no more.
6. **Closing beat.** The candle burns on. Corse waves the Fool off, already turning back
   to the window, and the quest closes on nothing resolved — the whole point.

**[If WS_DEATH_UNBOUND: …]** — If the Fool unbinds Death after meeting Corse, the candle
finally gutters — the first honest flame-death in three hundred years. Corse does not
grieve any louder for it; he simply watches it go out and thanks the Fool for having sat
with him *before* it did. The tallow merchant, absurdly and unbidden, brings him a fresh
unlit candle — "for when you're ready" — and the two of them stand in the smell of cold
wax, not arguing, for once. The laugh inside the ending.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (either state) | none — NPC-level only | Corse's barks and the candle prop update (still-lit pre-`WS_DEATH_UNBOUND`, guttered after); the merchant feud softens; no `WS_*` flag is set and no other quest reads this outcome. |

## Consistency references

- `world.md` §The Stillmarsh ("the world's kindest and wariest people"); §Hydrology /
  stasis logic and §World-state matrix (`WS_DEATH_UNBOUND`: what an *ending* means for the
  candle, applied here as order-independence handling).
- `characters.md` §Pip (bow-on-sight reverence, written as instinctive, never stated).
- `narrative.md` §Themes 1 & 3 (endings as mercy; the ordinary grief an ending touches,
  shown and not resolved); §Dialogue style guide (melancholy rule — the merchant's honest
  beat inside the comic feud; the fresh-candle laugh inside the sad ending; Fool's
  ≤12-word rule).
- `quests/main/MQ13-an-ending.md` §Beats — the Stillmarsh's tone and Old Sallow-adjacent
  register this quest must not contradict.

## Open questions

- This quest is written as pre-unbinding with an `[If WS_DEATH_UNBOUND]` order-
  independence branch. Decide whether it remains *offerable* after Death is unbound (the
  candle already guttered, so the hook is gone) or auto-closes — recommend it becomes
  un-offerable once `WS_DEATH_UNBOUND` fires, with any in-progress instance resolving via
  the branch above.
- Reward: recommend none material; company is the exchange. Confirm, or a modest cosmetic
  (a taper-and-holder mantel piece) per `progression.md`.
