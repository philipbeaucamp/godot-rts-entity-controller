extends Resource

class_name RTSSettings

@export var double_click_time : float = 0.35

@export var collision_layer_navigation = 1
var collision_layer_units = 2
var collision_layer_buildings_and_rocks = 4
var collision_layer_selection = 5
var collision_layer_pickable_physics = 6
var collision_layer_force = 7
var collision_layer_player_attack = 8
var collision_layer_player_defense = 9
var collision_layer_enemy_attack = 10
var collision_layer_enemy_defense = 11
var collision_layer_shields = 12
var collision_layer_projectile = 13

@export_group("Debugging")
@export var allow_enemy_entity_control: bool = false
@export var invincibility: bool = false
