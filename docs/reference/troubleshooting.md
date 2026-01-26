# Troubleshooting

Common issues and how to resolve them.

## Units Not Selectable

**Problem**: Can't click on units to select them.

**Solutions**:

1. Ensure `SelectableComponent` is added to unit
2. Check collision layers/masks for raycast compatibility
3. Verify `RTSPlayerInput` is enabled
4. Check that input event handling isn't blocked elsewhere

```gdscript
# Debug: Check if component exists
if not unit.has_node("SelectableComponent"):
    print("Unit missing SelectableComponent!")
```

## Units Not Moving

**Problem**: Move commands don't result in unit movement.

**Solutions**:

1. Add `MovableComponent` to unit
2. Verify `NavigationRegion3D` with NavMesh exists in scene
3. Bake the NavMesh
4. Check collision layers for path validation

## NavMesh Not Working

**Problem**: Pathfinding doesn't work or units get stuck.

**Solutions**:

1. Open Scene menu → Bake NavMesh
2. Ensure static obstacles are set properly
3. Verify cell/agent sizes are appropriate
4. Check that terrain is included in NavMesh

## Events Not Firing

**Problem**: Signal connections don't work.

**Solutions**:

1. Verify correct signal name (case-sensitive)
2. Ensure callback function exists
3. Check autoloads are enabled in Project Settings
4. Use `get_tree().debug_connections` to inspectgs


## Performance Issues

**Problem**: Game runs slowly with many units.

**Solutions**:

1. Use spatial hashing for queries (see [Spatial Hashing](../advanced/spatial-hashing.md))
2. Reduce update frequency for non-critical systems
3. Use object pooling for projectiles/effects
4. Profile with Godot's profiler

**Remark**:

On modern hardware, the game should run well with up to 100 units. Consider simplifying the complexity or geometry of units if using more than that. Since Gdscript is not a perfomant language and the logic being completely writtin in gdscript, don't expect to handle multiple hundreds of units at the same time.

## Animation Not Playing

**Problem**: Unit animations don't trigger.

**Solutions**:

1. Ensure AnimationPlayer and AnimationTree are properly set up
2. Verify animation names match exactly
3. Check AnimationTree parameters are set correctly
4. Enable AnimationTree with `anim_tree.active = true`
5. Be aware that an active AnimationTree overwrites the AnimationPlayer!

## Health/Damage Not Working

**Problem**: Health doesn't decrease when taking damage.

**Solutions**:

1. Add `HealthComponent` to unit
2. Verify damage is actually being applied
3. Check if unit has defense that might block damage
4. Inspect health events to unit
5. 
## Autoload Not Found

**Problem**: RTSEventBus, RTSController, or RTSPlayerInput errors.

**Solutions**:

1. Check plugin is enabled (Project → Settings → Plugins)
2. Reload project if adding plugin
3. Verify autoload names in Project Settings → Autoload
4. Check for script errors in console Settings → Plugins)
5. Try manually adding the autoloads
   
## Collision Issues

**Problem**: Units pass through each other or obstacles.

**Solutions**:

1. Configure collision layers properly, by checking rts_settings.tres
2. Use appropriate collision shapes (not too small)
3. Check collision layer/mask combinations

**Remark**:

Collision layers for RTS_Entity and RTS_Component should automatically be set in _ready depending on the Faction of the Entity.


## Getting Help

If you're stuck:

1. Check the [Best Practices](best-practices.md) guide
2. Review relevant documentation section
3. Check the [examples](../getting-started.md#next-steps) in the addon
4. Enable debug output and check console
5. Use Godot's debugger to inspect state

## See Also

- [Getting Started](../getting-started.md) - Initial setup
- [Best Practices](best-practices.md) - Common patterns
- [Core Concepts](../core-concepts.md) - How things work
