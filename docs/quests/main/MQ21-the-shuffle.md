---
id: MQ21
title: The Shuffle
type: main
status: outline
arcana: XXI. The World
region: The Axis
requires: []          # always open — the finale is a right, not a reward (world.md §gates)
fires: [WS_WORLD_UNBOUND]
---

# MQ21 — The Shuffle

## Introduction

The Axis has been open since the moment you landed in the Spread; the dancer at its
center has been visible from every region of the game. This quest begins the moment you
step inside the wreath of white stone — at hour two or hour forty, with zero Trumps or
all twenty. Nothing stops you but the fight itself: every Arcana still bound lends the
Dancer their office as a full phase. What you are walking into, and whether the world
survives you finishing it, depends entirely on the journey you did or didn't take first.
This quest owns all three endings ([`narrative.md`](../../design/narrative.md) §Endings).

## Beats

1. **The threshold.** Crossing into the Axis silences everything — no music but the
   distant dance rhythm ([`art-audio.md`](../../design/art-audio.md) §Music), no
   weather, no barks. Pip walks ahead, calm; he has been here before. The Querent stops
   narrating mid-sentence for the first time in the game. The silence where their voice
   should be is the beat.
2. **The approach.** The long walk through the wreath-amphitheater. On its inner walls:
   twenty-one alcoves, one per Arcana. Unbound Arcana's alcoves hold their card,
   face-up, at rest; bound Arcana's alcoves stand hollow and humming. The player reads
   their own journey as architecture before the fight makes it mechanical.
3. **The Dancer.** First close look at The World: the previous Fool — travel-worn
   clothes under the wreath's silver, a bindle long since set down at the edge of the
   dance floor, and beside it a withered white rose. They do not stop dancing to speak.
   Bound-Arcana dialogue rule holds: they never say "I" with a name — but the player is,
   by now, equipped to notice *why* that rule has always existed.
4. **The offices borrowed (fight, part one).** Per [`arcana.md`](../../design/arcana.md)
   §XXI: one phase per still-bound Arcana, borrowed movesets in compressed form, fought
   in the order of the card sequence. Each phase begins with the hollow alcove flaring
   and the Dancer taking up that office's silhouette. (Fully unbound saves skip this
   part entirely.)
5. **The duel (fight, part two).** With nothing left to borrow: two Fools. No gimmick,
   no adds — the deliberate rhyme with MQ13's purity. The Dancer fights with the
   player's own move vocabulary (Bindle forms, dodge, block-step, Fool's Chance) —
   the mirror the Anti-Fool faked in MQ18, made sincere.
6. **The yield.** The office cracks. The Dancer's freed name returns — and the game
   withholds it from the player deliberately: they say it *to Pip*, quietly, and Pip
   wags. It was never ours to hear. They ask the only question of the scene:
   **"Do you know what turning it does?"** — with dialogue variants:
   - `[If CONFESSED]` the Fool's options are steady; the Dancer nods: "Good. He told
     you. He told me too, my time round."
   - `[If NOT CONFESSED]` (rushed run): the Dancer explains it themselves — harder,
     shorter, without Mortimer's kindness. The Early Shuffle ending will keep this tone.
7. **The Fool's Reading, read.** Only on a fully-unbound save (True Shuffle path): the
   Querent lays the player's 21 cards out on the Axis floor **in the order the player
   turned them** — *"your reading, little Excuse — you've been dealing it since the
   cliff"* — and reads three positions aloud per
   [`narrative.md`](../../design/narrative.md) §The Fool's Reading: the first card
   (*how the world woke*), the eleventh (*the heart of the journey*), and the last
   before The World (*the world's final lesson*). Line variants per card × position are
   this quest's second-largest scripting matrix (see Open questions).
8. **The Querent's answer.** Immediately after the reading, still True Shuffle path
   only: the Querent finally answers the question the player has been allowed to ask
   since MQ00 — *who is this Reading for?* — per narrative.md §The Querent. The reveal
   is delivered looking outward from the Axis: every region of the Spread visible at
   once, all of it awake, all of it listening. The world has been asking how its story
   ends. The Fool is the answer it finally had the courage to hear.
9. **THE CHOICE (first pick commits; the game's last input).**

   | Choice | Consequence |
   |---|---|
   | Turn the card | The Shuffle (ending per save state — beats 10a/10b) |
   | Not yet | The Refusal (beat 10c) |

10. **Endings** (all owned here; summaries in narrative.md §Endings):
   - **10a. The True Shuffle** (all 21 unbound): the gathering-up — regions fold closed
     like cards being collected **in the order the player unbound them** (the world
     ends in the order it woke), each with a one-line farewell drawn from that region's
     quest choices (this outline's biggest scripting cost: 21 farewell variants ×
     branch states; see Open questions). The gathering's tone is styled by the last
     card turned before The World; the ending's opening image and the new deal's dawn
     are styled by the first (narrative.md §The Fool's Reading). The previous Fool
     takes up their bindle at last and walks off the edge of the Axis, upward. Our Fool
     takes the center. The rose blooms. Final scene: a new deal — a new cliff, a new
     campfire, a new Fool waking; one small detail from the player's journey persists
     (see Open questions); Pip is already there, watching them wake. Credits over the
     Fool's journey theme, resolved.
   - **10b. The Early Shuffle** (1–20 still bound): the same gathering-up, but the
     farewell lines are replaced by what never woke — the frozen regions fold still
     frozen, mid-gesture, unfinished. Shorter, harsher montage, and deliberately
     **unstyled by the Reading** (an incomplete reading reads as nothing — narrative.md
     §The Fool's Reading; the Querent's identity also stays unrevealed). The new Fool
     still wakes at the cliff; the deal goes on. The game does not scold; it just shows.
   - **10c. The Refusal**: the Fool walks back down the Axis. The Querent: "Then we'll
     say — not yet." Play continues at the current world state; NPCs begin, gently, to
     age (`[If WS_DEATH_UNBOUND]`); the Axis stays open; this quest can be re-entered
     any time. No credits. The Refusal is respected, never punished — but the world's
     "last days" content (Act III, world.md) keeps quietly asking.

## Key NPCs

- **The Dancer / The World** — the previous Fool ([`characters.md`](../../design/characters.md)
  §XXI defers here and to narrative.md; this quest owns their voice: brief, kind, very
  tired, drily funny about the dancing — "Three hundred years. I never learned a second
  dance.").
- **Pip** — load-bearing throughout: calm at the threshold, greeted by name (the only
  being the Dancer names aloud), present in every ending. Pip is the continuity between
  deals; the game never says so.
- **The Querent** — silent at the threshold, answering at the summit. Their single
  fourth-wall wink for this quest is reserved for the final line before the choice
  (see Open questions — it must be the best line in the game, so it is not drafted in
  an outline).

## Mourning NPC

The whole world, in the farewell montage — but specifically: on the walk to the Axis
(Act III state), one ordinary Minor NPC stands at the Axis threshold with a packed bag,
having walked from wherever the player first helped them, just to see the Fool go in.
Which NPC appears is chosen from the player's completed side quests (highest-Renown
suit breaks ties). They don't try to stop the Fool. They just wanted to be there.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Turning the card | `WS_WORLD_UNBOUND` | The Shuffle: ending sequence per save state; credits (10a/10b) |
| The Refusal | none | World persists; Axis re-enterable; ambient aging begins |

## Consistency references

- `narrative.md` §The Twist, §The Querent, §Endings — this quest is their execution.
- `arcana.md` §XXI — fight structure (borrowed phases → pure duel), no Trump granted.
- `world.md` §Hard and soft gates (Axis always open), §Global states (Act III content).
- `characters.md` §Pip (protection rule holds — no ending harms Pip), §The Querent.
- `art-audio.md` §Music (the Axis near-silence; the unbinding stinger's final, largest use).
- MQ13 (`main/MQ13-an-ending.md`) — the confession scene this quest's variants key off;
  MQ18 — the Anti-Fool mirror this duel makes sincere.

## Open questions

- **The persisting detail in 10a** (what carries from the player's journey to the new
  Fool's cliff): the strongest candidate is the keepsake dug up by Pip in MQ00 — decide
  once MQ00's keepsake is locked, and keep the loop closed (the keepsake was *ours*).
- **The Querent's final line** (the pre-choice wink): to be written at script status by
  a human-level pass; the outline deliberately refuses to draft it.
- **Farewell-line matrix cost** (10a): 21 regions × branch states is the single largest
  localization/VO line-count item in the game; the Reading recital (beat 7) adds a
  second matrix of 21 cards × 3 positions (63 short lines). Both are wanted — we
  iterate until they're all good rather than cutting them (GDD §Iteration clause) —
  but sequencing/VO batching needs a plan at M4.
- **Early Shuffle phase tuning**: are 21 compressed phases actually beatable at hour
  two on Journey difficulty? Must be *possible* (BotW rule) — define the compression
  budget per borrowed office at combat-prototype time.
- **Refusal saves at credits**: if a player refuses, later turns the card, do we replay
  beats 7–8 (the Reading recital and the Querent's answer)? (Proposed: yes, abridged.)
