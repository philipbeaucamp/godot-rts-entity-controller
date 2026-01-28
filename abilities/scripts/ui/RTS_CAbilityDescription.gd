class_name RTS_CAbilityDescription extends Control

@export var square: Control
@export var label: Label

var ability_resource: AbilityResource

func set_up(_res: AbilityResource):
	ability_resource = _res
	label.text = _res.description
	
func _ready():
	self.visible = false
	square.mouse_entered.connect(on_mouse_entered)
	square.mouse_exited.connect(on_mouse_exited)

func on_mouse_entered():
	if label.text:
		self.visible = true
func on_mouse_exited():
	self.visible = false
