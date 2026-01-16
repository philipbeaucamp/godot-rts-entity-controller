class_name RTS_ControlGroup extends Control

@export var control_group_index: int
@onready var label: Label = $Label
@onready var index_label: Label = $Index

func _ready():
	RTSEventBus.update_control_group.connect(on_control_group_updated)
	RTSEventBus.select_control_group.connect(on_select_control_group)
	index_label.text = str(control_group_index)

func on_control_group_updated(index: int, selectables: Array[RTS_Selectable], _selection: RTS_Selection):
	if control_group_index == index:
		visible = !selectables.is_empty()
		label.text = str(selectables.size())

func on_select_control_group(index: int, _selectables: Array):
	if index == control_group_index:
		var style_box = self.get_theme_stylebox("panel","PanelContainer") as StyleBoxFlat
		style_box.border_color.a = 1
		await get_tree().create_timer(0.05).timeout
		style_box.border_color.a = 0
		
