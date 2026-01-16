class_name RTS_RaycastCamera extends Camera3D

@export var default_position: Vector3 = Vector3(7.0,10.0,7.0)
@export var default_rotation_in_degrees: Vector3 = Vector3(-45.0,45,0)
@export var default_size : float = 10

var cache_per_collision_mask: Dictionary = {} #cached each frame
var last_processed_frame: int = -1

func to_screen_packed(world_pos: PackedVector3Array) -> PackedVector2Array:
	var packed_screen = PackedVector2Array()
	for pos in world_pos:
		packed_screen.append(self.unproject_position(pos))
	return packed_screen

#returns cached raycast result, per frame, per collision_mask
func get_mouse_position_raycast(collision_mask: int) -> Dictionary:
	if last_processed_frame != Engine.get_physics_frames():
		cache_per_collision_mask.clear()

	if last_processed_frame == Engine.get_physics_frames() && cache_per_collision_mask.has(collision_mask):
		return cache_per_collision_mask[collision_mask]

	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var from = project_ray_origin(mouse_pos)
	var to = project_ray_normal(mouse_pos) * 1000 + from
	var query = PhysicsRayQueryParameters3D.create(from,to,collision_mask,[self])
	var result = space_state.intersect_ray(query)
	cache_per_collision_mask[collision_mask] = result
	last_processed_frame = Engine.get_physics_frames()
	return cache_per_collision_mask[collision_mask]
