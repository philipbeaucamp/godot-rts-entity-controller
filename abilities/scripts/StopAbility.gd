@icon("res://addons/rts_entity_controller/assets/icons/keyboard_s_outline.png")
extends CommonAbility

class_name StopAbility

func activate():
	super.activate()
	entity.selectable.stop()
