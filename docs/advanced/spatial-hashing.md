# Spatial Hashing

Godots native collisios checks are usually very fast and well integrated. Therefore this tool uses Area3D and CharacterBody4D's built in collision checks and events on many occasions.

However, for more flexibility and in order to perform custom qeueries, a spatial hashing system implemented in gdscript is provided.

A good example to check its use is `RTS_DamageDealerAoE` which uses 

```gdscript
RTS_SpatialHashArea.main_grid.find_entities(...)
```

to find nearby entities.

## Overview

Apart from `RTS_SpatialHashArea`, the remaining spatial hash scripts (RTS_HashClient, RTS_SpatialHashFast, RTS_SpatialHashUtils, RTS_HashNode) can be used as an independent library, as they are self containing.

Spatial hashing divides the map into a grid for faster spatial queries.

## Benefits

- **Fast spatial queries** - O(1) instead of O(n)
- **Better performance** - Especially with many units
- **Efficient updates** - Only rebuild affected cells
- **Scalable** - Works with large maps and unit counts

## Basic Implementation

While the internal spatial hashing algorithms are complex, the `RTS_SpatialHashArea` component provides a simple interface for querying entities efficiently.

### RTS_SpatialHashArea Component

`RTS_SpatialHashArea` is an `Area3D` that automatically manages a spatial hash grid for fast entity lookups.

#### Setup

Create a scene with an `RTS_SpatialHashArea` node and a `CollisionShape3D` child:

```
Level (Node3D)
├── RTS_SpatialHashArea (Area3D)
│   └── CollisionShape3D (BoxShape3D)
└── Units...
```

#### Properties

```gdscript
@export var id: String = "1"  # Unique identifier for the grid
@export var INIT_CELL_SIZE = 1.0  # Size of each grid cell (larger = fewer cells)
@export var visual_debug: bool = false  # Visualize grid (requires DebugDraw3D addon)
@export var auto_update_clients: bool = false  # Auto-update entity positions each frame
```

#### How It Works

1. **Automatic Registration** - When an `RTS_Entity` with `space_hash = true` enters the scene, it's automatically added to the grid
2. **Grid Cells** - The collision shape defines the grid bounds; cell size determines query speed vs accuracy
3. **Position Tracking** - Entity positions update in the grid (manually or automatically)
4. **Fast Queries** - Find entities by position/radius in O(1) time instead of O(n)

#### Static Main Grid

The last `RTS_SpatialHashArea` running in the scene becomes the main grid:

```gdscript
# (in _ready)
#set main_grid
main_grid = self
```

```gdscript
# Access globally
var nearby = RTS_SpatialHashArea.main_grid.find_entities(position, radius, exact=false)
```

Overwrite this functionality if you want to assign main_grid in a different fashion. It is important that this main_grid is set, as most queries will use the main_grid to query by default. Ofcourse it is possible use multiple SpatialHashAreas and query them independently as well.

#### Common Methods

Query entities by position:

```gdscript
# Find by radius
var entities = spatial_hash.find_entities(position, radius, exact=false)

# Find by bounds (Vector2 x/z size)
var entities = spatial_hash.find_entities_bounds(position, bounds, exact=false)

# Find by AABB (3D bounding box)
var entities = spatial_hash.find_entities_using_aabb(aabb, exact=true)

# exact=true: Precise distance checks
# exact=false: Faster, grid-based checks
```

#### Faction Filtering

Find only enemies or allies:

```gdscript
# Group parameter: -1 = all, 0 = PLAYER faction, 1 = ENEMY faction, 2 = NEUTRAL
var enemies = spatial_hash.find_entities(position, radius, exact=false, group=1)
```

#### Cell Size Tuning

**Larger cells** = Fewer cells to check, but more false positives

```gdscript
INIT_CELL_SIZE = 5.0  # Each cell is 5x5 units
```

**Smaller cells** = More accurate but slower

```gdscript
INIT_CELL_SIZE = 1.0  # Each cell is 1x1 units
```

**Rule of thumb**: Set cell size roughly equal to average entity search radius

#### Example Usage

```gdscript
# Find nearby enemies to attack
func find_targets(attack_range: float) -> Array[RTS_Entity]:
    var nearby = RTS_SpatialHashArea.main_grid.find_entities(
        global_position,
        attack_range,
        exact=false,
        group=RTS_Entity.Faction.ENEMY
    )
    return nearby

# Check if area is clear of enemies
func is_area_clear(center: Vector3, radius: float) -> bool:
    var enemies = RTS_SpatialHashArea.main_grid.find_entities(
        center,
        radius,
        exact=true,
        group=RTS_Entity.Faction.ENEMY
    )
    return enemies.is_empty()
```

#### Manual Updates

If `auto_update_clients = false`, manually update positions:

```gdscript
# Call when entities move significantly
RTS_SpatialHashArea.main_grid.update_clients()
```

If false, make sure to call this before doing any queries.

#### Visual Debugging

Consider adding the DebugDraw3D addon to debug the grid.
This draws grid cells and entity positions for troubleshooting.

## See Also

- [Best Practices](../reference/best-practices.md) - Performance tips
- [Core Concepts](../core-concepts.md) - System architecture
