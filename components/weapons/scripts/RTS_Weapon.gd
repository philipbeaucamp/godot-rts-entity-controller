class_name RTS_Weapon extends RTS_Component

# Base class for all RTS Weapons.
# Uses damage dealers to deal damage to targets.
# Behaviour (i.e. instant damage, or using projectiles etc) should be implemented in subclasses.

@export var attack: RTS_AttackComponent
@export var is_melee: bool = false #in the future this could become a getter if multiple attack variants exist?
@export var damage_dealers: Array[RTS_DamageDealer] = []
@export var modifiers : Array[RTS_WeaponModification] = []


@export_group("Times")
# Note: Cooldown duration is timed from attack anim start, 
# but only actually cooling down after weapon.use() has been called. This means if attack anim
# gets interrupted before use(), cooldown won't start.
@export var cooldown_duration: float = 0.5
@export var attack_immobilize_duration : float = 0 

@export_group("Areas")
@export var weapon_area: Area3D 
@export var scan_area: Area3D

var scan_range: float #radius of scan_area
var weapon_range: float #radius of weapon_area
var last_weapon_target: RTS_Defense #Set by AttackComponent

func set_component_active():
	super.set_component_active()
	var areas = [weapon_area,scan_area]
	for area in areas:
		area.set_deferred("monitoring", true)

func set_component_inactive():
	super.set_component_inactive()
	var areas = [weapon_area,scan_area]
	for area in areas:
		area.set_deferred("monitoring", false)

func fetch_entity() -> RTS_Entity:
	return attack.fetch_entity()
	
func _ready():
	super._ready()
	var scan_shape = scan_area.get_child(0) as CollisionShape3D
	scan_range = scan_shape.shape.radius
	var weapon_shape = weapon_area.get_child(0) as CollisionShape3D
	weapon_range = weapon_shape.shape.radius
	
	for dealer in damage_dealers:
		if dealer.publisher == null:
			dealer.publisher = entity
			push_warning("Publisher was not set on RTS_Weapon")

	#Set layers and masks based on faction
	var areas = [weapon_area,scan_area]
	if entity.faction == RTS_Entity.Faction.PLAYER:
		for area in areas:
			area.set_collision_layer_value(RTS_Controls.settings.collision_layer_player_attack,true) 
			area.set_collision_mask_value(RTS_Controls.settings.collision_layer_enemy_defense,true) 
	else:
		for area in areas:
			area.set_collision_layer_value(RTS_Controls.settings.collision_layer_enemy_attack,true) 
			area.set_collision_mask_value(RTS_Controls.settings.collision_layer_player_defense,true) 

func allow_allies_to_be_targeted(activate: bool):
	if entity.faction == RTS_Entity.Faction.PLAYER:
		scan_area.set_collision_mask_value(RTS_Controls.settings.collision_layer_player_defense,activate)
		weapon_area.set_collision_mask_value(RTS_Controls.settings.collision_layer_player_defense,activate) 
	else:
		scan_area.set_collision_mask_value(RTS_Controls.settings.collision_layer_enemy_defense,activate)
		weapon_area.set_collision_mask_value(RTS_Controls.settings.collision_layer_enemy_defense,activate) 

func make_active():
	attack.set_active_weapon(self)

func use():
	if !component_is_active:
		push_warning("Looks like this still gets triggered from dying units, which is not ideal")
		return
	if !last_weapon_target:
		printerr("Why is target null inWWepaon?")
		return
	for modifier in modifiers:
		modifier.use(self)
	attack.start_cooldown_timer(cooldown_duration)

func add_weapon_modification(item: RTS_WeaponModification):
	modifiers.append(item)

func increase_damage_by_percent(percent: float):
	for dmg in damage_dealers:
		dmg.damage = dmg.damage * (1 + percent)
