class_name RTS_ObjectPool extends Node

#Optional Basic Object Pool implementation

@export var prefab: PackedScene
@export var prewarm_count: int = 0

var _pool: Array[ObjectPoolItem] = []

func _ready():
	for i in prewarm_count:
		var item = _create_instance()
		_pool.append(item)
		item.set_active(false)

func get_item(set_active: bool) -> ObjectPoolItem:
	for i in _pool.size():
		var item = _pool[i]
		if !item.is_active:
			if set_active:
				item.set_active(set_active)
			return item
	# If none are available, create a new one
	var new_instance = _create_instance()
	_pool.append(new_instance)
	return new_instance

func retire_item(item: ObjectPoolItem) -> void:
	item.set_active(false)

func _create_instance() -> ObjectPoolItem:
	var instance : ObjectPoolItem = prefab.instantiate()
	instance.set_active(false)
	add_child(instance)
	return instance
