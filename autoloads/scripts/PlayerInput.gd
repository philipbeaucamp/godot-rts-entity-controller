extends Node

var double_click_timer : SceneTreeTimer = null
var double_click_count := 0
var double_click_key : Dictionary[String,SceneTreeTimer] = {}
var first_click_pickable: PickablePhysics
var last_press_was_double_click = false
var last_pressed_hotkey: String

static var hotkeys : Array[StringName] = ["rts_1","rts_2","rts_3","rts_4","rts_5","rts_6","rts_7","rts_8","rts_9"]
static var hotkeys_double : Array[StringName] = ["1d","2d","3d","4d","5d","6d","7d","8d","9d"]

func _ready():
	for hotkey in hotkeys:
		double_click_key.set(hotkey,null)

func on_double_click_timer_timeout():
	double_click_timer = null
	double_click_count = 0
	first_click_pickable = null
	
func _process(_delta):
	#--- COLLECTION OF INPUT---
	var input : Dictionary[StringName,Variant] = {}

	input["shift_just_released"] = Input.is_action_just_released("rts_shift")
	input["shift_is_pressed"] = Input.is_action_pressed("rts_shift")
	input["control_is_pressed"] = Input.is_action_pressed("rts_control")
	input["escape_just_pressed"] = Input.is_action_just_pressed("rts_escape")
	input["patrol_just_pressed"] = Input.is_action_just_pressed("rts_patrol")
	input["attack_just_pressed"] = Input.is_action_just_pressed("rts_attack")

	input["zoom_in"] = Input.is_action_just_pressed("rts_zoom_in")
	input["zoom_out"] = Input.is_action_just_pressed("rts_zoom_out")
	var mouse_left_just_pressed = Input.is_action_just_pressed("rts_mouse_left")
	var mouse_left_just_released = Input.is_action_just_released("rts_mouse_left")
	input["mouse_left_just_pressed"] = mouse_left_just_pressed
	input["mouse_left_just_released"] = mouse_left_just_released
	input["mouse_left_double_click_just_pressed"] = false
	var mouse_left_double_released = mouse_left_just_released && last_press_was_double_click
	input["mouse_left_double_click_just_released"] = mouse_left_double_released
	if mouse_left_double_released:
		last_press_was_double_click = false
	if mouse_left_just_pressed:
		double_click_count += 1
		if double_click_count == 1:
			double_click_timer = get_tree().create_timer(Controls.settings.double_click_time)
			double_click_timer.timeout.connect(on_double_click_timer_timeout)	
		elif double_click_count == 2:
			input["mouse_left_double_click_just_pressed"] = true
			input["first_click_pickable"] = first_click_pickable
			last_press_was_double_click = true
			double_click_timer = null
			double_click_count = 0
			first_click_pickable = null

	input["mouse_right_just_pressed"] = Input.is_action_just_pressed("rts_mouse_right")
	input["mouse_right_just_released"] = Input.is_action_just_released("rts_mouse_right")


	input["hold_is_just_pressed"] = Input.is_action_just_pressed("rts_hold")
	input["stop_is_just_pressed"] = Input.is_action_just_pressed("rts_stop")
	input["mouse_click_is_consumed"] = false
	input["debug_just_pressed"] = Input.is_action_just_pressed("rts_debug")

	for i in range(9):
		var hotkey = hotkeys[i]
		var pressed = Input.is_action_just_pressed(hotkey)
		input.set(hotkey,pressed)
		if pressed:
			var timer = double_click_key[hotkey]
			if timer != null && timer.time_left > 0 && last_pressed_hotkey == hotkey:
				#double click
				input.set(hotkeys_double[i],true)
				double_click_key[hotkey] = null
			else:
				input.set(hotkeys_double[i],false)
				timer = get_tree().create_timer(Controls.settings.double_click_time)
				double_click_key.set(hotkey,timer)
			last_pressed_hotkey = hotkey
		else:
			input.set(hotkeys_double[i],false)



	#---DISTRIBUTION OF INPUT---
	#Controls (Camera)
	if Controls && Controls.is_enabled:
		Controls.process_input(input)
		
		#Abilities
		if Controls.ability_manager:
			if Controls.ability_manager.process_input(input):
				input["mouse_click_is_consumed"] = true

		#RTS_Selection
		if Controls.selection:
			Controls.selection.process_input(input)
			if input.has("first_click_pickable"):
				first_click_pickable = input["first_click_pickable"]
