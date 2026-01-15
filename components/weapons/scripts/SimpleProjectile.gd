extends Node3D

## Simple lerp between "from" to targets position
class_name SimpleProjectile 

var target: Defense
var target_pos: Vector3
var offset: Vector3 # random offset to target.global_position

signal impact(projectile: SimpleProjectile, hit:bool)

@export var speed : float = 1
@export var use_exact_target_pos: bool = false
@export var face_velocity: bool = false #todo
# @export var damage: Array[DamageDealer]
@export var vfxs: Particles3DContainer
@export var hide_on_impact: Array[Node3D]

@export var y_curve: Curve 
@export var x_curve: Curve

var value: float = 0 # tween from 0 to 1

var init_position: Vector3

# func start(from: Vector3, _target: Defense,_damage: Array[DamageDealer]):
func start(from: Vector3, _target: Defense):
	global_position = from
	init_position = from
	target = _target
	target.add_to_incoming_projectiles(self)
	if use_exact_target_pos:
		target_pos = _target.entity.position
	else:
		var collision_shape = target.area.get_node("CollisionShape3D") as CollisionShape3D
		target_pos = + Vector3.UP * 0.5 + GeometryUtils.random_front_facing_global_point_on_shape(collision_shape,from)

	look_at(target_pos)

	#TWEEN-------
	var distance = global_position.distance_to(target_pos)
	var duration = distance/speed
	var tween: Tween = create_tween()
	tween.tween_property(self,"value",1.0,duration)
	await tween.finished
	#--------------

	finish()

func finish():
	if target && target.incoming_projectiles.has(self):
		#projectile could have been removed due to abilities or other circumstances
		target.remove_from_incoming_projectiles(self)
		impact.emit(self,true)
	else:
		impact.emit(self,false)
		

	#Turn project invisible and wait for queue_free until all particles have played
	for h in hide_on_impact:
		h.visible = false
	vfxs.set_emit_all(false)
	await get_tree().create_timer(vfxs.max_particle_time).timeout
	queue_free()


#lerps from initial position to target position.
#optionally uses y and x curves for some variation
func _process(_delta: float):
	var lerped: Vector3 = init_position.lerp(target_pos,value)
	if y_curve != null:
		lerped.y += y_curve.sample(value)

	if x_curve != null:
		lerped.x += x_curve.sample(value)

	if face_velocity:
		var direction = (lerped - global_position).normalized()
		transform.basis = Basis.looking_at(direction,Vector3.UP)
		
	global_position = lerped
		
