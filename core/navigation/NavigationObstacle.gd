extends NavigationObstacle3D

class_name NavigationObstacle


func _enter_tree():
	call_deferred("add_to_handler")

func add_to_handler():
	if NavigationHandler.current != null:
		NavigationHandler.current.add_obstacle(self)
	else:
		push_error("Loaded NavigationObstacle with missing NavigationHandler")
