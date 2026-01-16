class_name Squad extends Node

var entities: Array[RTS_Entity]
var waiting_init: Array[RTS_Entity]

var state_machine: CallableStateMachine = CallableStateMachine.new()

var init_behaviour: Behaviour
var last_tree_exit_entity_position: Vector3

enum Behaviour {
	AGGRESSIVE, #Will automatically seek and attack enemies based on main grid
	DEFENSIVE #Will only attack if attacked or given player orders
}

func _init(_init_entities: Array[RTS_Entity], _init_state: Behaviour):
	init_behaviour = _init_state
	for e in _init_entities:
		if !e.is_ready:
			waiting_init.append(e)
			if !RTSEventBus.entity_ready.is_connected(on_entity_ready):
				RTSEventBus.entity_ready.connect(on_entity_ready)
		else:
			add_to_squad(e)

	var is_waiting = !waiting_init.is_empty()
	RTSEventBus.squad_created.emit(self,is_waiting)

	if !is_waiting:
		ready_squad()

func on_entity_ready(entity: RTS_Entity):
	if waiting_init.has(entity):
		waiting_init.erase(entity)
		add_to_squad(entity)
	if waiting_init.is_empty():
		RTSEventBus.entity_ready.disconnect(on_entity_ready)
		ready_squad()
		print("Initialized Squad after waiting for all entities!")

func ready_squad():
	state_machine.add_states(Behaviour.AGGRESSIVE,state_engaging,Callable(),Callable())
	state_machine.add_states(Behaviour.DEFENSIVE,state_defending,Callable(),Callable())
	state_machine.set_initial_state(init_behaviour)
	RTSEventBus.squad_is_ready.emit(self)

func add_to_squad(entity: RTS_Entity):
	entities.append(entity)
	if entity.attack != null:
		entity.attack.target_became_not_null.connect(on_target_became_not_null)
	if entity.ai != null:
		entity.ai.set_squad(self)
	entity.before_tree_exit.connect(on_before_tree_exit)

func remove_from_squad(entity: RTS_Entity):
	entities.erase(entity)
	if entity.ai != null:
		entity.ai.remove_squad(self)
	if entity.attack != null:
		entity.attack.target_became_not_null.disconnect(on_target_became_not_null)
	if entities.is_empty():
		RTSEventBus.squad_became_empty.emit(self)
		self.queue_free()

func free_all_entities():
	for e in entities:
		e.queue_free()

func state_engaging():
	var ai = Controls.tactical_ai
	
	if ai.player_cluster_centers.is_empty():
		return

	#1. any entities doing nothing?
	var idling : Array[Ability] = []
	for e in entities:
		if e.ai != null && e.ai.can_engage():
			idling.append(e.abilities["attack"])
	
	if !idling.is_empty():
		#Get closest cluster and attack more there
		var closest_cluster : Vector3
		var closest_distance : float = INF
		var representive_start = idling[0].entity.global_position
		for c in ai.player_cluster_centers:
			var d = representive_start.distance_squared_to(c)
			if d < closest_distance:
				closest_cluster = c
				closest_distance = d
		set_context_and_attack(idling,closest_cluster,null)

func state_defending():
	pass 

func on_before_tree_exit(entity: RTS_Entity):
	last_tree_exit_entity_position = entity.global_position
	remove_from_squad(entity)

func has_attack_target(entity: RTS_Entity) -> bool:
	return entity.attack.current_target != null || entity.attack.player_assigned_target != null

func on_target_became_not_null(_attack: RTS_AttackComponent, new_target: RTS_Defense):
	var idling : Array[Ability] = []
	for e in entities:
		assert(e != null,"Squad RTS_Entity should not be null")
		if e.ai != null && e.ai.can_engage():
			idling.append(e.abilities["attack"])

	if !idling.is_empty():
		#Not force setting player assigned target to new_target.entity is better for ai handling
		#if we do set it events such as threat_changed will update current_target,
		#but not player_assigned target and we run into issues for enemies.
		set_context_and_attack(idling,new_target.entity.global_position, null) 

func set_context_and_attack(abilities: Array[Ability], target: Vector3, source: RTS_Entity):
	print("Squad making attack move!")
	var context : Dictionary = {
		"click_target": target,
		"click_target_source": source,
		"shift_is_pressed": false
	}
	abilities[0].set_context(context)
	abilities[0].activate_group(abilities)
