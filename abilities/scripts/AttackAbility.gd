@icon("res://addons/godot-rts-entity-controller/assets/icons/keyboard_a_outline.png")
extends RTS_ClickAbility

class_name RTS_AttackAbility

func is_valid_target(_target: Vector3, _source: RTS_Entity):
	return true

func activate():
	var movables : Array[RTS_Movable] = []
	movables.append(entity.movable)
	Controls.movement.group_move(
		click_target,
		click_target_source,
		movables,
		context["shift_is_pressed"],
		RTS_Movable.Type.MOVEATTACK,
		)
	activated.emit(self)

func activate_group(abilities: Array):
	var movables : Array[RTS_Movable] = []
	for ability in abilities:
		movables.append(ability.entity.movable)
		ability.activated.emit(ability)

	Controls.movement.group_move(
		click_target,
		click_target_source,
		movables,
		context["shift_is_pressed"],
		RTS_Movable.Type.MOVEATTACK
	)
