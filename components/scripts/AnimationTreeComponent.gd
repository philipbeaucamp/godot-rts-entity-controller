extends AnimationTree

class_name AnimationTreeComponent

signal tree_node_entered(node: StringName)
signal tree_node_exited(node: StringName)

@export var activate_on_start : bool = true
@export var overlay_anim_player : AnimationPlayer #Optional Player to play additional anims with same name as nodes
@export var overlay_anims: Dictionary[String,String] #NodeName to Overlay Anim Name
## Names of nodes (not animations) to should randomize the anim seek point when entered
@export var randomize_start: Array[String] #todo...

var sm: AnimationNodeStateMachine
var playback : AnimationNodeStateMachinePlayback
var previous_node : String = ""
var animation_player: AnimationPlayer

func _ready():
	if tree_root == null:
		print("Warning: No tree_root set in AnimationTreeComponent on " + owner.name)
		return
		
	sm = self.tree_root.get_node("StateMachine")
	playback = self.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
	if playback == null:
		push_warning("Need to update " + owner.name  + " with blend tree")
		playback = self.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if !active && activate_on_start:
		self.active = true
	animation_player = get_node(anim_player)
		
func travel(node: String):
	playback.travel(node)

func _process(_delta):
	if playback == null:
		return
	#Handle State change callbacks
	var node : StringName = playback.get_current_node()
	var pos : float = playback.get_current_play_position()
	if node != previous_node:
		on_tree_node_exited(previous_node)
		previous_node = node
		on_tree_node_entered(node)

func test():
	var seek = randf_range(0,1.0)
	animation_player.seek(seek,true)

func on_tree_node_entered(node: String):
	# Log.info_owner(self,"Entered " + node)
	# var seek: float = -1
	if randomize_start.has(node):
		pass
		# call_deferred("test")
		# var length = animation_player.current_animation.length()
		# seek = randf_range(0,1.0)
		# animation_player.seek(seek,true)
	if overlay_anim_player != null && overlay_anims.has(node):
		var overlay_anim : String = overlay_anims[node]
		if overlay_anim_player.has_animation(overlay_anim):
			overlay_anim_player.play(overlay_anim)
			# if seek != -1:
			# 	overlay_anim_player.seek(seek,true)
		
	tree_node_entered.emit(node)

func on_tree_node_exited(node: String):
	# Log.info_owner(self,"Exited " + node)
	tree_node_exited.emit(node)
	if overlay_anim_player != null && overlay_anims.has(node):
		var overlay_anim : String = overlay_anims[node]
		if overlay_anim_player.is_playing() && overlay_anim_player.current_animation == overlay_anim:
			overlay_anim_player.stop()
