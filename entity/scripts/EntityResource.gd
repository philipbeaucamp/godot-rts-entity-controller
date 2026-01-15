extends Resource

#Simple data holder class for Entity
#Useful for accessing entity data without loading the entire entity scene
class_name EntityResource

@export var display_name: StringName
@export var id: StringName
@export var short_id: StringName
@export var thumbnail: Texture2D
