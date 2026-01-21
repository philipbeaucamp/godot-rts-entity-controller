@icon("res://addons/godot-rts-entity-controller/assets/icons/keyboard_h_outline.png")
extends RTS_Ability

class_name HoldAbility


func activate():
	super.activate()
	entity.movable.hold()
