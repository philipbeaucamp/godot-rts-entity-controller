class_name SphereAreaProjectile extends Node3D

@export var area: Area3D
@export var damage_dealer: DamageDealer
@export var is_top_level: bool = true

var entity: Entity
var is_shooting: bool
var tween: Tween
var player_assigned_target: Defense

func _ready() -> void:
	area.area_entered.connect(on_area_entered)
	if is_top_level:
		set_as_top_level(true)

func activate(_publisher: Entity):
	entity = _publisher
	var mask: int = Controls.settings.collision_layer_enemy_defense if _publisher.faction == Entity.Faction.PLAYER else Controls.settings.collision_layer_player_defense
	if _publisher.attack.player_assigned_target_is_ally:
		area.set_collision_mask_value(Controls.settings.collision_layer_player_defense,true)	
		player_assigned_target = _publisher.attack.player_assigned_target
	else:
		player_assigned_target = null
	area.set_collision_mask_value(mask,true)
	area.monitoring = true
	
func disactivate():
	area.set_collision_mask_value(Controls.settings.collision_layer_enemy_defense,false)
	area.set_collision_mask_value(Controls.settings.collision_layer_player_defense,false)
	area.monitoring = false

func shoot_sphere(_from: Entity, _to: Vector3, _duration: float):
	if is_shooting:
		printerr("Trying to shoot again while still shooting sphere")
		return
	
	is_shooting = true
	global_position = _from.global_position
	activate(_from)
		
	tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.parallel().tween_property(self,"global_position",_to,_duration)
	if _from.is_debugged:
		tween.parallel().tween_method(debug_sphere,global_position,_to,_duration)
	await tween.finished
	
	disactivate()
	is_shooting = false
	player_assigned_target = null
	
func debug_sphere(pos: Vector3):
	if entity.is_debugged:
		var radius : float = area.get_node("CollisionShape3D").shape.radius
		##DebugDraw3D.draw_sphere(pos,radius,Color.RED)

func on_area_entered(other: Area3D):
	var other_entity: Entity = other.component.entity
	#Always allow different faction damage. if same, only if player_assigned_target
	if other_entity.faction == entity.faction && other_entity.defense != player_assigned_target:
		return
		
	var other_defense: Defense = other.component.entity.defense
	if other_defense:
		damage_dealer.deal_damage(other_defense,global_position)
		
