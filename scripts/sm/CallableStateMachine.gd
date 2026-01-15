class_name CallableStateMachine

var state_dictionary = {}
var previous_state: int = -1
var current_state: int = -1

signal exit_state(previous_state:int)
signal enter_state(new_state:int)

func add_states(
	state: int,
	normal_state_callable: Callable,
	enter_state_callable: Callable,
	leave_state_callable: Callable
):
	state_dictionary[state] = {
		"normal": normal_state_callable,
		"enter": enter_state_callable,
		"leave": leave_state_callable
	}

func set_initial_state(state:int):
	if state_dictionary.has(state):
		_set_state(state)
	else:
		push_warning("No state with name " + str(state))

func set_initial_state_silent(state:int):
	if state_dictionary.has(state):
		current_state = state
	else:
		push_warning("No state with name " + str(state))

func update():
	if current_state != null:
		(state_dictionary[current_state].normal as Callable).call()

func updatev(args: Array):
	if current_state != null:
		return (state_dictionary[current_state].normal as Callable).callv(args)

func change_state(new_state: int):
	if state_dictionary.has(new_state):
		_set_state.call_deferred(new_state)
	else:
		push_warning("No state with name " + str(new_state))

func _set_state(new_state:int):
	if current_state == new_state:
		return
	previous_state = current_state
	if current_state != -1:
		var leave_callable = state_dictionary[current_state].leave as Callable
		if !leave_callable.is_null():
			leave_callable.call()
		exit_state.emit(current_state)
	
	current_state = new_state
	var enter_callable = state_dictionary[current_state].enter as Callable
	if !enter_callable.is_null():
		enter_callable.call()
	enter_state.emit(new_state)
