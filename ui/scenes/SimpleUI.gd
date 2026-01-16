class_name RTS_SimpleUI extends Control

@export var c_display_abilities: CDisplayAbilities

var blocks: Dictionary[RTS_BlockingControl,bool] = {}

func add_blocking_ui(control: RTS_BlockingControl):
	if !blocks.has(control):
		blocks.set(control,true)

func remove_blocking_ui(control: RTS_BlockingControl):
	if blocks.has(control):
		blocks.erase(control)
