extends Resource

class_name RTSSettings

@export_group("General Settings")
@export var double_click_time : float = 0.35

@export_group("Selection")
@export var use_highest_entity_for_ability_selection: bool = false

@export_group("Collision Layers")
@export var collision_layer_navigation = 1
@export var collision_layer_units = 2
@export var collision_layer_buildings_and_rocks = 4
@export var collision_layer_selection = 5
@export var collision_layer_pickable_physics = 6
@export var collision_layer_force = 7
@export var collision_layer_player_attack = 8
@export var collision_layer_player_defense = 9
@export var collision_layer_enemy_attack = 10
@export var collision_layer_enemy_defense = 11
@export var collision_layer_shields = 12
@export var collision_layer_projectile = 13

@export_group("Debugging")
@export var allow_enemy_entity_control: bool = false
@export var invincibility: bool = false
