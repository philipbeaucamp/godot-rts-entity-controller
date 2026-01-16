extends Node3D

class_name SquadBehaviour

@export var init_behaviour : Squad.Behaviour = Squad.Behaviour.DEFENSIVE
@export var init_move_target: Node3D
@export var init_move_type: RTS_Movable.Type = RTS_Movable.Type.MOVE
@export var hold_on_init: bool = false

var squad : Squad

func _ready():
	var children = get_children()
	var entities : Array[RTS_Entity] = []
	for child in children:
		if child is RTS_Entity:
			entities.append(child)
	if !entities.is_empty():
		squad = Squad.new(entities,init_behaviour)
		add_child(squad)
	
	if init_move_target:
		await get_tree().create_timer(1).timeout #todo...
		call_deferred("move",init_move_target,entities)
			
	if hold_on_init:
		for e in entities:
			if e.abilities.has("hold"):
				e.abilities["hold"].activate()

func move(target: Node3D,entities: Array[RTS_Entity]):
	var moving_abilities: Array[Ability] = []
	var moving_id = ""
	var source_target = target if target is RTS_Entity else null
	match init_move_type:
		RTS_Movable.Type.MOVE:
			var movables: Array[RTS_Movable] = []
			for e in entities:
				if e.movable:
					movables.append(e.movable)
			Controls.movement.group_move(
				target.global_position,
				source_target,
				movables,
				false,
				RTS_Movable.Type.MOVE
			)
			return
		RTS_Movable.Type.PATROL:
			moving_id = "patrol"
		RTS_Movable.Type.ATTACK, RTS_Movable.Type.MOVEATTACK:
			moving_id = "attack"

	if target:
		for e in entities:
			if e.abilities.has(moving_id):
				moving_abilities.append(e.abilities[moving_id])

	if !moving_abilities.is_empty():
		var input: Dictionary = {}
		input["click_target"] = target.global_position
		input["click_target_source"] = source_target
		input["shift_is_pressed"] = false

		moving_abilities[0].set_context(input)
		moving_abilities[0].activate_group(moving_abilities)
