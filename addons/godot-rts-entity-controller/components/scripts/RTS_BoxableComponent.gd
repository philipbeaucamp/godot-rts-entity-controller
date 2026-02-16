class_name RTS_BoxableComponent extends RTS_Component

@export var collision_shape : CollisionShape3D

var selectable: RTS_Selectable

var camera : Camera3D
var radius_in_screen: float
var height_in_screen: float
var screen_box : Rect2

func fetch_entity():
	return get_parent().fetch_entity()
	
func _ready():
	super._ready()
	#only allow player units to be boxable:
	if entity.faction != RTS_Entity.Faction.PLAYER:
		self.queue_free()
	else:
		camera = RTS_Controls.camera
		selectable = get_parent() as RTS_Selectable
		update_screen_lengths()

func get_screen_box() -> Rect2:
	var origin_in_screen = camera.unproject_position(entity.global_position)
	return Rect2(origin_in_screen - Vector2(radius_in_screen,height_in_screen),Vector2(radius_in_screen*2,height_in_screen))

#this function will calculate the radius_in_screen and height_in_screen, which ideally only
#need to be calculate once. exception: if size or upwards position of entity changes
func update_screen_lengths():
	var origin_in_screen = camera.unproject_position(entity.global_position)
	var radius : float
	var height : float
	if collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		radius = capsule.radius
		height = capsule.height
	elif collision_shape.shape is BoxShape3D:
		var box = collision_shape.shape as BoxShape3D
		radius = box.size.x/2
		height = box.size.y
		
	var right_in_screen = camera.unproject_position(entity.global_position + camera.global_transform.basis.x * radius)
	var top_in_screen = camera.unproject_position(entity.to_global(Vector3.UP * height))
	radius_in_screen = origin_in_screen.distance_to(right_in_screen)
	height_in_screen = origin_in_screen.distance_to(top_in_screen)
	
