# Camera System

RTS-style camera controls for player navigation.

## Overview

The camera system provides:

- Smooth panning
- Rotation around focus point
- Zoom in/out
- Boundary constraints
- Height-based perspective

## Basic Setup

```gdscript
extends Node3D

func _ready():
    RTSPlayerInput.set_camera($Camera3D)
    RTSPlayerInput.enable_input()
```

## Camera Controls

### Pan
- **Middle Mouse + Drag** or **Arrow Keys**
- Moves camera across the map

### Rotate
- **Right Mouse + Drag** (context-dependent)
- Rotates camera around target

### Zoom
- **Mouse Wheel**
- In/out camera distance

## Configuration

Adjust camera behavior:

```gdscript
# Camera distance
var min_distance = 5.0
var max_distance = 50.0

# Rotation speed
var rotation_speed = 2.0

# Zoom speed
var zoom_speed = 2.0
```

## Focus Points

Set what the camera looks at:

```gdscript
# Focus on a unit
camera.focus_on(unit)

# Focus on a position
camera.focus_on_position(position)

# Free look
camera.set_free_look()
```

## Follow

Make camera follow selected units:

```gdscript
if selected_units.size() == 1:
    camera.follow(selected_units[0])
else:
    # Focus on center of group
    var center = calculate_group_center(selected_units)
    camera.focus_on_position(center)
```

## Bounds

Constrain camera movement:

```gdscript
@export var map_bounds: Rect2i

func _process(delta: float) -> void:
    # Clamp camera position to bounds
    camera.global_position = camera.global_position.clamp(
        Vector3(map_bounds.position.x, camera.global_position.y, map_bounds.position.y),
        Vector3(map_bounds.end.x, camera.global_position.y, map_bounds.end.y)
    )
```

## Height Management

Adjust camera height based on zoom:

```gdscript
func update_camera_height() -> void:
    var height = lerp(min_height, max_height, zoom_factor)
    camera.global_position.y = height
```

## See Also

- [Player Input System](../player-input.md) - Input handling
- [Core Concepts](../core-concepts.md) - System architecture
