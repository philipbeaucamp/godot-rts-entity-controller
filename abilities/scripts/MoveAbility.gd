@icon("res://addons/godot-rts-entity-controller/assets/icons/keyboard_m_outline.png")
extends RTS_Ability

class_name RTS_MoveAbility

var last_move_target_source : RTS_Entity

func is_valid_target(_target: Vector3, _source: RTS_Entity):
	return true

func activate():
	move([entity.movable])
	activated.emit(self)

func activate_group(abilities: Array):
	var movables : Array[RTS_Movable] = []
	for ability in abilities:
		movables.append(ability.entity.movable)
		ability.activated.emit(ability)
	move(movables)

func move(movables: Array[RTS_Movable]):
	var world_pos = Controls.movement.get_current_mouse_world_pos()
	last_move_target_source = null
	if Controls.selection.hovered_pickable != null:
		last_move_target_source = Controls.selection.hovered_pickable.entity
		world_pos = last_move_target_source.global_position

	Controls.movement.group_move(
		world_pos,
		last_move_target_source,
		movables,
		context["shift_is_pressed"],
		RTS_Movable.Type.MOVE
	)
