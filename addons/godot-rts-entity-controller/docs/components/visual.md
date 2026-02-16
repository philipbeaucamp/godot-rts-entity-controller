# Visual Component

The `RTS_VisualComponent`'s main purpose is to hold all visual elements of the entity, in particular the ones that require a pivot point for rotation.

It is the visual component, **not the RTS_Entity itself** which gets rotated by the attack or movement system.


### Properties

```gdscript
@export var meshes : Array[MeshInstance3D] = []
@export var flash_time = 0.05
```

The default implementation has an optional array of `MeshInstance3D`, which (if the material is a `StandardMaterial3D`) are flashed white (for the duration of `flash_time`) when receiving damage,

```gdscript
func on_health_damaged(_health: RTS_HealthComponent):
	if mats.is_empty() || timer != null:
		return

	for mat in mats:
		mat.emission_energy_multiplier = 1.0

	timer = get_tree().create_timer(flash_time)
	timer.timeout.connect(on_timeout)	
```

If unwanted, simply leaving the meshes empty will not run any code.


See [Components Overview](overview.md) for system integration.
