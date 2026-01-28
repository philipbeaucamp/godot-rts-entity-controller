class_name RTS_Selection extends Node3D

@export var box_selection : RTS_BoxSelection
@export var movement: RTS_Movement
@export var physics_selection : RTS_PhysicsSelection

var hovered_pickable: RTS_PickablePhysicsComponent
var selection : Array[RTS_Selectable] = []
var hovered : Dictionary[RTS_Selectable,bool] = {}
var hotkey_groups : Dictionary #KEY (int) -> Array[RTS_Selectable]
var selectables_on_screen : Dictionary[RTS_Selectable,bool] = {}

var highest: RTS_Entity

signal selection_changed(selection: Array[RTS_Selectable])
signal added_to_selection(selection: Array[RTS_Selectable])
signal removed_from_selection(selection: Array[RTS_Selectable])
signal hovered_pickable_set(pickable: RTS_PickablePhysicsComponent)
signal hovered_pickable_unset(pickable: RTS_PickablePhysicsComponent)
signal hovered_pickable_empty()
signal highest_selected_changed(entity: RTS_Entity)

func _ready():
	RTS_Controls.time_utility.paused.connect(on_paused)
	RTS_Controls.time_utility.unpaused.connect(on_unpaused)
	RTS_EventBus.entity_exiting_tree.connect(on_entity_exiting_tree)

func process_input(input: Dictionary):
	if input["debug_just_pressed"]:
		toggle_debug()
		
	if !input["mouse_click_is_consumed"]:
		if input["mouse_left_double_click_just_pressed"]:
			if hovered_pickable != null && (hovered_pickable == input["first_click_pickable"] || input["control_is_pressed"]):
				select_all_similar_on_screen(hovered_pickable.selectable,!input["shift_is_pressed"])
			else:
				box_selection.start_dragging()
		elif input["mouse_left_just_pressed"]:
			#save hovered pickable for double click check later
			if hovered_pickable != null:
				input["first_click_pickable"] = hovered_pickable
			#if ctrl+click (down) on physics pickable, don't do box selection
			if input["control_is_pressed"] && hovered_pickable != null:
				select_all_similar_on_screen(hovered_pickable.selectable,!input["shift_is_pressed"])
			# elif !input["mouse_left_double_click_just_pressed"]:
			else: 
				box_selection.start_dragging()
		elif input["mouse_left_just_released"]:
			box_selection.finish_dragging(!input["shift_is_pressed"])
			
	#HotkeySelection
	for i in range(9):
		var hotkey = RTS_PlayerInput.hotkeys[i]
		if input[hotkey]:
			if input["shift_is_pressed"]:
				add_to_hotkey_group(hotkey.to_int())
			elif input["control_is_pressed"]:
				create_hotkey_group(hotkey.to_int())
			else:
				select_hotkey_group(hotkey.to_int())	
		if input[RTS_PlayerInput.hotkeys_double[i]]:
			jump_to_hotkey_group(hotkey.to_int())

func add_to_selectables_on_screen(selectable: RTS_Selectable):
	if !selectables_on_screen.has(selectable):
		selectables_on_screen[selectable] = true
		if selectable.boxable != null:
			box_selection.add_to_eligible_boxable(selectable.boxable)

func remove_from_selectables_on_screen(selectable: RTS_Selectable):
	if selectables_on_screen.has(selectable):
		selectables_on_screen.erase(selectable)
		if selectable.boxable != null:
			box_selection.remove_from_eligible_boxable(selectable.boxable)

func create_hotkey_group(key: int):
	hotkey_groups[key] = selection.duplicate()
	RTS_EventBus.update_control_group.emit(key,hotkey_groups[key],self)

func add_to_hotkey_group(key: int):
	if !hotkey_groups.has(key):
		create_hotkey_group(key)
		return
	var group = hotkey_groups[key]
	var copies = selection.duplicate()
	for c in copies:
		if !group.has(c):
			group.append(c)
	RTS_EventBus.update_control_group.emit(key,hotkey_groups[key],self)

func select_hotkey_group(key:int):
	if !hotkey_groups.has(key):
		return

	var group = hotkey_groups[key]
	var old_selection = selection
	var new_selection = group.duplicate()

	#Create sets for fast comparison
	var old_set := {}
	var new_set := {}
	for s in old_selection:
		old_set[s] = true
	for s in new_selection:
		new_set[s] = true

	#Units removed from selection
	var removed : Array[RTS_Selectable] = []
	for s in old_selection:
		if !new_set.has(s):
			s.on_deselected()
			removed.append(s)
	
	#Units added to selection
	var added : Array[RTS_Selectable] = []
	for s in new_selection:
		if !old_set.has(s):
			s.on_selected()
			added.append(s)

	#update selection
	selection = new_selection
	update_highest_selected()

	#Emit events:
	if !removed.is_empty():
		removed_from_selection.emit(removed)
	if !added.is_empty():
		added_to_selection.emit(added)
	if !removed.is_empty() || !added.is_empty():
		selection_changed.emit(selection)

	RTS_EventBus.select_control_group.emit(key,hotkey_groups[key])

func jump_to_hotkey_group(key: int) -> void:
	if !hotkey_groups.has(key):
		return
	var group = hotkey_groups[key]
	var rig_position = RTS_Controls.raycast_rig.position
	var highest_entities: Array[RTS_Entity] = []
	for selectable in group:
		if selectable.entity.resource.id != highest.resource.id:
			continue
		highest_entities.append(selectable.entity)
	var closest_distance_squared : float = INF
	var closest_entity: RTS_Entity
	for entity in highest_entities:
		var d = rig_position.distance_squared_to(entity.global_position)
		if d < closest_distance_squared:
			closest_distance_squared = d
			closest_entity = entity
	RTS_Controls.raycast_rig.teleport_to(closest_entity.global_position)
	

func add_to_selection_bulk(selectables: Array[RTS_Selectable]):
	var added : Array[RTS_Selectable] = []
	var current_set := {}
	for s in selection:
		current_set[s] = true

	for selectable in selectables:
		if !current_set.has(selectable):
			selection.append(selectable)
			selectable.on_selected()
			added.append(selectable)

	if !added.is_empty():
		update_highest_selected()
		added_to_selection.emit(added)
		selection_changed.emit(selection)

func remove_from_selection(selectable: RTS_Selectable):
	var index := selection.find(selectable)
	if index != -1:
		selection.remove_at(index)
		selectable.on_deselected()
		update_highest_selected()
		removed_from_selection.emit([selectable] as Array[RTS_Selectable])
		selection_changed.emit(selection)

func remove_from_selection_bulk(selectables: Array[RTS_Selectable]):
	if selection.is_empty():
		return

	var old_set := {}
	for s in selection:
		old_set[s] = true
	
	var removed : Array[RTS_Selectable] = []
	for s in selectables:
		if old_set.has(s):
			removed.append(s)
			old_set.erase(s)
			s.on_deselected()

	if removed.is_empty():
		return

	var remaining: Array[RTS_Selectable] = []
	for key in old_set.keys():
		remaining.append(key)

	selection = remaining
	update_highest_selected()
	removed_from_selection.emit(removed)
	selection_changed.emit(selection)

func remove_all_selection():
	if selection.is_empty():
		return

	var removed := selection.duplicate()
	for s in removed:
		s.on_deselected()

	selection.clear()
	update_highest_selected()
	removed_from_selection.emit(removed)
	selection_changed.emit([] as Array[RTS_Selectable])

func add_to_hovered(selectable: RTS_Selectable):
	if !hovered.has(selectable):
		hovered[selectable] = true
		selectable.on_hovered()

func remove_from_hovered(selectable: RTS_Selectable):
	if hovered.has(selectable):
		hovered.erase(selectable)
		selectable.on_unhovered()

func remove_all_hovered():
	for h in hovered:
		h.on_unhovered()
	hovered.clear()

# only allow one hovered pickable
func set_hovered_pickable(pickable: RTS_PickablePhysicsComponent):
	if hovered_pickable == pickable:
		return
	if hovered_pickable != null:
		hovered_pickable.selectable.on_unhovered()
		hovered_pickable_unset.emit(hovered_pickable)
	hovered_pickable = pickable
	#only call hover when not already hovered
	if !hovered.has(pickable.selectable):
		pickable.selectable.on_hovered()
	hovered_pickable_set.emit(pickable)

func unset_hovered_pickable(pickable: RTS_PickablePhysicsComponent):
	if hovered_pickable != null :
		if hovered_pickable == pickable:
			hovered_pickable = null
			#only unhover when not hovered by box
			if !hovered.has(pickable.selectable):
				pickable.selectable.on_unhovered()
			hovered_pickable_unset.emit(pickable)
			hovered_pickable_empty.emit()
		else:
			printerr("RTS: Trying to unset hovered pickable that is not currently set!")

func get_all_similar_from_current_selection(selectable: RTS_Selectable) -> Array[RTS_Selectable]:
	var similar : Array[RTS_Selectable] = []
	for s in selection:
		if s.is_same_type_and_faction(selectable):
			similar.append(s)
	return similar

func select_all_similar_on_screen(selectable: RTS_Selectable,clear_previous_selection = true):
	var similar : Array[RTS_Selectable] = []
	for s in selectables_on_screen:
		if s.is_same_type_and_faction(selectable):
			similar.append(s)
	if clear_previous_selection:
		remove_all_selection()
	add_to_selection_bulk(similar)

#called when mouse button is lifted
func finalize_hovered_selection(clear_previous_selection = true):
	var to_select = hovered.keys()
	if hovered_pickable != null && !hovered.has(hovered_pickable.selectable):
		to_select.append(hovered_pickable.selectable)

	if !to_select.is_empty():
		if clear_previous_selection:
			remove_all_selection()
		add_to_selection_bulk(to_select)

	remove_all_hovered()
	physics_selection.clear_previous_pickable() #set unhovered in here


func update_highest_selected() -> void:
	if selection.is_empty():
		highest = null
		return
	var highest_priority = -INF
	var highest_selectable : RTS_Selectable = null
	for s in selection:
		if !RTS_Controls.settings.allow_enemy_entity_control && s.entity.faction != RTS_Entity.Faction.PLAYER:
			continue
		if s.priority > highest_priority:
			highest_priority = s.priority
			highest_selectable = s
	if highest_selectable != null:
		highest = highest_selectable.entity

	highest_selected_changed.emit(highest)

func on_paused():
	box_selection.finish_dragging()

func on_unpaused():
	pass

#todo: to clean up due to hotkeys creating duplications of original selectables
#also need to emit selection changed if part of current selection, which will
#refresh highest and ability manager etc
func on_entity_exiting_tree(entity: RTS_Entity):
	var selectable = entity.selectable
	if selectable == null:
		return
	if hovered.has(selectable):
		hovered.erase(selectable)
	if selectables_on_screen.has(selectable):
		selectables_on_screen.erase(selectable)

	#Hotkey
	for key in hotkey_groups:
		var group = hotkey_groups[key]
		if group.has(selectable):
			group.erase(selectable)
			RTS_EventBus.update_control_group.emit(key,group,self)
	#RTS_Selection
	remove_from_selection(selectable)

#debugging
func toggle_debug():
	for s in selection:
		(s.owner as RTS_Entity).toggle_entity_debug()
