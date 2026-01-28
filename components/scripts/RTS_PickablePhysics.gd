class_name RTS_PickablePhysicsComponent extends RTS_Component

var raycast_in_body = false
var selection : RTS_Selection
@export var selectable: RTS_Selectable
@export var static_body: StaticBody3D

signal hovered(pickable: RTS_PickablePhysicsComponent)
signal unhovered(pickable: RTS_PickablePhysicsComponent)

func fetch_entity():
	return selectable.fetch_entity()

func _ready():
	super._ready()
	selection = RTS_Controls.selection

func set_component_active():
	super.set_component_active() 
	static_body.set_collision_layer_value(RTS_Controls.settings.collision_layer_pickable_physics,true)
	static_body.set_collision_mask_value(RTS_Controls.settings.collision_layer_pickable_physics,true)

func set_component_inactive():
	super.set_component_inactive()
	static_body.collision_layer = 0
	static_body.collision_mask = 0

func on_raycast_entered():
	raycast_in_body = true
	hovered.emit(self)
	selection.set_hovered_pickable(self)

func on_raycast_exited():
	raycast_in_body = false
	unhovered.emit(self)
	selection.unset_hovered_pickable(self)
