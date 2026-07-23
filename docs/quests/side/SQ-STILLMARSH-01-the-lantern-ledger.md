---
id: SQ-STILLMARSH-01
title: The Lantern Ledger
type: side
status: outline
arcana: none
region: The Stillmarsh
requires: []
fires: []
---

# SQ-STILLMARSH-01 — The Lantern Ledger

## Introduction

A small errand of remembrance, homed at the Stillmarsh's ferry landing and built to
show the region at its truest: kind, wary, and quietly determined that nobody who
waited here be forgotten. Old Sallow's newest ferryman's mate keeps a private book of
names — everyone who has ever waited at the landing without being able to pass — and one
of those names has gone missing from it. The quest is not a mystery so much as a favor,
the kind the Stillmarsh does for its own: the Fool helps put a name back where it
belongs. Taking up the Ferryman's-mate Calling (`callings.md`) is the natural doorway
in, but the quest stands on its own.

## Beats

1. **The hook.** Tarn Loach (canon, `characters.md` §Regional named NPCs), Old Sallow's
   young ferryman's mate, keeps a battered little book — the *lantern ledger* — in
   which he has written the name of every soul who ever waited at the landing and could
   not pass. Hundreds of names, kept for no purpose he can defend, "except that somebody
   ought to remember they were here." He bows to Pip on sight, instinctive and
   unexplained, the way everyone here does (`characters.md` §Pip).
2. **The trouble.** A waiting family's great-aunt is missing from the ledger. Everyone
   at the landing remembers her — but her name is nowhere in Tarn's book, and it has
   shaken him badly: if the one book that remembers them all has a hole in it, what was
   the point of keeping it? He is too proud and too near tears to ask outright; the Fool
   offers.
3. **The search.** Tarn is on his third ledger in three centuries — the earlier two,
   water-swollen and half-blind, are boxed under the ferry-house bench. The Fool
   cross-checks the old books against the lanterns still burning at the landing and asks
   the patient dead themselves, who are unhurried and helpful and occasionally very
   funny about being asked to recall their own names.
4. **The find (and the laugh).** The name was never lost, only misfiled — copied three
   books back under a nickname nobody thought to look up. Old Sallow, poling past,
   supplies it at once, dry as a bone: everyone called her that, and she loathed it, and
   said so daily for a hundred years. A small warm laugh in a solemn place — the tone bar
   kept.
5. **Restoration.** The name is written into the current ledger properly, both the given
   name and the hated nickname side by side, so she is remembered whole. Tarn steadies.
6. **Closing beat.** The point of the ledger comes clear: in a place where nothing ends,
   nothing is marked either — no graves, no last dates, no closing of any account. The
   book is the only proof these souls were ever here. It was never a record for the
   living. Tarn keeps writing.

**[If WS_DEATH_UNBOUND: …]** — If the Fool has already unbound Death, the landing has
emptied and the ledger has quietly become a memorial rather than a waiting-list. The
missing name matters *more*, not less: Tarn is now copying the whole book fair onto the
Hollows' new stones, and a name left out would be a name that waited three centuries and
still got no marker. He reads the recovered name aloud at the water's edge when it is
found — the first of his names to belong, at last, to someone who got to leave.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (either state) | none — NPC-level only | Tarn's greeting barks warm; the recovered name appears in the ledger prop; no `WS_*` flag is set and no other quest reads this outcome. |

## Consistency references

- `characters.md` §Recurring named NPCs (Old Sallow — wry, unhurried, "nearly done
  dying"); §Pip (Stillmarsh NPCs bow to Pip on sight, written as instinctive reverence,
  never spelled out).
- `world.md` §The Stillmarsh (candle-flat wetlands, ferry lanterns, "the world's kindest
  and wariest people"); §World-state matrix (`WS_DEATH_UNBOUND`: Stillmarsh empties over
  days, Hollows unlock).
- `callings.md` §The Callings — Ferryman's mate (pole Old Sallow's lantern route; post-
  MQ13 "the route means something else, Sallow says so") as the quest's doorway.
- `quests/main/MQ13-an-ending.md` §Beats — for Old Sallow's characterization and the
  Stillmarsh's reception of the Fool, which this quest must not contradict.
- `narrative.md` §Themes 1 (endings are a mercy); §Dialogue style guide (melancholy
  rule — the nickname laugh inside the solemn errand).

## Open questions

- Reward: a quiet honor rather than loot fits the tone. Recommend a small coin gift from
  the grateful family, or a cosmetic ferryman's-mate token, per `progression.md`; confirm
  which, or whether the deed is its own reward.
- Should the ledger become a persistent, readable Almanack lore object once completed, so
  the recovered name (and the whole book) can be revisited post-`WS_DEATH_UNBOUND`?
