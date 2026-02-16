class_name RTS_StunnableComponent extends RTS_Component

#Example component that "stuns" entity, essentially rendering attack/defense/movable inactive for a duration

@export var sprite: Sprite3D

var is_stunned: bool
var stun_timer: SceneTreeTimer
var stunned_position: Vector3
var pos_tween: Tween
var animation_player: AnimationPlayer

signal stunned(entity: RTS_Entity,value: bool)

func _ready():
	super._ready()
	sprite.visible = false
	animation_player = entity.anim_tree.get_node(entity.anim_tree.anim_player)

#duration: Duration of the overall stun
#anim_duration: Duration of the position tween and animation length, shorter or equal than duration
func stun(duration: float, anim_and_tween_duration: float, stun_target: Vector3 = Vector3.ZERO):
	assert(anim_and_tween_duration <= duration)
	is_stunned = true
	sprite.visible = true
	if stun_timer != null:
		stun_timer.timeout.disconnect(on_stun_timeout)
	stun_timer = get_tree().create_timer(duration)
	stun_timer.timeout.connect(on_stun_timeout)

	entity.enable_unit_collisions(false)
	#components
	if entity.attack != null:
		entity.attack.set_component_inactive()
	if entity.defense != null:
		entity.defense.set_component_inactive()
	if entity.movable != null:
		entity.movable.add_controller_override(self,5)

	#tween position
	stunned_position = entity.global_position
	if stun_target != Vector3.ZERO:
		if pos_tween != null:
			pos_tween.stop()
		pos_tween = create_tween()
		pos_tween.tween_property(self,"stunned_position",stun_target,anim_and_tween_duration)

	#Adjust anim tree timescale so that stun anim aligns perfectly with position tween	
	if entity.anim_tree && animation_player && animation_player.has_animation("stun"):
		var anim : Animation = animation_player.get_animation("stun")
		var anim_length = anim.length
		var factor : float = anim_length/ anim_and_tween_duration
		entity.anim_tree.set("parameters/TimeScale/scale", factor) #requires blend tree setup
		entity.anim_tree.tree_node_exited.connect(on_tree_node_exited)
			
	stunned.emit(entity,true)

func on_tree_node_exited(node: StringName):
	if node == "stun":
		entity.anim_tree.tree_node_exited.disconnect(on_tree_node_exited)
		entity.anim_tree.set("parameters/TimeScale/scale", 1.0)

func on_stun_anim_timeout():
	animation_player.speed_scale = 1
func on_animation_finished(_anim_name: StringName):
	animation_player.speed_scale = 1
func on_animation_changed(old_name: StringName, _new_name: StringName):
	if old_name == "stun":
		animation_player.speed_scale = 1

func on_stun_timeout():
	stun_timer = null
	sprite.visible = false
	is_stunned = false

	entity.enable_unit_collisions(true)

	if entity.attack != null:
		entity.attack.set_component_active()
	if entity.defense != null:
		entity.defense.set_component_active()
	if entity.movable != null:
		entity.movable.remove_controller_override(self)

	stunned.emit(entity,false)

func override_movable_physics_process(_delta: float, _movable: RTS_Movable):
	entity.global_position = stunned_position

func is_externally_immovable(_movable: RTS_Movable) -> bool:
	return true
