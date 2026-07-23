---
id: MQ05
title: The Same Old Song
type: main
status: outline
arcana: V. The Hierophant
region: The Chantry
requires: []
fires: [WS_HIEROPHANT_UNBOUND]
---

# MQ05 — The Same Old Song

## Introduction

The player enters the Chantry to bells already mid-toll — the same hour, the same hymn,
rung since the Stall, a whole cathedral-town keyed to one endless note. To reach the
Hierophant the Fool must learn the hymn's own structure well enough to break it: not by
force, but by sabotaging the harmony that keeps him untouchable at the organ-colosseum's
center.

## Beats

1. Arrival at the Chantry: bells tolling the same hour they've tolled for 300 years,
   choir acoustics carrying from every stone surface in town.
2. The Fool meets Chorister Linnet (canon, `characters.md` §Regional named NPCs), who has sung the same hymn every day of
   her life and quietly aches, without knowing quite what for, for one new note.
3. Approach step: attending the endless service itself, a rhythm-tutorial disguised as
   worship, teaching the hymn's meter before the fight demands reading it.
4. Approach step: locating and redirecting three choir-pipes across the town's rooftops
   and bell towers, each guarded by bell-Blanks that ring the alarm if disturbed carelessly.
5. Approach step: silencing a stray bell-Blank loose in the town square, proving — to the
   Fool and to Linnet both — that the harmony can be broken without the sky falling in.
6. Reading the stasis: the Fool enters the organ-colosseum proper; the Hierophant
   conducts the eternal hymn from its center, untouchable while the harmony holds.
7. The fight begins: redirected pipes and silenced bells expose off-beat windows in his
   guard; his attacks arrive in strict, audio-telegraphed meter (with visual beat markers
   for accessibility).
8. Mid-fight, his practiced patience cracks — the flicker of real fear that the Fool
   might be right shows through the doctrine for the first time in three centuries.
9. The final choir-pipe redirected: the hymn breaks mid-note.
10. The Chantry falls silent — genuinely silent, not merely paused — for the first time
    since the Stall.
11. Unbinding: the office cracks like an organ pipe splitting; his name returns to him
    mid-breath; he hands the Fool Trump V personally, humbled rather than defeated.
12. Aftermath on the ground: the bells begin to ring new songs; ambient weddings and
    festivals resume across every settled region; Linnet sings something of her own
    making for the first time in her life.
13. Closing: the Fool leaves the colosseum to a town practicing a new hymn badly, and
    happily.

## Key NPCs

- **The Hierophant** (freed name Bede, `characters.md` §V) — once a genuine comfort to
  his flock, now reciting a sermon so worn it has stopped meaning anything, even to him.
- **Chorister Linnet** (canon, `characters.md` §Regional named NPCs) — a
  young singer who has never known a hymn besides the one, and quietly hopes for another.

## Choices & branches

- No hard branch. Minor choice: the Fool can encourage Linnet to improvise during the
  approach (small dialogue beat) — colors her closing-scene song but changes nothing
  mechanical.

## Mourning

**Brother Tolliver** (canon, `characters.md` §Regional named NPCs), an
elder chorister who has structured his entire life around the one certain hour, mourns
the unbinding: new songs mean the schedule he built his faith on is gone, and he isn't
sure what to pray by instead.

## [If CONFESSED] variants

- The Hierophant's flicker of fear in beat 8 becomes explicit dread post-MQ13 — he knows,
  by then, exactly what "the Fool might be right" costs the world, and says so between
  verses instead of merely flinching at it.
- Linnet's new song in the aftermath carries an elegiac note if CONFESSED — she has heard,
  by now, what unbinding the whole Spread means, and sings something closer to a eulogy
  than a celebration.
- Brother Tolliver's mourning bark shifts register: no longer grieving lost routine alone,
  but grieving that routine and time itself are both, eventually, ending together.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_HIEROPHANT_UNBOUND` | The bells fall silent, then ring new songs; weddings and festivals resume as ambient events in every settled region. |

## Consistency references

- `arcana.md` §V. The Hierophant — organ-colosseum fight design, meter/off-beat mechanic, Trump V.
- `world.md` §The Chantry — region sketch (doctrine as weather, choir acoustics).
- `world.md` §World-state matrix (`WS_HIEROPHANT_UNBOUND`) — exact world effects.
- `characters.md` §V. The Hierophant — personality, "practiced patience" framing.
- `narrative.md` §Themes (1, 2, 3), §Dialogue style guide (accessibility note), §Act II (`CONFESSED`).

## Open questions

- Should Brother Tolliver be introduced earlier in the approach (as a counterpoint to
  Linnet's hope) rather than appearing only at the mourning beat — affects pacing and
  whether he needs his own approach-step scene.
- Does the "new song" the town learns in the aftermath need to be an actual composed
  motif reused elsewhere (audio callback), or is it left undefined at outline stage?
