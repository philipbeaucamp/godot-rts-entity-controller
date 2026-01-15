@icon("res://addons/rts_entity_controller/assets/icons/keyboard_h_outline.png")
extends Ability

class_name HoldAbility


func activate():
	super.activate()
	entity.movable.hold()
