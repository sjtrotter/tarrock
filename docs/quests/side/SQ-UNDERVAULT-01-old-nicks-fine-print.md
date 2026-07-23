---
id: SQ-UNDERVAULT-01
title: Old Nick's Fine Print
type: side
status: outline
arcana: none
region: The Undervault
requires: []
fires: []
---

# SQ-UNDERVAULT-01 — Old Nick's Fine Print

## Introduction

A dry caper homed in the Undervault, played while the Devil still holds it. Gambler Fessy
Dunmore signed a bargain generations ago for a run of good luck and now wants desperately
out, certain there must be some buried loophole in Old Nick Lowry's contract. There is —
and that is the joke, and the horror: the terms were always in plain print, the out was
always there, and nobody, Fessy least of all, ever read the whole thing. The quest plays
Old Nick exactly per canon — scrupulously honest, plainly printed, the terror being that
he never once lies (`characters.md` §XV). This is a side quest, not an unbinding: the Fool
never fights the Devil here. They read.

## Beats

1. **The hook.** Fessy Dunmore (canon, `characters.md` §Regional named NPCs) corners the Fool,
   frantic to escape a contract he signed lifetimes ago. He is sure Old Nick cheated him
   somewhere in the small print and wants the Fool to help him find where.
2. **The premise (and the joke).** Old Nick's contracts are honest to the letter. There
   is an out — a plain termination clause on plain conditions — and it has been sitting in
   the document, in ordinary readable print, the entire time. The chain's door was never
   locked; nobody opened the paper to check.
3. **The retrieval.** The contract is on file at the vault, weighed and ledgered with
   everything else the Undervault keeps. Getting it means a light errand through the
   pit's gilded tiers — and then the real task: actually reading the thing, dense and dry
   and long, a mirror-script and undersized-print nod to MQ15's fine-print puzzle (cited,
   not reused).
4. **Asking the Devil.** The Fool can go straight to the desk and ask. Old Nick will tell
   the truth — cheerfully, respectfully — because lying is not in him; the print is
   already honest and he sees no reason to hide it. He simply will not read it *for*
   anyone: "Everything a soul needs is in the print. Reading was never a service I was
   hired to provide." (Bound-Arcanum rule: he answers to the "Old Nick Lowry" the
   residents use as an epithet, but never says the personal name of himself, first
   person — that beat belongs to MQ15.) Pip growls, once, and settles.
5. **The find.** The loophole is gloriously mundane — a standard clause Fessy could have
   exercised any decade, on conditions he could always have met (a notice period; the
   surrender of the specific winnings the luck bought). The grand escape is paperwork he
   never opened. Honesty was the only lock on the cage.
6. **The out.** Fessy invokes the clause; Old Nick honors it without a flicker of rancour
   — a valid clause is valid, and an honest devil keeps his word in both directions.
   Fessy walks free, absurdly deflated that his epic liberation was a form he'd never
   turned past the first page.
7. **The honest beat.** Fessy admits, quietly, that he never read it because part of him
   never wanted out — the luck was *comfortable*, and comfort is the whole argument of
   the Undervault. He reads it now because he finally means to leave. The Fool can be
   earnest or dry — "Did you ever read it yourself?" / "The frightening part's the
   spelling." (≤12 words, one earnest option).

**[If WS_DEVIL_UNBOUND: …]** — If the Fool has already unbound the Devil, Fessy's chain
has physically fallen and the contract is void — yet Fessy is one of those who lingered
by his open chain, unsure. The quest becomes about the same choice with the paperwork
already gone: freedom was never the lock, and reading the clause becomes the ritual of a
man finally deciding, on purpose, to climb out. (See Open questions on offerability.)

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest resolved (either state) | none — NPC-level only | Fessy leaves the Undervault (or commits to leaving, post-unbinding); his barks and location change; no `WS_*` flag is set and no other quest reads this outcome. |

## Consistency references

- `characters.md` §XV. The Devil — Old Nick Lowry ("a contract-keeper who never lies,
  because the terms were always in plain print, and that is the whole horror of him");
  §The Fool (never sarcastic by default; earnest option never cut) and the bound-Arcanum
  "never says 'I' with a personal name" rule (`narrative.md` §The 21 Arcana / §Dialogue).
- `quests/main/MQ15-terms-and-conditions.md` §Beats 4, 6, 11 — the fine-print puzzle and
  Old Nick's honest-negotiation register this quest echoes without unbinding him; the
  personal-name beat is reserved to MQ15.
- `world.md` §The Undervault ("every resident signed for their chains… will tell you
  they're very happy"); §World-state matrix (`WS_DEVIL_UNBOUND`: chains fall, some linger).
- `narrative.md` §Themes 4 (the Fool is nobody — a stranger can read the paper an insider
  never would); §Dialogue style guide (Fool's ≤12-word rule; humor from situation, not
  winking; melancholy rule — the honest beat under the caper).
- `progression.md` §Renown / Currency (a shrewd reading of a contract as a Coins-culture
  virtue).

## Open questions

- This quest is written pre-unbinding with a post-`WS_DEVIL_UNBOUND` branch. Decide whether
  it stays offerable after unbinding (recommend: yes, reframed per the branch, since it
  reinforces "freedom isn't wanted by everyone") or auto-closes with the chains.
- Reward: recommend coins from a grateful Fessy plus a slight Coins Renown for the reading,
  per `progression.md`. Confirm — and confirm it does *not* stray into gear/Trump territory.
- Line audit: verify at script stage that no Old Nick line has him assert his personal name
  first-person before MQ15 (the residents' epithet "Old Nick" is fine; his self-naming is
  not).
