class_name RTS_PoolManager extends Node

func get_pool(pool: String) -> RTS_ObjectPool:
	return find_child(pool) as RTS_ObjectPool
