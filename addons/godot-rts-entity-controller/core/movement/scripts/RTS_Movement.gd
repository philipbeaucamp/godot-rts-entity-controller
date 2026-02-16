class_name RTS_Movement extends Node3D

# Class which coordinates group movement of RTS_Movable Entities

@export var camera : RTS_RaycastCamera
@export var collision_mask: int

static var next_session_uid : int = 0
static func generate_session_uid() -> int:
	next_session_uid += 1
	return next_session_uid

func get_current_mouse_world_pos() -> Vector3:
	var target_position = Vector3.ZERO
	var raycast = camera.get_mouse_position_raycast(collision_mask)
	if !raycast.is_empty():
		target_position = raycast.position
	else:
		printerr("Empty RayCast from MousePos in RTS_Movement!")	
	return target_position

#z can be ignored
func get_polygon_from_selection(selection : Array[RTS_Movable]):
	var packed_array = PackedVector3Array()
	for s in selection:
		packed_array.append(s.entity.global_position)
	return packed_array

func group_move(target_position: Vector3, source: Node3D, movables: Array[RTS_Movable], append: bool, type: RTS_Movable.Type):
	var group_positions : PackedVector3Array = []
	var entities: Array[RTS_Entity] = []

	for movable in movables:
		var e = movable.entity
		group_positions.append(e.global_position)
		entities.append(e)

	var center : Vector3
	var use_formation: bool = false
	if source == null:
		var group_center = calc_center(group_positions)
		if should_use_formation(target_position,entities,group_positions,group_center):
			center = group_center
			use_formation =  true

	#change MOVE -> ATTACK if source is attackable
	if source != null && type == RTS_Movable.Type.MOVE:
		if source is RTS_Entity && source.faction == RTS_Entity.Faction.ENEMY:
			type = RTS_Movable.Type.ATTACK

	var group_id = generate_session_uid()
	# for group in groups:
	for m in movables:
		var e : RTS_Entity = m.entity
		if !append:
			m._clear_targets()
		if source == m.entity:
			#Dont allow move to self
			continue
		if use_formation:
			# source should always be null since we're moving in formation
			var offset = e.global_position-center
			offset.y = 0
			m.append_to_targets([RTS_Target.new(target_position+offset,type,source,group_id,-offset)])
		else:
			m.append_to_targets([RTS_Target.new(target_position,type,source,group_id)])
	
func group_patrol(target_position: Vector3, source: Node3D, movables: Array[RTS_Movable], append: bool):
	var group_positions : PackedVector3Array = []
	for movable in movables:
		group_positions.append(movable.entity.global_position)
	var center = calc_center(group_positions)

	for m in movables:
		var e = m.entity
		if !append:
			m._clear_targets()
		if source == m.entity:
			#Dont allow patrol to self
			continue
		var id1 = generate_session_uid()
		var offset = e.global_position-center
		if m.targets.is_empty():
			var id2 = generate_session_uid()
			if source == null:
				m.append_to_targets([
					RTS_Target.new(e.global_position,RTS_Movable.Type.PATROL,null,id1),
					RTS_Target.new(target_position + offset,RTS_Movable.Type.PATROL,null,id2)
				])
			else :
				m.append_to_targets([
					RTS_Target.new(e.global_position,RTS_Movable.Type.PATROL,null,id1),
					RTS_Target.new(target_position,RTS_Movable.Type.PATROL,source,id2)
				])
		else:
			m.append_to_targets([
				RTS_Target.new(target_position + offset,RTS_Movable.Type.PATROL,source,id1)
			])

static func is_target_close_to_center(polygon: PackedVector3Array, target: Vector3, _pre_comp_center: Vector3 = Vector3.INF) -> bool:
	var _center = _pre_comp_center if _pre_comp_center != Vector3.INF else calc_center(polygon)
	var avg_distance = calc_avg_dist_to(_center,polygon)
	return target.distance_squared_to(_center) < avg_distance*avg_distance

static func calc_center(points: PackedVector3Array):
	if points.is_empty():
		return Vector3.ZERO
	var center = Vector3()
	for point in points:
		center += point
	return center / points.size()

static func calc_avg_dist_to(target: Vector3, points: PackedVector3Array) -> float:
	if points.is_empty():
		return 0
	var avg : float = 0
	for point in points:
		avg += point.distance_to(target)
	return avg / points.size()

##If suitable (entities are all in one main_grid cluster and target is not in that center), returns center
#to be used for offset calculation in formation move
static func should_use_formation(target: Vector3,entities: Array[RTS_Entity],positions: PackedVector3Array, group_center: Vector3 = Vector3.INF) -> bool:
	var main_grid : RTS_SpatialHashArea = RTS_SpatialHashArea.main_grid
	var clients: Dictionary[RTS_HashClient,bool] = {}
	for e in entities:
		if main_grid.entities.has(e):
			clients.set(main_grid.entities[e],true)
	var clusters = main_grid.grid.flood_fill_clusters(1,-1,clients) #Array[Array[Vector2i]]
	if clusters.size() == 1:
		#try use formation
		if !is_target_close_to_center(positions,target,group_center):
			return true
	return false
