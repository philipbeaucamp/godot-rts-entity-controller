class_name RTS_AttackVariant extends RTS_Component

#Base class for implementing unit specific attack variants.
#For most units RTS_DefaultAttackVariant will be sufficient. (Think Sc2 Marine)

@export var can_attack_while_moving = false
@export var behaviour: RTS_AttackComponent

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
			weapon.cooldown_duration = weapon.attack_anim_duration
			push_warning("RTS_Weapon cooldown duration cannot be less than attack animation duration.")

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
	
