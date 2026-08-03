# The Fool's Reading — the playthrough this novelization renders

This is the continuity bible for the novelization in this folder. It fixes **one
player's complete True Shuffle run** — every ordering, every choice, every piece of
kit — so that twenty-two chapters written by many hands agree with each other and with
canon. Canon itself lives in `docs/design/` and `docs/quests/`; this file only *selects*
among options canon leaves to the player. Where this file and a design doc disagree, the
design doc wins and this file is wrong.

Shared prose rules live in [`STYLE.md`](STYLE.md).

## The Reading (unbinding order of this run)

The order below is this playthrough's `READING_ORDER` — the spread the Fool deals across
the whole book without knowing it. It is chosen so the three positions read aloud in the
finale (first, eleventh, last-before-the-World) are the Magician, Justice, and the Sun —
all three canonical worked recital lines in `quests/main/MQ21-the-shuffle.md`.

| # | Card | Region | Quest | Novel chapter | Act |
|---|---|---|---|---|---|
| 1 | I. Magician | The Prestige | MQ01 | 2 | I |
| 2 | III. Empress | The Bower | MQ03 | 3 | I |
| 3 | VI. Lovers | The Divide | MQ06 | 4 | I |
| 4 | V. Hierophant | The Chantry | MQ05 | 5 | I |
| 5 | VIII. Strength | The Maw | MQ08 | 6 | I |
| 6 | VII. Chariot | The Longroad | MQ07 | 7 | I → II |
| 7 | IV. Emperor | The Bastion | MQ04 | 8 | II |
| 8 | X. Wheel of Fortune | The Wheelhouse | MQ10 | 9 | II |
| 9 | XII. Hanged Man | The Gallowwood | MQ12 | 10 | II |
| 10 | IX. Hermit | The Dim | MQ09 | 11 | II |
| 11 | XI. Justice | The Assize | MQ11 | 12 | II |
| 12 | II. High Priestess | The Veil | MQ02 | 13 | II |
| 13 | XIII. Death | The Stillmarsh | MQ13 | 14 | II (keystone) |
| 14 | XIV. Temperance | The Confluence | MQ14 | 15 | II → III |
| 15 | XV. Devil | The Undervault | MQ15 | 16 | III |
| 16 | XVI. Tower | The Spire | MQ16 | 17 | III |
| 17 | XVII. Star | The Mere | MQ17 | 18 | III |
| 18 | XVIII. Moon | The Mirrormarsh | MQ18 | 19 | III |
| 19 | XX. Judgement | The Hollows | MQ20 | 20 | III |
| 20 | XIX. Sun | The Noonlands | MQ19 | 21 | III |
| 21 | XXI. World | The Axis | MQ21 | 22 | III |

Chapter 1 is MQ00 (The Cliff, no unbinding). Death is the **thirteenth** card turned —
card XIII, turned thirteenth; the book may let a character notice this once, lightly
(licensed: Old Sallow). The Sun is turned **last** before the World: the first sunset is
the last unbinding, and the Fool walks to the Axis through the world's first true night,
under stars that were already waiting (`world.md` §The Fool's Reading, Star-before-Sun
motif — canonical bark: "When the sun finally set, the stars were already waiting. Like
they knew.").

Sequence-motif licenses for this run (use these; do not invent others):
- Star-before-Sun sky motif (above) — chapters 21 and 22.
- Death-as-thirteenth noticed once — chapter 14 (Old Sallow, dry).
- "Backwards sort of Fool" Flick motif does NOT apply (Magician was first).
- `HERMIT_ANSWER` barked back exactly twice (see chapter 11 entry).

## Act weather

- **Act I** (chapters 1–7, unbindings 1–6): storybook adventure; unbindings feel purely
  joyous; each region leaves one mourner unresolved; the Stillmarsh is the place nobody
  will talk about; the Axis glitters at the edge of every horizon.
- **Act II** (chapters 8–15, unbindings 7–14): awake and uneasy. Changes compound;
  NPCs ask where this is heading; the Fool starts doing the arithmetic. Chapter 14
  (`CONFESSED`) is the hinge: from chapter 15 on, everyone the Fool meets already knows
  what her journey means, and treats her accordingly — some with gratitude, some with
  terror.
- **Act III** (chapters 16–22, unbindings 15–21): elegiac, tender, resolved. "Last
  days" texture everywhere: festivals, goodbyes, debts settled, the touring Troupe's
  final show. The world is more alive than it has been in three centuries and everyone
  knows it is ending.

## This player's choices (fixed; chapters must honor them)

| Chapter | Choice made | Consequence carried forward |
|---|---|---|
| 2 (MQ01) | Encouraged the Troupe to **travel** (`WS_TROUPE_TRAVELING`) | Troupe recurs on the roads all book (pop-up shows, vendors); their **final show** plays in Act III (ch. 21, Noonlands festival eve — licensed). Ferridge is left with an empty green; he is the threshold mourner in ch. 22. |
| 3 (MQ03) | Shared food with the hungry Coins family; **heeded** Gaffer Nettle (invited approach) | Stallholder debt-of-honour beat at chapter's end. |
| 4 (MQ06) | Chose the **east** bank wedding (`WS_DIVIDE_EASTMARRIED`) | Wystan crosses to Elsbeth's side; west-bank family packs to relocate; Pell's ferry obsolesced. Ch. 22 farewell uses the EASTMARRIED worked line. |
| 5 (MQ05) | **Coaxed Linnet** to sing the early off-hymn note | Her aftermath song is bold, grown-in. |
| 6 (MQ08) | Freed the trapped bear **gently** | Yarrow's respect; mercy-path tone. |
| 7 (MQ07) | Let Corporal Pike **decide in his own time** | Pike keeps the toll-fort by choice; hints at Waystation-keeping (may be glimpsed once later, tending a Waystation — licensed for ch. 20 travel connective). |
| 8 (MQ04) | Earned the Writ **honestly** (the Four Windows) | Nan Ostler beat on-page; Anselm's crooked stamp; feeds Interlude III. |
| 9 (MQ10) | Refused Baroness Fettle's bribe, asked what she's afraid of | Fettle's mourning lands harder. |
| 10 (MQ12) | Answered the Hanged Man: **"No. My arms fell asleep an hour ago."** (foolish) | Wendel delighted. The one deliberate foolish pick of the run; the narrator may savor it. |
| 11 (MQ09) | `HERMIT_ANSWER` = **"Whatever's still waiting to be found."** (earnest) | Barked back exactly twice: ch. 20 (a waiting spirit of the Hollows, gently) and ch. 22 (the Querent, during the Reading). No other callbacks. |
| 12 (MQ11) | Filed as no one; fought **clean** (no cheap tactics all game) | The scales' audit finds an honest fighter; Prudence's mid-fight audit lines note it with faint approval. |
| 13 (MQ02) | The **honest path** — all three tasks true; never drew the staff; kept Vesper's secret | No shadow-duel. The kept secret stays kept: the book never reveals its content beyond what the script says aloud. |
| 14 (MQ13) | Answer at the confession: **"Then I'll walk it with my eyes open."** (earnest) | Colors Mortimer's response; echoes at ch. 22's yield. |
| 15 (MQ14) | Took Delphine's tempering tutorial; heard Elgin Thatch out fully | Conditional fight line (learned tempering); Elgin's mourning beat lands with history. |
| 16 (MQ15) | **Declined all three clauses** | The hardest, proudest fight; Old Nick's respect. The refusal of the Companionship Clause (Pip waits outside) is the chapter's emotional center. No borrow-clause. |
| 18 (MQ17) | **Kept the vigil** in full | Esther's name said to the Fool; the Mere stays bright. |
| 19 (MQ18) | Entered by the **Hermit's Lantern** (slotted Present); did not slot Wish | Arrival texture: the narrow lantern-corridor, most intimate and frightening. |
| 22 (MQ21) | Answer at the yield: earnest (**"Yes. Death told me. I'm ready."**); then **turned the card** | The True Shuffle. |

## The Fool's kit, chapter by chapter

Slots unlock per `progression.md`: Present with the 1st Trump (ch. 2), Past at 3 Trumps
(ch. 4), Future at 7 Trumps (ch. 8). One copy of each Trump; swapping is free out of
combat; full respec at Waystations. Fast travel and the summonable Chariot from ch. 7 on.

| Ch. | Trumps held after | White Rose petals | Favored spread going forward |
|---|---|---|---|
| 1 | none | 3 | — |
| 2 | Manifest | 3 | Present: Manifest |
| 3 | +Bloom | 3 | Present: Manifest |
| 4 | +Union | 3 | Past: Bloom · Present: Manifest |
| 5 | +Rite | 3 | Past: Bloom · Present: Manifest |
| 6 | +Tame | 4 (grafting, Maw) | Past: Tame · Present: Manifest |
| 7 | +Triumph | 4 | Past: Triumph · Present: Manifest |
| 8 | +Decree | 4 | Past: Triumph · Present: Manifest · Future: Decree |
| 9 | +Spin | 5 (grafting, Wheelhouse) | Past: Triumph · Present: Manifest · Future: Spin |
| 10 | +Overturn | 5 | Past: Overturn · Present: Manifest · Future: Spin |
| 11 | +Lantern | 5 | Past: Overturn · Present: Lantern · Future: Spin |
| 12 | +Verdict | 6 (grafting, Assize) | Past: Overturn · Present: Lantern · Future: Verdict |
| 13 | +Secrets | 6 | unchanged |
| 14 | +Passage | 6 | Past: Overturn · Present: Lantern · Future: Passage |
| 15 | +Blend | 6 | unchanged |
| 16 | +Bargain | 7 (grafting, Undervault stair) | unchanged |
| 17 | +Ruin | 7 | unchanged |
| 18 | +Wish | 8 (grafting, the Mere) | unchanged (Wish held, unslotted) |
| 19 | +Glamour | 8 | Past: Overturn · Present: Lantern · Future: Passage (mirrored reversed by the Anti-Fool) |
| 20 | +Reveille | 8 | Past: Overturn · Present: Lantern · Future: Passage (Reap denies the Herald's meter) |
| 21 | +Daybreak | 8 | Past: Overturn · Present: Daybreak · Future: Passage |
| 22 | all 20 | 8 | her choice; the duel is base-vocabulary anyway |

Passage's Past effect (what she fells stays ended) is felt from ch. 14 on — the first
Blank that does not get back up is a beat, not a footnote.

## The book's shape

Front matter: title — **Tarrock: The Fool's Reading** — and a one-page opening in the
narrator's voice (part of chapter 1's brief).

22 chapters (titles = quest titles) + 6 interludes in other voices/forms:

| After ch. | Interlude | Form and voice | Word target |
|---|---|---|---|
| 2 | I. The Programme | The Prestige's last handbill and Flick's patter as the carnival packs; Wren's question; the Troupe takes the road | 1,000–1,400 |
| 4 | II. The Letters That Cross Anyway | Letters between Aunt Perpetua (east) and Uncle Osric (west) spanning the wedding | 1,000–1,500 |
| 8 | III. The Amendment | Bastion documents: Nan Ostler's 300-year petition finally granted; Anselm's crooked stamp; the first theft reports ("Sixpence" Loft) | 1,000–1,500 |
| 14 | IV. The Lantern Ledger | Tarn Loach's ledger: names, first crossings, first funerals; the world learning what the Fool is | 1,100–1,600 |
| 18 | V. Wishes | Slips left at waking wish-wells across the Spread; Marigold Fen reading cards on the road; Act III "last days" texture | 1,000–1,500 |
| 21 | VI. The Rim-Watchers | The people at the Axis's edge — Corvin Rathe, the Loach lens-grinders, Elder Sister Loveday — watching the Fool come; Ferridge arrives with a packed bag | 1,100–1,600 |

Interludes use canon NPCs only, invent no events beyond their sources
(`characters.md` §Regional named NPCs; the side-quest slate they cite), and each must
land one honest laugh and one honest ache.

Main-chapter word targets: ch. 1 ≈ 4,000; ch. 2 ≈ 5,000; chapters 3–13, 15, 17 ≈
4,200–4,800; ch. 14 ≈ 6,500; chapters 16, 18–21 ≈ 5,000–5,500; ch. 22 ≈ 8,000.
Total ≈ 110,000 words.

## Withheld things (permanent, by design — the book keeps them withheld)

- **The Dancer's freed name**: said only to Pip, too low to hear. Never rendered.
- **The Querent's final line before the choice** (MQ21's reserved director's line): the
  narrator declines to repeat it on the page — "what I said to her then was for her, and
  I am keeping it" — honoring the reserved placeholder without drafting it.
- **Vesper's secret** (MQ02 task three): kept. The Fool kept it; so does the book.
- **Why Pip is bowed to; why a white dog walks with every Fool**: never explained.

## Canon reconciliations this novelization relies on

Resolved in the same change as this file (see the respective docs):

1. **MQ21 farewell matrix completed** — the 16 regional farewell one-liners previously
   marked "authored at content pass" are now authored in `quests/main/MQ21-the-shuffle.md`,
   so chapter 22 can quote the gathering-up in full.
2. **MQ05 pipe count** — the script's three town choir-pipes plus the master organ-pipe
   finisher is now stated unambiguously in `quests/main/MQ05-the-same-old-song.md`.
3. **Ferryman Pell / Sculley Marsh overlap** — differentiation recorded in
   `quests/main/MQ06-the-longest-engagement.md` (Pell owns the obsolete-trade mourning
   beat; SQ-DIVIDE-02 owns the gossip-network loss).

Two ambiguities the book simply avoids rather than resolves: the MQ14 bench Mixer is
kept unnamed (not conflated with Comfrey Cross), and the MQ18 multi-light precedence
question never arises (the Fool enters by Lantern with Wish unslotted).
