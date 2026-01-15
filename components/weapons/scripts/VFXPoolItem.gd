extends ObjectPoolItem

class_name VFXPoolItem

@export var impact_vfx : Particles3DContainer

func set_active(value: bool):
	super.set_active(value)
	if value:
		impact_vfx.restart_all()
		await get_tree().create_timer(impact_vfx.max_particle_time).timeout
		retire()

func retire():
	set_active(false)
