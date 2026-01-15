extends Node

class_name AttackProjectile

@export var pool : String
@export var spawn_point: Node3D

@export var attack: AttackBehaviour

var object_pool: ObjectPool

func _ready():
	object_pool = Controls.pool_manager.get_pool(pool)

func spawn():
	if attack.current_target != null:
		var projectile = object_pool.get_item(false) as NonPhysicalProjectile
		projectile.set_up(attack.entity, spawn_point.global_position,attack.current_target)
		projectile.set_active(true)
		
