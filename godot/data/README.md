# `godot/data/` — authored content, as resources

Every content fact the design docs own lives here as a `.tres` resource, one folder per
feature (`data/world_state/`, `data/quests/`, `data/regions/`, …), typed by a
`TarrockDefinition` subclass under `godot/systems/<feature>/definitions/`. This is the
Godot form of the ScriptableObject rule in
[`docs/design/technical.md`](../../docs/design/technical.md).

- **`docs/` is the source of truth, not these files.** Where a doc is tabular
  (the `WS_*` matrix, quest frontmatter, the region list, the Renown ladder), the
  resources are *generated* from the doc and a drift test fails when the two disagree.
  Prose facts are hand-authored resources that cite the doc section they came from.
- **Definitions are immutable at runtime.** Nothing writes to one during play; all
  mutable state lives in the save model.
- **IDs only.** Content refers to content by `TarrockDefinition.id` — never by resource
  path, never by display name — so files can move and names can be localized.
- No player-facing strings in here either: text is a translation key resolved against
  [`godot/localization/`](../localization/).

Empty until round 2 (`docs/gauntlet-systems/PROMPT.md`) writes the world-state matrix out.
