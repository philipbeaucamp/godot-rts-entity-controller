extends NavigationRegion3D

class_name NavigationHandler

var will_bake_at_end_of_frame: bool = false
static var current: NavigationHandler


func _enter_tree():
	NavigationHandler.current = self

func _ready():
	RTSEventBus.navigation_obstacle_tree_exit.connect(on_navigation_obstacle_tree_exit)

func _exit_tree():
	if NavigationHandler.current == self:
		NavigationHandler.current = null

func add_obstacle(obstacle: NavigationObstacle):
	obstacle.reparent(self)
	rebake()

func rebake():
	if !will_bake_at_end_of_frame:
		call_deferred("_rebake_deferred")
		will_bake_at_end_of_frame = true

func _rebake_deferred():
	print("Baking Nav Mesh...")
	for child in get_children():
		print("Child name: " + child.name)
	will_bake_at_end_of_frame = false
	self.bake_navigation_mesh(true)

func on_navigation_obstacle_tree_exit(obstacle: NavigationObstacleComponent):
	rebake()
