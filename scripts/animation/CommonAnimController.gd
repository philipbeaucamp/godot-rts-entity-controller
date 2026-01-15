extends AnimationTree

class_name CommonAnimController

@export var movable: Movable
@export var attack: AttackBehaviour #optional
@export var ability: Ability

signal tree_node_entered(node: String)
signal tree_node_exited(node: String)

@export_group("Idle")
@export var custom_idle_min_treshold : float = 5 #how long until a custom idle anim can be played, after IDLE state is reached
@export var custom_idle_lambda : float = 0.15 #how long until a custom idle anim can be played, after IDLE state is reached
@export var custom_idle_amount : int = 0 #how many custom idle animations exist
var is_idling : bool = true
var idle_index = 0


var playback : AnimationNodeStateMachinePlayback
var last_state : String = ""
var state: String:
	get: return playback.get_current_node()


func _ready():
	playback = self.get("parameters/playback") as AnimationNodeStateMachinePlayback
	await get_tree().create_timer(randf()*0.5).timeout
	playback.travel("idle_default")
	if attack != null:
		attack.state_machine.enter_state.connect(on_attack_enter_state)

var attack_variant_name: String:
	get: return attack.active_variant.attack_anim_name

func _process(delta):
	#Determin new state
	var current_state = playback.get_current_node()
	if current_state == "idle_default":
		if attack != null:
			if attack.state == AttackBehaviour.State.ATTACKING && movable.state == Movable.State.HOLD:
				#todo attacking while hold
				playback.travel(attack_variant_name)
			elif attack.state == AttackBehaviour.State.ATTACKING:
				playback.travel(attack_variant_name)
			elif movable.state == Movable.State.HOLD:
				playback.travel("hold")
			elif !attack.defenses_in_weapon.is_empty():
				playback.travel("enemy_in_range")
		else:
			if movable.state == Movable.State.HOLD:
				playback.travel("hold")

	elif current_state == "hold":
		if attack != null:
			if attack.state == AttackBehaviour.State.ATTACKING:
				playback.travel(attack_variant_name)
			if movable.state != Movable.State.HOLD:
				playback.travel("idle_default") #todo use offset seek ?
		else:
			if movable.state != Movable.State.HOLD:
				playback.travel("idle_default") #todo use offset seek ?
	elif current_state == "attack_default":
		if attack.state != AttackBehaviour.State.ATTACKING:
			if attack.defenses_in_weapon.is_empty():
				playback.travel("idle_default")
			else:
				playback.travel("enemy_in_range")
	elif current_state == "enemy_in_range":
		if attack.state == AttackBehaviour.State.ATTACKING:
			playback.travel(attack_variant_name)
		elif attack.defenses_in_weapon.is_empty():
			playback.travel("idle_default")

	#Handle State change callbacks
	current_state = playback.get_current_node()
	if current_state != last_state:
		on_tree_node_exited(last_state)
		on_tree_node_entered(current_state)
		last_state = current_state


func on_tree_node_entered(node: StringName):
	# Log.info_owner(self,"Entered " + node)
	tree_node_entered.emit(node)

func on_tree_node_exited(node: StringName):
	# Log.info_owner(self,"Exited " + node)
	tree_node_exited.emit(node)


#yeah yeah
func on_attack_enter_state(_sm: Node, new_state:int):
	if new_state == AttackBehaviour.State.ATTACKING:
		playback.travel("attack_default")
		
#occasionally randomly selects a custom idle animation to play
var idle_timer : SceneTreeTimer
func start_random_custom_idle_timer():
	if custom_idle_amount < 1:
		return
	var wait_time = MathUtil.inverse_exponential(custom_idle_min_treshold,custom_idle_lambda)
	idle_timer = get_tree().create_timer(wait_time)
	await idle_timer.timeout
	if idle_timer != null:
		idle_index = randi_range(1,custom_idle_amount)
