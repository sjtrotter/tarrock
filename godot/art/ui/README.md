# `art/ui/` — the shell's vector art

Source: [`docs/gauntlet-ui/concepts/`](../../../docs/gauntlet-ui/concepts) (round **U1**,
`DONE`). Those SVGs are the implementation source, exactly as
[`docs/gauntlet-ui/STATUS.md`](../../../docs/gauntlet-ui/STATUS.md) says. Two concepts are
used — `dialogue-a.svg` (Gilded Vine) and `prompt-a.svg` (Marginal Note) — and the files
here are those two taken apart: **paths are copied, never redrawn by hand; what is dropped
is dropped whole; nothing is added.** The parts that belong to a Control of their own (the
speaker cartouche, the advance lozenge) are cut out into their own file with their path
re-originated onto a canvas that fits it, which is the only geometry that changes.

Path by path, so the next person can check it against the concept:

| File | Taken from | Every path KEPT | Every path DROPPED, and why |
|---|---|---|---|
| `dialogue_frame.svg` | `dialogue-a.svg` | the parchment body, the gold rail, the inner black rule, and the two foliate corner clusters (one path for the top pair, one for the bottom) — five paths, unchanged | `<title>`/`<desc>` (authoring metadata); the dark presentation `<rect>` (there to photograph a frame, not to be drawn behind one); the speaker cartouche and its highlight (its own file, below); the "THE QUERENT" `<text>`; the two vertical gold rails and their inner curves (they fence a fixed text column, and the panel's column is a container at whatever text size the player chose); both placeholder `<text>` lines; the advance lozenge (its own file, below) |
| `name_plate.svg` | `dialogue-a.svg`'s speaker cartouche | the cartouche outline and its pale-gold highlight, re-originated from (390,36) onto a 420×52 canvas | the "THE QUERENT" `<text>` that sat on it — the plate is a `PanelContainer` and the name is a `Label` over it |
| `caret.svg` | `dialogue-a.svg`'s advance lozenge | the lozenge, re-originated from (1080,238) onto a 28×28 canvas, its arms shortened from 14 to 10 so the 4-wide stroke fits inside that canvas | nothing else was in it |
| `prompt_chip.svg` | `prompt-a.svg` | the parchment chip and its gold inner rule — two paths, unchanged | `<title>`; the dark presentation `<rect>`; the stick glyph (lozenge + dot) and the leader rule after it (the glyph is read live out of the `InputMap` by `InputGlyphs`, so a rebind changes it); the "Move the left stick" `<text>`; the trailing lozenge |
| `panel.svg` | **new**, in the same border language | three nested paths — body, gold rail, inner rule — at menu proportions, following `dialogue_frame.svg`'s construction | — |
| `card_face.svg`, `card_back.svg` | **new, placeholder** | — | — |
| `petal.svg` | **new, placeholder** | — | — |
| `suit_cups/swords/wands/coins.svg` | **new**, the four traditional suit signs | — | — |
| `theme.tres` | the U1 palette | — | — |

Baked-in English is exactly what `docs/gauntlet-systems/PROMPT.md` standing decision 6
forbids, which is why every `<text>` above is dropped rather than translated: each of those
words is a `Label` over the art instead, resolved through
[`localization/ui.csv`](../../localization/ui.csv), and
`res://tests/unit/ui/ui_strings_test.gd` reads them back off the built page to prove it.

How each file is drawn:

| File | Drawn as |
|---|---|
| `dialogue_frame.svg` | `NinePatchRect`, margins 180/100/180/100 |
| `name_plate.svg` | `NinePatchRect`, margins 40/0/40/0 |
| `prompt_chip.svg` | `NinePatchRect`, margins 60/40/60/40 |
| `panel.svg` | `NinePatchRect`, margins 52/40/52/40 |
| `caret.svg` | `TextureRect` |
| `card_face.svg`, `card_back.svg` | `TextureRect` inside `CardView` |
| `petal.svg` | `TextureRect`, one per White Rose charge |
| `suit_cups/swords/wands/coins.svg` | `TextureRect` |
| `theme.tres` | the one `Theme` every Control uses |

Palette, from U1 and unchanged: parchment `#ead9ad`, ink `#211a12`, gold `#b88a2c`, pale
gold `#f0dfaa`, ground `#1d1811`. `UiFrames` is the only place a `Color` or a patch margin
is spelled in code.

## ART REQUESTS (the Codex lane's, per `godot/art/ART-REQUESTS.md`)

1. **A font.** Everything is Godot's default face today. `art-audio.md` visual pillar 3
   wants hand-lettered manuscript chrome; the theme has one `default_font_size` and no
   font, so dropping a face into `theme.tres` is the whole change.
2. **U2's restyle, applied to these five frames.** `docs/gauntlet-ui/STATUS.md` §U2 names
   the gap: the corner ornaments read as Art-Deco talons rather than tarot woodcut, and
   the lines are too geometrically perfect. Redrawing `dialogue_frame.svg`,
   `prompt_chip.svg`, `panel.svg`, `name_plate.svg` and `caret.svg` in place needs no code
   change **as long as the border widths stay within the patch margins above** — if they
   grow, `UiFrames`' margin constants move with them.
3. **The 22 card faces.** `art-audio.md` §Card art: full-frame illustrated art, a visibly
   corrupted **reversed** variant, and a **bound-state** variant that reads as slightly
   wrong. Until they exist, `CardView` letters the name and the printed number onto
   `card_face.svg`, and draws a reversed card turned about — which is what the finished
   art replaces, not something it contradicts. The map's face-down cards want the same
   deck's back.
4. **A White Rose petal that is the White Rose's petal**, in five states — whole, three
   quarters, half, one quarter, spent — because the petals ARE the Fool's health
   (issue #11) and `RoseMeter` fakes the four partial states with alpha today.
5. **The suit marks, in the deck's own hand.** The four here are honest woodcut-ish
   shapes and colourblind-safe by construction (shape only, no colour), but they are not
   drawn by whoever draws the Blanks' tabards, and they should match those.
