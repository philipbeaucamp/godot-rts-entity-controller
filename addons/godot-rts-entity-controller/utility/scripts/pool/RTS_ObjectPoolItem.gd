class_name RTS_ObjectPoolItem extends Node3D

var is_active := false

func set_active(value: bool):
	if value && !is_active:
		is_active = true
		visible = true
		set_physics_process(true)
		set_process_input(true)  
		process_mode = Node.PROCESS_MODE_INHERIT
	elif !value:
		is_active = false
		visible = false
		set_physics_process(false)
		set_process_input(false)   
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		process_mode = Node.PROCESS_MODE_DISABLED
		
