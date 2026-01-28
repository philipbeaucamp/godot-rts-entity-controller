class_name RTS_NavigationHandler extends NavigationRegion3D

var will_bake_at_end_of_frame: bool = false
static var current: RTS_NavigationHandler


func _enter_tree():
	RTS_NavigationHandler.current = self

func _ready():
	RTS_EventBus.navigation_obstacle_tree_exit.connect(on_navigation_obstacle_tree_exit)

func _exit_tree():
	if RTS_NavigationHandler.current == self:
		RTS_NavigationHandler.current = null

func add_obstacle(obstacle: RTS_NavigationObstacle):
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

func on_navigation_obstacle_tree_exit(obstacle: RTS_NavigationObstacleComponent):
	rebake()
