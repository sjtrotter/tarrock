---
id: SQ-HOLLOWS-01
title: The Groundskeeper's Empty Plot
type: side
status: outline
arcana: none
region: The Hollows
requires: [WS_DEATH_UNBOUND, WS_JUDGEMENT_UNBOUND]
fires: []
---

# SQ-HOLLOWS-01 — The Groundskeeper's Empty Plot

## Introduction

The Hollows have bloomed. Judgement's trumpet has called every waiting soul onward
(MQ20), the terraces have greened over, and the amphitheater of open graves has become a
garden instead of a waiting-room. And the groundskeeper who spent three hundred years
tending one plot reserved for a soul who was never going to arrive is now standing over
that plot — the wildest-flowered of them all — with nothing left to keep ready and no
notion of what a graveyard at peace even needs from him. This quest is the quiet after the
bloom: helping a man whose whole shape was *waiting* find something to tend that isn't a
grave.

## Beats

1. **The hook.** In the newly-blooming Hollows, Yew Halloway (characters.md §Regional
   named NPCs), groundskeeper, stands over a single plot flowering wilder than any other
   — a plot he kept bare, level, and ready for three centuries, for a soul who, while the
   Stall held, was never actually going to die to fill it.
2. **What the plot was.** By an old arrangement from before the Stall, the plot was
   reserved for one specific person (unnamed — and left so, deliberately). Keeping it
   ready was Yew's private act of faith: to hold a place for an ending, in a world that
   had forbidden endings, was his stubborn way of believing endings would one day come
   back. (Theme 1: the ending, when it finally came, was a mercy — the plot's riot of
   flowers is the answer to three hundred years of hope.)
3. **The turn.** Now Judgement has come; the reserved soul was among those called on in
   the goodbye wave, and the plot's whole purpose is spent. The wild bloom that ought to
   be joyful has quietly demolished the daily shape Yew's life was built on. (Theme 3:
   even a mercy delivered on schedule takes something from someone ordinary.)
4. **Finding something to tend.** The Fool helps Yew turn from graves-in-waiting to the
   living garden — choosing what to plant where the waiting used to be, learning that a
   bloom needs more, and messier, care than a bare plot ever did. The quest does not fully
   resolve his grief; it just gives his hands somewhere to go.
5. **The ache and the laugh.** The honest ache: Yew is grieving a job that was really
   three hundred years of hope, now fulfilled and therefore gone. The laugh: his flat,
   put-upon complaint that a garden is far more trouble than a graveyard ever was — "the
   dead at least stay where you put them; a foxglove won't."
6. **Resolution and Calling hook.** Yew becomes the gardener of the bloom (callings.md,
   Groundskeeper post-MQ20); his barks shift from vigil to cultivation, and if the Fool
   has taken up the Groundskeeper Calling here, Yew develops workplace-memory lines.
   Reward: a rose grafting cut from the wild-flowered plot itself — the world's own
   aliveness, handed over.
7. **No unconfessed variant.** The Hollows are reachable only after `WS_DEATH_UNBOUND`
   (MQ13), which is the same event that sets `CONFESSED` — so every scene here is, by
   construction, post-confession. There is no un-confessed variant to write (mirrors
   MQ20's note).

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | Yew turns from vigil to gardening; his barks and the tended plot change; no `WS_*` flag is set. |

## Consistency references

- `design/world.md` §The Hollows (gated behind Death; blooms after MQ20), §Hard and soft
  gates (Death→Judgement), §World-state matrix (`WS_DEATH_UNBOUND`, `WS_JUDGEMENT_UNBOUND`).
- `quests/main/MQ20-the-last-trumpet.md` — the bloom, the goodbye wave, and the always-
  confessed baseline this quest sits downstream of.
- `design/characters.md` §Regional named NPCs — Yew Halloway (being promoted in the
  parallel change); §XX Judgement — Clemency, for the region's presiding grief-of-almost-
  done-duty context.
- `design/callings.md` — the Groundskeeper Calling (post-MQ20: "gardener of the bloom"),
  which Yew embodies without this quest duplicating its loop.
- `design/narrative.md` §Themes 1 and 3, §Act structure (region is always-confessed),
  §Dialogue style guide (one laugh in the sad scene).
- `design/progression.md` §The White Rose — rose grafting as a legal side-quest reward.

## Open questions

- Should the reserved soul stay strictly unnamed (recommended — preserves the region's
  reticence and avoids inventing new canon), or be linked to another Hollows thread? If
  linked, it must be to an existing one, not a new NPC.
- Confirm rose-grafting sourcing with progression.md's TBD grafting list at content pass.
