extends Node3D

class_name RTS_CamerStartPosition

@export var is_enabled: bool = true
static var current: RTS_CamerStartPosition

func _ready():
	if is_enabled:
		RTSEventBus.set_camera_start_position.emit(global_position)
	current = self
