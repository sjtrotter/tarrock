---
id: MQ19
title: The First Sunset
type: main
status: outline
arcana: XIX. The Sun
region: The Noonlands
requires: []
fires: [WS_SUN_UNBOUND]
---

# MQ19 — The First Sunset

## Introduction

The player arrives in the Noonlands — golden grain country under a sun nailed at noon
for three hundred years — to meet Aurel, the region's undefeated child-knight, who
greets the news of a challenger with pure, unguarded delight: nothing new has happened
in his entire long childhood. This quest is the game's trailer moment. Its fight teaches
one clean lesson (read the shadow, not the radiant body), and its aftermath — the first
sunset in three centuries, playing out in real, visible time while Aurel grows up inside
it — is the most visually scripted sequence in the whole main-quest line. The Noonlands'
creeping drought and sunstroke sidequests resolve the moment the sun finally moves.

## Beats

1. **Arrival.** Fields of sunflowers turned permanently toward a sun that never left
   noon; harvest-festival bunting decades faded but never taken down.
2. **Reading the stasis.** A festival organizer explains, cheerfully, that today is
   always the harvest festival, which was lovely for the first few decades. The drought
   creeping in at the fields' edges is the tell the cheer is papering over.
3. **Mini-challenge — the qualifying bouts.** The Fool fights through a short ladder of
   the coliseum's local champions to earn a match with Aurel himself — Aurel's own
   arena runs on open challenge, and he has quietly outlasted everyone who ever tried.
4. **Mini-challenge — reading shadows.** A tutorial bout (a squire, or a training
   dummy rigged with the same radiance trick) teaches the fight's single lesson before
   the real one: Aurel's own glow whites out normal tells, but his shadow on the sand
   telegraphs every move honestly.
5. **Meeting Aurel.** Personal, warm banter before the fight — Aurel treats the
   challenge like the best gift he's been given in decades, because it is.
6. **The duel.** The sunflower coliseum at permanent high noon, per `arcana.md` §XIX:
   joyous, breakneck, radiance whiting out his body while his shadow tells the truth.
7. **The loss.** Aurel loses — and laughs. Genuinely, immediately, delighted rather
   than devastated, per his characterization in `characters.md` §XIX.
8. **Unbinding.** The office cracks like a held breath finally let go. Aurel's name was
   already known (canon, per `GLOSSARY.md` and `characters.md`) — but per the bound-
   Arcanum dialogue rule, this is the first time he says "Aurel" of himself, first
   person, laughing through it.
9. **The first sunset begins (the trailer sequence).** The sun — nailed at noon for
   three hundred years — visibly, physically begins to move for the first time. Shadows
   across the whole coliseum lengthen in real time. The crowd falls silent, then
   erupts.
10. **The sunset, scripted.** Gold shifts to amber, amber to violet, across the whole
    visible Noonlands horizon — sunflowers slowly turning to track a sun that is, for
    the first time in living memory, actually setting. This is the single largest
    lighting/art beat in the main-quest line; every region with sightline to the
    Noonlands sky should register the color shift.
11. **Aurel grows up.** Over the course of the sunset, in view of the player, Aurel
    visibly ages from child-knight to young man — a virtue finally given an evening to
    rest into. Play this tenderly, not as body-horror: a relief, not a loss.
12. **First night.** As full dark falls — the Spread's first true night in three
    centuries — `[If WS_STAR_UNBOUND]`: the Mere's returned stars are visible in full
    immediately, since the night they were waiting for now exists. `[If NOT
    WS_STAR_UNBOUND]`: the first sky is dark but starless, ordinary night without the
    Star's blessing yet — equally beautiful, differently so, and consistent with the
    order-independence rule (`world.md`).
13. **Aftermath — the mourner.** Bramble Coss (proposed — promote to characters.md
    before script status), the festival organizer from beat 2, watches the first
    sunset with open grief rather than joy: the endless festival was the only life she
    ever planned for, and she has no notion what a calendar with actual days in it is
    for. She doesn't ask for noon back. She just needs a minute.
14. **Closing beat.** The Querent, watching the color drain out of the sky for the
    first time in the game: "There it goes. Go on and watch, little Excuse — you
    earned this one." One wink, spent entirely on wonder rather than a joke.

## Key NPCs

- **Aurel (the Sun)** — canon, see `arcana.md` §XIX, `characters.md` §XIX.
- **Bramble Coss, festival organizer (proposed — promote to characters.md before
  script status)** — the quest's mourning NPC (beats 2, 13).
- **The squire or training-dummy rig (proposed — promote to characters.md before
  script status)** — delivers the shadow-reading tutorial (beat 4); may remain an
  unnamed device if scope requires.

## [If CONFESSED] variants

- Bramble's grief (beat 13), if `CONFESSED`, includes a line that she knows the
  festival was never going to be forever regardless — which doesn't make watching it
  end any easier.
- Aurel's pre-fight banter (beat 5) gains a beat of real curiosity about what growing
  up costs, if he's heard enough by now to wonder.
- The Querent's closing wink (beat 14) plays a half-second longer before the line, if
  `CONFESSED` — the wonder shares space with knowing what the wonder costs.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Unbinding Aurel | `WS_SUN_UNBOUND` | The first sunset in 300 years (set-piece); global day/night cycle begins; nocturnal content unlocks everywhere; Noonlands cool, drought sidequests resolve; night-dependent content (e.g. Star's sky) becomes fully visible per order-independence rule. |

## Consistency references

- `arcana.md` §XIX — duel design (read the shadow), Trump XIX, unbinding, "the
  trailer moment" framing.
- `world.md` §The Noonlands, §World-state matrix, §Interaction rules (order-
  independence with `WS_STAR_UNBOUND`).
- `characters.md` §XIX — Aurel's canon name and personality (real cheer, real
  exhaustion, envy of aging).
- `narrative.md` §Theme 3 — Bramble's grief for the endless festival.
- `art-audio.md` — the sunset sequence is this quest's single largest asset; flag as
  a priority pass at script status.

## Open questions

- Confirm the exact visual budget for beat 10 (region-wide sky shift) with
  `art-audio.md` — the note above assumes every region with Noonlands sightline
  updates, which may be a significant lighting-system cost.
- Aurel's aging (beat 11) needs an art-direction call: a smooth morph, a series of
  discrete stages, or a single cut? Tone note: avoid anything that reads as loss.
- Should the qualifying-bout ladder (beat 3) be skippable for returning players or
  higher-Renown saves, given it's a soft gate rather than a hard one?
