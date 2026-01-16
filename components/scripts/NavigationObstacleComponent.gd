class_name NavigationObstacleComponent extends Component

##If positive and this is a movable target, will translate the target position
##by below float range towards movable
@export var obstacle_radius: float = 0.5

func _exit_tree():
	RTSEventBus.navigation_obstacle_tree_exit.emit(self)
