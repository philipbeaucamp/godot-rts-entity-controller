class_name RTS_ToggleAbility extends RTS_Ability

#RTS_Ability that can have an is_ability_active state, i.e. SC2 Tanks's "Siege Mode"

signal toggle_activated()
signal toggle_deactived()

enum State {
	DEACTIVATED,
	ACTIVATED
}

func set_up_statemachine():
	state_machine.add_states(State.DEACTIVATED,Callable(),on_deactivated,Callable())
	state_machine.add_states(State.ACTIVATED,state_active,on_activated,Callable())
	state_machine.set_initial_state_silent(State.DEACTIVATED)

func get_cooldown_timer_duration() -> float:
	if state_machine.current_state == State.ACTIVATED:
		return resource.cooldown_duration
	else:
		return resource.deactivate_cooldown_duration
	
func activate():
	if state_machine.current_state == State.DEACTIVATED:
		state_machine.change_state(State.ACTIVATED)
	else:
		state_machine.change_state(State.DEACTIVATED)

func state_active():
	pass

func on_activated():
	start_cooldown(resource.cooldown_duration)
	toggle_activated.emit()

func on_deactivated():
	start_cooldown(resource.deactivate_cooldown_duration)
	toggle_deactived.emit()
