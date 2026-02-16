class_name RTS_CamerStartPosition extends Node3D

@export var is_enabled: bool = true
static var current: RTS_CamerStartPosition

func _ready():
	if is_enabled:
		RTS_EventBus.set_camera_start_position.emit(global_position)
	current = self
