class_name DialogueStyle
extends RefCounted

## The lintable half of `docs/design/narrative.md` §Dialogue style guide.
##
## The guide has five rules; exactly two of them can be checked by a machine, and
## they live here so a test can run them over the shipped catalog **and** over a
## deliberately bad graph:
##
##   * **The Fool's selectable lines stay short** - "≤ 12 words ... it is the
##     character's soul". Measured on the English, so a line that is short as a key
##     and long as a sentence still fails.
##   * **One earnest option wherever possible** - the script marks it *(earnest)*;
##     a table may waive it only with a recorded reason (`DialogueNode.earnest_exempt`
##     plus `notes`), which is a review decision rather than an oversight.
##
## The other three are not lintable and are not pretended to be: the one-wink-per-
## quest rule (a wink is a judgement, not a token), the melancholy rule, and the
## register. They stay review items on the CLAUDE.md checklist.
##
## The text lookup is injected rather than taken from `TranslationServer`, so a test
## can lint a synthetic graph without writing to the shipped CSV.

## The style guide's hard ceiling on a line the player picks.
const MAX_FOOL_WORDS := 12


## Any run of whitespace: what separates two words, whatever the CSV happens to hold.
##
## A translated line can carry a tab or a newline as readily as a space (a two-line
## option, a key pasted out of a table), and splitting on the space character alone
## would count `one\ttwo` as one word and let a line over the ceiling through.
static var _whitespace: RegEx = RegEx.create_from_string("\\s+")


## How many words a line is: whitespace-separated tokens, the way a reader counts.
static func word_count(text: String) -> int:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return 0
	return _whitespace.sub(trimmed, " ", true).split(" ", false).size()


## Every style-guide violation in one graph, one string per violation.
##
## `translate` is called with a `StringName` key and must return the English `String`
## for it. In the game that is `TranslationServer.translate`; in a test it is a
## dictionary lookup. A key with no English behind it is NOT reported here - the
## localization test owns missing lines, and reporting it twice would make one
## mistake look like two.
static func violations(graph: DialogueGraph, translate: Callable) -> PackedStringArray:
	var errors := PackedStringArray()
	if graph == null:
		return errors
	for node: DialogueNode in graph.choice_nodes():
		if not node.has_earnest_option():
			errors.append("%s/%s offers no earnest option and claims no exemption" % [
				graph.id, node.id
			])
		for option: DialogueOption in node.options:
			if option == null or option.text_key == &"":
				continue
			var english: String = translate.call(option.text_key)
			if english == String(option.text_key):
				continue
			var words := word_count(english)
			if words > MAX_FOOL_WORDS:
				errors.append("%s/%s: %s is %d words, over the %d the Fool gets" % [
					graph.id, node.id, option.text_key, words, MAX_FOOL_WORDS
				])
	return errors
