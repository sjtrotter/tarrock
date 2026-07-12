# Tarrock — Design Documentation

This folder is the **single source of truth (SSOT)** for everything about Tarrock. No code is
written until the design here supports it, and no code may contradict what is written here.
The two `.docx` files in the repository root are the original source material; they have been
superseded by these markdown documents.

## Reading order

1. [`GDD.md`](GDD.md) — the master Game Design Document. Start here. It summarizes everything
   and links out to the detail docs.
2. [`GLOSSARY.md`](GLOSSARY.md) — canonical names and terms. If a word for a thing exists here,
   use it; if you need a new term, add it here first.
3. `design/` — one document per discipline. Each is the SSOT for its area:

   | Document | SSOT for |
   |---|---|
   | [`design/narrative.md`](design/narrative.md) | Story, themes, acts, endings, dialogue style |
   | [`design/world.md`](design/world.md) | The map, regions, world-state change matrix |
   | [`design/arcana.md`](design/arcana.md) | All 21 Arcana: characters, boss fights, Trumps, world changes |
   | [`design/combat.md`](design/combat.md) | Player combat kit, enemies, difficulty |
   | [`design/progression.md`](design/progression.md) | Pocket Spread, Fortune, healing, economy, Renown |
   | [`design/characters.md`](design/characters.md) | The Fool, Pip, the Querent, NPC cultures |
   | [`design/npc-system.md`](design/npc-system.md) | Ambient NPC behavior: bark layers, awareness, rumor, schedules |
   | [`design/art-audio.md`](design/art-audio.md) | Visual style, UI, music, sound |
   | [`design/technical.md`](design/technical.md) | Unity architecture, conventions, data model |

4. `quests/` — quest scripts and outlines. See [`quests/README.md`](quests/README.md) for the
   ID scheme, status workflow, and the script template.

## Rules for editing these docs

- **One fact lives in one place.** Detail docs own their facts; the GDD and quest docs summarize
  and *link*, never restate at length. If you find the same fact written twice, one of them is
  wrong (or will be soon).
- **Quests cite canon.** Every quest file lists the canon sections it depends on
  (`Consistency references`). A quest may not invent a world-state change, power, or character
  trait — those get added to the owning design doc first, then referenced.
- **Card meanings are load-bearing.** Every Arcana's character, fight, Trump, and world change
  must be defensible from the card's traditional upright and reversed meanings. When in doubt,
  return to the card.
- **The tone bar is Fable/MediEvil:** storybook warmth, dry humor, and a melancholy edge.
  Whimsy is allowed; snark and grimdark are not.
- Changes to canon require updating every doc that references the changed fact — search before
  you commit. `CLAUDE.md` at the repository root defines the consistency checklist used to
  review every change.
