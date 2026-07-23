---
id: MQ13
title: An Ending
type: main
status: outline
arcana: XIII. Death
region: The Stillmarsh
requires: []
fires: [WS_DEATH_UNBOUND]
---

# MQ13 — An Ending

## Introduction

The player has heard the Stillmarsh mentioned, uneasily, in every region behind them —
the one place nobody quite wants to talk about. Arriving changes the whole shape of the
game: for the first time, nobody here treats the Fool as a stranger with no category.
The Stillmarsh knows exactly what the Fool's arrival means, and Mortimer — the kindest
person in the world, and the only Arcanum who has ever asked to be fought — is waiting
to welcome them like an old friend, not to bar their way. What follows is the purest
duel in the game, a confession the Querent can no longer dodge, and the single largest
change the world will ever undergo.

## Beats

1. Arrival at the Stillmarsh: candle-flat wetlands, ferry lanterns burning low over
   still water, a hush unlike anywhere else in the Spread.
2. Old Sallow poles the ferry across without asking for coin — he has been "nearly done
   dying" for three hundred years and treats the crossing like an old joke he's still
   fond of.
3. The Stillmarsh receives the Fool differently than any other region: no wariness, no
   curiosity at a stranger with no box to fit in. Here, they know. NPCs bow — not to
   the Fool, but to Pip, on sight, instinctive and unexplained, as they always have.
4. The Fool meets Mortimer directly, at the region's heart, before any gauntlet — warm,
   unhurried, delighted, welcoming the Fool like family arriving late for supper. Ally-
   coded from the first line, not an obstacle to be earned past.
5. Approach step: a vigil-house scene — several of the Stillmarsh's "dying," patient and
   kind about their three-century wait, occasionally very funny about it. Real warmth,
   real dread, one honest laugh, per the tone bar.
6. Approach step: the Fool takes over a small ferryman's duty — carrying a lantern to a
   bedside, sitting with someone briefly — so Mortimer can rest his feet for longer than
   he'll admit he's needed to.
7. Approach step: the Fool meets Bettony Marsh (canon, `characters.md` §Regional named NPCs), keeping a years-long vigil
   over her grandfather, Gaffer Corlin (canon, `characters.md` §Regional named NPCs) — deathless, bedridden, and utterly
   unable to let go. This is planted here so the aftermath lands with real weight.
8. Mortimer states plainly, unasked, that he wants this fight: "anything less would be
   disrespect to the office." He is the only Arcanum in the game who asks for his own
   unbinding outright.
9. The arena: a ring of candles on the Stillmarsh's flattest shore. No adds. No arena
   gimmick. No trick at all — he lays the scythe across his knees and waits for the Fool
   to be ready, on the Fool's own time.
10. Phase one begins: the pure duel, exactly per `arcana.md` §XIII — total sincerity,
    the hardest test of the base combat system in the entire game, by design.
11. Between phases, he lowers the scythe. The canonical confession: he tells the Fool
    plainly what the final card is, what completing the journey means, and that he will
    not pretend otherwise — closing, kindly, scythe at rest: *"You are the ending,
    little Excuse. I am only the door."*
12. In the same breath, the Querent — playful and evasive in every quest until now —
    stops pretending too, confirming the twist to the Fool directly and without a joke,
    for the first time in the game. The Fool answers with a short dialogue choice
    (≤12 words per line, one earnest option per the Fool's voice rule): this is the game's
    clearest moment of choosing to keep walking with full knowledge, not out of trickery.
13. Phase two: the duel resumes, harder and cleaner, both fighters now fighting with
    everything named and nothing left unsaid — the game's purest fight, played twice
    over, the second time with no illusions left standing on either side.
14. Mortimer falls. Every soul in the Stillmarsh has called him "Mortimer" for three
    hundred years, but he has never once said it of himself, first person, until this
    moment. He does, quietly amazed by the sound of it, and hands the Fool Trump XIII —
    Passage — with both hands, asking, entirely sincerely, only one thing: don't waste
    it.
15. Aftermath, day one: mortality returns instantly for those who are ready. The vigil-
    houses begin, quietly and without spectacle, to empty.
16. Aftermath, over the following in-game days: the Stillmarsh empties further; the
    world's first funerals appear as ambient events, modest and communal rather than
    grim; seasons begin cycling for the first time in three hundred years.
17. The mourning beat: days later, Gaffer Corlin dies gently in his sleep. Bettony Marsh
    holds two things at once, and the game refuses to resolve them into one — relief
    that his three-century wait is finally over, and grief that it is actually, truly
    over. He leaves her a note, found after: *"Took you all long enough."* It breaks her
    heart open in the good way, not the bad one — the tone bar's laugh, delivered
    posthumously.
18. Closing beat — Old Sallow, the quest's last word: his ferry runs the same lanes, but
    the crossing means something different now that the far shore is a place people
    actually reach. Wry, warm, unhurried: he's spent three centuries being nearly done
    dying, and he's rather looking forward, now, to actually managing it. "No rush,
    mind. I've waited this long."

## Key NPCs

- **Mortimer** (Death, canon, `characters.md` §XIII) — ally-coded from the first
  meeting; the only Arcanum who asks to be fought; the game's keystone confession.
- **Old Sallow** (canon, `characters.md` §Recurring named NPCs) — the Stillmarsh's
  ferry-keeper, "nearly done dying" for three centuries; gets the quest's final beat.
- **Bettony Marsh** (canon, `characters.md` §Regional named NPCs) — this
  quest's mourning NPC, keeping vigil over a deathless grandfather.
- **Gaffer Corlin** (canon, `characters.md` §Regional named NPCs) —
  Bettony's grandfather, deathless and bedridden for three centuries; his death is the
  game's first concrete demonstration of `WS_DEATH_UNBOUND`'s weight.

## Choices & branches

- No hard branch; `fires` is unconditional. The dialogue choice in beat 12 is flavor
  only (per the Fool's ≤12-word, one-earnest-option rule) — it colors the Querent
  exchange but does not gate the fight or the unbinding.

## Mourning

**Bettony Marsh** mourns the unbinding in the game's deepest register: her deathless
grandfather's three-century wait finally ends, days after the quest concludes, and she
is left holding relief and grief at once, refused a resolution into either one alone.

## Note on CONFESSED

This quest does not carry `[If CONFESSED]` variants of its own — it is the origin of
the global `CONFESSED` state (`world.md` §Global states: condition "MQ13 complete").
Every main quest from MQ02 onward carries variants that assume *this* quest as their
source material; this file is what they are reacting to, not a reaction itself.

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion | `WS_DEATH_UNBOUND` | Mortality returns; seasons begin cycling; NPCs can die (scripted only, no systemic aging sim); the Stillmarsh empties over days; funerals appear as ambient events; the Hollows unlock (`MQ20` gate). Also sets the global `CONFESSED` state (`world.md` §Global states), activating post-confession dialogue variants world-wide. |

## Consistency references

- `arcana.md` §XIII. Death (KEYSTONE) — pure-duel design, no-adds/no-gimmick rule, the
  canonical confession and its exact line, Trump XIII.
- `world.md` §The Stillmarsh, §World-state matrix (`WS_DEATH_UNBOUND`), §Global states
  (`CONFESSED`, `ACT_II` Querent steering).
- `characters.md` §XIII. Death (Mortimer); §Recurring named NPCs (Old Sallow, "nearly
  done dying").
- `narrative.md` §Premise, §The Twist, §The Querent (the confession scene is explicitly
  the point the Querent "stops pretending too"), §Act structure (Act I seed: "Death's
  region is visibly the place the whole world refuses to mention"; Act II keystone),
  §Themes (all four — this quest is the game's fullest expression of all of them),
  §Dialogue style guide (Fool's ≤12-word/earnest-option rule; Querent's one-wink rule).
- `GLOSSARY.md` — Mortimer is one of the four Arcana already named prior to unbinding
  (design reference only; his own dialogue withholds the personal "I" until beat 14).

## Open questions

- The exact wording of the Fool's dialogue-choice response in beat 12 needs script-
  stage drafting against the ≤12-word/earnest-option rule — this outline only sketches
  that the beat exists and what it accomplishes.
- Whether the Querent's one allowed wink for this quest is spent earlier (e.g., the
  ferry crossing) or withheld entirely given the confession's gravity — this outline
  recommends withholding it, but flags the call for narrative review.
- Should Gaffer Corlin's death (beat 17) be scripted to a fixed number of in-game days,
  or triggered on the player's next visit to the Stillmarsh? Affects whether it needs a
  hard trigger or can run as a pure ambient/ambush-free scene.
- Confirm Gaffer Corlin is a special-cased named-NPC death (recommended, for narrative
  weight) rather than an instance of the general "NPCs can die (scripted only)" system
  described in `world.md` — the distinction matters for how `technical.md` schedules it.
