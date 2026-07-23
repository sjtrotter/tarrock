---
id: SQ-SPREAD-01
title: The Scattered Deck
type: side
status: outline
arcana: none
region: The Spread (world-spanning — all 21 regions plus the Cliff)
requires: []
fires: []
---

# SQ-SPREAD-01 — The Scattered Deck

## Introduction

Somewhere in every region of the Spread, the Fool will start noticing small, specific,
too-deliberate things: a card-shape cut into a shadow, a glint behind a waterfall that
doesn't belong to the rockface, a bell that only rings true if struck in the right order.
These are the 56 Minor Arcana — the pip and Court cards of the Scattered Deck — thrown
loose across the world in the Stall and never gathered back up, because nobody but a
wandering card-reader ever thought to look. That reader is the **Cartomancer** (canon, `characters.md` §Regional named NPCs), met early and often, who is quietly trying to reassemble the deck for a reason she
never quite explains. The Fool doesn't need a checklist or a nag to play this: cards are
found by looking properly at a world built to reward it, brought back whenever
convenient, and the finding is the whole game — this is Tarrock's Korok-scale collectible
hunt, and it must never feel like homework.

## The Cartomancer

A named NPC (canon, `characters.md` §Regional named NPCs), met for the first time in whichever region the player finds their
first card, and encountered again — never at a fixed post, always somewhere plausible on
the road — every so often after.

- **Personality:** dry, itinerant, unbothered by weather or danger, treats the cards like
  old acquaintances rather than objects ("that one's always cold to the touch, don't
  mind it, it's shy"). Speaks in the same register as the Querent's warmth but without
  the wink — the Cartomancer is never fourth-wall aware, per `narrative.md`'s rule that
  the wink belongs to the Querent alone. Fond of the Fool without fussing over them;
  treats every card handed over as a small personal relief rather than a transaction.
- **What she knows:** more than she says, always. She never explains why she collects the
  deck, deflects the question every single time it's asked (a different deflection each
  time — the pool should run deep per `npc-system.md`'s dialogue-volume guidance), and
  occasionally says something that lands strangely true about the Fool's larger journey
  without ever naming the Querent, the Stall, or the twist. This is a controlled
  temperature, not a reveal: she may *gesture* at knowing what the Reading is, never
  *state* it. Nothing she says may pre-empt or contradict `narrative.md` §The Querent —
  her knowledge is texture, not exposition.
- **Never fixed to one region.** She is written as an itinerant — her "home" is the road
  between regions, reinforcing that she, like the Fool, belongs to no single suit-culture
  or place. This also solves scheduling: she can plausibly be encountered anywhere without
  needing a bespoke schedule per `npc-system.md`.

## Discovery philosophy (BotW-style: "that looks deliberate")

No card is ever hidden in undifferentiated scenery ("push every bush," "check every
barrel"). Every placement obeys one rule: **the environment must already look like it's
pointing at something**, so a careful player's own attention is the tool, not a detector
UI. Concrete placement patterns to draw from (illustrative, not exhaustive — the actual
56 are a content-design pass once regions are greyboxed):

- **Sightline bait.** A card visible from a high vantage but requiring a specific climb
  route or traversal Trump to actually reach (rewards Chariot mount, Overturn, feather-
  fall equally across the roster, not just one).
- **Small environmental puzzles**, never combat-gated: redirect a mixer's pour at the
  Confluence to reveal one behind a now-dry channel; ring the Chantry's bells in a
  specific short sequence; light three Dim lamps in view of each other at once; use the
  Veil's Truesight-adjacent logic (a reflection, a specific moonlit angle) to spot one in
  a pool.
  **hydrology tie-in:** at least one card per water-adjacent region (Maw, Dim, Mere,
  Confluence, Mirrormarsh, Noonlands) should reward *reading the water correctly* per
  `world.md`'s hydrology rule — a card tucked where a real spring, outlet, or confluence
  would have to be, never behind an arbitrary waterfall.
- **Callbacks to region character.** A card inside the Bower's single most overripe
  fruit, pickable only once a farmhand mentions which tree; a card in the Assize found by
  actually reading one scribe's absurd paperwork closely; a card wedged behind a fixed
  Gallowwood knot the Rope-Checker Calling has already taught the player to spot.
- **Never random grass**, never a "collectible glow" without a legible reason it's there.
  If a playtester's answer to "how did you find that" is "I swept the area," the
  placement has failed the rule.

## Density guidance per region

56 cards across 22 world-spaces (21 regions + the Cliff), weighted by difficulty band
(`world.md` §Intended difficulty bands) rather than spread flat — harder regions get
fewer but knottier puzzles; the Wheelhouse, already "the game's densest side-quest den,"
gets the deliberate bonus. The Axis gets none, on purpose (see below).

| Region / band | Cards | Note |
|---|---|---|
| The Cliff (tutorial) | 2 | Gentle, unmissable teaching placements — the player's first lesson in the "that looks deliberate" rule, before the game trusts them with anything harder. |
| Band 1 — Prestige, Bower, Divide, Chantry, Maw | 3 each (15) | Early, generous, confidence-building. |
| Band 2 — Noonlands, Bastion, Assize, Longroad, Confluence, Gallowwood, Dim | 2 each (14) | |
| Band 2 — Wheelhouse | 5 | Deliberate density bonus per its "densest side-quest den" billing. |
| Band 3 — Veil, Stillmarsh, Undervault, Spire, Mere, Mirrormarsh | 3 each (18) | Fewer regions, but each region's puzzles should be the hunt's trickiest — Band 3 traversal and Trump variety is assumed. |
| Hollows (finale, gated) | 2 | Placed with the region's tone — quiet, contemplative finds, nothing frantic. |
| The Axis | 0 | The still center holds nothing hidden. The Cartomancer, asked why, only ever says she "wouldn't dream of hiding anything there" — a small, deliberate mercy for a region that's meant to feel found, not searched. |

**Total: 56.**

## Reward ladder

Every reward stays inside `progression.md`'s closed set (coins, rose graftings, staff
heads, cosmetic outfits, Renown) — the hunt never invents a new reward category. The
ladder is keyed to raw count, not to completing a specific suit, so it stays fully
order-independent (a player may find cards from any suit in any order).

| Threshold | Reward |
|---|---|
| 7 / 56 | Rose grafting (+1 max petal) |
| 14 / 56 (one suit's worth) | Staff head — "the Reader's Wand," a light, quick-thrusting head the Cartomancer says was "never much use to me, but it might suit you" |
| 28 / 56 (halfway) | Outfit — the Cartomancer's travelling coat, cosmetic only |
| 42 / 56 (three suits' worth) | Rose grafting (+1 max petal, second one) |
| 56 / 56 (the full deck) | Small Renown lift across all four suits (word of the completed labor spreads, per `npc-system.md`'s rumor propagation) **and** the unique scene below |

**Bonus flavor, not a separate reward tier:** whenever the player happens to complete one
full 14-card suit, regardless of overall count or order, the Cartomancer gets one bespoke
line of dialogue recognizing it specifically ("all fourteen Cups, then. That's a full
telling of feeling, that is.") — texture on top of the ladder, never a gate.

### The 56/56 scene

Proposed, kept modest and story-true per the brief: on the last card, the Cartomancer
lays the complete Minor Arcana out on whatever surface is nearest — a fence post, a
Waystation bench, bare ground — and does one plain, wordless-mostly reading, not of fate,
but of the Fool's journey so far: she turns a few cards, names small true things about
choices the player actually made (data-driven from `READING_ORDER` and world-state where
feasible; otherwise generic-but-warm), and closes with one line that gestures at the
larger stakes without naming them — *"someone's listening awfully hard to how this all
turns out, I think. Best make it a good telling."* Then she folds the now-complete deck
away, thanks the Fool, and — the ache and the laugh both — asks whether they'd mind
terribly if she kept on walking anyway, since "a full deck's a good deal less interesting
to read than a road that's still being walked." She wanders off into the Spread exactly
as she always has, unresolved on purpose, and remains encounterable (rarer, no more
cards to give, just conversation) for the rest of the playthrough.

## The no-completionist-shame rule

The Almanack shows a **found count only, after the first find** (e.g., "Scattered Deck:
12"). It never shows a total-out-of-56 before the player has found at least one card
(no spoiling the hunt's scope up front), and it **never** lists which cards are missing,
where they are, or a per-region breakdown of misses. This is a diary of what's been
found, never a checklist of what hasn't — consistent with the Almanack's "Days Lived"
philosophy for Callings (`callings.md`) and its general hand-annotated-manuscript styling
(`art-audio.md`). A player who finds 9 of 56 and stops should feel like they had a nice
walk, not like they failed a test.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Any card found / any threshold reached | none | NPC-level and Almanack-level only; no `WS_*` flag is set or read by this quest. Card placements themselves may sit in regions whose *scenery* changes on an unbind (a card behind a waterfall in a region that later drains, for instance), but the quest system tracks find-state per card, not per world-state — see Open questions. |

## Consistency references

- `design/progression.md` §Currency, shops, and gear-lite; §The White Rose — the entire
  reward ladder is built only from rewards those sections already permit.
- `design/callings.md` §The Almanack — "Days Lived," no percentages, no checkmarks; the
  no-completionist-shame rule is a direct extension of that existing design intent.
- `design/world.md` §Hydrology rule — several placements are explicitly written to rely
  on reading water correctly, not to decorate around it.
- `design/world.md` §Intended difficulty bands — the density table's weighting.
- `design/npc-system.md` §Dialogue volume and pool-size targets — the Cartomancer's
  deflection lines need a deep pool to survive repeated encounters without repetition;
  §Rumor propagation for the 56/56 Renown lift's flavor.
- `design/narrative.md` §The Querent — the Cartomancer's "gestures, never states" rule is
  written specifically not to pre-empt or contradict this section.

## Open questions

- Should card find-state persist independent of world-state changes (a card behind a
  waterfall stays found even after `WS_TEMPERANCE_UNBOUND` drains the water around it),
  or does the environment change require the placement itself to relocate? Proposed:
  find-state is permanent and placement-independent once collected — a changed region
  should never be able to "lose" an already-found card or make an unfound one
  unreachable without an equivalent alternate route.
- Exact 56 placements are a content-design pass once each region is greyboxed — this
  outline fixes philosophy and density, not the individual card list.
