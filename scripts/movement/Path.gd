extends ObjectPoolItem

class_name Path

var start: Vector3
var end: Vector3
var color: Color
var alpha_factor: float
var start_source: Node3D
var end_source: Node3D

@onready var mesh_instance : MeshInstance3D = $MeshInstance3D

func set_active(value: bool):
	super.set_active(value)

func set_up(_start: Vector3, _end: Vector3, _color: Color, _start_source, _end_source,_alpha_factor:float):
	self.start = _start
	self.end = _end
	self.color = _color
	self.start_source = _start_source
	self.end_source = _end_source
	self.alpha_factor = _alpha_factor
	update_instance()

func _process(_delta):
	if !is_active:
		return
	if start_source != null:
		start = start_source.global_position
	if end_source != null:
		end = end_source.global_position
	if start_source != null || end_source != null:
		# update shader parameters
		update_instance()

func update_instance():
	global_position = (start+end)/2.0
	var direction = (end-start).normalized()
	self.basis = Basis.looking_at(direction,Vector3.UP)
	var length = start.distance_to(end)
	mesh_instance.mesh.size = Vector2(mesh_instance.mesh.size.x,length)
	var material = mesh_instance.mesh.surface_get_material(0)
	if material != null:
		material.set_shader_parameter("scale",Vector2(1,length*5))
		material.set_shader_parameter("color",color)
		material.set_shader_parameter("alpha_factor",alpha_factor)
