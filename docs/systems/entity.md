# RTS_Entity: The Core Unit Host

## Overview

`RTS_Entity` is the central hub that hosts and coordinates all components for a unit in the RTS Entity Controller. It extends `CharacterBody3D` and acts as the owner/parent that manages component lifecycle, state coordination, and integration with the broader system. An Entity can represent anything from a movable Unit to an immovable structure such as a building.

## The Host/Owner Pattern

Rather than components being standalone, they are **children of the RTS_Entity node** which acts as their host and orchestrator.

### Why This Design?

- **Centralized State** - Entity manages all component state in one place
- **Easy Discovery** - Components are automatically found and cached
- **Physics Support** - CharacterBody3D provides physics and collision support
- **Spatial Hashing** - Entity represents a spatial unit for queries
- **Lifecycle Management** - Entity emits useful lifecycle events


### EntityResource

Basic data, such as the entities name, id or thumbnail should be configured by creating a `EntityResource` resource, from which the `RTS_Entity` can read.

## Component Discovery & Caching

RTS_Entity automatically discovers components on startup:

```gdscript
@export var selectable: RTS_Selectable
@export var movable: RTS_Movable
@export var health: RTS_HealthComponent
@export var attack: RTS_AttackComponent
@export var defense: RTS_Defense
@export var stunnable: RTS_StunnableComponent
@export var anim_tree: RTS_AnimationTreeComponent
@export var visuals: RTS_VisualComponent
@export var obstacle: NavigationObstacleComponent
```

In `_ready()`, the entity calls `update_and_fetch_components()`:

```gdscript
func update_and_fetch_components():
    abilities.clear()
    abilities_array.clear()
    for child in get_children():
        if child is RTS_Selectable:
            selectable = child
        if child is RTS_Movable:
            movable = child
        if child is RTS_HealthComponent:
            health = child
        # ... etc for all components
```

This means:

1. **No manual setup needed** - Just add components as children
2. **Components are cached** - Accessed via properties, not `get_node()` calls
3. **Type-safe** - Full IDE autocomplete support


Since the script as @tool annotated, this happens during editor time, to avoid race conditions during startup.

## Faction System

Entities belong to factions that determine team affiliation:

```gdscript
enum Faction { PLAYER, ENEMY, NEUTRAL }

@export var faction = Faction.PLAYER
```

Use faction to:
- Determine ally/enemy relationships
- Set collision layers
- Control targeting
- Manage rendering/highlighting

```gdscript
func setup_unit(_faction: Faction):
    faction = _faction
    # Faction affects collision detection and team relationships
```

## Component Coordination

The entity coordinates between components by connecting signals and routing events:

### Component State & Animation Sync

```gdscript
if movable:
    movable.sm.enter_state.connect(on_movable_enter_state)
    on_movable_enter_state(movable.sm.current_state)
```

When the certain component changes states, the entity updates its own state dictionaries:

```gdscript
var sb : Dictionary[StringName, bool] = {} #state bool
var si : Dictionary[StringName, int] = {} #state integer
```

At first this might seem redundant and look like unnecessary coupling, however this is done so the AnimationTree a central place to check state for its State Transitions. Unforuntately the advanced expressions in Godots StateMachines can only evaluate state from one script (called the "AdvancedExpressionBaseNode") and the Entity is the perfect candidate to read this state from. Thus you can evaluate any state easily in the AnimationTree's StateMachine, for instance

```gdscript
si["move_state"] = new_state      # Which movement state
si["attack_state"] = new_state    # Which attack state  
sb["is_stunned"] = value          # Stunned status
si["weapon_index"] = weapon_index # Current weapon
```

## Ability Management

RTS_Entity automatically collects and manages abilities:

```gdscript
var abilities: Dictionary[String, RTS_Ability] = {}
var abilities_array: Array[RTS_Ability] = []
```

All `RTS_Ability` components are discovered and stored by ID:

```gdscript
if child is RTS_Ability:
    abilities_array.append(child)
    abilities[child.resource.id] = child
```

Access abilities by name or iterate:

```gdscript
# Get specific ability
var fireball = entity.abilities["fireball"]

# Iterate all
for ability in entity.abilities_array:
    ability.use(target)
```

## Spatial Hashing Integration

The entity integrates with spatial hashing for efficient queries:

```gdscript
@export var space_hash: bool = true:
    set(value):
        space_hash = value
```

When set to false, the spatial hash system will not include this entity as a "client" in its grid.
This can be efficient to set to false for immovable structures or entities that don't require special quering, to reduce workload on the spatial hash system.

## Lifecycle Events

The entity emits important lifecycle signals:

```gdscript
signal before_tree_exit(entity: RTS_Entity)
signal end_of_life(entity: RTS_Entity)  # Guaranteed exactly once
```

These allow other systems to track unit creation and destruction.

## Screen Visibility

Track when units enter/exit screen for optimization:

```gdscript
visible_on_screen.screen_entered.connect(on_screen_entered)
visible_on_screen.screen_exited.connect(on_screen_exited)

func on_screen_entered():
    RTSEventBus.entity_screen_visible.emit(self, true)
```

Use this to:
- Stop processing off-screen units
- Optimize rendering
- Control audio playback

## Accessing Entity from Components

Every component implements the `func fetch_entity() -> RTS_Entity` to easily fetch the corresponding entity.

## Creating a Custom Entity

RTS_Entity can be extended for unique behaviour, i.e.

```gdscript
class_name HeroUnit extends RTS_Entity
@export var experience: int = 0
```

but before you do, think twice and reconsider if this additional behavior can not rather be implement using a new component, to keep your entities modular!

## Best Practices

### 1. Always Check Component Existence (since they are optional)

```gdscript
# Good
if entity.health:
    entity.health.take_damage(10)

# Avoid
entity.health.take_damage(10)  # Crashes if health component missing
```

### 2. Use Entity as Central Coordinator

Even though certain components technically depend on each other (for instance RTS_Defense requires a RTS_Health to work an deal damage), it is usually best to query this component from RTS_Entity, to avoid coupling and spaghetti references.

### 3. Leverage Caching

```gdscript
# Good - Cached reference
var health = entity.health
for i in range(100):
    health.current_hp -= 1

# Avoid - Repeated node lookups
for i in range(100):
    entity.get_node("RTS_HealthComponent").current_hp -= 1
```


## See Also

- [Component System](components/overview.md) - Creating components
- [Getting Started](getting-started.md) - Setting up units
- [Best Practices](reference/best-practices.md) - Design patterns
- [Custom Integration](advanced/custom-integration.md) - Extending entities
