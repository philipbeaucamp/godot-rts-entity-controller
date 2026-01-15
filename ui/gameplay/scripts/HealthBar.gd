extends Node2D

class_name HealthBar

var _health : Health
var _raycast_camera : Camera3D
# var _render_cam : Camera3D
var _mesh: MeshInstance2D

func set_up(health: Health):
	# print("Being setup!")
	_health = health
	_raycast_camera = Controls.camera
	# _render_cam = Controls.render_camera
	_health.death.connect(on_death)
	_health.health_changed.connect(on_health_changed)
	_mesh = get_node("MeshInstance2D")
	_mesh.material.set_shader_parameter("health",_health.health/_health.init_health)

func _process(_delta):
	var pos = _health.global_position
	if _raycast_camera.is_position_in_frustum(pos):
		visible = true
		#todo this is super unperfomant. make part of 3d space .. ?
		var pos_2d = _raycast_camera.unproject_position(pos)
		self.position = pos_2d
	else:
		visible = false

func on_health_changed(_h: Health):
	_mesh.material.set_shader_parameter("health",_health.health/_health.init_health)

func on_death(_entity: Entity):
	queue_free()
