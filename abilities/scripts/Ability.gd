extends Component
class_name Ability

@export var resource: AbilityResource #determins action id, cooldown, ap cost, etc

signal activated(ability: Ability)
signal recharged(ability: Ability)

var state_machine: CallableStateMachine = CallableStateMachine.new()
var context: Dictionary = {} #populated by ability manager or RTS_AiComponent before activation
var cooldown_timer : SceneTreeTimer
var _ap: int
var ap_cost: int

var remaining_cooldown_time: float:
	get: 
		if has_cooldown():
			return cooldown_timer.time_left
		return 0

func get_cooldown_timer_duration() -> float:
	return resource.cooldown_duration

func _ready():
	super._ready()
	set_up_statemachine()
	_ap = resource.init_ap
	set_process(false) 

func add_ap(amount: int):
	var before: int = _ap
	_ap = min(resource.max_ap, _ap + 1)
	if before == 0 && _ap > 0:
		recharged.emit(self)

func set_up_statemachine():
	pass

func has_cooldown() -> bool:
	return cooldown_timer != null && cooldown_timer.time_left > 0

func can_be_activated() -> bool:
	return component_is_active && !has_cooldown() && _ap > 0

func activate():
	if !component_is_active:
		printerr("Trying to activate inactive ability")
	start_cooldown(resource.cooldown_duration)
	_ap -= resource.ap_cost
	activated.emit(self)

func activate_group(abilities: Array):
	for ability in abilities:
		ability.activate()

#if allow_trigger_multiple == false, then only one out of the group will be activated.
#use this function to determin which ability should be prioritized
#i.e. closest to a target etc
func get_preferred_ability_to_activate(abilities: Array) -> Ability:
	return abilities[0]

func set_context(value: Dictionary):
	context = value

func start_cooldown(duration: float):
	if duration <= 0:
		return
	if has_cooldown():
		printerr("Calling activate on ability with cooldown")
		return
	cooldown_timer = get_tree().create_timer(duration)
	cooldown_timer.timeout.connect(on_cooldown_timeout)

func on_cooldown_timeout():
	cooldown_timer = null
	if _ap >= resource.ap_cost:
		recharged.emit(self)
