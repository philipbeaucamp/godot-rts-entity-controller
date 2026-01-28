class_name RTS_NavigationObstacle extends NavigationObstacle3D


func _enter_tree():
	call_deferred("add_to_handler")

func add_to_handler():
	if RTS_NavigationHandler.current != null:
		RTS_NavigationHandler.current.add_obstacle(self)
	else:
		push_error("Loaded RTS_NavigationObstacle with missing RTS_NavigationHandler")
