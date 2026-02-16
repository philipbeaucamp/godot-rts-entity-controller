# Health Component 

Component that keeps track of entities health.

Setting `instantiate_health_bar` to true will auto instantiate the `health_bar.tscn` scene for each entity, at the `RTS_HealthComponents` Node3D position.

Apart from a few usual functions (`heal`, `heal_percentage`), it contains the `take_damage` function to reduce health,


```gdscript
func take_damage(dmg : float):
	if !component_is_active:
		return
	if dmg <= 0 || RTS_Controls.settings.invincibility:
		return
		
	health -= dmg
	health_changed.emit(self)
	health_damaged.emit(self)
	if health <= 0 && !is_dead:
		die()	
```

which emits the `death` signal

```gdscript
func die():
	is_dead = true
	set_component_inactive()
	death.emit(entity)
```

used by a variety of systems, perhaps most notably used by `RTS_Entity` to emit the `end_of_life` signal which turns off any `RTS_Component`, if this default behaviour is not override.


### Taking Damage and RTS_Defense

Usually scripts don't set the health of `RTS_Health` directly, but go through `RTS_Defense` which can "receive" damage (for example from other entities, damage dealers, weapons) and the call `take_damage` in turn.

## Events

```gdscript
signal death(entity: RTS_Entity)
signal health_changed(health: RTS_HealthComponent)
signal health_damaged(health: RTS_HealthComponent)
```

See [Combat System](../systems/combat.md) for complete combat details.
