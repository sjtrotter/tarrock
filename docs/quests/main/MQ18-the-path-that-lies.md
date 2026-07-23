---
id: MQ18
title: The Path That Lies
type: main
status: script
arcana: XVIII. The Moon
region: The Mirrormarsh
requires: []          # HARD GATE (world.md §Hard and soft gates): the Mirrormarsh interior
                       # requires ANY true light — WS_HERMIT_UNBOUND (Lantern), WS_STAR_UNBOUND
                       # (Wish), or WS_SUN_UNBOUND (Daybreak). This is an any-of-three OR
                       # condition, not a single flag, and cannot be expressed in `requires`
                       # as written. Modeled as diegetic region-logic (the loop-out), not a
                       # flag gate. See Open questions.
fires: [WS_MOON_UNBOUND]
---

# MQ18 — The Path That Lies

## Introduction

The player comes to the Mirrormarsh and, for the first and only time in the game, Pip
will not follow. He balks at the fog-line — ears back, planted, the one fear he has ever
shown — and the quest is built around that refusal so completely that no other quest is
allowed to borrow it. The Mirrormarsh's interior is hard-gated on true light: unless the
player already carries one — the Hermit's Lantern (`WS_HERMIT_UNBOUND`), the Star's Wish
(`WS_STAR_UNBOUND`), or the Sun unbound (`WS_SUN_UNBOUND`) — the fog simply loops them back
to the border, the locked door written as geography instead of a wall. Whichever light the
player brings changes how the fog receives them, and the script carries three arrival
textures for it. With true light in hand, the player walks a marsh where the path itself
lies: signposts that disagree, a bridge that isn't there, faces wearing borrowed shapes.
Partway into the deepest fog, "Pip" trots up and confidently leads — and every player who
has learned Pip's rules feels the wrongness before the reveal, because the real Pip is
still at the border, and the real Pip never performs concern, never leads anxiously, never
hurries the Fool anywhere. It is not Pip. The fog leads to black glass water and the boss
the whole game has been quietly building toward: the Anti-Fool, the player's own reflection,
carrying the player's *exact current Pocket Spread* cast reversed — the favorite build,
turned honestly against them. At the fight's lowest point the real Pip's howl reaches
across the fog from outside the marsh, cracks the false-Pip's glamour and the black glass
both, and the Moon surfaces to be unbound: her office cracks, her name — **Luned** —
returns, and Trump XVIII, Glamour, is handed over still dripping, by something never quite
sure it was ever only one person. The fog lifts region-wide; the "monsters" were lost
people all along. If the player reaches the Mirrormarsh after MQ13 (Death, "An Ending"),
the marsh already knows what the Fool's coming means, and the key scenes carry their
`[If CONFESSED]` variants.

---

## QUEST: THE PATH THAT LIES

### EXT. THE MIRRORMARSH: The Fog-Line — DUSK (STATE-DEPENDENT)

THIRD PERSON GAMEPLAY

The last dry ground of the border settlement gives out onto a wall of fog that stands
where a horizon should be — not rolling, not drifting, just *there*, grey and upright and
patient. The rope-line runs along the safe edge of it, weathered posts and a hand-worn
guide-rope, the one honest handrail in a place that keeps none of its promises. Past the
rope the land refuses to hold still: a signpost's arms point three ways at a fork the eye
can't quite find twice, a lit window floats somewhere it has no house to belong to, and a
path that led left a moment ago now leads left in a different direction.

**[Environmental: no combat here. Approaching the rope-line triggers Pip's refusal below.
The fog-line is a hard visual boundary — everything past it reads as unreliable, on
purpose.]**

Pip, who has walked off the Cliff without looking down and sat unbothered through every
horror the Spread has offered, stops. Six feet short of the rope-line he stops, and will
not take the seventh step.

TRANSITION TO CUT SCENE

### CUT SCENE

Pip stands stiff-legged at the edge of the dry ground, ears flat, weight back on his
haunches. No bark. No fuss — Pip never fusses — but his whole small body has gone taut in
a way the Fool has never once seen it go. When the Fool moves toward the fog he does not
follow. He looks from the Fool to the fog and back, and holds exactly where he is, and the
holding is the loudest thing he has ever done.

**THE QUERENT** *(quiet, and for once not wry at all)*
> ...Ah. Here's the one, then. I wondered when we'd reach it.
>
> He's walked you into everything, that dog. Fire, flood, the end of the world at a
> carnival, and never a flicker. This is the single thing in all the Spread he's afraid
> of. Has been since before your grandmother's grandmother, I should think. He's not being
> stubborn, little Excuse. He's being honest. It cost him something to stop.

Pip's tail does not wag. He sits, finally — not the easy sit of a dog at rest, but the
braced sit of a dog who has decided he cannot go on and cannot bring himself to leave,
either. He watches the Fool with the frank misery of an animal who would follow anywhere
but here.

END CUT SCENE

### CHOICE DIALOG — Pip at the border *(all questions may be exhausted)*

| The Fool | The Querent's response |
|---|---|
| He's never once been afraid. | No. Not once, not of anything. That's rather what makes this worth paying attention to, wouldn't you say. |
| What could a dog know that I don't? | More than you, about some things. Less, about most. He knows *this*. I'd take the warning, in your place. |
| I won't drag him in. *(earnest)* | Good. Don't you dare. Whatever's past that rope, he's earned the right to sit it out. First time for everything. |
| Then I'll go alone. *(foolish/brave)* | Of course you will. You're a Fool; going alone into the obviously-wrong place is practically the job description. Mind the fog lies. |

[All versions pick up here:]

The Fool kneels a moment beside Pip. Pip leans his head into the Fool's hand — braced, not
comforted — and stays exactly where he is as the Fool straightens and turns toward the
rope-line alone.

### EXT. THE MIRRORMARSH: The Border, the Rope-Line — DUSK

THIRD PERSON GAMEPLAY

The fog-warden works the near end of the rope-line: NETTLE VANCE, weathered and unhurried,
coiling a length of guide-rope over one arm with the flat competence of someone who has
brought more lost people out of a fog than she can be bothered to count. She watches the
Fool leave the dog behind and says nothing about it for a moment — then everything about it.

**NETTLE VANCE Random Lines** *(repeatable greeting; pick one at random)*

> Dog's got the right of it, stopping there. Cleverer than most folk who reach that rope,
> and I've walked a great many folk back off it.

> You'll want to keep the rope in your hand or a light in your fist. Preferably both.
> Marsh lies about everything but the rope, and it's working on the rope.

> [If CONFESSED: Word came up the road ahead of you. The one who ends things. Well — the
> marsh ends things too, in its way, only it never lets on. You two ought to get along.]

TRANSITION TO CUT SCENE

### CUT SCENE

**NETTLE VANCE**
> Right. You're going in regardless — they always are — so you'll hear the warden's
> warning first, same as everyone. Marsh has monsters. Always has. They were here before
> me and they'll want feeding after.

**THE FOOL**
> Monsters made of what?

**NETTLE VANCE**
> Made of whoever went looking. That's the trick of the place. Folk come to the fog after
> a lost brother, a lost wife, a lost whoever — and some of them come back out. Not one of
> them comes back *better*. They come back quieter. Wearing their own face a little loose.
>
> [If CONFESSED: You'll know that shape by now, I'd wager. Coming back changed. You've been
> the reason for a fair bit of it, up and down the Spread. Difference is, you change a
> thing on purpose and you own it. The marsh changes you on the sly and calls it a rescue.]

END CUT SCENE

### CHOICE DIALOG — the warden's warning *(all questions may be exhausted; first light-question commits nothing)*

| The Fool | Nettle Vance's response |
|---|---|
| Why does light let me through? | Because the fog's whole living is deceit, and a true light doesn't argue with it — it just shows the real ground under the lie. Fog hates that. Won't stop it, but hates it. |
| Where does the fog lead? | Down. Everything in a marsh leads down, to the black water at the bottom of it. That's where whatever runs this place keeps house. |
| Have you gone to the bottom? | No. I walk the rope and I bring folk off it. I'm a warden, not a hero. The heroes are the quiet ones I fish out three days later. |
| I'll bring your lost ones home. *(earnest)* | ...Aye. You might, at that. Nobody's had the light *and* the nerve at once before. Go careful. And Fool — the dog stays with me. I'll not have him near it. |

[All versions pick up here:]

Nettle presses the end of a spare guide-rope into the Fool's hand out of pure habit,
then takes it back, because past the fog-line the rope is one more thing that lies.

**NETTLE VANCE**
> No. Rope's no good to you in the deep. Light's your rope in there. Keep it up and keep it
> honest and you'll keep yourself.

### EXT. THE MIRRORMARSH: The Border Waystation — DUSK

THIRD PERSON GAMEPLAY

A low wayside shrine stands on the last patch of dry ground, half-drowned in reed and
mist — the Mirrormarsh's Waystation, and the final honest rest before the fog. The White
Rose stirs near the basin, petals unfolding.

**[Tutorial prompt: rest at the Waystation. The Rose regrows to full; the player may
reslot the Pocket Spread here. Design note surfaced diegetically — nothing else: whatever
the player slots at this Waystation is the spread the Anti-Fool will mirror, reversed.]**

Pip lies down beside the Waystation basin, chin on his paws, keeping the border and
refusing the fog in the same steady look.

**THE QUERENT Random Lines** *(if the player rests again)*

> Last dry stone before the lie. Set your cards how you like them — you'll be meeting
> them again sooner than you'd guess.

> He'll wait right here. He always waits. Waiting's the one thing that dog does better
> than anyone in the Spread.

> [If CONFESSED: Rest while it's honest ground. The fog doesn't care what you've confessed
> to. The fog cares what you're afraid of, and it's about to go looking.]

### EXT. THE MIRRORMARSH: The Fog-Line, Crossing — NIGHT (STATE-DEPENDENT)

THIRD PERSON GAMEPLAY

The Fool steps past the rope-line into the fog.

**[GATE CHECK — no true light carried:]** The world greys out to arm's length. The Fool
walks a path that feels straight, turns once at a lit window, turns again at a leaning
signpost — and comes out at the rope-line, facing Nettle and the dog, exactly where they
started. No message box. No "you need X." The region simply will not resolve into anywhere.
Try again and it loops again, the geometry politely refusing, until the player leaves to
fetch a true light. Nettle, each loop, says only:

> **NETTLE VANCE** *(gate-loop bark)*
> Back already. You've no light, is why. Fog'll do that all night — it's not toying with
> you, it just hasn't decided you're real yet. Come back with a lantern, a wish, or the
> sun on your shoulders.

**[GATE CHECK — true light carried:]** The fog does not part so much as *admit* the Fool.
A real path resolves underfoot, wet and dark and singular, and holds.

[The arrival texture depends on which true light the Fool carries. If more than one is
held, daylight dominates, then the Wish, then the Lantern — brightest wins:]

**[If WS_SUN_UNBOUND (the Sun unbound — daylight):]** The fog thins from above, shallowed
by an open sky it cannot roof over. This is the least eerie way in: the marsh lies flatly,
almost ordinarily, its tricks reduced to daylit sleight-of-hand a careful eye can catch.
The horror here is that it looks so nearly like anywhere.

**[If WS_STAR_UNBOUND (the Star's Wish — guiding glow):]** A soft wish-light drifts ahead
of the Fool like a lure — but this lure, for once, does not lie. It picks out the true path
in gentle silver, and the fog closes warm and close behind it, and the marsh feels less
crossed than *permitted*, which is somehow worse.

**[If WS_HERMIT_UNBOUND (the Hermit's Lantern — held light):]** The Lantern cuts a narrow
corridor of true ground, no wider than its own reach. The Fool sees only what the light
touches and must carry the honest yard of it forward step by step, everything past the
edge of the glow left to the fog. The most intimate arrival, and the most frightening: the
lie waits exactly one pace out, all the way in.

**THE QUERENT**
> There. Now the ground means what it says — as far as your light says it, and no further.
> Keep it lit. The moment you doubt it, this place has you.

### EXT. THE MIRRORMARSH: The Lying Path — NIGHT

THIRD PERSON GAMEPLAY

The first true traversal. Two signposts contradict each other across a single fork; a
third, further on, contradicts them both. A boardwalk bridge crosses a channel of still
black water, planks solid to the eye — and the true light, swept across it, shows the
boards for painted fog with nothing under them but a long drop into the marsh.

**[Tutorial prompt: raise true light across suspect ground to reveal the real route
beneath the false one. Where a path lies, the light shows the honest ground a stride off
to the side.]**

**[Tutorial prompt: call Pip's Seek to point the fog-hidden path — then remember the wheel
is greyed out. Pip is not here. The command does not answer. This is intended: the one
place in the game the Seek prompt appears and cannot be used.]**

The Fool's own hand tries for the dog that isn't there. The command-wheel ghosts up and
falls dark.

**THE QUERENT** *(gently)*
> He'd have found the real plank in a heartbeat, wouldn't he. Funny, the things you only
> notice by their absence. You're on your own eyes now, little Excuse. Trust the light,
> not the boards.

The real route runs a hand's breadth beside every lie — always the less inviting way, the
narrow reed-shelf beside the handsome bridge, the low mud beneath the floating lamp. Where
the Fool follows the light instead of the path, the ground holds. Where the Fool trusts the
path, it opens under them into cold water and puts them back a stretch, wet and no worse —
the marsh does not kill; it only unmakes your certainty.

### EXT. THE MIRRORMARSH: The Deep Reeds — NIGHT

THIRD PERSON GAMEPLAY

Shapes stand in the reeds ahead: human-sized, human-shaped, wearing faces. Not blank ovals
like the Blanks — *faces*, borrowed and ill-fitting, a stranger's kind eyes worn a size too
loose, a lost brother's smile hung on wrong. They do not rush. They drift, and turn their
borrowed faces toward the Fool, and mean harm in the slow patient way of a thing that has
all the time there is.

**[GAMEPLAY — the fog-masks: the region's "monsters," encountered as genuine threats before
the reveal. Shaped by dread, not gore. They ambush from mimicry — standing as a signpost, a
waiting traveler, a second copy of the Fool — and gain a first-strike bonus that a raised
true light strips away (the light shows the borrowed face for what it is a beat before it
moves). Fight them as unsettling, sorrowful enemies; they read as wrong, never as gross.
Post-`WS_MOON_UNBOUND`, illusion-type enemies lose this ambush bonus world-wide.]**

**THE QUERENT** *(low)*
> Don't look too long at the faces. Nettle's monsters, these — and Nettle's right about
> what they're made of, though I'd not say so where they can hear. Put them down gently as
> you can. You'll understand why by morning, and you'll wish you'd been gentler.

The fog-masks fall without cards, without confetti, without the tidy reassembly of a
Blank — they simply sink back into the fog they were wearing, faces last, and the reeds go
quiet, and something about the quiet is worse than the fight was.

### EXT. THE MIRRORMARSH: The Deepening Fog — NIGHT

THIRD PERSON GAMEPLAY

The path narrows and darkens and leads, always, down. The black water shows more often
between the reeds now, flat as poured glass. The true light holds its honest yard. And then,
from a bank of fog to the Fool's left, small and white and utterly familiar —

Pip trots out.

**[GAMEPLAY — the false-Pip beat. This beat belongs to MQ18 exclusively (characters.md
§Pip's protection rule); no UI element ever labels it. "Pip" appears perfect — the right
size, the right scrappy white, the right ragged ear — and begins to *lead*, trotting ahead
along a path the true light does NOT confirm, looking back over his shoulder to check the
Fool is following, whining softly when the Fool slows, hurrying them on with an anxious,
eager, please-follow-me energy. Every one of these is a tell drawn from Pip's canon, and
none is spoken aloud:]**

- The real Pip is at the border, and could not be made to cross it. This one crossed
  gladly.
- The real Pip never performs concern. This one performs nothing else — all worry, all
  fuss, all look-at-me.
- The real Pip waits to be needed; he does not lead the Fool anxiously into an unknown.
  This one leads, and hurries, and needs *you* to come.
- The real Pip's tail gives one polite thump. This one's tail never stops — too much, too
  eager, wagging to be believed.

**THE QUERENT** *(and something in the voice has gone careful)*
> ...There's the dog. Isn't that a relief.
>
> [If CONFESSED: No. No, that isn't right, and you know it isn't, and by now you know
> better than most what it costs when a thing puts on warmth it never earned. Look at it.
> *Look* at how much it wants you to be comforted.]
>
> [Else: Only — he stopped at the border, didn't he. He wouldn't cross it for you or for
> anything. So who's this, trotting so bravely into the one place he's afraid of, so very
> keen for you to come along.]

### CHOICE DIALOG — the dog in the fog *(all questions may be exhausted; the false-Pip cannot answer — it only fusses)*

| The Fool | Result |
|---|---|
| Pip? Is that you? | "Pip" wags harder, whines, circles back to hurry the Fool on. It does not come to heel. It only leads. |
| You don't wait. He always waits. | "Pip" pauses — a half-second too long, an animal listening for a cue it doesn't have — then resumes leading as if the words were wind. |
| Good dog. Show me the way. *(foolish/trusting)* | "Pip" brightens with a relief no real dog performs, and hurries ahead toward the black water, delighted to be believed. |
| I'll follow. But I know you're not him. *(earnest)* | "Pip" does not react at all. It cannot. It only leads, because leading you down is the whole of what it is for. |

[All versions pick up here — the Fool follows the false-Pip toward the black glass water,
whether trusting or knowing:]

TRANSITION TO CUT SCENE

### CUT SCENE

The false-Pip trots ahead onto a spit of mud that reaches into the black water — and, for
a moment, forgets to be a dog. Its edges smear. The white coat unravels a thread into grey
fog and knits back. The ragged ear runs like a candle and re-forms. It is not violent and
it is not loud; it is the quiet horror of a beloved shape admitting, for one held breath,
that it is only fog wearing a memory. Then it is Pip again — perfectly, brightly Pip — and
it turns its borrowed face to the Fool and leads on, entirely unbothered that it has been
seen, because it was never trying to fool the Fool. It was only trying to bring the Fool
here.

**THE QUERENT**
> There. Now you've seen it. It doesn't even mind being caught — it got what it wanted the
> moment you followed. That's the marsh's whole art, little Excuse. It didn't need you
> fooled. It needed you *here*.

END CUT SCENE

### EXT. THE MIRRORMARSH: The Black Glass Water — NIGHT

THIRD PERSON GAMEPLAY

The reeds fall away. The Fool stands at the edge of a flat black mere, still as poured
glass, and above it — the only thing the fog will not veil — hangs the Moon, fixed, full,
three hundred years risen and never once setting. The false-Pip trots to the water's edge,
sits, and looks up at its own maker with the blank devotion of a reflection. Then it comes
apart, unhurried, back into the fog it borrowed, its work done.

The black glass is perfectly, terribly still. It shows the Moon. It shows the Fool. And
then the Fool's reflection stands up out of the water.

TRANSITION TO CUT SCENE

### CUT SCENE

It rises dripping, and it is the Fool exactly — the same face the player built, the same
Bindle, the same White Rose, held the same way. Only the light is wrong: where the Fool
carries true light, the reflection carries its reverse, a light that darkens what it touches.
It says nothing, because it has nothing of its own to say. It only lifts the Bindle in the
Fool's own grip, and waits, and the fog holds its breath.

**THE QUERENT**
> Ah. And here's what the whole marsh has been walking you toward. Not a monster. Not a
> stranger. *You* — every card you chose to carry, every trick you leaned on, turned round
> the wrong way and handed to something that fights exactly as well as you do, because it
> is exactly as good as you are.
>
> This one's between you and you, little Excuse. I'll not take sides — least of all against
> whoever's had the wheel this whole long journey. You know your own tricks better than
> anyone watching does. Go on. Beat yourself.

END CUT SCENE

**[GAMEPLAY — the Anti-Fool (arcana.md §XVIII). A build-check mirror fight. The Anti-Fool
carries the player's EXACT current Pocket Spread — whatever three Trumps, whichever slots,
however oriented, as slotted at the border Waystation — and casts them all REVERSED. The
reversed burdens the player usually pays become the Anti-Fool's whole kit: the favorite
Present power, the trusted passive, the reactive the player relies on, each turned against
them at its darker weight. The fight is self-balancing by design — it is the player's own
loadout, so it is exactly as hard as the player made it, and it playtests their favorite
build against them (arcana.md §Cross-Trump synergy notes). Poignant edge, flagged as a
tension below: if the player's slotted true-light Trump (Lantern/Wish/Daybreak) is part of
the mirrored spread, the Anti-Fool casts even the light that got the Fool in — reversed,
into deception. Bring the right spread, or fight your favorite one honestly.]**

The Anti-Fool fights in perfect silence and perfect symmetry — the Fool's own timing, the
Fool's own openings, the Fool's own favorite feint answered a half-beat before it lands. It
does not gloat. It does not tire. It is the honest measure of everything the player has
become, and it will not go down until the player out-fights the person they have spent the
whole game turning into.

### EXT. THE MIRRORMARSH: The Black Glass Water, the Climax — NIGHT

**[GAMEPLAY — the fight's lowest point: the Anti-Fool has the Fool pressed, the true light
guttering, the black glass reflecting two identical figures with no way left to tell the
honest one. This is the beat the climax fires on.]**

CUT SCENE — INTERCUT: THE BORDER / THE BLACK WATER

At the rope-line, on the last dry ground, the small white dog who could not cross lifts his
head.

Pip has sat the whole quest facing a fog he is afraid of, refusing it, waiting. Now — with
the Fool at the far black bottom of the thing, further than any sound should carry — Pip
throws his head back and *howls*. One long note, whole and unafraid, from a dog who never
once made a sound at this border until the Fool needed him to. It is the only thing all
night that crosses the fog honestly. It is the bravest thing he has ever done, and he does
it from outside, because outside is exactly as far as he will ever go — and it is enough.

The howl reaches the black water like a struck bell.

The Anti-Fool's silence breaks — not into speech, into *reflection*: for one instant it is
not the Fool at all but only the Moon's glamour wearing the Fool's shape, the same lie the
false-Pip wore, seen at last for borrowed fog. The black glass spiders across, corner to
corner, a long clean crack running the whole still surface. The reflection cannot hold a
shape the glass can no longer keep.

**THE QUERENT**
> *There* he is. Told you he'd find a way to be needed — and only ever from where he could
> reach. Now. While the glass is broken and the lie can't set. *Finish it.*

END CUT SCENE

**[GAMEPLAY — the crack opens the window: the Anti-Fool can no longer perfectly mirror,
its reversed casts destabilizing as the glamour fails. The player lands the finishing
exchange against their own dissolving reflection.]**

### EXT. THE MIRRORMARSH: The Broken Glass — NIGHT

CUT SCENE

The Anti-Fool comes apart the way the false-Pip did — no violence, no body, no death — just
a borrowed shape releasing the Fool's face back to the Fool and sinking, grey, into the
cracked black water. And the water, cracked, no longer holds still. It ripples. It has not
rippled in three hundred years.

Something surfaces in it. Not a reflection this time. From the broken glass rises the Moon's
true shape — pale, shifting, hard to hold in the eye, a face that is several faces settling
uneasily toward being one. The fixed Moon above and the shape in the water dim together, the
long glamour guttering like a blown lamp, and the office that has ruled the Mirrormarsh for
three centuries cracks down its length like ice going off a pond.

**THE MOON** *(the bound voice — plural, unplaceable, never a name)*
> ...who is asking. We show every shape but our own. We have shown so many. We have almost
> forgotten which of them we were keeping the fog for—

The cracking reaches something under the office. A name, surfacing the way the water
surfaces, the way a held breath finally lets go.

**THE MOON**
> ...*Luned.*

She says it uncertainly, testing it — the way you test ground the marsh has lied about
before, half-sure it will give.

**LUNED**
> Luned. That was — that was one of us. The first of us, perhaps. Or the one the rest were
> built to hide. I truly could not tell you, and I have never in three hundred years been
> able to say *I* and mean only the one thing. ...There. I said it. It held.

END CUT SCENE

### CHOICE DIALOG — the Moon, unbound *(all questions may be exhausted; every answer is, deliberately, only nearly true)*

| The Fool | Luned's response |
|---|---|
| Were you ever one person? | I don't know. Isn't that a mercy — to finally not know, instead of pretending I did. Ask the fog. Oh. It's lifting. Ask it quick. |
| Why wear Pip's shape? | Because it was the shape you'd follow past your own good sense. The marsh never lies at random. It lies with whatever you love. I'm sorry. Mostly. |
| The monsters — who are they? | Look and see. I hid them so long even I lost their faces. You're about to give them back. I'm not sure they'll thank us. |
| I'm glad you said your name. *(earnest)* | ...So am I. As glad as a thing can be that still can't swear it's only one thing. Keep the doubt, Fool. The certain ones are the ones who freeze. |

[All versions pick up here:]

Luned lifts a card from the broken water — no flourish, no sleight, just an open hand,
which from the Moon is its own small miracle — and it comes up dripping, the paint beaded
and running and re-forming as she holds it out.

**LUNED**
> Trump the Eighteenth. Glamour, if it's ever written down — and who'd trust the Moon to
> write it true. Take it. It sees through mimics and false walls and borrowed faces now,
> instead of making them. Turned the right way round, it's just... honesty, wearing a
> disguise it's finally allowed to drop.

**[The Fool receives Trump XVIII (Glamour). Its slots and reversed burden are owned by
arcana.md §XVIII — Past: see through mimics and fog-masks; Present: become illusion,
enemies lose you; Future: dodge swaps you with an illusory copy. Reversed burden: the lie
deepens, doubled and doubly costly, and while you are a lie, Pip cannot find you.]**

### EXT. THE MIRRORMARSH: The Fog Lifting — DAWN

THIRD PERSON GAMEPLAY

The fog does not blow away. It *thins* — the way a lie thins when nobody's left keeping it
— and the Mirrormarsh resolves, for the first time in three hundred years, into simply a
marsh: reed-beds and dark honest water and a low grey dawn, unremarkable, real. Where the
fog-masks stood are people. Ordinary, blinking, hollow-cheeked people, wearing their own
faces now, loose no longer, looking at their own hands as if to check whose they are.

**[World change: `WS_MOON_UNBOUND`. Fog lifts region-wide; the "monsters" are revealed as
lost people; the border town un-curses; illusion-type enemies lose their ambush bonus
world-wide. The Mirrormarsh becomes navigable without true light. SQ-MIRRORMARSH-02 and
the post-MQ18 variants of SQ-MIRRORMARSH-01 and -03 open on this flag.]**

**THE QUERENT**
> Nettle's monsters. Every one of them somebody who came looking for somebody, and got
> kept. Look at them finding their own hands again. That's what was under the fog the
> whole while — not beasts. People, mislaid. The Moon wasn't hoarding horrors. She was
> hoarding the lost, and calling it protection, until she couldn't tell the difference
> either.

At the far edge of the clearing marsh, past the rope-line, a small white shape breaks from
the border and comes running.

CUT SCENE

Pip crosses the fog-line.

He comes across the ground he has feared his whole long life — the one border he would not
step over for the Fool or for anything — now that the thing in it is gone, and he does not
slow, and he does not look down, and he reaches the Fool at a dead run and presses his whole
scrappy self against the Fool's legs, tail going, once, twice, and then not stopping. The
first time Pip has ever entered the Mirrormarsh. The last fear he had, walked into on his
own four feet, the moment it was safe to.

**THE QUERENT** *(soft)*
> ...And there's the dog. In the marsh at last, on his own terms, not a step before he was
> good and ready. He never does look down first, that one. Neither, in the end, did you.

Pip and the Fool stand together in the thinning fog, in the place he was afraid of, which
is no longer a place to be afraid of, because the two of them are in it.

END CUT SCENE

### EXT. THE MIRRORMARSH: The Cleared Reeds — MORNING

THIRD PERSON GAMEPLAY

Among the found people, one sits apart on a reed-hummock, knees drawn up, watching the fog
go with an expression that is not relief. IVY ASHBY, hollow-cheeked and newly herself,
does not look up until the Fool is close.

**IVY ASHBY Random Lines** *(repeatable; pick one at random)*

> Everyone keeps saying I'm found. I don't feel found. I feel handed back.

> I had a whole self in there, you know. No name to answer to, no family to be a
> disappointment to. Just fog. It was the simplest I've ever been.

> [If CONFESSED: You're the one giving everyone their names back, region by region. Mine
> included. I'm meant to thank you. Give me a moment. I'm still working up to wanting it.]

TRANSITION TO CUT SCENE

### CUT SCENE

**IVY ASHBY**
> Ivy Ashby. That's who I am, apparently. There's a family up the road who've been grieving
> an Ivy Ashby for longer than I can hold in my head, and any moment now someone's going to
> come and be *so glad*, and I'm going to have to be her again. The disappointing daughter.
> The one who owes letters. The whole weight of a name.

**THE FOOL**
> You don't have to go back today.

**IVY ASHBY**
> No. But I don't get to stay lost, either — you saw to that, and I'm not even sorry, quite.
> In the fog I wasn't anyone's. That's a terrible thing to miss. I miss it terribly.
>
> [If CONFESSED: And everyone I meet now is getting the same gift you gave me — their name
> back, their weight back, whether they're ready to carry it or not. You must hear this a
> lot. That it doesn't feel like a gift yet. I don't imagine it gets easier to hear.]

END CUT SCENE

### CHOICE DIALOG — Ivy Ashby *(all questions may be exhausted; nothing here resolves — Theme 3)*

| The Fool | Ivy Ashby's response |
|---|---|
| Do you want to go back to the fog? | No. That's the awful part. I don't want it back. I just wasn't finished being no one yet. |
| Your family will be glad. | I know. That's a weight too — being glad *at*. I'll manage it. Just not this hour. |
| Who were you, in there? *(earnest)* | Nobody. Blessedly, weightlessly nobody. And now I have to be somebody again, and her name is Ivy, and I'm not ready to answer to it. |
| Take all the time you need. *(earnest)* | ...That's the kindest thing anyone's said since I got my face back. I'll sit here a while longer. Don't tell them where. |

[All versions pick up here — nothing is fixed; Ivy stays where she is, not lost, not
ready, exactly herself and grieving it:]

Ivy Ashby turns back to watch the last of the fog go, in no hurry to be found the rest of
the way. Pip, unbothered as ever, trots over and sits companionably beside her, and she
puts one hand on his head without quite deciding to, and the small comfort of it is the
only thing resolved in the whole clearing.

### BARKS — the border town, post-unbinding *(the cleared Mirrormarsh)*

**Nettle Vance Random Lines**

> Rope-line's for guiding folk *home* now, not just out. Different work. Better work. I'll
> get used to it, give me thirty years.

> Marsh had my whole life's monsters in it, and every one turned out to be somebody's
> missing kin. I walked past them for years. Didn't know. Couldn't have.

> [If CONFESSED: You end things, they tell me. Well. You ended the fog. Nobody up here's
> calling that anything but mercy — whatever else is coming down the road behind you.]

**Freed Fog-Person Random Lines**

> I came in looking for my brother. I think I *was* my brother, for a while. It's very hard
> to explain and I'd rather not try before breakfast.

> Whose hands are these. They're mine. I keep having to check. They're mine.

> Somebody said my name and I flinched. First time I'd heard it in — I don't know. Long
> enough that it fit like a stranger's coat.

**Cartographer's Bark — Rue Aldous** *(at her cottage, ringed by contradictory old maps)*

> Fog's gone and now the wretched place maps itself in an afternoon. Twelve years I fought
> it. Twelve. Don't you dare look smug on my behalf.

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Luned unbound (Anti-Fool defeated + climax + unbinding cutscene) | `WS_MOON_UNBOUND` | The Mirrormarsh fog lifts region-wide; the marsh becomes navigable without true light; its "monsters" are revealed as lost people and the border town un-curses; illusion-type enemies lose their ambush bonus world-wide (combat.md); the Fool receives Trump XVIII (Glamour); Pip enters the Mirrormarsh for the first time. Opens SQ-MIRRORMARSH-02 and the post-MQ18 variants of SQ-MIRRORMARSH-01 and -03. |

MQ18 does not branch: there is no player choice that sets a mutually exclusive world-state.
Ivy Ashby's scene resolves nothing by design (Theme 3) and sets no flag.

## Consistency references

- `arcana.md` §XVIII. The Moon — the Anti-Fool as the player's reflection carrying their
  exact current Pocket Spread reversed; the hard-gate on true light; Pip's refusal and the
  false-Pip who leads; the real Pip's howl cracking the glamour and the glass; the black
  glass water arena under the fixed Moon; Trump XVIII (Glamour) slots and reversed burden;
  §Cross-Trump synergy notes (the three true lights; the self-balancing build-check).
  §Bespoke-boss rule 7 — the Anti-Fool wears the player's rig by design.
- `characters.md` §Pip — the one fear (the Mirrormarsh), the protection rule and this
  quest's exclusive ownership of the false-Pip beat; Pip never performs concern, never
  leads anxiously, waits to be needed, gives one polite thump — the tells are drawn from
  here; Pip cannot be harmed and no dog is harmed on screen. §XVIII. The Moon — Luned,
  deliberately the most unreliable Arcanum, never entirely knowable, never self-naming
  until unbinding. §Regional named NPCs (Mirrormarsh) — Nettle Vance (fog-warden), Rue
  Aldous (cartographer bark), Ivy Ashby (MQ18's mourner).
- `world.md` §Hard and soft gates — the Mirrormarsh any-true-light gate and the loop-out as
  the locked-door message; §The Mirrormarsh — fog wetlands where paths, lights, and faces
  lie, "monsters" as lost people; §World-state matrix — `WS_MOON_UNBOUND` results, and the
  three true-light source flags (`WS_HERMIT_UNBOUND`, `WS_STAR_UNBOUND`, `WS_SUN_UNBOUND`).
- `combat.md` §Pip — the command wheel (Seek greyed out in Pip's absence); the Anti-Fool
  wearing the player's rig; illusion-type ambush bonus removed on unbinding.
- `narrative.md` §Dialogue style guide — Fool lines ≤ 12 words with one earnest/foolish
  option; the single Querent wink (spent at the Anti-Fool reveal, "whoever's had the wheel
  this whole long journey" / "anyone watching"); every sad scene one laugh (Rue's water
  bark, Ivy's dry "before breakfast"), every comic scene one honest beat; bound Arcana
  never pair "I" with a name; §Theme 2 (offices eat people — Luned's name returns), §Theme
  3 (freedom isn't wanted by everyone — Ivy, unresolved); §Act II `[If CONFESSED]` variants
  (`WS_DEATH_UNBOUND`).
- `callings.md` §The Callings — Fog-warden (Nettle: walk the rope-line, guide the lost out;
  post-MQ18, guide them home instead).
- `progression.md` §The Pocket Spread — the spread slotted at the border Waystation is what
  the Anti-Fool mirrors; Past/Present/Future slots and reversed orientation.
- `quests/side/SQ-MIRRORMARSH-01/-02/-03` — shared canon (the fog's freed people; the
  true-light gate; Nettle, Rue, Corin, Ivy) honored without contradiction; those quests
  deliberately carry no Pip beats and none is introduced there.
- `quests/TEMPLATE.md` — script format followed throughout.

## Open questions

- **Gate modeling (carried from outline):** the true-light requirement is an any-of-three
  OR across `WS_HERMIT_UNBOUND`, `WS_STAR_UNBOUND`, and `WS_SUN_UNBOUND`, which the
  `requires` schema (a flat list read as AND) cannot express. This script models the gate
  as diegetic region-logic (the loop-out), with `requires: []` a deliberate acknowledgment
  that quest-level gating can't carry it. Recommend formalizing an OR-group syntax in
  `quests/README.md`/`technical.md` only if a second any-of gate ever appears; otherwise
  leave as region-logic. Unresolved at the schema level.
- **False-Pip accessibility tell (carried from outline):** the false-Pip beat depends on
  players already knowing Pip's behavioral rules, and the tells are deliberately never
  labeled in UI. Does the beat need a distinct non-diegetic accessibility affordance (a
  subtitle cue, an audio-description track, a colorblind-safe fog-sheen) for players who
  can't read the behavioral tells, without breaking the "never labeled" rule for everyone
  else? Needs an `art-audio.md`/accessibility pass. Unresolved.
- **The reversed true-light problem (new tension).** If the player's slotted Pocket Spread
  includes their true-light Trump (very likely, since it's what admitted them to the marsh),
  the Anti-Fool mirrors and reverses it too — turning the Fool's own light into deception
  mid-fight. Thematically perfect, but does the reversed light disrupt the arena's
  navigability or the player's ability to read the honest Anti-Fool, and is that intended
  difficulty or an unfair spiral? Combat tuning to rule. Flagged, not fixed here.
- **Multiple-light arrival precedence (new tension).** The script rules brightest-wins
  (Sun > Wish > Lantern) for a player carrying more than one true light. This is asserted
  here, not sourced from an owning doc; confirm against any world.md/art-audio precedent for
  stacked light sources, or promote the rule to world.md if this is the first case of it.
- **Ivy Ashby vs. Corin Vesk proximity (per SQ-MIRRORMARSH-02's open question).** Both are
  freed fog-people who resist the "happy ending." This script differentiates Ivy sharply —
  she refuses *nothing* and rejects *no one*, she simply isn't ready to re-shoulder a name —
  where Corin actively refuses his family. The differentiation is written; the two beats'
  spacing/gating relative to each other remains SQ-02's call, not resolved here.
- **Border-settlement naming.** The fog-line settlement is left unnamed to avoid inventing
  canon; if world.md or a future side quest names it, this script should adopt the name.
