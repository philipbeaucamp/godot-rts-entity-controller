extends Area3D

@export var is_enabled: bool = true

func _ready():
	if is_enabled:
		RTS_EventBus.set_camera_boundary.emit(self,true)

func _exit_tree():
	RTS_EventBus.set_camera_boundary.emit(self,false)
