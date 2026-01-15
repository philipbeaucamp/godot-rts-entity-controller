extends Control

class_name UI

@export var c_display_abilities: CDisplayAbilities

var blocks: Dictionary[BlockingControl,bool] = {}

func add_blocking_ui(control: BlockingControl):
	if !blocks.has(control):
		blocks.set(control,true)

func remove_blocking_ui(control: BlockingControl):
	if blocks.has(control):
		blocks.erase(control)
