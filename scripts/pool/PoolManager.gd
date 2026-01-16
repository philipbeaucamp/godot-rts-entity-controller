extends Node

class_name RTS_PoolManager

func get_pool(pool: String) -> ObjectPool:
	return find_child(pool) as ObjectPool
