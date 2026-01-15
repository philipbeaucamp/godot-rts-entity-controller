extends CanvasLayer

@export var index: Sprite2D
@export var buttons: Array[CMainMenuButton] = []
@export var anim_player : AnimationPlayer

var is_open: bool = false
var is_active: bool = false
var current_index_position : CMainMenuButton

#todo when back from trip:
	#main menu should perhaps pause scenario when scenario has started,
	#otherwise (before scenario, or when copmleted) time doesnt have to be paused
	#but input/control should be disabled
	#map never has to be paused but also input disabled


func on_mouse_entered(button: CMainMenuButton):
	index.visible = true
	current_index_position = button
	index.global_position = button.index_target.global_position

func on_mouse_exited(button: CMainMenuButton):
	if button == current_index_position:
		index.visible = false

func process_input(input: Dictionary[StringName,Variant]):
	if input["escape_just_pressed"]:
		close_menu()

func close_menu():
	if !is_active:
		return
	is_active = false
	is_open = false
	for button in buttons:
		button.mouse_entered.disconnect(on_mouse_entered.bind(button))
		button.mouse_exited.disconnect(on_mouse_exited.bind(button))
		button.pressed.disconnect(on_pressed.bind(button))
	RTSEventBus.main_menu_closing.emit()
	anim_player.play("closing")
	RTSEventBus.main_menu_closed.emit()

func open_menu():
	if is_active:
		return
	for button in buttons:
		button.mouse_entered.connect(on_mouse_entered.bind(button))
		button.mouse_exited.connect(on_mouse_exited.bind(button))
		button.pressed.connect(on_pressed.bind(button))
	is_active = true
	anim_player.play("opening")
	RTSEventBus.main_menu_opening.emit()
	await anim_player.animation_finished
	RTSEventBus.main_menu_opened.emit()
	is_open = true

func on_pressed(_button: CMainMenuButton):
	if _button.name == "Play":
		close_menu()
		# Controls.enter_from_main_menu() #todo use signal for this
	if _button.name == "Quit":
		get_tree().quit()
