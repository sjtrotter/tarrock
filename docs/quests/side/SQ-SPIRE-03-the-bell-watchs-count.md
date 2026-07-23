---
id: SQ-SPIRE-03
title: The Bell-Watch's Count
type: side
status: outline
arcana: none
region: The Spire
requires: []
fires: []
---

# SQ-SPIRE-03 — The Bell-Watch's Count

## Introduction

A small, still quest about being witnessed. Somewhere below the frozen tower, a junior
keeper of the bell-watch has spent a working life logging every lightning strike the Spire's
warning bell has caught — dry, numbered entries in a battered ledger, kept out of duty
rather than hope. Read end to end, which no one has ever bothered to do, the log stops
being a record and becomes something closer to a poem: three hundred years of waiting for a
strike to finally finish striking, one line at a time. The quest is simply the Fool reading
it through, and discovering that mattering to one quiet person is sometimes the whole of a
good deed. It plays before the Spire falls.

## Beats

1. **The hook.** The junior bell-watch keeper (unnamed; proposed — promote to
   `characters.md` before script status; distinct from Harrow Brock) is buried in ledgers at
   the watch-post, cross-checking a strike-count nobody has ever asked to see. They are dutiful,
   dry, and faintly apologetic about the whole business — it's the job, they'll tell you,
   somebody has to keep the count.
2. **The complication.** The keeper needs help finding one particular entry — an old strike
   they're sure was logged but can't locate — and to find it the Fool must read back through
   the log rather than skip to it. Nobody in three hundred years has read it straight through;
   it was only ever kept, never read.
3. **The turn.** Read in sequence, the numbers do something the keeper never intended. The
   same strike, the same bell, the same nothing-changes, entry after entry after entry — and
   somewhere in the sheer accumulation it becomes a record of *waiting itself*, dry as a
   ledger and aching as a hymn. The Fool is the first ever to feel it.
4. **The missing entry.** The lost strike turns up — misfiled, not missing — a small honest
   payoff for the reading-through. Finding it is the errand; reading the rest is the quest.
5. **The ache and the laugh.** It lands on the keeper harder than either expected: to have
   the count *seen*, once, by someone who read all of it, retroactively makes three hundred
   years of pointless tallying into three hundred years of a thing worth doing. The keeper
   is mortified to be caught being moved by it, and covers with a very dry joke about the
   ink budget.
6. **Closing beat.** The keeper keeps counting — nothing about the duty changes — but keeps
   it a little differently now, aware for the first time that a record is only ever kept for
   the day someone reads it.
   - `[If WS_TOWER_UNBOUND: the log finally has a last entry — the strike that never finished`
     `striking, finished. The keeper shows the Fool the final line, closes the ledger, and`
     `doesn't yet know what a bell-watch counts once the bell has nothing left to catch.]`

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (log read through) | none — NPC-level only | The keeper's barks warm slightly; the completed strike-log becomes a readable Almanack lore entry. No `WS_*` flag is set. |

## Consistency references

- `world.md` §The Spire — the lightning-struck tower, the "lightning bell" warning system
  (per MQ16 beat 2); §World-state matrix (`WS_TOWER_UNBOUND`, closing variant only).
- `characters.md` §Regional named NPCs — the junior bell-watch keeper (proposed, unnamed) is
  the design brief; kept distinct from Harrow Brock (SQ-SPIRE-02) and Sorrel Vance (MQ16).
- `callings.md` §The Callings — Bell-watch ("watch the lightning bell; log strikes"), the
  role the keeper embodies.
- `narrative.md` §Theme 1 (endings are a mercy — the log yearns for the strike to finish);
  §Dialogue style guide (one laugh in the sad scene: the ink-budget deflection).

## Open questions

- Should the strike-log be a real, readable in-Almanack document (a genuine "poem in
  numbers" the player can scroll), or evoked in the keeper's dialogue only? The former is a
  small content cost with an outsized payoff; recommend it if the Almanack lore pipeline
  supports long-form entries.
- Whether the keeper is left deliberately unnamed (the slate's framing) even after promotion
  to `characters.md`, or given a name at script status. Recommend keeping them unnamed — the
  anonymity is part of the quest's point.
