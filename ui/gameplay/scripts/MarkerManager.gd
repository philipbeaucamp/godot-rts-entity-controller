extends Control

class_name MarkerManager

@export var markers: Dictionary[String,Marker] = {}
var prev_active_marker: Marker
var active_marker: Marker

func _ready():
	# RTSEventBus.click_abilities_initiated.connect(on_click_abilities_initiated)
	# RTSEventBus.click_abilities_terminated.connect(on_click_ability_terminated)
	Controls.selection.hovered_pickable_set.connect(on_hovered_pickable_set)
	Controls.selection.hovered_pickable_empty.connect(on_hovered_pickable_empty)
	Controls.ability_manager.sm.state_changed.connect(on_abilities_state_changed)
	for key in markers:
		markers[key].visible = false

func _process(_delta):
	if active_marker != null:
		var mouse_pos = get_viewport().get_mouse_position()
		active_marker.global_position = mouse_pos

# func on_click_abilities_initiated(abilities: Array[ClickAbility]):
# 	var id = abilities[0].resource.id
# 	if id == "attack" || id == "patrol":
# 		markers["action"].requests_to_be_active["movement"] = true
# 	determine_active_marker()

# func on_click_ability_terminated(abilities: Array[ClickAbility],_cancelled: bool):
# 	var id = abilities[0].resource.id
# 	if id == "attack" || id == "patrol":
# 		markers["action"].requests_to_be_active.erase("movement")
# 	determine_active_marker()

func on_hovered_pickable_set(_pickable: RTS_PickablePhysicsComponent):
	markers["hover"].requests_to_be_active["pickable"] = true
	determine_active_marker()

func on_hovered_pickable_empty():
	markers["hover"].requests_to_be_active.erase("pickable")
	determine_active_marker()

func on_abilities_state_changed(_previous_state: int, new_state:int):
	if new_state == RTS_AbilityManager.State.QUEUED_CLICK_ABILITIES_VALID:
		markers["action"].requests_to_be_active["click-ability"] = true
		markers["invalid"].requests_to_be_active.erase("click-ability")
	elif new_state == RTS_AbilityManager.State.QUEUED_CLICK_ABILITIES_INVALID:
		markers["invalid"].requests_to_be_active["click-ability"] = true
		markers["action"].requests_to_be_active.erase("click-ability")
	else:
		markers["action"].requests_to_be_active.erase("click-ability")
		markers["invalid"].requests_to_be_active.erase("click-ability")
	determine_active_marker()

func determine_active_marker():
	var highest : int = -2147483648 #-INF but as min 32-bit signed int
	active_marker = null
	for key in markers:
		var marker = markers[key]
		if !marker.requests_to_be_active.keys().is_empty() && marker.priority > highest:
			highest = marker.priority
			active_marker = marker
	if prev_active_marker != null && prev_active_marker != active_marker:
		prev_active_marker.visible = false
	if active_marker != null:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		active_marker.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	prev_active_marker = active_marker
