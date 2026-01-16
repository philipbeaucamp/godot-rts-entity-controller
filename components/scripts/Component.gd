class_name RTS_Component extends Node

# Base class for all RTS RTS_Entity Components.
# Holds a reference to entity (usually the parent) manages activating/deactivating components.
# Usually for example when wanting to disable certain component logic, such as 
# Movement, or Attack etc.

@export var set_component_active_on_ready: bool = true

var component_is_active = false
var entity: RTS_Entity
var is_set_up : bool = false

func _ready():
	entity = fetch_entity()
	entity.end_of_life.connect(on_end_of_life)
	if set_component_active_on_ready && !component_is_active:
		set_component_active()

# can be override, for instance if the component is NOT direct child of RTS_Entity
func fetch_entity() -> RTS_Entity:
	return get_parent() as RTS_Entity
	
func set_component_inactive():
	component_is_active = false

func set_component_active():
	assert(!component_is_active,"RTS_Component set active twice. You're game logic is probably flawed.")
	component_is_active = true

func on_end_of_life(_entity: RTS_Entity):
	set_component_inactive()
