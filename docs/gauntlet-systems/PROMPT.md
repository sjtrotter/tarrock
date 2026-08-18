# The Systems Gauntlet — Tarrock's game systems, in Godot, for the 2D game

**Run opened:** 2026-08-17 by the director ("run a gauntlet to write the game systems to
support the gameplay — we are using Godot now, targeting a 2D top-down game à la Zelda
ALttP; I am working on the artwork with Codex").
**Branch:** `feat/systems` (off `feat/anim-stepped`, which carries every Godot commit).
**Live page:** [`STATUS.md`](STATUS.md) — round-by-round; committed and pushed at every
round close so the director can watch on GitHub. Machine state between rounds lives in
[`ROUND-STATE.md`](ROUND-STATE.md).

## What this run builds

The engine-side systems that the design docs already specify, so that quests, combat,
progression, and the world's permanent changes can be *authored as data and played* —
starting with the Cliff → Prestige proof slice (`docs/final-claude-2d.md` §10) and built
so the whole 21-Arcana game rests on them without rework. Not art (the director's Codex
lane owns art; see `godot/art/ART-REQUESTS.md` for how gaps are handed over), not quest
content beyond what proves a system, not polish.

The systems, in dependency order (each is normally one round; a round may split):

| # | System | Canon owner | Round proves it by |
|---|---|---|---|
| 0 | Docs first: `technical.md` amended for Godot 2D; the 2D canon amendment (`final-claude-2d.md` §9) | technical.md, GDD.md, combat.md, arcana.md | Reviewed against the CLAUDE.md checklist; no code contradicts a doc |
| 1 | Foundation: test runner, folder layout, composition root, input map, localization tables, definition-resource base | technical.md (amended) | `godot --headless` runs every test in one command; a failing test fails the command |
| 2 | WorldState service: `WS_*` flags, Renown, act thresholds, `READING_ORDER`, `HERMIT_ANSWER`, per-NPC memory, mutation events | world.md §World-state matrix, §Global states; progression.md §Renown | Every matrix row is a generated definition; fire-once/never-unfire proven; act thresholds proven at the boundaries |
| 3 | Save: versioned JSON, explicit migrations, IDs-only, append-only sets | technical.md §Save system | Round-trip + a fixture migration test; a missing migration is a test failure |
| 4 | Quests: state-machine definitions, requires/fires/branches, event-gated transitions, MQ00 wired as the first quest | technical.md §Quests at runtime, quests/README.md, MQ00 | MQ00's beats advance from the Cliff scene headlessly; `fires` commit only at completion; branch groups exactly-one |
| 5 | Dialogue: graph resource, `[If WS_…]` / `[If CONFESSED]` branching on WorldState queries, choice tables, style-guide lints, localization keys only | narrative.md §Dialogue style guide, TEMPLATE.md | An MQ00 scene runs as data; a lint fails on a >12-word Fool line or a literal string |
| 6 | Trumps + Pocket Spread + Fortune + White Rose | progression.md, arcana.md (rules only) | Slot unlock pacing (1/3/7), six-expression rule structural, upright/reversed + burden, Fortune costs/Favor overfill, Rose regrowth by region-bound state |
| 7 | Combat: Bindle moveset (2D), Focus lock-strafe, dodge/i-frames/Fool's Chance slow-mo, block-step, hurt/hit boxes, telegraph→commit→recovery, defeat loop, difficulty modes, accessibility slider | combat.md (amended) | Headless combat sim: a perfectly-timed dodge triggers Fool's Chance and one free Present cast; the Fool at zero petals returns to the last Waystation |
| 8 | Enemies: Blank definitions (suit × rank), telegraphs, pooling, card-flutter defeat; Beasts/Fog-masks stubs gated on WS flags | combat.md §Enemies | One definition per suit/rank; behavior differs by suit, role by rank; `WS_STRENGTH_UNBOUND` neutralises Beasts |
| 9 | Pip: follow (exists), command wheel Fetch/Harry/Seek, cannot die | combat.md §Pip, characters.md §Pip | Seek points at a hidden thing in the Cliff scene; zero health = retreat + return |
| 10 | Regions + Waystations: region definitions, scene switching with the persistent layer, adjacency, rest (Rose regrow, ambient respawn), loadouts, fast travel gated on `WS_CHARIOT_UNBOUND` | world.md §Regions, progression.md §Waystations | Cliff→Prestige transition keeps all services alive; fast travel refuses before the flag |
| 11 | Progression economy: Coins, shops whose stock/prices read WorldState + Renown, staff heads, Rose graftings | progression.md | Food price halves on `WS_EMPRESS_UNBOUND` through data, not code |
| 12 | NPC system: bark layers as data, conditions (WS combos, act, CONFESSED, Renown tier, `READING_ORDER` motifs), light schedules, rumor propagation, aware-of-Pip | npc-system.md | The Sun-before-Star motif bark selects only in that order; layer priority proven |
| 13 | UI shell: HUD (Fortune, petals), dialogue frame, Pocket Spread screen, Almanack (Reading), map-as-spread — vector-first per the UI gauntlet's U1/U2 direction | art-audio.md §UI, docs/gauntlet-ui | Every visible string comes from a translation key |

Later rounds may reorder within dependency constraints; the table is the plan, STATUS.md
is the truth.

## Standing decisions (briefs point here; agents elaborate, never re-decide)

1. **Engine: Godot 4.7.1, GDScript with static typing everywhere.** The godot project is
   `godot/` (`godot --headless --path godot …`). C# / godot-mono is NOT used for game
   systems in this run: the whole existing Godot codebase is GDScript, and a
   single-language project keeps the director's art/scene work and the systems work in
   one toolchain. `shared/Tarrock.Shared` (C#) stays as the seed it is — untouched,
   not expanded, not deleted. (Posted to the director as a confirmable assumption; a
   reversal costs one small port of round-1/2 code.)
2. **technical.md is amended, not replaced**: Unity content stays as the historical/3D
   section; a Godot 2D section owns the conventions this run codes against. Where the
   two disagree for the 2D game, the Godot section wins. Concepts map:
   ScriptableObject → custom `Resource` subclass; asmdef per feature → one folder per
   feature under `godot/systems/`; event channels → signals on the owning service;
   the sanctioned bootstrap → ONE autoload composition root (`Services`) that owns
   plain `RefCounted` services constructible without a scene tree (so tests build them
   directly); Addressables/streaming → scene switching beneath a persistent layer.
3. **Data-driven, docs-generated where docs are tabular.** Definitions live as `.tres`
   resources under `godot/data/<feature>/`, typed by scripts under
   `godot/systems/<feature>/definitions/`. Where the doc is a table or frontmatter
   (world-state matrix, global states, quest frontmatter, region list, glossary
   regions, Renown ladder), a tool `godot/tools/gen_definitions.py` generates the
   resources from the docs and a drift test fails when docs and data disagree. Prose
   facts (what a Trump does) are hand-authored resources that cite their doc section.
   Definitions are immutable at runtime by convention + a test that no system writes to
   a definition; all mutable state lives in the save model.
4. **WorldState is the only mutation path** for flags, Renown, quest state, Reading
   order — exactly per technical.md; a `WS_*` flag can never be un-fired (no method
   exists to do so). Only quest transitions write; everything else raises events and
   subscribes to signals; polling forbidden.
5. **Save**: versioned JSON in `user://saves/`, `schema_version` int, explicit
   `migrate_vN_to_vN+1` chain, missing migration = hard failure, IDs only, append-only
   containers.
6. **Localization from day one**: Godot translation CSV under `godot/localization/`,
   `tr()` keys, no player-facing literal in code or in dialogue resources. A lint test
   greps for offenders.
7. **Input**: named InputMap actions (`move_*`, `interact`, `attack_light`,
   `attack_heavy`, `dodge`, `focus`, `rose`, `pip_wheel`, `spread`, `almanack`,
   `pause`), device-agnostic, rebindable; gameplay code never reads raw keys.
   `player.gd` migrates from `ui_*` to `move_*` in round 1.
8. **2D combat translation** (recorded in the combat.md amendment): Focus = target
   lock + strafing in 8 directions; heavy = radial arc; charged heavy = a *stagger
   launcher* (target lifted into a brief helpless stagger with bonus follow-ups — the
   opener the 3D launcher gave, without an aerial moveset); no jump verb in the
   top-down grammar (ledge drops are contextual; side-view sequences own vertical
   play); the grand backflip survives as the Focus back-dodge flourish; Overturn's
   gravity bubble outside side-view spaces stays TBD in the doc — never resolved in
   code.
9. **Tests are the critic's instrument.** Mandatory surfaces (technical.md): world-state
   transitions, quest state machines, save migrations — plus every system round ships
   tests for the behaviors its "proves it by" cell names. One command runs everything:
   `bash godot/tests/run_all.sh` (exit 0 = green).
10. **Coding conventions (GDScript):** `snake_case` files/functions/variables,
    `PascalCase` `class_name`s, `_leading_underscore` privates, `##` doc comments on
    every public class/method, typed signals, no `get_node` string paths from systems
    into scenes (scenes call systems, systems never reach into scenes), no magic
    strings (IDs come from definitions or a generated constants surface), no per-frame
    allocations in combat/AI loops. Existing scripts under `godot/scripts/` are
    presentation; migrate them under `godot/systems/` only when a round touches them.

## How a round runs

1. **Lead** (Fable, this session) writes the round brief from this charter + the owning
   docs: file ownership, deliverable, tests, tool budget. Pre-dispatch check: every
   file/section the brief names exists.
2. **Builder** (Claude Opus by default; Sonnet only for well-briefed mechanical follow-
   ups; **never Haiku**) implements + tests, runs `run_all.sh`, reports with provenance
   (paths, test names, command output).
3. **Critic** — a fresh-context agent, briefed to be genuinely harsh: reads the diff
   against the owning canon docs and the CLAUDE.md checklist, tries to break the tests
   (mutation-style: does deleting the guard fail a test?), names the single biggest
   remaining gap, sends it back. Loop until the critic finds nothing blocking or the
   lead judges the residue as logged debt.
4. **Lead validates** against canon and the review checklist, then commits (scoped
   adds only — `godot/`, `docs/gauntlet-systems/`, named docs; never `-A`; never the
   director's in-flight files: `docs/README.md` mod, `docs/*-2d.md`,
   `docs/design/3d-models-inwork/`, `docs/design/character-*.md`), pushes
   `feat/systems`, updates STATUS.md in the same push.
5. Codex (`codex exec`) is a cross-model *review* lane only, used sparingly — the
   director's Codex quota is busy with art. Any use follows the memory rules
   (`< /dev/null`, `--` before the prompt with `-i`).

## Director channel (async)

Director-only decisions (canon calls, tradeoffs this charter doesn't settle, hard
blockers) go to a GitHub issue (`gh issue create`, body @-mentions `@sjtrotter`, plain
English for a reader with no run context, links the STATUS.md section). Keep working on
everything not blocked; poll ≥5 min; acknowledge, apply, record in ROUND-STATE, close
when resolved. Carried-twice rule: anything unresolved more than two rounds gets an
issue. Ordinary engineering judgment stays with the lead — take the industry-standard
option and log it.

## Machine rules (director-ordered, still in force)

Governor at `/tmp/tarrock-governor/slots` sets batch width (≤3 agents ever); read it
before dispatch; agents self-pulse on PAUSE. Godot headless runs are light, but only one
sustained full-core process at a time; check `/proc/loadavg` before anything heavy. No
Unity, no Blender in this run.
