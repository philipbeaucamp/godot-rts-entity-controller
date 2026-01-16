class_name RTS_SpatialHashFast

#Godot implementation of a spatial hash grid for fast spatial queries
#Reference: Translated from here: https://github.com/simondevyoutube/Tutorial_SpatialHashGrid_Optimized/blob/main/src/spatial-grid.js
#Video Reference https://www.youtube.com/watch?v=sx4IIQL0x7c

var cells: Array #Array[Array[RTS_HashNode]] (rows/columns)
var dimensions: Vector2i # dimensions of grid (how many x and y cells)
var bounds: Array[Vector2] # [min: Vector2, max: Vector2] defines area of the grid
var query_ids: int = 0
var cell_size: Vector2
var clients: Dictionary[RTS_HashClient,bool] #only used for flood fill

func _init(_bounds: Array[Vector2], _dimensions: Vector2i):
	bounds = _bounds
	dimensions = _dimensions
	clients.clear()
	print("Initialize Spatial grid with bounds: " + str(bounds) + " and dim: " + str(dimensions))
	cell_size = (bounds[1]-bounds[0])/Vector2(_dimensions)
	cells = []
	for x in dimensions.x:
		var col = []
		for y in dimensions.y:
			col.append(null)
		cells.append(col)

func _get_cell_index(pos: Vector2) -> Vector2i:
	var x = (pos.x - bounds[0].x) / (bounds[1].x - bounds[0].x)
	var y = (pos.y - bounds[0].y) / (bounds[1].y - bounds[0].y)
	return Vector2i(floori(x * (dimensions.x)), floori(y * (dimensions.y )))

func get_cell_start_position(x: int,y:int) -> Vector3:
	return Vector3(bounds[0].x + x * cell_size.x, 0, bounds[0].y + y * cell_size.y)
func get_cell_center_position(x: int,y:int) -> Vector3:
	return Vector3(bounds[0].x + x * cell_size.x + cell_size.x/2.0, 0, bounds[0].y + y * cell_size.y + cell_size.y/2.0)
func get_cell_center_position_float(x: float, y: float) -> Vector3:
	return Vector3(bounds[0].x + x * cell_size.x + cell_size.x/2.0, 0, bounds[0].y + y * cell_size.y + cell_size.y/2.0)
	
func new_client(pos: Vector2, size: Vector2, group: int) -> RTS_HashClient:
	var c = RTS_HashClient.new()
	c.position = pos
	c.dimensions = size
	c.group = group 
	insert(c)
	return c

#same as below but saving method call overhead by passing in the full array
func update_clients(_clients: Array[RTS_HashClient]):
	for c in _clients:
		var half : Vector2 = c.dimensions * 0.5
		var i1 :Vector2i = _get_cell_index(c.position - half)
		var i2 :Vector2i = _get_cell_index(c.position + half)
		if c._cells.min == i1 && c._cells.max == i2:
			continue
		remove(c)
		insert(c)

func update_client(c: RTS_HashClient):
	var half = c.dimensions * 0.5
	var i1 :Vector2i = _get_cell_index(c.position - half)
	var i2 :Vector2i = _get_cell_index(c.position + half)
	if c._cells.min == i1 && c._cells.max == i2:
		return
	remove(c)
	insert(c)

func has_any_client(i1: Vector2i, i2: Vector2i) -> bool:
	for x in range(i1.x, i2.x + 1):
		if x < 0 || x >= dimensions.x:
				continue
		for y in range(i1.y, i2.y + 1):
			if y < 0 || y >= dimensions.y:
				continue
			if cells[x][y] != null:
				return true
	return false

# exact = true will do exact distance check of both clients radius, using the x 
# value of _bounds and client.dimension. exact = false will fetch any clients in cell
func find_near(pos: Vector2, _bounds: Vector2, exact: bool = true, group : int = -1) -> Array[RTS_HashClient]:
	var half = _bounds * 0.5
	var i1 = _get_cell_index(pos - half)
	var i2 = _get_cell_index(pos + half)
	var near_clients : Array[RTS_HashClient] = []
	var qid = query_ids
	query_ids += 1
	for x in range(i1.x, i2.x + 1):
		if x < 0 || x >= dimensions.x:
				continue
		for y in range(i1.y, i2.y + 1):
			if y < 0 || y >= dimensions.y:
				continue
			var head : RTS_HashNode = cells[x][y]
			while head != null:
				var c : RTS_HashClient = head.client
				head = head.next
				if group > -1 && group != c.group:
					continue
				if c.query_id != qid:
					c.query_id = qid
					if exact:
						#radius check, for now use _bounds.x as radius
						var l = half.x + c.dimensions.x * 0.5
						if pos.distance_squared_to(c.position) < l*l:
							near_clients.append(c as RTS_HashClient)
					else:
						near_clients.append(c as RTS_HashClient)
						
	return near_clients

func insert(c: RTS_HashClient):
	var half = c.dimensions * 0.5
	var i1 = _get_cell_index(c.position - half)
	var i2 = _get_cell_index(c.position + half)
	var nodes = []
	for x in range(i1.x, i2.x + 1):
		var x_nodes : Array[RTS_HashNode] = []
		if x < 0 || x >= dimensions.x:
			continue
		for y in range(i1.y, i2.y + 1):
			if y < 0 || y >= dimensions.y:
				continue
			var node = RTS_HashNode.new()
			node.client = c
			node.next = cells[x][y]
			if cells[x][y]:
				cells[x][y].prev = node
			cells[x][y] = node
			x_nodes.append(node)
		nodes.append(x_nodes)
	c._cells.min = i1
	c._cells.max = i2
	c._cells.nodes = nodes
	clients[c] = true

func remove(c: RTS_HashClient):
	var i1 = c._cells.min
	var i2 = c._cells.max
	var offset_x : int =  i1.x if (i1.x >= 0) else 0 
	var offset_y : int =  i1.y if (i1.y >= 0) else 0 
	for x in range(i1.x, i2.x + 1):
		if x < 0 || x >= dimensions.x:
			continue
		for y in range(i1.y, i2.y + 1):
			if y < 0 || y >= dimensions.y:
				continue
			var xi = x - offset_x
			var yi = y - offset_y
			var node: RTS_HashNode = c._cells.nodes[xi][yi]
			if node.next:
				node.next.prev = node.prev
			if node.prev:
				node.prev.next = node.next
			if node.prev == null:
				cells[x][y] = node.next
	c._cells.min = null
	c._cells.max = null
	c._cells.nodes = null
	clients.erase(c)

#Below are further utility functions, but not required to run

const OFFSETS_8 = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0),                 Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]

#Returns Array[Array[Vector2i]] of clusters, holding cells. Each cluster is Array[Vector2i]
func flood_fill_clusters(min_units_per_cluster : int = 1, group: int = -1, filter: Dictionary[RTS_HashClient,bool] = {}) -> Array:

	#1. only consider non empty (ocuppied) cells
	var occupied: Dictionary[Vector2i,bool] = {}
	var use_filter: bool = !filter.is_empty()
	for client in clients:
		if (group > -1 && client.group != group) || (use_filter && !filter.has(client)):
			continue
		var _min = client._cells["min"]
		var _max = client._cells["max"]
		for x in range(_min.x, _max.x + 1):
			for y in range(_min.y, _max.y + 1):
				var pos = Vector2i(x, y)
				occupied[pos] = true

	#2. flood fill from occupied cells
	var visited : Dictionary = {} #visited cells
	var clusters: Array = [] #array of array of cells, the latter representing a cluster

	for cell in occupied:
		if cell in visited:
			continue
		var cluster : Array[Vector2i] = []
		var queue : Array[Vector2i] = [cell]
		while queue.size() > 0:
			var current = queue.pop_back()
			if current in visited:
				continue
			if !occupied.has(current):
				continue
			visited[current] = true
			cluster.append(current)

			for offset in OFFSETS_8:
				var neighbor = current + offset
				if !visited.has(neighbor) && occupied.has(neighbor):
					queue.append(neighbor)
		
		if cluster.size() >= min_units_per_cluster:
			clusters.append(cluster)
	return clusters
