class_name RTS_BlockingControl extends Control

func _ready():
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func on_mouse_entered():
	RTS_Controls.ui.add_blocking_ui(self)

func on_mouse_exited():
	RTS_Controls.ui.remove_blocking_ui(self)
