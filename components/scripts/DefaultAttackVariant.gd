extends AttackVariant

class_name DefaultAttackVariant

@export_group("Movement")

@export var attack_overrides_rotation = true
@export var cooldown_overrides_rotation = true

func state_idle():
	if behaviour.weapon_target:
		behaviour.state_machine.change_state(AttackBehaviour.State.ATTACKING)

func state_cooldown():
	if !behaviour.is_cooling_down():
		if behaviour.weapon_target:
			behaviour.state_machine.change_state(AttackBehaviour.State.ATTACKING)
		else:
			behaviour.state_machine.change_state(AttackBehaviour.State.IDLE)

func state_attacking():
	if behaviour.attack_anim_has_finished || behaviour.do_interrupt_attack:
		if behaviour.is_cooling_down():
			behaviour.state_machine.change_state(AttackBehaviour.State.COOLDOWN)
		else:
			behaviour.state_machine.change_state(AttackBehaviour.State.IDLE)

func set_component_active():
	super.set_component_active()
	if entity.movable != null:
		entity.movable.add_controller_override(self,1)
	
func set_component_inactive():
	super.set_component_inactive()
	if entity.movable != null:
		entity.movable.remove_controller_override(self)

func physics_process_override_movable(delta: float, movable: Movable):
	var apply_force : bool = true #Generally true, only false if we're calling move()
	if !behaviour.is_attack_immobilized():
		var state : int = behaviour.state_machine.current_state
		if state == AttackBehaviour.State.IDLE:
			if !try_move_attack_chased_target(movable):
				movable.sm.updatev([delta])
		elif state == AttackBehaviour.State.COOLDOWN:
			if cooldown_overrides_rotation && behaviour.current_target != null:
				movable.apply_instant_rotation(behaviour.current_target.entity.global_position)
			if !try_move_attack_chased_target(movable) && behaviour.weapon_target:
				if entity.movable.sm.current_state > Movable.State.HOLD:
					entity.movable.sm.change_state(Movable.State.IDLE)
			else:
				movable.sm.updatev([delta])
		elif state == AttackBehaviour.State.ATTACKING:
			if attack_overrides_rotation && behaviour.current_target != null:
				movable.apply_instant_rotation(behaviour.current_target.entity.global_position)
			if movable.sm.current_state != Movable.State.HOLD:
				if can_attack_while_moving:
					var active_target_type = movable.get_active_target_type()
					if (behaviour.current_target == behaviour.player_assigned_target || !(active_target_type == Movable.Type.MOVE || active_target_type == Movable.Type.ATTACK)):
						if entity.movable.sm.current_state > Movable.State.HOLD:
							entity.movable.sm.change_state(Movable.State.IDLE) #DO NOT MOVE
					else:
						apply_force = false
						movable.sm.updatev([delta])
				else:
					entity.movable.sm.change_state(Movable.State.IDLE) #DO NOT MOVE
	
	if apply_force && movable.accumulated_force != Vector3.ZERO:
		movable.apply_accumulated_force(delta)

func is_externally_immovable(movable: Movable) -> bool:
	var state = behaviour.state_machine.current_state
	return movable.sm.current_state == Movable.State.HOLD || state == AttackBehaviour.State.ATTACKING


func try_move_attack_chased_target(movable: Movable) -> bool:
	var target_to_chase : Defense
	if behaviour.player_assigned_target != null:
		target_to_chase = behaviour.player_assigned_target
	elif behaviour.current_target != null && behaviour.can_auto_attack_current_target:
		target_to_chase = behaviour.current_target
	elif behaviour.aggressor != null:
		target_to_chase = behaviour.aggressor
	
	if !target_to_chase:
		return false

	if (
		movable.sm.current_state != Movable.State.HOLD
		&& (!movable.next || 
			(
			movable.next.source != target_to_chase.entity
			&& (movable.next.type != Movable.Type.MOVE &&  movable.next.type != Movable.Type.ATTACK)
			)
			)
		):
		var previous_nav_target = movable.nav_agent.target_position
		movable.nav_agent.target_position = target_to_chase.entity.global_position
		var can_reach = movable.nav_agent.is_target_reachable()
		movable.nav_agent.target_position = previous_nav_target
		if !can_reach:
			# print("cant reach!")
		# if false:
			pass
			#unreachable, try moving to closest point if far away
			# var closest_point = NavigationServer3D.map_get_closest_point(rid,to)
			# if from.distance_squared_to(closest_point) > movable.stop_distance_squared:
			# 	movable.insert_before_next_target([
			# 		Target.new(
			# 		closest_point,
			# 		Movable.Type.MOVEATTACK,
			# 		null,
			# 		-1,
			# 		Vector3.ZERO,
			# 		{},
			# 		behaviour)
			# 		]
			# 	)
			# 	return true
		else:
			var target = Target.new(target_to_chase.entity.global_position,Movable.Type.MOVEATTACK,target_to_chase.entity,-1,Vector3.ZERO,{},behaviour)
			target.display = false
			movable.insert_before_next_target([target])
			return true
	return false
