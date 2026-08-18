class_name CombatLayers
extends RefCounted

## The physics layers combat uses, in one place.
##
## Layer numbers are magic numbers in exactly the way `docs/design/technical.md`
## forbids ids to be magic strings: a hurtbox authored on layer 3 in one scene and
## looked for on layer 2 in another is a bug nothing reports, the enemy simply never
## gets hit. So the numbers live here and the boxes set themselves up in `_ready()`
## from these constants rather than carrying the values in every `.tscn`.
##
## The arrangement is one-directional on purpose: **hurtboxes sit on a layer and
## watch nothing; hitboxes watch that layer and sit on none.** A hitbox therefore
## never sees another hitbox (two swings cannot parry each other by accident), and a
## hurtbox never spends a frame testing anything.

## Godot's layer numbers are 1-based in the editor and bit-indexed in code; both
## spellings are kept so a scene author and a script agree.

## The layer every `Hurtbox` sits on.
const HURTBOX_LAYER := 3

## That layer as a collision bitmask.
const HURTBOX_MASK := 1 << (HURTBOX_LAYER - 1)

## Nothing: what a hurtbox scans, and what a hitbox occupies.
const NONE := 0
