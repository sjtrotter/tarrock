---
id: SQ-AXIS-01
title: The Telescope-Makers
type: side
status: outline
arcana: none
region: The Axis
requires: []
fires: []
---

# SQ-AXIS-01 — The Telescope-Makers

## Introduction

At the edge of the Axis approach, a family of lens-grinders has spent four generations
building ever-finer spyglasses, all aimed inward at the lone figure dancing at the still
center — certain that if they could only resolve the Dancer a little more clearly, they'd
finally understand *something*. The Fool helps them grind their best lens yet, and then
does the one hard, kind thing the quest is built around: says nothing. The Fool alone, of
everyone in the Spread, could tell the Loaches what their answer will turn out to be. It
isn't kind to, yet. This quest observes the Dancer from exactly as far away as its NPCs
do, and never one step closer.

## Beats

1. **The hook.** The Loach family's workshop on the Axis rim (characters.md §Regional
   named NPCs), cluttered with four generations of spyglasses all pointed at the center.
   The current elder wants the Fool's help gathering the last thing needed for the finest
   lens the family has ever attempted.
2. **The work.** A modest fetch-and-grind errand along the approach — a truer sand, a
   cleaner polish. As they work, the youngest Loach explains the family faith: that seeing
   the Dancer clearly would answer a question they've never quite been able to name. They
   don't know what the question *is*. That, tenderly, is the whole trouble.
3. **The better lens.** It works — the clearest view of the Dancer any Loach has ever had.
   And it is still just a figure, dancing, under the wreath of white stone: nearer, not
   *known*. The family is moved and unsatisfied in the same breath.
4. **The reticence beat.** The scene hands the Fool the obvious moment — the Fool, who
   will one day walk right up to that figure, could end four generations of wondering with
   a sentence — and the quest's spine is that the Fool declines it. `[Fool options are
   limited to gentle wonder or deflection; none reveals the Dancer's nature or that the
   watching ends when the Fool's journey does. Earnest — "It's beautiful. Keep looking."
   / foolish — "Sharper than my own eyes, that." Both ≤ 12 words.]` (Theme 1, held at
   arm's length: the answer these hopeful people are chasing is the world's own ending,
   and the Fool lets them keep the question a while longer.)
5. **The ache and the laugh.** The honest ache: four generations, and the answer was never
   going to be a better lens. The laugh: the elder cheerfully allows that the spyglasses
   are, at least, unmatched for spotting weather rolling in and neighbors coming up the
   road — so it's hardly been wasted craft.
6. **`[If CONFESSED]`.** Once the Fool knows the truth, the not-telling stops being mere
   tact and becomes plain mercy — the Fool now knows exactly what clearer sight would cost
   these people. Played entirely in the withholding; no dialogue option is added that
   spills it, and nothing in the scene confirms to the *player* anything narrative.md
   hasn't already revealed elsewhere.
7. **Resolution.** The Loaches keep looking, content and uncontented as ever; the Fool
   leaves them the fine lens (flavor) and takes a modest reward. The family's ambient barks
   gain the Fool as "the one who ground us the good glass."

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved | none — NPC-level only | The Loaches keep their new lens and gain barks about the Fool; no `WS_*` flag is set, and nothing about the Dancer is revealed. |

## Consistency references

- `design/narrative.md` §The Twist (this quest observes the Dancer from outside and must
  not reveal the Dancer's identity or that finishing ends the world), §Themes 1, §Act
  structure (`[If CONFESSED]`), §Dialogue style guide (Fool lines ≤ 12 words with an
  earnest option; the melancholy rule).
- `design/world.md` §The Axis (always open; the lone dancing figure visible from
  everywhere, too far to see clearly), §Hard and soft gates (Axis always open).
- `design/characters.md` §XXI The World (the entry deliberately withholds — this quest
  preserves that reticence), §Regional named NPCs — the Loach family (being promoted in
  the parallel change); §Pip.
- `design/progression.md` §Currency, §Renown — a modest legal reward.

## Open questions

- Which suit's Renown (if any) fits the Axis, which has no home suit-culture? (Recommend a
  small flat coin reward and no suit Renown, since the Axis sits outside the suit map.)
- The Fool's dialogue set needs a human-level authoring pass at script status to guarantee
  no option — confessed or not — reveals the Dancer's nature. This is the quest's single
  load-bearing constraint.
