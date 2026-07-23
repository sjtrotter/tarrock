---
id: SQ-MIRRORMARSH-01
title: The One Truth in the Fog
type: side
status: outline
arcana: none
region: The Mirrormarsh
requires: []          # No WS flag. The Mirrormarsh interior is hard-gated on ANY true light
                       # (world.md §Hard and soft gates) — a diegetic region-logic gate, not a
                       # world-state flag, so it cannot and does not appear in `requires`.
fires: []
---

# SQ-MIRRORMARSH-01 — The One Truth in the Fog

## Introduction

The Mirrormarsh lies about everything — paths, lights, landmarks, faces — and its interior
is hard-gated accordingly: without a true light in hand (the Hermit's Lantern, the Star's
Wish, or the Sun unbound, per `world.md` §Hard and soft gates), the fog simply loops the
Fool back out, over and over, the locked door written as geography. This quest plays before
the Moon is unbound, and it hands the player the one honest tool the marsh cannot corrupt.
A cartographer has spent years trying to map the Mirrormarsh and failed every single time,
because the land itself deceives — and the insight, once the Fool can carry true light into
the fog, is beautifully simple: *water doesn't lie.* Follow the marsh's real flow, always
downhill, always toward its one true outlet, and you cut a straight, honest line through a
region built to have none.

## Beats

1. **The hook.** At the border town, Rue Aldous (canon, `characters.md` §Regional named NPCs) sits ringed by her own failed maps, every one contradicting the
   last. She has surveyed the Mirrormarsh a dozen ways and produced a dozen different lands;
   the fog rewrites her landmarks between one glance and the next, and it is driving her,
   dryly and thoroughly, mad.
2. **The lying land.** The Fool sees the problem first-hand at the fog-line: signposts that
   disagree, a hill that isn't where it was, a light that promises a path and delivers a
   loop. Without true light, the region will not resolve into anywhere — the gate is felt,
   not explained.
3. **The key.** Carrying a true light (Lantern raised, Wish's guiding glow, or plain
   daylight), the Fool can hold a real path open long enough to test Rue's theory — and the
   theory, worked out together over her ruined charts, is that the marsh can lie about
   everything it *shows* but nothing about where its water *goes*. Water obeys gravity even
   here; the Stall paused the marsh but could not make its flow run uphill.
4. **The transect.** The Fool traces the marsh's actual water-flow — downhill, thread by
   thread, toward the single real outlet the whole wetland drains to — while Rue records it.
   Where the fog offers a shortcut, the water refuses it; where a landmark lies, the current
   tells the truth. It is slow, careful, luminous work, and it holds.
5. **The honest beat / the laugh.** The finished line is the first true measurement anyone
   has ever taken of the Mirrormarsh. Rue is overcome — and immediately, defensively dry
   about it: a lifetime of cartography, and the answer was to stop trusting her eyes and
   follow a puddle downhill. She will be insufferable about water forever now.
6. **Closing beat.** Rue frames the finished map in her cottage — the region's one reliably
   honest document, drawn along the one thing in the fog that could not lie.
   - `[If WS_MOON_UNBOUND: the fog is gone and the marsh maps trivially now — but Rue keeps`
     `her water-map on the wall above all the accurate new ones, because it is the only map`
     `that was true while the land was still lying. A monument to honesty under deceit.]`

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (transect completed) | none — NPC-level only | Rue's honest map exists as a framed landmark / Almanack lore; her barks shift from despair to dry water-evangelism. No `WS_*` flag is set. |

## Consistency references

- `world.md` §Hard and soft gates (the Mirrormarsh's any-true-light gate — Lantern, Wish, or
  Sun — and the loop-out as the locked-door message; the quest's Introduction states it
  diegetically); §Hydrology rule (water begins high, flows downhill, ends at one real outlet —
  the mechanism of the whole insight); §The Mirrormarsh (paths, lights, and faces lie).
- `characters.md` §Regional named NPCs — Rue Aldous's entry (canon) is the design brief.
- `callings.md` §The Callings — Fog-warden ("walk the rope-line; guide the lost out"), the
  region role adjacent to Rue's work.
- `narrative.md` §Dialogue style guide (comic scene owning one honest beat; Fool lines ≤ 12
  words with an earnest option; no Querent wink spent).

## Open questions

- Should carrying true light *through* this quest teach the player the general "water reads
  true" traversal trick usable elsewhere in the Mirrormarsh (a reusable navigation aid), or
  stay flavour local to Rue? Recommend making it a genuine, subtle nav aid — it rewards the
  attentive player and rhymes with MQ18's true-light theme — but confirm it does not trivialise
  MQ18's own lying-path challenge.
- The marsh's single outlet is referenced but unplaced; its map position should be fixed in
  `world.md` alongside SQ-MERE-01's downstream marsh, since the two hydrology quests may share
  the same watershed. Flagged, not decided.
