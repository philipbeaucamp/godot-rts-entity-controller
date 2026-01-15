extends Node3D

class_name SquadBehaviour

@export var init_behaviour : Squad.Behaviour = Squad.Behaviour.DEFENSIVE
@export var init_move_target: Node3D
@export var init_move_type: Movable.Type = Movable.Type.MOVE
@export var init_move_timing: TIMING
@export var hold_on_init: bool = false

var squad : Squad

enum TIMING{
	READY,
	SCENARIO_START
}

func _ready():
	var children = get_children()
	var entities : Array[Entity] = []
	for child in children:
		if child is Entity:
			entities.append(child)
	if !entities.is_empty():
		squad = Squad.new(entities,init_behaviour)
		add_child(squad)
	

	if init_move_target:
		if init_move_timing == TIMING.READY:
			await get_tree().create_timer(1).timeout #todo...
			call_deferred("move",init_move_target,entities)
		elif init_move_timing == TIMING.SCENARIO_START:
			NimbleEvents.subscribe("scenario_started",self,"on_scenario_started")
			
	if hold_on_init:
		for e in entities:
			if e.abilities.has("hold"):
				e.abilities["hold"].activate()

func on_scenario_started(_event: Event):
	await get_tree().create_timer(1).timeout
	move(init_move_target,squad.entities)

func move(target: Node3D,entities: Array[Entity]):
	var moving_abilities: Array[Ability] = []
	var moving_id = ""
	var source_target = target if target is Entity else null
	match init_move_type:
		Movable.Type.MOVE:
			var movables: Array[Movable] = []
			for e in entities:
				if e.movable:
					movables.append(e.movable)
			Controls.movement.group_move(
				target.global_position,
				source_target,
				movables,
				false,
				Movable.Type.MOVE
			)
			return
		Movable.Type.PATROL:
			moving_id = "patrol"
		Movable.Type.ATTACK, Movable.Type.MOVEATTACK:
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
