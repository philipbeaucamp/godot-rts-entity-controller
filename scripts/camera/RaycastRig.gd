extends Node3D

class_name RaycastRig

@export var move_speed := 10.0
@export var edge_threshold := 10 #could improve this by using a % of current window size
@export var lock_mouse := true

var screen_size = Vector2i.ZERO
var boundaries : Array[Area3D] = []
@export var camera : RaycastCamera
@export var tilt_shift: MeshInstance3D

var tilt_shift_material: ShaderMaterial
var tween: Tween

func _enter_tree():
	RTSEventBus.set_camera_boundary.connect(on_set_camera_boundary)
	RTSEventBus.set_camera_start_position.connect(on_camera_start_position)

func _ready():
	var viewport = camera.get_viewport()
	screen_size = viewport.get_visible_rect().size
	set_mouse_confined(lock_mouse)
	if tilt_shift:
		tilt_shift_material = tilt_shift.mesh.surface_get_material(0)

func set_mouse_confined(value: bool):
	lock_mouse = value
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func teleport_to(target: Vector3):
	position = target

func on_set_camera_boundary(area: Area3D, value: bool):
	if value:
		if !boundaries.has(area):
			boundaries.append(area)
	else:
		if boundaries.has(area):
			boundaries.erase(area)

func on_camera_start_position(start: Vector3):
	global_position = start

func tween_to(target: Node3D, duration: float) -> Tween:
	if tween:
		tween.stop()
	tween = create_tween()	
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ignore_time_scale(true)
	tween.parallel().tween_property(self,"global_position",target.global_position,duration)
	return tween

func _process(delta):
	
	if tilt_shift:
		tilt_shift_material.set_shader_parameter("focal_point",global_position)
		
	if !lock_mouse || !Controls.is_enabled:
		return
	if !DisplayServer.window_is_focused():
		return
	#Movement should happen at same scale, regardless of ingame time	
	if Engine.time_scale != 0:
		delta /= Engine.time_scale
	else :
		delta = Controls.time_utility.unscaled_delta
	
	var viewport = camera.get_viewport()
	var mouse_pos = viewport.get_mouse_position()
	screen_size = viewport.get_visible_rect().size

	var direction = Vector3.ZERO
	if mouse_pos.x < edge_threshold:
		direction.x -= 1 #Move left
		direction.z += 1
	elif mouse_pos.x > screen_size.x - edge_threshold:
		direction.x += 1 #Move right
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = direction.normalized() * move_speed * delta
		var new_position = position + direction
		if is_inside_boundaries(new_position):
			position = new_position
			
	#apply direction separately for x and y edge threshold
	direction = Vector3.ZERO
	if mouse_pos.y < edge_threshold:
			direction.z -= 1  # Move up (forward)
			direction.x -= 1
	elif mouse_pos.y > screen_size.y - edge_threshold:
			direction.z += 1  # Move down (backward)
			direction.x += 1

	if direction != Vector3.ZERO:
		direction = direction.normalized() * move_speed * delta
		var new_position = position + direction
		if is_inside_boundaries(new_position):
			position = new_position
	
func is_inside_boundaries(point: Vector3):
	if boundaries.is_empty():
		return true
	for boundary in boundaries:
		var collision_shape = boundary.get_node("CollisionShape3D") #todo improve perfomance
		var shape = collision_shape.shape as BoxShape3D
		var point_in_local = collision_shape.to_local(point)
		var min_x = -shape.size.x/2
		var max_x = shape.size.x/2
		var min_z = -shape.size.z/2
		var max_z = shape.size.z/2
		# Check if the point's X and Z are within the bounds of the AABB
		if min_x <= point_in_local.x && point_in_local.x <= max_x && min_z <= point_in_local.z && point_in_local.z <= max_z:
				return true
	return false
