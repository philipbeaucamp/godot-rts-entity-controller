extends Node3D

class_name TransformFollower

@export var target : Node3D

func _process(_delta):
	global_position = target.global_position
	global_rotation = target.global_rotation
