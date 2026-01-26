# Special Components

Specialized components for specific behaviors and effects.

## Stunnable Component

Applies status effects and crowd control to units.

### Basic Usage

```gdscript
extends Node3D

func _ready():
    add_child(Stunnable.new())
```

### Features

- Stuns (complete immobilization)
- Slows (reduced movement speed)
- Roots (can't move but can act)
- Duration tracking
- Multiple simultaneous effects

### Applying Effects

```gdscript
var stunnable = unit.get_node("Stunnable")
stunnable.stun(duration)
stunnable.slow(slow_factor, duration)
stunnable.root(duration)
```

### Checking Status

```gdscript
if stunnable.is_stunned():
    # Unit cannot act
    pass

if stunnable.is_slowed():
    # Reduce movement speed
    pass
```

## CommonAnimController

Standard animation controller for common unit animations.

### Features

- Unified animation state management
- Walk/Run transitions
- Attack coordination
- Damage reactions
- Death sequences

### Integration

Works automatically with movement and combat systems.

## ComponentLinker

Connects components and manages dependencies.

### Purpose

- Manages component references
- Ensures proper initialization order
- Handles component communication

### Usage

Automatically used by the addon's core systems.

## Custom Components

Create your own specialized components:

```gdscript
extends Component
class_name MySpecialComponent

func _ready() -> void:
    super()
    # Initialize special behavior
    pass

func _process(delta: float) -> void:
    # Update special logic
    pass
```

## See Also

- [Component System](overview.md) - Creating custom components
- [Combat System](../systems/combat.md) - Combat with status effects
- [Best Practices](../reference/best-practices.md) - Component design patterns
