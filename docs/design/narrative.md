# Narrative — SSOT

Owns: story, themes, act structure, the twist, endings, the Querent mystery, dialogue
style. Character detail lives in [`characters.md`](characters.md); per-boss story beats
live in [`arcana.md`](arcana.md); quest-level scripting lives in `../quests/`.

## Premise

The world is a tarot reading. Not metaphorically — the Great Reading is dealt age by age,
each Major Arcana taking its turn "in position" to give its age meaning, and when the
final card turns, the Shuffle comes: the world is gathered up and dealt anew. It has
happened countless times. Every deal, a world; every world, a journey; every journey, a
Fool.

Three hundred years ago, the Reading stalled one card from the end. The final card — The
World — was never turned. Since the Stall, the 21 Arcana have been locked in position,
and their virtues have calcified into tyrannies: the Sun cannot set, the Emperor's law
cannot amend, the Lovers cannot choose, and Death cannot end anything at all. The land
lives in a golden, airless *pause*.

The Fool wakes at the Cliff with a dog, a rose, a bindle, and a voice in their ear — the
Querent, the one the Reading is for. The task, as first presented: the Arcana are stuck,
so unbind them. Set the world moving again.

## The Twist

**The 21st Arcana is The World. Unbinding The World destroys it.**

This is not a late-game rug-pull; it is the game's gravity, planted from the first hour
and confirmed in the middle, so that Act III is played in full knowledge. The player
spends Act I liberating. Somewhere in Act II they do the arithmetic: every unbinding
restarts something by letting it *end* — sunsets end days, verdicts end trials, death
ends lives. The Reading itself is one unbinding from complete. Finishing the journey
means turning the final card. Turning the final card is the Shuffle. The Shuffle is the
end of the world.

The design intent: the player should keep going anyway — not tricked, but convinced.
Every region they've revived has already taught the argument: **a thing that cannot end
cannot live.** The frozen world isn't safe, it's dead and politely pretending otherwise.
The Fool is not the world's savior. The Fool is the world's *ending* — the kindest one
it could have asked for.

**The World's identity:** the previous Fool. Whoever completes the journey becomes The
World — the wreath-dancer at the Axis — and holds the world together until the next
Fool comes to relieve them. The Stall happened because for three hundred years, no Fool
came (why is the Querent mystery, below). The final fight is not a villain; it is an
exhausted predecessor who must be *earned past*, testing whether this Fool is strong
enough to carry what comes next.

## The Querent

The voice that guides the Fool. Warm, wry, evasive about specifics — the game's
narrator in the Fable tradition. What the Querent knows and when they lie is tracked
here and nowhere else:

- The Querent knows from the first line that the journey ends the world. Early guidance
  is honest but incomplete ("the cards are stuck, little Excuse; go turn them loose").
- Mid-game, once the player can't be talked out of the journey by the truth, the Querent
  confirms the twist rather than letting the player feel cheated by it (MQ13, Death's
  quest, is the canonical confession scene — Death refuses to pretend, and the Querent
  stops pretending too).
- **Who is the Querent?** Canon: the Querent is *the world itself* — the Spread, dimly
  aware, asking the question every querent asks: *how does my story end?* The Reading
  was always being dealt **for the world, about the world**. It has been waiting three
  hundred years for its answer, afraid of it, and finally asking anyway. The Stall
  happened because the world flinched — it saw the last card coming and refused to hear
  it, and no Fool could be dealt into a reading the querent had abandoned. The Fool
  exists because the world has, at last, found the courage to ask again.
- This is revealed only in the finale (MQ21), and only if the player has unbound all 21
  Arcana (true ending). Rush endings leave the Querent's identity an open question.

## Act structure

Acts are narrative *weather*, not gates — the world is open throughout. Acts advance by
count of Arcana unbound (thresholds owned by [`world.md`](world.md) §Global states).

### Act I — The Deal (0–6 unbound)
Tone: storybook adventure. The Fool discovers the Spread and the rules of stasis.
Unbindings feel purely joyous: the carnival ends, crops fruit, roads open. The Querent
is playful. Seeds planted: every region has one NPC who *mourns* the change (drafted in
each quest doc), and Death's region is visibly the place the whole world refuses to
mention.

### Act II — The Turning (7–14 unbound)
Tone: awake and uneasy. World-changes compound visibly (night + weather + seasons +
mortality interact). NPCs start asking where this is heading. MQ13 (Death, "An Ending")
is the act's keystone and may be done any time — but if the player reaches 14 unbindings
without it, the Querent steers them to the Stillmarsh (soft narrative pressure only).
After MQ13, all remaining quest scripts use their post-confession dialogue variants:
everyone knows what the Fool's journey is now, and treats them accordingly — some with
gratitude, some with terror. (Every main quest doc from MQ02 on carries both variants.)

### Act III — The Shuffle (15–21 unbound)
Tone: elegiac, tender, resolved. The world is more alive than it has been in three
centuries and everyone knows it is ending. Regions get "last days" content: festivals,
goodbyes, debts settled, the traveling troupe's final show. The approach to the Axis is
the emotional summit; the fight itself is the release.

## The Fool's Reading (order matters)

The game is modeling a real divinatory act, so the player's own sequence is sacred: the
order in which the Arcana are unbound is recorded, card by card, as **the Fool's
Reading** — a 21-card spread the player deals across their whole playthrough without
being told they are dealing it. It is displayed in the Almanack as cards laid left to
right in the order they were turned. (Runtime representation: `world.md` §Global
states; glossary: `GLOSSARY.md`.)

How the order is felt:

1. **The world comments on sequence.** Quest docs already carry `[If WS_…]` variants for
   order-dependent pairs (world.md's order-independence rule); on top of that, ambient
   bark pools may reference notable sequence facts ("the sun set on us before we ever
   had stars," "Death came to the carnival before the show even closed"). Canonical
   motif examples live in `world.md` §The Fool's Reading; quests add theirs locally.
2. **The true ending is styled by it.** In MQ21, on the True Shuffle path only, the
   Querent lays the player's 21 cards out in the order they were turned — *"your
   reading, little Excuse — you've been dealing it since the cliff"* — and reads three
   positions aloud:
   - **The first card turned** — *how the world woke*. Styles the ending's opening
     image and the dawn of the new deal.
   - **The eleventh card** (the middle) — *the heart of the journey*. Styles the
     Querent's reading of who this Fool was.
   - **The last card before The World** — *the world's final lesson*. Styles the tone
     of the gathering-up and the final farewell line.
3. **The Shuffle gathers in your order.** During the True Shuffle, regions fold closed
   in the order the player unbound them — the world ends in the order it woke.
4. **Rushed endings are unstyled**, deliberately. The Early Shuffle is a reading left
   incomplete — there is nothing to read, which is its own statement — and the
   Querent's identity likewise stays unrevealed there (§The Querent).

Design guardrail: the Reading *styles*; it never *branches* the endings into different
outcomes. There are three endings, not thousands — but no two True Shuffles read the
same.

## Endings

1. **The True Shuffle** (all 21 unbound, then MQ21): the Fool relieves the previous
   Fool, learns the Querent's identity, hears the Fool's Reading read back (§above),
   and turns the final card. The Shuffle plays out — not fire, but a gathering-up:
   regions fold closed **in the order the player unbound them**, each with a one-line
   farewell drawn from the player's choices. Final scene: a new deal, a new world, a
   new Fool at a cliff's edge — wearing one small detail the player will recognize
   from their journey, its opening dawn styled by the first card the player ever
   turned. The player's Fool is now The World; Pip is already waiting beside the new
   one.
2. **The Early Shuffle** (MQ21 attempted with 1–20 Arcana still bound): the final fight
   includes a phase per still-bound Arcana. Brutally hard by design; beating it earns a
   shorter, harsher ending — the Shuffle comes with the world still half-frozen, and the
   farewell montage shows what never got to wake. Legendary for challenge runners,
   melancholy on purpose.
3. **The Refusal** (at the final choice, walk away): the game continues; the world stays
   alive-but-mortal at whatever state it has reached. NPCs age. The Axis stays open.
   This is not a fail state — it is a genuine, playable "not yet," and the Querent
   respects it. The credits roll only on a Shuffle ending.

## Themes (writer's checklist)

Every quest should touch at least one; MQ quests should touch the first.

1. **Endings are a mercy.** The frozen world is the villain; no Arcana is.
2. **Offices eat people.** Every Arcana is a person calcified into a role; unbinding
   returns their name. (Watch for this in dialogue: bound Arcana never use "I" with a
   personal name; unbound ones do.)
3. **Freedom isn't wanted by everyone.** Every unbinding hurts someone ordinary. Show
   them. Don't resolve them.
4. **The Fool is nobody, and that is a power.** Doors open for the card that belongs
   nowhere.

## Dialogue style guide

- **Register:** storybook British — Fable's warmth, MediEvil's gallows-cheer. Contractions
  yes; modern slang no; anachronism only as deliberate comedy and sparingly.
- **The Fool is voiced by choice, not monologue** — dialogue trees per the quest template.
  The Fool's selectable lines stay short (≤ 12 words) and include one foolish/earnest
  option wherever possible; it is the character's soul.
- **Humor rule:** jokes come from character and situation, never from the game winking
  at the player. The one exception is the Querent, who is allowed exactly one wink per
  quest.
- **Melancholy rule:** every comic scene owns one honest beat; every sad scene owns one
  laugh. This is the Fable/MediEvil tone in one sentence.
- **Card language:** common folk swear and bless by the deck ("by the Deal," "gods turn
  your card," "he's a few pips short of a suit"). Build the lexicon in quest docs; add
  recurring coinages to the glossary.
