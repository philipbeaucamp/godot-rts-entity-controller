# Component System Overview

## What is a Component?

Components are modular pieces of functionality that can be attached to units to give them specific capabilities. Rather than building units through inheritance, you compose them from components.

### Component-Based Architecture Benefits

- **Modularity** - Each component handles one responsibility
- **Reusability** - Use the same components on different unit types
- **Flexibility** - Mix and match components to create varied units
- **Testability** - Components can be tested independently
- **Performance** - Only required components are active

## Base Component Class

All components extend from the base class `RTS_Component`, which always has a reference to its entity (usually the parent)

```gdscript
func fetch_entity() -> RTS_Entity:
	return get_parent() as RTS_Entity
```

and can be turned on and off:

```gdscript
func set_component_inactive():
	component_is_active = false

func set_component_active():
	assert(!component_is_active,"RTS_Component set active twice. You're game logic is probably flawed.")
	component_is_active = true
```

If not required otherwise, leaving `set_component_active_on_ready` set to true is usually the right call.

RTS_Component is the main building block to build modular and scalable, yet unique entity behaviours. For developers wanting to adopt this framework, it is recommended to come up with your own unique and new components which add features and complexity to entities by extending this base class.

Here we briefly introduce the most common components that are included in RTS Godot Entity Controller.
Note that `RTS_Ability` themselves as well as many other scripts (such as `RTS_Weapon`) are themselves inheriting from `RTS_Component`.


## Common Components

### Selection & Interaction

- **[SelectableComponent](selectable.md)** - Make units clickable and selectable
- **[BoxableComponent]** - Enable box selection support, see [SelectableComponent](selectable.md)
- **[PickablePhysics]** - Enables clicking units to select using raycast, see [SelectableComponent](selectable.md)

### Movement & Navigation

- **[MovableComponent](movable.md)** - Unit movement and pathfinding

### Health & Combat

- **[HealthComponent](health.md)** - Hit points and health management
- **[DefenseComponent](defense.md)** - Armor and damage reduction
- **Attack components** - See [Attack System](attack.md)

### Visuals & Animation

- **[VisualComponent](visual.md)** - Rendering and visibility
- **[AnimationTreeComponent](animation-tree.md)** - AnimationTree integration. Also see [Attack System](attack.md)

### Example: ExampleUnit.tscn

As alluded to in [Entity System](../systems/entity.md), components usually (but no always) sit as direct children underneath the entity:

```
ExampleUnit (RTS_Entity)
├── (...)
├── SelectableComponent
├── MovableComponent
├── HealthComponent
├── DefenseComponent
├── AnimationTreeComponent
```

## Creating Custom Components

Creating custom components is as easy as inherting from `RTS_Component`. The easiest thing to forget is to properly implement 

```gdscript
func set_component_inactive()
func set_component_active()
```

so that components can be turned off which should disable any heavy computation or update loops.

## Next Steps

- Learn about specific components in the detailed guides
- [Selectable Component](selectable.md)
- [Movable Component](movable.md)
- [Health & Defense](health-defense.md)
- [Creating custom abilities](../advanced/abilities.md)
