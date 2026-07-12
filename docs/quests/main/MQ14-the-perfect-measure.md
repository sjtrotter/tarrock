---
id: MQ14
title: The Perfect Measure
type: main
status: outline
arcana: XIV. Temperance
region: The Confluence
requires: []
fires: [WS_TEMPERANCE_UNBOUND]
---

# MQ14 — The Perfect Measure

## Introduction

The player arrives at the Confluence to find a city built on a single, beautiful
problem: nothing here is ever allowed to finish. Bridges stand at exactly
half-completion. Tea has been steeping in the same pot for three hundred years and is,
by all accounts, nearly perfect. At the delta's heart, the Mixer pours forever between
two colossal cups, blending a mixture that can never be poured out, because pouring it
out would mean it was done. This quest asks the player to learn her patience before it
asks them to break it — the mini-challenges teach tempering as a skill before the fight
demands it as the only way to win.

## Beats

1. **Arrival.** The Fool crosses one of the Confluence's famous unfinished bridges —
   scaffolding still up, three centuries weathered smooth. Below, two rivers braid
   through the delta toward cups too large to be architecture.
2. **Reading the stasis.** A mixer at a public bench explains, unprompted and pleased
   about it: the tea has *nearly* finished steeping since the Stall. So has everything
   else worth doing properly. Nobody here considers this a tragedy. That's the tell.
3. **Mini-challenge — the small blend.** A mixer's apprentice, mid-panic over a
   simpler blend that keeps scalding or freezing, asks for help. The Fool learns to
   redirect hot into cold and back to cut a neutral path — the exact mechanic the boss
   arena will scale up. Skippable, but the fight is markedly harder without it.
4. **Mini-challenge — the flooding channels.** Crossing the outer delta to reach the
   twin-cup plaza means timing passage between alternating bands of scald-mist and
   frost-spray thrown off by the rivers themselves — an environmental preview of the
   arena's core hazard.
5. **Mini-challenge — the mason's plea.** Elgin Thatch (proposed — promote to
   characters.md before script status), the bridge-mason, intercepts the Fool at the
   final span and asks, quite sincerely, that this one thing be left alone. He has laid
   the same stone for longer than he can be sad about. This is the quest's mourning
   beat planted early, so its return in the aftermath lands.
6. **Arrival at the arena.** The twin cups, the Mixer astride the confluence between
   them, pouring — an eternal, gorgeous, unbearable patience.
7. **The encounter, phase one.** Per [`arcana.md`](../../design/arcana.md) §XIV: the
   arena floods in alternating bands of scald and frost as she pours, punishing
   frantic dodging.
8. **The encounter, phase two — tempering.** The counter to her pours is redirecting
   her own mixtures into each other, cutting neutral paths and exposing her between
   mixtures. The fight rewards conducting, not scrambling.
9. **The falter.** Pressed enough times, her pour finally misses a beat — the first
   uneven moment in three hundred years of perfect measure.
10. **Unbinding.** The office cracks around her like a dropped cup. The name that
    returns to her *(freed name TBD — see characters.md and Open questions)* is spoken
    once, quietly, and she hands the Fool Trump XIV — Blend — herself, still holding
    the two jugs, empty for the first time she can remember.
11. **Aftermath — the pour completes.** The two rivers finally reach the sea. Over the
    following in-game hours the delta visibly drains: mudflats firm into grassland,
    sunken relics of the pre-Stall city surface, and the long-submerged Confluence
    delta caves become enterable (`world.md` §Hard and soft gates).
12. **Aftermath — the mason.** Elgin stands on his now-completed bridge, unsure what to
    do with his hands. He mourns — not the work, the *finishing* of it. He doesn't ask
    the Fool to undo it. He just needed someone to notice.
13. **Aftermath — elixir-craft.** Mixer benches across the Confluence begin brewing
    proper elixirs (`progression.md` system detail) rather than eternal almost-teas.
14. **Closing beat.** The Querent, watching the drained delta glitter with old
    rooftops: "There. Now it's finished. Doesn't that feel *dreadful*." One wink, no
    more.

## Key NPCs

- **The Mixer (Temperance)** — canon, see `arcana.md` §XIV, `characters.md` §XIV.
- **Elgin Thatch, bridge-mason (proposed — promote to characters.md before script
  status)** — the quest's mourning NPC (beats 5, 12).
- **The mixer's apprentice (proposed — promote to characters.md before script
  status)** — delivers the tempering tutorial in beat 3; unnamed placeholder, "the
  Apprentice," pending a proper name.

## [If CONFESSED] variants

- The apprentice, if `CONFESSED`, references finishing things "before the big one"
  with a nervous laugh rather than simple enthusiasm.
- Elgin's plea in beat 5 gains a line acknowledging he knows exactly what "finished"
  is going to mean for everything, eventually — and asks anyway.
- The Querent's closing wink (beat 14) gains a harder edge if `CONFESSED`: "dreadful"
  lands less like a joke.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Unbinding the Mixer | `WS_TEMPERANCE_UNBOUND` | Rivers reach the sea; Confluence delta drains, exposing new land; elixir crafting unlocks at mixers; Confluence delta caves open (previously underwater). |

## Consistency references

- `arcana.md` §XIV — encounter, Trump, reversed burden, unbinding line.
- `world.md` §The Confluence, §Hard and soft gates (delta caves), §World-state matrix.
- `characters.md` §XIV — personality (serene surface, frantic underneath); freed name
  TBD.
- `narrative.md` §Themes 1, 3 — endings as mercy; Elgin's grief as the "not everyone
  wants this" beat.

## Open questions

- Temperance's freed name is TBD in `characters.md`; this quest's naming beat (10)
  needs it assigned before promotion to `script` status.
- Is the tempering tutorial (beat 3) mandatory or skippable? Outline assumes skippable
  with a difficulty cost; confirm against scope/accessibility goals.
- Should Elgin's finished bridge open a new fast-route across the delta, or remain
  cosmetic? Affects world.md traversal notes if the former.
