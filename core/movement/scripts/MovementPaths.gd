extends Node3D

class_name MovementPaths

@export var selection: RTS_Selection
@export var colors: Dictionary[RTS_Movable.Type,Color] = {}
@export var pm: RTS_PoolManager

var paths: Dictionary[int,Path] = {} # target_group_id to  path
var paths_claims: Dictionary[int,int] #target_group_id to number of movables
var individual_paths: Dictionary[RTS_Entity,Path] # first path of unit

var points: Dictionary[int,RTS_WaypointPoolItem] = {}
var points_claims: Dictionary[int,int] = {} #target_group_id to number of targets

var path_pool: RTS_ObjectPool
var waypoint_pool: RTS_ObjectPool

func _ready():
	path_pool = pm.get_pool("path")
	waypoint_pool = pm.get_pool("waypoint")
	selection.removed_from_selection.connect(on_removed_from_selection)
	selection.added_to_selection.connect(on_added_to_selection)
	RTSEventBus.entity_exiting_tree.connect(on_entity_exit_tree)

func create_path(start: Vector3, end: Vector3, type: RTS_Movable.Type, start_source: Node3D, end_source: Node3D,alpha_factor:float) -> Path:
	var path = path_pool.get_item(false) as Path
	path.set_up(start,end,colors[type],start_source,end_source,alpha_factor)
	path.set_active(true)
	return path

func create_point(pos: Vector3, type: RTS_Movable.Type, source: Node3D) -> RTS_WaypointPoolItem:
	var point = waypoint_pool.get_item(false) as RTS_WaypointPoolItem
	point.global_position = pos + Vector3.UP * 0.025
	point.set_color(colors[type])
	point.set_source(source)
	point.set_active(true)
	return point

func on_added_to_selection(selectables: Array[RTS_Selectable]):
	for s in selectables:
		var movable = s.entity.movable
		if movable != null:
			movable.after_targets_added.connect(on_after_targets_added)
			movable.before_all_targets_cleared.connect(on_before_all_targets_cleared)
			movable.next_target_just_reached.connect(on_next_target_just_reached)
			add_paths(movable.targets)
			add_points(movable.targets)
			if movable.targets.size() > 1 && movable.next.type != RTS_Movable.Type.PATROL:
				add_individual_path(movable.entity,movable.next)

func on_removed_from_selection(selectables: Array[RTS_Selectable]):
	for s in selectables:
		var movable = s.entity.movable
		if movable != null:
			movable.after_targets_added.disconnect(on_after_targets_added)
			movable.before_all_targets_cleared.disconnect(on_before_all_targets_cleared)
			movable.next_target_just_reached.disconnect(on_next_target_just_reached)
			remove_points(movable.targets)
			remove_paths(movable.targets)
			remove_individual_path(movable.entity)

func add_paths(targets: Array[RTS_Target]):
	for target in targets:
		if !target.display:
			continue
		#add claim
		var id :int = target.group_id
		if !target.previous && id == -1: #index 0 handled by individual path
			continue
		if !paths_claims.has(id):
			paths_claims[id] = 0
		paths_claims[id] += 1
		#paths
		if target.previous: #meaning this is not index 0 i.e there exist a target before
			if !paths.has(id):
				var previous_source :Node3D = target.previous.source if is_instance_valid(target.previous.source) else null
				var path = create_path(
					target.previous.pos + target.previous.offset,
					target.pos + target.offset,
					target.type,
					previous_source,
					target.source,
					1
				)					
				# print("Added one path")
				paths[id] = path

func remove_paths(targets: Array): 
	for target: RTS_Target in targets:
		if !target.previous || !target.display:
			continue
		var id : int = target.group_id
		if id == -1:
			continue
		if paths_claims.has(id):
			paths_claims[id] -= 1
			#sanity check
			if paths_claims[id] < 0:
				printerr("Negative path claims")
				paths_claims[id] = 0
		if paths_claims[id] != 0:
			continue
		if paths.has(id):
			var path = paths[id]
			path_pool.retire_item(path)
			paths.erase(id)
			# print("Removed one path")

func add_points(targets: Array[RTS_Target]):
	for target : RTS_Target in targets:
		if !target.display:
			continue
		#add claim
		var id = target.group_id
		if id == -1:
			continue
		if !points_claims.has(id):
			points_claims[id] = 0
		points_claims[id] += 1
		#points
		if !points.has(id):
			var pos = target.pos + target.offset
			# var source = null
			# if is_instance_valid(target.source):
			# 	source = movable.target_source[index] #todo maybe do a clean up in movable itself ?
			var point = create_point(pos, target.type,target.source)
			points[id] = point


func remove_points(targets: Array[RTS_Target]):
	for target in targets:
		if !target.display:
			continue
		var id = target.group_id
		if id == -1:
			continue
		if points_claims.has(id):
			points_claims[id] -= 1
			#sanity check
			if points_claims[id] < 0:
				printerr("Negative point claims")
				points_claims[id] = 0
		if points_claims[id] != 0:
			continue
		#points
		if points.has(id):
			var point = points[id]
			waypoint_pool.retire_item(point)
			points.erase(id)


func add_individual_path(entity: RTS_Entity,target:RTS_Target):
	if !individual_paths.has(entity):
		var target_source: RTS_Entity = target.source if target.source && is_instance_valid(target.source) else null 
		var path = create_path(
			entity.global_position,
			target.pos + target.offset,
			target.type,
			entity,
			target_source,
			0.1
		)					
		individual_paths[entity] = path

func remove_individual_path(entity: RTS_Entity):
	if individual_paths.has(entity):
		var path = individual_paths[entity]
		path_pool.retire_item(path)
		individual_paths.erase(entity)

func on_after_targets_added(_movable: RTS_Movable,targets: Array[RTS_Target]):
	add_paths(targets)
	add_points(targets)
	if _movable.targets.size() > 1 && _movable.next.type != RTS_Movable.Type.PATROL:
		add_individual_path(_movable.entity,_movable.next)

func on_before_all_targets_cleared(movable: RTS_Movable):
	#simply remove everything
	remove_points(movable.targets)
	remove_paths(movable.targets)
	remove_individual_path(movable.entity)

func on_next_target_just_reached(movable: RTS_Movable, target: RTS_Target):
	if target.type != RTS_Movable.Type.PATROL:
		remove_points([target])
		handle_normal_next_target_just_reached(movable,target)	
	# only remove all patrol paths next target is not patrol
	elif target.next && target.next.type != RTS_Movable.Type.PATROL:
			#pop all patrol points and paths
			var walk_back : RTS_Target = target
			var to_erase: Array[RTS_Target] = []
			while walk_back:
				assert(walk_back.type == RTS_Movable.Type.PATROL,"Found non patrol target")
				to_erase.append(walk_back)
				walk_back = walk_back.previous
			remove_points(to_erase)
			remove_paths(to_erase)
			handle_normal_next_target_just_reached(movable,target)

func handle_normal_next_target_just_reached(movable: RTS_Movable, target: RTS_Target):
	remove_individual_path(movable.entity) #remove old self path
	if target.next && target.next.type != RTS_Movable.Type.PATROL:
		if target.next:
			remove_paths([target.next])
		if movable.targets.size() > 2:
			add_individual_path(movable.entity,target.next) #add new self path

func on_entity_exit_tree(entity: RTS_Entity):
	remove_individual_path(entity)
