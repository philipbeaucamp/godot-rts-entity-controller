class_name RTS_DefaultAttackVariant extends RTS_AttackVariant

# Default attack variant implementation.
# Suitable for most basic units (eg. SC2 Marine)
# Notice how it overrides movement logic by implementing physics_process_override_movable
# which is called from RTS_MovableComponent.gd

@export_group("RTS_Movement")
@export var attack_overrides_rotation = true
@export var cooldown_overrides_rotation = true

func state_idle():
	if behaviour.weapon_target:
		behaviour.state_machine.change_state(RTS_AttackComponent.State.ATTACKING)

func state_cooldown():
	if !behaviour.is_cooling_down():
		if behaviour.weapon_target:
			behaviour.state_machine.change_state(RTS_AttackComponent.State.ATTACKING)
		else:
			behaviour.state_machine.change_state(RTS_AttackComponent.State.IDLE)

func state_attacking():
	if behaviour.attack_anim_has_finished || behaviour.do_interrupt_attack:
		if behaviour.is_cooling_down():
			behaviour.state_machine.change_state(RTS_AttackComponent.State.COOLDOWN)
		else:
			behaviour.state_machine.change_state(RTS_AttackComponent.State.IDLE)

func set_component_active():
	super.set_component_active()
	if entity.movable != null:
		entity.movable.add_controller_override(self,1)
	
func set_component_inactive():
	super.set_component_inactive()
	if entity.movable != null:
		entity.movable.remove_controller_override(self)

func physics_process_override_movable(delta: float, movable: RTS_Movable):
	var apply_force : bool = true #Generally true, only false if we're calling move()
	if !behaviour.is_attack_immobilized():
		var state : int = behaviour.state_machine.current_state
		if state == RTS_AttackComponent.State.IDLE:
			if !try_move_attack_chased_target(movable):
				movable.sm.updatev([delta])
		elif state == RTS_AttackComponent.State.COOLDOWN:
			if cooldown_overrides_rotation && behaviour.current_target != null:
				movable.apply_instant_rotation(behaviour.current_target.entity.global_position)
			if !try_move_attack_chased_target(movable) && behaviour.weapon_target:
				if entity.movable.sm.current_state > RTS_Movable.State.HOLD:
					entity.movable.sm.change_state(RTS_Movable.State.IDLE)
			else:
				movable.sm.updatev([delta])
		elif state == RTS_AttackComponent.State.ATTACKING:
			if attack_overrides_rotation && behaviour.current_target != null:
				movable.apply_instant_rotation(behaviour.current_target.entity.global_position)
			if movable.sm.current_state != RTS_Movable.State.HOLD:
				if can_attack_while_moving:
					var active_target_type = movable.get_active_target_type()
					if (behaviour.current_target == behaviour.player_assigned_target || !(active_target_type == RTS_Movable.Type.MOVE || active_target_type == RTS_Movable.Type.ATTACK)):
						if entity.movable.sm.current_state > RTS_Movable.State.HOLD:
							entity.movable.sm.change_state(RTS_Movable.State.IDLE) #DO NOT MOVE
					else:
						apply_force = false
						movable.sm.updatev([delta])
				else:
					entity.movable.sm.change_state(RTS_Movable.State.IDLE) #DO NOT MOVE
	
	if apply_force && movable.accumulated_force != Vector3.ZERO:
		movable.apply_accumulated_force(delta)

func is_externally_immovable(movable: RTS_Movable) -> bool:
	var state = behaviour.state_machine.current_state
	return movable.sm.current_state == RTS_Movable.State.HOLD || state == RTS_AttackComponent.State.ATTACKING

func try_move_attack_chased_target(movable: RTS_Movable) -> bool:
	var target_to_chase : RTS_Defense
	if behaviour.player_assigned_target != null:
		target_to_chase = behaviour.player_assigned_target
	elif behaviour.current_target != null && behaviour.can_auto_attack_current_target:
		target_to_chase = behaviour.current_target
	elif behaviour.aggressor != null:
		target_to_chase = behaviour.aggressor
	
	if !target_to_chase:
		return false

	if (
		movable.sm.current_state != RTS_Movable.State.HOLD
		&& (!movable.next || 
			(
			movable.next.source != target_to_chase.entity
			&& (movable.next.type != RTS_Movable.Type.MOVE &&  movable.next.type != RTS_Movable.Type.ATTACK)
			)
			)
		):
		var previous_nav_target = movable.nav_agent.target_position
		movable.nav_agent.target_position = target_to_chase.entity.global_position
		var can_reach = movable.nav_agent.is_target_reachable()
		movable.nav_agent.target_position = previous_nav_target
		if can_reach:
			var target = RTS_Target.new(target_to_chase.entity.global_position,RTS_Movable.Type.MOVEATTACK,target_to_chase.entity,-1,Vector3.ZERO,{},behaviour)
			target.display = false
			movable.insert_before_next_target([target])
			return true
		else:
			# You could add extra logic to handle non reachable targets, i.e. move to closest point
			pass
	return false
