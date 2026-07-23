---
id: SQ-HOLLOWS-02
title: The Long-Overdue's Last Request
type: side
status: outline
arcana: none
region: The Hollows
requires: [WS_DEATH_UNBOUND]
fires: []
---

# SQ-HOLLOWS-02 — The Long-Overdue's Last Request

## Introduction

Death has been unbound, and the long-overdue have gathered in the Hollows to wait for
Judgement's trumpet to call them onward. One of them is not ready — not because she fears
the call, but because she has one thing left undone: an apology, overdue by decades even
before the Stall froze it in her throat. This is a quiet errand, no fight, meant to make
an ending feel *earned* rather than merely arrived at. It is designed to be done in the
window between Death's unbinding and Judgement's — and it deliberately handles what
happens when the player closes that window early.

## Beats

1. **The hook.** Among the waiting souls of the terraces, Elder Petronella Dusk
   (characters.md §Regional named NPCs) — long-overdue, at peace with being called on, and
   holding herself back from it for one reason only: an apology she never managed to say,
   already decades late when the world stopped.
2. **The errand.** The person she wronged waits here too — another of the long-overdue, an
   unnamed soul a few terraces down, findable by the marker Petronella can only describe,
   never approach. Three hundred years within sight of each other and she still can't
   cross the ground between. The Fool carries the message, or brings the two together.
3. **The delivery.** Soul to soul, the apology lands. Not a grand absolution — a small,
   plain, earned acknowledgment between two people who have had far too long to think
   about it. (Theme 1: the ending is made a mercy by being *finished properly* first.)
4. **The ache and the laugh.** The honest ache: Petronella has been ready to die for
   centuries but not ready to be found wanting by her own silence. The laugh, dry as
   grave-dust: "You'd think three hundred years would be time enough to work up to five
   words. Turns out it's exactly not."
5. **At peace to answer.** With it done, Petronella will answer the call whenever it
   comes. If Judgement has not yet fired, she waits — content now, not stalled. When
   `WS_JUDGEMENT_UNBOUND` fires (MQ20's goodbye wave, beat 11), she is among the resolved:
   this quest is, by design, one of the "waiting" ghost threads that MQ20 closes.
6. **The window — `[If WS_JUDGEMENT_UNBOUND already set]`.** `requires` cannot express
   "before Judgement," so the quest keeps `requires: [WS_DEATH_UNBOUND]` and handles the
   case in fiction. If the player never met Petronella before firing Judgement, she has
   already been called on with the whole wave, her apology undelivered. Recommended
   handling (see Open questions): the quest remains discoverable as a memorial coda — the
   wronged soul, or their marker, lingers a beat longer, and the Fool may deliver the
   apology *on her behalf*, a quieter and sadder shape of the same errand. The alternative
   is a hard close, the thread folded silently into MQ20's wave.
7. **No unconfessed variant.** Reachable only after `WS_DEATH_UNBOUND` (MQ13) = `CONFESSED`;
   every scene is post-confession by construction. No un-confessed variant to write.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | Petronella is at peace to be called; her thread is designed to be *closed by* `WS_JUDGEMENT_UNBOUND` (MQ20), not to fire anything itself. |

## Consistency references

- `design/world.md` §The Hollows (fills with the long-overdue after Death, empties after
  Judgement), §Hard and soft gates (Death→Judgement), §World-state matrix
  (`WS_DEATH_UNBOUND`, `WS_JUDGEMENT_UNBOUND`).
- `quests/main/MQ20-the-last-trumpet.md` §beat 11 (the goodbye wave that closes every
  "waiting" sidequest — this quest is one of them) and its Open question surveying how
  many such threads exist; this quest should be registered in that survey.
- `design/characters.md` §Regional named NPCs — Elder Petronella Dusk (being promoted in
  the parallel change); §XX Judgement — Clemency, for the call-and-waiting frame.
- `design/narrative.md` §Theme 1, §Act structure (always-confessed region), §Dialogue
  style guide (one laugh in the sad scene; Fool lines ≤ 12 words with an earnest option).

## Open questions

- **The window handling is the central decision:** if the player fires Judgement before
  ever starting this quest, does the thread hard-close (folded into MQ20's wave) or reopen
  as a memorial coda where the Fool delivers the apology posthumously? (Recommend the
  coda — it keeps the quest reachable and adds a genuinely sadder second reading.)
- Register this quest in MQ20's cross-region "waiting ghost threads" survey so MQ20's
  goodbye wave doesn't promise a closure it can't see, or double-resolve one already done.
- Whether the wronged party stays an unnamed walk-on soul (recommended) or is worth a
  named entry — recommend unnamed, to avoid inventing canon.
