extends Weapon

class_name SimpleProjectileWeapon

@export var projectile: PackedScene #SimpleProjectile
@export var impact_vfx: PackedScene
@export var from: Node3D

func fetch_entity() -> Entity:
	return attack.fetch_entity()

func use():
	super.use()
	if !component_is_active:
		printerr("This should ideally not happen..")
		return
	# if !attack.weapon_target:
	if !last_weapon_target:
		return
	var instance : SimpleProjectile = projectile.instantiate()
	get_tree().root.add_child(instance)
	instance.start(from.global_position,last_weapon_target)
	instance.impact.connect(on_impact)

func on_impact(p: SimpleProjectile, hit: bool):
	for d in damage_dealers:
		if d is DamageDealerAoE || hit:
			d.deal_damage(p.target,p.target_pos)
	if impact_vfx:
		var instance : SelfFreeingVFX = impact_vfx.instantiate()
		get_tree().root.add_child(instance)
		instance.global_position = p.position
		instance.play()
