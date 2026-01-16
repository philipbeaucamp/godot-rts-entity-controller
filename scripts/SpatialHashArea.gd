extends Area3D

class_name SpatialHashArea

@export var id: String = "1"
@export var INIT_CELL_SIZE = 1.0
@export var visual_debug: bool = false
@export var auto_update_clients : bool = false
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var origin: Vector3
var grid: SpatialHashFast
var entities: Dictionary[RTS_Entity,Client] = {} # keeps track of active entities
var clients: Dictionary[Client,RTS_Entity] = {}
var cell_size: float
var debug_color: Color

#Easy way to retrieve a main grid, set in _ready. Can be overwritten to achieve
#more complex behaviour
static var main_grid : SpatialHashArea 

func _ready():
	initialize_spatial_grid(INIT_CELL_SIZE)
	
	#subscription
	RTSEventBus.entity_entered_tree.connect(on_entity_entered_tree)
	RTSEventBus.entity_exiting_tree.connect(on_entity_exit_tree)

	debug_color = Color.from_hsv(randf(), 1.0, 1.0)

	#add already existing entities to grid
	var _entities = get_tree().get_nodes_in_group("entity")
	for e in _entities:
		try_add_client(e)

	#set main_grid
	main_grid = self
	RTSEventBus.grid_ready.emit(self)

func _physics_process(_delta):
	var do_debug = visual_debug
	if auto_update_clients || do_debug:
		update_clients()
	if do_debug:
		debug()

func initialize_spatial_grid(_cell_size: float):
	cell_size = _cell_size
	var size = collision_shape.shape.size
	var pos = collision_shape.global_position
	var dimensions : Vector2i = Vector2i(ceili(size.x/cell_size),ceil(size.z/cell_size))
	var half_bounds : Vector2 = cell_size * dimensions/2.0 
	origin = pos - Vector3(half_bounds.x,0,half_bounds.y)
	var end = pos + Vector3(half_bounds.x,0,half_bounds.y)
	var bounds : Array[Vector2] = [Vector2(origin.x,origin.z),Vector2(end.x,end.z)]
	grid = SpatialHashFast.new(bounds,dimensions)

	#for any already existing entities, (re)insert them into the spatial hash grid
	var keys = entities.keys()
	entities.clear()
	clients.clear()
	for entity in keys:
		if entity.space_hash:
			add_client(entity)

func try_add_client(entity: RTS_Entity):
	if entity.space_hash:
		add_client(entity)
	else:
		entity.sm.state_changed.connect(on_entity_state_changed.bind(entity))
		
func add_client(entity: RTS_Entity):
	if !entities.has(entity):
		var radius :float = entity.get_collision_radius()
		if radius == 0:
			printerr("RTS_Entity " + entity.name + "has missing or wrong collision shape/range")
		var client = grid.new_client(
			Vector2(entity.global_position.x,entity.global_position.z),
			Vector2(radius*2,radius*2),
			entity.faction
		)
		clients[client] = entity
		entities[entity] = client
	
func remove_client(entity: RTS_Entity):
	if entities.has(entity):
		var client = entities[entity]
		grid.remove(client)
		entities.erase(entity)
		clients.erase(client)

func update_clients():
	var _clients = clients.keys()
	for c in _clients:
		var pos = clients[c].global_position
		c.position = Vector2(pos.x,pos.z)
		#grid.update_client(client)
	grid.update_clients(_clients)

func find_entities_using_aabb(aabb: AABB, exact: bool, group: int = -1) -> Array[RTS_Entity]:
	var rst: Array[RTS_Entity] = []
	var center: Vector3 = aabb.get_center()
	var grouped_clients = grid.find_near(Vector2(center.x,center.z),Vector2(aabb.size.x,aabb.size.z),exact,group)
	for c in grouped_clients:
		rst.append(clients[c])
	return rst
	
func find_entities_bounds(pos: Vector3, bounds: Vector2, exact: bool, group: int = -1) -> Array[RTS_Entity]:
	var rst: Array[RTS_Entity] = []
	var grouped_clients = grid.find_near(Vector2(pos.x,pos.z),bounds,exact,group)
	for c in grouped_clients:
		rst.append(clients[c])
	return rst

func find_entities(pos: Vector3,radius: float, exact: bool, group: int = -1) -> Array[RTS_Entity]:
	var rst: Array[RTS_Entity] = []
	var double : float = radius * 2
	var grouped_clients = grid.find_near(Vector2(pos.x,pos.z),Vector2(double,double),exact,group)
	for c in grouped_clients:
		rst.append(clients[c])
	return rst

func get_selected_clients() -> Dictionary[Client,RTS_Entity]:
	var selectables : Array[RTS_Selectable] = Controls.selection.selection
	var selected_clients: Dictionary[Client,RTS_Entity] = {}
	for s in selectables:
		var e = s.entity
		if entities.has(e):
			selected_clients.set(entities[e],e)
	return selected_clients

func debug():
	var aabb = AABB(origin,Vector3(grid.dimensions.x * grid.cell_size.x,1,grid.dimensions.y * grid.cell_size.y))
	##DebugDraw3D.draw_aabb(aabb,debug_color)
	for x in grid.dimensions.x:
		for y in grid.dimensions.y:
			if grid.cells[x][y] != null:
				aabb = AABB(grid.get_cell_start_position(x,y),Vector3(grid.cell_size.x,1,grid.cell_size.y))
				##DebugDraw3D.draw_aabb(aabb,debug_color)
	#var _clients : Array[Client] = clients.keys()

func on_entity_entered_tree(entity: RTS_Entity):
	try_add_client(entity)

func on_entity_exit_tree(entity: RTS_Entity):
	remove_client(entity)
	
func on_entity_state_changed(entity: RTS_Entity, previous_state: int, new_state:int):
	if entity.space_hash:
		add_client(entity)
		entity.sm.state_changed.disconnect(on_entity_state_changed)
