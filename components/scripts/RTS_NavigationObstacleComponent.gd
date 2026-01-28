class_name RTS_NavigationObstacleComponent extends RTS_Component

##If positive and this is a movable target, will translate the target position
##by below float range towards movable
@export var obstacle_radius: float = 0.5

func _exit_tree():
	RTS_EventBus.navigation_obstacle_tree_exit.emit(self)
