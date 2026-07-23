---
id: MQ17
title: The Vigil
type: main
status: outline
arcana: XVII. The Star
region: The Mere
requires: []
fires: [WS_STAR_UNBOUND]
---

# MQ17 — The Vigil

## Introduction

The player arrives at the Mere, a night-locked lakeland under one impossible star, and
finds a region that actively resists violence: Fortune doesn't charge here, Blanks don't
enter, and the Warden of the Mere doesn't ask to be fought at all. She asks the Fool to
keep one night's vigil — tend the wish-lights, hear three pilgrims out, sit with Pip on
the jetty — and offers the Trump freely at dawn. Nothing here requires combat. The
player *can* attack her anyway; the game will not stop them, will not punish them
mechanically, and will not forget it either. This is the quietest quest in the game,
placed deliberately among the hardest regions, and it should feel like the whole game
exhaling on purpose.

## Beats

1. **Arrival.** The Mere's shoreline: water like held breath, one enormous star fixed
   overhead, wish-wells dark and waiting along the jetty.
2. **Reading the stasis.** The Warden greets the Fool without ceremony and explains,
   simply: nothing has been wished for and answered here in three hundred years. Not
   because wishing stopped. Because finishing a wish is a kind of ending too.
3. **The invitation.** She asks the Fool to keep the night's vigil with her — no
   combat, no timer pressure beyond the vigil's own pacing. Pip settles at the jetty's
   end immediately, at ease, the calmest he has been in any region so far.
4. **Vigil task — tending the wish-lights.** A simple, unhurried interaction: relight
   the shoreline's wish-lanterns one by one as the Warden pours her waters between
   them.
5. **Vigil task — the three pilgrims.** Three visitors, each a brief vignette:
   - A widower still waiting on a wish made the night before the Stall.
   - A child asking the Warden if wishes ever get old, sincerely worried about her own.
   - An old soldier who stopped believing in wishes decades ago and came anyway, out of
     habit, which the game treats as its own kind of faith.
6. **Vigil task — sitting with Pip.** A wordless beat on the jetty: the Fool, Pip, and
   the star's reflection on flat water. No prompt but "sit." The game does not rush
   this.
7. **THE CHOICE (the only branch point; may be made at any point after beat 3).**

   | Path | What happens |
   |---|---|
   | Keep the vigil (default, no input required) | Proceed to beat 8 |
   | Attack the Warden | She does not defend herself. The Trump is given anyway, at
   once, without ceremony. Skip to beat 11 (shame-branch aftermath). |
8. **Vigil's end.** Dawn does not come — the Mere has no dawn — but the vigil
   completes: every wish-light lit, all three pilgrims heard, the night sat through.
9. **The gift.** The Warden gives Trump XVII — Wish — freely, unprompted by combat of
   any kind. Per `arcana.md` §XVII: the only Arcanum unbound by kindness alone.
10. **Unbinding.** The office cracks gently, more a settling than a break. Her freed
    name — **Esther** — returns, spoken shyly, as if she isn't sure she's
    earned it back yet.
11. **Aftermath — if vigil kept.** Wish-wells wake across the Spread; the night sky
    fills with stars everywhere night exists. `[If WS_SUN_UNBOUND]`: since night
    already exists globally, the new stars are visible in full, everywhere, that same
    night. `[If NOT WS_SUN_UNBOUND]`: the Mere's own permanent night shows the full sky
    immediately (it never needed a day/night cycle to have night), but the rest of the
    Spread's skies won't show the change until `WS_SUN_UNBOUND` fires later — the
    world-state is set now; its full visibility catches up whenever the Sun is unbound
    (order-independence rule, `world.md`).
12. **Aftermath — if the Warden was attacked.** The Trump is granted exactly as in beat
    9 — no mechanical penalty. The Mere itself, though, is permanently dimmer: one
    fewer wish-light, one bark pool instead of the full pilgrim rotation, forever. No
    dialogue calls it out. The game just remembers.
13. **The mourner.** The old soldier from beat 5, if the vigil was kept, is the quest's
    mourning NPC: he liked a world where a wish could stay paused, safely, forever
    unbroken by disappointment. Real hope now means the possibility of real
    disappointment, and he says so, gently, on his way out.
14. **Closing beat.** The Querent, if the vigil was kept: "Not every ending needs
    blood on it, little Excuse. Some of them just need someone to *stay*."

## Key NPCs

- **The Warden of the Mere (the Star)** — canon, see `arcana.md` §XVII,
  `characters.md` §XVII.
- **The old soldier (proposed — promote to characters.md before script status)** —
  one of the three pilgrims (beat 5); the quest's mourning NPC (beat 13).
- **The widower and the child (proposed — promote to characters.md before script
  status)** — the other two pilgrims (beat 5); minor, one scene each.

## [If CONFESSED] variants

- The old soldier's line (beat 13), if `CONFESSED`, sharpens: he knows exactly what
  kind of ending is coming and still thinks paused hope was kinder.
- The widower's vignette (beat 5) gains an acknowledgment that his wish might not get
  answered in the way he pictured, and that this is now possible at all.
- The Querent's closing line (beat 14) is delivered more quietly if `CONFESSED` —
  less a comfort, more a shared held breath.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Vigil completed or Warden attacked | `WS_STAR_UNBOUND` | Wish-wells wake world-wide (coin → timed blessing); night sky fills with stars wherever night exists (full visibility depends on `WS_SUN_UNBOUND`, order-independent). |
| Warden attacked (sub-effect, same flag) | `WS_STAR_UNBOUND` | Mere permanently dimmer: one wish-light and one bark pool instead of the full pilgrim rotation; no other mechanical penalty. |

## Consistency references

- `arcana.md` §XVII — vigil structure, both paths, Trump XVII, unbinding.
- `world.md` §The Mere, §World-state matrix, §Interaction rules (night/Sun
  order-independence).
- `characters.md` §XVII — personality (soft-spoken, hope held still); freed name
  Esther; §Pip (calm, unbothered — no fear beat here, that is MQ18's alone).
- `narrative.md` §Theme 3 — the old soldier's grief for paused hope as "freedom isn't
  wanted by everyone."

## Open questions

- Should the attack-anyway path (beat 12) have any *optional* late-game callback (an
  NPC mentioning the dimmer Mere), or does silence serve the "the game just remembers"
  intent better? Outline assumes silence.
- Confirm the vigil's actual real-time/in-game-time length at script status — "one
  night" needs a concrete pacing target so it reads as restful, not padded.
