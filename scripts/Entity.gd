@tool
class_name Entity extends CharacterBody3D

enum Faction {PLAYER,ENEMY,NEUTRAL}

@export var faction = Faction.PLAYER
@export var resource: EntityResource

signal debug_entity(entity: Entity,value: bool)
signal before_tree_exit(entity:Entity)
signal end_of_life(entity: Entity) #guarnateed to be called exactly once, either when dying or if hasn't died, when removed
signal spatial_hash_entity(entity: Entity, value: bool)

#DEBUG
var is_debugged = false
var entity_debug_scene = preload("res://addons/rts_entity_controller/entity/scenes/entity_debug.tscn")
var entity_debug_instance

# Components should automatically be fetched. It is less error prone to assign this way
# instead of in _ready so that components can be accessed at any time, i.e. in children's _ready
@export var selectable: Selectable
@export var movable: Movable
@export var defense: Defense
@export var attack: AttackBehaviour
@export var health: Health 
@export var stunnable: Stunnable
@export var anim_tree: AnimationTreeComponent

@export var visible_on_screen: VisibleOnScreenNotifier3D
@export var visuals: VisualComponent
@export var ai : AiComponent
@export var entity_collider : CollisionShape3D #can be nullable
@export var obstacle: NavigationObstacleComponent

@export var space_hash: bool = true:
	set(value):
		space_hash = value
		spatial_hash_entity.emit(self,space_hash)

var passive_components: Array[Component] = []

var abilities: Dictionary[String,Ability] = {}
var abilities_array: Array[Ability] = []
var is_ready : bool = false

#--- Anim Tree Evelations. Avoid getters for perfomance
var sb : Dictionary[StringName, bool] = {} #state bool
var si : Dictionary[StringName, int] = {} #state integer
func set_state_bool(key: StringName, value: bool):
	sb.set(key,value)
func set_state_int(key: StringName, value: int):
	si.set(key,value)
#AnimationTree Evaluations End-------------

#Use get_collision_radius() if race conditions on bootup is an issue. otherwise use property
var collision_radius: float 

func get_collision_radius() -> float:
	if entity_collider != null:
		if entity_collider.shape is SphereShape3D:
			return (entity_collider.shape as SphereShape3D).radius
		elif entity_collider.shape is BoxShape3D:
			var box = (entity_collider.shape as BoxShape3D)
			return maxf(box.size.x/2.0,box.size.z/2.0)
		else:
			printerr("Unknown collision shape on entity")
	return 0.25 #default small value


func set_up(_faction: Faction):
	faction = _faction

func _enter_tree():
	update_and_fetch_components()
	if Engine.is_editor_hint():
		return
	RTSEventBus.entity_entered_tree.emit(self)

func _exit_tree():
	if Engine.is_editor_hint():
		return
	before_tree_exit.emit(self)
	if !health || !health.is_dead:
		end_of_life.emit(self)
	RTSEventBus.entity_exiting_tree.emit(self)

func _ready():
	if Engine.is_editor_hint():
		update_and_fetch_components()
		return

	collision_radius = get_collision_radius()

	#Set up component signals
	if health:
		health.death.connect(on_death)
	if movable:
		movable.sm.enter_state.connect(on_movable_enter_state)
		on_movable_enter_state(movable.sm.current_state)
	if attack:
		print("TODO CLEAN THIS CRAP UP AND DO PROPER INITIALIZATION OF STATES")
		attack.state_machine.enter_state.connect(on_attack_enter_state)
		on_attack_enter_state(attack.state_machine.current_state)
		attack.active_weapon_changed.connect(on_active_weapon_changed)
		var index = attack.weapons.find(attack.active_weapon)
		set_state_int("weapon_index",index)
		
	if stunnable:
		stunnable.stunned.connect(on_stunned)
	
	#Set collision layers and masks
	set_collision_layer_value(Controls.settings.collision_layer_units,true)
	set_collision_mask_value(Controls.settings.collision_layer_units,true)
	set_collision_mask_value(Controls.settings.collision_layer_buildings_and_rocks,true)
	set_collision_mask_value(Controls.settings.collision_layer_force,true)

	visible_on_screen.screen_entered.connect(on_screen_entered)
	visible_on_screen.screen_exited.connect(on_screen_exited)

	is_ready = true
	RTSEventBus.entity_ready.emit(self)
	
func make_essential_components_passive():
	if attack && attack.component_is_active:
		passive_components.append(attack)
	if defense && defense.component_is_active:
		passive_components.append(defense)
	for a in abilities_array:
		if a.component_is_active:
			passive_components.append(a)
	for c in passive_components:
		c.set_component_inactive()

func on_movable_enter_state(new_state: int):
	si["move_state"] = new_state
	# if id == "striker":
	# 	if si["attack_state"] != 1 && si["move_state"] <= 2:
	# 		print("YES")
func on_attack_enter_state(new_state: int):
	si["attack_state"] = new_state
	# if id == "striker":
	# 	if si["attack_state"] != 1 && si.has("move_staet") && si["move_state"] <= 2:
	# 		print("YES")
func on_active_weapon_changed(new_weapon: Weapon,weapon_index: int):
	si["weapon_index"] = weapon_index
func on_stunned(entering_entity: Entity,value: bool):
	sb["is_stunned"] = value

func enable_unit_collisions(value: bool):
	set_collision_mask_value(Controls.settings.collision_layer_units,value)


func update_and_fetch_components():
	abilities.clear()
	abilities_array.clear()
	for child in get_children():
		if child is Selectable:
			selectable = child
		if child is Movable:
			movable = child
		if child is Defense:
			defense = child
		if child is AttackBehaviour:
			attack = child
		if child is Health:
			health = child
		if child is AnimationTreeComponent:
			anim_tree = child
		if child is Ability:
			abilities_array.append(child)
			if abilities.has(child.resource.id):
				printerr("Multiple abilities using same resource is not supported. " + str(child.resource.id) + " Entity:  " + str(self.name))
			else:
				abilities[child.resource.id] = child

static func get_color(_faction: Faction):
	if _faction == Faction.PLAYER:
		return Color.GREEN
	elif _faction == Faction.ENEMY:
		return Color.RED
	elif _faction == Faction.NEUTRAL:
		return Color.YELLOW

func on_death(_entity: Entity):
	self.collision_layer = 0
	self.collision_mask = 0

	if anim_tree:
		#death logic, perhaps find better place for this in future
		var death_node: String = "death"
		if velocity.length_squared() > 0 && anim_tree.sm.has_node("death_forward"):
			death_node = "death_forward"
		if anim_tree.sm.has_node(death_node):
			anim_tree.tree_node_entered.connect(on_tree_node_entered)
			anim_tree.travel(death_node)
		else:
			queue_free()
	else:
		queue_free()

	end_of_life.emit(self)

func on_tree_node_entered(node: StringName):
	if node == "End":
		queue_free()
		

func toggle_entity_debug():
	is_debugged = !is_debugged
	var controls = Controls
	if is_debugged:
		var canvas = controls.canvas_layer
		controls.selection.removed_from_selection.connect(on_removed_from_selection)
		if canvas != null:
			entity_debug_instance = entity_debug_scene.instantiate()
			entity_debug_instance.set_up_entity_debug(self)
			canvas.add_child(entity_debug_instance)
		else:
			printerr("Scene is missing CanvasLayer")
	else:
		controls.selection.removed_from_selection.disconnect(on_removed_from_selection)
		entity_debug_instance.queue_free()
	debug_entity.emit(self,is_debugged)
		
func on_removed_from_selection(selection: Array[Selectable]):
	if selection.has(get_node("Selectable")):
		toggle_entity_debug()

func on_screen_entered():
	RTSEventBus.entity_screen_visible.emit(self,true)
func on_screen_exited():
	RTSEventBus.entity_screen_visible.emit(self,false)
