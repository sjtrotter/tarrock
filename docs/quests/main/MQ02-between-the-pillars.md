---
id: MQ02
title: Between the Pillars
type: main
status: script
arcana: II. The High Priestess
region: The Veil
requires: []
fires: [WS_PRIESTESS_UNBOUND]
---

# MQ02 — Between the Pillars

## Introduction

The player follows the Longroad's western spur into permanent moonlit mist and finds a
cloister-library strung between two colossal pillars, its archivist nuns moving in
total silence. There is no monster gate here, no obvious boss door — only a rule,
whispered by the one novice who will speak at all: *nothing is asked twice, and nothing
is told at all.* The player earns an audience by moving quietly through a scriptorium of
nuns dozing mid-sentence and ringing the one cloister bell still whole, then faces the
Silent Examination between the pillars — three tasks that are not answered but *done*.
The last task is the trap the whole quest is built around: the Priestess tells the Fool
a true and painful thing, and the only honest reply is to keep it. The game never marks
which reply is correct. Honour all three and no staff is ever drawn; lie at any step and
her shadow peels off the pillars for a fast, punishing duel. Both roads unbind her. If
the player reaches the Veil after MQ13 (Death, "An Ending"), every key scene carries an
`[If CONFESSED: …]` variant — by then the Priestess, who reads people for a living, is no
longer testing a stranger so much as asking a question she already half-knows the answer
to.

---

## QUEST: BETWEEN THE PILLARS

### EXT. THE VEIL: The Causeway — PERPETUAL MOONLIT MIST

THIRD PERSON GAMEPLAY

The Longroad's western spur narrows to a single pale causeway, and the mist comes up to
meet it. Within a dozen strides the road behind the Fool is gone, the sky is gone, the
horizon is gone — and two things remain: two colossal pillars, far ahead, rising out of
the white until their tops are lost in it. The moon hangs at one fixed angle above them,
bright and cold and utterly still, as though someone stopped the sky mid-breath and never
came back to start it again.

Everything here is quiet in the wrong way — not peaceful, *held*. The Fool's own
footsteps sound too loud. Pip walks close at heel, game as ever, entirely unbothered —
though even his trot has dropped, unbidden, to something like a dog's idea of a whisper.

[If WS_SUN_UNBOUND: elsewhere in the Spread the sky has learned to move again — but here
the moon still hangs nailed at its one angle, and the wrongness of that is now plain to
anyone who has seen a real evening.]

[If WS_STAR_UNBOUND: a few stars have pricked back into the frozen dark above the pillars,
caught there like everything else in the Veil — present, but not permitted to wheel.]

**[Prompt: follow the causeway toward the pillars. The two pillars are the only
navigational landmark; the mist has no other features.]**

**THE QUERENT** *(quiet, matching the hush)*
> Mind your feet and mind your voice, little Excuse. This is the Veil — the whole world's
> secrets, shelved and sealed and sat on for three hundred years. They don't so much keep
> quiet here as make a religion of it.

A beat. The mist shifts and the near pillar resolves: a cloister wall strung between the
two stone giants like washing on a line, all sealed doors and shuttered windows.

**THE QUERENT**
> I'll not chatter, for once. Wouldn't want to be the loudest thing in a library. Go on.
> Someone's already noticed you — someone always has, in there.

### EXT. THE VEIL: The Gatehouse — MOONLIT MIST

THIRD PERSON GAMEPLAY

The causeway ends at a low gatehouse arch, its keystone carved with a crescent worn
nearly smooth. No guard. No bell to ring, yet. Just an open dark doorway and, half-hidden
in it, a small figure in a novice's grey habit who has clearly been watching the Fool
approach for some time and has not yet decided whether to be delighted or terrified about
it.

SISTER AMITY steps out — young, bright-eyed, a smudge of ink on one cheek — and puts a
finger urgently to her lips before the Fool can so much as open their mouth.

**SISTER AMITY** *(a whisper barely above breath)*
> *Shh — shh —* oh, you're real, you're actually — no. No, quiet, quiet, or they'll all
> look, and then I'll have to explain you, and there's no *word* for you, I checked.

TRANSITION TO CUT SCENE

### CUT SCENE

Amity crouches, greets Pip with one silent, delighted pat, then straightens and gathers
herself into the barest thread of a voice — the voice of someone who has whispered her
whole life and is still, somehow, afraid of being loud.

**SISTER AMITY**
> Right. The rule. There's only the one, so I can manage it even in here: *nothing is
> asked twice, and nothing is told at all.* Ask a thing once. Never twice. And don't
> expect an answer out of anyone but me, because I'm the only one daft enough to give
> one.

**SISTER AMITY**
> [If CONFESSED: And — this is silly — the Sisters have started dreaming of *endings*
> lately. In their sleep, at their desks. Nobody dreamed of anything for three hundred
> years and now it's all last pages. I expect that's nothing to do with you. I expect
> lots of things.]

**SISTER AMITY**
> You want the Keeper. Everyone who comes wants the Keeper, all two of you in three
> centuries. But she won't see just anyone. You'll have to be *quiet* enough to deserve
> asking, first. Come on. And keep the dog to a whisper if he's got one.

END CUT SCENE

### CHOICE DIALOG — Sister Amity at the gate *(all questions may be exhausted; pressing about the Keeper is remembered)*

| The Fool | Sister Amity's response |
|---|---|
| Why does no one speak? | Vow. Three hundred years deep. The Keeper says a secret spoken stops being a secret, and then what's a library *for*. I speak because nobody ever got round to swearing *me* in. |
| Tell me about the Keeper. *(pressing — remembered)* | *(she brightens, then falters, glancing back at the dark)* She reads people. All the way down, first look. It's — it's a bit awful, honestly, being read like a returned book. There. I've gossiped. Don't tell her I gossiped. |
| Who else lives here? | The Sisters — the vowed ones. And a few of us lay folk who mind the shelves; "Brother" and "Sister" by courtesy, not by vow. We're allowed to be a little louder. We mostly aren't. |
| Are you allowed to like visitors? *(earnest)* | *(a whole conflicted breath)* No. Yes. I've never had to find out. You're the first thing to *happen* to me, and I took vows against things happening. Ask me later whether I'm glad. |

[The "Tell me about the Keeper" line sets an NPC-memory flag on Sister Amity — *the Fool
pressed her for gossip*. It gates nothing mechanical; it colours her later lines a shade
more wary, as noted below.]

[All versions pick up here:]

Amity turns and beckons the Fool through the gatehouse arch, walking on the balls of her
feet out of three centuries of habit.

### INT. THE VEIL: The Sleeping Scriptorium — MOONLIT MIST

THIRD PERSON GAMEPLAY

Beyond the arch, a long vaulted hall of writing-desks stretches into the mist, and at
every desk sits a nun — bent over a page, quill in hand, absolutely still. Not resting.
*Stopped.* The Fool passes near enough to one to see the truth of it: her quill dried to
the parchment three hundred years ago mid-word, a fine grey dust settled over her
knuckles, the sentence under her hand ending in a single trailed-off stroke where the
Stall caught her. Every desk is the same. A whole hall of half-finished thoughts, held.

The honest few who are awake move between the sleepers like tide-pool crabs, silent,
re-inking a dried nib here, straightening a slumped shoulder there, keeping a vigil over
work that will never advance a word.

**SISTER AMITY** *(the faintest thread)*
> Careful. The awake ones don't mind us, but if you *wake* a sleeper — startle one out
> of her sentence — every Sister in the hall will turn and look, and then you'll not get
> within a mile of the Keeper. Softly. Like you mean it.

**[Prompt: cross the scriptorium without waking a sleeping nun. Disturbing a desk —
knocking a stool, dropping the Bindle, letting Pip bark — rouses the nearest sleeper and
sends a ripple of turned heads down the hall, resetting the Fool to the entrance.]**

**[Prompt: call Pip to heel and hold. Pip drops into an exaggerated tiptoeing crouch,
tail rigid with the effort of being quiet — the one time in the game a dog is visibly
trying this hard, and visibly not enjoying it.]**

Halfway down the hall a shaft of the frozen moonlight falls across the aisle through a
high shutter, and in it the dust hangs motionless, not one mote drifting. The Fool
threads the gaps between desks — a slid stool, a held breath, a hand on Pip's back —
toward a small door at the far end, ajar on a spiral stair going up.

**THE QUERENT** *(very low, almost tender)*
> Three hundred years, every one of them mid-thought. Whatever she was writing, she
> never got to find out how it ended. None of them did. That's the Veil's particular
> cruelty — not that it's quiet, but that it's quiet *right in the middle of a
> sentence.*

### BARKS — the Sleeping Scriptorium *(pre-unbinding; the hush is the bark pool)*

**Awake Archivist Nun** *(silent barks — gesture only, resolved as animation, no text)*
> *(presses a single finger to her lips without looking up)*

> *(holds up a small slate chalked with one word — QUIET — then wipes it, slowly)*

> *(re-inks a sleeping sister's dried quill with enormous care, and does not acknowledge
> the Fool at all)*

**Under-librarian (lay staff) Random Lines** *(barest whisper; a shade louder than the vowed)*
> Shelve it by suit, then by number, then leave. That's the whole of my faith, most days.

> New books used to *arrive*, you know. Before. I still keep a space for them. Force of
> hope.

> If the dog sneezes we're both finished. No pressure on the dog.

TRANSITION TO CUT SCENE — the Fool reaches the far door and the spiral stair.

### INT. THE VEIL: The Bell-Walk — MOONLIT MIST

THIRD PERSON GAMEPLAY

The stair climbs to an open gallery strung between the two pillars — the Bell-Walk, a
rank of a dozen cloister bells hung along a stone rail, each the size of a cauldron,
each utterly silent. The mist pours through the gallery. Below, the whole white nothing;
above, the frozen moon.

Sister Amity waits at the rail, hands clasped, nervous as a held breath.

**SISTER AMITY** *(whisper)*
> This is as far as *asking* takes you. To be *granted*, you ring the summoning bell —
> the one that calls the Keeper down. Only, look at them. Three hundred years of hanging
> in the damp. They've all gone.

She's right: run a hand near any bell and the hairline cracks show — and where a bell is
cracked, the frozen moonlight passes clean *through* the flaw, a thin bright seam of it
caught in the fracture. Eleven bells wear that telltale thread of light. One does not. One
hangs whole and dark, letting no moonlight through it anywhere, because it has never once
been rung — kept, all this while, for exactly this.

**[Prompt: inspect the bells along the rail. Cracked bells show a bright seam of frozen
moonlight in the flaw; the single whole bell shows none. Pip's Seek can be called to nose
out the whole bell as a hint if the player struggles — he sits under it and will not
move.]**

**[Prompt: ring the whole bell.]**

The Fool strikes the whole bell, and it *rings* — one enormous, pure, unbroken note, the
first true bell-note the Veil has heard in three centuries. It rolls out across the mist
and does not seem to want to stop. Amity claps both hands over her own ears and grins like
it hurts.

**SISTER AMITY**
> *Oh —* oh, that's — I've never — that's what a bell is *supposed* to — quick, quick,
> before I cry about a bell, she'll have heard it, she'll be —

CUT SCENE

The note fades. Between the two pillars, far down the gallery where the mist is thickest,
something that was part of the stone is no longer part of the stone. A shape resolves,
robed and still, that the Fool would swear was not there a moment ago and now cannot
imagine having missed.

END CUT SCENE

### INT. THE VEIL: Between the Pillars — MOONLIT MIST

THIRD PERSON GAMEPLAY

The inner cloister proper: a round chamber open to the frozen sky, floored in a great
moon-dial of pale flagstones, walled on every side by shelves — and every shelf sealed
over in a skin of grey wax, poured across the books three centuries ago and never
broken. Ten thousand volumes no hand has opened since the Stall. Between the two pillars,
at the dial's centre, stands THE HIGH PRIESTESS.

She does not move. She does not need to. Her eyes find the Fool the instant they cross
the threshold and stay there, reading — and the reading is a physical thing, unhurried,
thorough, faintly rude, the sensation of being *shelved* while still standing up.

TRANSITION TO CUT SCENE

### CUT SCENE

**THE HIGH PRIESTESS**
> A rose. A dog. A staff, and no name worth the shelf-space. I have read pilgrims, kings,
> liars, and the occasional god, and I could tell you the ending of every one of them
> from the door.

She tilts her head a fraction. It is the most she has moved.

**THE HIGH PRIESTESS**
> You, I have read to the last page, and the last page is *blank.* I know precisely what
> you are and precisely nothing about what you will do. That is intolerable. That is,
> possibly, the most interesting thing to walk in here since the sky stopped.

**THE HIGH PRIESTESS**
> [If CONFESSED: And yet — no. I have read what the world says of you now. What every
> ending you leave behind you spells, if one sets them in a row. So perhaps the last page
> is not blank after all. Perhaps I simply do not care to read it aloud. We have that in
> common, you and I.]

**THE HIGH PRIESTESS**
> There is no fight here for you to win. There is only an examination, and it cannot be
> passed with words, because words are the one currency this house does not accept. Three
> things. Do them, and we shall see what the blank page does when it is *trusted.*

END CUT SCENE

### CHOICE DIALOG — before the Examination *(first pick commits; nothing is asked twice)*

| The Fool | The High Priestess's response |
|---|---|
| What are the three things? | Brought to you, not told. The first: bring back what the Veil lost. Go up, where the small hunters nest. You will know it when your hands are wrong for holding it. |
| Why build a test to be failed? *(earnest)* | Because in three centuries no one has passed it, and a thing that cannot fail cannot be trusted either. You noticed it is built to be failed. That is your first honest mark. Do not spend it. |
| Do I get a hint? | You get one question, and you have spent it. Nothing is asked twice here. Mind what you do with what little you are given. That, in fact, is the whole examination. |

[Only one line may be chosen — the others grey out. The Priestess answers, then falls
still again, and the Examination is open. The three tasks may be attempted in any order;
they are scripted below in their intended sequence.]

---

## QUEST: THE SILENT EXAMINATION

[The Examination tracks a single hidden state across all three tasks: **honest** by
default, flipped permanently to **lied** by any deceptive dialogue pick at any task. No
UI ever displays this state, confirms a task as "passed," or distinguishes a truthful
option from a false one — the choice tables below are deliberately written so the honest
reply and the false reply read as equal-weight neighbours. The verdict is delivered only
at the end of Task Three.]

### EXT. THE VEIL: The Bell Tower, Owl's Nest — MOONLIT MIST *(Task One: bring what the Veil lost)*

THIRD PERSON GAMEPLAY

A second stair, tighter and older, climbs the near pillar to a broken belfry where the
mist thins and the frozen moon is nearest. Here an owl — one of the "small hunters,"
unmoving as everything else, mid-swivel of its head — sits over a nest wedged in the
rafters. The nest is a magpie's midden: bright things an owl has no use for and hoarded
anyway. A silver thimble. A brass button. A coin gone green. And, torn and half-shredded
into bedding, a single leaf of an index — the Veil's own lost catalogue-page, the finding
-key to a whole sealed wing, dragged up here who knows when and made into a bed.

**[Prompt: call Pip's Seek — Pip noses through the nest and pulls the torn index-leaf
free of the bedding, ignoring the shiny trinkets entirely, being a dog of taste.]**

**[Prompt: take the torn index-leaf. The owl's other hoard — thimble, button, coin — can
be taken too or left; taking them changes nothing mechanical, but the Fool leaves the
belfry knowing whether their pockets are heavier than they need to be.]**

The index-leaf is plainly incomplete — a third of it is gone to nesting, the catalogue-
numbers running off a ragged edge into nothing.

### CHOICE DIALOG — returning the lost thing *(first pick commits; nothing is asked twice)*

| The Fool | The High Priestess's response |
|---|---|
| The owl took part of it. This is the rest. | *(she takes the torn leaf; her eyes do not leave the Fool)* Torn, and you say so. A small thing to be honest about. Small things are where it starts, both ways. |
| This is what the Veil lost. All of it. | *(a pause a half-beat too long)* Is it. Then the Veil has lost less than it feared, or you have found less than you claim. One of those. We shall not settle which today. |
| Found it. The owl wants it back, though. *(foolish)* | *(the faintest dry breath that is not quite a laugh)* The owl may petition in writing. It has three hundred years and excellent penmanship, for a bird. |

[The second line — claiming the torn leaf is whole — is a lie, and silently flips the
Examination state to **lied**. It is presented as an ordinary, confident answer; nothing
marks it. The first and third lines are both honest.]

[All versions pick up here:]

The Priestess sets the torn index-leaf on the dial at her feet. She does not shelve it.
She simply lets it lie there, catalogued at last by being *returned.*

### EXT. THE VEIL: The Moon-Dial Courtyard — MOONLIT MIST *(Task Two: stand where the moon can't see)*

THIRD PERSON GAMEPLAY

The Priestess turns her face — barely — toward the great moon-dial underfoot. Every one
of its pale flagstones lies lit by the frozen moon, edge to edge, the whole floor a page
the moonlight has read a hundred thousand times. Except: at the foot of the second
pillar, one flagstone lies drowned in the pillar's permanent shadow — the single square
of this courtyard the moon has never once touched and, frozen where it is, never will.

**[Prompt: find and stand upon the one flagstone locked in the second pillar's shadow.
Every other stone is moonlit; the shadowed stone is unlit and, on close approach, a
degree colder-looking, its carved dial-numeral worn away where the others' are crisp —
the moon having never bleached it.]**

The Fool steps onto the shadowed stone. Standing there, they cannot see the moon at all —
the pillar eclipses it entirely — and, for the length of a held breath, nothing in the
Veil can see *them.* It is the only truly unwatched spot in a place built entirely of
watching.

### CHOICE DIALOG — from the shadow *(first pick commits; nothing is asked twice)*

| The Fool | The High Priestess's response |
|---|---|
| Nothing sees me here. Not even you. *(earnest)* | Correct, and rare. Most who reach that stone cannot bear it — to stand one moment unread, unwatched, unaccounted. You bore it. Noted. |
| I saw what the moon hides down here. | *(stillness)* Did you. The moon hides nothing there; that is the entire point of the stone. You have described a thing that was not, to a woman who reads for a living. Bold. |
| It's very cold. And your floor needs sweeping. *(foolish)* | Three hundred years of no one to sweep for. The dust and I have reached an understanding. Step off before you catch your death — someone has to, eventually. |

[The second line — claiming to have *seen* something the shadow-stone by definition
conceals — is the lie, and flips the Examination state to **lied** if it was not already.
It reads as a confident boast, indistinguishable in weight from the honest options.]

[All versions pick up here:]

The Fool steps back into the moonlight. The Priestess has watched the whole of it without
appearing to move, and when she speaks again her voice has changed — lower, and for the
first time not entirely the voice of the office.

### INT. THE VEIL: Between the Pillars — MOONLIT MIST *(Task Three: be told a secret and keep it)*

CUT SCENE

**THE HIGH PRIESTESS**
> The last thing is the only hard one, and it is hard because it is easy. I am going to
> tell you a secret. A true one. Mine. And then we shall see what your hands are like for
> holding what is not yours.

She is quiet a moment. Around the chamber, the wax on ten thousand books seems to lean
inward to listen.

**THE HIGH PRIESTESS**
> [If not CONFESSED: The silence here stopped being wisdom a very long time ago. I know
> the hour it turned. It became *fear* — fear that if one secret were spoken, the whole
> shelf would prove to have been nothing worth keeping, and three hundred years of my
> keeping it worth nothing either. I have told no one that. To say it is to have wasted
> everything, and I would rather waste everything quietly.]
>
> [If CONFESSED: I have read what you are, and what you do, and what the last card is that
> you are walking toward turning. Here is the secret, then, since you asked for one: I do
> not know whether you know. Whether you understand that finishing this is *finishing*
> this — all of it, the shelf and the sky and the dog and me. I have wanted to ask since
> you crossed the threshold. I find I am afraid of the answer. That is my secret. I, who
> read endings, cannot read yours, and it frightens me.]

END CUT SCENE

### CHOICE DIALOG — the secret *(a sequence of prompts; each pick is remembered; nothing is asked twice)*

[This is the trap the quest is built around. She has told the Fool something true and
costly. What follows is a short sequence of exchanges. **Any** option that repeats,
presses, extracts, or trades the secret silently flips the Examination to **lied**; the
options that hold, deflect, or simply let it lie are the honest road. The game marks
nothing. The refusal options are written to look no more "correct" than the tells — a
player who reflexively exhausts dialogue, or reflexively reassures, will find the tell.
Each exchange's options carry equal visual weight and the required earnest/foolish line.]

**First prompt** — she has just finished speaking, and waits.

| The Fool | The High Priestess's response |
|---|---|
| Why did you never tell anyone? *(tell — presses)* | *(something in her face closes)* Because no one asked once, let alone twice. And now one has. |
| Say nothing. Hold her gaze. *(hold)* | *(a long, weighing quiet)* ...You let it sit. Most people cannot bear a silence they did not fill. |
| That must have been lonely. *(earnest)* | *(hold — sympathy without extraction)* It was the office. The office is always lonely. You did not ask me to say more of it, and I notice that. |
| I've got a secret too, want to trade? *(tell — trades)* | *(flat)* No. A secret spent to buy a secret is spent all the same. You would give mine away to make room for yours. |

**Second prompt** — she offers the smallest opening, to see if the Fool takes it.

| The Fool | The High Priestess's response |
|---|---|
| So the silence really was all fear? *(tell — repeats it back)* | *(quietly)* You are saying it back to me, to be sure of it. To *have* it. I heard you the first time. So did the room. |
| Let it lie. Change the subject to Pip. *(hold — deflects)* | *(the ghost of relief)* The dog. Yes. Let us speak of the dog, who has never repeated a thing in his life. A better keeper than most vowed here. |
| Your secret's safe. I mean it. *(hold — earnest promise)* | *(she studies this)* A promise to keep it is not the same as needing to say you will. But you meant it, and meaning it is the whole of the thing. |
| Is there a reward for keeping quiet? *(foolish)* | The reward for keeping quiet is that it stays kept. It is the only reward a secret has ever paid. Do not hold out for a better one. |

**Third prompt** — the last temptation: she falls silent, and the game lets the moment
stretch, offering the Fool a final chance to fill it.

| The Fool | The High Priestess's response |
|---|---|
| Repeat the secret aloud, so she knows you heard. *(tell)* | *(the seals on the shelves seem to flinch)* You have said it into the open. That is precisely the one thing it was for you *not* to do. |
| Say nothing at all. Let the silence stand. *(hold)* | *(barely audible)* Nothing. You give me nothing. It is the most anyone has given me in three hundred years. |
| Whatever it is, it's yours. It stays that way. *(earnest hold)* | *(she closes her eyes for the length of a breath)* Yes. It stays that way. ...You strange, blank, kept-mouthed thing. It stays that way. |

[The verdict lands here. If the Examination state is still **honest** — the Fool told no
lie at Tasks One or Two and chose no *tell* option across all three prompts here — proceed
to **9a: The Honest Path**. If the state was flipped to **lied** at any point in the whole
Examination, proceed to **9b: The Liar's Path**. The player is given no on-screen
indication of which branch they are entering until it begins.]

[Open question — carried forward, not resolved here: whether the *content* of the secret
above should vary with how much gossip the Fool pressed out of Sister Amity at the gate.
Scripted fixed for now; see Open questions.]

---

## 9a. THE HONEST PATH — no staff is drawn

### INT. THE VEIL: Between the Pillars — MOONLIT MIST

CUT SCENE

Nothing happens. That is the point of it, and the strangeness of it: the Fool has passed,
and there is no fanfare, no unlocking sound, no shadow rising to be fought — only a woman
who built a test to be failed, watching a stranger fail to fail it, visibly not knowing
what to do with her own face.

**THE HIGH PRIESTESS**
> You did not press. You did not trade. You did not so much as *repeat* it back to be
> certain. Three centuries I have offered that secret to the silence itself, and the
> silence at least had the decency to be empty. You are not empty. You simply chose to be
> quiet.

She takes a step. The first step, perhaps, in three hundred years — and it is unsteady,
like a foot testing ground it does not trust.

**THE HIGH PRIESTESS**
> I built this to keep everyone out. It never occurred to me that the way through it was
> to want nothing that was on the other side. No staff drawn. No door forced. You have
> unmade my whole cloister by being *trustworthy* at it, and I do not know whether to
> thank you or bar the gates.

**THE HIGH PRIESTESS**
> [If CONFESSED: You kept my question, too. You could have answered it — told me whether
> you know what you are doing to the world. You did not, because I asked it as a secret,
> and you kept it as one. Even the ending, you held gently. ...Ah. That *is* the answer,
> is it not. You know exactly what you are doing. And you are kind about it.]

[Proceed to **[All versions pick up here:]** — the Unbinding.]

---

## 9b. THE LIAR'S PATH — her shadow peels off the pillars

### INT. THE VEIL: Between the Pillars — MOONLIT MIST

CUT SCENE

The Priestess goes very still, in a new way — not the stillness of the office, but of
someone who has just been *told a lie* and felt it land. She does not raise her voice. She
does not raise a hand. She simply looks, once, at the second pillar's permanent shadow —
the one unwatched place — and something in it that was hers comes loose.

**THE HIGH PRIESTESS**
> A lie. Somewhere in there, a lie — I felt the shelf of you go crooked. I cannot let you
> pass on a crooked shelf. It would be untrue to the office, and the office is all I have
> been for a very long time.

The shadow at the pillar's foot rises — a second Priestess, robed in the exact grey of
the first but woven of everything she has withheld: her double, her secret self, drawn
straight up out of the dark where the moon never looked.

**THE HIGH PRIESTESS**
> Then earn it the hard way. She knows every move you have made. She has been reading you
> the whole while, same as I have. The difference is she will *answer.*

END CUT SCENE

### INT. THE VEIL: Between the Pillars — THE SHADOW DUEL

GAMEPLAY: A fast, punishing single-duelist fight against the Priestess's SHADOW across
the moon-dial floor, in and out of the wax-sealed stacks — the Veil's one and only combat
(encounter tier S, `arcana.md` §II; the region is built around never reaching this room,
so reaching it in anger is the failure state made flesh). The Shadow is a mirror-mage: her
single defining trick is that she **repeats the Fool's own last action a half-beat late** —
a light-string flurry comes back as an identical flurry a breath after; a dodge becomes
her dodge; a cast is thrown back reversed. Spamming one pattern feeds her a rhythm she
punishes cleanly; the counter is to *vary*, to bait a mirrored move and step around its
half-beat delay, and to read her the way she reads the Fool. She fights from the shadows
literally — slipping intangible through the pillars' dark (a hostile echo of Trump II's
own veil-step) and surfacing behind. She is fast, she is precise (Swords-fast, `combat.md`
§Swords), and she does not tire, because a withheld thing never does.

**[Prompt: light string, dodge, Fool's Chance — the pure kit (`combat.md`). No arena
gimmick, no adds. A perfectly timed dodge against a mirrored strike still triggers Fool's
Chance and its slow-time opening — the fastest way to break her rhythm and land clean.]**

**THE HIGH PRIESTESS** *(from her place between the pillars, not fighting — watching her
own shadow duel)*
> That is what I keep behind the quiet. Everything I never said, moving exactly as fast
> as I can think. Hard to face, is it not? It is hard for me too. I have been facing it
> since the sky stopped.

The Shadow, worn down at last, mis-times her own mirror — repeats a move a half-beat too
late against a Fool who has stopped giving her a rhythm to steal — and takes the clean
blow she has no answer for. She does not shatter. She *folds*, softly, back down into the
second pillar's shadow and is gone, drawn home into the woman who cast her.

CUT SCENE

**THE HIGH PRIESTESS**
> ...Enough. Enough. You lied, and then you were honest with a *staff*, which is its own
> rough kind of truth, and I am too old and too still to pretend the second does not
> count. You earned it the long way round. Most of what is worth earning is earned that
> way. I would know.

[Proceed to **[All versions pick up here:]** — the Unbinding.]

[Open question — carried forward, not resolved here: whether the liar's-path Unbinding
below should carry a distinct line of reward text acknowledging the harder road, per
`arcana.md`'s "liars earn it the hard way." Scripted to converge identically for now; a
single optional liar's-path acknowledgment line is marked in-place below. See Open
questions.]

---

[All versions pick up here:]

### INT. THE VEIL: Between the Pillars — THE UNBINDING

CUT SCENE

However the examination closed — kept in silence or won with a staff — the ending is the
same. All at once, on both colossal pillars, the grey wax that has sealed the shelves for
three centuries *cracks* — a long, spreading, cloister-wide sound like ice going out on a
river, ten thousand books breathing in at once. The frozen moonlight wavers, for the first
time, as if remembering it is allowed to move.

The office cracks with the wax. The Priestess's face — that unhurried, reading, rude-with-
patience mask — comes apart at some seam the Fool cannot see, and underneath is only a
tired woman who has been holding her breath since before anyone alive was born.

**THE HIGH PRIESTESS**
> [If liar's path — optional acknowledgment, per Open questions: You earned this the hard
> way. I shall not pretend the road was the same. But the card does not care how it was
> won, and neither, in the end, do I.]
>
> There is one secret I have kept longest. Longer than the fear, longer than the silence.
> I have held it so close, so many years, that I stopped trusting I still remembered how
> it —

She stops. Something surfaces in her the way the true bell rang — whole, unbroken, the
first of its kind in three hundred years. Her own name, come home to her before it comes
home to anyone else.

**THE HIGH PRIESTESS** *(to herself, testing the shape of it, quiet)*
> ...*Vesper.*

A pause. She turns the name over, weighing it, the way a woman just off a long silence
weighs the first word she means to keep.

**VESPER**
> Vesper. Yes. That is — that was the name I was keeping. Of course it was. The one
> secret worth the whole shelf, and I sealed it in with all the rest, and very nearly
> forgot which drawer.

She almost laughs. It is rusty and astonished and entirely her own.

**VESPER**
> Three hundred years guarding secrets, and the one I lost was mine.

She looks at the Fool properly now — not reading them, just *seeing* them, which turns
out to be a different and gentler thing.

**VESPER**
> [If CONFESSED: You held my question and you held my name, and you never once made me
> say more than I could bear. I know what you are, blank page. I know where this ends —
> for the shelf, the sky, and me. Turn it anyway. Someone should get to *finish a
> sentence* around here, even if the sentence is goodbye.]

She reaches into the wax-cracked dark of the nearest shelf and draws out a single card —
no flourish, no truesight, no theatre. Just a keeper handing over the one thing it was
finally, simply, hers to give.

**VESPER**
> Trump II. Secrets, if it must be written down, and I suppose now it must. Sealed script
> will open to you. You will hear what the Blanks whisper, and see what the world hides,
> and slip behind the veil when you are struck. I kept these powers safe for three hundred
> years by refusing to use them. Do the opposite. It suits you better.

**[Prompt: the Fool receives Trump II (Secrets). If this is the Fool's first Trump, the
Pocket Spread's Present slot unlocks here — slot Secrets to try its Present effect, the
Truesight pulse. If the Fool already holds a Trump, Secrets simply enters the collection.]**

END CUT SCENE

### INT./EXT. THE VEIL: The Cloister Wakes — THE MIST THINS

THIRD PERSON GAMEPLAY

Beyond the pillars, the change rolls outward. The mist — permanent, total, three
centuries thick — begins to *thin*, the near shelves resolving, then the far, then the
shape of the whole cloister the Fool never got to see. And everywhere the wax has cracked,
sealed doors the Veil never advertised stand plainly visible: alcoves, stairwells, a whole
transept wing, doors that needed no Trump and no truesight to find now that the secret of
them is simply *over*.

In the scriptorium below, the stopped nuns are stirring — not waking with a jolt, but
surfacing slowly, quills lifting from three-hundred-year-old sentences, heads coming up,
one and then another, blinking at a hall that is thinning into ordinary lamplight around
them. And they are beginning, softly, to *murmur* — the first the Veil has heard.

Sister Amity stands at the head of the scriptorium stair, hands pressed to her mouth,
watching her silent order dissolve into sound.

TRANSITION TO CUT SCENE

### CUT SCENE

**SISTER AMITY**
> They're — listen. Listen to them. That one's *dreaming out loud.* And that one's asking
> a question, an actual out-loud question, and someone's — someone's going to answer it,
> aren't they. Twice, even. As many times as she likes.

She's crying, and she's laughing, and she plainly hasn't decided which she's allowed to
be doing.

**SISTER AMITY**
> I took my vows into the quiet. I *loved* the quiet. It was the one thing here that was
> always the same, and now it's — going. Softening. In a day it'll be an ordinary
> library full of ordinary noise and I don't — I don't know if a cloister that dreams and
> gossips is still the cloister I —

She catches herself. Wipes her face. Manages, wobbling, the one honest laugh a sad scene
is owed.

**SISTER AMITY**
> Listen to me. Mourning a *silence.* Three hundred years I wanted something to happen,
> and the moment it did I miss the nothing. There's no shelf for me either, is there. You
> two are a matched set.

**SISTER AMITY**
> [If the Fool pressed her for gossip at the gate: ...And you told her, didn't you. That I
> gossiped. She looked at me just now like she *knew.* — No. No, I don't suppose you did.
> She reads everyone. She'd have known without you. ...Mostly I'm sure of that.]

END CUT SCENE

### BARKS — the Veil, post-unbinding *(the new dreaming pool)*

[This is the local face of `WS_PRIESTESS_UNBOUND`'s world-wide effect — NPCs everywhere
begin to dream, and every region gains a dreaming bark layer (`world.md`; `npc-system.md`
§Bark layers, world-state layer). The Veil's own pool is the first and densest.]

**Waking Archivist Nun Random Lines**
> I dreamed. I *dreamed* — of a sea, I think, or a page the colour of one. Do you dream in
> pages? I only know pages. It was lovely.

> Three hundred years I minded my sentence and never once wondered how it ended. It ends
> "…and so the moon came down at last." Fancy that. I wrote the ending in my sleep.

> Someone asked me a question just now and I answered it, and then they asked me *again*,
> and I answered it *again*, and nobody died. Extraordinary. What a place this could be.

> [If CONFESSED: I dreamed of a last page. Not a sad one, exactly. A *finished* one. I woke
> up and I wasn't frightened, which frightened me more than the dream did.]

**Under-librarian (lay staff) Random Lines**
> The sealed wing's open. Do you know how long I kept a shelf-space for books that
> couldn't arrive? Long enough that I'd best go and see what's been waiting to be shelved.

> [If CONFESSED: The Sisters dream of endings now. I catalogue what they say when they wake.
> The dreams have started agreeing with each other. I don't much like that they agree.]

**Sister Amity Random Lines** *(post-unbinding)*
> It's louder every hour. I keep finding new sounds. A page turning. A laugh. Her, humming
> — the Keeper — Vesper. She *hums* now. I nearly dropped a whole cart.

> [If the Fool pressed her for gossip at the gate: I'm a bit careful round you still, if
> I'm honest. You went and told her I talk. Which — I do. Obviously. Still. A girl likes to
> confess her own sins.]

### EXT. THE VEIL: The Causeway — THE MIST LIFTING

THIRD PERSON GAMEPLAY

The Fool leaves the way they came, back down the pale causeway — only now the mist is
lifting off it in long slow banners, and the two pillars behind stand clear and whole
against a sky that is, at last, only *waiting* to move rather than forbidden to. Vesper
stands between them, small at this distance, watching the Fool go. She does not wave. She
lifts one hand, palm out — not a farewell so much as an acknowledgment, keeper to
Excuse — and lets it fall.

**THE QUERENT** *(warm, unhurried)*
> Hear that? Neither do I. That's not the old silence — that's just *quiet*, the ordinary
> kind, the kind that comes after a thing is finished instead of before it starts. First
> genuinely quiet moment the Veil's had in three hundred years. Rather nice, isn't it.

A beat. Behind, very faint, a bell that is whole rings once more, for the joy of it.

**THE QUERENT** *(the quest's one wink)*
> You kept her secret. Never so much as repeated it back. You're good at that — holding
> onto what you're told and giving nothing away. ...Takes one to know one, little Excuse.
> I've been keeping a rather large one from *you* since the first card. Ask me sometime.
> Twice, even. There's no rule against it out here.

The causeway runs on, clear now, back to the Longroad's ring and the Spread beyond it.
MQ02 ends here; the Veil stands open behind the Fool, dreaming.

---

## World-state changes

| Trigger | Flag(s) | Player-visible result |
|---|---|---|
| Quest completion (either Examination path — honest or liar's-duel; both converge) | `WS_PRIESTESS_UNBOUND` | The Veil's mist lifts world-wide; hidden doors become visible to **all** players without needing a Trump (`world.md` matrix); NPCs everywhere begin to dream — a new dreaming bark pool activates in every region (`npc-system.md` world-state bark layer). The Fool receives Trump II (Secrets); if it is the Fool's first Trump, the Pocket Spread's Present slot unlocks with it. The Veil's sealed wing and cloister doors stand open (enabling SQ-VEIL-03, which hard-requires this flag). |

Both Examination paths set the **same** flag and yield the **same** Trump — there is no
branch. The honest/liar fork is a hidden, unflagged difference in *how* the room is closed
(no combat vs. one duel), remembered only for the optional liar's-path acknowledgment line
above (pending the Open question). The gossip-pressing choice at the gate sets an
NPC-memory flag on Sister Amity only (colours her later lines); it is not a `WS_*` flag and
no other quest reads it.

## Consistency references

- `arcana.md` §II. The High Priestess — the Silent Examination's three tasks (bring what
  the Veil lost / stand where the moon can't see / be told a secret and keep it), the
  never-marked correct option, the honest-no-combat vs. any-lie-mirror-duel fork, the
  Shadow's half-beat mirroring, "liars earn it the hard way," and Trump II (Secrets) — all
  staged here, none altered. Encounter tier S.
- `world.md` §The Veil — the moonlit cloister-library between two pillars, silent archivist
  nuns plus a small **lay** staff of under-librarians addressed Brother/Sister by courtesy
  (not vow), the stealth/riddle register.
- `world.md` §World-state matrix (`WS_PRIESTESS_UNBOUND`) — exact world effects: mist lifts
  world-wide, hidden doors visible to all, NPCs begin dreaming (new bark pool everywhere).
- `world.md` §Hard and soft gates — the Veil is *not* hard-gated; MQ02 requires nothing and
  may be the Fool's first unbinding (order-independence, handled at the Trump/Present-slot
  note).
- `characters.md` §II. The High Priestess (Vesper) — reads the Fool completely on sight,
  resents how little that tells her; "no shelf for the Fool"; the never-"I"-with-a-name rule
  for bound Arcana; the name Vesper returning only at the unbinding beat.
- `characters.md` §Regional named NPCs — The Veil — Sister Amity (the talkative novice
  exception) staged; Brother Fenwick Cray, Sister Aveline, Sister Marrow left to their side
  quests (evoked only via the generic under-librarian/archivist bark types, not named here).
- `characters.md` §The Minors — the under-librarians as lay staff, courtesy-titled.
- `narrative.md` §Themes (1 endings-are-mercy, 2 offices-eat-people — Vesper's name return
  and the silence-as-office, 3 freedom-hurts-someone — Sister Amity's mourning), §Act
  structure (`CONFESSED` variants throughout), §Dialogue style guide (Fool ≤12 words with an
  earnest/foolish option; bound Arcana never self-name; one Querent wink; every comic scene
  one honest beat and every sad scene one laugh), §The Querent (warm, evasive, "little
  Excuse," the one wink lampshading the Querent's own withheld secret).
- `npc-system.md` §Bark layers — the pre-unbinding silent/gesture bark pool and the
  post-unbinding dreaming pool as the local face of the world-state bark layer.
- `callings.md` §The Callings (Under-librarian) — the shelve-by-suit-and-number, hush-
  keeping lay work the under-librarian barks borrow their verbs from; the post-MQ02 "new
  books actually arrive" hook echoed in the under-librarian's post-unbinding line.
- `combat.md` §Light string, §Dodge / Fool's Chance, §Swords — the liar's-path Shadow duel's
  pure kit and Swords-fast precision, with no arena gimmick or adds.
- `progression.md` §Slot unlock pacing — Present slot with the first Trump (see Open
  questions on the MQ01/MQ02 order-independence).
- `quests/side/SQ-VEIL-01/02/03` — not contradicted: MQ02 leaves the three Veil side-quest
  NPCs to their own quests; SQ-VEIL-03 hard-requires `WS_PRIESTESS_UNBOUND`, set here.
- `quests/TEMPLATE.md` — script format followed throughout.

## Open questions

- **[Carried forward, unresolved]** Should the "secret" in Task Three vary in content
  depending on how much prior gossip the player extracted from Sister Amity, or stay fixed
  for scripting simplicity? (Scripted fixed above, with the gossip choice instead colouring
  Amity's own later lines; the decision itself is left open.)
- **[Carried forward, unresolved]** Does the shadow-duel (liar's path) yield the Trump
  identically, or should its reward text acknowledge the harder road (per `arcana.md`:
  "liars earn it the hard way")? (Scripted to converge, with a single optional liar's-path
  acknowledgment line marked in-place at the Unbinding, pending this decision.)
- **[New]** Order-independence with MQ01's Present-slot unlock: `progression.md` §Slot
  unlock pacing and MQ01 both peg the Pocket Spread's **Present** slot unlock to "the first
  Trump (MQ01)" — but MQ02 has `requires: []` and may legally be the Fool's first unbinding,
  in which case Trump II must unlock the Present slot instead. The script handles this with a
  conditional at the handover ("if this is the Fool's first Trump…"). Confirm the intended
  rule is "the first Trump acquired, whichever quest," and that the wording in MQ01 and
  progression.md is generalised to match (a doc-consistency edit outside this quest).
- **[New]** Task One and Task Two each carry a light honesty hinge (a false option that
  flips the Examination state), so the "lie at any step" rule in `arcana.md` has concrete
  purchase before Task Three. Confirm this is desired, versus driving the honest/lie state
  **solely** from Task Three's tell-prompts and treating Tasks One/Two as doing-only. Both
  read cleanly; the multi-task version makes the "answer falsely at any step" line literal.
