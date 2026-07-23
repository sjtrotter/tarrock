---
id: MQ13
title: An Ending
type: main
status: script
arcana: XIII. Death
region: The Stillmarsh
requires: []
fires: [WS_DEATH_UNBOUND]
---

# MQ13 — An Ending

## Introduction

By the time the player reaches the Stillmarsh, they have heard it named in every region
behind them — always lowered, always the one place nobody quite wants to discuss.
Arriving changes the shape of the game. For the first time, nobody here treats the Fool
as a stranger with no category: the Stillmarsh knows exactly what the Fool's coming means,
and is glad of it, and a little afraid of it, and bows to Pip on sight without ever being
able to say why. Mortimer — Death, the kindest soul in the world and the only Arcanum who
has ever asked to be fought — waits at the region's heart to welcome the Fool like family
arriving late for supper, not to bar the way. The quest requires nothing and may be played
in any order; there is no hard branch. What it delivers is the purest duel in the game, a
confession the Querent can no longer dodge, and the single largest change the world will
ever undergo — mortality itself, handed back over. Completing MQ13 fires `WS_DEATH_UNBOUND`
and, with it, the global `CONFESSED` state: from this point on, every region already knows
what a visit from the Fool means. Because this quest is the *origin* of `CONFESSED`, it
carries no `[If CONFESSED]` variants of its own — it is the thing every other quest's
post-confession lines are reacting to.

---

## QUEST: AN ENDING

### EXT. THE STILLMARSH: The Ferry Landing — TIMELESS DUSK

THIRD PERSON GAMEPLAY

The road out of the last region simply lowers, and keeps lowering, until it is a plank
jetty over black, unmoving water. The Stillmarsh opens flat to every horizon: reed-beds
and mudflats and standing pools, and everywhere, set on posts and sills and the prows of
tied-up punts, small candle-lanterns burning low and level, none of them guttering, none
of them flickering, their reflections lying perfectly still on water that has not rippled
in three hundred years. The hush is unlike anywhere else in the Spread — not the held
breath of the Prestige or the frozen roar of the Spire, but something older and gentler,
the quiet of a house where someone is sleeping and everyone has agreed to let them.

[If WS_SUN_UNBOUND: the marsh lies under a genuine night now — real dark, real cold coming
off the water — and the lanterns burn against it rather than against the old timeless grey.]

[If WS_STAR_UNBOUND *(with WS_SUN_UNBOUND for the full effect)*: the stars have come out
over the Stillmarsh, and the still water holds every one of them, doubled and motionless,
so the Fool seems to walk out across two skies.]

At the jetty's end, a long flat-bottomed ferry waits, and leaning on its pole, in no
hurry whatsoever, stands OLD SALLOW — a thin, weathered man of no describable age, with
the look of someone who has been just about to sit down for a very long time.

**[Tutorial prompt: board the ferry.]**

As the Fool steps aboard, Pip pads on ahead and sits at the prow, ears up. Old Sallow
looks down at the dog, and — without a word, without seeming to decide to — inclines his
head to him. A small bow, given to a small white dog, as naturally as breathing.

**OLD SALLOW Random Lines** *(repeatable; pick one at random)*

> Mind the step. Not that a step's ever hurt anyone here. Nothing does, that's rather
> the trouble with the place.

> You'll be the Fool, then. No, don't look surprised — you're the only thing that's
> come down this road on *purpose* in three hundred years.

> [If Death unbound within the first seven Arcana: You've come to us early, haven't you.
> The rest of the world out there doesn't even know yet what you are. It will.]

> [If Death unbound with most other regions already woken: Took the long way round to
> us, didn't you. Watched the whole Spread wake up and leave us for last. Well. We're
> patient. It's the one thing we've had practice at.]

TRANSITION TO CUT SCENE

### CUT SCENE

Old Sallow pushes off. The pole goes down without a splash; the ferry slides across the
black water without a wake. He does not ask for a coin, and when the Fool moves as if to
offer one, he waves it off with the back of one hand.

**OLD SALLOW**
> Put it away. I've not taken a coin for this crossing in — oh, long enough that I've
> forgotten the weight of one. What would I spend it on? There's nothing to buy here
> and nowhere it'd get to before I did.

He poles on a while, unhurried, the lanterns sliding past.

**OLD SALLOW**
> I've been nearly done dying for three hundred years, friend. Nearly. Right on the
> lip of it. Longest goodbye anyone ever drew out, and I never even got to the good
> part. You get so you can make a joke of it. You have to. It's that or the other thing.

A beat. Pip, at the prow, has not moved, and Old Sallow glances at him again with that
same instinctive small deference, and does not explain it, because he could not.

**OLD SALLOW**
> Mortimer's expecting you. Been expecting you longer than the water's been still, if
> you want the truth of it. Go on up to him when you land. He'll not make you fight to
> reach him — that's not his way. He'll make the tea.

END CUT SCENE

### CHOICE DIALOG — the crossing *(all questions may be exhausted)*

| The Fool | Old Sallow's response |
|---|---|
| Don't I owe you a coin? | You owe me nothing. First honest fare I've had in three centuries is you, sitting still long enough to be carried. That'll do. |
| Nearly done dying — how long is *nearly*? | Three hundred years and counting, and every one of them I've thought, *this'll be the one.* You get fond of the nearly, in the end. Almost fond enough to keep it. |
| You must be so tired. *(earnest)* | ...Aye. That's the first anyone's said it plain in a long while. Tired's the word. Not sad, mind. Just — ready. There's a difference, and it took me a hundred years to learn it. |

[All versions pick up here:]

The ferry noses against the far bank with a soft wooden knock. Old Sallow steadies the
pole and nods the Fool ashore.

### EXT. THE STILLMARSH: The Lantern Lanes — TIMELESS DUSK

THIRD PERSON GAMEPLAY

The far bank is a scatter of low houses on stilts and raised board-walks, lantern-lit,
strung together by plank causeways that run out over the reeds. People move slowly here,
or not at all — sitting in doorways, standing at windows, tending flames that do not need
tending. None of them looks at the Fool the way the rest of the Spread has: no wariness,
no double-take at a stranger who fits in no box. Here, they know the box. They nod as the
Fool passes, the way you nod to family you were told to expect.

**[Tutorial prompt: cross the causeway toward the light at the marsh's heart. Pip leads.]**

As the Fool passes each doorway, the person in it looks first — always first, before they
look at the Fool at all — to Pip, and bows. Small bows, from the waist or just the head,
given to a scrappy white dog trotting past a puddle. Nobody says why. Nobody in three
hundred years has been able to say why. Pip accepts each one with the mild good grace of a
dog who is used to it, and keeps walking.

**Waiting Folk Random Lines** *(ambient; the people of the lanes)*

> Bless the little dog. Bless him and the one who walks with him. *(said to Pip, never
> the Fool)*

> You've come, then. We heard you would. We hear everything, out here — there's not a
> lot else to do but listen for footsteps.

> Don't mind us. We're only waiting. We're rather good at it by now.

> [If WS_SUN_UNBOUND: First night I've felt the cold of in three hundred years. Do you
> know, I think I *missed* being cold. Funny thing to miss.]

### INT. THE STILLMARSH: Mortimer's Hearth — TIMELESS DUSK

THIRD PERSON GAMEPLAY

The heart of the marsh is a broad, low house, open on all sides to the reeds, with a fire
in a stone ring and a kettle already on it and more mismatched chairs than one household
could ever need — as though the place has spent three centuries expecting company and
laying places for it. A tall figure in plain dark robes rises from tending the fire the
moment the Fool steps under the eaves, and turns, and his whole weathered face opens into
a smile of such uncomplicated gladness that it takes a second to remember what he is.

This is MORTIMER. He does not reach for the scythe leaning by the doorpost. He reaches
for another cup.

TRANSITION TO CUT SCENE

### CUT SCENE

**MORTIMER**
> There you are. *There* you are. Oh, come in, come in — sit down, you've come such a
> long way, and Pip, you old marvel, look at you, not a grey hair on him after all
> this time —

He crouches, and Pip trots straight to him and submits to having his ears fussed, tail
going, entirely at ease. Mortimer looks up at the Fool from there, and the gladness in
his face has a floor of something older under it — a tiredness so deep it has stopped
being a feeling and become simply the shape of him.

**MORTIMER**
> Forgive me. I don't get to be glad very often. I've been the last thing a great many
> people were ever glad to see, and then not allowed to be even that — do you understand?
> They come here to finish, and they cannot, and I have to sit with them in the not-
> finishing, year on year on year, and I cannot give them the one thing this whole
> office exists to give.

He straightens, and pours the tea — three cups, out of long habit, though there are only
the two of them and a dog — and hands one to the Fool with both hands, steady.

**MORTIMER**
> But you've come now. So. Sit. Drink that. And when you're rested — not before — you
> and I are going to have a talk about what happens next. There's no hurry. There has
> never, in the history of this marsh, been a hurry.

END CUT SCENE

### CHOICE DIALOG — Mortimer's welcome *(all questions may be exhausted)*

| The Fool | Mortimer's response |
|---|---|
| You're not going to stop me? | Stop you? Friend, I have been on my knees for three hundred years *praying* for you. You're not the thief at the door. You're the one who's finally come to open it. |
| Why is everyone here so kind? | Because we've had nothing to do but practise it. When there's no ending, there's no rush, and no rush is where kindness grows. It's the one crop this marsh has ever raised. |
| You've waited a long time. *(earnest)* | Longer than the words for it. I stopped counting when the counting started to hurt. But you're here, and that's — that's the count over, isn't it. That's the sum done at last. |

[All versions pick up here:]

Mortimer settles into a chair by the fire with his own cup, and for a moment simply sits,
in the plain animal comfort of a man with a guest and a warm drink, and lets the Fool rest.

**MORTIMER**
> Go and walk the lanes first, if you like. Meet the folk. See what it is I've been
> keeping. I'd have you know what you're setting right before you set about it — that's
> only fair. I'll be here. I'm always here. It's the whole of the job.

### INT. THE STILLMARSH: The Vigil-House — TIMELESS DUSK

THIRD PERSON GAMEPLAY

Down one of the longer causeways stands a great raftered house full of low beds and low
talk — a *vigil-house*, one of several where the Stillmarsh's dying have gathered to wait
out an ending that never comes. It should be dreadful, and in a way it is: dozens of them,
here, patient, some sitting up and playing at cards with hands that have not been dealt a
fresh game in centuries, some lying still with their eyes on the rafters, and one old woman
at the far window who has stopped talking altogether and simply watches the water, waiting,
waiting. The dread is real. So is the warmth. Someone is always holding someone's hand.

A knot of the more sprightly "dying" wave the Fool over the moment they clock the white dog.

**GAMMER THIST** *(a very old woman, propped up, bright as a robin)*
> You'll be the one, then. Come here, let me look at you. *(she looks; she is unimpressed
> and delighted in equal measure)* Hm. Smaller than I pictured the end of the world.

**OLD BARROW** *(across the aisle, not looking up from his cards)*
> Everything's smaller than she pictured it. Been telling her for two hundred years the
> ceiling's low and she keeps cracking her head on the beam getting up. You'd think
> she'd have learned. You'd think any of us would have learned anything, all this time.

**GAMMER THIST**
> Barrow and I have a wager going. *(she says it with enormous relish)* Which of us goes
> first, when the going finally starts. Laid it the night before the Stall. Two hundred
> and — how long, Barrow?

**OLD BARROW**
> Long enough that the stakes are a loaf of bread neither baker's alive to bake.

**GAMMER THIST**
> Longest game of nerves in the whole Spread, and the old goat still won't blink. *(a
> pause; then, gentler, to the Fool)* Settle it for us, would you. When you've done what
> you've come to do. I've a feeling I've got him beat at last — and I should so like to
> win one before I go.

The laugh she gets — from Barrow, from the beds nearby, from the Fool if the player lingers
— is real and warm and lands in the middle of the dread like a candle set down in a dark
room. Then Gammer Thist's eyes go, for just a second, to the silent woman at the far window,
and the room quiets, and the honest weight of the place settles back over it.

**GAMMER THIST** *(low)*
> She's been ready the longest of any of us. Won't play cards. Won't take the wager.
> Just watches the crossing. Some of us make jokes to pass a wait like this. Some of us
> haven't the jokes left. You'll be kind to her, when it comes. I know you will.

### CHOICE DIALOG — the vigil-house *(all questions may be exhausted)*

| The Fool | The dying's response |
|---|---|
| Doesn't the waiting frighten you? | *(Gammer Thist)* Frighten? Bless you, no. It's not the ending that frightens a body. It's the *never* — the going-on and going-on with the door locked. You're the key, duck. Keys don't frighten anyone. |
| What will you do, after? | *(Old Barrow)* Same as anyone does after. Nothing. Blessed, ordinary nothing. Do you know I have not been *nothing* in three hundred years? I can't wait. First rest in an age. |
| I'll settle the wager. I promise. *(earnest)* | *(Gammer Thist, delighted)* There's a good Fool. Written down and witnessed — Barrow, you heard it. Now off you go and make an honest woman of me before I lose my nerve, which at my age is a genuine risk. |

[All versions pick up here:]

Out one window, across the reeds, a single candle burns in a distant sill and does not
gutter — CORSE MILLBANK'S window, his wife among the waiting, a whole small story tended
in one unspent flame. Somewhere else, a family's several generations trade a vigil-rota by
the door — the Hallows, keeping a watch that has outlived four sets of the people keeping
it. The Stillmarsh is full of these. The Fool cannot fix a single one of them. That is not
what the Fool has come to do.

### EXT. THE STILLMARSH: The Ferryman's Errand — TIMELESS DUSK

THIRD PERSON GAMEPLAY

On the way back toward the heart of the marsh, TARN LOACH — Old Sallow's young ferryman's
mate, a battered book under one arm — steps out onto the causeway and stops the Fool. He
bows to Pip before he says a word, the way everyone here does, then holds out an unlit
lantern.

**TARN LOACH**
> You're going back up to Mortimer? Good. Then do us a kindness on the way and take his
> round for him — just the one. He'll have told you there's no hurry and he'll be right,
> but there's a difference between no hurry and no *rest*, and that man has not sat down
> properly in three centuries. He'll not stop while there's a lantern to be carried. So
> carry it, and let him.

**[Tutorial prompt: take the lantern. This is the Ferryman's-mate errand — the doorway to
the Stillmarsh Calling (`callings.md`); the Fool may take up the role in full afterward.]**

The errand is small and specific: light the lantern at the hearth-fire, carry it out along
the board-walk to a particular bedside where an old man lies too weak to keep his own flame,
set it in his sill, and sit with him a moment while it catches. He does not need
conversation. He needs the light, and the company of not being alone while it burns. The
Fool sits. The old man's breathing eases. That is the whole of the task, and the whole of
the office, and Mortimer — visible back at his hearth, watching the Fool take it up —
finally, for the first time the marsh has seen in memory, sits all the way down and closes
his eyes for a while.

**TARN LOACH** *(as the Fool returns the lantern)*
> There. He rested. First time in — I don't have a number for it, and I keep the numbers.
> *(he taps the battered book, half a joke and half not)* Thank you. He'd never have asked.
> None of them ever ask. That's why somebody has to notice.

### INT. THE STILLMARSH: Bettony's Door — TIMELESS DUSK

THIRD PERSON GAMEPLAY

The last house before the heart of the marsh has its door open and its lamp trimmed low.
Inside, a woman sits at a bedside she has plainly not left in longer than is reasonable —
BETTONY MARSH, hollow-eyed and upright and utterly devoted, holding the hand of the old
man in the bed. GAFFER CORLIN is deathless and bedridden and worn to almost nothing, a
whisper of a man, but his eyes are open and sharp and dry as flint when they find the Fool.

**BETTONY MARSH**
> You're here. *(she does not get up; she will not let go of his hand)* Grandda, look —
> the Fool's come. It's really the Fool. Didn't I say? Didn't I keep telling you to hold
> on just a little more?

**GAFFER CORLIN** *(a thread of a voice, and every word deliberate)*
> You did, girl. You've been telling me to hold on for a hundred years and more. *(his eyes
> go to the Fool, and there is something in them that is almost laughter)* She's a
> wonderful girl. She'd hold the whole marsh here by the coat-tails if the marsh would
> let her. That's rather the trouble.

Bettony's grip on his hand tightens, not gently, and she does not seem to know she's done
it. The room holds the exact tension the whole quest is planting here: he is ready to go,
and she is not ready to let him, and the office that would settle it between them has been
locked shut for three hundred years.

### CHOICE DIALOG — Bettony's vigil *(all questions may be exhausted)*

| The Fool | Bettony's / Gaffer Corlin's response |
|---|---|
| How long have you kept this vigil? | *(Bettony)* Since before I knew it was one. My mother sat here, and hers. I don't remember choosing it. You don't choose the ones you love — you just don't leave. |
| Is he in pain? | *(Gaffer Corlin)* Pain? No, lad. Worse than pain. *Boredom.* Do you know how long three hundred years is when you're too tired to sit up and too stubborn to stop? Don't answer. You'll find out soon enough, if you botch this. |
| You've held on so long. Both of you. *(earnest)* | *(Bettony, and it costs her)* ...I know. I know we have. Everyone keeps looking at me like I ought to be glad you're here. And I am. I *am.* It's only — when it comes, it'll be him gone. Glad and gone are a hard pair to hold at once. |

[All versions pick up here:]

Gaffer Corlin's dry eyes follow the Fool to the door.

**GAFFER CORLIN**
> Go on, then. Go and do the thing. *(a long breath)* And don't you mind her when it's
> done. She'll be cross with you and cross with me and cross with the whole business.
> It's how she loves. Always has been. Let her.

### EXT. THE STILLMARSH: Mortimer's Hearth — TIMELESS DUSK

THIRD PERSON GAMEPLAY

Back at the heart of the marsh, Mortimer is on his feet again, rested for once, and there
is a different quality to him now — not grimmer, but readier, a man who has let his guest
see the whole of what is at stake and will not now insult them by pretending it is small.

TRANSITION TO CUT SCENE

### CUT SCENE

**MORTIMER**
> You've seen them. Good. Then you know what I keep, and why I've prayed for you, and why
> what I'm about to ask isn't cruelty — it's the opposite. It's respect.

He crosses to the doorpost and takes up the scythe at last. He holds it the way a farmer
holds a tool, not the way a soldier holds a weapon — familiar, unfrightened, almost fond.

**MORTIMER**
> I'll not simply hand you the card. I've thought about it — the gods know I've had the
> time to think about it — and I can't. An ending has to be *earned*, friend. It's the
> one dignity the office has left to give. If I laid down and let you walk over me, I'd
> be handing you a death, and death isn't a thing you're handed. It's a thing you meet.
> Anything less would be disrespect to the office. To them. *(a glance toward the lanes)*
> To me, if I'm honest, and I am, now, at the end. I want this fought. I want it *proper.*

He steps out from under the eaves, toward the flat black shore beyond, and looks back once,
and the smile is there again, gentle and immense.

**MORTIMER**
> Come and meet me on the shore when you're ready. There's no clock. There's never been
> a clock. But when you come — come to *win*.

END CUT SCENE

### EXT. THE STILLMARSH: The Candle-Ring — TIMELESS DUSK

THIRD PERSON GAMEPLAY

The flattest shore in the marsh, where the black water goes out to nothing and the sky
comes down to meet it, has been ringed with candles — dozens of the same low, level,
unguttering flames from all across the Stillmarsh, set in a wide circle on the wet sand,
their reflections doubling them in the still water below so the ring seems to hang in the
middle of the dark, unsupported. There are no benches, no crowd, no stakes driven for
Blanks to rise from. There is Mortimer, standing easy at the ring's centre, and there is
the Fool, and there is Pip, who trots to the edge of the candlelight and sits, and watches,
and does not perform the slightest concern, because he never does.

Mortimer lowers himself and sits cross-legged on the sand, and lays the scythe across his
knees, and folds his hands over it, and waits.

**MORTIMER**
> On your time. Only yours. I've all of mine, and always have.

**[UI prompt: the fight begins on the Fool's input, and not before. Mortimer will wait
indefinitely — rest at the marsh's Waystation, change the Pocket Spread, walk away and come
back. The candle-ring holds. When the Fool commits, phase one begins.]**

### QUEST: THE DUEL — PHASE ONE

### EXT. THE STILLMARSH: The Candle-Ring — TIMELESS DUSK

THIRD PERSON GAMEPLAY

Mortimer rises in one unhurried motion, and the scythe comes up with him, and the kindest
man in the world becomes the hardest fight in it. This is the pure duel, exactly as
`arcana.md` §XIII stages it: no adds, no arena gimmick, no rotating hazard, no trick of any
kind — one opponent, one weapon, and the whole of the base combat system asked for at once.

The scythe's reach is the fight's entire language. Mortimer reads the Fool's distance
perfectly and answers it: long, unhurried horizontal sweeps that punish standing still, an
overhead reap that comes down slow enough to see and fast enough to hurt, and — the one
tell to live or die by — a drawing *pull* of the blade toward himself, telegraphed by a
half-step back, that turns the whole reach inside-out and catches anyone who read the sweep
as a reason to close. There is no cheap opening. Every window the Fool gets is one they
made: a Fool's Chance off a dodged sweep, a punish on the recovery of the reap, the pull
baited and slipped. He fights with total sincerity and total economy, wasting nothing,
forgiving nothing, and — unmistakably, in the set of his shoulders and the almost-smile he
never quite loses — *enjoying* it, in the way of a man doing the one thing his office was
ever for, well, and for the last time.

**[Combat note: this is the difficulty peak among the game's duels, by design (`arcana.md`
§XIII). It is tuned to be beaten clean, on skill, with no gimmick to exploit and none
needed — the fairest hard fight in the Spread.]**

At half health, Mortimer steps back out of measure, plants the scythe butt-down in the wet
sand, and rests one hand atop it — not staggered, not hurt, simply choosing to stop. The
candlelight steadies. The water goes glass-still. He is not out of breath. He never was.

TRANSITION TO CUT SCENE

### CUT SCENE — THE CONFESSION

Mortimer looks at the Fool across the ring, and for a moment says nothing, and the Querent
— who has been quieter through this whole region than in any quest before it, offering none
of the usual dry asides, spending not one wink, letting the place have its silence — is
silent still. When Mortimer speaks, it is gentle, and it is the truth, all of it, laid down
without a single soft edge to hide behind.

**MORTIMER**
> Now. While we've breath between us. Because you've earned the *whole* of it, and I'll
> not send you back into that second half half-blind.
>
> You know what I am. You've worked out, I think, most of what the rest are. Every card
> you've turned loose so far, you did it by letting something *end* — a show, a harvest,
> a verdict, a long march. That's the shape of the whole journey. That's not a trick
> being played on you. That's just what it is.
>
> The last card in the Great Reading is The World. When it turns, the Reading is done. And
> when the Reading is done, friend, the world is gathered up and dealt again — the Shuffle.
> Finishing the journey doesn't *save* the world. Finishing the journey *ends* it. That's
> what completing the Reading means. I'll not pretend otherwise. Nobody has ever loved a
> thing enough to pretend otherwise to it, and I love you too much to start.

He picks the scythe up off the sand, gently, and holds it at rest across both hands, level,
offered rather than raised — and closes, kindly, with the plainest thing he owns:

**MORTIMER**
> You are the ending, little Excuse. I am only the door.

A long beat. The candles do not move. And then the Querent speaks — and there is none of
the usual music in it, no deflection, no answering-a-question-with-a-question, no wink for
the player behind the Fool's shoulder. Just the truth, confirmed directly, for the first
time in the whole game.

**THE QUERENT** *(quiet, unhidden)*
> He's right. Everything he just said is true, and I've known it was true since the cliff,
> and I let you find it out slow because I couldn't bear to be the one to say it. But he
> can say it, because he's Death, and Death doesn't flinch. So — there. No more sliding
> round it. The journey ends the world. It always did. You've a right to know that
> standing up, and now you do.

The Fool answers — not the world, not the cosmos, just Mortimer, across a ring of candles.

### CHOICE DIALOG — the Fool's answer *(first pick commits; it colors the exchange and gates nothing)*

| The Fool | Mortimer's response |
|---|---|
| Then I'll walk it with my eyes open. *(earnest)* | *(and his whole face eases)* That's all I wanted for you. Not that you'd go on — that you'd go on *seeing.* There's the difference between a mercy and a murder, and you just chose the right side of it. |
| A world that can't end isn't living. | You've been paying attention. That's the argument, friend — the only one there is. Everything out there taught it to you, region by region. You just said it back to me plainer than I ever could. |
| I'm afraid. But I'm going anyway. | Good. Be afraid. Only a fool with no fear left would end a world lightly, and you're a better Fool than that. Afraid and going anyway — that's not weakness. That's the whole of courage. |

[All versions pick up here:]

Mortimer settles his grip on the scythe, and the almost-smile comes back, and it is proud.

**MORTIMER**
> Then let's finish it. Both of us. Nothing hidden now, on either side. Come on, friend.
> Come and do it *right.*

END CUT SCENE

### QUEST: THE DUEL — PHASE TWO

### EXT. THE STILLMARSH: The Candle-Ring — TIMELESS DUSK

THIRD PERSON GAMEPLAY

Phase two is the same duel and a different one. Mortimer fights harder and cleaner —
faster sweeps, tighter pulls, the reap chained now into follow-ups that ask everything the
first half taught and a little more — and there is nothing left unsaid between the two
fighters to slow either of them down. It is, by design, the purest fight in the game,
played through twice: once in ignorance and once in full knowledge, and the second time
with no illusion standing anywhere on the shore. The Fool is not tricking their way to an
ending now. The Fool is choosing one, blow by blow, having been told exactly what it costs.

When the last opening comes, it is the Fool's to take. Mortimer does not fall like a man
struck down. He sinks like a man setting down a weight he has carried past all reason —
knees to the sand, scythe laid flat, breath going out of him long and slow and, at the very
end of it, something that has been locked in his chest for three hundred years going out
with it.

TRANSITION TO CUT SCENE

### CUT SCENE — THE UNBINDING

The office cracks. It does not shatter theatrically; it comes apart the way frost comes off
a window in the first honest warmth — the dark robes, the scythe's authority, the weight of
being *Death* rather than a man, all of it thawing off him and away. He kneels there in the
candlelight, smaller and plainer and unbearably relieved, and looks at his own hands as
though they are new.

Everyone in the Stillmarsh has called him Mortimer for three hundred years. He has answered
to it, gently, a thousand thousand times. But he has never once said it of himself — never
put the name and the *I* together in his own mouth — because the office does not permit its
holder that, and the office has held him since before the Stall.

Now it doesn't.

**MORTIMER** *(barely aloud, testing it, wondering)*
> ...Mortimer.
>
> *I'm* Mortimer.

He says it the way a man says a word in a language he was born to and never allowed to
speak — carefully, then again, a little steadier, quietly *amazed* by the sound of it in
his own voice.

**MORTIMER**
> Do you know, in three hundred years — that's the first time I've ever got to say it.
> They all called me it. Every soul I ever sat with. And I never once got to say it *back.*
> Mortimer. My name is Mortimer. *(a breath that is almost a laugh, almost a sob, and
> lands as neither)* Oh, that's — that's a good sound. That's a *good* sound.

He reaches into the front of the robe, over the heart, and draws out the card — Trump XIII,
Passage, plain as a gravestone and warm from being carried. He does not flourish it. He
takes the Fool's hand in both of his and folds the card into it and closes their fingers
over it and holds them there, both his hands around the Fool's one, entirely sincere, and
asks the single thing he asks.

**MORTIMER**
> Don't waste it.

That is all. Not *use it well*, not *avenge me*, not *remember me* — nobody drops loot in
the Stillmarsh, and nobody dies here today; he is *released*, and he asks only that the mercy
he could never give be spent on purpose. He lets go. He gets to his feet — steady, whole,
unhurried in a way that is suddenly *choice* rather than office — and looks out at the
lantern lanes he has kept for three centuries with the face of a man about to finally,
finally go home.

**[The Pocket Spread's Present slot (open since MQ01) now holds Trump XIII — Passage. Slot
it to try Reap: execute a lesser enemy below a third of its health. Its Past effect —
Blanks you defeat stay ended, no longer reassembling elsewhere — and its Future — rise once
where you fell at one petal, *not yet* — come slotted with it.]**

END CUT SCENE

### EXT. THE STILLMARSH: The Lantern Lanes — DAY ONE

THIRD PERSON GAMEPLAY

The change arrives the way the office left — not with spectacle, but with a hush going out
of the air. Across the marsh, all at once and very quietly, the ones who were ready begin
to be able to go. There is no wave of collapse, nothing grim; there is a woman at a far
window who has watched the crossing for three hundred years, and her watching simply,
gently, ends, and the ones who love her close her eyes, and it is the first true ending the
Stillmarsh has held since before the Stall, and it is *right.*

**[Tutorial/world note: WS_DEATH_UNBOUND fires here. Mortality returns to the whole Spread;
the global CONFESSED state activates; the Hollows unlock (MQ20 gate). Seasons will begin
to cycle. Deaths in the world are scripted, never a systemic aging sim — `world.md`.]**

The vigil-house is already changing when the Fool passes it. Gammer Thist waves from her
bed, alight with mischief, jabbing a thumb at Old Barrow across the aisle.

**GAMMER THIST**
> There you are, my duck — quick, come here and *witness it,* the old goat's finally
> going first, I win, I *win* — three hundred years I've held that wager and I've got him
> at last —

**OLD BARROW** *(with enormous dignity, and not one shred of hurry)*
> Won fair. Loaf of bread, when either baker's reborn to bake it. *(to the Fool, dry as
> dust)* Tell her she can gloat all she likes. I'll not be about to hear it, and that,
> madam, is the sweetest part of losing.

The laugh they share is the last one either of them gets, and they both plainly know it,
and they spend it on each other anyway. It is exactly the tone bar: the honest weight and
the honest joke, in the same breath, refusing to be separated.

### EXT. THE STILLMARSH: Across the Marsh — DAYS LATER

THIRD PERSON GAMEPLAY

Over the following in-game days, the Stillmarsh empties the way a lamp lowers — slowly,
without drama, one light at a time. The lantern lanes thin. The vigil-houses go quiet room
by room. And into the emptied hush come two things the marsh has not held in three hundred
years: funerals, and weather.

The funerals are the world's first, and they are nothing like the dread the word carries —
modest, communal, more like a barn-raising than a horror: neighbours carrying a neighbour
out along the causeways by lantern-light, a few plain words at the water's edge, a cup
passed, a name said aloud and let go. And around it all, for the first time in living
memory, the *season turns* — a real chill coming into the reeds, the first leaves the marsh
willows have dropped since before the Stall going gold and letting go and drifting down onto
the still black water, which is, at last, allowed to carry them away.

**Mourning-Marsh Random Lines** *(ambient; the changing region)*

> We buried Sedge Fenner this morning. First grave dug in the Stillmarsh in three hundred
> years. Hard work, digging. Good work. Honest work. We'd forgotten.

> Cold's come in. Proper cold, the kind with an end to it — autumn, they're calling it,
> them as remember the word. My old bones ache and I could weep for the joy of it.

> [If Death unbound with most of the Spread already woken: We were last. Every other region
> got its waking before us. But ours is the one that *matters,* isn't it. Ours is the one
> that let all the rest of them mean anything.]

> Sallow's still poling. Same lanes, same lanterns. Only now the far shore's a place folk
> actually get *to.* Makes all the difference, that. Makes all the difference in the world.

### INT. THE STILLMARSH: Bettony's Door — DAYS LATER

THIRD PERSON GAMEPLAY

Some days on, the lamp at Bettony's door is out. Inside, the bed is neatly made and empty,
and the window is open to the turning cold, and Bettony Marsh sits in the chair beside it
with her hands in her lap and her face doing something the game does not resolve and refuses
to.

TRANSITION TO CUT SCENE

### CUT SCENE — THE MOURNING

**BETTONY MARSH**
> He went in his sleep. Three nights back. Just — went. Gentle as you like, the way I
> always swore to him he would, if he'd only hold on till you came. *(her voice is
> perfectly steady, which is the worst of it)* And he held on. He held on a hundred years
> past sense, because I asked him to. And then you came, and he didn't have to any more,
> and he *didn't.*

She looks up at the Fool, and there is no accusation in it, only the impossible arithmetic
of the thing.

**BETTONY MARSH**
> I keep waiting to feel one thing about it. Relief, or grief, the way you're meant to pick
> one. And I can't. It's both, all the time, at once, and they won't sit still long enough
> to be either. He's *out.* Three hundred years and he's finally out, and I'm so glad I can
> hardly breathe. And he's *gone.* And I'm so — *(and here, for the first time, it cracks,
> just slightly)* — I wanted him free more than I've ever wanted anything, and now he is,
> and the wanting's got nowhere to go.

She turns to the made bed, and on the pillow, tucked where she'd not find it until the
sheets were changed, is a folded scrap of paper in a shaky, deliberate hand — Gaffer
Corlin's, written some patient night against exactly this morning. She has plainly already
read it a hundred times. She unfolds it and reads it out anyway, because she cannot stop.

**BETTONY MARSH** *(reading)*
> "Took you all long enough."

And it does what he meant it to do — it breaks her heart open in the good way and not the
bad one, the laugh arriving through the tears and carrying half of them off with it, the dry
old man getting the last word from three nights dead and using it to make her *laugh* at his
own funeral because he loved her and knew exactly, exactly how she loved. She holds the two
feelings, both of them, and the game lets her, and does not tidy them into one.

**BETTONY MARSH** *(folding it away, wet-eyed and almost smiling)*
> ...Trust him. Trust him to have the last word. Three hundred years too tired to sit up,
> and he saves his breath for *that.* *(a shaky exhale)* Go on. I'll be all right. Not
> today. But I'll be all right, which is more than any of us could say last week. Thank
> you. For the door. For letting him find it.

END CUT SCENE

### EXT. THE STILLMARSH: The Far Shore — DUSK

THIRD PERSON GAMEPLAY

The quest's last word belongs, as it always would, to the ferry. Old Sallow is at his pole
where the Fool first met him, poling the same black lanes past the same low lanterns — but
the crossing is not the same crossing, and both of them know it. He brings the ferry in and
leans on the pole and looks at the Fool a while before he speaks, and there is something new
sitting under the old dry wryness: a thing that took three hundred years to become possible,
and has, at last.

TRANSITION TO CUT SCENE

### CUT SCENE

**OLD SALLOW**
> Well. You did it. *(he says it plainly, no ceremony)* Marsh is emptying out around me by
> the day. Folk I've carried across nowhere in particular for three centuries, and now the
> far bank's a real bank and they're actually *landing* on it. Strange, watching them go.
> Good strange. The best strange there is.

He looks out over the water, at the two lanterns doubling in it, at the leaves the willows
have finally been allowed to drop.

**OLD SALLOW**
> I've been nearly done dying for three hundred years, friend. And do you know — now that
> it's on the table, now that a body can actually *finish* — I find I'm rather looking
> forward to it. Not rushing at it, mind. I've a ferry to keep a while yet; somebody's to
> carry the last of them over, and I'll not leave that to young Tarn on his own. But when
> my turn comes round at the back of the line, where it belongs — I'll take it. Gladly.
> I've earned a good long nothing.

He pushes off, unhurried, the pole going down without a splash, and calls back over the
still water the plainest and most patient thing the Stillmarsh has to say:

**OLD SALLOW**
> No rush, mind. I've waited this long.

The ferry slides out across the two skies, and the candles burn low and level, and the
first leaves of the first autumn in three hundred years come down onto water that is, at
last, allowed to carry them somewhere.

END CUT SCENE

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion (Mortimer unbound) | `WS_DEATH_UNBOUND` | **Mortality returns** across the Spread. Seasons begin cycling (the Stillmarsh's first autumn); NPCs can die (scripted only — no systemic aging sim); the Stillmarsh empties over in-game days; funerals appear as ambient events (modest, communal); the Hollows unlock (`MQ20` gate). The Fool receives Trump XIII — Passage. Also activates the global `CONFESSED` state (`world.md` §Global states), turning on post-confession dialogue variants **world-wide** — every region from MQ02 on now knows what the Fool's journey is. |

## Choices & branches

No hard branch; `fires` is unconditional and there is exactly one outcome. The dialogue
choice at the confession (the Fool's answer, first-pick-commits) is flavor only per the
Fool's ≤12-word / one-earnest-option rule — it colors the exchange with Mortimer and gates
nothing: the fight, the unbinding, and `WS_DEATH_UNBOUND` are the same whichever line is
picked.

## Note on CONFESSED

This quest does not carry `[If CONFESSED]` variants of its own — it is the **origin** of
the global `CONFESSED` state (`world.md` §Global states: condition "MQ13 complete"). Every
main quest from MQ02 onward carries variants that assume *this* quest as their source
material; this file is what they are reacting to, not a reaction itself. The Querent's
direct confirmation of the twist here (the confession scene) is the single canonical event
those variants point back to.

## Key NPCs

- **Mortimer** (Death, canon, `characters.md` §XIII; freed name canonical in `GLOSSARY.md`)
  — ally-coded from the first line; the only Arcanum who asks to be fought; the game's
  keystone confession. Everyone else in the marsh calls him "Mortimer" freely throughout;
  **he** never says it of himself, first person, until the unbinding (the name-and-*I*
  finally permitted the moment the office breaks) — that asymmetry is deliberate and load-
  bearing. Hands over Trump XIII — Passage with both hands, asking only "Don't waste it."
- **Old Sallow** (canon, `characters.md` §Recurring named NPCs) — the Stillmarsh's ferry-
  keeper, "nearly done dying" for three centuries; takes no coin for the crossing; gets the
  quest's final beat and its final line, "No rush, mind. I've waited this long."
- **Bettony Marsh** (canon, `characters.md` §Regional named NPCs) — this quest's mourning
  NPC, keeping a generational vigil over her deathless grandfather; left holding relief and
  grief at once, refused a resolution into either.
- **Gaffer Corlin** (canon, `characters.md` §Regional named NPCs) — Bettony's grandfather,
  deathless and bedridden for three centuries; dry to the last. His gentle death days after
  the unbinding, and his posthumous note — "Took you all long enough." — are the game's
  first concrete demonstration of `WS_DEATH_UNBOUND`'s weight.
- **Tarn Loach** (canon, `characters.md` §Regional named NPCs) — Old Sallow's young
  ferryman's mate; hands the Fool the lantern for the ferryman's errand (the doorway to the
  Stillmarsh Calling). His name-ledger is his own side-quest (`SQ-STILLMARSH-01`); this
  quest only borrows his register, not his arc.
- **Gammer Thist and Old Barrow** (new, this quest — ambient vigil-house pair) — two of the
  waiting "dying," carrying a three-century wager over who goes first; the honest laugh in
  the vigil-house, and its honest weight. Promoted here as named ambient walk-ons (per
  `npc-system.md` §Named vs. ambient); flag below.

## Consistency references

- `arcana.md` §XIII. Death (KEYSTONE) — pure-duel design (scythe by candle-light, no adds,
  no arena gimmick, no gimmick at all), difficulty-peak-among-duels intent, the confession
  scene and its **exact** line (*"You are the ending, little Excuse. I am only the door."*),
  Trump XIII — Passage (Past/Present/Future effects), the unbinding-is-release rule (office
  cracks → name returns → Trump handed over; no loot, no death).
- `world.md` §The Stillmarsh (candle-flat wetlands, ferry lanterns, "the world's kindest and
  wariest people," nothing may end); §World-state matrix (`WS_DEATH_UNBOUND`: mortality
  returns, seasons cycle, scripted-only deaths, Stillmarsh empties over days, funerals as
  ambient events, Hollows unlock, CONFESSED activates world-wide); §Global states
  (`CONFESSED`, `ACT_II` Querent steering); §The Fool's Reading (Old Sallow's "Death last of
  the twenty" / "Death in Act I" sequence motifs, used as layer-2 barks); §Hydrology (the
  still water finally allowed to carry the fallen leaves).
- `characters.md` §XIII (Mortimer — kindest person in the game, ally-coded, worn to bone-
  deep exhaustion, the answer to a prayer he stopped believing in); §Recurring named NPCs
  (Old Sallow — wry, unhurried, "nearly done dying," host of the marsh); §Regional named NPCs
  — The Stillmarsh (Bettony Marsh, Gaffer Corlin, Tarn Loach, the Hallow family, Corse
  Millbank); §Pip (Stillmarsh NPCs bow to Pip on sight, instinctive and never explained;
  Pip's constancy through the confession); §The 21 Arcana dialogue rule (bound Arcana never
  put a personal name to their own "I" — Mortimer's withholding until the unbinding).
- `narrative.md` §Premise, §The Twist (the journey ends the world; confirmed here, in full
  knowledge, mid-game), §The Querent (this is the canonical scene where the Querent "stops
  pretending too" — direct confirmation, no joke, no wink), §Act structure (Act II keystone;
  Act I seed of "the region the world refuses to mention" paid off), §Themes (all four:
  endings are a mercy; offices eat people; freedom hurts someone ordinary — Bettony; the
  Fool is nobody, and doors open), §The Fool's Reading (order-sensitive barks), §Dialogue
  style guide (Fool ≤12-word / one-earnest-option lines; melancholy rule — the vigil-house
  laugh, the posthumous note; the Querent's wink deliberately spent nowhere here).
- `callings.md` §The Callings — Ferryman's mate (pole Old Sallow's lantern route; "post-MQ13
  the route means something else, Sallow says so") — the ferryman's errand is the diegetic
  doorway to the Calling.
- `npc-system.md` §Aware-of-Pip (bow-on-sight is scripted, not a bark), §Bark layers
  (sequence/world-state/act pools this quest seeds for the Stillmarsh), §Named vs. ambient
  (Gammer Thist and Old Barrow promoted to named ambient walk-ons).
- `quests/side/SQ-STILLMARSH-01/02/03` — this quest establishes the Stillmarsh's tone and
  Old Sallow's / Tarn Loach's register those side quests build on; it must not (and does
  not) resolve their arcs: the lantern ledger (Tarn), the Hallow family's own death (SQ-02,
  post-unbinding), and Corse Millbank's candle (SQ-03) are referenced only as ambient
  texture here.
- `GLOSSARY.md` — Mortimer, the Excuse, the Stillmarsh, the Shuffle, the Great Reading,
  Trump, Passage, Waystation, the Pocket Spread (canonical spellings).
- `quests/TEMPLATE.md` — script format followed throughout.

## Open questions

- The Fool's confession-answer lines (now drafted against the ≤12-word / one-earnest-option
  rule) resolve the outline's first open question. Confirm at VO/localization pass that all
  three read cleanly aloud and that "first-pick-commits" (rather than exhaustible) is the
  right interaction for a one-shot emotional beat — recommended, but flagged for review.
- The outline recommended spending the Querent's one allowed wink **nowhere** in this quest,
  given the confession's gravity; this script does so (zero winks, and a deliberately quieter
  Querent throughout). Confirm narrative-review sign-off that MQ13 is the intended permanent
  exception to the one-wink-per-quest budget.
- Gaffer Corlin's death (the mourning beat) is written as a scripted, special-cased named-NPC
  death occurring "days later," staged on the Fool's next visit to Bettony's door after
  `WS_DEATH_UNBOUND`. Confirm the trigger: fixed in-game-day count vs. next-visit fire — and
  resolve it **identically** for `SQ-STILLMARSH-02`'s Hallow death, which shares this
  question, so the two deaths pace consistently. (`technical.md` schedules the special-cased
  death, not the general scripted-death system.)
- Gammer Thist and Old Barrow are promoted here to named ambient walk-ons to carry the
  vigil-house laugh. Confirm they should be added to `characters.md` §Regional named NPCs
  (The Stillmarsh) in the same change, or remain quest-local unnamed-in-the-slate figures —
  recommend adding them, as the wager pays off across two scenes (vigil-house and Day One).
- Note (not this quest's to fix): `SQ-STILLMARSH-01` names the ferryman's-mate ledger-keeper
  "Tarn Loach" in beat 1 and its consistency refs, but calls him "Perrin" in beats 2–6 —
  canon (`characters.md`) is **Tarn Loach**, used here. The side-quest doc needs that
  inconsistency corrected in its own change.
