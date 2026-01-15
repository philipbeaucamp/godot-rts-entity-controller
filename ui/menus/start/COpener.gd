extends Control

class_name COpener

@export var title_label: Label
@export var supply_label: Label
@export var unit_label: Label
@export var rp_label: Label
@export var rp_rate_label: Label
@export var button: Button


var opener : Opener 
signal opener_selected(opener: Opener)

func set_up_c_opener(_opener: Opener):
	opener = _opener
	update_view()

func _ready():
	button.pressed.connect(on_button_pressed)

func on_button_pressed():
	opener_selected.emit(opener)

func update_view():
	title_label.text = Opener.Strategy.keys()[ opener.strategy]
	unit_label.text = "Starting Units: \n"
	for unit in opener.units:
		unit_label.text += unit.display_name + " "
	unit_label.text += "\n"
	for item in opener.production:
		unit_label.text += item.get_display_text()
	rp_label.text = "RP: " + str(opener.rp)
	rp_rate_label.text = "RP rate " + str(opener.rp_rate)
