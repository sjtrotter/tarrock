---
id: MQ11
title: The Adjourned
type: main
status: outline
arcana: XI. Justice
region: The Assize
requires: []
fires: [WS_JUSTICE_UNBOUND]
---

# MQ11 — The Adjourned

## Introduction

The player steps into the Assize's fog-grey courts to find the game's driest joke:
every trial here has stood adjourned for three hundred years, the accused waiting in
patient, knitting queues, nothing ever actually decided. To reach the Magistrate the
Fool must first survive her own bureaucracy — and then survive her scales, which return
to the Fool exactly what the Fool has dealt her.

## Beats

1. Arrival at the Assize: fog-grey court complexes, queues of the accused knitting
   through their three-hundredth year of waiting.
2. The Fool meets Clerk Pettibone (canon, `characters.md` §Regional named NPCs), the archivist who has kept the queue's
   order since the Stall and takes visible pride in never having lost a single file.
3. Approach step: navigating the Assize's absurd bureaucracy — the correct docket, the
   correct stamp, the correct queue — to be granted a hearing at all.
4. Approach step: witnessing (and nudging toward resolution) a minor NPC dispute that
   nearly concludes before everyone realizes even this small case can't fully close —
   foreshadowing Trump XI's Past-slot "Arbitrate" effect.
5. Approach step: a small mock-trial puzzle in a lower courtroom, modeling the
   scales-fill-and-dump tempo of the real fight before the Fool ever meets her.
6. Reading the stasis: ascent to the highest, emptiest courtroom — the Magistrate,
   blindfolded, scales hanging motionless above an otherwise silent room.
7. The encounter, exactly per `arcana.md` §XI (real-time, like all combat): her scales
   fill with everything the Fool deals her; on a telegraphed courtroom-bell rhythm she
   fires the stored total back as a single dodgeable riposte. The fight is tempo —
   stagger her before the bell to dump the scales harmlessly. Cheap tactics (backstabs,
   mid-duel healing, reversed-Trump burdens dodged onto her) weigh double.
8. The fight quietly audits how the Fool has played the whole game so far — players
   should feel *seen*, not punished.
9. Final stagger: the scales dump for good, and a verdict — the first in three hundred
   years — finally renders.
10. Unbinding: the office cracks; her blindfold slips; her name returns; she hands the
    Fool Trump XI personally, precise even in this.
11. Aftermath: verdicts land across the Spread; Assize queues disperse; prisons empty —
    including three genuinely bad actors, Gorrister Vale, the Widow Culpepper, and
    Corvin "Ninefingers" Rook, each walking free to seed a later reckoning; NPC dispute
    events unlock world-wide.
12. Mourning: Clerk Pettibone's ledger empties overnight; he has no idea who he is
    without a queue to keep in order.
13. Closing beat: a single petitioner skips out of the fog for the first time in three
    hundred years, verdict in hand — the day's one unambiguous joy, played straight
    against Pettibone's quiet grief.

## Key NPCs

- **Justice** (freed name Prudence, `characters.md` §XI) — scrupulously fair, unable to
  render a verdict; the fight audits the player's own tactics.
- **Clerk Pettibone** (canon, `characters.md` §Regional named NPCs) —
  the Assize's archivist; this quest's mourning NPC.
- **Gorrister Vale, the Widow Culpepper, Corvin "Ninefingers" Rook** (canon,
  `characters.md` §Recurring named NPCs) — referenced only in aftermath (beat 11); each
  seeds a future side quest and is not otherwise present in this quest.

## Mourning

**Clerk Pettibone** mourns the unbinding: he has spent three centuries matching
petitioners to their case files, and a court that actually decides things needs a great
deal less filing.

## [If CONFESSED] variants

- Pettibone's introduction (beat 2) gains a line: he's heard what the Fool's journey
  costs the world, and half-hopes his ledger stays full a while longer yet.
- The Magistrate's dry courtroom-farce tone (beat 8) admits one real crack: she notes,
  precisely, that she is about to render the last verdict she will ever get to fear.
- The freed prisoners' release (beat 11) gains a darker undertone — the Fool has, by
  now, met people who mourn every ending; guilt does not exempt anyone from being freed
  too.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_JUSTICE_UNBOUND` | Verdicts land; Assize queues disperse; prisons empty (including three genuinely bad actors); NPC dispute events unlock. |

## Consistency references

- `arcana.md` §XI. Justice — mirror-scales fight design, tempo mechanic, Trump XI.
- `world.md` §The Assize — region sketch ("Kafka by way of Ealing comedy").
- `world.md` §World-state matrix (`WS_JUSTICE_UNBOUND`) — exact world effects.
- `characters.md` §XI. Justice; §Recurring named NPCs (the three freed prisoners).
- `narrative.md` §Themes (1, 2, 3), §Act II (`CONFESSED` variants).

## Open questions

- Should any of the three freed prisoners appear on-screen in this quest itself, or
  remain purely referenced in the aftermath beat (recommended, to preserve their side
  quests' reveals)?
- The exact list of "cheap tactics" that weigh double against the scales needs a
  concrete definition from `combat.md` before script status.
