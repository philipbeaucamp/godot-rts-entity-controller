extends Node3D

@export var settings: RTSSettings

@export_group("Cameras")
@export var raycast_rig: RaycastRig
@export var camera: RaycastCamera
@export var min_size : float = 7
@export var max_size : float = 19
@export var zoom_factor : float = 0.2

@export_group("General")
@export var selection: Selection
@export var box_selection: BoxSelection
@export var movement: Movement
@export var pool_manager: PoolManager
@export var ability_manager: AbilityManager

@export_group("UI")
@export var canvas_layer: CanvasLayer
@export var canvas_layer_health_bar_control: Control
@export var ui: UI

@export_group("AI")
var tactical_ai: RTS_TacticalAI

@export_group("Audio")
@export var audio_listener: AudioListener3D
@export var audio_listener_max_height = 10

@export_group("Utility")
@export var geometry_utils: RTS_GeometryUtils
@export var time_utility: RTS_TimeUtility

var cam_size : float
var cam_tween: Tween

var is_enabled: bool

func _ready():
	cam_size = camera.size
	update_audio_listener_height()

	is_enabled = !DisableQueue.has_disable_requests(self)

#---Disable Queue---
func enable():
	canvas_layer.visible = true
	is_enabled = true

func disable():
	canvas_layer.visible = false
	is_enabled = false

#---Input----
func process_input(input: Dictionary):
	if !is_enabled:
		return
	if input["zoom_in"]:
		zoom_in()
	elif input["zoom_out"]:
		zoom_out()

#---Cameras---
func zoom_in():
	var new_size = cam_size - zoom_factor
	if new_size > min_size:
		cam_size = new_size
		camera.size = new_size
		camera.rotation.x -= 0.003
		update_audio_listener_height()

func zoom_out():
	var new_size = cam_size + zoom_factor
	if new_size < max_size:
		cam_size = new_size
		camera.size = new_size
		camera.rotation.x += 0.003
		audio_listener.global_position += Vector3.UP
		update_audio_listener_height()

func enter_map_to_scenario_animation():
	if cam_tween:
		assert(false,"Should not get in here twice")
		return

	RTSEventBus.scenario_enter_anim_started.emit()
	var duration = 0.5
	cam_tween = create_tween()	
	cam_tween.set_ease(Tween.EASE_OUT)
	cam_tween.set_trans(Tween.TRANS_EXPO)
	cam_tween.set_ignore_time_scale(true)
	camera.position.x = 0
	camera.position.z = 0
	cam_tween.parallel().tween_property(camera,"position",camera.default_position,duration)
	cam_tween.parallel().tween_method(tween_rotation,-90.0,-45.0,duration)
	await cam_tween.finished
	cam_tween = null
	RTSEventBus.scenario_enter_anim_finished.emit()

func exit_scenario_to_map_animation():
	if cam_tween:
		assert(false,"Should not get in here twice")
		return
	RTSEventBus.scenario_exit_anim_started.emit()
	var duration = 0.5
	cam_tween = create_tween()	
	cam_tween.set_ease(Tween.EASE_IN)
	cam_tween.set_trans(Tween.TRANS_EXPO)
	cam_tween.set_ignore_time_scale(true)
	var target_pos : Vector3 = camera.default_position
	target_pos.x = 0
	target_pos.z = 0
	cam_tween.parallel().tween_property(camera,"position",target_pos,duration)
	cam_tween.parallel().tween_method(tween_rotation,-45.0,-90.0,duration)
	await cam_tween.finished
	cam_tween = null
	RTSEventBus.scenario_exit_anim_finished.emit()

func tween_rotation(angle: float):
	var angle_rad = deg_to_rad(angle)
	var new_rotation : Vector3 = camera.rotation
	new_rotation.x = angle_rad
	camera.rotation = new_rotation

#---Audio---
func update_audio_listener_height():
	#Audiolistener should be on floor (y == 0) when fully zoomed in:
	var zoom_percentage : float = (camera.size - min_size) / (max_size - min_size)
	var height = lerp(0,audio_listener_max_height,zoom_percentage)
	var pos = audio_listener.global_position
	audio_listener.global_position = Vector3(pos.x,height,pos.z)
	assert(audio_listener.global_position.y >= 0,"Don't want listener to be underground")

#---Events---
func on_main_menu_opening():
	pass
	#DisableQueue.add_disable_request(MainMenu,self)
func on_main_menu_closed():
	pass
	#DisableQueue.remove_disable_request(MainMenu,self)
