---
id: MQ12
title: A Change of Perspective
type: main
status: outline
arcana: XII. The Hanged Man
region: The Gallowwood
requires: []
fires: [WS_HANGEDMAN_UNBOUND]
---

# MQ12 — A Change of Perspective

## Introduction

The player enters the Gallowwood braced for a fight and finds, instead, an invitation.
The Hanged Man is the only Arcanum who is happy — three centuries of hanging from the
World-Tree's bough gave his card exactly what it wanted — and he won't be beaten, only
joined. The quest is a traversal ordeal through a forest that forgot which way gravity
was going, ending in a single, gently absurd question.

## Beats

1. Arrival at the Gallowwood: canopy paths, gravity-flipped glades, a forest that
   forgot which way it was going.
2. The Fool meets Fenwick Loft (proposed), a guide who has spent years learning to read
   the flipped terrain for lost travelers, and offers to lead partway.
3. Approach step: a first, small hang from a low bough — a deliberate echo of the
   Cliff's opening leap of faith, teaching the "let go" motion this ordeal is built on.
4. Approach step: traversing a gravity-flipped glade, walking a canopy bridge from
   beneath it, camera honestly inverted in marked spaces.
5. Approach step: reassuring a stranded traveler mid-flip who's panicking at the wrong
   way up — a comic beat that turns sincere the moment the Fool actually helps.
6. Reading the stasis: the Fool reaches the World-Tree's great bough at last, where the
   Hanged Man hangs, radiating a calm nobody else in the game has earned.
7. The encounter, exactly per `arcana.md` §XII: he won't fight; he invites. The Ordeal —
   hanging from the bough alongside him and traversing the Gallowwood's inverted
   gauntlet in full.
8. At the ordeal's end he asks his only question: "Comfortable?"
9. He hands over the Trump either way, delighted equally by both answers.
10. Unbinding: the office cracks gently — a loosening, not a break; his name returns to
    him mid-laugh; the Trump changes hands in an unhurried drop, not a snatch.
11. Aftermath: the Gallowwood rights itself, and its traversal reshuffles; world-wide,
    penitent and anxious NPC barks soften — his peace spreading into the world's bark.
12. Mourning: Fenwick Loft's hard-won expertise in reading the flipped terrain becomes
    useless overnight; he stands in a suddenly ordinary forest, unsure what he's for.
13. Closing beat: Fenwick decides to keep guiding anyway, now as the Gallowwood's one
    living historian of "how it used to hang" — a small, deliberate laugh set against
    his loss.

## Key NPCs

- **The Hanged Man** (freed name Wendel, `characters.md` §XII) — the only Arcanum who is
  happy; regards the Fool with real affection and no urgency whatsoever.
- **Fenwick Loft** (proposed — promote to `characters.md` before script status) — a
  Gallowwood guide whose expertise is the flipped terrain; this quest's mourning NPC.

## Mourning

**Fenwick Loft** mourns the unbinding: he spent years learning to read a forest that no
longer needs reading, and finds himself expert in something that stopped existing.

## [If CONFESSED] variants

- His question, "Comfortable?" (beat 8), gains a second layer — he is the only Arcanum
  who would find it funny that the world ending, too, might just be another kind of
  letting go.
- Fenwick's mourning bark (beat 12) sharpens — the forest righting itself so soon
  before everything else might end feels, to him, like a cruel practical joke.
- The stranded traveler reassured in beat 5, if CONFESSED, is now anxious about a much
  bigger fall than gravity, and the Fool's reassurance must work harder to land.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_HANGEDMAN_UNBOUND` | Gallowwood rights itself (traversal reshuffles); world-wide, penitent/anxious NPC barks soften. |

## Consistency references

- `arcana.md` §XII. The Hanged Man — no-boss ordeal design, "Comfortable?", Trump XII,
  the deliberate rhyme with the Cliff's leap of faith.
- `world.md` §The Gallowwood — region sketch (traversal playground).
- `world.md` §World-state matrix (`WS_HANGEDMAN_UNBOUND`) — exact world effects.
- `characters.md` §XII. The Hanged Man — "hardest Arcana to feel good about defeating."
- `narrative.md` §Themes (1, 2, 3), §Act II (`CONFESSED` variants).

## Open questions

- Should Fenwick Loft recur as a Gallowwood side-quest NPC (the region's new
  "historian"), or does his arc close at this quest's final beat?
- The exact implementation of "camera honestly inverted in marked spaces" needs
  technical confirmation (comfort/accessibility settings) before script status.
