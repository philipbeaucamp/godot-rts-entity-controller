extends BlockingControl

class_name SelectionBoxUnit

@onready var label: Label = $Label
@onready var texture_btn: TextureButton = $TextureButton

var selectable: Selectable

func _ready():
	super._ready()
	texture_btn.pressed.connect(on_pressed)

func set_up(_selectable: Selectable):
	selectable = _selectable
	var resource = _selectable.entity.resource
	label.text = resource.display_name
	texture_btn.texture_normal = resource.thumbnail
	self.visible = true

func clean_up():
	self.visible = false

#todo might have to iron out the following:
#removals don't "select" selected units again, but "ctrl"/single click do select again
func on_pressed():
	var is_shifting = Input.is_action_pressed("shift")
	var is_ctrl = Input.is_action_pressed("control")
	if is_ctrl:
		var similar = Controls.selection.get_all_similar_from_current_selection(selectable)
		if is_shifting:
			Controls.selection.remove_from_selection_bulk(similar)
		else:
			Controls.selection.remove_all_selection()
			Controls.selection.add_to_selection_bulk(similar)	
	elif is_shifting:
		Controls.selection.remove_from_selection(selectable)
	else:
		Controls.selection.remove_all_selection()
		var selectables : Array[Selectable] = [selectable]
		Controls.selection.add_to_selection_bulk(selectables)
	
