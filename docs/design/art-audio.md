# Art & Audio — SSOT

Owns: visual direction, UI/UX direction, music and sound direction, and the VO plan.
Region facts (layout, gating, mood) are owned by [`world.md`](world.md) and only
translated to palette here; character personality is owned by
[`characters.md`](characters.md); world-state facts are owned by `world.md`'s
world-state matrix — this document only owns how each state *looks and sounds*.

## Visual pillars

Three references, stacked:

1. **Painterly storybook** — Fable's warmth. Soft lighting, saturated but never garish
   color, hand-painted texture feel over photoreal detail.
2. **Rider–Waite–Smith woodcut linework** — every character and prop reads with a clean,
   confident outline, the way the deck's own art does. This is the throughline that ties
   a carnival, a courtroom, and a graveyard into one visual language.
3. **Illuminated-manuscript gold-leaf framing** — all UI chrome (menus, dialogue boxes,
   the Almanack, card art borders) borrows gilded, hand-lettered manuscript framing
   rather than modern flat-UI chrome.

Character proportions are stylized and readable — silhouette-first design, so every
Arcanum and every Blank rank is identifiable at a glance and at a distance, which matters
for a boss-driven game where the player must recognize a threat mid-combat.

**Efficiency as craft** (per `GDD.md` §Iteration clause — these choices buy iteration
time for what matters; they are not a poverty plan):

- Low-poly meshes carrying hand-painted textures (bakes in most of the "painterly" read
  without sculpting detail geometry) — a *style* choice first; it also iterates fast.
- URP stylized toon/painterly shading — a small number of shared shaders (character,
  environment, foliage) reused across all 22 regions, which is what makes the world
  read as one illustrated deck.
- Silhouette-first design lets one Blank rig family (per `combat.md`) carry the whole
  *mook* roster through material and prop variation. **This sharing stops at the
  Blanks: every Arcana is a fully bespoke character** — unique model, rig, silhouette,
  and animation set (`arcana.md` design rule 7), and multiple characters where the card
  is multiple beings (the Lovers). The 21 Arcana are the game's art budget's first
  priority, and each is iterated until it could carry a poster.

## Current build: stand-in art (playtest phase)

**Status (blessed 2026-07-15): all 3D art in playable builds is CC0 stand-in art**,
adopted deliberately so playtesting can start now. It is not the final direction — the
Visual pillars above remain the target — and every system is built assuming this art
gets swapped.

The stand-in family is the **KayKit hex-diorama set** (single author, so it reads as one
style): Medieval Hexagon terrain, Adventurers 2.0 baked-outfit characters, Character
Animations 1.1 (161 clips on the shared Rig_Medium), Forest Nature dressing — plus
legacy Quaternius/Kenney pieces where already vendored. Licenses in
`THIRD-PARTY-NOTICES.md`. Chosen because: baked outfits eliminate the clothing-clipping
class of problems; hex-tile terrain makes every region read as a **diorama on a table**,
which rehearses the map-as-cards conceit for free; and the whole family is CC0.

**Swap discipline — the rules that make the art replaceable:**

1. **No content may depend on stand-in geometry.** Layout, gating, and mood facts live
   in `world.md`; quests and code reference marker IDs and definitions, never a
   particular mesh or its dimensions.
2. **Asset references live only in definitions/installers** (per `technical.md`'s
   data-driven rule). Gameplay code never names an art asset inline.
3. **Scale contract** (survives any swap): one hex ≈ 4 m flat-to-flat; player height
   ≈ 43% of hex width; human-usable props are tagged `PropHumanScale` and sized
   relative to the player, terrain furniture is sized to the diorama.
4. **Animation contract**: gameplay addresses animations by logical state (Idle, Walk,
   Run, Dodge, Dig, Sit…) through the Animator; which clip asset fills a state is an
   installer concern, swappable per rig.
5. **Terrain grammar is direction, not art**: elevation signposts the path — cliffs
   refuse, slopes permit, landmarks pull the eye. This survives any art swap and should
   be treated as canon direction for region building.

## The world-state is the art direction

This is the project's central scope strategy: **an unbinding is an art/audio state swap
far more often than it is a new asset.** Every region ships in two visual/audio states
from day one, keyed off its Arcanum's world-state flag (`world.md`'s world-state matrix):

- **Bound regions hold their breath.** Cloth and banners are posed mid-flutter, not
  animated. No wind, no ambient weather particles. Water is glassy, not lapping. Audio
  ambience is a short loop played without crossfade variation, so a careful ear can
  *hear* that it loops — the stasis is audible, not just visible.
- **Unbound regions gain motion.** Wind returns to cloth and foliage, weather rotation
  activates, water animates properly, ambience beds gain layered one-shots (birds,
  distant voices, weather) so the loop point disappears. NPC posing loosens from
  tableau-still to naturally idling.

Building a region "twice" (bound/unbound) is cheaper than it sounds because the base
geometry, textures, and rigs are shared — only pose, particle, lighting, and audio state
change. Budget region art as one asset pass plus one *state* pass, not two asset passes.

## Region color scripts

Palette and one signature visual per region, derived from `world.md`'s region
descriptions. These are direction, not a locked final grade — but no region's palette or
signature visual may be invented outside `world.md`'s canon description.

| Region | Palette | Signature visual |
|---|---|---|
| The Cliff | pale dawn gold, wind-scoured green | the one tree on the plateau that visibly dies |
| The Prestige | gaslit amber, red velvet | confetti and bunting frozen mid-fall |
| The Veil | moonlit silver-blue, ink black | mist that clings to the pillars but never drifts |
| The Bower | overripe emerald, honeyed gold | boughs bowed nearly to breaking under their own fruit |
| The Bastion | granite grey, cold gold | shadows aligned to a clock that never advances |
| The Chantry | candle-wax ivory, stained-glass jewel tones | bells caught mid-swing, silent |
| The Divide | canyon rust, dusk lavender | an unfinished bridge reaching but not meeting |
| The Longroad | sun-bleached banner-gold, road-dust brown | a procession frozen mid-stride, banners stiff as boards |
| The Maw | limestone bone-white, blood-rust | the woman and the lion, jaws held forever |
| The Dim | slate blue-grey, single lantern-gold | one distant light that is never overtaken |
| The Wheelhouse | split: gilt/emerald (lucky) vs. ash/bruise-purple (cursed) | a titanic stopped wheel splitting the skyline |
| The Assize | fog grey, ledger brown | patient queues of the accused, still knitting |
| The Gallowwood | inverted canopy green, hanging-vine violet | a figure hanging content from the World-Tree |
| The Stillmarsh | candle-flat silver, marsh green | lantern light on water that never ripples |
| The Confluence | river teal, tarnished copper | a bridge frozen half-built across the delta |
| The Undervault | gilded ochre, shadow black | chains worn smooth and comfortable with wear |
| The Spire | storm grey, lightning white | rubble and staircases suspended mid-collapse |
| The Mere | midnight blue, single star-white | one impossible star, whole, in glass-still water |
| The Mirrormarsh | fog white, wrong-colored murk | a path — or a face — that has moved when you look away |
| The Noonlands | high-noon gold, drought brown at the edges | a sun nailed motionless directly overhead |
| The Hollows | headstone grey, waiting-candle amber | terraces of graves, tended, and empty of mourners who ever leave |
| The Axis | white-silver, near-colorless | one dancer, alone, at the center of everything |

## Map, the Almanack, and UI

The map screen renders the world as cards dealt face-down on a table (`world.md`);
unbinding an Arcanum turns that region's card face-up. This is the game's primary
progress-at-a-glance UI and should need no HUD counter duplicating it.

The player's journal is called **the Almanack** — a new canon term introduced by this
document; it has been added to `GLOSSARY.md`. The Almanack collects quest logs, the
Bestiary of Blanks and beasts encountered, the Pocket Spread's collected Trumps, and any
lore pages found in the world, styled as a hand-annotated manuscript rather than a
database screen.

**UI/UX pillars:**

- **Diegetic card motifs everywhere.** Loading transitions are card cuts and flips; menu
  navigation moves like laying out a hand; the Pocket Spread's Past/Present/Future slots
  are rendered as an actual three-card spread, not an ability-bar reskin.
- **Minimal quest UI by default**, BotW-style discovery: no floating waypoint arrows, no
  constant objective marker unless the player opts in via an accessibility/assist toggle.
  The Almanack and environmental storytelling carry direction-finding; a quest marker is
  a setting, not a default.
- **HUD restraint:** health (White Rose petals) and Fortune are always visible; everything
  else (minimap, prompts) fades to unobtrusive when not in use.

**Accessibility notes:**

- Scalable text size across all UI, including the Almanack's manuscript styling (which
  must degrade gracefully at large sizes rather than break its frame art).
- Colorblind-safe suit iconography: the four suits already read as distinct **shapes**
  (cup, sword, wand/rod, coin/disc) per the traditional Minor Arcana suit signs, so no
  suit-identifying UI element may rely on color alone — shape and card-rank pip count are
  always the primary read, color is secondary.
- Subtitles and cardspeak murmur captions (see VO plan) ship as a baseline, not a
  post-launch add.
- Full control-remapping and a photo-mode/text-scaling pass appropriate for a mobile port
  are aspirational, gated behind the mobile port itself per `GDD.md`'s target platforms:
  **TBD** whether any accessibility feature must be locked at launch scope to hit M5.

## Card art

The 22 Major Arcana cards (the Fool included) get full-frame illustrated art — the game's
single most important 2D asset set, used simultaneously as UI iconography (Pocket Spread
slotting, the map's face-up cards, the Almanack) and as an in-fiction collectible players
will screenshot. Each card:

- Follows the RWS woodcut-linework pillar in composition and figure, gold-leaf framed to
  match the illuminated-manuscript UI pillar.
- Renders in a visually distinct **reversed** treatment (per `progression.md`'s
  upright/reversed Pocket Spread slotting) — not simply an upside-down flip, but a
  visibly corrupted variant of the same composition, echoing the bound-state art
  direction above.
- Bound-state card art (pre-unbinding) should read as slightly wrong or incomplete
  compared to its unbound version, giving the map screen's face-down-to-face-up flip
  somewhere to visually arrive.

Exact illustrator workflow (fully hand-painted vs. painted-over-3D-render hybrid for
production speed): **TBD**, a production decision rather than a design one.

## Music

- **One Fool's journey theme** — the game's single throughline melody, arranged
  differently by region and act but always recognizable; this is the "you are still the
  Fool" cue no matter how much the world has changed.
- **Twenty-one Arcana leitmotifs.** Each Arcanum has one motif. While bound, it plays
  corrupted and stuck — literally looping a short phrase, unresolved, matching the
  bound-region audio-loop rule above. On unbinding, the stinger (below) resolves the
  loop into a full, unlooped arrangement of the same motif, which then becomes that
  region's unbound ambient theme.
- **Region ambient beds in two states**, per the bound/unbound rule above: a static,
  audibly-looping bed while bound; a layered, evolving bed once unbound.
- **The Axis** is the tonal outlier: near-silence, with one distant, half-heard dance
  rhythm — the lone dancer's music, never resolving, audible from everywhere in the
  region and nowhere quite loud enough to place.

## SFX

- **Blanks carry a card accent, not a paper body** — they are humanoid card-*bearers*
  (combat.md), so their foley is physical (cloth, armor weight, footfalls) with a
  signature card layer on top: a riffle-flick on attacks, and the defeat moment is one
  clean card-turn as the borne card flutters free. The card is heard exactly where the
  metaphor lives.
- **Fool's Chance** (the perfect-dodge, per `combat.md`) is a held-breath riffle-shuffle
  sound, timed to the slow-motion window it opens.
- **The unbinding stinger** is the game's single largest sound event per boss: one
  enormous card turning over, scaled and layered per Arcanum so each of the 21 feels like
  a distinct seismic event rather than a shared stock sting.

## VO plan (scoped)

- **The Querent** is fully voiced throughout — the one character whose voice work covers
  every line, since they narrate constantly and their vocal warmth carries the game's
  tone (`characters.md` §The Querent).
- **The Arcana** get key-line VO only: a small handful of recorded lines each (arrival
  bark, mid-fight taunt or plea, defeat/unbinding line), with the remainder of their
  dialogue text-only. Exact per-Arcanum line count: **TBD**, set once voice budget is
  known.
- **Everyone else** (Minors, Court NPCs, named recurring characters) gets text plus short
  vocal murmurs — "cardspeak": brief, non-verbal or heavily processed vocal stamps (a
  word or two, a grunt, a laugh) rather than full lines, in the Animal-Crossing-adjacent
  tradition of implying a voice without recording one.
- **Pip** uses real dog recordings, not a designed "creature voice" — barks, whines, and
  pants sourced from an actual dog, mixed for game audio rather than synthesized.
- **The Fool** has no dialogue VO by design (`characters.md` §The Fool). Whether the Fool
  has non-verbal combat vocalizations (exertion grunts, hit reactions) is **TBD** — likely
  yes for combat feel, but not yet locked.
