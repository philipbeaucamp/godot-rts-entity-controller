# Selectable Component

The `SelectableComponent` makes a unit clickable or box selectable, needed to issue further commands, actions or cast abilities.
The component itself signifies whether an entity is selectable at all. Making a unit selectable (pickable) or box selectable (using a drawn rect) requires adding the respective `RTS_PickablePhysicsComponent` or `RTS_BoxableComponent`.

Whilst `RTS_PickablePhysicsComponent` requires a `StaticBody3D` and the correct collision layer to be set (collision_layer_selection), ``RTS_BoxableComponent`` requries a `CollisionShape3D` to determin the bounds and intersection with the user drawn rect on screen. This collision shape can be the same static body used for pickable physics.

The selection cone and hover_quad can be changed for any arbitrary meshes to toggle hover/selection visibility.

```gdscript
@export var selection_cone: MeshInstance3D
@export var hover_quad: MeshInstance3D
```


## Events

```gdscript
signal on_stop()
signal selected(value: bool)
```

Apart from the above signal, more selection signals can be found in `RTS_Selection`:

```gdscript
signal selection_changed(selection: Array[RTS_Selectable])
signal added_to_selection(selection: Array[RTS_Selectable])
signal removed_from_selection(selection: Array[RTS_Selectable])
signal hovered_pickable_set(pickable: RTS_PickablePhysicsComponent)
signal hovered_pickable_unset(pickable: RTS_PickablePhysicsComponent)
signal hovered_pickable_empty()
signal highest_selected_changed(entity: RTS_Entity)
```

## See Also

See [Selection System](../systems/selection.md) for more details.
