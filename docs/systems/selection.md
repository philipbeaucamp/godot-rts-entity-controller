# Selection System

## Overview

The Selection System manages which units are currently selected and provides feedback to the player about their selection. Only entities with the RTS_Selectable component can be selected. There are two types of selection: Pickable (using physics raycast) or Boxable (using click and drag box). A RTS_Selectable can have one or both of these types of selection configured.

## How Selection Works

### Single Unit Selection

1. RTS_PhysicsSelection uses RTS_PickablePhysicsComponent to determin hovered entities
2. Player clicks on a entity.
3. If the entity is hovered, RTS_Selection selects the entity
4. Necessary events are emitted

Note that Selection keeps track of the RTS_Selectable component, not RTS_Entity itself, since selection only cares about entities which have the RTS_Selectable component

### Multiple Unit Selection

#### Shift+Click
- Adds enitity to current selection
- Previous units remain selected

#### Box Select (Drag)
- Drag from one point to another
- All `RTS_BoxableComponent` units within the box are selected
- Can be combined with Shift to add to selection

#### Deselecting Units

By defaults unit can not be deselected. Only when selecting another entity does the previous selected entity get deselected.

## RTS_Selectable

The `RTS_Selectable` component enables a unit to be selected. Use the `priority` integer to determin which entity has the highest priority, for example when selecting entities of different types. This might be useful for casting abilities, or displaying the entity UI of only the highest priority entity.

Populate RTS_Selectable's `pickable` (ideally as a child component) to make the entity pickable (selection via mouse click), populate the `boxable` component to make it selectable via click and drag.


## RTS_Boxable

Requires a collision_shape `CollisionShape3D` to determine the bounds for the box selection. This collision_shape has to be of type `CapsuleShape3D` or `BoxShape3D`.


## RTS_PickablePhysicsComponent

Requires a static_body `StaticBody3D` used for raycasting to determine wether a unit can be selected (when hovered)

## Selection Feedback

RTS_Selectable toggles the visibilty of the following meshes to visually show hover/selection state.

```gdscript
@export var selection_cone: MeshInstance3D
@export var hover_quad: MeshInstance3D
```

## Programmatic Selection

While usually not needed, use RTS_Selection if you want to manually add entities to the selection.

```gdscript
#Add one or multiple entities
selection.add_to_selection_bulk(...)

# Remove from selection
selection.remove_from_selection_bulk(...)
```

## Spatial selection queries:

For spatial selections (finding units within a certain radius of a point) see [Spatial Hashing](../advanced/spatial-hashing.md)


## See Also

- [Player Input System](../player-input.md) - How input triggers selection
- [Selectable Component](../components/selectable.md) - Component details
- [Core Concepts](../core-concepts.md) - Architecture overview
