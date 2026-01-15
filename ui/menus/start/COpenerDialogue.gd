extends Control

class_name COpenerDialogue

@export var h_box_container: HBoxContainer
@export var c_opener: PackedScene

func _ready():
	RTSEventBus.run_ended.connect(on_run_ended)

func populate_with_openers():
	print("Populating Dialogue")
	# print_stack()
	var strategies : Array[Opener.Strategy] = [
		Opener.Strategy.ECO,
		Opener.Strategy.BALANCED,
		Opener.Strategy.RUSH
	]
	for strat in strategies:
		var opener = Opener.generate_opener(strat)		
		var c_instance : COpener = c_opener.instantiate()
		c_instance.set_up_c_opener(opener)
		c_instance.opener_selected.connect(on_opener_selected)
		h_box_container.add_child(c_instance)

func on_opener_selected(opener: Opener):
	RTSEventBus.opener_selected.emit(opener)
	queue_free()
	
func on_run_ended(_run: Run):
	self.queue_free()
