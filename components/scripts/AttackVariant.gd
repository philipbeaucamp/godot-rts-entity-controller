extends Component

class_name AttackVariant

@export var can_attack_while_moving = false
@export var behaviour: RTS_AttackComponent

#A list of (priority, controller) tuples that can overwrite the statemachine
# var sm_override: Array = []

func fetch_entity(): 
	return behaviour.fetch_entity()

func set_component_active():
	behaviour.do_interrupt_attack = false
	super.set_component_active()

func set_component_inactive():
	behaviour.do_interrupt_attack = true
	super.set_component_inactive()

func can_attack(other: RTS_Defense) -> bool:
	return other.can_be_attacked_by(behaviour)

#---UPGRADES---#
func increase_cooldown_duration_percent(percentage: float):
	for weapon in behaviour.weapons:
		weapon.cooldown_duration *= (1 + percentage)
		if weapon.cooldown_duration < weapon.attack_anim_duration:
			push_error("Cooldown smaller than atack_anim_duration")
			#todo limit? or somehow increase anim speed ?
			#todo what about the other (non active) attack variants ? 

#---STATES---
func state_idle():
	pass
func state_cooldown():
	pass
func state_attacking():
	pass

func enter_state_attacking():
	pass
func exit_state_attacking():
	pass
	
