# Glossary — Canonical Terms

SSOT for every proper noun and term of art in Tarrock. Docs, quests, dialogue, and (later)
code identifiers use these exact spellings. Add new terms here **before** using them elsewhere.

## The cosmology

| Term | Meaning |
|---|---|
| **The Great Reading** | The cosmic order. The world exists as a tarot reading being dealt, card by card, age by age. |
| **The Stall** | The catastrophe ~300 years ago: the final card was never turned. The Reading froze one card from completion. |
| **The Shuffle** | The end of a Reading — the world is gathered up and dealt anew. Has not come since the Stall. Ending the world **is** the Shuffle; this is what the Fool's journey causes. |
| **The Querent** | The unseen one for whom the Reading is dealt. Speaks to the Fool alone. Identity is a central mystery (see `design/narrative.md`). |
| **The Arcana** (sing. **Arcanum**) | The 21 Major Arcana, locked "in position" since the Stall. Each rules the region that grew around their card. |
| **Unbinding** | Defeating an Arcana. They are released, never killed — the office breaks, the person beneath it goes free, and their region transforms. |
| **Trump** | The card an unbound Arcana yields. Slotted into the Pocket Spread for powers. |
| **In position / Reversed** | An Arcana upright and functioning vs. corrupted by three centuries of stasis. Also the two orientations a Trump can be slotted in. |

## People and creatures

| Term | Meaning |
|---|---|
| **The Fool** | The player character. Card 0, the unnumbered card. |
| **The Excuse** | The Fool's formal title in the game of Tarrock: the one card that belongs to no position and may be played at any time. Why the Fool alone can walk the whole Spread. |
| **Pip** | The Fool's white dog. Named for the pip cards. Appears in every Fool's journey, somehow. |
| **The Minors** | The common folk of the Spread, organized in four suit-cultures: **Cups** (coasts — feeling, hospitality), **Swords** (peaks — intellect, soldiery), **Wands** (woods — craft, passion), **Coins** (plains — trade, earth). |
| **Courts** | The Minor nobility: **Pages** (messengers, children), **Knights** (wanderers, fighters), **Queens** and **Kings** (local rulers). Also the elite enemy tier. |
| **Blanks** | The standard enemies: **humanoid** soldier-figures with blank oval faces, each *bearing* a card that lost its face in the Stall (worn as tabard/heraldry showing suit and rank). The card is the being's anchor — fell the body and its card flutters off to raise a new bearer elsewhere. They represent cards; they are never literal walking cards. |

## Player systems

| Term | Meaning |
|---|---|
| **Pocket Spread** | The Fool's personal three-card spread: **Past** (passive), **Present** (active power), **Future** (triggered/fate effect). Each Trump has a distinct expression per slot, upright or reversed. |
| **Fortune** | The resource spent by Present-slot powers. Earned through combat, discovery, and daring. |
| **The White Rose** | The Fool's vitality, worn at the belt: its petals **are** the Fool's health (3 to start, 8 at most). A hit costs petals; at zero the Fool falls; the rose regrows at Waystations and slowly in unbound regions. See `design/progression.md`. |
| **The Bindle** | The Fool's weapon and inventory: a traveler's bundle on a quarterstaff. Unfolds into the fighting staff and, once each knot is learned, into its **unfoldings**. See `design/combat.md` §The Bindle. |
| **Unfoldings** | The other things the Bindle can become — the lantern, the rod, and the few more the Fool learns. The Fool's own tools, as distinct from a Calling's, which belong to the workplace; usable anywhere once learned; verbs, never weapons or growth. See `design/combat.md` §Unfoldings. |
| **Fool's Chance** | Perfectly-timed dodge: brief slow-motion window and a free Trump cast. |
| **Stagger launcher** | The Bindle's charged heavy in the 2D grammar: lifts the target into a brief helpless stagger that opens bonus follow-ups — the opener a launcher gives, with no aerial moveset. See `design/combat.md` §The Bindle. |
| **Side-view sequence** | One of the canon-designated set-pieces where the oblique top-down view turns to profile for the drama's sake (the leap, the under-stage, the colossus, the carriage roofs, the Gallowwood, the Spire). The list lives in `design/world.md` §Side-view sequences. |
| **Waystations** | Wayside shrines: rest, respec the Pocket Spread, regrow the Rose. Become fast-travel points after MQ07 (Chariot). |
| **Renown** | Per-suit reputation with the Minors. Governs prices, greetings, and some quest branches. |
| **The Almanack** | The Fool's journal: quest log, Bestiary, collected Trumps, and found lore, styled as a hand-annotated manuscript. See `design/art-audio.md`. |
| **The Fool's Reading** | The recorded order in which the player unbinds the 21 Arcana — the tarot spread the player deals across the whole playthrough. The world comments on it, and it styles the True Shuffle ending. See `design/narrative.md` §The Fool's Reading. |
| **Callings** | The repeatable, mundane roles the world offers the Fool (librarian, farmhand, ferryman's mate…) — the temptation to stay, made playable. One per region. See `design/callings.md`. |
| **Shift** | A Calling's unit of work: one in-game hour at the post (one real minute). Each loop pays Coins; each shift pays Renown; the Almanack stamps shifts. See `design/callings.md` §Shifts, wages, and the day. |
| **Days Lived** | The Almanack page that records the Fool's Callings — shifts worked per role, as hand-drawn stamps. A diary, never a checklist. See `design/callings.md`. |
| **The day** | Twenty-four in-game hours in twenty-four real minutes — one game minute per real second. The clock runs from the Fool's first step; the sun does not move until `WS_SUN_UNBOUND`. See `design/world.md` §Time. |
| **Held hour** | The time of day a bound region's sun is stuck at — the Noonlands' noon, the Dim's dusk — which its light and shadows show until `WS_SUN_UNBOUND`. A fact about light, not about what its NPCs know. See `design/world.md` §Time. |
| **The Scattered Deck** | The 56 Minor Arcana cards scattered across the Spread in the Stall — the game's hidden-collectible hunt (Korok-scale). Found cards return to the Cartomancer. See `quests/side/`. |

## The world (see `design/world.md` for detail)

| Region | Arcana | Sketch |
|---|---|---|
| **The Cliff** | — (0) | Tutorial plateau at the world's edge. The Fool's leap of faith opens the game. |
| **The Prestige** | I. Magician | A carnival at perpetual showtime for 300 years. |
| **The Veil** | II. High Priestess | A moonlit cloister-library between two pillars. |
| **The Bower** | III. Empress | A garden-realm strangling on unharvested abundance. |
| **The Bastion** | IV. Emperor | A stone city ruled by unamendable law. |
| **The Chantry** | V. Hierophant | A cathedral-town whose bells ring the same hour forever. |
| **The Divide** | VI. Lovers | A canyon between two towns; an engagement never sealed. |
| **The Longroad** | VII. Chariot | The great causeway ringing the Axis; an endless triumphal procession. |
| **The Maw** | VIII. Strength | Savage highlands; a woman holding a lion's jaws, forever. |
| **The Dim** | IX. Hermit | A dusk-locked mountain lit by one distant lantern. |
| **The Wheelhouse** | X. Wheel of Fortune | A gambling city, half eternally lucky, half eternally cursed. |
| **The Assize** | XI. Justice | Courts where every trial is eternally adjourned. |
| **The Gallowwood** | XII. Hanged Man | A forest where the world hangs the wrong way up. |
| **The Stillmarsh** | XIII. Death | Where the dying gather and cannot pass. Nothing ends here. |
| **The Confluence** | XIV. Temperance | A delta city of mixers where nothing may be finished. |
| **The Undervault** | XV. Devil | A gilded pit where the chained chose their chains. |
| **The Spire** | XVI. Tower | A tower frozen mid-collapse, eternally falling. |
| **The Mere** | XVII. Star | Night-locked lakeland under one enormous star; paused wishes. |
| **The Mirrormarsh** | XVIII. Moon | Illusion-fog wetlands where the path itself lies. |
| **The Noonlands** | XIX. Sun | Golden fields under a sun nailed at noon; drought creeping in. |
| **The Hollows** | XX. Judgement | Graveyards waiting for a call that never came. |
| **The Axis** | XXI. World | The still center of the Spread. The end of the game, and of everything. |

**The Spread** is the world itself — the land, laid out like a dealt spread around the Axis.

## Naming conventions

- Quest IDs: `MQ<card number>` for main quests (`MQ00` prologue … `MQ21` finale);
  `SQ-<REGION>-<##>` for side quests. See `quests/README.md`.
- Arcana are addressed by title ("the Magician"). For most Arcana the personal name is
  unknown to the world and unspoken until unbinding. Four are commonly named by others
  even while bound — Wicke, Mortimer, Aurel, and Old Nick Lowry, worn as public epithets
  by their regions — but the rule that matters holds for all twenty-one: a bound Arcanum
  never claims the name in their own first person ("I am —"). What unbinding returns is
  not the word; it is the name being *theirs to say*. The freed names
  (canonical spellings; character entries live in `design/characters.md`):
  Wicke (I), Vesper (II), Damson (III), Aldric (IV), Bede (V), Elsbeth and Wystan
  (VI — east and west banks of the Divide), Cassian (VII), Maud (VIII), Ellery (IX),
  Penny Farthing (X), Prudence (XI), Wendel (XII), Mortimer (XIII), Averil (XIV),
  Old Nick Lowry (XV), Balen (XVI), Esther (XVII), Luned (XVIII), Aurel (XIX),
  Clemency (XX). The World's name exists but is never the player's to hear
  (`design/narrative.md`; MQ21 owns the beat).
