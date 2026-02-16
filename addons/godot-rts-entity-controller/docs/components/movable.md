# Movable Component

The main logic of entity movement. It is modelled after common [steering](https://gdcvault.com/play/1018262/The-Next-Vector-Improvements-in) and [boid](https://en.wikipedia.org/wiki/Boids) logic and closely tuned to achieve a similar play and feel as Starcraft2.

This is by far to most complex component and probably deserves a future refactor. For now, we will go over the different states and explain the exposed properties in more detail. 

#### State and Targets

RTS_Movable holds a list of `RTS_Target`, which describe the target position and meta data (for instance whether the target is another RTS_Entity itself, or if there are any callbacks to invoke when reaching a target etc).

Most notably, each target is associated with a type 

```gdscript
enum Type {
	NULL = 0, #NULL only used for signal emitting since can't emit null variable and for null checks
	PATROL = 1, #Patrol back and forth between multiple targets
	MOVE = 2, 
	ATTACK = 3, # Will move to attack a specific target, ignoring anything else.
	MOVEATTACK = 4 #Moves towards target, but will auto attack enemy entities inbetween when possible.
	} 
```

signifying the type of movement towards this target. The types should be self explanatory to anyone who has played another RTS such as Warcraft or Starcraft.

At the same time, a RTS_Movable entity is always in one of the following states at a given time.

```gdscript
enum State {
	IDLE = 0,
	 #if we don't need to follow targets, we don't need this state. This makes things much simpler.
	 #However, I'm keeping it in for now since it might be useful to readd "entity following" logic later
	REACHED_SOURCE_TARGET = 1,
	HOLD = 2,
	PATROL = 3,
	WALK = 4,
	RETURN_TO_IDLE = 5, #Unit automatically returns to idle position
	PUSHED = 6 # Unit is pushed by external forces
	} # <= 2 means unit is stationary, > 2 is moving, > 3 is moving without patrol
```

Types and States are not necessarily the same, as the state describes what current state the movable component is in, whereas the target type gives information on how the next target should be treated.

#### Properties

```gdscript
@export_group("General")
@export var speed: float = 5
@export var stop_distance : float = 0.25
@export var pivot: Node3D #Node which gets rotated. Note: RTS_Entity node is never rotated to keep things simple
@export var steering : Area3D
```

The steering area is used for local avoidance and separation. As can be seen in the ExampleUnit, it is a sphere shape with a fairly small radius around the units, slightly larger thant the entities collision shape itself, used to find immediate neighbors. These neighbors are used for "separation" and "avoidance" explained further below

```gdscript
@export_group("Components")
@export var nav_agent: NavigationAgent3D
```

A NavigationAgent3D is required for the seeking component of the movement logic.

```gdscript
@export_group("Separation")
@export var use_separation :bool = true 
@export var separation_multiplier : float = 1.0
@export_group("Avoidance")
@export var use_avoidance :bool = true 
@export var avoidance_multiplier : int = 10
@export_group("Push")
@export var allow_being_pushed : bool = true
```

Separation, avoidance and pushing behaviour is what sets RTS_Movable entities apart from Godots standard implementation of NavigationAgents.

**Separation** enabled: If two moving entities are about to walk into each other, they a force will be applied (in opposite directions) which separates the entities, allowing them to smoothly pass each other.

**Avoidance** enabled: Avoidance is used to avoid, or walk around, immovable objects or immovable entities. Entities can be immovable, even when having a RTS_Movable component themselves, for example when the ability "RTS_HoldAbility" is activated. This default behaviour is implemented here,

```gdscript
func is_externally_immovable(_movable: RTS_Movable) -> bool:
	return sm.current_state == State.HOLD
```

and can often be overriden by other scripts, using the `active_controller` override.
To test avoidance behaviour, try "holding" an entity (making it immovable) and then walk into it with another entity.

**Allow Being Pushed** enabled: There are numerous occasions when entities want to push each other (this does not count as separation). For instance an **Idling** entity (meaning the movement state is IDLE) will always be pushed away from a moving entity that is walking and colliding with it. Enabling this will make it easy and smooth to walk through your own entities. Certain abilities could also make use of this and push other entities out of the way.


#### Controller overrides

Movement being the most complex logic in RTS, there are many times when you want to override the behaviour temporarily, for instance because you enable a certain ability. To accomodate this, RTS_Movable holds a list of controllers,

```gdscript
#A list of (priority, controller) tuples that can overwrite this scripts physics process
var active_controller: Object #Either this or a class that overrides movement, i.e. RTS_AttackVariant
var controller_overrides: Array = []
```

of which only the highest priority controller is considered active and determins the exact movement logic.

```gdscript
# RTS_Movable:

func add_controller_override(controller: Object, priority: int) -> void:
	controller_overrides.append({ "priority": priority, "controller": controller })
	controller_overrides.sort_custom(func(a, b): return b["priority"] - a["priority"])
	active_controller = controller_overrides[0].controller

func remove_controller_override(controller: Object) -> void:
	controller_overrides = controller_overrides.filter(func(entry): return entry["controller"] != controller)
	controller_overrides.sort_custom(func(a, b): return b["priority"] - a["priority"])
	if controller_overrides.is_empty():
		active_controller = null
	else:
		active_controller = controller_overrides[0].controller
```

For instance, the most common use is `RTS_DefaultAttackVariant`, which automatically overrides the default implementation of `RTS_Movable` when it is active:

```gdscript
# RTS_DefaultAttackVariant:

func set_component_active():
	super.set_component_active()
	if entity.movable != null:
		entity.movable.add_controller_override(self,1)
	
func set_component_inactive():
	super.set_component_inactive()
	if entity.movable != null:
		entity.movable.remove_controller_override(self)
```

Such a controller has to implement exactly two functions:

`func physics_process_override_movable(delta: float, movable: RTS_Movable)`
and

`func is_externally_immovable(movable: RTS_Movable) -> bool:`

of which we have already discussed the latter further above. This way, `RTS_DefaultAttackVariant` can implement (override) its own custom movement logic, which is needed because we might not won't to continue to move when we are attacking.

Note all the complex boid behaviours and state transitions are taken care of in `RTS_Movable`. Therefore the overriding controller doesn't have to implement custom movement logic itself, rather, it can run extra condition checks and determin which functions in the `RTS_Movable` should be execute. In most cases these controller still call

```gdscript
movable.sm.updatev([delta])
```

at some point, which runs the default movement logic in `RTS_Movable`. To clarify this point, imagine you only want the default movement logic to happen when the current time in seconds in divisible by two. You could add a controller, which checks the time modulo 2, and only calls `updatev([delta])` when this condition is true.


## Events

```gdscript
signal after_targets_added(movable: RTS_Movable, targets: Array[RTS_Target])
signal next_target_changed(movable: RTS_Movable) #onyl called for acute target change
signal before_all_targets_cleared(movable: RTS_Movable)
signal all_targets_cleared(movable: RTS_Movable)
signal next_target_just_reached(movable: RTS_Movable, target: RTS_Target) # called just before removal of index
signal final_target_reached(movable: RTS_Movable)
```


