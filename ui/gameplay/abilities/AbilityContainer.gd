extends Node3D

class_name AbilityContainer

var c_ability_container: CAbilityContainer

func _ready():
	c_ability_container = Controls.ui.c_display_abilities.create_ability_container()
	c_ability_container.set_world_node(self)
