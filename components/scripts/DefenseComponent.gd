class_name RTS_Defense extends RTS_Component

@export var armor: int = 0
@export var atp: int = 20 #RTS_AttackComponent-Target-Priority. Higher values are considered higher threats. This is different from selection priority.
@export var hit_animation = ""
@export var vfxs: Array[RTS_Particles3DContainer]
@export var area : Area3D

signal attacked_by(damage_dealer: RTS_DamageDealer)

var incoming_projectiles: Dictionary[Node3D,bool]  #todo refactor, the key should be damagedealers. the damage dealer should exist in the projectile scene itself
var health: RTS_HealthComponent
var attack_conditions: Array[Callable] = []
var defense_range: float
var defense_range_squared: float

var modifiers: Array[Object] = [] #dynamically added to manipulate effect when getting attacked

func _ready():
	super._ready()
	health = entity.health
	var defense_shape = area.get_child(0) as CollisionShape3D
	defense_range = defense_shape.shape.radius
	defense_range_squared = defense_range * defense_range
	set_faction(entity.faction)

func set_faction(faction: RTS_Entity.Faction):
	if faction == RTS_Entity.Faction.PLAYER:
		area.set_collision_layer_value(Controls.settings.collision_layer_player_defense,true)
		area.set_collision_mask_value(Controls.settings.collision_layer_enemy_attack,true) 
	else:
		area.set_collision_layer_value(Controls.settings.collision_layer_enemy_defense,true) 
		area.set_collision_mask_value(Controls.settings.collision_layer_player_attack,true)
	#Todo Set neutral layers

func add_get_attacked_modifier(modifier: Object):
	if !modifiers.has(modifier):
		modifiers.append(modifier)

func remove_get_attacked_modifier(modifier: Object):
	if modifiers.has(modifier):
		modifiers.erase(modifier)

func increase_armor(delta: int):
	armor += delta

func get_attacked_by(damage_dealer: RTS_DamageDealer):
	attacked_by.emit(damage_dealer) #to be called even when receiving no dmg, for example to pull aggro

	#Calc Damage
	var dmg : float = damage_dealer.damage - armor
	
	for modifier in modifiers:
		dmg = modifier.modify_on_get_attacked_by(dmg,damage_dealer,self)

	dmg = max(0,dmg)
	assert(dmg >= 0)
	entity.health.take_damage(dmg)

	for vfx in vfxs:
		vfx.restart_all()

func set_component_active():
	super.set_component_active()
	area.set_deferred("monitorable",true)

func set_component_inactive():
	super.set_component_inactive()
	area.set_deferred("monitorable",false)

func add_to_incoming_projectiles(projectile: Node3D):
	if !incoming_projectiles.has(projectile):
		incoming_projectiles[projectile] = true

func remove_from_incoming_projectiles(projectile: Node3D):
	if incoming_projectiles.has(projectile):
		incoming_projectiles.erase(projectile)

#Who am I (this defense) a threat to (other is attackbehavior)
#Override this function for more advanced threat logic, i.e. Air vs Ground units etc
func is_threat_to(other: RTS_AttackComponent) -> bool:
	if other == null:
		printerr("RTS: Called is_threat_to with null attack")
		return false
	if health.is_dead:
		return false
	if entity.faction == other.entity.faction:# && self != other.player_assigned_target:
		return false
	if entity.faction == RTS_Entity.Faction.NEUTRAL:
		#case: defender (this) is Neutral
		if other.entity.faction == RTS_Entity.Faction.PLAYER:
			return false
	if other.entity.faction == RTS_Entity.Faction.NEUTRAL:
		#case: attacker (other) is neutral:
		if entity.faction == RTS_Entity.Faction.PLAYER:
			return false
	return true

func add_attack_condition(callback: Callable) -> void:
	attack_conditions.append(callback)

func remove_attack_condition(callback: Callable) -> void:
	attack_conditions.erase(callback)

# Can be false while defense is still a threat. I.e. an unreachable defense
# dont check factions here, rather reachable conditions/ melee vs air etc conditions
# This is different from is_threat_to, i.e. this checks the actual possibility to attack
func can_be_attacked_by(other: RTS_AttackComponent) -> bool:
	for condition in attack_conditions:
		if condition.call(other) == false:
			return false
	return true
