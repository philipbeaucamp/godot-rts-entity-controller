class_name RTS_HealthComponent extends RTS_Component

@export var init_health : float = 100

var health_bar_scene = preload("res://addons/godot-rts-entity-controller/entity/scenes/health_bar.tscn")
var health_bar_instance: RTS_HealthBar

var health: float
var is_dead = false

signal death(entity: RTS_Entity)
signal health_changed(health: RTS_HealthComponent)
signal health_damaged(health: RTS_HealthComponent)

func _ready():
	super._ready()
	health = init_health
	instanitate_health_bar()
		
func _exit_tree():
	#Clean up after itself
	if health_bar_instance != null && !health_bar_instance.is_queued_for_deletion():
		health_bar_instance.queue_free()

func instanitate_health_bar():
	var control_parent = Controls.canvas_layer_health_bar_control
	if control_parent != null:
		health_bar_instance = health_bar_scene.instantiate()
		health_bar_instance.set_up(self)
		control_parent.add_child(health_bar_instance)
	else:
		printerr("Scene is missing CanvasLayer")

func heal(amount: float = INF):
	health = min(health + amount, init_health)
	health_changed.emit(self)

func heal_percentage(percentage: float):
	health = min(health + percentage * init_health,init_health)
	health_changed.emit(self)

func take_damage(dmg : float):
	if !component_is_active:
		return
	if dmg <= 0 || Controls.settings.invincibility:
		return
		
	health -= dmg
	health_changed.emit(self)
	health_damaged.emit(self)
	if health <= 0 && !is_dead:
		die()	

func increase_max_health(increase: float):
	var percentage = health/init_health
	init_health += increase
	health = percentage * init_health
	health_changed.emit(self)

func die():
	is_dead = true
	set_component_inactive()
	death.emit(entity)
