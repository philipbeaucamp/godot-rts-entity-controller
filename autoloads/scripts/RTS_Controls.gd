extends Node3D

@export var settings: RTSSettings

@export_group("Cameras")
@export var raycast_rig: RTS_RaycastRig
@export var camera: RTS_RaycastCamera

@export_group("General")
@export var selection: RTS_Selection
@export var box_selection: RTS_BoxSelection
@export var movement: RTS_Movement
@export var pool_manager: RTS_PoolManager
@export var ability_manager: RTS_AbilityManager

@export_group("RTS_SimpleUI")
@export var canvas_layer: CanvasLayer
@export var canvas_layer_health_bar_control: Control
@export var ui: RTS_SimpleUI

@export_group("Utility")
@export var geometry_utils: RTS_GeometryUtils
@export var time_utility: RTS_TimeUtility

var cam_tween: Tween
var is_enabled: bool

func _ready():
	is_enabled = !RTS_DisableQueue.has_disable_requests(self)

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
		raycast_rig.zoom_in()
	elif input["zoom_out"]:
		raycast_rig.zoom_out()



func enter_map_to_scenario_animation():
	if cam_tween:
		assert(false,"Should not get in here twice")
		return

	RTS_EventBus.scenario_enter_anim_started.emit()
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
	RTS_EventBus.scenario_enter_anim_finished.emit()

func exit_scenario_to_map_animation():
	if cam_tween:
		assert(false,"Should not get in here twice")
		return
	RTS_EventBus.scenario_exit_anim_started.emit()
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
	RTS_EventBus.scenario_exit_anim_finished.emit()

func tween_rotation(angle: float):
	var angle_rad = deg_to_rad(angle)
	var new_rotation : Vector3 = camera.rotation
	new_rotation.x = angle_rad
	camera.rotation = new_rotation

#---Events---
func on_main_menu_opening():
	pass
	#RTS_DisableQueue.add_disable_request(MainMenu,self)
func on_main_menu_closed():
	pass
	#RTS_DisableQueue.remove_disable_request(MainMenu,self)
