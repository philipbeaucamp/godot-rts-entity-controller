class_name RTS_PhysicsSelection extends Node3D

@export var camera: RTS_RaycastCamera
@export var collision_mask: int

var previous_pickable : RTS_PickablePhysicsComponent
@onready var ui : RTS_SimpleUI = %UI

func clear_previous_pickable():
	if previous_pickable != null:
		previous_pickable.on_raycast_exited()
	previous_pickable = null

func _physics_process(_delta):
	if !Controls.is_enabled:
		return
	if !ui.blocks.is_empty():
		if previous_pickable:
			clear_previous_pickable()
		return
	var result = camera.get_mouse_position_raycast(collision_mask)
	if result:
		if result.collider is not RTS_ComponentLinker:
			return
		var pickable : RTS_PickablePhysicsComponent = result.collider.component
		if pickable != null &&  pickable.component_is_active:
			if pickable != previous_pickable:
				if previous_pickable != null:
					previous_pickable.on_raycast_exited()
				previous_pickable = pickable
				previous_pickable.on_raycast_entered()
	else:
		if previous_pickable != null:
			previous_pickable.on_raycast_exited()
			previous_pickable = null
	
	
			
