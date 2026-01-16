class_name RTS_HealthBar extends Node2D

var _health : RTS_HealthComponent
var _raycast_camera : Camera3D
var _mesh: MeshInstance2D

func set_up(health: RTS_HealthComponent):
	_health = health
	_raycast_camera = Controls.camera
	_health.death.connect(on_death)
	_health.health_changed.connect(on_health_changed)
	_mesh = get_node("MeshInstance2D")
	_mesh.material.set_shader_parameter("health",_health.health/_health.init_health)

func _process(_delta):
	var pos = _health.global_position
	if _raycast_camera.is_position_in_frustum(pos):
		visible = true
		#This is somewhat costly...
		var pos_2d = _raycast_camera.unproject_position(pos)
		self.position = pos_2d
	else:
		visible = false

func on_health_changed(_h: RTS_HealthComponent):
	_mesh.material.set_shader_parameter("health",_health.health/_health.init_health)

func on_death(_entity: RTS_Entity):
	queue_free()
