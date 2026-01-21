extends RTS_Ability
class_name RTS_ClickAbility

enum Type {
	Position,
	RTS_Selectable
}

@export var radius_ring: RadiusRing #Optional. If present, will render radius when ability active
@export var dont_clear_targets_on_activate: bool = false #Only used by Patrol and Attack RTS_Ability. Best to keep false otherwise

var click_target: Vector3 #in world space
var click_target_source: RTS_Entity #optional/alternative click_target source
var click_resource: ClickAbilityResource
var is_soft_activated : bool = false #when moving to cast
var soft_target: RTS_Target #not null when soft activated and moving towards this target
var is_initiated: bool = false

# Emitted when click ability is "initiated" but not yet cast
signal soft_activated(click_ability: RTS_ClickAbility, value: bool)

func _ready():
	super._ready()
	click_resource = resource as ClickAbilityResource
	

func set_context(value: Dictionary):
	super.set_context(value)
	click_target = value["click_target"]
	click_target_source = value["click_target_source"]

func is_valid_target(_target: Vector3, _source: RTS_Entity):
	#todo check if on navmesh
	#todo write a utiltiy for thath
	if click_resource.type == Type.Position:
			if click_resource.auto_move_to_cast: #can always cast, will auto move until in range
				return true
			return can_cast()
	elif click_resource.type == Type.RTS_Selectable:
		return _source != null

func activate():
	if !component_is_active:
		printerr("Trying to activate inactive click ability")
	if can_cast():
		#Activate normal
		cast()
	else:
		if click_resource.auto_move_to_cast:
			if entity.movable && entity.movable.targets.size() > 0:
				#This will remove the potential move_target that has been set by RTS_AbilityManager
				#There are two cases:
				#a) -> Delayed activation: In this case we remove the next target, then soft_cast
				#	will add its own target again.
				#b) -> Non-Delayed activation: In this case all targets should already be cleared
				#	and we should not get in here anyway. 
				entity.movable.on_next_target_reached(true)
			soft_activate(true)
		else:
			printerr("Should not be able to activate non_auto_moving click ability that can't be cast")
			assert(false)

#the actual "casting" of the ability
func cast():
	start_cooldown(resource.cooldown_duration)
	_ap -= resource.ap_cost
	if entity.movable && entity.movable.targets.size() > 0:
		entity.movable.on_next_target_reached(true)
	RTSEventBus.click_ability_cast.emit(self)

func can_be_activated() -> bool:
	return component_is_active && !has_cooldown() && _ap > 0 && !is_soft_activated

func can_cast() -> bool:
	if entity.global_position.distance_squared_to(click_target) > click_resource.cast_max_range * click_resource.cast_max_range:
		return false
	if entity.global_position.distance_squared_to(click_target) < click_resource.cast_min_range * click_resource.cast_min_range:
		return false
	return true

#Todo: Handle multiple soft acitivation:
#If entity is already soft activated in other ability, that other ability should probably
#get cancelled and this one activated. Currently there is no logic for that
func soft_activate(value: bool):
	is_soft_activated = value
	if entity.movable != null:
		if value:
			soft_target = RTS_Target.new(click_target,RTS_Movable.Type.MOVE,click_target_source,RTS_Movement.generate_session_uid())
			entity.movable.append_to_targets([soft_target])
			entity.movable.all_targets_cleared.connect(on_all_targets_cleared)
			entity.movable.next_target_just_reached.connect(on_next_target_just_reached)
		else:
			entity.movable.all_targets_cleared.disconnect(on_all_targets_cleared)
			entity.movable.next_target_just_reached.disconnect(on_next_target_just_reached)
	set_process(value)		
	soft_activated.emit(self,value)
		
func on_all_targets_cleared(_movable: RTS_Movable):
	soft_activate(false)
	terminated(true)
	RTSEventBus.click_abilities_terminated.emit([self],true)
	
#We have reached the soft_target but were unable to cast (for instance because out of range, i.e.
#outside of nav mesh, in this case we terminate)
func on_next_target_just_reached(_movable: RTS_Movable, _target: RTS_Target):
	if _target == soft_target:
		soft_activate(false)
		terminated(true)
		RTSEventBus.click_abilities_terminated.emit([self],true)

#Only called when soft_activated
func _process(_delta):
	if can_cast():
		cast()
		soft_activate(false)
		terminated(false)
		RTSEventBus.click_abilities_terminated.emit([self],false)
		
#When action first pressed, but hasn't been cast yet
func initiated():
	is_initiated = true
	if radius_ring:
		radius_ring.show_ring(get_visible_ring_radius())

#opposite of initiated. cancelled is false if ability was activated
func terminated(cancelled: bool):
	is_initiated = false
	if cancelled && is_soft_activated:
		soft_activate(false)
	if radius_ring:
		radius_ring.hide_ring()

func get_visible_ring_radius() -> float:
	return click_resource.cast_max_range
