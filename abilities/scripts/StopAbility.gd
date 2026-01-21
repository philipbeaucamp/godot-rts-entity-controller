@icon("res://addons/godot-rts-entity-controller/assets/icons/keyboard_s_outline.png")
extends RTS_Ability

class_name StopAbility

func activate():
	super.activate()
	entity.selectable.stop()
