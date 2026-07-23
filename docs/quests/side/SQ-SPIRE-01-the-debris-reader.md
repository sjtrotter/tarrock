---
id: SQ-SPIRE-01
title: The Debris Reader
type: side
status: outline
arcana: none
region: The Spire
requires: []
fires: []
---

# SQ-SPIRE-01 — The Debris Reader

## Introduction

At the Spire's base, where the town lives in permanent flinch-distance from a tower
frozen mid-collapse, the Fool meets a fortune-teller who has made a whole practice out of
the one thing everyone else is too frightened to look at directly: the exact configuration
of rubble hanging in the air overhead. This is a light, charming quest with a genuinely
tender centre — the comedy of reading destiny in suspended masonry, and, underneath it, a
woman who has organised three hundred years of her life around a stillness she quietly
knows can't last. It plays before the Spire falls; the Fool's own arrival is the first
thing in living memory to disturb her frozen sky.

## Beats

1. **The hook.** Wisp Callow (canon, `characters.md` §Regional named NPCs) tends a little pitch under the hanging debris, "reading" it for anyone who'll
   sit: this chunk over the well means rain within the fortnight, that cornice's lean
   foretells a marriage, the dangling bell-cage governs luck at cards. It is charming
   nonsense delivered with total conviction, and the town humours her fondly.
2. **The disturbance.** As the Fool passes beneath a particular suspended block, it shifts
   — a visible inch, the first movement any Spire debris has made in three centuries. Wisp
   sees it happen. So, briefly, does the Fool. Nothing else in the tower so much as trembles.
3. **The complication.** Wisp is caught exactly between delight and dread. Delight, because
   *something happened* — after a lifetime of a sky that never changes, the world moved for
   her. Dread, because every reading she has ever given was premised on that block staying
   put, and if it can move an inch it can mean anything, which is to say it can mean nothing.
   Her whole grammar of prophecy has a loose tile in it now.
4. **The work.** The Fool can help Wisp re-read the changed sky — walking the town's
   landmarks against her charts to see what "moved" — or gently help her notice that the
   nudge came from the Fool's passing, not from fate. Either route arrives at the same
   place: the debris was never speaking; it was only very, very still, and stillness is
   easy to mistake for meaning.
5. **The ache and the laugh.** Wisp takes it better than either expects. She has, it turns
   out, always privately known the one true reading her tower holds — that it is going to
   fall, someday, all at once — and has spent three hundred years reading everything *except*
   that, because a fortune-teller who only ever has the one prophecy soon runs out of
   customers. The joke and the grief are the same sentence.
6. **Closing beat.** Wisp keeps her pitch, but reads a little differently now — for the
   pleasure of the telling, not the truth of it, and says so, to the Fool alone. Her barks
   soften from certainty into performance she'll admit is performance.
   - `[If WS_TOWER_UNBOUND: the debris is on the ground and the sky is ordinary. Wisp reads`
     `the fallen rubble instead — same charming nonsense, no longer premised on anything`
     `holding still — and is, against all sense, more at peace: a reader whose one true`
     `prophecy finally came true and left her free to make the rest up in good conscience.]`

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | Wisp's readings and barks shift from conviction to admitted performance; no `WS_*` flag is set, and no other quest reads this outcome. |

## Consistency references

- `world.md` §The Spire — the tower frozen mid-collapse, rubble hanging in the air, the
  town living in flinch-distance; §World-state matrix (`WS_TOWER_UNBOUND` post-fall
  geography, used only for the closing variant).
- `characters.md` §Regional named NPCs — Wisp Callow's entry (canon) is the design brief.
- `narrative.md` §Dialogue style guide — the melancholy rule (one honest beat in the comic
  scene: her one true, unread prophecy); Fool lines kept ≤ 12 words with an earnest option.

## Open questions

- Should the visible one-inch nudge (beat 2) be a scripted moment tied to this quest only,
  or a small ambient touch the whole town can witness once? Recommend quest-scoped, to keep
  the Spire's "nothing moves until it all moves" reading intact for MQ16.
- Which suit (if any) Wisp reads for, and whether resolving her quest grants a small Renown
  tick or stays reward-free like most side content. Recommend reward-free.
