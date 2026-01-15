@tool
extends Node3D

class_name Particles3DContainer

@export var particles: Array[GPUParticles3D]

@export_tool_button("Emit All","Callable") var emit_action = restart_all
@export_tool_button("Fetch All","Callable") var fetch_action = fetch_all

var anim_player : AnimationPlayer

var max_particle_time = 0

func _ready():
	if has_node("AnimationPlayer"):
		anim_player = get_node("AnimationPlayer")
	for p in particles:
		if p.lifetime > max_particle_time:
			max_particle_time = p.lifetime

func play():
	anim_player.play("init")

func restart_all():
	for p in particles:
		p.restart()

func fetch_all():
	particles.clear()
	for child in get_children():
		if child is GPUParticles3D:
			particles.append(child)
			
func set_emit_all(value: bool):
	for p in particles:
		p.emitting = value
