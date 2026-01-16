class_name RTS_SelectionUI extends Control

var boxes : Array = [] #RTS_SelectionBoxUnit

func _ready():
	Controls.selection.selection_changed.connect(on_selection_changed)
	boxes = find_children("*","RTS_SelectionBoxUnit",true,true)
	for box in boxes:
		box.clean_up()

func on_selection_changed(selection: Array[RTS_Selectable]):
	for box in boxes:
		box.clean_up()
	var _size = selection.size()
	for i in _size:
		if i < boxes.size():
			boxes[i].set_up(selection[i])
		else:
			push_warning("Todo: not enough selection ui boxes")
