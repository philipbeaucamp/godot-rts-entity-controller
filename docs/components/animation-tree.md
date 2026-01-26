# Animation Tree Component

The `AnimationTreeComponent` integrates unit animations through Godot's AnimationTree system.

## Basic Usage

```gdscript
extends Node3D

func _ready():
    add_child(AnimationTreeComponent.new())
```

## Setup

Requires an AnimationTree node in your unit:

```
Unit
├── Model (MeshInstance3D)
├── AnimationPlayer
├── AnimationTree
└── AnimationTreeComponent
```

## Features

- AnimationTree integration
- State machine support
- Animation blending
- Event-triggered animations
- Smooth state transitions

## Common Animations

Standard animation states:

- `idle` - Unit at rest
- `walk` - Moving around
- `run` - Faster movement
- `attack` - Attack animation
- `cast` - Ability casting
- `hit` - Taking damage
- `die` - Death animation

## Playing Animations

```gdscript
var anim = unit.get_node("AnimationTreeComponent")
anim.play("walk")
anim.play("attack")
```

## State Machine

Use AnimationTree's built-in state machine:

```gdscript
var playback = anim_tree.get("parameters/playback")
playback.travel("walk")
playback.travel("attack")
```

## Synchronization

Coordinate animations with game logic:

```gdscript
func execute_attack() -> void:
    anim_comp.play("attack")
    await get_tree().create_timer(0.5).timeout
    apply_damage(target)
```

## Configuration

Setup AnimationTree parameters:

```gdscript
anim_tree.anim_player = $AnimationPlayer
anim_tree.tree_root = $AnimationTree/AnimationNodeStateMachine
```

## Integration

Works with:
- Movement system for walk/run animations
- Combat system for attack/hit animations
- Ability system for casting animations

See [Components Overview](overview.md) for more details.
