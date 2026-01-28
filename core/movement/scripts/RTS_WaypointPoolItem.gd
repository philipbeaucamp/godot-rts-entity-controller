class_name RTS_WaypointPoolItem extends RTS_ObjectPoolItem

@export var sprite: Sprite3D
@export var column: MeshInstance3D

var color: Color
var time: float
var material: Material
var source: Node3D

func set_color(_color: Color):
	color = _color
func set_source(node: Node3D):
	source = node

func set_active(value: bool):
	super.set_active(value)
	time = 0 #use manual time, so shader time can start at 0
	material = column.material_override
	#set color
	sprite.modulate = color
	if material != null:
		material.set_shader_parameter("color",color)
	
func _process(delta):
	if !is_active:
		return
	if source != null && global_position != source.global_position:
		global_position = source.global_position
	time += delta
	material.set_shader_parameter("time",time)
