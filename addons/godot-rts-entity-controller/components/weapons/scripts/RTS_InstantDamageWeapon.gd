class_name RTS_InstantDamageWeapon extends RTS_Weapon

# Most basic implementation of RTS_Weapon
# When called (via use()), deals damage instantly to weapon target via its damage dealers
# Note that its usually best to call use() from the attack animation timeline,
# to line it up nicely with attack animations and other visual effects

@export var from: Node3D #used to calculate impact position, given this from position (approx is enough)

func fetch_entity() -> RTS_Entity:
	return attack.fetch_entity()

func _ready():
	super._ready()

func use():
	super.use()
	if !last_weapon_target || !component_is_active:
		return
	for dealer in damage_dealers:
		dealer.deal_damage(last_weapon_target,last_weapon_target.entity.global_position)
