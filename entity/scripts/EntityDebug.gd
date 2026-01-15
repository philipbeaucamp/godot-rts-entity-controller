extends Control
class_name EntityDebug

@export var entityLabel: Label
@export var faction: Label
@export var mState: Label
@export var mType: Label
@export var nextTarget: Label
# @export var grid: Label
@export var seek: Label
@export var separation: Label
@export var cohesion: Label
@export var alignment: Label
@export var phyVelocity: Label
@export var aState: Label
@export var aCooldown: Label
@export var currentTarget: Label
@export var assignedTarget: Label
@export var scan: Label
@export var weapon: Label
@export var attack_masks: Label
@export var health: Label
@export var armor: Label
@export var weapon_dmg: Label
@export var anim_state: Label

@export var box_rect_color : Color
@export var scan_range_color : Color
@export var weapon_range_color : Color
@export var steering_range_color : Color

var _entity: Entity
var _camera: Camera3D
# var _grid: SpatialGrid
var mLabels : Array[Label] = []
var aLabels : Array[Label] = []
var hLabels : Array[Label] = []

func _ready():
	mLabels = [mState,nextTarget,seek,separation,cohesion,alignment,phyVelocity]
	aLabels = [aState,currentTarget,assignedTarget,scan,weapon]
	hLabels = [health]
	##DebugDraw3D.scoped_config().set_no_depth_test(true).set_thickness(0.01)
	_camera = Controls.camera

func set_up_entity_debug(entity: Entity):
	_entity = entity

func _process(delta):
		process_debug_input(delta)

func process_debug_input(delta:float):
	if Input.is_action_pressed("numpad_4"):
		_entity.movable.apply_smooth_rotation(-_entity.global_transform.basis.x,delta/3)
	if Input.is_action_pressed("numpad_6"):
		_entity.movable.apply_smooth_rotation(_entity.global_transform.basis.x,delta/3)

func _physics_process(_delta):
	self.global_position = _camera.unproject_position(_entity.global_position)
	
	#general
	entityLabel.text = _entity.resource.display_name + "(" + str(_entity.get_instance_id()) + ")"
	faction.text = "(" + Entity.Faction.keys()[_entity.faction] + ")"

	#Draw collision raidus
	##DebugDraw3D.draw_cylinder_ab(_entity.global_position,_entity.global_position+ Vector3.UP*0.01,_entity.collision_radius,Color.BLUE)

	var m :Movable = _entity.movable
	var a :AttackBehaviour = _entity.attack
	var h :Health= _entity.health
	var d :Defense= _entity.defense
	var pos : Vector3 = _entity.global_position

	#movable
	if m != null:
		mState.text = "State: " + Movable.State.keys()[m.sm.current_state]
		var next: Target = m.next
		if next:
			mType.text = "Type: " + Movable.Type.keys()[next.type]
			var source_id = str(next.source.get_instance_id()) if next.source else "-"
			nextTarget.text = "Next: " + source_id  + "@" + str(next.pos) + " (" + str(m.targets.size()) + ")"
		else:
			mType.text = "Type: - "
			nextTarget.text = "Next: - "
		# var neighbors = _grid.get_entities_in_my_range(movable,movable.steering_radius) as Array
		# grid.text = "Grid " + str(_grid.to_grid_index(movable.global_position)) + "Neighbors: " + str(neighbors.size())
		# seek.text = "Seek: " + str(movable.seek_direction)
		# separation.text = "Separation: "
		# cohesion.text = "Cohesion: "
		# alignment.text = "Alignment: "
		phyVelocity.text = "PhyVelocity:  " + " (" + str(snapped(_entity.velocity.length(),0.01)) + ") " + str(_entity.velocity) 

		##DebugDraw3D.draw_arrow(pos,pos + _entity.velocity.normalized(),Color.BEIGE,0.1)

		#Roration
		# ##DebugDraw3D.draw_arrowhead(_entity.transform,Color.BLACK)
		#SeekDirection
		# ##DebugDraw3D.draw_arrow(movable.global_position,movable.global_position + movable.seek_direction,Color.GREEN,0.1)
		#Separation
		# ##DebugDraw3D.draw_arrow(movable.global_position,movable.global_position + movable.separation_force,Color.RED,0.1)
		# #SteeringForce
		# ##DebugDraw3D.draw_arrow(movable.global_position,movable.global_position + movable.combined_steering_force,Color.PURPLE,0.1)

		#Draw Steering Radius
		if !m.steering_neighbors.is_empty():
		# if !neighbors.is_empty():
			var collision_shape = m.steering.get_node("CollisionShape3D") as CollisionShape3D
			var radius = (collision_shape.shape as SphereShape3D).radius
			##DebugDraw3D.draw_cylinder_ab(_entity.global_position,_entity.global_position+ Vector3.UP*0.01,radius,steering_range_color)

		# draw_paths(m)
	else:
		for l in mLabels:
			l.visible = false

	#Attackable
	if a != null:
		aState.text = "State: " + AttackBehaviour.State.keys()[a.state_machine.current_state]
		aCooldown.text = "Cooldown: " + str(a.remaining_cooldown_time)
		currentTarget.text = "Current Target: " + (str(a.current_target.owner.name) if a.current_target != null else "NULL") + "(In WRange: " + str(a.defenses_in_weapon.has(a.current_target)) + ")"
		assignedTarget.text = "Assigned Target: " + (str(a.player_assigned_target.owner.name) if a.player_assigned_target != null else "NULL") + "(In WRange: " + str(a.defenses_in_weapon.has(a.player_assigned_target)) + ")"
		scan.text = "In Scan: " + str(a.defenses_in_scan.size())
		weapon.text = "In Weapon: " + str(a.defenses_in_weapon.size())
		weapon.text += "Aggresor: " + str(a.aggressor.entity.resource.id if (a.aggressor != null) else &"-")
		attack_masks.text = "Masks: " + str(a.active_weapon.scan_area.collision_mask)

		if a.current_target != null:
			pass
			##DebugDraw3D.draw_arrow(_entity.global_position,a.current_target.entity.global_position,Color.DARK_RED,0.1)
		elif a.player_assigned_target != null:
			pass
			##DebugDraw3D.draw_arrow(_entity.global_position,a.player_assigned_target.entity.global_position,Color.PURPLE,0.1)

		#Debug Radi
		var collision_shape_scan = a.active_weapon.scan_area.get_node("CollisionShape3D") as CollisionShape3D			
		var collision_shape_weapon = a.active_weapon.weapon_area.get_node("CollisionShape3D") as CollisionShape3D			
		var sphere_scan = collision_shape_scan.shape as SphereShape3D
		var sphere_weapon = collision_shape_weapon.shape as SphereShape3D
		##DebugDraw3D.draw_cylinder_ab(_entity.global_position,_entity.global_position+ Vector3.UP*0.01,sphere_scan.radius,scan_range_color)
		##DebugDraw3D.draw_cylinder_ab(_entity.global_position,_entity.global_position+ Vector3.UP*0.01,sphere_weapon.radius,weapon_range_color)
	else:
		for l in aLabels:
			l.visible = false

	#Anim
	if _entity.anim_tree != null && _entity.anim_tree.playback:
		anim_state.text = "Anim State: " + _entity.anim_tree.playback.get_current_node()

	#Health&Defense
	#Stats
	if h != null:
		health.text = "Health: " + str(h.health) + "/" + str(h.init_health)
	if d != null:
		armor.text = "Armor: " + str(d.armor)
	if a != null:
		var weapons : Array[Weapon]= a.weapons
		var dmg_text = ""
		for w in weapons:
			var dmgs : Array[DamageDealer]= w.damage_dealers
			dmg_text += "W1("
			for dmg in dmgs:
				dmg_text += str(dmg.damage) + ","
			dmg_text += ")"
		weapon_dmg.text = dmg_text
	#for 2D debugging	
	queue_redraw()

func get_circle_points(center: Node3D, radius: float, num_points: int = 12) -> PackedVector3Array:
	var points = [] 
	for i in range(num_points):
		var angle = i * 2 * PI / num_points  # Calculate the angle for this point
		var world = center.to_global(Vector3(radius * cos(angle),0,radius*sin(angle)))
		points.append(world)  # Store the point

		# var x = center.global_position.x + radius * cos(angle)  # Calculate the x position
		# var z = center.global_position.z + radius * sin(angle)  # Calculate the y position
		# points.append(center.global_position + Vector3(x,0,z))  # Store the point
	return PackedVector3Array(points)

func _draw():
	var selectable = _entity.selectable
	if selectable.boxable != null:
		var screen_box = selectable.boxable.get_screen_box()
		draw_rect(Rect2(screen_box.position - global_position, screen_box.size), box_rect_color,true)

# func draw_paths(movable: Movable):
# 	var points = Dictionary()
# 	var points_array = []
# 	var points_type_array = []

# 	for target in movable.targets:
# 		#draw line between movables and first target
# 		if !target.previous && :
# 			if target_type != Movable.Type.PATROL:
# 				##DebugDraw3D.draw_line(movable.entity.global_position,target,get_type_color(target_type))
# 		if !points.has(target):
# 			points[target] = movable
# 			points_array.append(target)
# 			points_type_array.append(target_type)

# 	#draw line between target points
# 	for i in range(points_array.size()):
# 		var color = get_type_color(points_type_array[i])
# 		# ##DebugDraw3D.draw_sphere(points_array[i], 0.3, color)
# 		if i < points_array.size() - 1:
# 			color = get_type_color(points_type_array[i+1])
# 			##DebugDraw3D.draw_line(points_array[i],points_array[i+1],color)

static func get_type_color(type: Movable.Type):
	if type == Movable.Type.MOVE:
		return Color.GREEN
	elif type == Movable.Type.PATROL:
		return Color.BLUE
	elif type == Movable.Type.ATTACK:
		return Color.RED
	elif type == Movable.Type.MOVEATTACK:
		return Color.RED
	# elif type == Movable.Type.AUTO_ATTACK:
	# 	return Color.GRAY
	elif type == Movable.Type.NULL:
		return Color.BLACK
