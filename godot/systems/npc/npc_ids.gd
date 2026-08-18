class_name NpcIds
extends RefCounted

## Every NAMED NPC the game knows, as a constant.
##
## HAND-AUTHORED from `docs/design/characters.md` §Recurring named NPCs - the nine
## people that section makes canon - and not generated: the section is prose bullets
## with the character in the sentence, and a parser turning "a Page of Wands, carnival
## barker at the Prestige" into a suit, a rank and a home region would be reading, not
## parsing. The profiles under `res://data/npc/profiles/` carry that reading, one
## `doc_ref` per person, and a reviewer checks them against the bullets.
##
## Code never types an NPC id: it names one of these, or reads an id off an
## `NpcProfile` (`docs/design/technical.md`, no magic strings). AMBIENT Minors are
## deliberately absent - they have no ids and no memory, and are read "by visible suit
## + Court rank" (`npc-system.md` §Named vs. ambient NPCs).
##
## **PIP IS NOT HERE, AND NEVER WILL BE.** `characters.md` §Pip: "Never speaks, never
## explained... no bark-subtitle gimmicks", and `npc-system.md` §Aware-of-Pip: "Pip
## never answers, in dialogue or bark - that silence is the character rule and the bark
## system must never manufacture a line that breaks it." The rule is kept structurally
## rather than by discipline: there is no Pip id to put in a bark's `speaker_id`, and
## `BarkDefinition.SpeakerKind` has no member that could carry one.
## `bark_definition_test.gd` asserts both (`test_speaker_kind_has_no_pip_member`,
## `test_no_named_npc_id_is_pip`) and `npc_data_test.gd` asserts it again of the
## shipped profile catalog, so the day somebody adds one the suite goes red.
##
## The Querent is not here either, for a different reason: the Querent is not an NPC
## (`characters.md` §The Querent - "the unseen narrator-guide voice"). A Querent line
## is spoken by `BarkDefinition.SpeakerKind.QUERENT` and names no person.

## The Prestige's carnival barker, a Page of Wands, "the first friendly face the Fool
## meets after the tutorial".
const FLICK := &"FLICK"

## The Troupe's juggler, who "has thrown the same five clubs for 300 years and dreams,
## quietly, of finally dropping one".
const OLD_TOMKIN := &"OLD_TOMKIN"

## The Troupe's fortune-teller and fire-eater, who "reads cards for a living inside a
## world made of them".
const MARIGOLD_FEN := &"MARIGOLD_FEN"

## The Troupe's strongman, "a gentle giant of few words".
const PERRIN_LOOM := &"PERRIN_LOOM"

## The Troupe's illusionist, "whose tricks are the only real magic in the show".
const TANSY_QUILL := &"TANSY_QUILL"

## A highwayman freed by `WS_JUSTICE_UNBOUND`, who "preyed on pilgrims bound for the
## Stillmarsh".
const GORRISTER_VALE := &"GORRISTER_VALE"

## A poisoner freed by `WS_JUSTICE_UNBOUND`, who "quietly ended several inconvenient
## marriages for inheritance".
const WIDOW_CULPEPPER := &"WIDOW_CULPEPPER"

## A smuggler and people-fence freed by `WS_JUSTICE_UNBOUND`.
const CORVIN_ROOK := &"CORVIN_ROOK"

## The Stillmarsh's ferry-keeper, "nearly done dying" for 300 years.
const OLD_SALLOW := &"OLD_SALLOW"

## Every named NPC, in the order `characters.md` §Recurring named NPCs lists them.
##
## The Lion of the Maw is deliberately absent: the section calls him "a beast, not a
## talker", and a profile for him would be a bark pool for something that does not
## talk. The Troupe itself is absent for the opposite reason - it is a group, and its
## four named members are the people.
const ALL: Array[StringName] = [
	FLICK,
	OLD_TOMKIN,
	MARIGOLD_FEN,
	PERRIN_LOOM,
	TANSY_QUILL,
	GORRISTER_VALE,
	WIDOW_CULPEPPER,
	CORVIN_ROOK,
	OLD_SALLOW,
]
