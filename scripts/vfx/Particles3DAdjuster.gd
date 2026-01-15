extends GPUParticles3D

class_name Particles3DAdjuster

@export var world_direction: Vector3
@export var camera: Camera3D

func adjust():
	pass
	# var screen_direction = camera.project_ray_normal(world_direction)
