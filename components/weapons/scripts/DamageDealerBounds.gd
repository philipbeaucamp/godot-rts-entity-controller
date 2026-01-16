class_name DamageDealerBounds extends DamageDealer

@export var box: CollisionShape3D
@export var debug: bool = false
@export var affect_heat_map: bool = false

var bounds: Vector2

func _ready():
	var box_size : Vector3 = (box.shape as BoxShape3D).size
	bounds = Vector2(box_size.x,box_size.z)

func deal_damage(_target: RTS_Defense,pos: Vector3):

#todo check chatgpt history: (https://chatgpt.com/c/6906fe73-cbbc-8323-be18-c72918a30948)
	
	#0. Creating data used in both #1 and #3 here
	var box_center = box.global_transform.origin
	var box_half_extents: Vector3 = box.shape.size * 0.5
	var forward = -box.global_transform.basis.z.normalized()
	var angle_y : float = atan2(forward.x,forward.z) #this is the yaw (rotation around Y), aka the box_angle_rad

	#1. Create AABB from collision shape box
	var aabb: AABB = get_aabb_from_rotated_box(box_center,box_half_extents,angle_y)
	
	#2. query entities using AABB
	var group_id : int = -1 if publisher &&  publisher.attack.player_assigned_target_is_ally else RTS_Entity.Faction.ENEMY
	var entities: Array[RTS_Entity] = SpatialHashArea.main_grid.find_entities_using_aabb(aabb,true,group_id)
	
	#3. do precise overlap checks for each candidate
	var amount: int = entities.size()
	for i in range(amount -1,-1,-1):
		var entity: RTS_Entity = entities[i]
		if !entity.defense || !circle_overlaps_rotated_box(
			entity.global_position,
			entity.defense.defense_range,
			box_center,
			box_half_extents,
			angle_y
			):
				entities.remove_at(i)
		
	for entity in entities:
		entity.defense.get_attacked_by(self)

	if affect_heat_map:
		RTSEventBus.heatmap_burn_shape.emit(box)

	if (publisher && publisher.is_debugged) || debug:
		##DebugDraw3D.draw_aabb(aabb,Color.YELLOW,0.4)
		##DebugDraw3D.draw_box(box.global_position,box.global_transform.basis,box.shape.size,Color.RED,true,1)
		pass

## ignores Y, all XZ projected
func get_aabb_from_rotated_box(center: Vector3,half_extents: Vector3, angle_rad):
	var hx = half_extents.x
	var hz = half_extents.z

	var cos_a = cos(angle_rad)
	var sin_a = sin(angle_rad)

	var half_w = abs(hx * cos_a) + abs(hz * sin_a)
	var half_d = abs(hx * sin_a) + abs(hz * cos_a)

	var min_vec = Vector3(center.x - half_w,0,center.z - half_d)
	var max_vec = Vector3(center.x + half_w,1,center.z + half_d)
	return AABB(min_vec,max_vec - min_vec)
	
func get_aabb_from_collision_shape(collision_shape: CollisionShape3D) -> AABB:
	var shape : BoxShape3D = collision_shape.shape as BoxShape3D
	if !shape:
		return AABB()

	var half_extents : Vector3 = shape.size * 0.5
	var pos = collision_shape.global_transform.origin
	var forward = -collision_shape.global_transform.basis.z.normalized()
	var angle_y = atan2(forward.x,forward.z) #this is the yaw (rotation around Y), aka the box_angle_rad

	var hx = half_extents.x
	var hz = half_extents.z

	var cos_a = cos(angle_y)
	var sin_a = sin(angle_y)

	var half_w = abs(hx * cos_a) + abs(hz * sin_a)
	var half_d = abs(hx * sin_a) + abs(hz * cos_a)

	var min_vec = Vector3(pos.x - half_w,0,pos.z - half_d)
	var max_vec = Vector3(pos.x + half_w,1,pos.z + half_d)
	return AABB(min_vec,max_vec - min_vec)

## ignores Y, all XZ projected
func circle_overlaps_rotated_box(
	circle_pos: Vector3,
	circle_radius: float,
	box_center: Vector3,
	box_half_extents: Vector3,
	box_angle_rad: float
) -> bool:

	# Translate into box local space
	var local_x = circle_pos.x - box_center.x
	var local_z = circle_pos.z - box_center.z

	var cos_a = cos(box_angle_rad)
	var sin_a = sin(box_angle_rad)

	# Rotate into box local space (inverse rotation)
	var px = local_x * cos_a - local_z * sin_a
	var pz = local_x * sin_a + local_z * cos_a

	# Compute closest point on box to circle center
	var dx = max(abs(px) - box_half_extents.x, 0.0)
	var dz = max(abs(pz) - box_half_extents.z, 0.0)

	# If the distance from circle center to box edge < radius, overlap
	return (dx * dx + dz * dz) <= (circle_radius * circle_radius)
