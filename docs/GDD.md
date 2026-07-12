# TARROCK
### Game Design Document — Master

Revision: 0.1.0 — first full draft (2026-07-12)

> GDD template written by Benjamin "HeadClot" Stanley. Credit to Alec Markarian and
> Benjamin Stanley, per the template license. The structure below follows their template,
> expanded where this project needs more.

This is the master document. It is the SSOT for **vision, pillars, scope, and pitch**.
Detailed facts live in the `design/` docs (see [`README.md`](README.md) for the map);
this document links to them rather than restating them.

---

## Overview

### Theme / Setting / Genre

- **Theme:** Endings are a mercy. A world that cannot end cannot live.
- **Setting:** The Spread — a storybook-medieval land that is literally a stalled tarot
  reading. Each region grew around one Major Arcana card; the common folk are the Minor
  Arcana. Nothing has truly ended here for 300 years.
- **Genre:** Third-person open-world action-adventure. Boss-driven. Single-player.

### Core Gameplay Mechanics (Brief)

1. **Unbinding the Arcana** — 21 handcrafted bosses, approachable in nearly any order.
   Each defeat permanently transforms the world.
2. **The Pocket Spread** — every boss yields their Trump card; slot it in the Past
   (passive), Present (active), or Future (fate/trigger) position, upright or reversed.
   One card, six expressions.
3. **Readable action combat** — staff-based light/heavy/dodge combat where a perfect
   dodge (**Fool's Chance**) opens a free Trump cast. Pip the dog fights alongside you.
4. **A world that answers back** — world-state changes stack: night falls for the first
   time, a tower finally finishes collapsing, mortality returns. NPCs react to all of it,
   and to the *order* you did it in: the sequence of your unbindings is recorded as
   **the Fool's Reading**, and in the true ending it is read back to you as the tarot
   spread you dealt without realizing it.

### Target Platforms

1. PC / Steam (primary; development target).
2. Consoles (post-launch port, budget permitting).
3. Mobile (aspirational far-future port; nothing in the design may *require* it, but UI
   and control schemes should avoid decisions that would make it impossible).

### Monetization

- **Premium, one-time purchase.** No microtransactions, no ads, no season pass.
  Possible paid story DLC (a Minor Arcana suit campaign) only after launch succeeds.

### Project Scope

- **Team & staffing model:** one human creative director, with Claude Fable as design
  lead and validator, delegating implementation to Opus- and Sonnet-level agents (never
  Haiku). Planning and validation happen at the top level; execution fans out. The
  binding constraint is therefore **iteration count and coherence, not headcount or
  asset budget** — we have time, and we iterate until it's polished.
- **Playtime target:** 20–30 hours main journey, 40+ completionist.
- **Build order (sequence, not a poverty plan — ship value at every rung):**
  1. **Vertical slice:** the Cliff + the Prestige — MQ00, MQ01, one side quest, core
     combat, Pocket Spread with 1 Trump, one world-state change firing end-to-end.
  2. **First act:** 5 regions / 5 Arcana, Renown, economy, save system.
  3. **Full spread:** all 22 regions, all 21 Arcana, all endings.
- **Iteration clause:** nothing ships below the quality bar; things ship *later* instead.
  Efficiency choices in this design (one Blank rig family for mooks; world-state changes
  expressed through lighting/audio/prop state; arena + gimmick + character boss design)
  are kept because they are *good craft* — they buy iteration time for what matters —
  not because we can't afford more. Where the design calls for bespoke work, it gets
  bespoke work: **every Arcana is a unique character with their own model, rig, and
  animation set** (see Assets below). Any scope pressure reduces region *size*, never
  boss *count* or boss *quality* — the 21 Arcana are the product.

### Influences

- **Fable / MediEvil** (games) — tone. Storybook Britain, dry warmth, comic melancholy.
  A world that is funny *and* sad, never cynical.
- **Shadow of the Colossus** (game) — structure and doubt. Boss-driven progression where
  every victory visibly changes the world and quietly asks whether you should be doing
  this at all. In Tarrock the answer is the twist: you are ending the world, and that is
  the right thing to do.
- **The Legend of Zelda: Breath of the Wild** (game) — openness. Tutorial plateau, then
  go anywhere; soft gating by ability and courage rather than walls; the finale is
  available early and brutal if rushed.
- **Mega Man / Zelda boss rewards** (games) — every boss pays out a power that changes
  how you fight *and* how you traverse, creating order-choice strategy.
- **The Rider–Waite–Smith tarot & the game of Tarock** (literature/folk games) — the
  entire world bible. Card meanings are load-bearing; the Fool's title, "the Excuse,"
  comes from the real card game where the Fool belongs to no trick.

### The Elevator Pitch

You are the Fool, the one card never dealt. The other 21 Major Arcana have held a frozen
world in place for 300 years — so walk the Spread, unbind them one by one, inherit their
powers, and watch the land come back to life with every victory… until you realize what
the final card is, and that bringing the world back to life and ending it are the same
journey.

### Project Description (Brief)

Tarrock is a third-person open-world action-adventure in which the player, as the Fool of
the tarot, must defeat ("unbind") the other 21 Major Arcana. The world is a stalled tarot
reading: the final card was never turned, so nothing — days, verdicts, harvests, deaths —
has been able to end for three centuries. Each Arcana rules a region shaped by their card,
and each unbinding permanently transforms the world: the first sunset in 300 years, a
frozen tower finally falling, mortality returning to the deathless.

Every defeated Arcana yields their Trump, slotted into the Fool's three-card Pocket
Spread — Past, Present, or Future, upright or reversed — so one card yields six distinct
effects and build-craft emerges from a small, legible set of pieces. The tone is Fable by
way of MediEvil: a warm, funny, gently mournful storybook. The twist is structural: the
21st Arcana is The World itself. Completing the journey destroys the world — and the game
argues, scene by scene, that this is a mercy. The Shuffle is not an apocalypse; it is a
world finally allowed to be dealt again.

### Project Description (Detailed)

See [`design/narrative.md`](design/narrative.md) for the full story and
[`design/world.md`](design/world.md) for the world. In brief:

The game opens at the Cliff, the tutorial plateau at the world's edge, where an unseen
voice — the Querent, the one the Reading is for — wakes the Fool and teaches the basics.
The tutorial ends with the Fool's leap of faith off the cliff into the Spread, and the
world opens. From that moment the player may go nearly anywhere. Regions are soft-gated
by traversal powers and enemy difficulty, never by walls; a handful of Arcana require
specific Trumps to *reach* (the Mirrormarsh cannot be honestly navigated without a light),
and the finale scales to how much of the journey remains (see below).

Each region is a diorama of its card's stasis, each Arcana a person calcified into an
office. Some are fought (the Emperor is a climbable colossus), some are outwitted (the
Hermit must be caught, not beaten), some are chosen (the Lovers can only be "defeated" by
making the choice they never could). Unbinding is never killing: the office shatters, the
person underneath gets their name back, and the region transforms — mechanically, visually,
and socially. These changes stack into the game's second act realization: the world is
waking up *in order to end*. The Axis, home of The World, is open from early on — enter
it, and the final battle includes a phase for every Arcana still bound, so rushing is
possible and legendary, while full preparation earns the true ending.

### What Sets This Project Apart

1. **The premise is the twist.** "Kill the bosses, destroy the world — and be right to
   do it" inverts the open-world power fantasy without cynicism.
2. **One card, six effects.** The Pocket Spread turns 21 collectibles into hundreds of
   builds while staying legible enough to balance by hand.
3. **Tarot is a pre-built world bible.** 600 years of iconography and meaning, in the
   public domain, that players half-know already — instant depth, zero license fee.
4. **World-state as reward.** The Megaman power is only half the payout; the other half
   is watching the world permanently change because of you.
5. **A finale that scales to your journey** — go early and fight everything at once, or
   unbind them all and face one final, personal duel.
6. **Your playthrough is literally a tarot reading.** The order you unbind the Arcana is
   the Fool's Reading — the world comments on your sequence, and the true ending is
   styled by it. No two completed journeys read the same.

---

## Core Gameplay Mechanics (Detailed)

Summaries only — each links to its SSOT.

1. **Combat** — staff-based third-person action: light/heavy/charged strings, dodge,
   block-step, Fool's Chance perfect-dodge, Pip commands, Fortune-fueled Trump powers.
   Enemy backbone is the Blanks (blank-faced humanoid soldiers bearing the cards of
   four suits and four ranks),
   letting one rig family carry the whole world. → [`design/combat.md`](design/combat.md)
2. **The Pocket Spread** — Past/Present/Future slots × upright/reversed orientation.
   Swappable outside combat; respec freely at Waystations. Reversed variants are stronger
   with a cost ("burdens"). → [`design/progression.md`](design/progression.md)
3. **Unbinding & world-state** — every Arcana defeat fires permanent world-state changes
   recorded in the world-state matrix; quests declare which states they require and which
   they alter. → [`design/world.md`](design/world.md),
   [`design/arcana.md`](design/arcana.md)
4. **Open-world traversal** — climb-lite, glide-lite (the Hanged Man's feather-fall),
   the Chariot mount, and gravity inversion open the map in layers.
   → [`design/world.md`](design/world.md)
5. **Renown & the Minors** — four suit-cultures with per-suit reputation; Fable-style
   villager reactivity to your deeds and to the world-state.
   → [`design/progression.md`](design/progression.md),
   [`design/characters.md`](design/characters.md)

## Story and Gameplay

- **Story (brief):** The Reading stalled; the Fool is dealt to finish it. Act I: the
  Fool believes they are freeing the world. Act II: the world wakes, and the cost of
  waking becomes visible — the Fool learns the final card is The World, and that the
  journey's end is the world's. Act III: the Fool chooses to finish it anyway, because
  a world that cannot end cannot live. The World is revealed to be the previous Fool,
  dancing alone at the center, waiting three hundred years to be relieved.
  Full detail, themes, endings, and dialogue style: [`design/narrative.md`](design/narrative.md).
- **Gameplay (brief):** Explore freely → find an Arcana's region → read its stasis →
  reach and unbind the Arcana → slot the Trump, watch the world change → the changes
  open new places, quests, and builds → repeat, in any order, toward the Axis.
  Full loops and moment-to-moment detail: [`design/combat.md`](design/combat.md),
  [`design/progression.md`](design/progression.md).

## Assets Needed (High Level)

- **2D:** card art for all 22 Majors (UI + collectible), suit iconography, UI set
  (illuminated-manuscript frames), region emblems, world map as a dealt spread.
- **3D:** the Fool + Pip; one Blank base rig × 4 suits × 4 ranks (material/prop
  variants — the *only* place enemy rigs are shared); **21 fully bespoke Arcana** —
  unique model, rig, silhouette, and animation set each, sized to their encounter, and
  more than one character where the card demands it (the Lovers are two duelists; the
  Moon's Anti-Fool deliberately wears the player's own rig); 22 region kits built
  from a shared medieval-storybook kit + per-region signature props; the Chariot mount.
- **Sound:** region ambiences in two states (bound/unbound — the audio *is* the world
  change half the time); combat foley; Pip; 22 Arcana leitmotifs over one journey theme.
- **Code:** see [`design/technical.md`](design/technical.md) — data-driven cards,
  quests, and world-state from day one.
- **Animation:** Fool locomotion/combat set, Pip set, per-Arcana boss sets (the big
  cost — budgeted per boss in [`design/arcana.md`](design/arcana.md)).

## Schedule (Milestones)

| Milestone | Contents | Exit criterion |
|---|---|---|
| M0 — Docs complete | This documentation, reviewed | Quests MQ00–MQ21 outlined; canon stable |
| M1 — Greybox slice | Cliff + Prestige greybox, combat prototype | MQ00→MQ01 playable start to finish, ugly |
| M2 — Vertical slice | Slice with art/audio/UI pass, 1 Trump, 1 world change | A stranger can play 90 min and want more |
| M3 — Act I | 5 regions, 5 Arcana, save system, Renown | Alpha; order-independence proven |
| M4 — Full spread | All content, both endings | Beta; full playthrough possible |
| M5 — Ship | Polish, difficulty modes, accessibility | Steam release |

Timeboxes are set when M1 begins; the docs phase does not pretend to know them.
