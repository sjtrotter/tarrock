class_name Speakers
extends RefCounted

## Who is allowed to say a line, as constants.
##
## HAND-AUTHORED, and deliberately short: an id lands here the first time a graph
## gives that character a line, and every character is one `docs/design/characters.md`
## already names. Code never types a speaker id - it names one of these
## (`docs/design/technical.md` §Architecture principles (Godot), no magic strings).
##
## **Pip is not here and never will be.** `characters.md` §Pip: "Never speaks, never
## explained. No bark-subtitle gimmicks, no inner monologue." There is no id to give
## him a line with, and a test asserts no graph tries.

## The narrator-guide voice, present from the game's first line and never seen
## (`characters.md` §The Querent).
const QUERENT := &"QUERENT"

## The Fool, whose lines the player picks and who then says them
## (`docs/design/narrative.md` §Dialogue style guide: "voiced by choice, not
## monologue").
const FOOL := &"FOOL"

## A Page of Wands, the Prestige's carnival barker, and the first friendly face after
## the tutorial (`characters.md` §Recurring named NPCs).
const FLICK := &"FLICK"

## Every speaker any authored graph uses, for tests and tooling.
const ALL: Array[StringName] = [
	QUERENT,
	FOOL,
	FLICK,
]

## The prefix every speaker's display-name key carries.
const NAME_KEY_PREFIX := "SPEAKER_"


## This speaker's display name as a translation key, e.g. `&"SPEAKER_QUERENT"`.
##
## Names are display text like any other, so they are keys and the English lives in
## the localization CSV (`docs/design/technical.md` §Localization). An id nobody
## declared still yields a key, which shows on screen as itself - loud, not blank,
## exactly as a missing key should look.
static func name_key(speaker_id: StringName) -> StringName:
	return StringName(NAME_KEY_PREFIX + String(speaker_id))
