# Art Bible — SSOT

Owns: **production-facing art direction** — the rules artists work from when making a
character, prop, or space for Tarrock: shape language, material and costume rules,
suit-culture craft motifs, silhouette benchmarks, animation-as-character principles,
and the production standards for character and environment assets.

What it does **not** own (link, never restate): visual pillars, shading/palette
direction, region color scripts, UI, and all audio are owned by
[`art-audio.md`](art-audio.md); region facts by [`world.md`](world.md); character
personality by [`characters.md`](characters.md); fight design by
[`arcana.md`](arcana.md); influences by [`../GDD.md`](../GDD.md); engine conventions by
[`technical.md`](technical.md).

**Status note.** Playable builds currently use CC0 stand-in art under the swap
discipline in `art-audio.md` §Current build — including its scale contract (the
player as game-piece miniature against hex-diorama terrain). This bible describes the
**target** art the stand-ins will be swapped for. Where a target decision is still
open (final character proportions, texture pipeline), it is marked TBD rather than
guessed — those calls belong to the in-progress character-art direction pass.

---

## Vision

Tarrock should not look like generic fantasy. It should look like a forgotten fairy
tale illustrated in the margins of an old tarot deck — a world where every hill,
person, and building was drawn by the same unseen hand, for a reason.

The working test for any asset: **does it belong, or is it merely cool?** Everything
in the Spread exists because the Reading dealt it there. A windmill turning in a
golden valley is more Tarrock than a castle exploding. The player should keep
thinking *"I've never seen this before,"* not *"that looks badass."*

Three commitments follow from the game's own canon:

1. **Wonder before spectacle.** The Fool is new to everything
   (`characters.md` §The Fool); the art's job is to make the player feel that too.
2. **Even offices are people.** The Arcana are not monsters; they are exhausted
   people calcified into roles (`narrative.md` §Themes). Every Arcana asset — model,
   idle, costume — must show centuries of accumulated habit, never menace for its
   own sake.
3. **Storybook reality.** The world reads as painted because that is how it truly
   exists — a dealt card, not a simulation (shading direction owned by
   `art-audio.md` §Visual pillars). Stylization is the fiction, not a budget apology.

Tone guard: whimsy without cynicism, warmth without parody — the Fable/MediEvil bar
(`narrative.md` §Dialogue style guide governs writing; this line governs images).

### Reference shelf (art-craft only)

`GDD.md` §Influences owns the game's influences. For purely *visual* craft study,
artists may also pull from: *The Secret of Kells* / *Wolfwalkers* (flattened
storybook space, pattern-as-meaning), *Kena: Bridge of Spirits* (painterly 3D that
stays readable in action), Studio Ghibli's quiet moments (idle life, weather,
mealtimes), and *Dishonored* (environmental storytelling density). References
inform; they are never matched 1:1.

---

## Shape language

The single most load-bearing section. Every named character must be identifiable
**by silhouette alone** — fill the model black; if you can't tell who it is, it is
not done (benchmark procedure below). Each Arcana gets one dominant geometric idea,
derived from the card and the person under it (`characters.md` owns who they are;
this table owns what shape they make).

| Who | Dominant geometry | The silhouette should say |
|---|---|---|
| **The Fool** | Open circles, gentle diagonals; head tilted up; nothing aggressive | "I wonder what's over there." |
| **Pip** | Soft triangles (ears, muzzle, tail), compact mass | Readable at map-icon size; unmistakably a small game dog |
| **I. Magician (Wicke)** | Tall verticals; ribbon flourishes, long coat-tails tapering toward clever hands | Movement, even standing still |
| **II. High Priestess (Vesper)** | Two strict verticals (her card's pillars) framing a closed crescent; layered veils | A book shut politely in your face |
| **III. Empress (Damson)** | Spreading rooted mass; she and the Briar Throne share one outline | Where does the garden end and she begin? |
| **IV. Emperor (Aldric)** | Cubes and right angles; shoulders like a lintel, crenellated crown | Architecture, seated |
| **V. Hierophant (Bede)** | A bell: tiered vestments widening to the floor, mitre as the handle | He is the instrument the Chantry rings |
| **VI. Lovers (Elsbeth & Wystan)** | Two mirrored silhouettes; the negative space between them forms an arch | The unfinished bridge, in people |
| **VII. Chariot (Cassian)** | Forward diagonals; rein-and-banner lines streaming behind; never plumb at rest | Momentum with nowhere to arrive |
| **VIII. Strength (Maud)** | Continuous arcs; her line and the lion's are one curve | Power held, not spent |
| **IX. Hermit (Ellery)** | A tall hunched dark triangle around one warm point of light | The lantern is the silhouette's only opening |
| **X. Wheel of Fortune (Penny Farthing)** | Concentric circles and spokes; asymmetric dress — one side gilded, one side patched | The lucky and cursed halves of the Wheelhouse, worn as clothes |
| **XI. Justice (Prudence)** | Strict bilateral symmetry; the blindfold the one horizontal | Stillness that implies a beam and two hanging scales |
| **XII. Hanged Man (Wendel)** | Inverted triangle, pendulum-calm; loose lines that hang the *right* way in a wood that hangs wrong | The only comfortable thing in frame |
| **XIII. Death (Mortimer)** | Lean, gentle verticals under one crescent (the scythe at rest) | A shepherd by candle-light — warm, never skeletal |
| **XIV. Temperance (Averil)** | S-curves and poured arcs; sleeves and water share one line | Mid-pour, even motionless |
| **XV. Devil (Old Nick Lowry)** | Inviting rounded forms — armchair curves, watch-chain loops — that resolve into chain links on the second look | Comfort, with terms |
| **XVI. Tower (Balen)** | Broken diagonals, fracture lines, impossible balance; crown askew | Never quite plumb; mid-catastrophe as a posture |
| **XVII. Star (Esther)** | One soft radiant point above still horizontals; a kneeling curve at the water | The gentlest light in the game |
| **XVIII. Moon (Luned)** | A silhouette that reads two ways depending on angle — deliberately unstable | The one sanctioned exception to silhouette-first, as design |
| **XIX. Sun (Aurel)** | Radial sunburst; child proportions in knight's kit; every line leaves his center like a noon ray | Joy at full volume |
| **XX. Judgement (Clemency)** | Long ascension verticals crowned by a single flared bell (the trumpet) | The call, drawn as a shape |
| **XXI. The World (the Dancer)** | The perfect circle; wreath symmetry — flawless from afar, travel-worn and human up close | Completion that rewards approach with humanity |
| **Blanks** | A rigid heraldic rectangle (the borne card, worn as tabard) over a featureless oval face | Suit and rank read from the card, never the body (`combat.md`) |

Two global rules:

- **The card's geometry leaks into its region.** The Bastion trends square because
  the Emperor does; the Confluence's bridges curve like Averil's pours; Wheelhouse
  balconies are spoked. Region kits, gates, furniture, and road markers should echo
  their Arcana's dominant geometry quietly — this is how the world reads as authored
  by one storyteller rather than assembled from a kit. (Per-region specifics are
  future chapters; see Roadmap.)
- **The Anti-Fool wears the player's silhouette** by design (`arcana.md` §XVIII) —
  no separate shape language; that's the point.

---

## Materials

Tarrock materials age gracefully. Nothing is pristine; nothing is filthy;
**everything has been loved.** Wear tells you how a thing was used, not that the
artist ran a grunge pass.

| Material | Rule of thumb |
|---|---|
| Leather | Cracked where it bends, darkened where hands go; never torn unless the tear is a story |
| Wood | Rounded edges, visible grain, tool marks; never machine-perfect |
| Metal | Brushed, not chrome; iron oxidizes, brass warms, silver softens |
| Fabric | Heavy weave, visible stitching, patchwork repairs, natural fibers |
| Stone | Rounded and weathered; moss rather than grime |

**The Stall wears the wear.** In bound regions, all aging is three hundred years old
and *frozen* — polished by the same hands on the same spots, no fresh scuffs, dust
hanging in the light rather than settling (motes rule, `art-audio.md` §The
world-state is the art direction). Unbound regions may finally accumulate *new*
wear: fresh mud, dropped petals, yesterday's cart ruts. Weathering state is part of
the bound/unbound art swap, not a static texture fact.

---

## Costume

Nobody in the Spread wears a costume. Everyone wears **clothing they have lived
in** — cut for their work, patched at the honest stress points, carrying exactly the
tools their day needs. For every accessory, ask: *what problem does this solve?*
Every pocket has a reason; every buckle fastens something; every scarf answers
weather. If the answer is "it looks fantasy," remove it.

Suit-culture dress (dyes, cuts, speech-culture pairings) is canon in
`characters.md` §The Minors — costume work starts from that table. This bible adds
the **craft-motif rule**: each suit's makers leave their suit's geometry in what
they make, so an object's origin reads at a glance —

- **Swords** — angular forge-work: chevrons, faceted guards, hard creases.
- **Cups** — flowing curves: vessel profiles, wave-scroll trim, poured lines.
- **Wands** — carved grain: knotwork that follows the wood, tool-wear left proud.
- **Coins** — stamped roundels: disc motifs, ledger-rule borders, weights-and-
  measures tidiness.

The rule covers props, furniture, stitching, sign-boards, and architecture trim as
much as clothing — a Swords-forged pommel and a Cups-thrown jug should never be
mistaken for each other's work.

---

## Color

Palette ownership sits in `art-audio.md` (§Visual pillars, §Region color scripts).
The bible adds the discipline for applying it: **the world is muted; the accents are
saturated — and saturation is a promise of meaning.** Villagers wear earth, linen,
and natural dye; full-chroma color is reserved for the things the game wants your
eye to trust: the White Rose, the Trumps and Arcana effects, tarot iconography, and
each region's signature visual. If an object is bright, the player should be right
to assume it matters. Never spend saturation on set dressing.

---

## Environment

No empty spaces — and no clutter either: **story.** Every abandoned chair implies
someone once sat there; every worn stair implies centuries of footsteps; every tree
grew because the region demanded it. In bound regions this becomes the Stall's
special flavor of storytelling: scenes interrupted three hundred years ago and held
— the meal mid-serving, the game mid-move, the confetti mid-fall (region signatures
owned by `art-audio.md` §Region color scripts).

Structure and navigation rules live elsewhere and are not repeated here: terrain
grammar and path-breathing (`art-audio.md` §Current build, rules 5–6), hydrology
(`world.md` §Hydrology rule), region facts (`world.md` §Regions). Dressing passes
must serve those rules, not fight them.

---

## Animation

**Animation is writing.** Idle animations reveal character more reliably than
dialogue — a character's idle should tell you their card before anyone says their
name. Canonical exemplars (personalities owned by `characters.md`):

- The Fool looks around — at everything, constantly. Wonder is the idle.
- Pip sniffs, ears up: entirely present, utterly unbothered by cosmic stakes.
- Aldric barely moves; his stillness *is* the schedule.
- Ellery breathes slowly, shoulders around his lantern.
- Aurel cannot stop moving.
- Mortimer moves gently — the kindest hands in the game.
- Wendel sways, slightly, like slow rope. Comfortable.

Bound NPCs pose tableau-still; unbound regions loosen into natural idling — the
posing state is half the world-change read (`art-audio.md` §The world-state is the
art direction). Boss animation sets are budgeted per Arcana in `arcana.md`.

---

## Production standards

### Characters

- **Silhouette benchmark (the gate for "modeling done"):** render the asset as a
  flat black shape at gameplay camera distance. Every named character must be
  identifiable; every Blank must read suit-and-rank from its borne card; Pip must
  survive shrinking to map-icon size. Fail the test, revise the model — texture
  cannot rescue silhouette.
- **Read order:** gameplay distance first, portrait distance second. Micro-detail
  belongs in textures, not geometry; when detail and clarity fight, **clarity
  wins** — players remember shapes, not polygons.
- **Modularity (hero assets):** hair, equipment, and accessories are separate
  meshes; one material per logical surface, no orphan material slots.
- **Scale:** 1 unit = 1 meter in Blender and Unity alike, transforms applied,
  origin at the base. (World assembly currently obeys the stand-in scale contract
  in `art-audio.md` — hex module, miniature player read — until the swap.)
- **Proportions: TBD.** Head-count and stylization degree are locked by the pending
  character-art direction pass, not this document. Until then, match the direction
  of whatever bespoke character ships first, and keep rigs Humanoid-compatible so
  animation survives the decision.
- **Texturing pipeline: TBD** at the same pass (hand-painted vs. hybrid), within
  the painterly/toon shading direction owned by `art-audio.md`.

### Environments & props

- Kit pieces obey the region's card geometry (shape-language leak rule) and the
  suit craft-motif rule for anything made by hands.
- Human-usable props are sized to people and tagged per the prop-scale rule in
  `art-audio.md` §Current build; asset references live only in definitions
  (`technical.md`) — no gameplay dependency on any particular mesh.
- Every asset ships bound-state-aware where it can be seen in both states: if it
  would move, flutter, drip, or settle, its bound pose is the *held-breath* version
  (motes, mid-gesture, glassy water), per `art-audio.md`.

---

## Roadmap (future chapters)

Planned expansions of this bible, each a section or sibling doc when its production
phase begins: per-region architecture kits (the shape-leak rule made concrete),
flora & fauna, the prop and material libraries, lighting per region state, and VFX
language for Trumps and unbindings. UI and iconography stay owned by
`art-audio.md`. None of these exist yet; nothing in them is canon until written.

## Open questions

- Final character proportions and texture pipeline (both TBD above) — decided by
  the character-art direction pass now in progress; this bible adopts the outcome.
- Should the shape-language leak rule extend to *music* motifs per region (a
  question for `art-audio.md` §Music, noted here only because the geometry table
  would be its natural index)?
- Whether the Blanks' borne-card heraldry needs a dedicated iconography sheet
  before the first bespoke Blank pass (proposed: yes, one page, owned by
  `art-audio.md` §Card art).
