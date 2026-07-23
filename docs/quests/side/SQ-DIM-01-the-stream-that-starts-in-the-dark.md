---
id: SQ-DIM-01
title: The Stream That Starts in the Dark
type: side
status: outline
arcana: none
region: The Dim
requires: []
fires: []
---

# SQ-DIM-01 — The Stream That Starts in the Dark

## Introduction

On the lamplighter's rounds a young apprentice mentions, half to himself, the one thing
about the Dim's single visible stream that has always bothered him: it runs down into a
ravine and never comes out the other side. The locals call it "swallowed" and leave it
there — this is a mountain of permanent dusk, and nobody looks far into a dark that never
lifts. The player, tracing it by careful dusk-blind climbing and Pip's nose, finds the
unspectacular truth: the water simply goes underground for a stretch and daylights again
lower down the slope, on its way to the lowlands, exactly where geology says it must. A
quiet, satisfying answer to a mystery that was never a mystery — only an unlit stretch of
perfectly ordinary rock.

## Beats

1. **The hook.** Lamplighter's apprentice Fenn Dusk (`characters.md` §Regional named NPCs
   — promoted in the parallel slate change), lighting wicks on his round, points out where
   the stream "gets swallowed" and admits it keeps him up: water that vanishes and doesn't
   come back feels wrong to him in a way he can't say properly.
   - Fool (earnest): "Let's find where it comes out." / (foolish): "Maybe the dark's
     thirsty."
2. **The descent.** Following the stream into the ravine by lamplight and by Pip's nose —
   the Dim's core skill of moving carefully through a dark that never eases. The water
   slips under a lip of rock and is gone; the "swallowing" is real, and completely
   physical.
   - `[If not WS_HERMIT_UNBOUND]` No stars overhead; the climb is navigated by landmark,
     lamplight, and Pip alone — the Dim at its darkest.
   - `[If WS_HERMIT_UNBOUND]` Stars have returned over the Dim; the slope is faintly
     legible for the first time, and the stream's lower course can be *seen* running toward
     the lowlands, which turns a blind trace into a confirmed one.
3. **The underground stretch.** A short traverse alongside where the water runs unseen
   through the rock — audible, never lost — the region's dusk-craft rewarding a player who
   trusts sound and slope over sight.
4. **The daylighting.** Lower down, the stream simply re-emerges from the hillside and
   carries on toward the lowlands, obeying gravity the whole way, exactly per the Spread's
   hydrology. Nothing was swallowed. It only went where the dark was.
5. **The ache and the laugh.** Fenn is almost disappointed the answer is so plain — a
   swallowed stream was a better story for a boy on a lonely round — then brightens: at
   least now he knows the mountain isn't eating anything, "which is more than I could say
   about my last supper." The honest note underneath: he'd built a small dread on the
   unlit dark, and the dark turned out to just be dark.
6. **Closing beat.** The re-emergence becomes a mapped waypoint; Fenn's round-barks gain
   the confident line of a boy who solved one thing about his mountain. A rose grafting
   tucked where the stream daylights rewards the descent.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Daylighting reached | none — NPC-level only | The stream's re-emergence becomes a mapped waypoint; Fenn's lamplighting barks update to the solved version; a rose grafting at the lower course rewards the trace. No `WS_*` flag is set. |

## Consistency references

- `world.md` §Hydrology rule — water begins high, flows downhill, ends somewhere real; the
  Dim's high ground is named there as a legitimate source; a stream running underground and
  daylighting lower is exactly the "shape water could have had" the rule demands.
- `world.md` §The Dim — permanent dusk, star-blind valleys, hermit shacks; §World-state
  matrix (`WS_HERMIT_UNBOUND`) — stars return, used only to color the `[If WS_…]` variant.
- `callings.md` — the Dim's Lamplighter Calling (walk the dusk routes lighting wicks), the
  quest's framing and Fenn's role.
- `characters.md` §Regional named NPCs — Fenn Dusk, lamplighter's apprentice (promoted in
  the parallel slate change); §Pip (nose as wayfinding in the dark).
- `narrative.md` §Themes (1 — the world was never as stopped, or as swallowed, as it
  looked) and §Dialogue style guide (one laugh in the small scene; Fool lines ≤ 12 words).
- `progression.md` §The White Rose — a rose grafting as a legal exploration reward.

## Open questions

- The slate tags this premise theme "—"; this outline touches theme 1 lightly (an ordinary
  dark mistaken for the uncanny). Confirm that read is wanted or keep it a pure puzzle.
- Is Fenn Dusk the apprentice of Wick Hollin (SQ-DIM-03's lamplighter), or an independent
  Lamplighter-Calling NPC? Recommend making them master-and-apprentice for economy, but
  only if characters.md promotion agrees — do not assume the link in script status.
- Reward as a rose grafting versus coins/Renown, and whether a grafting source belongs on
  this slope, is a content-pass decision.
