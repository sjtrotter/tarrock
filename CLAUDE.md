# Tarrock

Tarot-themed open-world action-adventure (Unity, C#; one human director + an AI dev
team). The
player is the Fool, unbinding the 21 Major Arcana who hold a frozen world in place —
and the 21st is The World itself: finishing the journey ends the world, on purpose.
Tone: Fable/MediEvil storybook — warm, dry, gently mournful.

**The project is docs-first.** `docs/` is the single source of truth; code is written
only where the design supports it. Start every task by reading
[`docs/README.md`](docs/README.md) (the doc map and SSOT rules), then the specific
docs your task touches. [`docs/GLOSSARY.md`](docs/GLOSSARY.md) owns every canonical
term and spelling. The Unity project lives at `Tarrock/` (URP, Input System; PC and
Mobile renderer assets) — `Tarrock/Assets/` is where `docs/design/technical.md`'s
folder layout applies.

## Staffing model (how work gets done here)

There is no artificial budget ceiling: the resources are time and an AI dev team, and
the bar is "iterated until polished" (see `docs/GDD.md` §Iteration clause).

- **Fable-level (top level): plan and validate only.** Design decisions, canon-defining
  creative work, task decomposition, briefs, and review of all delegated output happen
  here. Do not spend Fable-level effort on well-bounded execution.
- **Delegate execution to the appropriate intelligence tier:** Opus for hard/judgment-
  heavy implementation, Sonnet for well-briefed mid-level work. **Never Haiku.**
- **Briefs carry the decisions.** A delegated task's prompt must contain every design
  decision already made (or point to the owning doc) so agents elaborate rather than
  invent canon. Agents mark genuinely undecided points as TBD instead of guessing.
- **All delegated work is validated at the top level against canon before it counts as
  done** — read it, check it against the review checklist below, fix or send back.

## SSOT rules (non-negotiable)

- One fact lives in one place. Each `docs/design/*.md` states what it **Owns** in its
  header; other docs link, never restate at length.
- New canon (a term, an NPC, a world-state flag, a Trump behavior) is added to its
  owning doc **first**, in the same change that uses it. Quests never invent canon.
- World-state flags (`WS_*`) exist only in `docs/design/world.md` §World-state matrix.
  Quest `requires`/`fires` frontmatter may only reference flags that exist there.
- Card meanings are load-bearing: anything about an Arcana must be defensible from the
  card's traditional upright/reversed meanings. When in doubt, return to the card.

## Review checklist — every PR / every change

Run every applicable section. A finding is a blocking review comment, not a nitpick.

### 1. Story & canon consistency (all changes touching docs/ or narrative content)

- [ ] Terms match `docs/GLOSSARY.md` exactly (spellings, region names, titles). New
      terms were added to the glossary in this change.
- [ ] No restated canon: facts appear in their owning doc and are linked elsewhere.
      If this change duplicates a fact, move it or link it.
- [ ] The change is consistent with `docs/GDD.md` (vision/pillars) and does not
      quietly alter the twist, the endings, or the act structure owned by
      `docs/design/narrative.md`.
- [ ] Arcana content matches `docs/design/arcana.md` (fight design, Trump effects,
      unbinding beats: office cracks → name returns → Trump handed over personally;
      nobody drops loot; nobody is killed).
- [ ] World changes match the `docs/design/world.md` matrix; no new `WS_*` flag is
      used without being added to the matrix in the same change.

### 2. Quest changes (anything under docs/quests/)

- [ ] Frontmatter follows `docs/quests/README.md` schema; `requires`/`fires`/`branches`
      reference only real flags and quests.
- [ ] The quest follows the quest it claims to follow: check the `Consistency
      references` section against the actual canon sections, then check the quest
      against them.
- [ ] Script-status quests follow `docs/quests/TEMPLATE.md` format (sluglines,
      gameplay blocks, Random Lines, choice tables, `[All versions pick up here:]`
      convergence, world-state table).
- [ ] Dialogue obeys `docs/design/narrative.md` §Dialogue style guide: Fool lines
      ≤ 12 words with one earnest/foolish option; bound Arcana never self-refer by
      personal name; at most ONE Querent fourth-wall wink per quest; every comic scene
      one honest beat, every sad scene one laugh; no modern slang or snark.
- [ ] Order-independence: main quests handle any legal play order; scenes affected by
      other world-states carry `[If WS_…]` variants; MQ02+ carry `[If CONFESSED]`
      variants for key scenes.
- [ ] Pip protection rule (`docs/design/characters.md`): no quest other than MQ18
      threatens Pip.
- [ ] Status promotions (`outline` → `script` → `implemented`) happen only through
      this checklist.

### 3. Code (once the Unity project exists)

Canonical conventions live in `docs/design/technical.md` — review against it, not
memory. Summary of the hard rules:

- Data-driven: content facts live in ScriptableObject definitions mapped from docs;
  definitions are immutable at runtime; all mutable state in the save model.
- World-state flags are read/written ONLY through the WorldState service; a `WS_*`
  flag can never be un-fired.
- No player-facing string literals in code (Unity Localization tables from day one).
- No magic strings; IDs come from definitions. `[SerializeField] private` over public
  fields; file-scoped namespaces; one public type per file; PascalCase public /
  `_camelCase` private; asmdef per feature.
- Mandatory EditMode test surfaces: world-state transitions, quest state machines,
  save migrations. A PR touching any of these without tests is incomplete.
- A change that makes a doc and the code disagree must fix one of them in the same PR
  (`implemented` quests: the doc matches what shipped).

## Working conventions

- Branches: `docs/<topic>`, `feat/<topic>`, `fix/<topic>`. Conventional-commit style
  messages (`docs:`, `feat:`, `fix:`).
- Keep changes reviewable: one quest / one system per PR. A canon change and its
  ripple edits (glossary, cross-links, dependent quests) belong in the same PR —
  search the docs for the changed term before considering the change done.
- `Open questions` sections in quest docs are the designated place for undecided
  design; resolve them by editing the owning canon doc, then updating the quest.
- The two `.docx` files in the repo root are historical source material; the markdown
  docs supersede them. Do not edit the `.docx` files.
