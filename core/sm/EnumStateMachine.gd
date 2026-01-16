class_name RTS_EnumStateMachine

# A simple state machine that uses Enums for state representation

signal exit_state(previous_state:int)
signal enter_state(new_state:int)
signal state_changed(previous_state: int, new_state:int)

var current_state : int = -1 #initial current_state should be set in parent controller
var disabled := false #todo use dic

func change_state(new_state: int) -> void:
	if current_state == new_state || disabled:
		return
	
	var previous_state = current_state
	on_exit_state(previous_state)
	current_state = new_state
	on_enter_state(new_state)
	on_state_changed(previous_state,new_state)

# To be overridden by child classes
func on_enter_state(new_state: int) -> void:
	enter_state.emit(new_state)

func on_exit_state(old_state: int) -> void:
	exit_state.emit(old_state)

func on_state_changed(previous_state: int, new_state:int):
	state_changed.emit(previous_state, new_state)

#useful for debugging
func translate_state(enum_type: Dictionary) -> String:
	for key in enum_type.keys():
		if enum_type[key] == current_state:
			return key
	return "Unknown"
