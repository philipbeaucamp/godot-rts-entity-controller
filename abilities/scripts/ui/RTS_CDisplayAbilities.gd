class_name RTS_CDisplayAbilities extends Control

@export var common_container: HBoxContainer
@export var unique_container: HBoxContainer

var c_abilities: Array[RTS_CAbility] = []
var c_ability : PackedScene = preload("res://addons/godot-rts-entity-controller/abilities/scenes/ui/c_ability.tscn")
var c_ability_container : PackedScene = preload("res://addons/godot-rts-entity-controller/abilities/scenes/ui/c_ability_container.tscn")

func _ready():
	RTS_Controls.ability_manager.abilities_changed.connect(on_abilities_changed)

func on_abilities_changed():
	for c in c_abilities:
		if is_instance_valid(c): #todo improve these queue free logic with callback ?
			c.queue_free()

	var dic : Dictionary[StringName,Array] = RTS_Controls.ability_manager.selected_abilities
	for id in dic:
		var abilities = dic[id]
		var resource : AbilityResource = abilities[0].resource
		if !resource.display:
			continue

		#Instaniate RTS_CAbility
		var instance : RTS_CAbility = c_ability.instantiate()
		var cast : Array[RTS_Ability] = []
		cast.assign(abilities)
		instance.set_up(cast)
		c_abilities.append(instance)

		#Parent to correct place
		var rep = abilities[0] as RTS_Ability
		if resource.is_common:
			common_container.add_child(instance)
		else:
			unique_container.add_child(instance)
					
