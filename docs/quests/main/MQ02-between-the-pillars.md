---
id: MQ02
title: Between the Pillars
type: main
status: outline
arcana: II. The High Priestess
region: The Veil
requires: []
fires: [WS_PRIESTESS_UNBOUND]
---

# MQ02 — Between the Pillars

## Introduction

The player follows the Longroad's western spur into permanent moonlit mist and finds a
cloister-library strung between two colossal pillars, its archivist nuns moving in
total silence. There is no monster gate here, no obvious boss door — only a rule,
repeated by every nun who will speak at all: *nothing is asked twice, and nothing is
told at all.* The player will need to earn an audience with the Veil's keeper, and then
pass — or fail — three tests that are not answered but *done*.

## Beats

1. Arrival: the Fool crosses onto the Veil's causeway; mist thickens until the two
   pillars are the only fixed points in the world, moonlight frozen at one angle.
2. First contact: Sister Amity (proposed), a young novice, meets the Fool at the
   gatehouse and whispers the cloister's one rule before vanishing back into hush.
3. Approach step — the Sleeping Scriptorium: the Fool threads a stealth passage between
   robed archivists dozing mid-sentence over their desks; waking one alerts the rest.
4. Approach step — the Ushering Bell: a small puzzle to find the one cloister bell not
   yet cracked with age, buried among a dozen silent, broken decoys, and ring it to be
   granted audience.
5. Reading the stasis: the Fool reaches the inner cloister — every shelf sealed in wax,
   every book unopened for 300 years, and between the pillars, the Priestess, mid-thought
   since the Stall.
6. The Silent Examination begins. First task: bring what the Veil lost — the Fool
   retrieves a torn index-page from an owl's nest high in the bell tower.
7. Second task: stand where the moon can't see — the Fool searches the courtyard's
   moon-dial for the single flagstone locked in the second pillar's permanent shadow.
8. Third task: be told a secret and keep it. The Priestess (or, in her silence, Sister
   Amity as proxy) confides something true and painful. The dialogue never marks the
   correct choice — declining to repeat or press it is the only honest answer.
9a. If all three are honored: no staff is drawn. The exam simply ends; the Priestess is
   visibly unsettled that a stranger passed a test she built to be failed.
9b. If any answer is false: her shadow peels off the pillars and duels the Fool — fast,
   punishing, mirroring the Fool's own last move a half-beat late.
10. Unbinding: whichever path closes it, the wax seals on both pillars crack at once. Her
    name returns to her before it returns to anyone else; she says it to herself first,
    testing its weight, then hands the Fool Trump II personally.
11. Aftermath on the ground: the mist thins across the whole Veil; sealed doors the
    cloister never advertised become visible without needing the Trump at all.
12. The nuns begin to dream — a new, murmuring bark pool replaces the total hush, some
    of it delighted, some of it disturbed to be dreaming again at all.
13. Closing: the Fool leaves by the causeway they entered by, and for the first time it
    is genuinely quiet behind them, rather than merely silent.

## Key NPCs

- **The High Priestess** (freed name Vesper, `characters.md` §II) — reads the Fool
  completely on sight and resents how little that tells her about what happens next.
- **Sister Amity** (proposed — promote to characters.md before script status) — a young
  novice archivist, the cloister's one talkative exception; guides the Fool through the
  gatehouse and the Sleeping Scriptorium, and is quietly thrilled and terrified by
  visitors.

## Choices & branches

- The examination's three tasks are not a dialogue-tree branch but a hidden pass/fail
  state tracked across the whole encounter (honest vs. any lie); no UI ever confirms
  which the player is on. This is the quest's one true choice moment and it is meant to
  feel like it isn't one.
- Minor choice: whether the Fool presses Sister Amity for gossip about the Priestess
  during the approach. Pressing colors her later reactions (a little wounded) without
  gating anything mechanical.

## Mourning

**Sister Amity** mourns the unbinding in miniature: the hush she took her vows into is
already softening into ordinary noise, and she isn't sure yet whether a cloister that
dreams and gossips is still a cloister she recognizes.

## [If CONFESSED] variants

- The Priestess already half-suspects the truth before the Fool arrives — she reads
  people, after all. Post-MQ13, her "third task" secret is not a small cloister grief but
  a quiet question about whether the Fool knows what they're doing to the world; the
  dialogue no longer marks silence as clearly correct, since silence now *is* an answer.
- Sister Amity's gatehouse whisper gains a second line, delivered only if CONFESSED:
  half-joking that the nuns have started dreaming of endings, not just of new songs.
- The cloister's new bark pool (post-unbinding) shifts tone: dreams described in barks
  turn from wonder to something closer to premonition.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion (either exam path) | `WS_PRIESTESS_UNBOUND` | Veil's mist lifts world-wide; hidden doors become visible to all players without the Trump; NPCs begin dreaming — new ambient bark pool everywhere. |

## Consistency references

- `arcana.md` §II. The High Priestess — encounter design, honest/lie fork, Trump II.
- `world.md` §The Veil — region sketch (stealth/riddle flavor, archivist nuns).
- `world.md` §World-state matrix (`WS_PRIESTESS_UNBOUND`) — exact world effects.
- `characters.md` §II. The High Priestess — personality, "no shelf for the Fool" framing.
- `narrative.md` §Themes (1, 2, 3) and §Act II (`CONFESSED` variants).

## Open questions

- Should the "secret" in task three vary in content depending on how much prior gossip
  the player extracted from Sister Amity, or stay fixed for scripting simplicity?
- Does the shadow-duel (dishonest path) still yield the Trump identically, or should its
  reward text acknowledge the harder road (per arcana.md: "liars earn it the hard way")?
