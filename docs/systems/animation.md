# Animation System

Coordinating unit animations across movement, combat, and abilities.

## Overview

The animation system provides:

- State-based animations
- Smooth transitions
- Combat animation sync
- Movement animation blending
- Ability animation coordination

## Basic Animation States

Common states for RTS units:

- **idle** - Unit at rest
- **walk** - Moving at normal speed
- **run** - Moving at higher speed
- **attack** - Performing basic attack
- **cast** - Casting an ability
- **stun** - Stunned/crowd controlled
- **hit** - Taking damage
- **die** - Death sequence

## AnimationTree Setup

Configure your AnimationTree:

```
AnimationTree
├── AnimationNodeStateMachine (root)
│   ├── Idle
│   ├── Walk
│   ├── Run
│   ├── Attack
│   ├── Cast
│   └── Die
```

## Animation Transitions

```gdscript
# Set parameters for transitions
anim_tree.set("parameters/conditions/moving", true)
anim_tree.set("parameters/conditions/attacking", false)

# Use playback for complex transitions
var playback = anim_tree.get("parameters/playback")
playback.travel("walk")
```

## Movement Animations

Automatically sync with movement:

```gdscript
func _process(delta: float) -> void:
    if is_moving:
        anim_tree.set("parameters/conditions/moving", true)
        var speed = velocity.length()
        anim_tree.set("parameters/speed_scalar", speed / max_speed)
    else:
        anim_tree.set("parameters/conditions/moving", false)
```

## Combat Animations

Coordinate attacks with animations:

```gdscript
func execute_attack(target: Node) -> void:
    var playback = anim_tree.get("parameters/playback")
    playback.travel("attack")
    
    # Wait for animation to reach damage point
    await get_tree().create_timer(0.5).timeout
    apply_damage(target)
```

## Ability Animations

Play animations for abilities:

```gdscript
func cast_ability(ability: String) -> void:
    var playback = anim_tree.get("parameters/playback")
    playback.travel("cast")
    
    # Wait for cast animation
    var anim_player = get_node("AnimationPlayer")
    await anim_player.animation_finished
    
    execute_ability()
```

## Blending

Smooth transitions between animation states:

```gdscript
# Set blend positions for smooth transitions
anim_tree.set("parameters/idle_move/blend_position", blend_value)
```

## Hit Reactions

Play hit animations on damage:

```gdscript
func _on_unit_damaged(unit: Node, damage: float) -> void:
    if unit == get_parent():
        var playback = anim_tree.get("parameters/playback")
        playback.travel("hit")
```

## Death Animation

Handle death sequences:

```gdscript
func play_death_animation() -> void:
    var playback = anim_tree.get("parameters/playback")
    playback.travel("die")
    
    # Wait for animation to complete
    var anim_player = get_node("AnimationPlayer")
    await anim_player.animation_finished
    
    queue_free()
```

## See Also

- [Animation Tree Component](../components/animation-tree.md) - Component details
- [Movement & Navigation](movement.md) - Movement system
- [Combat System](combat.md) - Combat coordination
