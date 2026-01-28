@icon("res://addons/godot-rts-entity-controller/assets/icons/keyboard_s_outline.png")
class_name StopAbility extends RTS_Ability

func activate():
	super.activate()
	entity.selectable.stop()
