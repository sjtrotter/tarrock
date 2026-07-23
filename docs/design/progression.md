# Progression — SSOT

Owns: the Pocket Spread system rules, the Fortune economy, healing (the White Rose),
Waystations, currency/shops/gear-lite (staff heads), and Renown. The *content* of what
each Trump does in each slot belongs to [`arcana.md`](arcana.md) — this doc owns the
rules of the system the Trumps plug into. The player combat kit itself (the Bindle,
dodge, Fool's Chance) belongs to [`combat.md`](combat.md).

## Philosophy: no XP, no levels, no skill tree

Tarrock has no experience points, no character level, and no skill tree. **All player
growth is horizontal**, not vertical: the Fool does not get bigger numbers, they get more
*options*. Every growth vector is one of exactly three things:

1. **Trumps** — won from unbinding an Arcana, slotted into the Pocket Spread.
2. **Staff heads** — found or bought, retuning the Bindle's moveset (see below).
3. **Rose graftings** — found or earned, raising the White Rose's maximum petals (see
   below).

There is no armor system and no charm system. Outfits found or bought across the Spread
are **cosmetic only** — they change how the Fool looks, never how the Fool plays. This is
a deliberate, explicit scope cut: it keeps the build space small enough to balance by
hand (21 Trumps × 3 slots × 2 orientations is already the intended ceiling of
build complexity) and it keeps every visible outfit a pure expression of player taste
rather than a stat trap.

## The Pocket Spread

The Fool's personal spread of three cards, worn always, is the game's build system.

**Plain-language note (this confused a reader once, so it's canon now): Past / Present /
Future is not a time-travel mechanic.** The three slots are named for the positions in
a classic three-card tarot spread, and the position determines *how the equipped card's
power expresses*: Past = "what you carry" (a passive), Present = "what you do" (an
active you trigger), Future = "what awaits" (a reactive effect that fires on a
condition). Nothing rewinds, nothing fast-forwards; it is an equipment metaphor.

| Slot | Nature | Cost model |
|---|---|---|
| **Past** | Passive | Always active while slotted; no per-use cost. |
| **Present** | Active | Triggered by the player; costs Fortune per cast. |
| **Future** | Triggered / fate | Fires on a condition (not a button press); no Fortune cost, but the condition and effect are fixed by the card. |

Each Trump defines a **distinct effect for each slot** — a card is not one power with two
reskins, it is three. Every Trump can additionally be slotted **upright** or **reversed**:
reversed gives a stronger effect in exchange for a "burden," a drawback themed to the
card's traditional reversed meaning. Content for all of this — what the Magician's
Present-upright actually does, what its reversed burden costs — is owned by
[`arcana.md`](arcana.md); this doc only fixes the rules every Trump must follow.

There is **one copy of each Trump** — no duplicates, no upgrading a single Trump's power
over time. Depth comes from recombination (which three Trumps, which slots, which
orientations), not from grinding any one of them.

- **Swapping** individual Trumps in and out of the Spread is allowed **anywhere, out of
  combat** — no cooldown, no resource cost, no travel required. The Fool can rebuild
  between one fight and the next.
- **Full loadout saving and respec** — naming and swapping between whole saved Spread
  configurations — is available at **Waystations** only (see below). Free-form swapping
  covers moment-to-moment adaptation; Waystation loadouts cover deliberate, considered
  builds the player wants to return to.

### Slot unlock pacing

| Slot | Unlocks | Rationale |
|---|---|---|
| **Present** | With the first Trump acquired — whichever quest grants it (MQ01 on the intended first-region path, but every unbinding quest handles the case) | The player's very first power teaches the core loop: spend Fortune, get an effect, on demand. |
| **Past** | Upon holding 3 Trumps | Passive, always-on effects are a harder concept (nothing to press, just a standing truth) — introduced only once the player already trusts the Present slot. |
| **Future** | Upon holding 7 Trumps | Triggered/fate effects are the subtlest axis (a condition the player doesn't directly control) — held back until Past and Present are both second nature. |

The pacing exists to **teach one axis at a time**: three fundamentally different kinds of
power (do something now, always be something, let fate answer) would be overwhelming
handed out together at MQ01. By the time all three slots are open, the player already
understands each in isolation and is ready to combine them.

## Fortune

Fortune is the single resource spent by Present-slot Trumps.

- **Meter size:** roughly 100 units baseline.
- **Present casts cost roughly 20–50 units**, varying by Trump — exact per-Trump costs
  are owned by [`arcana.md`](arcana.md) once each Trump's Present effect is designed.
- **Earned by:**
  - **Combat** — landing hits and, disproportionately, triggering Fool's Chance (see
    [`combat.md`](combat.md) §Fortune in combat for the in-fight earn philosophy).
  - **Discovery** — finding a new location or a secret rewards a flat Fortune bonus, the
    same lever that makes exploring feel materially useful mid-fight-prep, not just
    narratively nice.
  - **Daring** — near-miss dodges and surviving high falls both grant Fortune; the meter
    rewards boldness broadly, not only combat skill narrowly.
- **Fortune's Favor:** immediately after a Fool's Chance, the meter can briefly hold
  *more* than its normal maximum — an overfill window that empties back down to the cap
  if unspent, encouraging the player to actually spend the free cast's momentum rather
  than bank it forever.
- **Reversed Present casts cost less** than their upright counterpart, in exchange for
  applying the card's burden on every cast — a direct economic trade the player makes at
  slotting time, not at cast time.

## The White Rose

The Fool's healing item is **the White Rose**, worn at the belt. Its petals are healing
charges:

- **Starting capacity: 3 petals. Maximum: 8**, raised by finding or earning **Rose
  graftings** in the world or as side-quest rewards.
- **One petal = one fast heal**, triggered on a dedicated button — no menu, no channel
  time, keeping healing compatible with the combat pacing in [`combat.md`](combat.md).
- **Regrowth** is where the Rose becomes a piece of world-state storytelling rather than
  a plain resource:
  - **Fully regrows at Waystations**, instantly, on rest.
  - **Regrows slowly over time** while the Fool is in a region that has been unbound
    ("living" / unbound regions only) — the world's own aliveness feeds the Rose.
  - **Does not regrow at all in still-bound regions.** Stasis means nothing grows,
    including the Fool's own healing — a small, constant pressure that is *felt*
    mechanically before it is explained narratively, and one that eases naturally as
    more of the Spread wakes up over a playthrough.

## Waystations

Wayside shrines, one per region and along the Longroad, are the game's rest points (see
[`world.md`](world.md) §Regions for their placement). At a Waystation the Fool can:

- **Rest** — fully regrow the White Rose and respawn ambient (non-boss) enemies.
- **Respec the Pocket Spread** — save, name, and switch between full loadouts.
- **Fast travel** — Waystations become fast-travel points world-wide once
  `WS_CHARIOT_UNBOUND` fires (see [`world.md`](world.md) §World-state matrix); before
  that they are rest-only, keeping early traversal grounded in the physical world.

## Currency, shops, and gear-lite

**Coins** are the Fool's money — fittingly, since the suit of Coins is literally the
Spread's culture of trade and earth (see [`GLOSSARY.md`](../GLOSSARY.md)). Coins are
found, looted, and earned through quests, and spent at **shops in every settled region**.

- **Prices vary by region**, and are further affected by the Fool's **Renown** with the
  local suit and by relevant **world-states** — a shop's stock and prices are a live
  reflection of the world-state matrix in [`world.md`](world.md), not a static price
  list. (E.g., `WS_EMPEROR_UNBOUND` halves nothing by itself, but food prices halve
  Spread-wide on `WS_EMPRESS_UNBOUND` — shop pricing simply reads that state.)
- **Staff heads** are the game's only "gear": roughly **8–10** exist across the Spread,
  found in the world or bought from specific shops. Each is a small, distinct twist on
  the Bindle's moveset or a minor property (reach, an elemental tag, a different heavy
  shape — see [`combat.md`](combat.md) §The Bindle) — never a numeric upgrade. There is
  no treadmill to climb; a player can pick a favorite staff head in hour three and never
  feel behind for keeping it.

The exact identity and location of each staff head, and the full list of Rose-grafting
sources, are **TBD** — content-design passes that happen once regions are greyboxed, not
decisions the docs phase needs to lock.

## Renown

Renown is the Fool's **per-suit reputation** with the Minors — tracked separately for
**Cups, Swords, Wands, and Coins** (see [`GLOSSARY.md`](../GLOSSARY.md)). It moves in
response to deeds and quest choices, and it gates some dialogue branches and shop stock,
and changes greetings and ambient barks.

Renown is **not a morality meter** — there is no good/evil axis, and no suit judges the
Fool by a universal standard. Renown tracks *standing*, and each suit-culture values
different kinds of deed, consistent with their culture in [`GLOSSARY.md`](../GLOSSARY.md)
and [`world.md`](world.md):

| Example deed | Cups reaction | Swords reaction | Wands reaction | Coins reaction |
|---|---|---|---|---|
| Helping a stranger at personal cost | Renown up (hospitality prized) | Neutral | Slight up (passion for the deed) | Slight down (bad business sense) |
| Winning a formal duel or contest | Neutral | Renown up (soldierly virtue) | Slight up (spectacle) | Neutral |
| Striking a sharp bargain | Slight down (feels cold) | Neutral | Neutral | Renown up (shrewdness prized) |
| Finishing a craft or creative work | Slight up | Neutral | Renown up (craft is the culture) | Slight up (sellable) |

Each suit uses the same **five-tier ladder**:

| Tier | Standing |
|---|---|
| 1 | Stranger |
| 2 | Known |
| 3 | Welcome |
| 4 | Honored |
| 5 | Fabled |

## Player growth over a playthrough

Because there is no level number to point to, growth has to be felt through the Pocket
Spread, the Rose, and Renown together:

- **Hour 1:** the Fool has the Bindle, an empty Rose beyond its 3 starting petals, no
  Trump yet, and no reputation anywhere. Every fight is decided by the moveset alone —
  light string, heavy, dodge. This is deliberately the "purest" the combat ever feels.
- **Hour 10:** the Fool likely holds 3–4 Trumps (Past slot just unlocked or about to),
  a couple of staff heads picked up along the way, a Rose grafting or two, and a
  recognizable Renown with at least one suit whose region they've spent time in. Fights
  start to show build identity — a favored Present power, a passive the player leans on.
- **Hour 25:** most or all of the Pocket Spread's three slots are populated with
  deliberately chosen Trumps in deliberately chosen orientations, the Rose is at or near
  its 8-petal cap, Renown is distinctly uneven across suits (high where the player spent
  time and did right by that culture, low or unknown elsewhere), and the world itself has
  visibly changed around all of it. The power fantasy by hour 25 is not "bigger numbers"
  — it is "a spread of options as personal as the choices that built it."
