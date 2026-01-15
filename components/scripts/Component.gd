extends Node

class_name Component

@export var set_component_active_on_ready: bool = true

var component_is_active = false
var entity: Entity
var is_set_up : bool = false

func _ready():
	entity = fetch_entity()
	entity.end_of_life.connect(on_end_of_life)
	if set_component_active_on_ready && !component_is_active:
		set_component_active()

# can be override, for instance if the component is NOT direct child of Entity
func fetch_entity() -> Entity:
	return get_parent() as Entity
	
func set_component_inactive():
	component_is_active = false

func set_component_active():
	assert(!component_is_active,"Component set active twice. You're game logic is probably flawed.")
	component_is_active = true

func on_end_of_life(_entity: Entity):
	set_component_inactive()
