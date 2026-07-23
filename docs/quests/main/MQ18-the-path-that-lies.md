---
id: MQ18
title: The Path That Lies
type: main
status: outline
arcana: XVIII. The Moon
region: The Mirrormarsh
requires: []          # HARD GATE (world.md §Hard and soft gates): the Mirrormarsh interior
                       # requires ANY true light — WS_HERMIT_UNBOUND (Lantern), WS_STAR_UNBOUND
                       # (Wish), or WS_SUN_UNBOUND (Daybreak). This is an any-of-three OR
                       # condition, not a single flag, and cannot be expressed in `requires`
                       # as written. See Open questions.
fires: [WS_MOON_UNBOUND]
---

# MQ18 — The Path That Lies

## Introduction

The player reaches the Mirrormarsh's edge only to find Pip — steady through every
horror the Spread has offered so far — refuse to go any further. This is the one thing
in the world he fears, and the quest owns that fear entirely: no other quest may borrow
this beat. Without at least one true light already carried (Lantern, Wish, or
Daybreak), the fog simply loops the player back to the entrance, over and over, the
locked door's message written in geography instead of a wall. With true light in hand,
the player enters a region where the path itself lies, is led astray by something
wearing Pip's shape, and finally meets the boss the whole game has been quietly
building toward without saying so: a mirror carrying the player's own current Pocket
Spread, cast reversed.

## Beats

1. **Arrival — the border.** The Mirrormarsh's fog-line, visibly wrong even from a
   distance: paths that seem to double back on themselves, lights that flicker in
   patterns no lantern makes.
2. **Pip refuses.** He stops dead at the border, ears back, the only time in the game
   he will not follow. This is not staged for effect — it plays exactly the same
   regardless of build, per `characters.md` §Pip.
3. **The gate check.** Without true light, entering the fog loops the player back to
   the border after a short, disorienting walk — no dialogue box, no "you need X,"
   just the region quietly refusing to resolve into anywhere. With true light
   (Lantern raised, Wish's guiding light, or daylight itself), the fog parts enough to
   walk a real path.
4. **Reading the stasis.** A local at the border town explains, carefully, that the
   marsh's "monsters" have always been there, and that nobody who's gone looking for a
   missing relative in the fog has ever come back changed for the better — which reads,
   correctly, as an unresolved warning rather than lore-dump.
5. **Mini-challenge — the lying path.** The first real fog traversal: signposts that
   contradict each other, a bridge that appears solid but isn't, true light briefly
   revealing the real route beneath the false one.
6. **Mini-challenge — the fog-people.** A handful of the region's "monsters" are
   encountered as threats before the reveal — genuinely unsettling, shaped by dread
   rather than gore, in keeping with tone.
7. **The false-Pip beat.** Partway through the deepest fog, "Pip" trots up, tail
   wagging, and confidently leads the way — except the real Pip refused to enter at
   all. Players who know Pip's rules (never leads with false confidence into danger,
   always at the Fool's side, never ahead into an unknown he'd be wary of) feel the
   wrongness before any mechanical reveal. This beat belongs entirely to this quest,
   per `characters.md` §Pip's protection rule.
8. **The reveal.** "Pip" dissolves or shifts, briefly, into fog-stuff — not a jump
   scare, a quiet horror — and leads the Fool onward regardless, deeper toward black
   glass water.
9. **The arena.** Black glass water under the fixed Moon. The boss surfaces: the
   Anti-Fool, carrying the player's *exact current Pocket Spread*, casting the
   player's own Trumps reversed against them, per `arcana.md` §XVIII.
10. **The encounter.** A build-check mirror fight — the reversed burdens of whatever
    the player has slotted become the Anti-Fool's whole kit. Bring the right spread,
    or fight the favorite one, honestly.
11. **The climax.** At the fight's lowest point, the real Pip's howl — audible from
    outside the fog, somehow, the one sound that reaches this far in — cracks both the
    false-Pip's glamour (if not already resolved) and the black glass itself.
12. **Unbinding.** The office cracks with the water. The Moon's freed name —
    **Luned** — returns, and the Trump XVIII — Glamour — is handed over, still
    dripping, honestly uncertain whether it was ever fully "one" person to begin with.
13. **Aftermath — the fog lifts.** Region-wide, the Mirrormarsh's fog clears. The
    "monsters" are revealed as lost people — a town un-curses. Illusion-type enemies
    lose their ambush bonus world-wide.
14. **Aftermath — the mourner.** One of the freed fog-people, Ivy Ashby (proposed —
    promote to characters.md before script status), grieves — not the fog itself, but
    who she was inside it: uncomplicated, untethered from a name and a family she now
    has to be again. She doesn't ask to go back. She's just not ready to be herself
    yet, and says so.

## Key NPCs

- **The Moon** — canon, see `arcana.md` §XVIII, `characters.md` §XVIII.
- **Pip** — load-bearing throughout (beats 2, 7, 11); this is the only quest permitted
  to threaten him, per `characters.md` §Pip's protection rule.
- **The Anti-Fool** — the player's own mirrored Pocket Spread; not a separate
  character, per `arcana.md` §XVIII.
- **Ivy Ashby, freed fog-person (proposed — promote to characters.md before script
  status)** — the quest's mourning NPC (beat 14).

## [If CONFESSED] variants

- The border local's warning (beat 4) gains a line acknowledging that the Fool
  probably already knows what "coming back changed" tends to mean, by now.
- Ivy's grief (beat 14), if `CONFESSED`, includes an acknowledgment that everyone's
  getting their name back, one region at a time, and that hers doesn't feel like a
  gift yet either.
- The false-Pip's dialogue (if any is used pre-reveal) leans harder into dread —
  something wearing warmth it hasn't earned — since the player is more attuned to
  what "getting things back" costs by this point in the game.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Unbinding the Moon | `WS_MOON_UNBOUND` | Mirrormarsh fog lifts; its "monsters" revealed as lost people, a town un-curses; illusion-type enemies lose ambush bonuses world-wide. |

## Consistency references

- `arcana.md` §XVIII — Anti-Fool design, hard gate, Trump XVIII, unbinding; §Cross-Trump
  synergy notes ("the three true lights").
- `world.md` §Hard and soft gates (Mirrormarsh true-light gate, exact wording),
  §The Mirrormarsh, §World-state matrix.
- `characters.md` §Pip — fear of the Mirrormarsh, protection rule, and this quest's
  exclusive ownership of the false-Pip beat; §XVIII personality (unreliable by design).
- `narrative.md` §Theme 3 — Ivy's grief for a self she liked better as "freedom isn't
  wanted by everyone."

## Open questions

- **Gate modeling:** the true-light requirement is an any-of-three OR across
  `WS_HERMIT_UNBOUND`, `WS_STAR_UNBOUND`, and `WS_SUN_UNBOUND` — the frontmatter
  `requires` field as specified in `quests/README.md` implies a flat list (read as
  AND, or at best an implicit set), with no documented OR syntax. This quest needs
  either (a) a documented OR-group syntax added to the schema in
  `quests/README.md`/`technical.md`, or (b) the gate check modeled entirely in-engine
  as region logic rather than in `requires` at all, with `requires: []` here being a
  deliberate acknowledgment that quest-level gating can't express it. Recommend (b)
  for this quest, formalized as (a) if a second any-of gate ever appears.
- Does the false-Pip beat (7) require a distinct visual "tell" beyond behavior (e.g. a
  fog-sheen, wrong eye color) for accessibility, given the beat depends on players
  already knowing Pip's behavioral rules? Needs an `art-audio.md`/accessibility pass.
