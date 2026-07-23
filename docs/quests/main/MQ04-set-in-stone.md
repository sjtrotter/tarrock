---
id: MQ04
title: Set in Stone
type: main
status: outline
arcana: IV. The Emperor
region: The Bastion
requires: []
fires: [WS_EMPEROR_UNBOUND]
---

# MQ04 — Set in Stone

## Introduction

The player arrives at the Bastion to find a city that runs like clockwork because it is
terrified of what happens if it doesn't: granite grids, gong-timed streets, citizens
who live to the minute. At its center, unmoved since the Stall, sits a forty-foot
colossus of law-graven stone — the Emperor, who has not risen from his cube throne in
three centuries because his own law forbids amendment, including of himself. Reaching
him is bureaucracy before it is combat; climbing him is the fight.

## Beats

1. Arrival at the Bastion's outer gate: papers checked, gongs marking the hour, a city
   that has not missed a schedule in 300 years.
2. The Fool learns the law: no one approaches the Emperor's plinth without a Writ of
   Audience, issued only through proper channels.
3. Meet Clerk Anselm (canon, `characters.md` §Regional named NPCs), a Bastion functionary who processes the writ — brisk,
   correct, and quietly exhausted by a perfection he's never allowed to question aloud.
4. Approach step: a training climb across the city's monumental statues and scaffolding
   to reach a vantage over the plinth, teaching the climb in miniature before it matters.
5. Approach step: crossing a curfew checkpoint at the "wrong" hour — a timing puzzle
   against clockwork guard patrols who will not deviate from their own rota.
6. Reading the stasis: the Fool reaches the plinth and sees the colossus whole for the
   first time — Edicts carved into wrists, shoulders, and crown, unbroken since the Stall.
7. The climb-fight begins: the Fool scales the Emperor as he attacks on a strict,
   learnable rota — the fight plays as a timetable to be mastered, not survived.
8. Third Edict breaks; one remains. The Emperor does the single most frightening thing in
   the fight: he amends his own schedule, once, breaking the rhythm the Fool just learned.
9. The Fool adapts and reaches the crown; the final Edict cracks.
10. The colossus's grip on the rota fails entirely — his stone hands finally lower.
11. Unbinding: granite splits along the Edicts' old seams; his name returns to him, spoken
    formally, like a decree of one; he hands the Fool Trump IV personally.
12. Aftermath on the ground: the Bastion's gates are thrown open; curfew barks are
    replaced; a market stall suffers its first petty theft in 300 years, and the guards
    look almost relieved to have something ordinary to chase.
13. Closing: Clerk Anselm processes his last writ of the old order and doesn't quite know
    what to file it under.

## Key NPCs

- **The Emperor** (freed name Aldric, `characters.md` §IV) — built a perfect,
  unamendable law and has been strangled by his own perfection ever since; regards the
  Fool as a jurisdictional problem first, a person only once forced to.
- **Clerk Anselm** (canon, `characters.md` §Regional named NPCs) — a
  Bastion functionary who issues the Writ of Audience; correct on the surface, secretly
  tired of a rigidity he's never had the standing to question.

## Choices & branches

- No hard branch. Minor choice: the Fool may obtain the Writ of Audience honestly
  (a short fetch/paperwork chain with Anselm) or bluff/sneak past the checkpoint in
  beat 5 without it — changes Anselm's closing line but not the fight or unbinding.

## Mourning

**Clerk Anselm** mourns the unbinding: he built his entire professional identity on
flawless order, and a Bastion with petty crime in it again is a Bastion where his ledgers
no longer add up the way they used to.

## [If CONFESSED] variants

- The Emperor's "amend the schedule" moment reads differently post-MQ13: he already
  understands that no amendment saves anything permanently, since every order in the
  Spread is ending regardless — the line delivered mid-fight shifts from defiance to a
  kind of resignation.
- Clerk Anselm's writ-processing dialogue gains a line, if CONFESSED, worrying aloud that
  a world with no order left to keep isn't freedom, it's just an ending with the paperwork
  skipped.
- Aftermath barks acknowledge the Fool more explicitly as the one ending things, not
  merely freeing them — guards' relief in beat 12 curdles slightly toward unease.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_EMPEROR_UNBOUND` | Bastion gates open; curfew barks replaced; petty crime returns as new ambient crime events world-wide — freedom has texture. |

## Consistency references

- `arcana.md` §IV. The Emperor — colossus-climb design, Edicts, "amends the schedule", Trump IV.
- `world.md` §The Bastion — region sketch (granite grid, schedule-sacred citizens).
- `world.md` §World-state matrix (`WS_EMPEROR_UNBOUND`) — exact world effects.
- `characters.md` §IV. The Emperor — personality, "jurisdictional problem" framing.
- `narrative.md` §Themes (1, 2, 3) and §Act II (`CONFESSED` variants).

## Open questions

- What mechanically is the "amended schedule" attack at one-Edict-remaining — a new
  telegraph pattern, a tempo change, or a genuinely novel move never seen before?
  Encounter tier L already schedules full iteration effort for something bespoke;
  needs a combat-design decision.
- Should the Writ of Audience be a real inventory item/fetch-quest, or purely a dialogue
  gate with Anselm — affects whether this is a scripted beat or a small systemic sidequest.
