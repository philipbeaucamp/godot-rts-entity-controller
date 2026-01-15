extends Button

@export var entity: Entity

func set_up(_entity: Entity):
	entity = _entity

func _ready():
	self.text = entity.resource.display_name
	var health = entity.health
	if health != null:
		self.text = self.text + "(" + str(health.health) + "/" + str(health.init_health) + ")"
