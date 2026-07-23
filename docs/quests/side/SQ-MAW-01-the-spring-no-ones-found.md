---
id: SQ-MAW-01
title: The Spring No One's Found
type: side
status: outline
arcana: none
region: The Maw
requires: []
fires: []
---

# SQ-MAW-01 — The Spring No One's Found

## Introduction

Every hunter in the Maw will tell the player the same thing: the high river isn't born of
any spring, it simply *appears* partway down the crags, "of the mountain's own will." It
is the region's proudest myth, and it is wrong — not because the world is enchanted, but
because nobody has ever climbed high enough to look. With Pip's nose and some honest,
punishing limestone climbing, the player traces the water up past where anyone bothers to
go and finds the answer exactly where gravity always said it would be: a modest spring in
the high rock. This is a quest for the player who reads the land as land, and it rewards
that reading with the quiet satisfaction of a mystery that was never supernatural.

## Beats

1. **The hook.** Herder Sask Combe (`characters.md` §Regional named NPCs — promoted in
   the parallel slate change) tells the myth as gospel while working the border pasture:
   the river is a gift of the mountain, sourceless, and only a fool would go looking for
   where a gift begins. The Fool, being exactly that, asks where the water actually comes
   from.
   - Fool (earnest): "Water starts somewhere. Always." / (foolish): "I'll ask the
     mountain myself."
2. **The trace.** Following the river *up* — against the current, the way no hunter does
   — the Fool reads the course the way the region's whole hydrology is built to be read:
   downhill has a top. Pip catches the cold, mineral scent of the source on the wind and
   leads where sight fails.
   - `[If not WS_STRENGTH_UNBOUND]` The high crags are wild and hostile; the climb is as
     much about avoiding provoking the Maw's beasts as about the route.
   - `[If WS_STRENGTH_UNBOUND]` The beasts are neutral-until-provoked; the ascent becomes
     purely about reading the rock, and the lion may amble past, indifferent, on his own
     rounds.
3. **The false crest.** A ledge where lesser climbers turned back, marked with an old
   cairn and a hunter's scratched claim that "there's nothing above this." There is. The
   cairn is the exact height of the myth.
4. **The find.** Above the last handhold: a plain spring welling from the limestone,
   feeding the whole "sourceless" river, precisely where geology insists it must. No
   miracle, no will of the mountain — just water, doing what water does, in a world that
   only *looked* stopped.
5. **The ache and the laugh.** Told the truth, Sask is briefly deflated — a mountain that
   merely obeys gravity is a smaller mountain to love — then rallies with a herder's dry
   grace: "Well. It's a good spring, at least. Kept its mouth shut three hundred years."
6. **Closing beat.** The spring becomes a named waypoint on the Fool's map; Sask retells
   the myth afterward with a wink and a correction, half-proud the truth is *hers* to tell
   now. A rose grafting, tucked in the high rock where only a real climber would reach it,
   rewards the ascent.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Spring reached | none — NPC-level only | The source becomes a mapped waypoint; Sask's myth-telling barks update to the corrected version; a rose grafting hidden at the source rewards the climb. No `WS_*` flag is set. |

## Consistency references

- `world.md` §Hydrology rule — rivers begin at credible sources, flow downhill, end
  somewhere real; the Maw's high ground is named there as a legitimate river source, which
  is the entire factual backbone of this quest.
- `world.md` §The Maw — savage limestone highlands, vertical crags, hunting culture.
- `world.md` §World-state matrix (`WS_STRENGTH_UNBOUND`) — beasts neutral-until-provoked,
  used only to color the climb's `[If WS_…]` variants (this quest is order-independent).
- `characters.md` §Regional named NPCs — Herder Sask Combe (promoted in the parallel slate
  change); §Pip (his nose as a wayfinding tool, per the character bible).
- `narrative.md` §Themes (1 — the world was never as stopped as it looked) and §Dialogue
  style guide (Fool lines ≤ 12 words; one laugh in the small deflation).
- `progression.md` §The White Rose — a rose grafting as a legal exploration reward.

## Open questions

- The slate tags this premise theme "—"; this outline touches theme 1 lightly (stasis
  mistaken for the supernatural), matching the Mere's parallel hydrology quest. Confirm
  that light theme-1 read is wanted, or keep it a pure puzzle with no thematic gloss.
- Should the reward be a rose grafting (as written) or coins/Renown, and is one grafting
  source wanted this high in the Maw at content-pass? Defer to content-design.
- Does Sask Combe recur as a Shepherd-Calling contact in the Maw (overlapping SQ-MAW-03's
  flock), or stay scoped to this quest? Recommend a light recurrence, not a dependency.
