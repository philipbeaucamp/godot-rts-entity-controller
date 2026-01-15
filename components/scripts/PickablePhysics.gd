extends Component
class_name PickablePhysics

var raycast_in_body = false
var selection : Selection
@export var selectable: Selectable
@export var static_body: StaticBody3D

signal hovered(pickable: PickablePhysics)
signal unhovered(pickable: PickablePhysics)

func fetch_entity():
	return selectable.fetch_entity()

func _ready():
	super._ready()
	selection = Controls.selection

func set_component_active():
	super.set_component_active() 
	static_body.set_collision_layer_value(Controls.settings.collision_layer_pickable_physics,true)
	static_body.set_collision_mask_value(Controls.settings.collision_layer_pickable_physics,true)

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
