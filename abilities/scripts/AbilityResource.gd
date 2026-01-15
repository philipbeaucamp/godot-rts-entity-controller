extends Resource

class_name AbilityResource

@export var id: StringName #must be same as action input name

# @export var order: int = 0 #for now always 0, maybe set to 1 or 2 when an entity has multiple abilities ?
@export var is_common: bool = false # if is_common, always executable if entity is selected
@export var allow_trigger_multiple = false #can trigger multiple abilities with single button press
@export var activate_as_group = false # calls activate_group once instead of activate individually for reach ability
@export var cooldown_duration : float = 0.0
@export var is_chainable: bool = true #if false, ability will immediately be activated, even when shift pressed
@export var display: bool =  true

@export var display_ap: bool = true
@export var init_ap: int = 1
@export var max_ap: int = 1
@export var ap_cost: int = 1

@export var icon_normal: Texture2D
@export var icon_hover: Texture2D
@export var icon_pressed: Texture2D

@export var background: Texture2D
@export var description: String
