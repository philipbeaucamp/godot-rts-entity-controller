class_name RTS_AiComponent extends RTS_Component

#This component should only handle micro decisions like activating abilities etc
#Position, and more tactical decisisions are computed in Squad

@export var cast_lambda: float = 0.2 # 5 sec avg

# cast_lambda multiplier when health reaches below certain threshold
# this means avg wait time is halfed i.e. lambda 0.25 -> 0.5 means avg wait time becomes 4s -> 2s
const LAMBDA_INTENSIFIER = 2 
const TICK_TIME = 0.3

var squad: Squad
var delay: bool = true
var tick_delta: float
var cast_delta: float
var cast_threshold: float
var is_intense: bool =  false

func _ready():
	super._ready()
	if entity.faction != RTS_Entity.Faction.ENEMY:
		self.queue_free()
	update_cast_threshold(TICK_TIME,cast_lambda)
	await get_tree().create_timer(randf_range(0,TICK_TIME)).timeout
	if entity.health != null:
		entity.health.health_changed.connect(on_health_changed)
	delay = false

func update_cast_threshold(minimum: float, lambda: float):
	cast_threshold = RTS_MathUtil.inverse_exponential(minimum,lambda)

func reset_cast_threshold(minimum: float, lambda: float):
	cast_delta = 0
	update_cast_threshold(minimum,lambda)

func set_squad(_squad: Squad):
	squad = _squad

func remove_squad(_squad: Squad):
	if squad == _squad:
		squad = null

func _process(delta):
	if delay || !component_is_active:
		return
	tick_delta += delta
	cast_delta += delta
	if tick_delta >= TICK_TIME:
		tick_delta -= TICK_TIME
		tick()

func tick():
	# You can run indiviual entity AI logic here if needed
	pass

# Return Array of following:
# index 0 : bool -> valid or not
# index 1 : Vector3 -> valid target for ClickAbilities
func valid_to_cast(ability: Ability) -> Array:
	if !component_is_active:
		return [false]
	if ability._ap == 0:
		return [false]
	if cast_delta < cast_threshold:
		return [false]
	if !ability.can_be_activated():
		return [false]
	if Controls.tactical_ai.player_cluster_centers.is_empty(): #is this true for all abilities ?
		return [false]
	if entity.is_stunned:
		return [false]

	var click_ability = ability as ClickAbility		
	var valid_target: Vector3 = Vector3.INF
	if click_ability:
		for center in Controls.tactical_ai.player_cluster_centers:
			if click_ability.is_valid_target(center,null):
				valid_target = center
				break
		if valid_target == Vector3.INF:
			return [false]
			
	return [true,valid_target]

func can_engage() -> bool:
	if !component_is_active || entity.attack == null || entity.movable == null:
		return false
	if !entity.abilities.has("attack"):
		return false
	if entity.attack.current_target != null || entity.attack.player_assigned_target != null:
		return false
	if !entity.movable.targets.is_empty(): #todo update this with new defual attack behaviour
	# if entity.movable.next && entity.movable.next.type != RTS_Movable.Type.PATROL:
		return false
	return true

func on_health_changed(_health: RTS_HealthComponent):
	if is_intense:
		return
	var health = entity.health
	if health.health/health.init_health < 0.6:
		is_intense = true
		update_cast_threshold(0,cast_lambda*LAMBDA_INTENSIFIER)
