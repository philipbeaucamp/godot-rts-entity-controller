extends Area3D

class_name CameraBoundary

@export var is_enabled: bool = true

func _ready():
	if is_enabled:
		RTSEventBus.set_camera_boundary.emit(self,true)

func _exit_tree():
	RTSEventBus.set_camera_boundary.emit(self,false)
