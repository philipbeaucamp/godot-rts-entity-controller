class_name RTS_TimeUtility extends Node

var is_paused : bool = false
var time_scale : float = 1.0

signal paused
signal unpaused

var pause_requests: Dictionary = {}

#unscaled delta time
var _last_time : float = 0.0
var unscaled_delta: float = 0.0

func _process(delta):
	if is_paused:
		var now: float = Time.get_ticks_msec() / 1000.0
		unscaled_delta = now - _last_time
		_last_time = now

func pause(requester: Object):
	if !pause_requests.has(requester):
		pause_requests.set(requester,true)

	if is_paused:
		return
	Engine.time_scale = 0.0
	is_paused = true
	_last_time = Time.get_ticks_msec() / 1000.0
	paused.emit()

func unpause(requester: Object):
	if !pause_requests.has(requester):
		return
	if !is_paused:
		return
	pause_requests.erase(requester)
	if pause_requests.is_empty():
		is_paused = false
		Engine.time_scale = time_scale
		unpaused.emit()

func set_time_scale(value: float):
	if value == 0:
		push_warning("not allowed. use pause() to pause time")
		return
	time_scale = value
	Engine.time_scale = time_scale

func call_delayed(seconds: float, func_ref: Callable,args: Array):
	await get_tree().create_timer(seconds).timeout
	func_ref.callv(args)

func call_delayed_non_suspend(seconds: float, func_ref: Callable,args: Array):
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func_ref.bindv(args))
