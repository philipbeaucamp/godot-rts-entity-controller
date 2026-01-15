extends Control

class_name BlockingControl

func _ready():
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func on_mouse_entered():
	Controls.ui.add_blocking_ui(self)

func on_mouse_exited():
	Controls.ui.remove_blocking_ui(self)
