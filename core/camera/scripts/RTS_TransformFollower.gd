class_name RTS_TransformFollower extends Node3D

@export var target : Node3D

func _process(_delta):
	global_position = target.global_position
	global_rotation = target.global_rotation
