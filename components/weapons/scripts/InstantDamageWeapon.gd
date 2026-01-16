extends Weapon

class_name InstantDamageWeapon

@export var use_impact_vfx = true
@export var vfx_is_melee: bool = true
@export var from: Node3D #used to calculate impact position, given this from position (approx is enough)
@export var impact_vfx : String

var impact_vfx_pool : ObjectPool

func fetch_entity() -> RTS_Entity:
	return attack.fetch_entity()

func _ready():
	super._ready()
	impact_vfx_pool = Controls.pool_manager.get_pool(impact_vfx)

func use():
	super.use()
	# if !attack.weapon_target || !component_is_active:
	if !last_weapon_target || !component_is_active:
		return
	for dealer in damage_dealers:
		dealer.deal_damage(last_weapon_target,last_weapon_target.entity.global_position)
	if use_impact_vfx:
		play_impact_vfx(last_weapon_target)

func play_impact_vfx(t: RTS_Defense):
	var vfx = impact_vfx_pool.get_item(false) as VFXPoolItem
	var collision_shape = t.area.get_node("CollisionShape3D") as CollisionShape3D
	if vfx_is_melee:
		vfx.global_position = from.global_position
	else:
		vfx.global_position = Controls.geometry_utils.random_front_facing_global_point_on_shape(collision_shape,from.global_position)
	vfx.set_active(true) #automatically deactivates after vfx has played
