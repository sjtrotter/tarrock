# Quests — Conventions

Owns: quest ID scheme, file organization, the frontmatter schema, and the doc-status
workflow. The script format itself is [`TEMPLATE.md`](TEMPLATE.md) (adapted from the
original `Tarrock.docx` source). Canon rules for what quests may and may not invent:
[`../README.md`](../README.md) §Rules.

## ID scheme

| Pattern | Meaning | Examples |
|---|---|---|
| `MQ<nn>` | Main quest. The number **is the card number**: MQ00 = the prologue (the Fool, card 0), MQ01–MQ21 = unbinding that Arcana. There are exactly 22 main quests, forever. | `MQ13` = Death's quest |
| `SQ-<REGION>-<nn>` | Side quest, homed to a region (uppercase, no "the"). | `SQ-PRESTIGE-01` |
| `SQ-SPREAD-<nn>` | World-spanning side quest — touches all or most regions rather than one home region (collection hunts, trading chains, and similar Spread-wide content). | `SQ-SPREAD-01` = The Scattered Deck |
| `SQ-<SUIT>-<nn>` | Suit-culture side quest — defines a Minor suit-culture's values, homed to a region that culture is present in but not necessarily that region's own Arcana. `SUIT` ∈ `CUPS` / `SWORDS` / `WANDS` / `COINS`. | `SQ-CUPS-01` = The Guest-Right |

Files: `main/MQ<nn>-<kebab-title>.md`, `side/SQ-<REGION>-<nn>-<kebab-title>.md`,
`side/SQ-SPREAD-<nn>-<kebab-title>.md`, `side/SQ-<SUIT>-<nn>-<kebab-title>.md`.

## Frontmatter schema

Every quest file opens with YAML frontmatter. This block is load-bearing: it maps 1:1 to
the future `QuestDefinition` ScriptableObject (see
[`../design/technical.md`](../design/technical.md)), so the doc *is* the data spec.

```yaml
---
id: MQ01                      # ID per scheme above
title: The Greatest Trick     # display title
type: main                    # main | side
status: outline               # outline | script | implemented
arcana: I. The Magician       # the card, or 'none' for most side quests
region: The Prestige          # home region (GLOSSARY spelling)
requires: []                  # WS_* flags and/or quest IDs that must be set/complete
fires: [WS_MAGICIAN_UNBOUND]  # WS_* flags this quest sets on completion
branches:                     # mutually exclusive WS_* flags set by player choice (omit if none)
  - [WS_TROUPE_TRAVELING, WS_TROUPE_SETTLED]
---
```

Rules:

- `requires` and `fires` may only use flags that exist in
  [`../design/world.md`](../design/world.md) §World-state matrix. A quest needing a new
  flag adds it to the matrix **first**, in the same change.
- Main quests must handle being played in any order consistent with their `requires`
  (order-independence rule, world.md). If a scene changes when another world-state is
  already set, the script marks the variant: `[If WS_SUN_UNBOUND: …]`.
- Every quest from MQ02 onward carries **post-confession variants** for its key scenes
  (`[If CONFESSED: …]`) per [`../design/narrative.md`](../design/narrative.md) §Act II.

## Status workflow

`outline` → `script` → `implemented`

- **outline** — structured beats (synopsis, beat list, NPCs, choices, consistency refs).
  Enough to evaluate against canon and to schedule.
- **script** — full screenplay per [`TEMPLATE.md`](TEMPLATE.md): every cutscene, choice
  dialog, bark set, and branch written.
- **implemented** — the quest exists in the Unity project and the doc matches what
  shipped. Any divergence found later is a bug in one of the two.

Promotion to `script` or `implemented` requires the consistency review in the root
`CLAUDE.md`.

## Required sections (all quests, all statuses)

1. Frontmatter (above).
2. **Introductory paragraph** — written from the *player's* perspective (what the player
   is doing and needs to know), per the original template.
3. **Beats** (outline) or full script (script status).
4. **World-state changes** — restated as a Choice/Consequence table where branching.
5. **Consistency references** — bullet list of the canon sections this quest depends on
   (e.g. `arcana.md §I`, `world.md §Prestige`, `characters.md §Flick`). Reviewers check
   the quest against exactly these.
6. **Open questions** — anything the quest needs canon to decide, phrased as decisions.
