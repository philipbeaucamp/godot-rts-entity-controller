extends Control

class_name ControlGroups

@export var control_groups : Array[Control] = []
@export var ctrlnum: Control

func _ready():
	RTSEventBus.update_control_group.connect(on_control_group_updated)
	ctrlnum.visible = true

func on_control_group_updated(_index: int, _selectables: Array[RTS_Selectable],selection: RTS_Selection):
	ctrlnum.visible = selection.hotkey_groups.is_empty()
