@icon("res://addons/godot-rts-entity-controller/assets/icons/keyboard_h_outline.png")
class_name RTS_HoldAbility extends RTS_Ability


func activate():
	super.activate()
	entity.movable.hold()
