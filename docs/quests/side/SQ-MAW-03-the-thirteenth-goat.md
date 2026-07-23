---
id: SQ-MAW-03
title: The Thirteenth Goat
type: side
status: outline
arcana: none
region: The Maw
requires: []
fires: []
---

# SQ-MAW-03 — The Thirteenth Goat

## Introduction

Take up the Maw's Shepherd Calling and the player will notice a small accounting problem:
every night, one goat from the flock — the thirteenth, always the thirteenth — slips away
to the same crag and cannot be found until morning, when she wanders back pleased with
herself and entirely unbothered. Following her (Pip beside himself with joy, obviously,
this being his favorite work in the world) reveals where she goes: right up to the frozen
tableau of the lion and the woman holding its jaws, closer and calmer than any human dares
stand. It is the warmest small mystery in the region, and — if Strength is unbound — it
becomes the Maw's silliest and most heart-warming landmark: a freed lion and a goat who
were never going to be talked out of each other.

## Beats

1. **The hook.** While herding for the Shepherd Calling (`callings.md`; Pip's favorite,
   canon), the Fool keeps losing the same goat at dusk. The other herders shrug — she
   always comes back, so who's counting? Pip is counting. Pip has opinions about the
   thirteenth goat.
   - Fool (earnest): "One's missing. I'll find her." / (foolish): "Twelve's a fine number."
2. **The follow.** Tracking the goat up a dusk crag — Pip leading, delighted, tail like a
   metronome — to a ledge no shepherd bothers with. The route is a gentle traversal read,
   no combat: the goat knows a safe path and the player learns it by watching her take it.
3. **The find.** The goat has been visiting the frozen tableau — the woman holding the
   lion's jaws — and settles against the still lion's flank like it's the warmest rock on
   the mountain. Pip trots up and sits beside her, equally unafraid, because neither
   animal has read the story everyone else is terrified of.
   - `[If not WS_STRENGTH_UNBOUND]` The lion is stone-still, mid-Stall; the goat keeps a
     vigil no one asked for beside a danger that cannot, right now, be dangerous. It is
     eerie and tender at once.
   - `[If WS_STRENGTH_UNBOUND]` The lion is unbound and roaming friendly (`world.md`); the
     goat has simply kept her friend, and the two are now inseparable — the lion ambles
     the crags with a goat trotting at his heel and a shepherd's whole flock unbothered.
4. **The honest beat.** There is no puzzle to solve and no danger to resolve — the goat
   was never lost, only visiting. The quiet joke of it (a nightly playdate with the most
   feared thing in the Maw) carries one true note underneath: something in the mountain
   was gentle the whole time, if you were small enough not to know better.
5. **The laugh.** The head shepherd, told where the thirteenth goat goes, refuses to
   believe it until they see it, then flatly declines to be the one to explain it to the
   rest of the flock. Pip, meanwhile, would clearly like to move in.
6. **Closing beat.** The ledge becomes a named landmark; `[If WS_STRENGTH_UNBOUND]` the
   lion-and-goat pair roams as a recurring friendly sight across the region. The Fool's
   Shepherd-Calling barks gain a running line about "keeping an eye on the thirteenth."
   A cosmetic shepherd's outfit flourish, or Wands Renown for the herders' delight, may
   reward finishing the follow.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Follow completed | none — NPC-level only | The crag becomes a named landmark; post-`WS_STRENGTH_UNBOUND` the lion-and-goat pair roams as a friendly recurring sight; Shepherd-Calling barks gain the "thirteenth goat" running line. No `WS_*` flag is set. |

## Consistency references

- `characters.md` §Recurring named NPCs — The Lion of the Maw (frozen in Strength's
  tableau; becomes a roaming friendly landmark on `WS_STRENGTH_UNBOUND`); §Pip (utterly
  unbothered, never endangered — his delight is the tone of the whole quest).
- `callings.md` — the Maw's Shepherd Calling ("herd goats to pasture with Pip; Pip's
  favorite Calling"), the quest's framing and hook.
- `world.md` §The Maw and §World-state matrix (`WS_STRENGTH_UNBOUND`) — the lion as a
  roaming friendly landmark after unbinding; the frozen tableau before.
- `narrative.md` §Themes (1 — a gentleness that was there under the stasis all along) and
  §Dialogue style guide (every comic scene one honest beat; Fool lines ≤ 12 words).
- `progression.md` §Renown / cosmetics — Wands Renown or a cosmetic outfit flourish as the
  only rewards.

## Open questions

- Pip protection: this quest keeps Pip purely delighted and never at risk (the lion is
  frozen pre-unbinding, friendly post-unbinding). Confirm no encounter designer later adds
  a "scare" beat here — none is permitted per the Pip protection rule.
- Why "thirteenth"? It is currently pure flock-count flavor; confirm it should stay
  incidental and carry no nod to Death (XIII), to avoid a cross-Arcana misread.
- Should the visiting goat get a name (currently just "the thirteenth"), or does she stay
  charmingly un-named as a running gag? Recommend un-named.
