class_name InputActions
extends RefCounted

## The one place the game's InputMap action names are written down.
##
## Gameplay code never reads raw keys or literal action strings: it asks
## `Input` for these constants, and the bindings behind them live in
## `project.godot [input]` where a rebinding screen can rewrite them
## (see docs/design/technical.md, Godot 2D section).
##
## `ui_*` actions are Godot's own (menu focus, list navigation) and are NOT
## listed here: gameplay must not read them.
##
## **There is no `rose` action.** The White Rose's petals ARE the Fool's health
## (director ruling, issue #11), so there is nothing to press: a hit costs petals and
## the Rose grows back on its own and at a Waystation. R is deliberately left free.

## Movement, resolved as one vector by `Input.get_vector`.
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"

## Held (or toggled, per combat.md §Accessibility) faster travel.
const SPRINT := &"sprint"

## Talk to an NPC, pick a thing up, use a Waystation.
const INTERACT := &"interact"

## The Bindle moveset.
const ATTACK_LIGHT := &"attack_light"
const ATTACK_HEAVY := &"attack_heavy"
const DODGE := &"dodge"

## The hop-guard (combat.md §Defense): absorbs a hit, repositions, no counter-window.
const BLOCK_STEP := &"block_step"

## Target lock + strafe (combat.md, 2D amendment).
const FOCUS := &"focus"

## Step the Focus lock to the next enemy, without leaving the stance.
const FOCUS_CYCLE := &"focus_cycle"

## Pip's command wheel.
const PIP_WHEEL := &"pip_wheel"

## The Pocket Spread screen.
const SPREAD := &"spread"

## The Almanack (the Reading).
const ALMANACK := &"almanack"

## Pause menu.
const PAUSE := &"pause"

## Every gameplay action, for tests and for a rebinding screen to enumerate.
const ALL: Array[StringName] = [
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_UP,
	MOVE_DOWN,
	SPRINT,
	INTERACT,
	ATTACK_LIGHT,
	ATTACK_HEAVY,
	DODGE,
	BLOCK_STEP,
	FOCUS,
	FOCUS_CYCLE,
	PIP_WHEEL,
	SPREAD,
	ALMANACK,
	PAUSE,
]
