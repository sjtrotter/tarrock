---
id: MQ20
title: The Last Trumpet
type: main
status: outline
arcana: XX. Judgement
region: The Hollows
requires: [WS_DEATH_UNBOUND]
fires: [WS_JUDGEMENT_UNBOUND]
---

# MQ20 — The Last Trumpet

## Introduction

The player enters the Hollows only after Death has been unbound — the graves here
could not open while nothing was able to leave, and now they can. Terraced graveyards
ring the Axis approach, tended for three centuries by a Herald with a trumpet and no one
yet able to answer its call. This quest's fight is a conversation between two Trumps:
the Herald raises the Fool's fallen enemies mid-battle on a meter the player can watch
fill, and Passage's Reap (if slotted) denies the resurrection outright — kill order
becomes the whole puzzle. Because this quest is hard-locked behind MQ13, every scene
here plays in the post-confession world as a baseline, not a variant.

## Beats

1. **Arrival.** The Hollows' terraces, tended and waiting, headstones catching low
   light. This is the first area the player has seen that was *always* going to open —
   it was simply waiting for permission.
2. **Reading the stasis.** A ghost NPC explains, without self-pity, that they've been
   waiting to be called for three hundred years, and that waiting stopped being painful
   somewhere around year fifty. It just became Tuesday.
3. **Mini-challenge — the terraces.** Navigating the amphitheater's terraced graves
   means dealing with restless minor hauntings (not the boss) — small, contained
   scuffles that foreshadow the kill-order puzzle to come.
4. **Mini-challenge — the reluctant ghost.** One spirit, Fennimore Ashgrove (proposed
   — promote to characters.md before script status), begs the Fool not to hurry things
   along on his account. He isn't ready to be called yet, whatever the Herald's meter
   says. Plants this quest's mourning beat early.
5. **Mini-challenge — the ancestor shrines.** A handful of shrines around the
   amphitheater's rim, currently inert, that the player learns give "final gifts" once
   Judgement is unbound — seeding the payoff in beat 12 rather than surprising the
   player cold.
6. **Arrival at the amphitheater.** The Herald waits at the center: an angel with a
   trumpet, solemn, patient, carrying the grief of a duty perpetually almost-done.
7. **The encounter, phase one.** Per `arcana.md` §XX: the trumpet blast raises fallen
   enemies mid-fight, on a visible meter — every kill is provisional until the meter is
   managed.
8. **The encounter, phase two — kill order.** The fight's real puzzle: which enemies
   to end last, which to leave until the meter resets, and — if the player has Trump
   XIII (Passage) slotted — using Reap's execute to deny a resurrection outright, per
   the deliberate cross-Trump synergy in `arcana.md`.
9. **The falter.** The Herald's own trumpet finally sounds a note that doesn't raise
   anything — the first silence in the fight, and the tell that the office is cracking.
10. **Unbinding.** The office cracks. The Herald's freed name — **Clemency** —
    returns, and Trump XX — Reveille — is handed over, the trumpet lowered for the
    first time in three centuries.
11. **Aftermath — every waiting ghost.** Ghost NPCs across the whole Spread say their
    goodbyes at once — every "waiting" sidequest thread the game has planted since
    MQ13 closes here, in one wave, region by region.
12. **Aftermath — the shrines.** The Hollows' ancestor shrines activate, giving final
    gifts to those who tended them.
13. **Aftermath — the Hollows bloom.** The terraces green over; the amphitheater of
    open graves becomes, visibly, a garden rather than a waiting room.
14. **Aftermath — the mourner.** Fennimore, from beat 4, is the last ghost in the
    Hollows to fade — he lingers a beat longer than everyone else, admits he still
    isn't ready, and fades anyway, gently, because the call doesn't actually wait for
    ready. This is the quest's clearest expression of "freedom isn't wanted by
    everyone": even a mercy, delivered on schedule, can still ache.
15. **Closing beat.** The Querent, watching the Hollows empty and bloom at once: "That
    was the last of the waiting, little Excuse. Everyone's been let go now. Including,
    I think, you."

## Key NPCs

- **The Herald (Judgement)** — canon, see `arcana.md` §XX, `characters.md` §XX.
- **Fennimore Ashgrove, a reluctant ghost (proposed — promote to characters.md before
  script status)** — the quest's mourning NPC (beats 4, 14).
- **A waiting ghost at the terraces (proposed — promote to characters.md before
  script status)** — delivers beat 2's tone-setting line; may remain unnamed if scope
  requires.

## [If CONFESSED] variants

- This quest is hard-gated behind `WS_DEATH_UNBOUND`, and `CONFESSED` is set the
  moment MQ13 completes (`world.md` §Global states) — every scene in this quest is
  therefore, by construction, always in the post-confession state. There is no
  un-confessed variant to write. This is noted explicitly rather than silently
  omitted, since every other MQ from 02 onward is expected to carry both.
- Where this quest still varies is **how far Act III has progressed** (7–14 vs. 15–21
  Arcana unbound at time of play) — ghost barks in beat 2 and the goodbye wave in
  beat 11 should scale in volume/specificity with Arcana count, not with `CONFESSED`
  itself.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Unbinding the Herald | `WS_JUDGEMENT_UNBOUND` | Ghost NPCs across the Spread say goodbyes, closing every "waiting" sidequest; the Hollows bloom; ancestor shrines give final gifts. |

## Consistency references

- `arcana.md` §XX — Herald encounter, kill-order/resurrection-denial design, Passage/
  Reveille synergy, Trump XX, unbinding.
- `world.md` §The Hollows, §Hard and soft gates (Death→Judgement, the one other hard
  story gate besides the Mirrormarsh), §World-state matrix.
- `characters.md` §XX — personality (solemn, patient, grief of almost-done duty);
  freed name Clemency.
- `narrative.md` §Global states (`CONFESSED` fires at MQ13, guaranteeing this quest's
  always-confessed state), §Theme 3 (Fennimore's reluctance).
- MQ13 (`main/MQ13-an-ending.md`, if present) — the confession this quest's baseline
  assumes throughout.

## Open questions

- Since `CONFESSED` cannot meaningfully vary here, should the "both variants" rule in
  `quests/README.md` be formally amended to exempt gate-locked-post-MQ13 quests (this
  one, and any future one gated the same way), or is the explicit "no variant to
  write" note (as given above) sufficient documentation on its own?
- How many of the Spread's "waiting" ghost threads (beat 11) are expected to exist by
  the time this quest is written at script status? Needs a cross-region survey once
  side-quest docs exist, to avoid this quest silently promising closures that were
  never seeded.
