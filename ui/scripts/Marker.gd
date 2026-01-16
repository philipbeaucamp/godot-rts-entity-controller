class_name RTS_Marker extends Node2D

@export var priority: int = 0
var requests_to_be_active: Dictionary[String,bool] = {}