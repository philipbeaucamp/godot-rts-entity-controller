@icon("res://addons/rts_entity_controller/assets/icons/keyboard_a_outline.png")
extends ClickAbility

class_name AttackAbility

func is_valid_target(_target: Vector3, _source: Entity):
	return true

func activate():
	var movables : Array[Movable] = []
	movables.append(entity.movable)
	Controls.movement.group_move(
		click_target,
		click_target_source,
		movables,
		context["shift_is_pressed"],
		Movable.Type.MOVEATTACK,
		)
	activated.emit(self)

func activate_group(abilities: Array):
	var movables : Array[Movable] = []
	for ability in abilities:
		movables.append(ability.entity.movable)
		ability.activated.emit(ability)

	Controls.movement.group_move(
		click_target,
		click_target_source,
		movables,
		context["shift_is_pressed"],
		Movable.Type.MOVEATTACK
	)
