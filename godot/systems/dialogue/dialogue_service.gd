class_name DialogueService
extends RefCounted

## The conversation runner: it walks an authored `DialogueGraph` and says what is on
## screen right now.
##
## It decides nothing about the world. `docs/design/technical.md` §The WorldState
## service (Godot) is explicit that "combat, dialogue, UI, and NPCs never write
## state; they raise domain events, and a quest transition responds" - so this
## service **reads** `WorldStateService` for its branch conditions, and the only path
## from a conversation to a permanent change is an `EVENT` node, which is emitted on
## `event_raised` for the SCENE to forward to `QuestService.raise()`. The service
## never holds a `QuestService` and never reaches into a scene (architecture
## principle 5).
##
## Four properties hold by construction rather than by discipline:
##
##   * **Nothing is a literal.** A node carries a translation key; the English lives
##     in `res://localization/dialogue_*.csv` and nowhere else.
##   * **Branches are queries.** A `BRANCH` node has no place to put a boolean - it
##     holds `WS_*` ids, CONFESSED and an act floor, and asks the world state.
##   * **Nothing persists.** Which options have been used is state of *this*
##     conversation, cleared when it ends. A save records quest state, not what the
##     Fool has already asked; a fresh service knows nothing.
##   * **No per-frame work.** Everything happens inside `start()`, `advance()`,
##     `choose()` and `leave()`. Interested systems connect to the signals.
##
## Threads and exhaustible tables. `docs/quests/TEMPLATE.md` writes a choice table as
## rows plus "If the Fool asked ..." follow-ups, and marks the table either *(all
## questions may be exhausted)* or *(first pick commits)*. Both are literal here: an
## `EXHAUST_ALL` table pushes itself onto a return stack when an option is taken, so
## that option's thread runs to its `END` and comes **back** to the table with the
## row spent; when every row is spent - or the Fool `leave()`s - the table falls
## through to `after_all`, which is the script's `[All versions pick up here:]`. A
## `FIRST_PICK_COMMITS` table pushes nothing: the chosen thread simply continues on
## and the table is never offered again. The stack is what makes a follow-up table
## inside a thread work, which MQ00's edge questions need twice.

## A conversation began. Carries the graph id.
signal dialogue_started(graph_id: StringName)

## The runner stopped on something the player can see. Carries a read-only view; the
## UI round renders it.
signal node_presented(view: DialogueView)

## The Fool picked a row of a choice table.
signal option_chosen(graph_id: StringName, node_id: StringName, index: int)

## A conversation raised a domain event. The SCENE forwards it to
## `QuestService.raise()`; this service never does, so dialogue can never write world
## state by accident.
signal event_raised(event: StringName)

## A conversation ended. Emitted for a graph that ran out and for one `end()` stopped
## early; a chained graph's `dialogue_started` follows immediately after.
signal dialogue_ended(graph_id: StringName)

## How many nodes the runner will walk through without presenting anything before it
## calls the graph broken. `BRANCH` and `EVENT` nodes are walked through rather than
## shown, so a graph that loops through only those would otherwise hang the game;
## `DialogueGraph.validate()` deliberately does not attempt cycle detection, and this
## is the guard that makes that safe.
const MAX_WALK_STEPS := 256

var _world_state: WorldStateService = null
var _catalog: DialogueCatalog = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## The conversation in progress, or `null` when there is none.
var _graph: DialogueGraph = null

## What `current()` hands out: the last thing presented, or `null`.
var _view: DialogueView = null

## `choice node id -> { option index: true }`, for the current conversation only.
var _used: Dictionary = {}

## `choice node id -> true` for every `FIRST_PICK_COMMITS` table already played.
var _committed: Dictionary = {}

## The exhaustible tables a thread must return to, innermost last.
var _return_stack: Array[StringName] = []


## Build the runner over the live world state and the authored dialogue catalog.
##
## `rng_seed` is for `POOL` nodes (the script's Random Lines). Leave it at 0 for a
## randomised game; pass a non-zero seed and every pool pick is reproducible, which
## is how the tests assert one.
func _init(
	world_state: WorldStateService, catalog: DialogueCatalog, rng_seed: int = 0
) -> void:
	_world_state = world_state
	_catalog = catalog
	if world_state == null or catalog == null:
		push_error("DialogueService was built without its world state or its catalog")
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed


# --- Queries -----------------------------------------------------------------


## True while a conversation is in progress.
func is_active() -> bool:
	return _graph != null


## The graph being played, or `&""` when nothing is.
func current_graph_id() -> StringName:
	return _graph.id if _graph != null else &""


## What is on screen right now, or `null` when no conversation is running.
func current() -> DialogueView:
	return _view


## True when this option of the table on screen has already been taken. False for
## anything that is not a live option of a live table.
func is_option_used(index: int) -> bool:
	if _view == null or not _view.is_choice():
		return false
	if index < 0 or index >= _view.options.size():
		return false
	return _view.options[index].is_used


# --- Playing -----------------------------------------------------------------


## Begin a conversation. Returns true only when **this call** started it.
##
## Refused, without changing anything, when another conversation is already running
## or the catalog does not list this graph. A scene may therefore always ask; a beat
## whose line arrives while the Fool is mid-sentence is simply not interrupted.
func start(graph_id: StringName) -> bool:
	if is_active():
		return false
	var graph := _catalog.find(graph_id) if _catalog != null else null
	if graph == null:
		push_error("no dialogue graph with id %s" % graph_id)
		return false
	_graph = graph
	_used = {}
	_committed = {}
	_return_stack = []
	_view = null
	dialogue_started.emit(graph.id)
	_walk(graph.start_node)
	return true


## Move past the line on screen.
##
## A no-op when nothing is running, and a no-op on a choice table: a table moves
## through `choose()` or `leave()`, never by being advanced past.
func advance() -> void:
	if _graph == null or _view == null:
		return
	var node := _graph.find_node(_view.node_id)
	if node == null:
		return
	if node.kind == DialogueNode.Kind.CHOICE:
		return
	_walk(node.next)


## Take row `index` of the choice table on screen. Returns true only when the pick
## was accepted.
##
## Refused when nothing is running, when what is on screen is not a table, when the
## index is not a row, and - in an exhaustible table - when that row has already been
## taken. Refusals change nothing.
func choose(index: int) -> bool:
	if _graph == null or _view == null or not _view.is_choice():
		return false
	var node := _graph.find_node(_view.node_id)
	if node == null or index < 0 or index >= node.options.size():
		return false
	var option := node.options[index]
	if option == null:
		return false
	var exhaustible := node.mode == DialogueNode.ChoiceMode.EXHAUST_ALL
	if exhaustible and _is_used(node.id, index):
		return false
	_mark_used(node.id, index)
	option_chosen.emit(_graph.id, node.id, index)
	if option.raises_event != &"":
		event_raised.emit(option.raises_event)
	if exhaustible:
		_return_stack.append(node.id)
	else:
		_committed[node.id] = true
	_walk(option.next)
	return true


## Leave the choice table on screen without taking (another) row - the script's
## `[All versions pick up here:]` edge, reached early.
##
## Exhaustible tables only: *(all questions **may** be exhausted)* means the Fool is
## never obliged to ask them all, and leaving with nothing asked is allowed too - a
## Fool with no questions is a Fool. A *(first pick commits)* table has no such edge:
## the pick is the point, so this returns false and changes nothing.
func leave() -> bool:
	if _graph == null or _view == null or not _view.is_choice():
		return false
	var node := _graph.find_node(_view.node_id)
	if node == null or node.mode != DialogueNode.ChoiceMode.EXHAUST_ALL:
		return false
	_walk(node.after_all)
	return true


## Stop the conversation where it is.
##
## Unlike a conversation that runs out, this does **not** chain into
## `next_graph_id`: `end()` is an interruption (a region change, a fight starting),
## and an interruption that then started the next scripted beat would be worse than
## the interruption.
func end() -> void:
	if _graph == null:
		return
	var finished := _graph.id
	_reset()
	dialogue_ended.emit(finished)


# --- Internals ---------------------------------------------------------------


## Walk from `target` until something presentable is reached, the conversation ends,
## or the graph proves itself broken.
##
## `BRANCH` and `EVENT` are resolved here rather than shown: a world-state question
## and a raised event are not moments of dialogue, so the player never sees one. An
## `END` inside a thread pops the exhaustible table that thread came from and lands
## back on it; an `END` with nothing to return to finishes the conversation.
func _walk(target: StringName) -> void:
	var steps := 0
	var at := target
	while true:
		steps += 1
		if steps > MAX_WALK_STEPS:
			push_error("%s walked %d nodes without stopping" % [_graph.id, MAX_WALK_STEPS])
			end()
			return
		if at == &"":
			_finish()
			return
		var node := _graph.find_node(at)
		if node == null:
			push_error("%s has no node %s" % [_graph.id, at])
			end()
			return
		match node.kind:
			DialogueNode.Kind.LINE, DialogueNode.Kind.POOL:
				_present(node)
				return
			DialogueNode.Kind.CHOICE:
				# A table with nothing left to offer is walked through rather than
				# shown again - an exhaustible one whose every row is spent, and a
				# committing one that has already been played and whose thread has
				# come back round to it. Both fall through to `after_all`: the
				# script's pickup point for the first, and for the second whatever
				# the author gave it, which is normally nothing at all and ends the
				# conversation. Re-offering a committed table would let the Fool
				# take a second "first pick".
				if _all_used(node):
					at = node.after_all
					continue
				_present(node)
				return
			DialogueNode.Kind.BRANCH:
				at = node.then_node if node.conditions_met(_world_state) else node.else_node
				continue
			DialogueNode.Kind.EVENT:
				event_raised.emit(node.event)
				at = node.next
				continue
			DialogueNode.Kind.END:
				if _return_stack.is_empty():
					_finish()
					return
				at = _return_stack.pop_back()
				continue


## Build the view for a node and hand it out.
func _present(node: DialogueNode) -> void:
	var view := DialogueView.new()
	view.kind = node.kind
	view.node_id = node.id
	view.graph_id = _graph.id
	view.speaker = node.speaker
	match node.kind:
		DialogueNode.Kind.LINE:
			view.text_key = node.text_key
		DialogueNode.Kind.POOL:
			view.text_key = _pick_pooled_key(node)
		DialogueNode.Kind.CHOICE:
			view.speaker = &""
			for index: int in node.options.size():
				var option := node.options[index]
				if option == null:
					continue
				view.options.append(
					DialogueOptionView.new(
						option.text_key, option.is_earnest, _is_used(node.id, index)
					)
				)
	_view = view
	node_presented.emit(view)


## One of a pool's Random Lines. Deterministic when the service was seeded.
func _pick_pooled_key(node: DialogueNode) -> StringName:
	if node.text_keys.is_empty():
		return &""
	return StringName(node.text_keys[_rng.randi_range(0, node.text_keys.size() - 1)])


## The conversation ran out. Chains into `next_graph_id` when the graph names one, so
## a script's "the line, then the table" is one thing a scene starts, not two.
func _finish() -> void:
	var finished := _graph
	_reset()
	dialogue_ended.emit(finished.id)
	if finished.next_graph_id != &"":
		start(finished.next_graph_id)


## Forget everything about the conversation. Nothing here is save data.
func _reset() -> void:
	_graph = null
	_view = null
	_used = {}
	_committed = {}
	_return_stack = []


func _is_used(node_id: StringName, index: int) -> bool:
	var rows: Dictionary = _used.get(node_id, {})
	return rows.has(index)


func _mark_used(node_id: StringName, index: int) -> void:
	if not _used.has(node_id):
		_used[node_id] = {}
	var rows: Dictionary = _used[node_id]
	rows[index] = true


## True when every row of an exhaustible table has been taken - or when the table has
## been committed, which a `FIRST_PICK_COMMITS` table can be.
func _all_used(node: DialogueNode) -> bool:
	if _committed.has(node.id):
		return true
	for index: int in node.options.size():
		if not _is_used(node.id, index):
			return false
	return true
