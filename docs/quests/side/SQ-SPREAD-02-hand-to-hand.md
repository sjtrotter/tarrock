---
id: SQ-SPREAD-02
title: Hand to Hand
type: side
status: outline
arcana: none
region: The Spread (world-spanning — touches all four suit-cultures)
requires: []
fires: []
---

# SQ-SPREAD-02 — Hand to Hand

## Introduction

Somewhere on the Divide, a young Page can't bring himself to give his sweetheart the one
keepsake he meant to — and asks the Fool to trade it away for something bolder instead.
What follows, if the player chooses to see it through, is a quiet thread running the
length of the whole Spread: one small, humble object passed from hand to hand, region to
region, suit-culture to suit-culture, each trade a tiny honest portrait of what that
culture actually values, until it arrives — small, ordinary, and exactly right — in the
hands of someone who needed it more than any of the people who carried it. This is
Tarrock's OoT-style trading chain: no combat, no urgency, just a road's worth of people
being decent to each other in their own culture's language, and the Fool as the thread
tying it together.

## The chain

Nine links: eight trades and one final gift, cycling through Cups → Swords → Wands →
Coins twice before resolving. All NPCs below are now canon (`characters.md` §Regional named NPCs), promoted
together as a set.

| # | Suit / region (flexible — see below) | NPC | Gives up | Receives | What it says about the suit |
|---|---|---|---|---|---|
| 1 | Cups — The Divide | Wills, a young Page | his father's cracked wooden whistle-charm, meant as a courting keepsake he's lost his nerve to give | (the Fool takes the whistle to trade on his behalf) | Cups courtship is indirect, sentimental, and terrified of its own sincerity — the whole culture in one blush. |
| 2 | Cups → Swords hinge, Divide/Longroad | Corporal Hale, a sentry on his one hour off duty in 300 years | his ornamental dress-medal | the whistle | His one true want, off duty, for once, outranks decoration — Swords discipline yielding, briefly, to a small personal wish. |
| 3 | Wands — Maw or Gallowwood | Fell, a huntress-tanner | a beautifully finished leather satchel | the dress-medal | She collects fine handiwork as craft-inspiration, not rank — Wands sees the medal as art, not authority. |
| 4 | Coins — Wheelhouse or Noonlands | Grissom, a travelling peddler | a small sealed money-pouch (fair, generous weight) | the satchel | Shrewd, practical trade — but he throws in an extra copper "for luck," the tiny crack in the driest suit's armor. |
| 5 | Cups — Chantry or Confluence | Mother Loosely, an innkeeper | a hand-knit shawl | the money-pouch | She uses the coin to finally settle a kindness she's owed someone — generosity multiplying rather than banking. |
| 6 | Swords — Assize or Bastion | Ser Colm, a retired duelist | his last good whetstone | the shawl | His knees ache in the cold court halls; the shawl's plain warmth is a comfort Swords culture rarely admits needing. |
| 7 | Wands — Spire or Dim | Cobb, a tinker | a small polished brass hand-bell, clapper-hinge unrepaired | the whetstone | He needs the stone to finish restoring the bell properly — a craftsman who won't let a piece out unfinished. |
| 8 | Coins — Undervault or Wheelhouse | Thrimsy, a vault-teller | *nothing* — she recognizes the bell's worth and refuses payment, sending the Fool on for free | the bell | A rare, uncharacteristic Coins moment: she still logs it in her ledger as "value: immeasurable, price: nothing," visibly bothered by the entry all day. |
| 9 (final) | The Stillmarsh | **Old Sallow** (canon, `characters.md`) | — | the bell, as a gift, not a trade | He's never had a way to call the ferry back from the far bank except his own hoarse voice, worn thin over 300 years of waiting-souls. He rings it once, delighted like a boy — then goes quiet, because now he'll never have an excuse to lose his voice calling for the dead who might, someday soon, finally be able to go. The laugh and the ache in the same breath, exactly as the brief asks. |

**Ending object:** a small, plain brass hand-bell — modest, functional, unglamorous.
Deliberately not a weapon, not a Trump-adjacent curio, not powerful in any mechanical
sense; its only property is that it lets Old Sallow call the ferry without shouting, and
that is the whole point.

## Order-independence handling

A trading chain is *internally* sequential by definition — link 4 cannot exist before
link 3 hands over its item — but that is a puzzle-structure fact, not a world-state
order dependency, and must not be confused with the main quest's order-independence rule
(`world.md` §Interaction rules). Three concrete handling notes:

1. **No link is gated behind any `WS_*` flag.** Every NPC above is placed somewhere
   ordinary and reachable regardless of which or how many Arcana are unbound — a
   roadside, a tavern, a market stall, a checkpoint — never inside a space a hard or soft
   gate could block (per `world.md` §Hard and soft gates). A player who starts this chain
   at hour two and a player who starts it at hour forty must both be able to finish it.
2. **World-state variants are additive flavor, never blockers.** If a link's home region
   has already been transformed by the time the player reaches it (e.g., Corporal Hale's
   checkpoint after `WS_EMPEROR_UNBOUND` has ended curfew, or Cobb's tinker stall after
   `WS_TOWER_UNBOUND` has changed the Spire's skyline), the scene gets the standard
   `[If WS_<FLAG>: …]` variant line per the quest template — the trade itself, and its
   outcome, never changes.
2a. Because several plausible regions are listed per link ("Maw or Gallowwood," etc.),
   the script pass should pick one fixed home per NPC rather than leaving it floating —
   the table's flexibility is a content-placement question for that pass, not a runtime
   branch.
3. **The final delivery (Old Sallow) has no prerequisite Arcana-unbind requirement.**
   The scene's meaning shifts naturally with `CONFESSED` / `WS_DEATH_UNBOUND` state (a
   pre-Death Sallow receiving the bell reads as one more small kindness among centuries
   of waiting; a post-Death Sallow receiving it reads as bittersweet obsolescence, per
   his region's own post-unbinding tone) — write both variants, gate neither.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Chain completed (bell delivered to Old Sallow) | none | NPC-level only. Old Sallow's future barks and greeting pool gain the bell as a recurring detail (a new object he's seen using, referenced in ambient dialogue per `npc-system.md` layer 1). No `WS_*` flag is set or read. |

## Consistency references

- `design/characters.md` §The Minors: suit-cultures — every link's NPC behavior is
  written directly from that table's Values/Dress/Speech columns.
- `design/characters.md` §Old Sallow — final recipient; behavior consistent with his
  established "nearly done dying," wry, unhurried characterization.
- `design/world.md` §Hard and soft gates, §Interaction rules — order-independence
  handling above is built directly from these sections.
- `design/progression.md` — the chain deliberately awards nothing mechanical; the bell is
  flavor-only, consistent with the "ends small and perfect, not powerful" brief.
- `narrative.md` §Dialogue style guide §Melancholy rule — the final scene's ache-and-laugh
  pairing is written to satisfy this rule directly.

## Open questions

- Fixed home regions for the "either/or" links (table column 2) — a content-placement
  decision for the script pass, not a canon decision.
- Whether any of the eight intermediate NPCs should be flagged for later reuse (a
  recurring bark-pool presence, a face seen again in an unrelated quest) — proposed: yes
  for Corporal Hale and Ser Colm at minimum, since Bastion/Assize soldierly culture is
  otherwise thin on named faces in the current slate.
- Should the Fool be able to *keep* the bell instead of delivering it (a completionist
  temptation)? Recommend no — per the brief's "no fetch-quest filler" bar, the quest's
  whole point is the delivery; an alternate ending where the Fool keeps it should read as
  a quiet failure-forward (the chain simply never resolves, no punishment, just an
  absent scene) rather than a rewarded choice.
