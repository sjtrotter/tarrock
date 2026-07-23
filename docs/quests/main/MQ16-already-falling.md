---
id: MQ16
title: Already Falling
type: main
status: outline
arcana: XVI. The Tower
region: The Spire
requires: []
fires: [WS_TOWER_UNBOUND]
---

# MQ16 — Already Falling

## Introduction

The player approaches the Spire, visible from half the Spread as a broken tooth against
the sky — a tower struck by lightning three centuries ago and frozen mid-collapse ever
since, rubble hanging in the air, staircases ending in open sky. The Warden at its
summit has spent all three hundred years refusing to let the fall finish. This quest is
a single vertical setpiece: the ascent through the frozen catastrophe *is* the fight, and
finishing it means the whole thing comes down — with the Fool riding it to the ground.

## Beats

1. **Arrival.** The Spire's base, ringed by a town built in permanent flinch-distance
   from a tower everyone insists could not possibly fall any further.
2. **Reading the stasis.** Locals point out the "lightning bell" — a warning system
   rigged generations ago for a strike that never quite finishes striking. Nobody has
   updated it. Nobody has needed to.
3. **Mini-challenge — the lower tiers.** A preamble climb through the Spire's stable
   lower floors, teaching the vertical traversal grammar (handholds, timed rubble
   shifts) the ascent will demand at full intensity later.
4. **Mini-challenge — the fallen climber's gear.** The Fool finds a rope and journal
   belonging to a previous adventurer who attempted the ascent and did not finish it —
   a found-lore beat that foreshadows the danger without invoking a body (tone: warm
   dread, not grimdark).
5. **Mini-challenge — the bell-keeper's warning.** The town's bell-keeper, Sorrel Vance
   (canon, `characters.md` §Regional named NPCs), begs the Fool to
   reconsider — not out of concern for the Fool, but because the tower's silhouette is
   the only skyline she's ever known, and she is afraid of what a changed horizon means
   for people who navigate by it. Plants this quest's mourning beat early.
6. **The ascent begins.** Per `arcana.md` §XVI: climbing suspended rubble as the
   Warden's lightning re-awakens gravity in patches, dropping whole staircases the
   Fool was about to use.
7. **Mid-ascent gimmick.** Lightning strikes read as a rota, not randomness — a
   learnable rhythm, per design rule 1 (card-first: sudden upheaval, mastered).
8. **The summit.** A short, desperate duel with the Warden — a crowned figure fighting
   bare-handed for a ruin, per `arcana.md` §XVI.
9. **Unbinding.** The office cracks with the same violence the lightning always
   promised. The Warden's freed name — **Balen** — returns, and the Trump
   XVI — Ruin — is handed over on the way down, because there is no "after" up here:
   the Tower is already falling.
10. **The fall (scripted descent).** The Fool rides the Spire's collapse to the ground
    — feather-fall (Overturn) and mounted (Triumph) players get style options per
    `arcana.md` design intent; all players land safe, only the manner of landing
    differs.
11. **Aftermath — the skyline.** Visible from every region in the game: the broken
    tooth is gone. Debris opens new cave routes at the Spire's base. Thunderstorms join
    the weather rotation world-wide.
12. **Aftermath — the bell-keeper.** Sorrel stands before her now-useless bell, and
    rings it anyway, once, for the tower that isn't there to hear it. She mourns a
    silhouette, not a monster.
13. **Closing beat.** The Querent, looking up at the new, ordinary sky: "There. Fewer
    teeth in the world's smile. Rather suits it."

## Key NPCs

- **The Warden (the Tower)** — canon, see `arcana.md` §XVI, `characters.md` §XVI.
- **Sorrel Vance, bell-keeper (canon, `characters.md` §Regional named NPCs)** — the quest's mourning NPC (beats 5, 12).
- **The fallen climber (mentioned only, not met)** — a found-journal device, beat 4;
  no new named NPC required if the journal stands alone.

## [If CONFESSED] variants

- Sorrel's warning (beat 5) gains a line: she's heard, by now, what all this
  unbinding adds up to, and rings her bell early "just to have said something first."
- The fallen climber's journal (beat 4), if `CONFESSED`, includes a line the climber
  clearly wrote *before* understanding the stakes — a small, sad dramatic irony rather
  than a tone shift.
- The Querent's closing line (beat 13) plays drier, with a beat of silence before it.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Unbinding the Warden | `WS_TOWER_UNBOUND` | The Spire finally falls — skyline change visible everywhere; debris opens new cave routes; thunderstorms join the weather rotation world-wide. |

## Consistency references

- `arcana.md` §XVI — ascent structure, lightning gimmick, summit duel, Trump XVI,
  scripted descent.
- `world.md` §The Spire, §World-state matrix, §Layout ("visible from every region").
- `characters.md` §XVI — personality (volatile, blunt, relieved to be fought); freed
  name Balen.
- `narrative.md` §Theme 3 — Sorrel's grief for a landmark, not a person, as a variant
  expression of "freedom isn't wanted by everyone."

## Open questions

- Should the fallen climber (beat 4) be promoted to a named, findable body/grave later
  (a small side-quest hook), or remain an unseen device? Recommend the latter to keep
  scope down, but flagging for side-quest writers.
- Does the scripted descent (beat 10) need a third "default" landing style for
  players with neither Overturn nor Triumph slotted, or is a basic fall-recovery
  animation sufficient? Needs a call from `combat.md`/`art-audio.md` at script status.
