# `systems/ui/` — the shell: HUD, dialogue frame, the Spread, the Almanack, the map

Built by round 13 of [`docs/gauntlet-systems/PROMPT.md`](../../../docs/gauntlet-systems/PROMPT.md).
Canon: [`docs/design/art-audio.md`](../../../docs/design/art-audio.md) §Visual pillars 2–3
and §Map, the Almanack, and UI (which owns the UI/UX pillars and the accessibility notes),
[`docs/design/technical.md`](../../../docs/design/technical.md) §Godot 2D (port-readiness,
conventions, localization), [`docs/design/combat.md`](../../../docs/design/combat.md)
§Accessibility and §Difficulty modes, [`docs/design/progression.md`](../../../docs/design/progression.md)
(the Spread, the Rose, Fortune, Waystations, Renown), and the UI gauntlet's round U1
concepts ([`docs/gauntlet-ui/`](../../../docs/gauntlet-ui)), used as the implementation
source they were drawn to be — see [`res://art/ui/README.md`](../../art/ui/README.md).

**Every visible string is a translation key.** That is this round's "proves it by" cell,
and it is enforced four ways: `UiKeys` is the only place a key is spelled,
`tests/unit/core/localization_lint_test.gd` fails on a literal in any `.tscn`, `.gd` or
`.tres`, `tests/unit/ui/ui_keys_test.gd` proves the two directions nobody else checks
(every constant has a CSV row, and every CSV row is named by a constant), and
`tests/unit/ui/ui_strings_test.gd` **builds every page and reads back every string it
drew** — which is the one that matters here, because these pages assemble their Controls
in code and a file-reading lint cannot see `button.text = "Resume"` happen. The two kinds
of text that cannot be a single key — a row formatted out of a key and a number ("Slot 1")
and a device label the hardware spells ("Space", "LB") — say so on the control itself
(`UiKeys.COMPOSED_TEXT_META`), which is a claim in the tree a reviewer can check.

## The shape

```
ui_keys.gd            every key the shell resolves; nothing else spells one
ui_frames.gd          the U1 art as NinePatches, the palette, the patch margins
ui_scale.gd           the text-size setting, applied to the one theme
ui_settings.gd        user://settings.cfg: options AND rebinds (see the ruling below)
ui_state.gd           which menus are up -> GameClock.paused
input_glyphs.gd       an InputMap action -> the key or pad button to draw on a chip
definitions/map_layout.gd, map_placement.gd    where each of the 22 cards lies
nodes/ui_shell.gd     the one node under UIRoot: builds the pages, wires the services
nodes/hud.gd          petals + Fortune, always; a prompt chip that fades; nothing else
nodes/rose_meter.gd   one petal icon per charge, spent ones faint
nodes/health_meter.gd the health POOL, drawn as the bloom's fullness - TBD, issue #11
nodes/fortune_meter.gd the band, with the Favor overfilling past the cap
nodes/prompt_chip.gd  U1's marginal slip: a key, and the live glyph for an action
nodes/fools_chance_vignette.gd  the gold wash, obeying the screen-flash toggle
nodes/dialogue_frame.gd  U1's panel: name plate, line, the Fool's options, "…"
nodes/camera_framing.gd  the easing zoom into a conversation; no hard lock
nodes/card_view.gd    one card: face-up/face-down, upright/reversed, name, number
nodes/pocket_spread_screen.gd  Past/Present/Future as three real cards; loadouts
nodes/almanack.gd     Quests, the Reading, Trumps, Bestiary, Lore
nodes/map_screen.gd   22 cards on a table; face-up = unbound; fast travel
nodes/pip_wheel_overlay.gd  the three sectors, while the wheel is held
nodes/pause_menu.gd   Resume / Save / Load / Settings / Quit - asks, never acts
nodes/settings_screen.gd  every option combat.md and art-audio.md ask for
nodes/defeat_overlay.gd   a gentle fade after Pip's lick; no drama, no invented lines
nodes/bark_bubble.gd  round 12's barks, as a slip over somebody's head
nodes/card_transition.gd  a region change, as a card turned over
```

Scenes are under [`res://scenes/ui/`](../../scenes/ui) — one per page, each a single root
node carrying its script, and that is all any of them contains. **The scene is the ENTRY
POINT and the view builds its own Controls in `_ready()`.** Nearly everything on these
pages is counted out of the world at runtime (a petal per point of capacity, a card per
region, a row per dialogue option, a rebinding row per action), and a page laid out half in
a `.tscn` and half in code would have its layout in two places and its strings in two
lints. So the layout is in one place — the script — and the strings are protected by
`tests/unit/ui/ui_strings_test.gd`, which builds each page and reads back what it drew.
(A later round that wants a page authored in the editor moves that page's structure into
its scene; nothing else here changes, and the string lint covers both.)

## Decisions this round made

- **Rebinds and settings live in a settings FILE, not the save file.** This closes
  `technical.md` §Open questions (TBD) — Godot 2D's "Rebinding UI and the settings save".
  `user://settings.cfg`, via `ConfigFile`, holds text scale, screen shake/flash, the quest
  marker toggle, the Fool's Chance window bonus, hold/toggle per held input, and the
  rebindings. A binding is a fact about the person at the keyboard, not about the Fool: a
  second playthrough keeps it, and loading an old save does not restore an old text size.
  The difficulty mode stays in the save (`SaveModel.difficulty_mode`) and is only
  MIRRORED into the file so the settings screen can show it before a playthrough exists.
- **A rebind replaces one DEVICE CLASS, not the whole binding.** Every action is bound
  twice in `project.godot` — a key and a pad button — and a player moving `rose` off R has
  said nothing about the controller. `UiSettings.rebind()` therefore replaces only the
  events of the pressed device's own class, remembers the whole resulting list, and
  restores the whole list on the next boot; restored events carry `device = -1` (all
  devices), exactly as the authored ones do.
- **Settings are pushed again whenever they change.** `UiSettings.changed` is what the
  shell listens to (`UiShell.apply_settings`): the screen edits the settings object, and
  the shell is what makes the screen-flash toggle reach the Fool's Chance wash and the
  text size reach the theme. "Reset to defaults" resets that object IN PLACE
  (`UiSettings.reset()`) rather than building a new one, because the shell holds it.
- **A conversation takes the camera frame, and gives it back.** `DialogueFrame` asks
  `CameraFraming` for the easing zoom when a view first appears and releases it when the
  conversation ends — once per conversation, never per line, so a player who walks out of
  the frame is not hauled back into it by the next line. Who is framed comes from the
  SPEAKER-NODE PROVIDER (`UiShell.speaker_node`, handed over as a `Callable`): the Fool and
  Pip for the Querent — `art-audio.md` frames "the Fool and Pip especially", and the
  Querent is a voice with no body — a named speaker's own node where a region scene has put
  one in the group named by that speaker's id, and the Fool alone where there is nobody
  else. The shell is the one node that can answer this, because the persistent layer beside
  it owns the Fool and Pip.
- **The map has no InputMap action of its own.** `technical.md` §Input actions fixes the
  action list and this round adds none, so `almanack` turns the page: Almanack → the
  Spread on the table → closed. A dedicated `map` action is a change to that list; it is
  owed below.
- **The HUD carries no progress counter.** `art-audio.md` §Map says the map screen "is the
  game's primary progress-at-a-glance UI and should need no HUD counter duplicating it",
  so there is no unbound count, no quest tracker and no minimap on the HUD. Adding one is
  a canon change.
- **Dialogue does not pause the world and is not a menu.** `art-audio.md` §UI/UX pillars:
  an easing camera zoom, no separate screen, no hard lock. `UiState` therefore never
  counts the dialogue frame, and `CameraFraming` releases itself when the Fool walks off.
- **The Querent's defeat remark is a graph id and nothing else.** Canon gives a rotating,
  low-frequency pool of warm, dry lines and gives none of its words.
  `DefeatOverlay.QUERENT_REMARKS_GRAPH` (`DEFEAT_QUERENT_REMARKS`) is the id the writing
  lane authors into; this round plays nothing there, because inventing a Querent line in
  a UI script would be inventing canon.
- **A Blank has no name, so the Bestiary names the card.** `combat.md` §Enemies gives no
  enemy display names and `systems/enemies/README.md` says so; the Bestiary draws the
  suit's SHAPE and the rank's printed number (a Court rank prints its own name), which is
  also `art-audio.md` §Accessibility notes' colourblind rule satisfied by construction.
- **A Trump's slot texts do not exist and are not guessed.** `arcana.md` owns them and has
  authored none in player-facing words, so each slot letters `UI_TRUMP_TEXT_PENDING`. A
  `TRUMP_NN_PAST/PRESENT/FUTURE_TEXT` key set is a writing request, listed below.

## The MQ00 tutorial prompts

`docs/quests/main/MQ00-the-leap.md` writes twelve `[Tutorial prompt: …]` brackets. Eleven
are prompts a player reads; the twelfth says "none — this reassembly plays automatically",
which is a direction and not a line, so it has no key. The eleven are
`TUTORIAL_MQ00_*` rows in [`localization/strings.csv`](../../localization/strings.csv) —
with the quest doc's imperative kept **verbatim** and the STAGE DIRECTION inside the same
bracket left out, because it is written to the team, not to the player:

| Key | Bracket | Left out of the row |
|---|---|---|
| `TUTORIAL_MQ00_BINDLE` | pick up the Bindle. | — |
| `TUTORIAL_MQ00_MOVE` | move. | "The camera follows; a soft highlight marks the meadow's open ground." |
| `TUTORIAL_MQ00_CAMPSITE` | interact with a fire-ring to inspect it. | "No dialogue triggers — this is environmental only." |
| `TUTORIAL_MQ00_SEEK` | call Pip's Seek command. | — |
| `TUTORIAL_MQ00_DEAD_TREE` | approach the dead tree. | "No combat, no item — a beat, held for a few seconds before the Querent speaks." |
| `TUTORIAL_MQ00_LIGHT_STRING` | light string — three quick strikes of the Bindle. | — |
| `TUTORIAL_MQ00_DODGE` | dodge roll — a short burst of invincibility. Time it against an incoming strike for Fool's Chance | ": a long beat of slow time (~1.5s, per combat.md) and a free opening." |
| `TUTORIAL_MQ00_REST` | rest at the Waystation. | "The Rose regrows to full. The Pocket Spread menu is introduced but empty…" |
| `TUTORIAL_MQ00_EDGE` | approach the cliff's edge | "to trigger dialogue." |
| `TUTORIAL_MQ00_EDGE_AGAIN` | approach the very edge. Pip will not wait long. | — |
| `TUTORIAL_MQ00_LEAP` | step off the Cliff. | — |

Only the leading letter is capitalised, which is typography rather than wording. **Nothing
raises these prompts yet**: the Cliff scene's beats are the round that owns showing them
(`PromptChip.show_prompt` is the door), and the rows exist first so that round wires
instead of writes. That is owed work, listed again below so it is counted with the rest.

## Owed / TBD

- **Nothing raises the MQ00 tutorial prompts.** The eleven rows exist and `PromptChip`
  draws whatever it is handed; the Cliff's beats are the round that calls it (see the table
  above).
- **Issue #11 (health vs petals) decides `HealthMeter`.** Its class doc carries both
  readings and what happens to the control under either. Nothing else in the shell
  depends on the answer.
- **A `map` InputMap action**, if the page-turn above is not the wanted answer. One row in
  `technical.md` §Input actions, one constant in `InputActions`, three lines in `UiShell`.
- **`TRUMP_NN_{PAST,PRESENT,FUTURE}_TEXT` and `TRUMP_NN_BURDEN_NAME_KEY`** — writing
  requests. `arcana.md` owns the effects; the localization lint's own note already spells
  out that the burden name a screen shows is a NEW `burden_name_key` field and never the
  doc-citation `burden_name`.
- **The Bestiary is not in the save file.** `EnemyService` now remembers what has been met
  and offers `to_snapshot()` / `restore_snapshot()`, which NOTHING CALLS: wiring a
  `bestiary` section into `SaveModel` is the save lane's shape to change, so today the
  Bestiary remembers a session and the snapshot pair sits unwired. It is kept rather than
  deleted because the section it is waiting for is a known, small save-lane change — and
  it is listed here so that "unwired" is a decision on the page rather than a surprise.
- **The Pip wheel's hold/toggle does not reach anything yet.** `combat.md` §Accessibility
  names it as a held input and `SettingsScreen` offers it, but `FoolCombat.set_hold_mode`
  knows the other four and `PipCompanion` has no latch of its own — owed to whoever next
  touches `systems/pip/nodes/pip_companion.gd`.
- **Nothing draws a quest marker.** The assist toggle exists and persists (OFF), as
  `art-audio.md` requires; the marker itself is owed to whoever builds one.
- **Nothing shakes, so the screen-shake toggle reaches nothing.** `combat.md`
  §Accessibility asks for the toggle and it is here, honoured in the file and in
  `UiSettings.screen_shake`; there is no camera-shake system in the project for it to turn
  off. Whoever adds one reads it (the settings object is pushed on every change) — and
  until then the setting is a promise the game keeps only by never shaking.
- **The Querent's barks have no body to float over.** `BarkService` picks the Cliff's four
  idle lines and `UiShell.say_bark_for` draws a slip over whoever said it — but the Querent
  is "the unseen narrator-guide voice" (`characters.md`), so there is nobody to draw it
  over and nothing appears. Whether a Querent line is VO, a subtitle, or a slip over the
  Fool is `art-audio.md`'s call, not a UI round's; the wiring is done and waiting for it.
- **A Waystation does not open the Spread's loadout panel by itself.** The panel follows
  `PocketSpreadService.at_waystation()`, which `RegionService` sets; both are real, and
  no scene calls the rest verb that would let a player see it yet.
- **`DEFEAT_QUERENT_REMARKS` has no graph.** The writing lane owns the pool.
