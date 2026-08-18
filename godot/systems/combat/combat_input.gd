class_name CombatInput
extends RefCounted

## One frame of intent, handed to `MovesetController.update()`.
##
## It is a struct, not a reader: nothing here touches `Input`, so the whole moveset
## runs headless in a unit test that just sets fields. `FoolCombat` is what reads the
## `InputActions` and fills one of these in - and it **owns exactly one instance and
## refills it every frame**, which is why this is a mutable bag rather than an
## immutable value (`docs/design/technical.md` §Performance guardrails: no per-frame
## allocation in the combat loop).
##
## The edge-shaped fields (`*_pressed`, `heavy_released`) are one-frame events; the
## level-shaped ones (`heavy_held`, `focus_held`) are states. `focus_held` and
## `heavy_held` arrive already resolved through `HoldOrToggle`, so this class never
## knows whether the player has hold or toggle configured for them.

## Movement intent this frame, unnormalised, as read from the move actions.
var move: Vector2 = Vector2.ZERO

## The light-attack button went down this frame.
var light_pressed: bool = false

## The heavy-attack button went down this frame.
var heavy_pressed: bool = false

## The heavy-attack button is down (or latched on, under toggle).
var heavy_held: bool = false

## The heavy-attack button came up this frame (or the toggle was released).
var heavy_released: bool = false

## The dodge button went down this frame.
var dodge_pressed: bool = false

## The block-step button went down this frame.
var block_pressed: bool = false

## Focus is engaged (held, or latched on under toggle).
var focus_held: bool = false

## The cycle-target button went down this frame. Only meaningful while `focus_held`;
## the moveset ignores it entirely (who Focus is locked onto is `FocusTargeting`'s
## question, not the moveset's), it rides here so one struct is still the whole of one
## frame's intent.
var focus_cycle_pressed: bool = false

## How fast the Fool is already moving as a fraction of top speed, for the running
## attack's threshold.
var run_speed_fraction: float = 0.0


## Clear every field. Called by the owner at the top of each frame so a stale edge
## from last frame cannot fire a second move.
func clear() -> void:
	move = Vector2.ZERO
	light_pressed = false
	heavy_pressed = false
	heavy_held = false
	heavy_released = false
	dodge_pressed = false
	block_pressed = false
	focus_held = false
	focus_cycle_pressed = false
	run_speed_fraction = 0.0
