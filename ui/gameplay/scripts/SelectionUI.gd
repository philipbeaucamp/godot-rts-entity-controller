extends Control

class_name SelectionUI

var boxes : Array = [] #SelectionBoxUnit

func _ready():
	Controls.selection.selection_changed.connect(on_selection_changed)
	boxes = find_children("*","SelectionBoxUnit",true,true)
	for box in boxes:
		box.clean_up()

func on_selection_changed(selection: Array[Selectable]):
	for box in boxes:
		box.clean_up()
	var _size = selection.size()
	for i in _size:
		if i < boxes.size():
			boxes[i].set_up(selection[i])
		else:
			printerr("todo: not enough selection ui boxes")
