# `godot/systems/` — the game's systems

One folder per system, in the dependency order of
[`docs/gauntlet-systems/PROMPT.md`](../../docs/gauntlet-systems/PROMPT.md). This is the
Godot answer to Unity's "asmdef per feature" in
[`docs/design/technical.md`](../../docs/design/technical.md).

- Systems are plain `RefCounted` services, constructible with no scene tree, so tests
  build them directly. `systems/core/services.gd` is the single autoload that
  constructs them in dependency order and holds them as typed fields.
- **Scenes call systems; systems never reach into scenes** — no `get_node` string paths
  out of a system, no `find_child`. Systems report through typed signals.
- `<system>/definitions/` holds the `Resource` subclasses that type the authored `.tres`
  content under [`godot/data/`](../data/README.md).
- Presentation scripts still live under `godot/scripts/`; a script moves under
  `systems/` only when a round has reason to touch it.

`core/` is the foundation everything else may depend on and which depends on nothing:
the composition root, the input-action names, the definition base class, the clock.
