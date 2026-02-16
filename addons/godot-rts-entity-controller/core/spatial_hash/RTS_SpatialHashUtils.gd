class_name RTS_SpatialHashUtils

static func rank_cells_by_center_and_ratio(spatialHash: RTS_SpatialHashFast) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for x in spatialHash.dimensions.x:
		for y in spatialHash.dimensions.y:
			keys.append(Vector2i(x,y))
	var ratio : float = float(spatialHash.dimensions.x)/float(spatialHash.dimensions.y)
	var offset : Vector2 = Vector2(spatialHash.dimensions- Vector2i.ONE)/2.0
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da = pow(a.x - offset.x, 2) + pow((a.y - offset.y) * ratio, 2)
		var db = pow(b.x - offset.x, 2) + pow((b.y - offset.y) * ratio, 2)
		return da < db
	)
	return keys

static func rank_cells_by_proximity_to(spatialHash: RTS_SpatialHashFast, target_cell: Vector2i):
	var keys: Array[Vector2i] = []
	for x in spatialHash.dimensions.x:
		for y in spatialHash.dimensions.y:
			keys.append(Vector2i(x,y))
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.distance_squared_to(target_cell) <  b.distance_squared_to(target_cell)
	)
	return keys
