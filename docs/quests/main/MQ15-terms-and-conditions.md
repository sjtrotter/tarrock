---
id: MQ15
title: Terms and Conditions
type: main
status: outline
arcana: XV. The Devil
region: The Undervault
requires: []
fires: [WS_DEVIL_UNBOUND]
---

# MQ15 — Terms and Conditions

## Introduction

The player descends into the Undervault — the only region with no sky — to find the
game's darkest comedy: a gilded pit-city where everyone signed for their own chains and
will insist, cheerfully, that they're delighted with the arrangement. Old Nick Lowry
receives the Fool at a beautiful desk before any fight begins, and offers three real
deals for three real prices. This negotiation, not the swordplay after it, is the heart
of the quest: every buff he offers works exactly as advertised, and every cost he asks
for is paid in full. The player chooses how comfortable to get before finding out what
comfort costs.

## Beats

1. **Arrival.** The descent past the Undervault's gate — the last sky the Fool will see
   until they climb back out. Warm gaslight, velvet rope, a queue of chained residents
   who all, unnervingly, seem to be having a lovely time.
2. **Reading the stasis.** A resident (Coins-culture, ledger at her belt) explains her
   chain proudly: it bought her comfort she'd never otherwise have had, and she'll not
   hear a word against the arrangement. The horror is that she isn't lying.
3. **Mini-challenge — the antechamber trials.** Three short vignettes on the way to the
   desk, each modeling a small, honest bargain already struck by a minor NPC (a
   gambler who traded his luck, a singer who traded her silence, a mother who traded a
   grief for a memory) — priming the player for what an honest devil's contract feels
   like before the real one is offered.
4. **Mini-challenge — reading the fine print.** A puzzle room where a contract's real
   terms are written backward, in mirror-script, or in undersized print — solving it
   (a light literacy/observation puzzle) is the quest's nod to "fine-print stock" (Trump
   XV Past slot) before the player has the Trump.
5. **The desk.** Old Nick Lowry receives the Fool personally, unhurried, delighted to
   have a new signature to collect. Pip growls, once, at the foot of the stairs — the
   only warning the game gives before the negotiation.
6. **THE NEGOTIATION (all three may be taken, none, or any subset; first pick per term
   commits for the fight).**

   | Contract | Real buff (for the fight only) | Real term (paid immediately) |
   |---|---|---|
   | The Coin Clause | +50% Fortune generation for the encounter | An honest cut of carried coin, taken from the purse on the spot, gone for good |
   | The Flesh Clause | White Rose fully reblossoms, +1 petal capacity for the encounter | One petal of maximum White Rose capacity, surrendered — a real, persistent cost until addressed by later systems (see Open questions) |
   | The Companionship Clause | A spectral second mimics the player's current Present-slot Trump throughout the fight | **Pip waits outside.** The gate shuts. Pip can be heard, faintly, the whole fight. |

7. **Taking none.** The fight is offered brutal and proud, no strings — Nick respects
   this answer more than any other, and says so.
8. **Taking all three.** Nick barely needs to raise a hand. Mid-fight he exercises a
   clause buried in the print: he borrows the Fool's equipped Trumps and casts them
   reversed, against the Fool, once. Every contract was honest. That's the horror.
9. **The encounter.** Per `arcana.md` §XV: chains, the pit's gilded tiers, and whatever
   the player brought into the room with them — literally, mechanically.
10. **The falter.** Beneath the contracts and the charm, Nick fights like a man who's
    forgotten what losing feels like — and remembers, badly.
11. **Unbinding.** The office cracks. He has always answered to "Old Nick Lowry" — the
    Undervault's own residents use it daily — but per the bound-Arcanum dialogue rule
    (`narrative.md`), he has never once said it of himself, first person, until now:
    "Nick," he says, testing the word like cutlery he hasn't held in years, and hands
    over Trump XV — Bargain — with both hands, like a man closing a ledger for good.
12. **Aftermath — the chains fall.** Across the Undervault, chains open. Most residents
    leave, dazed, blinking at unfamiliar daylight for the first time in decades.
13. **Aftermath — the mourner.** Not everyone climbs out. Merrow Slate (proposed —
    promote to characters.md before script status), the gambler from beat 3, walks
    partway up the stair, stops, and walks back down — quietly re-latching his own
    empty chain out of habit, because comfort, once worn long enough, fits like skin.
    This is per `world.md`'s explicit note that some freed folk walk back down.
14. **Closing beat.** The Querent, watching Merrow descend again: "Freedom's a
    door, little Excuse. Nobody's obliged to walk through it twice."

## Key NPCs

- **Old Nick Lowry (the Devil)** — canon, see `arcana.md` §XV, `characters.md` §XV.
- **Merrow Slate, a freed gambler (proposed — promote to characters.md before script
  status)** — the quest's mourning NPC (beats 3, 13); embodies the "some walk back
  down" world-state note.
- **The chained resident at the gate (proposed — promote to characters.md before
  script status)** — a Coins-culture minor NPC, delivers beat 2's tone-setting line.

## [If CONFESSED] variants

- Nick's antechamber vignettes (beat 3) gain a line acknowledging the Fool's larger
  purpose: he offers a fourth, unofficial observation — "you're spending down the
  whole world's chains, aren't you" — spoken with something closer to respect than
  mockery.
- Merrow's walk back down (beat 13) plays with a heavier beat if `CONFESSED`: he knows
  what's coming for everyone eventually and chooses the chain anyway, on purpose.
- The gate resident's line (beat 2) shifts from proud to slightly defensive.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Unbinding Old Nick | `WS_DEVIL_UNBOUND` | Chains fall across the Undervault; freed folk return to families across the Spread; a per-NPC, permanent subset (including Merrow) walk back down of their own accord. |

## Consistency references

- `arcana.md` §XV — negotiation phase, three contracts, reversed-clause mid-fight
  twist, Trump XV, unbinding line.
- `world.md` §The Undervault, §World-state matrix ("not everyone leaves").
- `characters.md` §XV — Old Nick Lowry's canon name and personality; `narrative.md`
  §Themes 2, 3 (offices eat people; freedom isn't wanted by everyone) and the
  bound-Arcanum "never says 'I' with a name" dialogue rule.
- `GLOSSARY.md` — "Personal names exist but are only spoken after unbinding" (Old Nick
  is the one Arcanum whose name is already public *as an epithet* before this quest).

## Open questions

- **Naming tension:** "Old Nick" is itself a centuries-old real-world folk-epithet for
  the Devil, which risks reading as an office-title rather than a private name — even
  before this quest, the Undervault already calls him that. This outline resolves it
  by treating "Old Nick Lowry" as public shorthand the *office* wears, and the
  first-person "Nick" in beat 11 as the actual return-of-name beat (he's never said it
  of himself before). Flag for a canon decision: is a distinct, unheard-until-now given
  name warranted instead, to make the beat land harder?
- Is the petal-capacity cost (Flesh Clause) meant to persist permanently past this
  quest, or reset at the next rest/Waystation? `progression.md` should confirm before
  script status, since a permanent max-Rose reduction is a significant economy change
  for a single optional choice.
- Does taking zero contracts unlock any acknowledgment/reward beyond Nick's respect
  (beat 7), or is the respect itself the reward? Recommend the latter, per tone.
