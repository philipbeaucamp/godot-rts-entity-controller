class_name RTS_AttackComponent extends RTS_Component

#Handles logic for automatic targeting and attack states, using Scan and RTS_Weapon Area
#a)Requires an RTS_AttackVariant to implement explicit state logic (like RTS_DefaultAttackVariant)
#This is done so that AttackVariants can easily be swapped out to create different attack behaviours,
#while keeping the core attack component logic (such as keeping track of targets within scan/weapon range)
#and handling changing of targets etc, the same.
#b)Requires a RTS_Weapon to handle damage dealing


#reference https://liquipedia.net/starcraft2/Automatic_Targeting
#reference https://liquipedia.net/starcraft2/Category:Game_Mechanic

@export var always_threat_to_attacker : bool = false
@export var variant_to_activate_on_ready: RTS_AttackVariant
@export var weapon_to_activate_on_ready: RTS_Weapon
@export var use_overlay_anim_for_attack_duration: bool = false

## Required to find out when anim has entered attacking
@export var attack_nodes: Dictionary[StringName,bool] = {
	"attack": true
}

@export_group("VFX")
@export var vfx_on_take_damage: Array[RTS_Particles3DContainer]

@export_group("Debug")
@export var inactive_on_ready = false

signal target_changed(attack: RTS_AttackComponent, old_target: RTS_Defense, new_target: RTS_Defense)
signal target_became_not_null(attack: RTS_AttackComponent, new_target: RTS_Defense)
signal target_became_null(attack: RTS_AttackComponent, old_target: RTS_Defense)
signal player_assigned_target_death(attack: RTS_AttackComponent, player_assigned_target: RTS_Defense)
signal current_target_death(attack: RTS_AttackComponent, target: RTS_Defense)
signal active_weapon_changed(new_weapon: RTS_Weapon,weapon_index: int)

enum State {
	IDLE =0,
	ATTACKING =1,
	COOLDOWN =2
}

#Timers
var remaining_cooldown_time: float:
	get: 
		if is_cooling_down():
			return cooldown_timer.time_left
		return 0

var current_target : RTS_Defense #can only be within scan range
var player_assigned_target: RTS_Defense #can be outside scan range
var weapon_target: RTS_Defense #guaranteed to be within weapon range

var player_assigned_target_is_ally = false #attack move on own faction entity
var can_auto_attack_current_target = true #usually true unless moving/strict attacking
var do_interrupt_attack = false #can be set by other components to cancel attack anim
var aggressor: RTS_Defense #attacked by other defense

var defenses_in_weapon: Dictionary[RTS_Defense,bool] = {}
var defenses_in_scan: Array[RTS_Defense]

var state_machine: RTS_CallableStateMachine = RTS_CallableStateMachine.new()

#--- VARIANTS ---
var variants: Array[RTS_AttackVariant] = []
var active_variant: RTS_AttackVariant
var prev_variant: RTS_AttackVariant = null

#--- WEAPONS ---
var weapons: Array[RTS_Weapon] = []
var active_weapon: RTS_Weapon

#TIMERS
var cooldown_timer : SceneTreeTimer
var immobilize_timer: SceneTreeTimer
var attack_anim_has_finished: bool = false

func set_active_weapon(weapon: RTS_Weapon):
	if active_weapon == weapon:
		return

	if active_weapon:
		active_weapon.set_component_inactive()
		do_interrupt_attack = true
		active_weapon.weapon_area.area_entered.disconnect(on_weapon_area_entered)
		active_weapon.weapon_area.area_exited.disconnect(on_weapon_area_exited)
		active_weapon.scan_area.area_entered.disconnect(on_scan_area_entered)
		active_weapon.scan_area.area_exited.disconnect(on_scan_area_exited)

		#Manually remove all defenses from previous weapon/scan areas
		for defense in defenses_in_weapon.keys():
			defenses_in_weapon.erase(defense)
		for defense in defenses_in_scan:
			defenses_in_scan.erase(defense)
		set_target(null)

	active_weapon = weapon

	if active_weapon:
		assert(!active_weapon.component_is_active, "RTS_Weapon already active when setting active weapon in RTS_AttackComponent")
		active_weapon.weapon_area.area_entered.connect(on_weapon_area_entered)
		active_weapon.weapon_area.area_exited.connect(on_weapon_area_exited)
		active_weapon.scan_area.area_entered.connect(on_scan_area_entered)
		active_weapon.scan_area.area_exited.connect(on_scan_area_exited)
		active_weapon.set_component_active()

	var index :int = weapons.find(active_weapon) #Index or -1
	active_weapon_changed.emit(active_weapon,index)

func set_active_variant(variant: RTS_AttackVariant):
	if active_variant == variant:
		return
	active_variant = variant
		
	if prev_variant != null:
		prev_variant.set_component_inactive()
	else: #Auto Calculate target since it wasn't allowed to be set before
		set_target(try_auto_assign_target())
		
	if variant != null:
		if !variant.component_is_active:
			variant.set_component_active()
	else:
		state_machine.change_state(State.IDLE) #todo test this, but we probably shouldnt be in COOLDOWN or ATTACK when active variant is null
	prev_variant = active_variant

func _physics_process(_delta):
	if !component_is_active:
		return
	update_weapon_target()
	update_active_variant()
	state_machine.update()
	do_interrupt_attack = false

func update_active_variant():
	#Override in subclasses
	pass

func _ready():
	super._ready()
	var children = get_children()

	variants.clear()
	for child in children:
		if child is RTS_Weapon:
			weapons.append(child)
		if child is RTS_AttackVariant:
			variants.append(child)

	state_machine.add_states(State.IDLE,state_idle,Callable(),Callable())
	state_machine.add_states(State.COOLDOWN,state_cooldown,Callable(),Callable())
	state_machine.add_states(State.ATTACKING,state_attacking,enter_state_attacking,exit_state_attacking)
	state_machine.set_initial_state(State.IDLE)

	RTSEventBus.threat_changed.connect(on_threat_changed)

	if entity.selectable != null:
		entity.selectable.on_stop.connect(stop)
	if entity.movable != null:
		entity.movable.next_target_changed.connect(on_movable_next_target_changed)
		entity.movable.all_targets_cleared.connect(on_all_targets_cleared)
		entity.movable.final_target_reached.connect(on_final_target_reached)
	if entity.defense != null:
		entity.defense.attacked_by.connect(on_attacked_by)

	if variant_to_activate_on_ready != null:
		set_active_variant(variant_to_activate_on_ready)
	if weapon_to_activate_on_ready != null:
		set_active_weapon(weapon_to_activate_on_ready)

	if inactive_on_ready:
		print("Setting attack on " + entity.name + " inactive" )
		set_component_inactive()

func state_idle():
	if active_variant != null:
		active_variant.state_idle()
func state_cooldown():
	if active_variant != null:
		active_variant.state_cooldown()
func state_attacking():
	if active_variant != null:
		active_variant.state_attacking()

func enter_state_attacking():
	assert(!is_cooling_down(),"Shouldnt be able to enter this state when attack is cooling down")
	# assert(!is_playing_attack_anim(),"Starting cooldowns but attack anim is still playing")
	assert(weapon_target,"Should have target to attack when entering attacking")
	
	if active_variant && active_weapon:
		attack_anim_has_finished = false
		for weapon in weapons:
			weapon.last_weapon_target = weapon_target
		entity.anim_tree.tree_node_entered.connect(on_tree_node_entered)
		active_variant.enter_state_attacking()

func exit_state_attacking():
	if !attack_anim_has_finished:
		on_attack_anim_finished(&"")
	
	entity.anim_tree.tree_node_entered.disconnect(on_tree_node_entered)
	
	if active_variant != null:
		active_variant.exit_state_attacking()

func stop():
	set_player_assigned_target(null)
	can_auto_attack_current_target = true
	do_interrupt_attack = false
	aggressor = null
	set_target(try_auto_assign_target())
	#do not set_target(null), since attack can continue attacking next frame if possible

func set_component_active():
	super.set_component_active()
	if active_weapon:
		active_weapon.set_component_active()
	if active_variant:
		active_variant.set_component_active()

func set_component_inactive():
	super.set_component_inactive()
	if active_weapon:
		active_weapon.set_component_inactive()
	if active_variant:
		active_variant.set_component_inactive()

func set_target(target: RTS_Defense):
	if current_target != target:
		var previous_target = current_target
		current_target = target
		if target != null:
			target.health.death.connect(on_current_target_death)
			if previous_target != null:
				previous_target.health.death.disconnect(on_current_target_death)
				target_changed.emit(self,previous_target,target)
			else:
				target_became_not_null.emit(self,target)
		else:
			previous_target.health.death.disconnect(on_current_target_death)
			target_became_null.emit(self,previous_target)
		update_weapon_target()

#this should inturn inside on_scan_rea_entered call set_target
func set_player_assigned_target(defense: RTS_Defense):
	var previous = player_assigned_target
	if previous && previous.entity.faction == entity.faction:
		#guarantee prev ally is cleaned up

		if defenses_in_weapon.has(previous):
			defenses_in_weapon.erase(previous)
		remove_from_defenses_in_scan(previous)
	
	player_assigned_target = defense
	player_assigned_target_is_ally = player_assigned_target && player_assigned_target.entity.faction == entity.faction

	for w in weapons:
		w.allow_allies_to_be_targeted(player_assigned_target_is_ally)

	if player_assigned_target_is_ally && active_weapon:
		#guarnatee instead assignment to scan/weapon, since godot's area_entered/exited is called much later
		var distance = player_assigned_target.entity.global_position.distance_squared_to(entity.global_position)
		var scan_and_defense : float = active_weapon.scan_range + player_assigned_target.defense_range
		var scan_and_weapon : float = active_weapon.weapon_range + player_assigned_target.defense_range
		if distance <= scan_and_defense * scan_and_defense:
			on_scan_area_entered(player_assigned_target.area)
		if distance <= scan_and_weapon * scan_and_weapon:
			on_weapon_area_entered(player_assigned_target.area)

	#instantly set_target if within range
	if defenses_in_scan.has(defense):
		set_target(defense)

#Auto-Targeting is only used for
# 1. Stop (also known as "idling")
# 2. Hold Position
# 3. Patrol
# 4. RTS_AttackComponent-Move
# 5. Follow Ally
# and NOT for
# 1. Move
# 2. RTS_AttackComponent RTS_Target
# 3. Any spell or ability

#The criteria for target selection are, from most to least important:
# 1. Which targets are threats to me? (Update August 2025: Of which, which can be attacked)
# 2. Which targets have the highest RTS_AttackComponent RTS_Target Priority (ATP) values?
# 3. Which targets allow me to use my primary weapon?
# 4. Only if I lost my previous target: Which target is the closest?
func try_auto_assign_target() -> RTS_Defense:
	if active_variant == null:
		return null

	#1. Threats
	var threats : Array[RTS_Defense] = []
	var attackable_threats: Array[RTS_Defense] = []
	for other_defense in defenses_in_scan:
		if other_defense != null:
			if other_defense.is_threat_to(self) || other_defense  == player_assigned_target:
				threats.append(other_defense)
				if active_variant.can_attack(other_defense):
					attackable_threats.append(other_defense)
		else:
			assert(false,"Investigate this")

	if threats.size() == 0:
		return null

	#Remove non-attackble threats, only if can attack any
	if !attackable_threats.is_empty():
		threats = attackable_threats

	#2. ATP
	var highest_threats : Array[RTS_Defense] = []
	var highest_atp = -1
	for threat in threats:
		if threat.atp >= highest_atp:
			highest_threats.append(threat)
			highest_atp = threat.atp

	#3 Primary RTS_Weapon?
	#todo for now there is only one weapon, so skip
	
	#4. Distance. First prioritize any in weapon range, then scan range
	var min_distance_squared :float = 10000000
	var min_target : RTS_Defense = null
	#if !defenses_in_weapon.is_empty():
		#if defenses_in_weapon
		
	for high_threat in highest_threats:
		var distance = entity.global_position.distance_squared_to(high_threat.entity.global_position)
		if distance < min_distance_squared:
			min_distance_squared = distance
			min_target = high_threat

	if min_distance_squared == 10000000:
		printerr("Distance check failed..why? this has happened before in stutter step scenario")
		
	if min_target == null:
		assert(false,"I dont think we're ever getting in here")
		var mypos = entity.global_position
		var otherpos = highest_threats[0].entity.global_position
		var distance = mypos.distance_squared_to(otherpos)
		printerr("I dont think we're ever getting in here")
		#this can happen when only neutral targets are left
		if highest_threats.is_empty():
			return null
		else:
			return highest_threats[0]

	#var target_name = str(min_target.owner.name) if min_target != null else "null"
	# Log.info_owner(self, "Auto assigned target: " + target_name)
	return min_target

func remove_from_defenses_in_scan(defense: RTS_Defense):
	if defenses_in_scan.has(defense):
		defenses_in_scan.erase(defense)
		if defense == current_target:
			if defense == player_assigned_target:
				#case: player assigned target has left the scan area
				set_target(null)
			else:
				#case: other enemies left in scan. auto choose next best target
				set_target(try_auto_assign_target())
		else:
			#todo after this is figured out, probably do a reassign of target..
			# printerr( defense.owner.name + " left scan but is not current_target ")
			# var current_target_name = current_target.owner.name if current_target != null else "NULLL"
			# printerr(current_target_name)
			pass

### CALLBACKS ###

# todo: rushers don't auto attack other targets in weapon scan when there a click player assigned targe dies

func on_current_target_death(_entity: RTS_Entity):
	#note: we do NOT change the current target, since this logic will be set in respective area_exited functions
	if current_target == aggressor:
		aggressor = null
	if current_target == player_assigned_target:
		var target = current_target
		set_player_assigned_target(null)
		player_assigned_target_death.emit(self,target)

	current_target_death.emit(self,current_target)
	
func on_all_targets_cleared(_movable: RTS_Movable):
	stop()
	
func on_attacked_by(damage_dealer: RTS_DamageDealer):
	#not 100% sure if this movable logic should be done here...
	#if entity.movable != null:
		#var type = entity.movable.get_active_target_type()
		#if type == RTS_Movable.State.WALK:
			#return

	if damage_dealer.publisher != null:
		var other_defense = damage_dealer.publisher.defense
		if  other_defense != null && other_defense.entity.faction != entity.faction:
			if entity.faction == RTS_Entity.Faction.NEUTRAL:
				printerr("Todo: Neutral enemies not implemented")
				return
			# Log.info("Got attack by " + damage_dealer.publisher.name)
			if aggressor == null:
				aggressor = other_defense

func update_weapon_target():
	if player_assigned_target && defenses_in_weapon.has(player_assigned_target):
		weapon_target = player_assigned_target
		return
	else:
		if current_target && defenses_in_weapon.has(current_target) && (can_auto_attack_current_target || active_variant.can_attack_while_moving):
			weapon_target = current_target
			return
	weapon_target = null

#MOVEMENT RELATED----

#only handles player_assigned_target changes, not state or current target (one exception) changes
func on_movable_next_target_changed(movable: RTS_Movable):
	var next: RTS_Target = movable.next
	var next_type :int = next.type if next else -1
	var previous_pat: RTS_Defense = player_assigned_target

	if next && !next.owner && (next_type == RTS_Movable.Type.ATTACK || next_type == RTS_Movable.Type.MOVEATTACK):
		var source = next.source
		if source != null && source is RTS_Entity && source.defense && source.defense != entity.defense:
			set_player_assigned_target(source.defense)

	can_auto_attack_current_target = !(next_type == RTS_Movable.Type.MOVE || next_type == RTS_Movable.Type.ATTACK || player_assigned_target)

	if (next_type == RTS_Movable.Type.MOVE || next_type == RTS_Movable.Type.ATTACK):
		aggressor = null

	match(next_type):
		RTS_Movable.Type.MOVE, RTS_Movable.Type.PATROL:
			do_interrupt_attack = true
		RTS_Movable.Type.MOVEATTACK:
			#interrupt only when changing player_assigned_target
			if previous_pat != player_assigned_target && !defenses_in_scan.has(player_assigned_target):
				do_interrupt_attack = true

			if defenses_in_scan.is_empty():
				#switching to move_attack from previously attacking ally unit, 
				#so we want to interruptt
				do_interrupt_attack = true 

	if do_interrupt_attack:
		weapon_target = null

func on_final_target_reached(movable: RTS_Movable):
	can_auto_attack_current_target = true

### TIMERS ###
func is_cooling_down() -> bool:
	return cooldown_timer != null && cooldown_timer.time_left > 0

func is_attack_immobilized() -> bool:
	return immobilize_timer != null && immobilize_timer.time_left > 0

var movable_state_before_immobilization: RTS_Movable.State #todo recheck this

func on_tree_node_entered(node: StringName):
	if attack_nodes.has(node):
		var anim_tree: RTS_AnimationTreeComponent = entity.anim_tree
		anim_tree.tree_node_entered.disconnect(on_tree_node_entered)

		if use_overlay_anim_for_attack_duration:
			anim_tree.overlay_anim_player.animation_finished.connect(on_attack_anim_finished)
			assert(anim_tree.overlay_anim_player.current_animation_length > 0)
		else:
			anim_tree.animation_finished.connect(on_attack_anim_finished)
			var test = anim_tree.playback.get_current_length()
			assert(test > 0)
		start_immobilization_timer(active_weapon.attack_immobilize_duration)

func start_immobilization_timer(immobile_duration: float):
	assert(!cooldown_timer,"Can't attack while cooldown timer is active")
	assert(!attack_anim_has_finished)

	if immobile_duration > 0 && entity.movable != null:
		immobilize_timer = get_tree().create_timer(immobile_duration)
		
		assert(false,"todo: use movement override to immobilize instead of changing states")
		#todo consider using movement override instead
		movable_state_before_immobilization = entity.movable.sm.state
		entity.movable.sm.set_state(RTS_Movable.State.IDLE)
		entity.movable.sm.disable_state_changes(true)
		immobilize_timer.timeout.connect(on_attack_immmobilize_countdown_reached)

func start_cooldown_timer(duration: float):
	#Can be called multiple times from weapon, hence we only start one cooldown timer
	#Can also be called from weapon when we've already exited attack state, in which case
	#we don't start the cooldown anymore.
	if cooldown_timer:
		return
	var elapsed : float
	if use_overlay_anim_for_attack_duration:
		elapsed = entity.anim_tree.overlay_anim_player.current_animation_position
		assert(duration > entity.anim_tree.overlay_anim_player.current_animation_length, "Cooldown can't be shorter that attack anim length")
	else:
		elapsed = entity.anim_tree.playback.get_current_play_position()
		assert(attack_nodes.has(entity.anim_tree.playback.get_current_node()))
		assert(duration > entity.anim_tree.playback.get_current_length(), "Cooldown can't be shorter that attack anim length")

	assert(!attack_anim_has_finished,"Cooldown start should happen during attack anim")

	cooldown_timer = get_tree().create_timer(duration - elapsed)
	cooldown_timer.timeout.connect(on_cooldown_reached)

#Can be called before cooldown timer has actually finished
func on_cooldown_reached():
	cooldown_timer.timeout.disconnect(on_cooldown_reached) #Needed, since we can interrupt cooldown before cooldown has actually finishd, i.e. ChargeAbility
	cooldown_timer = null

#Can be called before attack anim timer has actually finished
func on_attack_anim_finished(anim_name: StringName= &""):
	if use_overlay_anim_for_attack_duration:
		entity.anim_tree.overlay_anim_player.animation_finished.disconnect(on_attack_anim_finished)
	else:
		entity.anim_tree.animation_finished.disconnect(on_attack_anim_finished)
	attack_anim_has_finished = true
	

func on_attack_immmobilize_countdown_reached():
	immobilize_timer = null
	entity.movable.sm.disable_state_changes(false)
	entity.movable.sm.set_state(movable_state_before_immobilization)

### AREAS ENTERED ###

#Only handles enemy areas via collision layer/mask
#Area_entered/exist only to handle current_target changes, NOT state changes or player targets
func on_weapon_area_entered(area: Area3D):
	if area.component.entity == entity:
		return
	var defense = area.component as RTS_Defense
	#if ally, only allow player_assigned_targert
	if defense.entity.faction == entity.faction:
		if defense != player_assigned_target:
			return

	if !defenses_in_weapon.has(defense):
		defenses_in_weapon[defense] = true

		#Not the best approach, but in case weapon_area_entered gets called before
		#scan_area_entered, manually call the latter to guarantee correct order
		if !defenses_in_scan.has(defense):
			on_scan_area_entered(area)
		elif player_assigned_target == null && current_target:
			#Try resetting target, since this weapon target could be better/closer than
			#a current_target that is further away in the scan range
			var new_target = try_auto_assign_target()
			if new_target:
				set_target(new_target)
		
#Todo: If current target leaves, but we have other defense in attack range, 
#switch current target to other. this makes for better micro as the current
#target is not always followed. This is only noticable for units with vastly different
#ranges between weapon and scan range. If they are the same, this is not an issue.
#Exception: player assigned taget should be followed
func on_weapon_area_exited(area: Area3D):
	if area.component.entity == entity:
		return

	var defense = area.component as RTS_Defense

	if defenses_in_weapon.has(defense):
		defenses_in_weapon.erase(defense)
		
		#We do this, because we should switch prioritize a closer target
		if defense == current_target \
			&& player_assigned_target == null \
			&& !defenses_in_weapon.is_empty():
				#change to target that is in range without pursuing old target
				set_target(try_auto_assign_target())

func on_scan_area_entered(area: Area3D):
	if area.component.entity == entity:
		return
	var defense = area.component as RTS_Defense

	#if ally, only allow player_assigned_targert
	if defense.entity.faction == entity.faction:
		if defense != player_assigned_target:
			return

	if !defenses_in_scan.has(defense):
		defenses_in_scan.append(defense)
		if defense == player_assigned_target:
			set_target(player_assigned_target)
		else:
			if !player_assigned_target:
				set_target(try_auto_assign_target()) 

func on_scan_area_exited(area: Area3D): #has to be of type defense
	if area.component.entity == entity:
		return
	var defense = area.component as RTS_Defense
	remove_from_defenses_in_scan(defense)

func on_threat_changed(defense: RTS_Defense):
	if defense == current_target && !active_variant.can_attack(defense):
		var new_target = try_auto_assign_target()
		set_target(new_target)
