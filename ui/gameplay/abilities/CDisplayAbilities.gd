extends Control

class_name CDisplayAbilities

@export var common_container: HBoxContainer
@export var unique_container: HBoxContainer

var c_abilities: Array[CAbility] = []
var c_ability : PackedScene = preload("res://addons/rts_entity_controller/ui/gameplay/abilities/c_ability.tscn")
var c_ability_container : PackedScene = preload("res://addons/rts_entity_controller/ui/gameplay/scenes/c_ability_container.tscn")

func _ready():
	Controls.ability_manager.abilities_changed.connect(on_abilities_changed)

func create_ability_container() -> CAbilityContainer:
	var instance: CAbilityContainer = c_ability_container.instantiate()
	self.add_child(instance)
	return instance

func on_abilities_changed():
	for c in c_abilities:
		if is_instance_valid(c): #todo improve these queue free logic with callback ?
			c.queue_free()

	var dic : Dictionary[StringName,Array] = Controls.ability_manager.selected_abilities
	for id in dic:
		var abilities = dic[id]
		var resource : AbilityResource = abilities[0].resource
		if !resource.display:
			continue

		#Instaniate CAbility
		var instance : CAbility = c_ability.instantiate()
		var cast : Array[Ability] = []
		cast.assign(abilities)
		instance.set_up(cast)
		c_abilities.append(instance)

		#Parent to correct place
		var rep = abilities[0] as Ability
		if resource.is_common:
			common_container.add_child(instance)
		else:
			unique_container.add_child(instance)
					
