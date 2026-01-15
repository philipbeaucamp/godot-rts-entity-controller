extends Control

class_name Alert

@export var label: Label

static var instance: Alert

var tween: Tween

func _ready():
	instance = self
	label.modulate.a = 0.0

func push_new_alert(msg: StringName):
	label.text = msg
	if tween:
		tween.stop()
	tween = create_tween()
	label.modulate.a = 1.0
	tween.tween_property(label, "modulate:a", 0.0, 1.0) # fade out over 1 second
