---
id: SQ-DIVIDE-03
title: The Letters That Cross Anyway
type: side
status: outline
arcana: none
region: The Divide
requires: []
fires: []
---

# SQ-DIVIDE-03 — The Letters That Cross Anyway

## Introduction

Two elderly relatives of the Betrothed — one from each town — have exchanged letters by
trained messenger-bird across the canyon for three hundred years, quietly keeping a peace
their younger kin never managed. Carrying one particularly overdue letter across by hand
reveals that this correspondence is the real reason the Divide never came to open war
during the Stall: while the towns glared and the Betrothed froze, two old people kept
choosing, day after day, to stay in each other's lives across an uncrossable gap. Warm,
funny, and a little embarrassed to be found out.

## Beats

1. **The hook.** On the east bank, Aunt Perpetua (characters.md §Regional named NPCs), an
   elder of the Betrothed's kin, presses the Fool a sealed letter and gestures at her
   fretful, elderly messenger-bird, which will not fly the canyon today. Would the Fool
   carry this one across by hand to Uncle Osric on the west bank?
2. **The crossing.** A small errand over the Divide — by ferry pre-unbinding [If
   WS_LOVERS_UNBOUND: across the finished bridge]. Uncle Osric (characters.md §Regional
   named NPCs) receives it, reads it, laughs, weeps a little, and immediately begins a
   reply — the unbroken rhythm of three hundred years.
3. **The reveal (theme 1).** Reading between the lines, and through Osric's fond
   indiscretion, the Fool learns these two have written across the canyon their whole
   lives: recipes, gossip, small forgivenesses, and once, a warning that stopped a feud
   before it could become a war. The peace nobody ever credited was theirs — the daily
   choice to stay that the frozen Betrothed could never make.
4. **The comedy.** They are mortified to be found out — two old people who have been
   quietly undermining their towns' grand mutual grudge with kindness for three centuries,
   and each would rather their own side never learned they'd been "fraternizing." They
   bicker, by proxy through the Fool, about whose turn it actually was to write.
5. **The honest beat.** The letters were never really about news. Each was proof the other
   was still there, still willing, across a gap no one could cross — a small daily "yes"
   the Betrothed, frozen at their own bridge, never managed. The old folk did, unbound,
   the exact thing the Lovers could not.
6. **Closing.** The Fool carries one more letter, or the reply, and the correspondence
   goes on.
   - [If WS_LOVERS_UNBOUND: with the bridge open the two could finally just walk across and
     speak — and after one awkward face-to-face tea they agree they much prefer the
     letters, and keep writing anyway, now hand-delivered. Some crossings are better left a
     little unfinished.]
   - [If WS_DIVIDE_EASTMARRIED / If WS_DIVIDE_WESTMARRIED: the pair are quietly delighted
     their kin's wedding finally landed on one bank, and each teases the other that their
     town "won" — entirely without malice, a new running joke folded into the letters.]

Rewards, if any: modest coins and a rise in Cups Renown (the letters are pure Cups
warmth); optionally a rose grafting for the long cross-canyon errand — nothing gated.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (any state) | none — NPC-level only | Perpetua's and Osric's barks warm; the correspondence continues (by bird, or hand-delivery post-bridge). No `WS_*` flag is set. |

## Consistency references

- `world.md` §The Divide — the two glaring towns and the canyon the correspondence spans.
- `world.md` §World-state matrix (`WS_LOVERS_UNBOUND`, branch flags
  `WS_DIVIDE_EASTMARRIED` / `WS_DIVIDE_WESTMARRIED`) — the either-unbinding and branch
  variants; this quest fires nothing.
- `docs/quests/main/MQ06-the-longest-engagement.md` — the engagement, the two towns'
  grudge, and the bridge; these correspondents are the Betrothed's kin and must not
  contradict MQ06's account.
- `characters.md` §VI. The Lovers — the Betrothed, whose relatives these are (freed names
  Elsbeth/Wystan per `GLOSSARY.md`, unspoken pre-unbinding; the bound Betrothed are never
  named here).
- `characters.md` §Regional named NPCs — Aunt Perpetua, Uncle Osric (promoted in the
  parallel change).
- `characters.md` §The Minors: suit-cultures — Cups (warmth, blessings) as the pair's
  register.
- `narrative.md` §Themes (1), §Dialogue style guide (one honest beat inside the comedy;
  Fool lines ≤ 12 words).

## Open questions

- **Name collision.** Aunt Perpetua (Divide) shares a first name with Sister Perpetua Vane
  (Chantry, SQ-CHANTRY-01). Flag for the parallel `characters.md` promotion to
  disambiguate — recommend renaming one, since two "Perpetua"s in adjacent Band-1 regions
  will confuse.
- Which correspondent is east and which west should map to the Betrothed's banks (Elsbeth
  east / Wystan west per `GLOSSARY.md`); confirm Aunt Perpetua's and Uncle Osric's kinship
  sides before script status.
- Possible cross-link: did SQ-DIVIDE-02's Sculley ferry these letters for centuries?
