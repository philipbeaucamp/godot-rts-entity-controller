extends ObjectPoolItem

class_name NonPhysicalProjectile 

var target: Vector3 #consider live update?
var target_defense: Defense
var target_to_defense_offset: Vector3

@export var speed : float = 1
@export var is_homing: bool = false
@export var damage: DamageDealer
@export var trigger_distance_to_target = 0.1

@export_group("Curves")
@export var y_curve: Curve 
@export var x_curve: Curve

@export_group("VFX")
@export var projectile_vfx: Array[VfxLifecycle] #optional, todo find more elgant solution
@export var impact_vfx : Particles3DContainer

@export_group("Physics")
@export var shield_collider: Area3D #optional. If missing, cannot be caught by shields

@export_group("AoE")
@export var area_of_effect: Area3D
@export var peripheral_dmg: DamageDealer

var has_hit = false
var global_position_spawn: Vector3
var flat_travelled: float
func hit():
	has_hit = true
	if area_of_effect:
		hit_aoe()
	elif target_defense != null:
		#projectile could have been removed due to abilities or other circumstances
		if target_defense.incoming_projectiles.has(self):
			target_defense.get_attacked_by(damage)
			target_defense.remove_from_incoming_projectiles(self)

	retire_with_impact_vfx()

func hit_aoe():
	var overlaps = area_of_effect.get_overlapping_areas()
	var radius = (area_of_effect.get_child(0) as CollisionShape3D).shape.radius
	for overlap in overlaps:
		var other_defense = overlap.component as Defense
		var distance = global_position.distance_to(other_defense.entity.global_position)
		var aoe_dmg = damage
		if distance >= radius/2.0:
			aoe_dmg = peripheral_dmg
		other_defense.get_attacked_by(aoe_dmg)
		other_defense.remove_from_incoming_projectiles(self)
		

func retire_with_impact_vfx():
	if impact_vfx != null:
		set_projectile_vfx(false)
		impact_vfx.restart_all()
		await get_tree().create_timer(impact_vfx.max_particle_time).timeout
		retire()
	else:
		retire()


func retire():
	set_active(false)

func set_projectile_vfx(value: bool):
	for vfx in projectile_vfx:
		vfx.set_active(value)

func set_active(value: bool):
	super.set_active(value)
	set_projectile_vfx(value)
	has_hit = !value
	if value:
		global_position_spawn = global_position
		flat_travelled = 0
	if shield_collider != null:
		if value:
			shield_collider.area_entered.connect(on_shield_entered)
		else:
			shield_collider.area_entered.disconnect(on_shield_entered)

func set_up(publisher: Entity, spawn_position: Vector3, _target_defense: Defense):
	damage.publisher = publisher
	if peripheral_dmg != null:
		peripheral_dmg.publisher = publisher
	target_defense = _target_defense
	global_position = spawn_position
	_target_defense.add_to_incoming_projectiles(self)
	var collision_shape = _target_defense.area.get_node("CollisionShape3D") as CollisionShape3D
	target = GeometryUtils.random_front_facing_global_point_on_shape(collision_shape,spawn_position)
	target_to_defense_offset = target - _target_defense.entity.global_position

func _process(delta):
	if has_hit || !is_active:
		return
	if is_homing && target_defense != null:
		target = target_defense.entity.global_position + target_to_defense_offset

	var flat_init = Vector2(global_position_spawn.x, global_position_spawn.z)
	var flat_target = Vector2(target.x, target.z)
	var direction = (target - global_position).normalized()

	# var percent = distance_travelled/length
	var length = flat_init.distance_to(flat_target) 
	var percent = flat_travelled/length
	if percent > 1:
		# printerr("percent" + str(percent))
		hit()
		return

	var seek = direction * speed * delta
	var next_global_position = global_position + seek
	flat_travelled += seek.length()

	if y_curve != null:
		var base_height = global_position_spawn.lerp(target,percent).y
		var sample_height = y_curve.sample(percent)
		next_global_position.y = base_height + sample_height

	if x_curve != null:
		var base_x = global_position_spawn.lerp(target,percent).x
		var sample_x = x_curve.sample(percent)
		next_global_position.x = base_x + sample_x

	look_at(next_global_position)
	global_position = next_global_position

	if global_position.distance_squared_to(target) < trigger_distance_to_target*trigger_distance_to_target:
		hit()

func on_shield_entered(_area: Area3D):
	#for now simply retire, no distinction between area
	has_hit = true
	retire_with_impact_vfx()
