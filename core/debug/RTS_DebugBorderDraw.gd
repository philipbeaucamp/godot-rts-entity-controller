extends Node2D

@export var margin := 10
@export var color := Color.RED
@export var thickness := 2
@export var enabled := false

func _draw():
	if !enabled:
		return
		
	var size = get_viewport_rect().size

	var top_left     = Vector2(margin, margin)
	var top_right    = Vector2(size.x - margin, margin)
	var bottom_left  = Vector2(margin, size.y - margin)
	var bottom_right = Vector2(size.x - margin, size.y - margin)

	draw_line(top_left, top_right, color, thickness)
	draw_line(top_right, bottom_right, color, thickness)
	draw_line(bottom_right, bottom_left, color, thickness)
	draw_line(bottom_left, top_left, color, thickness)
