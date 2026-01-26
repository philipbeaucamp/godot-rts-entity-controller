# Movement & Navigation

## Overview

The movement system uses a mix of Godot's built-in navigation system for seeking a target position (static) and various custom avoidance and separation boid behaviours (dynamic) implement in RTS_Movable.

## Architecture

### RTS_Movement

This script handleds group and formation logic. Contrary to its name, it doesn't implement any concrete movement logic itself, but rather converts movement commands of multiple RTS_Movable's into concret target points that it then sends to each respective RTS_Movable. This logic is done in `group_move` and `group_patrol`.

### RTS_Movable

The logic that handles the details of seeking, avoidance and separation between moving entities is `RTS_Movable`. For details see [Movable Component](../components/movable.md)

### Issuing movement commands

Instead of hardcoding movement commands, or have the PlayerInput directly dictate move commands to RTS_Movable, commands are issued via the generic [Ability System], for example via 
RTS_MoveAbility, RTS_AttackAbility, RTS_PatrolAbility or RTS_HoldAbility. An example:

```gdscript
# RTS_PatrolAbility:

func activate():
	var movables : Array[RTS_Movable] = []
	movables.append(entity.movable)
	Controls.movement.group_patrol(
		click_target,
		click_target_source,
		movables,
		context["shift_is_pressed"],
		)
	activated.emit(self)
```

This way it is easy to deactivate or disable certain move commands, for example by simply removing the ability from an entity. For instance, ff you wanted an entity that can only move but not patrol, simple remove the "RTS_PatrolAbility" from the entity (or disable it somehow), and you can no longer issue patrol commands to the entity. 

To learn more about abilities see [Ability System]

## See Also

- [MovableComponent](../components/movable.md) - Component details
- [Core Concepts](../core-concepts.md) - Architecture overview
- [Spatial Hashing](../advanced/spatial-hashing.md) - Performance optimization
