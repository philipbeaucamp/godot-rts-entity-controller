extends Button
class_name EventBusButton
@export var emit_on_pressed: RTSEventBus.Event
@export var visible_on: Array[RTSEventBus.Event] = []
@export var invisible_on : Array[RTSEventBus.Event] = []

@export var invisible_on_ready : bool = true
@export var root: Control
@export var auto_turn_invisible_after: float = -1
###
func _ready():
	for e in visible_on:
		NimbleEvents.subscribe(e,self,"on_event")
	for e in invisible_on:
		NimbleEvents.subscribe(e,self,"on_event")

	if invisible_on_ready:
		root.visible = false
		
	pressed.connect(on_pressed)

func on_pressed():
	NimbleEvents.broadcast(Event.new(emit_on_pressed))

func on_event(_event: Event):
	if _event.id in visible_on:
		root.visible = true
		if auto_turn_invisible_after > 0:
			await get_tree().create_timer(auto_turn_invisible_after).timeout
			root.visible = false
	elif _event.id in invisible_on:
		root.visible = false
