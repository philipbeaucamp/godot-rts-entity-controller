class_name RTS_AbilityManager extends Node

#Future improvements:
#c) Refactor this class using typed variables
#d) 10/4/2025 : next should be calculated here, not in cAbility
#e) 10/4/2025: this code will probably bug if two different abilities use same ability resource, which ideally it shouldnt

@export var movement: RTS_Movement
@export var selection : RTS_Selection
var highest_group: Array[RTS_Selectable] 
var selected_abilities : Dictionary[StringName,Array] = {} #Array[RTS_Ability]
var sm: RTS_EnumStateMachine = RTS_EnumStateMachine.new()

var initiated_resource : ClickAbilityResource #can be activated and in cooldown, but representing the "initiated" group of same click ability type
var initiated_abilities : Array[RTS_ClickAbility]
var is_shifting_click_ability: bool = false

signal abilities_changed()
signal abilities_activated(abilities: Array)

enum State {
	NO_ACTIVE_ABILITIES,
	ACTIVE_ABILITIES,
	QUEUED_CLICK_ABILITIES_INVALID,
	QUEUED_CLICK_ABILITIES_VALID
}

func _ready():
	selection.selection_changed.connect(on_selection_changed)
	sm.change_state(State.NO_ACTIVE_ABILITIES)

func _exit_tree():
	if selection != null:
		selection.selection_changed.disconnect(on_selection_changed)

func process_input(input: Dictionary) -> bool:
	#do not process further input when click selected_abilities are queued
	if initiated_resource:
		return process_initiated_click_abilities(input)
	else:
		process_abilities(input)
		return false
	
func process_abilities(input: Dictionary):
	var keys = selected_abilities.keys()
	
	#todo improve this check
	for key in keys:
		var abilities = selected_abilities[key]
		for ability in abilities:
			if !is_instance_valid(ability):
				printerr("Not valid ability found...")
				
	if keys.is_empty():
		sm.change_state(State.NO_ACTIVE_ABILITIES)
	else:
		sm.change_state(State.ACTIVE_ABILITIES)
	for key in keys:
		if Input.is_action_just_pressed(key):
			var abilities = selected_abilities[key]
			if initiated_resource != null:
				printerr("Investigate why initiated_resource are not empty")
				clear_queued_click_abilities(true)
			if abilities.is_empty():
				continue

			if abilities[0] is RTS_ClickAbility:
				initiated_abilities.clear()
				for ability in abilities:
					if ability.can_be_activated():
						ability.initiated()
						initiated_abilities.append(ability)
				if !initiated_abilities.is_empty():
					initiated_resource = initiated_abilities[0].click_resource
					RTS_EventBus.click_abilities_initiated.emit(initiated_abilities) #currently in cooldown abilities can be initiated further below
			else:
				#Activate normal abilites immediately
				activate(abilities,input)


func activate(abilities: Array, input: Dictionary) -> Dictionary:
		var to_activate : Array[RTS_Ability] = []
		var to_activate_delayed: Array[RTS_Ability] = []
		var consumed = false
		for ability in abilities:
			if ability.can_be_activated():
				var do_break = false
				if !ability.resource.allow_trigger_multiple:
					do_break = true
					var valid_abilities_in_group = abilities.filter(func(a): return a.can_be_activated())
					ability = ability.get_preferred_ability_to_activate(valid_abilities_in_group)

				ability.set_context(input)
				var movable = ability.entity.movable
				if ability.resource.is_chainable && input["shift_is_pressed"] && movable != null && !movable.targets.is_empty():
					#activate when arriving at next move target
					to_activate_delayed.append(ability)
				else: #activate now
					to_activate.append(ability)
					var click_ability = ability as RTS_ClickAbility
					if click_ability && !click_ability.dont_clear_targets_on_activate && click_ability.entity.movable:
						#remove any move targets since casting should immediately be prioritized
						click_ability.entity.movable.stop()
				consumed = true
				if do_break:
					break
		coordinate_activation(to_activate)
		activate_abilities_on_next_target_reached(to_activate_delayed)
		return {
			"consumed" : consumed,
			"to_activate_delayed": to_activate_delayed
		}

#Escape: Cancel (todo)
#Right Mouse: Cancel
#Left Mouse: Activate
func process_initiated_click_abilities(input: Dictionary) -> bool:
	var consumed = false

	#determine marker (valid or not)
	if !selected_abilities.has(initiated_resource.id):
		initiated_resource = null
		print("INIT RESOURCE NULL")
		return consumed
	
	var all_abilities : Array[RTS_ClickAbility] = []
	assert(initiated_resource,"How come this can be null???")
	all_abilities.assign(selected_abilities[initiated_resource.id]) 
	#Initiate other abilities that are now initiatable
	for ability in all_abilities:
		if !ability.is_initiated && ability.can_be_activated():
			ability.initiated()
			initiated_abilities.append(ability)
			RTS_EventBus.click_abilities_initiated.emit([ability])
	
	var rep : RTS_ClickAbility = initiated_abilities[0] #all selected_abilities have to be of same type anyway
	assert(rep,"Rep is null")
	assert(is_instance_valid(rep),"Rep is not valid instance")
	if !rep || !is_instance_valid(rep):
		initiated_resource = null
		return consumed
	
	var world_pos : Vector3 = movement.get_current_mouse_world_pos()
	var source : RTS_Entity = null
	if selection.hovered_pickable != null:
		source = selection.hovered_pickable.entity
		world_pos = source.global_position
	
	#TODO MAMI FOUND BUG
	if rep.is_valid_target(world_pos, source): #big todo. how will this work with ranges?
	#i.e. onyl the reps range is checked, but another unit might be closer to target...
		sm.change_state(State.QUEUED_CLICK_ABILITIES_VALID)
	else:
		sm.change_state(State.QUEUED_CLICK_ABILITIES_INVALID)
	
	if input["mouse_left_just_pressed"] && sm.current_state == State.QUEUED_CLICK_ABILITIES_VALID:
		input["click_target"] = world_pos
		input["click_target_source"] = source

		var rst = activate(initiated_abilities,input)
		consumed = rst["consumed"]
		var to_activate_delayed : Array[RTS_Ability] = rst["to_activate_delayed"]
		if !to_activate_delayed.is_empty():
			#add an additional move target todo should be a new Move Type: ABILITY
			var group_id = RTS_Movement.generate_session_uid()
			for click_ability in to_activate_delayed:
				click_ability.entity.movable.append_to_targets([RTS_Target.new(world_pos,RTS_Movable.Type.MOVE,source,group_id)])

		if input["shift_is_pressed"]: #keep queue if shift pressed
			is_shifting_click_ability = true
		else:
			clear_queued_click_abilities(false)
					
	elif Input.is_action_just_pressed("mouse_right") || input["escape_just_pressed"]:
		clear_queued_click_abilities(true)
		consumed = true

	if is_shifting_click_ability && input["shift_just_released"]:
		clear_queued_click_abilities(true)
	
	return consumed

#abiltiies are always of same type!!
func coordinate_activation(abilities: Array):
	var valid: Array
	for ability in abilities:
		if ability.can_be_activated(): #need to recheck since this could have been called deferred in process_initiated_click_abilities
			valid.append(ability)
	if valid.is_empty():
		return
	if valid.size() > 1 && valid[0].resource.activate_as_group:
		valid[0].activate_group(valid)
	else:
		for ability in valid:
			ability.activate()
	abilities_activated.emit(valid) #can lead to soft activation in case of click_ability

func activate_abilities_on_next_target_reached(abilities: Array):
	for ability in abilities:
		#important: pass ability inside and array (args) of array (selected_abilities), since coordinate_activation expects an array
		# ability.entity.movable.add_callable_to_last_target(coordinate_activation,[[ability]])
		ability.entity.movable.add_callable_to_last_target(on_target_reached,ability.resource.id,[[ability]])

#for now use call deferred but google when you have internet, if this is a good approach
#or if you sohuld manually call the abilites at the end of process of this node
var deferred_abilities: Array
func on_target_reached(abilities: Array):
	var first = deferred_abilities.size() == 0
	deferred_abilities.append_array(abilities)
	if first:
		call_deferred("consume_abilities_deferred")

func consume_abilities_deferred():
	print("Activating " + str(deferred_abilities.size()) + " deferred selected_abilities")
	#group in case deferred_abilities have different types
	var group : Dictionary = {}
	for d in deferred_abilities:
		var id : StringName = d.resource.id
		if !group.has(id):
			group[id] = []
		group[id].append(d)

	for key in group.keys():
		var abilities = group[key]
		coordinate_activation(abilities) #invoked together so abilties this frame can be activated as group
	deferred_abilities.clear()

func clear_queued_click_abilities(cancelled: bool):
	for ability in initiated_abilities:
		ability.terminated(cancelled)
	RTS_EventBus.click_abilities_terminated.emit(initiated_abilities,cancelled)
	initiated_resource = null
	initiated_abilities.clear()

#build selected_abilities
func on_selection_changed(selectables: Array[RTS_Selectable]):
	selected_abilities.clear()
	var settings = RTS_Controls.settings

	if !settings.use_highest_entity_for_ability_selection:
		for s in selectables:
			var e : RTS_Entity = s.entity
			if !RTS_Controls.settings.allow_enemy_entity_control && e.faction != RTS_Entity.Faction.PLAYER:
				continue
			var abilities: Array[RTS_Ability] = e.abilities_array
			var id = s.entity.resource.id
			for ability in abilities:
				if !ability.component_is_active:
					continue
				var ability_id : StringName = ability.resource.id
				if !selected_abilities.has(ability_id):
					selected_abilities[ability_id] = []
				selected_abilities[ability_id].append(ability)
			
	else:
	#ALTERNATIVE: ONLY USING HIGHEST SELECTABLES's ABILITIES (or commons ones)
	#This is similar to how SC2 RTS_Ability selection works
		var highest_entity = RTS_Controls.selection.highest
		if highest_entity != null: #can be null if no player selectables are selected
			var highest_id : StringName = highest_entity.resource.id
			for s in selectables:
				var e : RTS_Entity = s.entity
				if !settings.allow_enemy_entity_control && e.faction != RTS_Entity.Faction.PLAYER:
					continue
				var abilities: Array[RTS_Ability] = e.abilities_array
				var id = s.entity.resource.id
				for ability in abilities:
					if !ability.component_is_active:
						continue
					if id == highest_id || ability.resource.is_common || ability.ability_container:
						var ability_id : StringName = ability.resource.id
						if !selected_abilities.has(ability_id):
							selected_abilities[ability_id] = []
						selected_abilities[ability_id].append(ability)

	abilities_changed.emit()

func refresh():
	on_selection_changed(RTS_Controls.selection.selection)
