class_name RTS_SimpleAIController extends Node

# Simple AI Controller that manages squads for basic tactical behavior
# Feels free to extend or modify for more complex AI needs

const SQUAD_TICK_TIME : float = 1.5
const CLUSTER_UPDATE_TICK : float = 0.5

var squads_waiting_for_initialization: Array[Squad] = []
var active_squads: Array[Squad] = []
var waiting_squads: Array[Squad] = [] #need reference because otherwise waiting squad will have
var tick_deltas: Array[float]
var cluster_update_delta: float = 0

var player_order_clusters_by_biggest: Array = [] #biggest first
var player_cluster_centers: Array[Vector3] = []

func _ready():
	RTSEventBus.squad_created.connect(on_squad_created)
	RTSEventBus.squad_is_ready.connect(on_squad_is_ready)
	RTSEventBus.squad_became_empty.connect(on_squad_became_empty)

func _process(delta):
	cluster_update_delta += delta
	if cluster_update_delta >=  CLUSTER_UPDATE_TICK:
		cluster_update_delta -= CLUSTER_UPDATE_TICK
		update_clusters()
		
	for i in range(active_squads.size()):
		tick_deltas[i] += delta
		if tick_deltas[i] >= SQUAD_TICK_TIME:
			tick_deltas[i] -= SQUAD_TICK_TIME
			active_squads[i].state_machine.update()

func update_clusters():
	if !SpatialHashArea.main_grid:
		return

	#Ever tick we update the Spatial Hash grid. Don't do this every frame, since its relatively expensive
	var grid : SpatialHashFast = SpatialHashArea.main_grid.grid
	player_order_clusters_by_biggest = grid.flood_fill_clusters(1,RTS_Entity.Faction.PLAYER)
	player_order_clusters_by_biggest.sort_custom(func(a: Array, b: Array) -> bool:
		return a.size() > b.size()
	)
	player_cluster_centers = []
	if !player_order_clusters_by_biggest.is_empty():
		#probably good enough to simply avg the cluster pos, not client position
		var bounds = grid.bounds
		var cell_size = grid.cell_size
		for cluster in player_order_clusters_by_biggest:
			var avg : Vector2 = Vector2.ZERO
			for cell in cluster:
				avg += Vector2(cell)
			avg /= cluster.size()
			player_cluster_centers.append(Vector3(bounds[0].x + avg.x * cell_size.x, 0, bounds[0].y + avg.y * cell_size.y))

		#Not a bad idea to debug visualize the cluster centers here with your favorite debug draw tool

func add_squad(squad: Squad, is_waiting: bool):
	if is_waiting:
		waiting_squads.append(squad)
	else:
		active_squads.append(squad)
		tick_deltas.append(SQUAD_TICK_TIME) #will instantly run a tick

func remove_squad(squad: Squad):
	var index = active_squads.find(squad)
	if index > -1:
		active_squads.remove_at(index)
		tick_deltas.remove_at(index)

func on_squad_created(squad: Squad, is_waiting: bool):
	add_squad(squad,is_waiting)

func on_squad_is_ready(squad: Squad):
	if waiting_squads.has(squad):
		active_squads.append(squad)
		tick_deltas.append(SQUAD_TICK_TIME) #will instantly run a tick
		waiting_squads.erase(squad)

func on_squad_became_empty(squad: Squad):
	remove_squad(squad)
