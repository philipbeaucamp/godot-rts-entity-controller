extends BoxContainer

class_name CAbilityContainer

var cam: Camera3D
var active_world_node: Node3D

func _ready():
	cam = Controls.camera

func set_world_node(node: Node3D):
	active_world_node = node

func _process(_delta):
	if get_child_count() == 0:
		return
	var pos = active_world_node.global_position
	if cam.is_position_in_frustum(pos):
		var pos_2d : Vector2 = cam.unproject_position(pos)
		global_position = pos_2d - get_combined_minimum_size() * 0.5
