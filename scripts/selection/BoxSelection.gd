extends Node2D
class_name BoxSelection

@export var rtsCamera: Camera3D
@export var selection: Selection

var start_pos : Vector2
var dragging : bool
var selection_rect: Rect2

var eligible_boxables: Array[Boxable] = []

var ui : UI
func _ready():
	ui = Controls.ui

func add_to_eligible_boxable(boxable: Boxable):
	if !eligible_boxables.has(boxable):
		eligible_boxables.append(boxable)

func remove_from_eligible_boxable(boxable: Boxable):
	if eligible_boxables.has(boxable):
		eligible_boxables.erase(boxable)

func start_dragging():
	if !ui.blocks.is_empty():
		return
		
	start_pos = get_global_mouse_position()
	dragging = true
	selection_rect = Rect2(start_pos,Vector2.ZERO)

func finish_dragging(clear_previous_selection = true):
	if dragging:
		dragging = false
		selection.finalize_hovered_selection(clear_previous_selection)
		queue_redraw()
		selection_rect = Rect2()

func _process(_delta):
	if dragging:
		var end_pos = get_global_mouse_position()
		var raw_rect = Rect2(start_pos,end_pos-start_pos)
		selection_rect = raw_rect.abs()
		hover_selection()
		queue_redraw()

func hover_selection():
	for b in eligible_boxables:
		if !is_instance_valid(b):
			continue
		if selection_rect.intersects(b.get_screen_box()):
			selection.add_to_hovered(b.selectable)
		else:
			selection.remove_from_hovered(b.selectable)


func _draw():
	if dragging:
		draw_rect(selection_rect, Color(0, 0, 1, 0.3))  # A semi-transparent blue rectangle
