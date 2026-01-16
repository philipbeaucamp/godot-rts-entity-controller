class_name RTS_Movable extends RTS_Component

# https://starcraft.fandom.com/wiki/Marine_(StarCraft_II)
# Todo: consider Acceleration, lateral acceleration, deceleration

#GDC SC2 Pathing
# https://www.gdcvault.com/play/1014514/AI-Navigation-It-s-Not

#GDC Steering
#https://gdcvault.com/play/1018262/The-Next-Vector-Improvements-in

signal after_targets_added(movable: RTS_Movable, targets: Array[Target])
signal next_target_changed(movable: RTS_Movable) #onyl called for acute target change
signal before_all_targets_cleared(movable: RTS_Movable)
signal all_targets_cleared(movable: RTS_Movable)
signal next_target_just_reached(movable: RTS_Movable, target: Target) # called just before removal of index
signal final_target_reached(movable: RTS_Movable)

enum State {
	IDLE = 0,
	 #if we don't need to follow targets, we don't need this state. This makes things much simpler.
	 #However, I'm keeping it in for now since it might be useful to readd "entity following" logic later
	REACHED_SOURCE_TARGET = 1,
	HOLD = 2,
	PATROL = 3,
	WALK = 4,
	RETURN_TO_IDLE = 5, #Unit automatically returns to idle position
	PUSHED = 6 # Unit is pushed by external forces
	} # <= 2 means unit is stationary, > 2 is moving, > 3 is moving without patrol

enum Type {
	NULL = 0,
	PATROL = 1,
	MOVE = 2,
	ATTACK = 3,
	MOVEATTACK = 4
	} #NULL only used for signal emitting since can't emit null variable and for null checks

@export_group("General")
@export var speed: float = 5
@export var stop_distance : float = 0.25
@export var pivot: Node3D #Node which gets rotated. Note: RTS_Entity node is never rotated to keep things simple
@export var steering : Area3D

@export_group("Components")
@export var nav_agent: NavigationAgent3D

@export_group("Separation")
# @export var max_force : float = 1
@export var use_separation :bool = true 
@export var separation_multiplier : float = 1.0
@export_group("Avoidance")
@export var use_avoidance :bool = true 
@export var avoidance_multiplier : int = 10
@export_group("Push")
@export var allow_being_pushed : bool = true


var sm: CallableStateMachine = CallableStateMachine.new()

const VEL_Y_CAP = 2

var targets : Array[Target]
var next: Target
var last: Target

#reached source
var reached_source: RTS_Entity
var elapsed_since_reached_source_moved: float = 0 
var min_reaction_time_source_moved : float = 0.1

var idle_position: Vector3
var backwards: bool = false

var prev_avoidance: Vector3
var next_target_has_just_been_set : bool = false
var externally_immovable: bool = false
var stop_distance_squared: float 

#A list of (priority, controller) tuples that can overwrite this scripts physics process
var active_controller: Object #Either this or a class that overrides movement, i.e. RTS_AttackVariant
var controller_overrides: Array = []

#nav_mesh
var ignore_target_update_distance_squared = 0.0025 # 0.05^2
var prev_target = Vector3.INF

#steering
var steering_neighbors: Dictionary[Node3D,RTS_Movable] = {} #note: RTS_Movable Value can be nullable

#pushing
var accumulated_push = Vector3.ZERO
var min_push_time : float = 0.1
var elapsed_time_since_last_push: float = 0

#force push 
var has_been_force_pushed_this_tick : bool = false
var accumulated_force = Vector3.ZERO #similar to push, but not capped and always applied

#return to idle
var seconds_until_start_return_to_idle = 2.5 # todo make exponential distributed #used as a delay after having been pushed
var return_to_idle_time = 0

func increase_speed_percent(percentage: float):
	speed *= (1 + percentage)

func add_controller_override(controller: Object, priority: int) -> void:
	controller_overrides.append({ "priority": priority, "controller": controller })
	controller_overrides.sort_custom(func(a, b): return b["priority"] - a["priority"])
	active_controller = controller_overrides[0].controller

func remove_controller_override(controller: Object) -> void:
	controller_overrides = controller_overrides.filter(func(entry): return entry["controller"] != controller)
	controller_overrides.sort_custom(func(a, b): return b["priority"] - a["priority"])
	if controller_overrides.is_empty():
		active_controller = null
	else:
		active_controller = controller_overrides[0].controller

func _ready():
	super._ready()
	
	stop_distance_squared = stop_distance * stop_distance
	
	sm.add_states(State.IDLE,state_idle,enter_idle,Callable())
	sm.add_states(State.REACHED_SOURCE_TARGET,state_reached_source_target,enter_reached_source_target,exit_reached_source_target)
	sm.add_states(State.HOLD,state_hold,enter_hold,Callable())
	sm.add_states(State.WALK,state_walk,Callable(),Callable())
	sm.add_states(State.PATROL,state_patrol,Callable(),exit_patrol)
	sm.add_states(State.RETURN_TO_IDLE,state_return_to_idle,enter_return_to_idle,Callable())
	sm.add_states(State.PUSHED,state_pushed,enter_pushed,Callable())
	sm.set_initial_state(State.IDLE)

	if entity.selectable != null:
		entity.selectable.on_stop.connect(stop)

	steering.body_entered.connect(on_steering_body_entered)
	steering.body_exited.connect(on_steering_body_exited)
	
func set_component_active():
	super.set_component_active()
	add_controller_override(self,0)
	steering.set_collision_mask_value(Controls.settings.collision_layer_units,true)
	steering.set_collision_mask_value(Controls.settings.collision_layer_buildings_and_rocks,true)
	steering.set_deferred("monitorable",true)
	steering.set_deferred("monitoring",true)

func set_component_inactive():
	super.set_component_inactive()
	remove_controller_override(self)
	steering.set_deferred("monitorable",false)
	steering.set_deferred("monitoring",false)

func _physics_process(delta: float):
	if !component_is_active:
		return

	#update target if source has moved
	if next && next.source != null:
		#update obstacle
		if next.source.obstacle:
			var dir = (entity.global_position - next.source.global_position).normalized()
			next.pos = next.source.global_position + dir * next.source.obstacle.obstacle_radius
		#check source movement
		elif next.pos.distance_squared_to(next.source.global_position) > ignore_target_update_distance_squared:
				next.pos = next.source.global_position		

	#Only the active controller's logic is called.
	#This is done so it is easy to override movement logic from other components, e.g. attack component
	if active_controller:
		externally_immovable = active_controller.is_externally_immovable(self)
		if active_controller == self:
			sm.updatev([delta])
		else:
			active_controller.physics_process_override_movable(delta,self)
	else:
		externally_immovable = false

	next_target_has_just_been_set = false
	has_been_force_pushed_this_tick = false
	
#------------------------STATES---------------------------
func enter_idle():
	if sm.previous_state != State.PUSHED:
		idle_position = entity.global_position
	entity.velocity = Vector3.ZERO

func enter_hold():
	idle_position = entity.global_position
	entity.velocity = Vector3.ZERO

func enter_return_to_idle():
	return_to_idle_time = 0.0

func enter_reached_source_target():
	entity.velocity = Vector3.ZERO
	reached_source = next.source
	elapsed_since_reached_source_moved = 0

func enter_pushed():
	elapsed_time_since_last_push = 0.0

func exit_reached_source_target():
	reached_source = null

func exit_patrol():
	backwards = false

func state_idle(delta: float):

	if accumulated_push != Vector3.ZERO:
		sm.change_state(State.PUSHED)

	if accumulated_force != Vector3.ZERO:
		apply_accumulated_force(delta)

	if next:
		sm.change_state(determine_state(next))
	else:
		if idle_position.distance_squared_to(entity.global_position) > stop_distance_squared:
			return_to_idle_time += delta
			if return_to_idle_time > seconds_until_start_return_to_idle:
				sm.change_state(State.RETURN_TO_IDLE)
				append_to_targets([Target.new(idle_position,Type.MOVEATTACK,null,-1)])

func state_reached_source_target(delta: float):
	if accumulated_push != Vector3.ZERO:
		sm.change_state(State.PUSHED)

	if accumulated_force != Vector3.ZERO:
		apply_accumulated_force(delta)
	
	if next:
		if !next.source || next.source != reached_source:
			sm.change_state(determine_state(next))
		elif steering_neighbors.has(next.source):
			return
		#if source target has moved, follow (todo possible to add delay)
		elif elapsed_since_reached_source_moved > 0 || (reached_source.movable != null && reached_source.movable.sm.current_state > State.HOLD):
			elapsed_since_reached_source_moved += delta
			if elapsed_since_reached_source_moved > min_reaction_time_source_moved:
				sm.change_state(determine_state(next))
	else:
		sm.change_state(State.IDLE)

func state_hold(delta: float):
	if next:
		sm.change_state(determine_state(next))
	
	if accumulated_force != Vector3.ZERO:
		apply_accumulated_force(delta)

func state_walk(delta: float):
	if next:
		if next_target_has_just_been_set:
			sm.change_state(determine_state(next))
			#actually returning here is not good, because it will not run move() so that
			#the bool first_target_just_set has no effect on things like avoidance etc
			#keep an eye on the comment below
			#Returning because of the chance that we could reach next target this frame
			#even though we are in "Walk" state, not patrol state
		if steering_neighbors.has(next.source):
			on_next_target_reached()

			#Leaving this in so REACHED_SOURCE_TARGET can be used in future if needed
			#if targets.size() > 1:
				#on_next_target_reached()
			#else:
				#sm.change_state(State.REACHED_SOURCE_TARGET)
		else:
			if accumulated_force != Vector3.ZERO:
				apply_accumulated_force(delta)
			else:
				move(delta)
	else:
		sm.change_state(State.IDLE)
	
func state_patrol(delta: float):
	if !next || next.type != Type.PATROL:
		sm.change_state(determine_state(next))
		return

	if next && steering_neighbors.has(next.source):
		on_next_target_reached()
	elif accumulated_force != Vector3.ZERO:
		apply_accumulated_force(delta)
	else:
		move(delta)

func state_return_to_idle(delta: float):
	if !next || next_target_has_just_been_set:
		sm.change_state(determine_state(next))
		
	if accumulated_force != Vector3.ZERO:
		apply_accumulated_force(delta)
	else:
		move(delta)

var last_push: Vector3 = Vector3.ZERO

func state_pushed(delta: float):
	elapsed_time_since_last_push += delta

	if accumulated_push != Vector3.ZERO:
		last_push = accumulated_push
		apply_push(accumulated_push,delta)
		accumulated_push = Vector3.ZERO
		elapsed_time_since_last_push = 0
	elif last_push != Vector3.ZERO:
		apply_push(last_push,delta)


	if next_target_has_just_been_set || elapsed_time_since_last_push > min_push_time:
		sm.change_state(determine_state(next))

#--------------------------------------------------

# Decides whether this unit can be "pushed" by exernal forces
func is_externally_immovable(_movable: RTS_Movable) -> bool:
	return sm.current_state == State.HOLD

func set_next_target(new_next: Target):
	if next == new_next:
		return

	last = next
	next = new_next

	next_target_has_just_been_set = true
	next_target_changed.emit(self)

func insert_before_next_target(new_targets: Array[Target]):
	if !next:
		append_to_targets(new_targets)
		return
	
	var index = targets.find(next)
	var before : Target
	if index > 0:
		before = targets[index-1]
		
	var current_next: Target = next

	for i in range(new_targets.size()-1,-1,-1):
		var target = new_targets[i]
		if target.source:
			if target.source == entity:
				continue
			target.source.end_of_life.connect(on_target_source_eol.bind(target))
		assert(target.type != Type.PATROL,"Do we really need this case ? if so need to handle this properly below..")
		targets.insert(index,target)
		#link
		target.next = current_next
		current_next.previous = target
		current_next = target

	if current_next == next:
		return

	#link before
	if before:
		before.next = current_next
		current_next.previous = before

	after_targets_added.emit(self,new_targets)
	set_next_target(current_next)

func append_to_targets(new_targets: Array[Target]):
	for t in new_targets:
		if t.source:
			#ignore moving to self
			if t.source == entity:
				continue
			t.source.end_of_life.connect(on_target_source_eol.bind(t))
		targets.append(t)
		#link
		if targets.size() > 1:
			var previous : Target = targets[targets.size()-2]
			t.previous = previous
			previous.next = t

	#if t was skipped, targets can still be empty
	if targets.is_empty():
		return
		
	if !next:
		if targets[0].type == Type.PATROL:
			assert(targets[1].type == Type.PATROL,"Maybe improve this to not depend on this weird double patrol add")
			set_next_target(targets[1]) #depends on two patrol points being added...
		else:
			set_next_target(targets[0])
	
	after_targets_added.emit(self,new_targets)


#removes and disconnected eol signal, but DOES NOT LINK UP remaning targets
func remove_from_targets(target: Target):
	if targets.has(target):
		targets.erase(target)
		if target.source:
			target.source.end_of_life.disconnect(on_target_source_eol)
			
		#link up
		if target.previous:
			target.previous.next = target.next
		if target.next:
			target.next.previous = target.previous
			
func _clear_targets():
	if targets.is_empty():
		return

	before_all_targets_cleared.emit(self)
	for target in targets:
		if target.source:
			target.source.end_of_life.disconnect(on_target_source_eol)
	targets.clear()
	set_next_target(null)
	all_targets_cleared.emit(self)

# adds a func "fun" with arguments "args" to be invoked when target with "index" is reached
func add_callable_to_target(index: int, callable: Callable, id: String, args):
	var target =  targets[index]
	if target.callbacks.has(id):
		printerr("Trying to add callback with same id " + id + "to movable at index" + str(index))
	else:
		target.callbacks[id] = {
			"fun": callable,
			"args": args
		}

func add_callable_to_last_target(callable: Callable, id: String, args: Array):
	if targets.is_empty():
		printerr("Trying to add callable to empty target array")
	else:
		add_callable_to_target(targets.size()-1,callable,id,args)

func determine_state(next_target: Target) -> State:
	if next_target:
		if next_target.type > Type.PATROL:
			return State.WALK
		if next_target.type == Type.PATROL:
			return State.PATROL
	return State.IDLE

func stop():
	_clear_targets()
	sm.change_state(State.IDLE)

func hold():
	_clear_targets()
	sm.change_state(State.HOLD)

func is_at_or_near_final_target():
	if !next:
		return true
	if targets.size() > 1:
		return false
	if sm.current_state == State.REACHED_SOURCE_TARGET:
		return true
	#take into account that colliders could block when colliding with other units
	if entity.global_position.distance_squared_to(next.pos) < stop_distance_squared + entity.collision_radius:
		return true
	return false

func apply_accumulated_force(delta: float) -> bool:
	if accumulated_force == Vector3.ZERO:
		return false

	entity.velocity += accumulated_force * delta  * 60

	clamp_velocity_to_navmesh(delta)
	if entity.velocity.y > VEL_Y_CAP && entity.global_position.y > -1:
		printerr("High y-vel in push: " + str(entity.velocity))
		entity.velocity.y = 0

	#The below does produce a nice ripple wave of force pushing BUT
	#it is unstable, especially in large crowds and towards the nav mesh boundaries.
	#therefore we don't relay force pushing and let the force collider handle the rest
	#------
	# var m_neighbors = steering_neighbors.values()
	# for movable in m_neighbors:
	# 	if movable != null:
	# 		ovable.force_push(accumulated_force)
	#------

	entity.move_and_slide()
	accumulated_force = Vector3.ZERO
	#update idle_position when force pushed
	idle_position = entity.global_position

	return true

func apply_push(push: Vector3,delta: float) -> bool:

	entity.velocity = (push.normalized() * (speed)) #slightly faster than normal speed
	clamp_velocity_to_navmesh(delta)

	if entity.velocity.y > VEL_Y_CAP:
		printerr("High y-vel in push: " + str(entity.velocity))
		entity.velocity.y = 0
	if entity.move_and_slide():
		solve_collision()
		
	apply_instant_rotation(entity.global_position + push)
	return true

func apply_instant_rotation(look_at_target: Vector3):
	#fast (yaw only using local axis), using look_at is more expensive
	var from = pivot.global_position
	var to = look_at_target
	to.y = from.y #flatten

	var dir = from - to # why inversed ?
	if dir.length_squared() < 0.001:
		return # Avoid noise by dividing by small amounts
	
	var angle = atan2(dir.x,dir.z)

	if abs(pivot.rotation.y - angle) > 0.001:
		pivot.rotation.y = angle

func get_closest_point_on_nav_mesh(target: Vector3) -> Vector3:
	var rid = nav_agent.get_navigation_map() # remark, might have to be upifdated when working with multiple region2ds in the future
	if !rid.is_valid():
		printerr("Invalid rid!")
	return NavigationServer3D.map_get_closest_point(rid,target)

var combined_steering_force : Vector3

func move(delta: float):
	assert(next,"Target missing")
	if !next:
		push_error("Missing next target")
		return
	assert(!targets.is_empty(),'Targets shouldnt be empty')
	
	if prev_target != next.pos:
		#to check, but I believe we need this once because of y value mis match?
		next.pos = get_closest_point_on_nav_mesh(next.pos) 
		prev_target = next.pos

	#Docs: https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html#class-navigationagent3d-property-target-position
	#If set, a new navigation path from the current agent position to the target_position is requested from the NavigationServer.
	#Hence, it needs to be set each frame, even if target has not changed, since nav_agent could have moved/pushed
	nav_agent.target_position = next.pos 
	var next_nav_target = nav_agent.get_next_path_position()

	if !nav_agent.is_target_reachable():
		if next.source:
			#todo in a while loop iterate closer until we get a reacable target
			#use this for rocks etc which do use nav avoidance, so that we get
			# a more accurate goal
			pass

		#this can happen when nav areas are physically not connect
		#in this case, walk until next_nav_target is reached
		if entity.global_position.distance_squared_to(next_nav_target) < stop_distance_squared:
			on_next_target_reached()
			return
	elif entity.global_position.distance_squared_to(next.pos) < stop_distance_squared:
		on_next_target_reached()
		return

	#Separate neighbors into movable ones and immovables ones (can contain
	#movables that are "externally externally_immovable")
	var immovable_neighbors : Array[Node3D] = []
	var movable_neighbors: Array[RTS_Movable] = []
	for key in steering_neighbors:
		var m_neighbor : RTS_Movable = steering_neighbors[key]
		if m_neighbor:
			if m_neighbor.externally_immovable:
				immovable_neighbors.append(key)
			else:
				movable_neighbors.append(m_neighbor)
		else:
			immovable_neighbors.append(key)

	#The components contributing to move_to_next:
	var steering_force = Vector3.ZERO
	var avoidance_and_separation = Vector3.ZERO

	steering_force += seek(next_nav_target)

	#avoidance (of semi-static movables, could be units on HOLD or static objects)
	if use_avoidance:
		avoidance_and_separation += avoid(immovable_neighbors,next_nav_target)

	#separation (dynamic objects)
	if use_separation:
		avoidance_and_separation += dynamic_separation(movable_neighbors,next_nav_target)

	steering_force += avoidance_and_separation

	entity.velocity = (entity.velocity + steering_force).limit_length(speed)

	## push others
	if sm.current_state != State.RETURN_TO_IDLE:
		for m in movable_neighbors:
			var other_state = m.sm.current_state
			if other_state < 1 || other_state == State.PUSHED:
				#if !try_relinquish_target(m.entity):
				m.get_pushed_by(self)

	#To avoid jitter, especially when sliding happens, simply apply next_nav_target
	#Exception: If we have positive avoidance/separation, rotate in force instead
	if avoidance_and_separation != Vector3.ZERO:
		apply_instant_rotation(entity.global_position + avoidance_and_separation)
	else:
		apply_instant_rotation(next_nav_target)
		
	clamp_velocity_to_navmesh(delta)

	if entity.velocity.y > VEL_Y_CAP:
		printerr("High y-vel in move_to_next: " + str(entity.velocity))
		entity.velocity.y = 0

	if entity.move_and_slide():
		solve_collision()

#todo this needs to be optimized, kinda heavy function only really user avoidance?
# return boolean indicating whether clamping has occured
func clamp_velocity_to_navmesh(delta: float) -> bool:
	var predicted_position = entity.global_position + entity.velocity * delta
	var clamped = get_closest_point_on_nav_mesh(predicted_position)
	if clamped == Vector3.ZERO:
		printerr("Clamp failed. Investigate why map_get_closest_point is failing. Returning...")
		return false
	if predicted_position.distance_squared_to(clamped) > 0.25*0.25:
		var new_direction_flat = (clamped - entity.global_position)
		var velocity = new_direction_flat/delta
		velocity.y = entity.velocity.y
		entity.velocity = velocity
		return true
	return false

func seek(target: Vector3) -> Vector3:
	var seek_direction = (target - entity.global_position).normalized()
	var desired = seek_direction * speed
	desired -= entity.velocity
	return desired

func solve_collision():
	var collision = entity.get_last_slide_collision()
	var collision_count = collision.get_collision_count()
	for i in range(collision_count):
		var other = collision.get_collider(i)
		if other is RTS_Entity && other.movable:
			#only need to try relinquishing if we're actually moving
			if (sm.current_state == State.IDLE 
				|| sm.current_state == State.REACHED_SOURCE_TARGET 
				|| sm.current_state == State.PUSHED
				|| !try_relinquish_target(other)
			):
				other.movable.get_pushed_by(self)

func dynamic_separation(movables: Array[RTS_Movable], next_nav_target: Vector3) -> Vector3:
	var total_mind_read = Vector3.ZERO
	var influences = 0
	var pos = entity.global_position
	var debug : bool =  entity.entity_debug_instance != null
	for other in movables:
		if other.sm.current_state == State.PATROL || other.sm.current_state == State.WALK:
			#dont do separation if movables are sharing the same current target to avoid fighting
			if other.next && next.pos == other.next.pos:
				continue
			if next.source && other.next && next.source == other.next.source:
				continue

			#todo mind read and evade (only if dot less than 0)
			#todo improve this first draft of mindread. actuall y not bad but way to clean and unnaterual
			var dot = entity.velocity.dot(other.entity.velocity)
			if dot < 0.3: #todo make this better ?
				var diff = (other.entity.global_position - pos)
				diff.y = 0
				var p = Vector2(diff.x,diff.z).normalized()
				# var factor = ( 1 - p.length()/steering_radius)
				var o1 = Vector2(-p.y,p.x) #* factor #perpedicular to p
				var o2 = -o1
				var vel = Vector2(entity.velocity.x,entity.velocity.z)
				var avoidance_direction : Vector2
				if vel.dot(o1) > vel.dot(o2):
					avoidance_direction = o1
				else:
					avoidance_direction = o2

				#to avoid hugging, if within 90 degress to goal vector on the side of the obstruction dont apply force
				var goal_vector = Vector2(next_nav_target.x-pos.x,next_nav_target.z-pos.z)
				if avoidance_direction.dot(goal_vector) > 0:
					#only if both obstruction and avoidance are on same side of goal vector:
					var cross1 = p.cross(goal_vector)
					var cross2 = avoidance_direction.cross(goal_vector)
					if (cross1 >= 0 && cross2 >= 0 ) || (cross1 < 0 && cross2 < 0):
						avoidance_direction = Vector2.ZERO
						continue
				total_mind_read += Vector3(avoidance_direction.x,0,avoidance_direction.y)
				influences += 1
	if influences > 0:
		total_mind_read /= influences

	if debug:
		##DebugDraw3D.draw_line(pos,pos + total_mind_read,Color.RED)
		pass
	return total_mind_read * separation_multiplier

func force_push(push: Vector3, _origin: Vector3 = Vector3.ZERO, _limit: float = -1):
	if has_been_force_pushed_this_tick:
		return
	accumulated_force += push
	has_been_force_pushed_this_tick = true

func get_pushed_instantly_by(other: RTS_Movable, push_strength: float = 1):
	var pos = entity.global_position
	var o1 =  Vector3(-other.entity.velocity.z,0,other.entity.velocity.x).normalized()
	var o2 =  -o1
	var p : Vector3 = other.entity.global_position - pos
	p.y = 0
	var push_direction = o1 if p.dot(o1) < p.dot(o2) else o2
	push_direction = (push_direction - p).normalized() #optional, applies extra direction
	if entity.entity_debug_instance:
		##DebugDraw3D.draw_cylinder_ab(pos,pos + 0.01 * Vector3.UP,0.25,Color.PINK)
		##DebugDraw3D.draw_line(pos,pos + push_direction,Color.PINK)
		pass
	entity.velocity = push_direction * push_strength
	if entity.move_and_slide():
		var collision = entity.get_last_slide_collision()
		var collision_count = collision.get_collision_count()
		for i in range(collision_count):
			var next_collision = collision.get_collider(i)
			if next_collision is RTS_Entity && next_collision.movable != null:
				next_collision.movable.get_pushed_instantly_by(self,push_strength)
	
func get_pushed_by(other:RTS_Movable):
	if (
		!allow_being_pushed 
		|| externally_immovable 
		|| sm.current_state == State.WALK
		|| sm.current_state == State.PATROL
		|| sm.current_state == State.RETURN_TO_IDLE
	):
		return

	#Dont allow being pushed from followers
	if other.next && other.next.source == entity:
		return
	if other.last && other.last.source == entity:
		return

	var pos = entity.global_position
	var o1 =  Vector3(-other.entity.velocity.z,0,other.entity.velocity.x).normalized()
	var o2 =  -o1
	var p : Vector3 = other.entity.global_position - pos
	p.y = 0
	var push_direction = o1 if p.dot(o1) < p.dot(o2) else o2
	push_direction = (push_direction - p).normalized() #optional, applies extra direction
	if entity.entity_debug_instance:
		pass
		##DebugDraw3D.draw_cylinder_ab(pos,pos + 0.01 * Vector3.UP,0.25,Color.YELLOW)
		##DebugDraw3D.draw_line(pos,pos + push_direction,Color.YELLOW,)
	accumulated_push += push_direction
	return_to_idle_time = 0

#function used to avoid externally_immovable dynamic objects, i.e. concave depressions of units 
func avoid(immovables: Array[Node3D], next_nav_target: Vector3) -> Vector3:
	if immovables.is_empty():
		return Vector3.ZERO

	#Ignore irrelevant units
	var influences : int = 0
	var avoidance_direction = Vector2.ZERO
	var total_avoidance = Vector3.ZERO
	var existing_avoidance_direction = 0
	var prev_p = Vector2.ZERO
	var pos = entity.global_position
	var goal_vector = Vector2(next_nav_target.x-pos.x,next_nav_target.z-pos.z)
	var start = Vector2(pos.x,pos.z)
	var end = Vector2(next_nav_target.x,next_nav_target.z)
	var vel = Vector2(entity.velocity.x,entity.velocity.z)
	var to_end = Vector2(end.x-start.x,end.y-start.y)

	#debug
	var debug: bool = entity.entity_debug_instance != null

	for immovable in immovables:
		#Calculate perpendicular vector to p
		var diff = (immovable.global_position - pos)
		diff.y = 0
		var p = Vector2(diff.x,diff.z)
		var o1 = Vector2(-p.y,p.x).normalized() #perpedicular to p
		var o2 = -o1
		var prefer_o1 : bool

		if existing_avoidance_direction == 0:
			#normal case: use velocity as direction
			#special case: if new target has been set, use instead
			var current_direction = to_end if next_target_has_just_been_set else vel
			prefer_o1 = current_direction.dot(o1) > current_direction.dot(o2)
			existing_avoidance_direction = 1 if prefer_o1 else -1
		else:
			# to avoid flickering/stuck, stick the most aligned direction
			prefer_o1 = p.dot(prev_p) > 0  if existing_avoidance_direction > 0 else p.dot(prev_p) <= 0
		avoidance_direction = o1 if prefer_o1 else o2

		prev_p = p
		#to avoid hugging, if within 90 degress to goal vector on the side of the obstruction dont apply force
		if avoidance_direction.dot(goal_vector) > 0:
			#only if both obstruction and avoidance are on same side of goal vector:
			var cross1 = p.cross(goal_vector)
			var cross2 = avoidance_direction.cross(goal_vector)
			if (cross1 >= 0 && cross2 >= 0 ) || (cross1 < 0 && cross2 < 0):
				avoidance_direction = Vector2.ZERO
				if debug:
					pass
					##DebugDraw3D.draw_line(pos,pos + Vector3(goal_vector.x,0,goal_vector.y),Color.GREEN)
				continue
		total_avoidance += Vector3(avoidance_direction.x,0,avoidance_direction.y)
		influences += 1
	
	if influences > 0:
		total_avoidance /= influences
	total_avoidance *= avoidance_multiplier
	if debug:
		pass
		##DebugDraw3D.draw_line(entity.global_position,entity.global_position + total_avoidance,Color.RED)
	return total_avoidance

#Called when collided with other RTS_Entity
#Tries to relinquish movement target if possible, returns true if successful
#This essentially allows units to bump into other units with the same target
#and stop moving if both are at/near the target
func try_relinquish_target(other: RTS_Entity) -> bool:
	if !next:
		return true
	if next.type == Type.ATTACK || next.type == Type.MOVEATTACK:
		return false
		
	if next.type == Type.PATROL:
		#for patrol relinquish if other is same as source
		if next.source != null && next.source == other:
			on_next_target_reached()
			return true
		return false
	
	if other.movable:
		var other_current_or_last_target : Target = other.movable.next
		if !other_current_or_last_target:
			other_current_or_last_target = other.movable.last
		if !other_current_or_last_target:
			return false
		if next.source:
			if (other.movable.is_at_or_near_final_target()
				&& next.source == other_current_or_last_target.source):
					#sm.change_state(State.REACHED_SOURCE_TARGET) #Only use if we want to follow source movement
					on_next_target_reached()
					return true
		else:
			if (other.movable.is_at_or_near_final_target()
				&& other_current_or_last_target.pos.distance_squared_to(next.pos) < stop_distance_squared):
					on_next_target_reached()
					return true
	return false

func on_next_target_reached(use_current_position_as_last: bool = false):
	#Inserting target just before next works nicely, but movementpaths gets confused, because we're
	#telling it about it here, but didn't properly insert it. maybe add a boolean to target idk.
	next_target_just_reached.emit(self,next)
	
	if use_current_position_as_last:
		next.pos = entity.global_position
	var callbacks : Array = next.callbacks.values()

	if next.type == Type.PATROL:
		if backwards:
			if next.previous:
				#patrol further back
				set_next_target(next.previous)
				assert(next)
			else:
				#reached first patrol point
				set_next_target(next.next)
				backwards = false
		else:
			if next.next:
				set_next_target(next.next)
				if next.type != Type.PATROL:
					#pop all patrol targets and move to next
					assert(next)
					var walk_back: Target = next.previous
					while walk_back:
						assert(walk_back.type == Type.PATROL,"Found non patrol target")
						var previous: Target = walk_back.previous
						remove_from_targets(walk_back)
						walk_back = previous
					assert(!targets.is_empty())
			else:
				#patrol back
				set_next_target(next.previous)
				backwards = true
				assert(next)
	else:
		remove_from_targets(next)
		set_next_target(next.next)
		if next:
			#in next target is PATROL, we need to insert patrol point at current position
			if next.type == Type.PATROL && targets.size() == 1:
				var target: Target = Target.new(last.pos,Type.PATROL,last.source,RTS_Movement.generate_session_uid(),last.offset)
				targets.insert(0,target) #Ideally use insert function...
				#link 
				target.next = next
				next.previous = target
				#emit
				var new_targets : Array[Target]
				new_targets.append(target)
				after_targets_added.emit(self,new_targets)
		else:
			assert(targets.is_empty())
	
	if next:
		sm.change_state(determine_state(next))
	else:
		sm.change_state(State.IDLE)
		final_target_reached.emit(self)

	#callbacks
	if callbacks != null:
		for c in callbacks:
			c.fun.callv(c.args)

#We remove the target completetly when its source dies/existing tree
func on_target_source_eol(_entity: RTS_Entity,_target: Target):
	if _target == next:
		on_next_target_reached()
		if sm.current_state == State.PATROL:
			if targets.size() <= 2:
				stop()
			else:
				remove_from_targets(_target)
				#link up
				if _target.previous:
					_target.previous.next = _target.next
				if _target.next:
					_target.next.previous = _target.previous
			
	else:
		if sm.current_state == State.PATROL && targets.size() <= 2:
			stop()
		else:
			remove_from_targets(_target)
			#link up
			if _target.previous:
				_target.previous.next = _target.next
			if _target.next:
				_target.next.previous = _target.previous
		

func on_steering_body_entered(body: Node3D):
	if body == entity:
		return
	if !steering_neighbors.has(body):
		if body is RTS_Entity:
			var movable_neighbor : RTS_Movable = body.movable
			steering_neighbors[body] = movable_neighbor #body can be entity, or force (staticbody3d/ForceBody3D) or building/rocks
			body.before_tree_exit.connect(on_before_tree_exit)
		else:
			steering_neighbors[body] = null

func on_steering_body_exited(body: Node3D):
	if body == entity:
		return
	if steering_neighbors.has(body):
		steering_neighbors.erase(body)
		if body is RTS_Entity:
			body.before_tree_exit.disconnect(on_before_tree_exit)

func on_before_tree_exit(_entity: RTS_Entity):
	on_steering_body_exited(_entity)
