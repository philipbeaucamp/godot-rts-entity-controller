# Best Practices

## General Design

### Use Components Appropriately

- Create small, focused components
- One responsibility per component
- Avoid large monolithic scripts (Movable Component not being a good example...)
- Reuse components across unit types

### Event-Driven Communication

```gdscript
# Good: Decoupled via events
RTSEventBus.connect("unit_selected", Callable(self, "_on_unit_selected"))

# Avoid: Direct coupling
var player = get_node("/root/Player")
player.select_unit(unit)
```

### Cache References

```gdscript
# Cache component references
var health_comp: HealthComponent
var movement_comp: MovableComponent

func _ready() -> void:
    health_comp = get_node("HealthComponent")
    movement_comp = get_node("MovableComponent")
```

## Performance

### Use appropriate amount of entities

This tools works best with tens to low hundreds of units. Think SC2 sized squirmishes, not thousands of units large armies.


### Optimize entities

Perfomance is heavily influence by how complex your single units are. Try

- Removing any unnecessary `Node3D`s (or turning them into `Node` if possible)
- Optimize polygon, draw calls and generally try to combine meshes where possible
- Reuse `Area3D` where possible
- Track component activity using Godots profiler


### Batch Operations

```gdscript
# Good: Process multiple at once
var paths = []
for target in destinations:
    paths.append(calculate_path(start, target))

# Avoid: Individual queries in loops
for i in range(100):
    calculate_path(start, destinations[i])  # Slow!
```

Also note that Gdscripts function call overhead is (relatively) pretty expensive.

### Use Process Efficiently

```gdscript
# Only override if needed
func _process(delta: float) -> void:
    if active_state:  # Skip if not needed
        update_position(delta)

# Or use _physics_process for physics
# Or conditionally call update methods
```

## Component Integration

### Proper Initialization

99% of the time, you *do* want to call `super._ready()` when overriding components, so don't forget!

```gdscript
func _ready() -> void:
    super._ready()  # Call parent _ready
    
    health_comp = entity.health # Use entity to fetch components if possible!
    
    # Subscribe to events
    RTSEventBus.connect("unit_selected", Callable(self, "_on_selected"))
    
    # Validate setup
    assert(health_comp != null, "Missing HealthComponent")
```

### Graceful Cleanup

```gdscript
func _exit_tree() -> void:
    # Disconnect signals
    RTSEventBus.disconnect("unit_selected", Callable(self, "_on_selected"))
    
    # Cancel timers
    if timer:
        timer.stop()
    
    # Clean up resources
    if shader_material:
        shader_material.free()
```

## Selection & Input

### Validate Selections

```gdscript
# Ensure units still exist before using
for unit in selected_units:
    if not is_instance_valid(unit):
        continue  # Unit was deleted
    
    issue_command(unit)
```

## Testing & Debugging

### Use Debug Tools

Especially for drawing paths and geometry, using a debug drawing tools such as  `DebugDraw3D` is immensely helpful.
You will actual find commented `DebugDraw3D` calls throughout the code.

```gdscript
# Add debug visualization
##DebugDraw3D.draw_aabb(aabb,debug_color)
```

### Validate Assumptions

```gdscript
# Assert expected conditions
assert(unit != null, "Unit reference is null")
assert(unit.has_node("HealthComponent"), "Unit missing HealthComponent")
```



## See Also

- [Core Concepts](../core-concepts.md) - Architecture patterns
- [Component System](../components/overview.md) - Component design
- [Troubleshooting](troubleshooting.md) - Common issues
