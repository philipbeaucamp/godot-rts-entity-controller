class_name RTS_AbilityContainer extends Node3D

var c_ability_container: CAbilityContainer

func _ready():
	c_ability_container = Controls.ui.c_display_abilities.create_ability_container()
	c_ability_container.set_world_node(self)
