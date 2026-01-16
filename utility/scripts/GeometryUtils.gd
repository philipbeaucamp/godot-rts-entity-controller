class_name RTS_GeometryUtils extends Node3D

# Contains utility functions for geometry-related tasks

enum Direction {
	FORWARD,
	RIGHT,
	BACKWARD,
	LEFT
}

static func direction_to_vector3(direction: Direction) -> Vector3:
	match (direction):
		Direction.FORWARD: return Vector3(0,0,-1)
		Direction.RIGHT: return Vector3(1,0,0)
		Direction.BACKWARD: return Vector3(0,0,1)
		Direction.LEFT: return Vector3(-1,0,0)
	return Vector3(0,0,1)

func snap_node_to_navigation_layer(node: Node3D):
	snap_node(node,Controls.settings.collision_layer_navigation)

func snap_node(node: Node3D, layer: int):
	var snapped_position = get_snapped_position(node,layer)
	node.global_position = snapped_position

func get_snapped_position(node: Node3D, layer: int) -> Vector3:
	var ray_length := 100.0
	var collision_mask = 1 << (layer-1)
	var space_state : PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from = node.global_transform.origin + Vector3.UP * ray_length
	var to = node.global_transform.origin + Vector3.DOWN * ray_length
	var query = PhysicsRayQueryParameters3D.create(from,to,collision_mask,[node])
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	else:
		return node.global_position

func is_not_colliding(pos: Vector3, shape: Shape3D, layers: Array[int]) -> bool:
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = pos
	var mask := 0
	for layer in layers:
		mask |= 1 << (layer -1)
	query.collision_mask = mask
	var result = space.intersect_shape(query,1) #max results = 1
	return result.is_empty()

func random_point_in_sphere_fast(radius: float) -> Vector3:
	var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var dist = randf() * radius
	return dir * dist

func random_point_on_sphere_fast(radius: float) -> Vector3:
	var dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	return dir * radius

func random_front_global_point_on_sphere_fast(radius: float, target_pos: Vector3, attacker_pos: Vector3) -> Vector3:
	var forward_dir = (attacker_pos - target_pos).normalized()
	var random_dir = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
	#Blend random vector toward the attacker-facing direction
	var biased_dir = (random_dir + forward_dir * 2).normalized()
	return target_pos + biased_dir * radius

func random_point_in_box(half_extents: Vector3) -> Vector3:
	return Vector3(
		randf_range(-half_extents.x, half_extents.x),
		randf_range(-half_extents.y, half_extents.y),
		randf_range(-half_extents.z, half_extents.z)
	)

func random_point_in_area(area: Area3D) -> Vector3:
	var collision_shape := area.get_node_or_null("CollisionShape3D")
	if collision_shape == null:
		push_error("Area3D has no CollisionShape3D child.")
		return area.global_position

	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape == null:
		push_error("random_point_in_area only supports BoxShape3D for now.")
		return area.global_position

	var local_point := random_point_in_box(box_shape.size / 2.0)
	return area.global_transform * local_point

func random_front_global_point_on_box_fast(half_extents: Vector3, target_pos: Vector3,attacker_pos: Vector3):
	var forward_dir = (attacker_pos - target_pos).normalized()
	# Pick dominant axis
	var abs_dir = forward_dir.abs()
	var axis: int
	if abs_dir.x > abs_dir.y and abs_dir.x > abs_dir.z:
		axis = 0
	elif abs_dir.y > abs_dir.z:
		axis = 1
	else:
		axis = 2

	var side = sign(forward_dir[axis])

	# Random point on that face
	var x = randf_range(-half_extents.x, half_extents.x)
	var y = randf_range(-half_extents.y, half_extents.y)
	var z = randf_range(-half_extents.z, half_extents.z)

	match axis:
		0: x = side * half_extents.x
		1: y = side * half_extents.y
		2: z = side * half_extents.z

	return target_pos + Vector3(x, y, z)

#Utility function useful to get approximate global impact positions for projectiles etc
#given a position (from) and a target collisionshape. Will return a global position on the
#face of the shape facing the from position
func random_front_facing_global_point_on_shape(collision_shape: CollisionShape3D, from: Vector3) -> Vector3:
	var shape = collision_shape.shape
	if shape is SphereShape3D:
		return random_front_global_point_on_sphere_fast(shape.radius,collision_shape.global_position,from)
	elif shape is BoxShape3D:
		return random_front_global_point_on_box_fast(shape.size * 0.5,collision_shape.global_position,from)
	elif shape is CapsuleShape3D:
		return random_front_global_point_on_sphere_fast(shape.radius,collision_shape.global_position,from)
	else:
		printerr("Unsupported shape: %s" % shape)
		return Vector3.ZERO

func get_center_2d(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var center = Vector2()
	for point in points:
		center += point
	return center / points.size()
