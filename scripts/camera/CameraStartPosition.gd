extends Node3D

class_name CamerStartPosition

@export var camera_menu_position: Node3D
@export var is_enabled: bool = true
static var current: CamerStartPosition

func _ready():
	if is_enabled:
		RTSEventBus.set_camera_start_position.emit(global_position)
	current = self
