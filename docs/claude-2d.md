> **Superseded (2026-08-17).** This report was one of two blind inputs to `final-claude-2d.md`, which reconciles them; the 2D decision itself is recorded in `GDD.md` §Project Scope. Kept for provenance; do not cite as canon.

# Tarrock in 2D — a canon feasibility report for a v1 release

**Status:** report / proposal — NOT canon. Nothing here amends the GDD or any design doc.
**Method:** independent canon review (GDD, GLOSSARY, narrative, world, arcana, combat,
progression, callings, characters, npc-system, art-audio, art-bible, full quest
inventory). `docs/codex-2d.md` was deliberately **not read** before writing this, so the
two reports can be compared as independent takes. (Its section headings surfaced during
the doc sweep; nothing below is derived from its content.)
**Date:** 2026-08-10

---

## 1. The question, stated precisely

Could Tarrock ship a v1 as a 2D game — platformer, top-down ALttP-style, isometric, or
fake-3D — before committing fully to the 3D version, without breaking the canon?

Short answer: **yes, and more comfortably than the GDD's genre line suggests.** The canon
audit below finds that Tarrock's actual product — the twist, the 21 Arcana as characters,
the world-state matrix, the Pocket Spread, the Fool's Reading, the dialogue, the tone —
is almost entirely perspective-agnostic, and several load-bearing systems are *more* at
home in 2D than in 3D. The 3D commitments are real but narrow, countable, and mostly
production statements rather than design facts. The one genuinely hard design decision is
which 2D projection to pick, because the canon pulls in two directions at once (§5).

---

## 2. What the canon actually is, once you subtract the camera

Strip the genre statement ("third-person open-world") off the GDD and inventory what
remains. This is the product:

**Fully perspective-agnostic — survives any projection unchanged:**

- The entire narrative spine: the Stall, the twist (*the 21st Arcana is The World;
  unbinding it destroys it*), the three endings, the act structure as unbind-count
  thresholds, MQ13's confession pivot, the Querent's identity and reveal rules, the
  Fool's Reading (order recorded, three read positions, styles-never-branches guardrail).
- The unbinding beats themselves: office cracks → name returns → Trump handed over.
- The Pocket Spread in full: Past/Present/Future × upright/reversed, one card six
  expressions, Fortune economy, reversed burdens, Waystation respec.
- Progression entire: no-XP philosophy, staff heads, White Rose petals and its
  world-state regrowth storytelling, Renown's four-suit ladder, currency and shops.
- The NPC system entire: all seven bark layers, rumor propagation, named/ambient split,
  anchor-point schedules, the "aware NPCs or it's a bug" pillar. Pure data and logic.
- All dialogue canon: ≤12-word Fool lines, the earnest option, the one-wink rule, the
  melancholy rule, cardspeak, bound-Arcana naming grammar.
- The world-state matrix's *meaning*: 25 `WS_*` flags, most of them systemic or social
  (mortality, day/night, beast disposition, luck weather, bark deltas, economy). These
  are rules and dialogue changes, not camera effects.
- All 91 quests. The scripts are engine- and camera-agnostic text. 22 main quests at
  script status is a complete, portable story.
- Music, SFX, VO plan, card art, the Almanack, the map-as-dealt-cards.

**Boss mechanics** (from a fight-by-fight audit of arcana.md): of 21 encounters, **11 are
perspective-agnostic** (including Death's pure duel — the game's keystone — and the Moon's
Anti-Fool, which by construction inherits whatever the player system is), **4 are
natively side-view** (Chariot's train-top fight, Hanged Man's inversion ordeal, Tower's
vertical ascent, Emperor's colossus climb), **2 are natively top-down** (Wheel's rotating
ring arena, Sun's read-his-shadow duel), and **zero are intrinsically 3D**.

**Trump effects:** of 20 Trumps, **16 are fully projection-neutral**. One — Overturn
(XII) — is gravity-axis-dependent and is the single hard constraint on projection choice
(§5). None require 3D free movement, 3D aiming, or camera tricks.

**Callings:** roughly 15 of 21 loops are perspective-agnostic or actively top-down-native
(Groundskeeper is literally tile gardening; Shepherd is literally top-down herding;
Croupier is literally a card table). None are 3D-dependent.

**The art identity already has a native 2D analogue — the art bible says so itself.** The
reference shelf's primary craft references for "flattened storybook space,
pattern-as-meaning" are *The Secret of Kells* and *Wolfwalkers* — both hand-drawn 2D
films. Every identity descriptor — painterly storybook, Rider–Waite–Smith woodcut
linework, illuminated-manuscript UI, "a forgotten fairy tale illustrated in the margins
of an old tarot deck" — comes from 2D illustrative traditions. Tarot cards are 2D
objects. The map is cards on a table. The GDD itself describes each region as "a diorama
of its card's stasis." A 2D Tarrock is not a compromise of this identity; it is arguably
its most literal expression.

---

## 3. The complete list of genuine 3D dependencies

Five items in the entire canon intrinsically depend on 3D space. None are combat
mechanics, one is already deferred, and every one has a 2D substitution — several of
which are *stronger* on-theme than the 3D original.

| # | Dependency | Canon source | 2D substitution |
|---|---|---|---|
| 1 | **The Axis visible from everywhere** — the distant dancer as omnipresent landmark | world.md §The Spread | Axis on every region's painted horizon/parallax backdrop; the map screen carries the continuity. Weaker as ambient pressure; workable. |
| 2 | **The Spire's fall as a global skyline change** (`WS_TOWER_UNBOUND`, "visible from everywhere") | world.md matrix; arcana.md §XVI | Two-state backdrops per region. In 2D that's a painting swap — cheap, and already the shape of the bound/unbound art strategy. |
| 3 | **The Cliff's late-game vantage** ("the Spread finally visible from this height") | world.md §Regions | Already flagged "deferred idea, not current canon." Drop, or do it as a full-page illustration. |
| 4 | **Scale reveals** — the 40-ft Emperor, the Wheelhouse's titanic wheel, the Confluence's colossal cups | arcana.md §IV; world.md §Regions | Framed establishing art: full-page illuminated-manuscript illustrations at reveal moments. This turns the weakness into a signature — the storybook literally opens to a full-page plate. |
| 5 | **The leap of faith** — the Fool's vertical drop off the Cliff into the world | GDD; GLOSSARY | Native and *excellent* in side-view; in a top-down base it becomes a bespoke side-view moment (see §5's hybrid answer). |

Everything else tagged "3D" in the docs — Unity Terrain, triplanar shaders, rigs, the 1
unit = 1 m contract, greybox milestones, silhouette benchmarks "at gameplay camera
distance" — is **pipeline, not design**. It describes how the current build is made, not
what the game means.

---

## 4. What the canon says about combat and traversal in 2D

The friction concentrates in exactly three places, and it is worth naming them honestly:

1. **The vertical combat axis.** Charged-heavy launcher → aerial follow-up is native to
   side-view and awkward top-down (top-down has no "up" in combat). In a top-down base it
   becomes knockback/stagger + a juggle window — a redesign, not a loss of identity.
2. **Focus (OoT-style Z-targeting).** Designed for a rotating camera; its closest honest
   relative is top-down lock-strafe — which is exactly what 2D Zeldas do. Degrades in
   pure side-view (the left/right/back directional dodge collapses to two directions).
3. **Climb-lite traversal.** Already TBD in combat.md, and the one system built on
   continuous 3D terrain gradients ("cliffs refuse, slopes permit"). In 2D it dissolves
   into level design — which is arguably the cleanest resolution the open question could
   ask for.

Note what is *not* on this list: Fool's Chance, the dodge/block kit, Pip's command wheel,
the Blanks' entire suit×rank behavior grammar, the defeat loop, boss philosophy
("arena + gimmick + character"), and the four no-combat unbindings (Priestess, Hermit,
Hanged Man, Star). All perspective-agnostic.

---

## 5. The projection decision — where the canon pulls in two directions

This is the real design fork, and the audit gives it sharp edges:

**The case for side-view (platformer / Metroidvania):**
- **Overturn (XII) is the hard constraint.** Feather-fall, no fall damage, gravity
  bubbles — one of the two declared "traversal headlines" — is a side-view genre
  primitive (VVVVVV, Metroid) and *semantically void* top-down. The Gallowwood, MQ12's
  inverted ordeal ("camera honestly inverted" — solved for free by a screen flip), the
  Spire's vertical ascent, the Undervault's pit-city cross-section, the Divide's canyon,
  the Maw's crags, and the leap of faith are all side-view postcards.
- Launcher/aerial combat and the grand backflip come along free.

**The case for top-down / isometric (ALttP family):**
- **The society is the pillar.** "A world that answers back" — crowds, queues, festivals,
  markets, herding, farming, the whole Callings layer, ambient Minors reading as "a
  structured society" — reads at full strength on a ground plane and poorly in a
  side-view lane.
- **The world's topology is a top-down fact.** The Spread is a dealt wheel around the
  Axis; the Longroad is a ring; the Wheelhouse's luck districts are a street checkerboard;
  the Mirrormarsh's loops-you-back-out maze is a fog-of-war trick; the hydrology rule is
  cheap to satisfy on a map and awkward in cross-section.
- The Wheel's rotating arena and the Sun's shadow-read (the fight most sensitive to
  projection — the shadow must be legible on the ground plane, which side-view denies)
  both want top-down.
- Focus becomes lock-strafe; the heavy arc sweep becomes the classic radial hitbox.
- Open-world any-order structure survives. A side-view world of 21 regions inevitably
  drifts toward Metroidvania ability-gating — which quietly fights the BotW-derived
  "soft gating by courage, never walls" rule and the always-open Axis.

**Recommendation: top-down/isometric base with bespoke side-view set-piece sequences.**
There is direct genre precedent — *Link's Awakening* and ALttP themselves cut to
side-view rooms — and a modern reference class that already solved "storybook Zelda-like
with real verticality": *Tunic*, *Death's Door*, *Hades*. Concretely:

- The **base game** is top-down/isometric: regions, towns, Callings, ambient society,
  most fights. Isometric (rather than flat top-down) is worth the extra art cost
  precisely because it restores readable elevation — terraces, ledges, feather-fall
  hops — and honors the "elevation signposts the path" terrain grammar.
- **Side-view sequences** are the sanctioned exception, used exactly where canon is
  side-view-native: the Cliff's leap (MQ00), the Emperor climb (MQ04), the Chariot's
  train roofs (MQ07), the Gallowwood/MQ12 inversion ordeal (where Overturn's bubble
  mechanic lives at full strength), the Spire ascent and collapse ride (MQ16), the
  Undervault's descent framing (MQ15). Six bespoke sequences — a countable, budgetable
  list, and each is already canon's designated set-piece.
- **Overturn upright** (feather-fall) reinterprets in the base game as ledge-float and
  gap-drift (no fall damage anywhere, cross marked gaps) and runs at full literal
  strength inside side-view sequences. The gravity bubble outside them is a genuine
  redesign point — the honest TBD of this proposal.

---

## 6. What a 2D v1 should be — and the canon already answers this

The GDD's Iteration clause is explicit: **"Any scope pressure reduces region *size*,
never boss *count* or boss *quality* — the 21 Arcana are the product."** And the build
order is "sequence, not a poverty plan" — nothing in canon authorizes shipping an Act-I
slice as a commercial release, and an Act-I slice would be a broken promise anyway: the
twist *is* the premise, the finale is "a right, not a reward," and the Fool's Reading
only means anything across all 21 cards.

So the canon-compliant shape of a 2D v1 is:

> **The complete Tarrock — all 22 regions, all 21 Arcana, all three endings — with
> region size shrunk to 2D scale.**

This is not a workaround; it is the GDD's own scope valve applied maximally. A 2D region
is inherently smaller in authored surface (screens instead of square kilometres) while
holding boss count at 21 and boss quality at "bespoke character." Every quest script,
every bark pool, every world-state flag, every Trump ships. What shrinks is traversal
distance and set-dressing volume — the two things the canon explicitly marks as
compressible. The 20–30h playtime target likely compresses toward 12–20h; the GDD calls
playtime a target, not a pillar.

The Shuffle itself gets *stronger* in 2D: "regions fold closed in the order the player
unbound them" is literally a hand of cards being gathered up — on a map that is already
cards on a table, the true ending's signature image becomes the game's native UI verb.

---

## 7. What a 2D v1 buys strategically

1. **It unblocks the actual bottleneck.** The art-audio doc names the one art gap:
   "characters remain CC0 stand-ins; the 21 Arcana are the art budget's first priority,"
   and the GDD names per-Arcana 3D animation "the big cost." The project has spent weeks
   of hard iteration on a single 3D character (the Fool sculpt). In 2D, the same model
   sheets and the shape-language table (every Arcana's dominant geometry is already
   specified) drive sprite/puppet art directly — a pipeline where the team's
   illustration-first strengths and the RWS-woodcut identity actually converge.
2. **It validates every system that matters while they're cheap to change.**
   Order-independence across 21 bosses, the world-state matrix stacking, the bark-layer
   system, the Fool's Reading, the Anti-Fool build-mirror, the Pocket Spread economy —
   all get proven against real players. These are exactly the systems the technical.md
   mandates be data-driven; definitions, quest state machines, WorldState service, and
   save model are **shared between the 2D and 3D games**. The 2D v1 is a full-scale
   integration test of the design, not a detour.
3. **The mobile clause aligns.** GDD: nothing may make mobile impossible. A top-down 2D
   game is the friendliest possible shape for that constraint.
4. **The docs are already 2D-ready.** 22 main quests at script status, 68 side-quest
   outlines, complete region color scripts, a complete Calling per region — that is a
   finished 2D game's content bible *today*. The distance between the docs and a
   shippable game is much shorter through 2D than through 3D.

---

## 8. Honest costs and risks

- **2D is not cheap 3D.** 21 bespoke boss animation sets in 2D is still 21 bespoke
  animation sets — hand-drawn or puppet-rigged, with bound/unbound region states doubling
  backdrop art. The bound/unbound strategy stays cheap (pose/palette/particle swaps),
  but the headline cost (per-Arcana character animation) moves media; it does not vanish.
- **Two art pipelines if 3D continues.** Sprites and backdrops don't feed the 3D game.
  What *does* carry over: every design doc, every quest, all data definitions, all code
  architecture, the model sheets, the music, the VO, the card art, and everything learned
  from live players. The throwaway layer is the renderable art — the layer that is
  currently the least-built part of the 3D project anyway.
- **v1 defines the public identity.** If v1 is 2D, the eventual 3D version reads as "the
  3D remake" rather than "the real game." That's a framing choice to make deliberately —
  *Ori*, *Hades*, and *Death's Door* show 2D/isometric carries prestige fine, but the
  decision is one-way once shipped.
- **Some awe is genuinely lost.** The colossus felt from below, the Axis watching from
  every horizon, the leap of faith as a camera moment. §3's substitutions (full-page
  plates, painted horizons, side-view sequences) are good — they are not the same.
- **The Anti-Fool wears "the player's rig"** — trivially preserved in 2D (mirrored
  sprite + current Spread), noted only because it is easy to forget it's a costume
  system requirement.

---

## 9. Canon findings and required amendments (applies regardless of the 2D decision)

Found during the review — these are review-checklist findings in their own right:

1. **GDD §Schedule M4 says "both endings"; narrative.md canonically owns *three***
   (True Shuffle / Early Shuffle / Refusal). narrative.md is the SSOT; the GDD line
   should read "all endings." Should be fixed now, independent of this proposal.
2. **A 2D v1 cannot ship as a companion-doc decision.** The GDD owns genre ("third-person
   open-world"), combat.md rule 6 owns "all combat is real-time third-person action,"
   arcana.md rule 7 and the Iteration clause own "every Arcana is a unique character with
   their own model, rig, and animation set," and art-audio §Current build owns the 3D
   pipeline. Adopting this proposal means amending those four places in one PR —
   reinterpreting rule 7's *spirit* (bespoke character quality per Arcana) into 2D terms
   (unique design, silhouette, and animation set) rather than quietly violating its
   letter. Until then, the SSOT says Tarrock is 3D, and this document is a proposal.
3. **The silhouette-first regime transfers intact** — the fill-black test, the per-Arcana
   geometry table, and the costume/materials rules are already how good 2D character art
   is specified. The art bible needs a swapped production-standards section, not a new
   philosophy.
4. **Climb-lite's open TBD** (combat.md) is resolved by 2D rather than complicated by it.
5. **`docs/codex-2d.md` exists and is unreconciled with the GDD.** Whatever is decided,
   the decision belongs in the GDD; neither AI report should stand as shadow canon.

---

## 10. Recommendation

**Ship v1 as the complete Tarrock in 2D — isometric/top-down base, six bespoke side-view
set-piece sequences — all 21 Arcana, all three endings, region size as the scope valve.**
The canon survives the translation with five countable substitutions and one honest
redesign (Overturn outside side-view spaces); several of its deepest commitments — the
tarot-card identity, the map as a dealt spread, the Shuffle as a gathered hand, the
society that answers back, the storybook illustration tradition it already cites — come
through *stronger*. The 3D game remains the long-term vision; everything durable about
it (docs, data, systems, story, music, reputation, and a live player community's worth
of evidence) is exactly what the 2D v1 builds first.

Decision owed by the director: (1) adopt/reject the 2D v1 direction; (2) if adopted,
projection choice (this report argues isometric-with-side-view-set-pieces); (3) the GDD
amendment PR per §9.2.
