# Combat System

## Overview

Godot RTS Entity Controller provides a modular set of Attack and Weapon logic that can be easily extended and changed to achieve unique attack and AI behaviour.

The main components needed to implement attack and damage dealing logic are:

- **RTS_AttackComponent** : Holds the common, shared logic of tracking targets within scan/weapon range and manages state (IDLE, COOLDOWN, ATTACKING). 
- **RTS_AnimationTreeComponent**: **Required** component by RTS_AttackComponent to handle animation and attack durations.
- **RTS_AttackVariant** (default implementation: RTS_DefaultAttackVariant) : Implements RTS_AttackComponent's states explicitly, i.e. how to behave (mainly movement) during each state.
- **RTS_Weapon**: Holds weapon specific logic and data, such as cooldown duration, modifiers, damage dealing logic etc
- **RTS_DamageDealer**: Used (not exclusively) by weapon to deal damage to a RTS_Defense

A typical damage dealing entity should have a structure something like the following

```
Entity (RTS_Entity)
├── AnimationPlayer
├── AnimationTree (RTS_AnimationTreeComponent)
└── AttackComponent (RTS_AttackComponent)
	├── Weapon (RTS_Weapon)
		└── Damage (RTS_DamageDealer)
	└── Variant (RTS_AttackVariant)
```

althought the amount of weapons, damage dealer and variants might vary. Lets look at each component in more detail and use the minimalistic ExampleUnit.tscn as an example.

## Components

### RTS_AttackComponent

The main component of the combat system. Whilst a single entity can hold and switch between multiple weapons or attack variants, there should only be on RTS_AttackComponent acting as the orchestrator for the system.

The component emits useful signals,

```gdscript
signal target_changed(attack: RTS_AttackComponent, old_target: RTS_Defense, new_target: RTS_Defense)
signal target_became_not_null(attack: RTS_AttackComponent, new_target: RTS_Defense)
signal target_became_null(attack: RTS_AttackComponent, old_target: RTS_Defense)
signal player_assigned_target_death(attack: RTS_AttackComponent, player_assigned_target: RTS_Defense)
signal current_target_death(attack: RTS_AttackComponent, target: RTS_Defense)
signal active_weapon_changed(new_weapon: RTS_Weapon,weapon_index: int)
```
 
holds state,

```gdscript
enum State {
	IDLE =0,
	ATTACKING =1,
	COOLDOWN =2
}
```

and holds references to the entities weapons and attack variants:

```gdscript
#in _ready
	for child in children:
		if child is RTS_Weapon:
			weapons.append(child)
		if child is RTS_AttackVariant:
			variants.append(child)
```

Even when only using a single attack variant and weapon, such as ExampleUnit.tscn, it is recommended to always set the weapon and attack variants **set_component_active_on_ready** field to false, and let the attack component decide which attack variant or weapon to activate in _ready:

```gdscript
@export var variant_to_activate_on_ready: RTS_AttackVariant
@export var weapon_to_activate_on_ready: RTS_Weapon
```

This should become obvious when using multiple weapons or attack variants (of which only one, respectively, can be active at a time). The support for multipl weapons/attack variants can be thought of as the entity being able to wield different weapons (for example ground vs anti-air weapons), and different associated behaviours (normal attack mode, siege attack mode).

### Interplay with RTS_AnimationTreeComponent

An integral part to the combat system and successful state transitions between IDLE, COOLDOWN and ATTACKING is the RTS_AnimationTreeComponent and the AnimationPlayer. In order to understand the remaining two properties of RTS_AttackComponent,

```gdscript
## Required to find out when anim has entered attacking
@export var attack_nodes: Dictionary[StringName,bool] = {
	"attack": true
}
@export var use_overlay_anim_for_attack_duration: bool = false
```

it is important to understand the interplay of these components.

When an enemy unit is attacked, the RTS_AttackComponents state changes to "ATTACKING". This alone does not automatically deal damage or play an animation. Rather, it is the RTS_AnimationTreeComponent's statemachines job, to react to this state change and play an attack animation. Inspecting the ExampleUnits AnimationTreeComponents AnimationNodeStateMachine,

![alt text](../images/example_unit_sm.png)

we can see the transition from state "idle" to "attack" checks whether the attack state is 1, or ATTACKING.
Note the "Advance Condition Base Node" of the AnimationTreeComponent is RTS_Entity, as explained in [Entity System](../systems/entity.md)

![alt text](../images/example_unit_sm_transition.png)

Here is where the **attack_nodes** property comes into play. When name of the entered node is contained in the **attack_nodes** dictionary, we're telling RTS_AttackComponent that the attack animation has started. By default the name "attack" is included, but you could add multiple different attack nodes playing different attack animations, and add each of their name to the dictionary.

If **use_overlay_anim_for_attack_duration** is false, RTS_AttackComponent will wait for the animation AnimationTreeComponent's associated AnimationPlayer to finish to feedback the end of the attack animation. In other words, the state transition from ATTACKING to IDLE or COOLDOWN as well as the attack duration depend on the attack animation (which is played using the AnimationTree) to play correctly.

This coupling of the AnimatationTree's AnimationPlayer and attack state logic might not always be preferable. For example, one might want to use slightly different timings, or modify the "attack animation" but can't easily do this due to the models animation player being part of an imported scene (i.e. a gltf blender file). In this case, one can use an additional AnimationPlayer and set it as the RTS_AnimationTreeComponent's **overlay_anim_player** to use this animation players animation to determine the attack duration. In this case, to inform the RTS_AttackComponent of which animation it has to keep track of, you need to add a map from the state machines node name (above: "attack") to the overlayed animation players animation name (ideally called the same as the node name, "attack").

**Remark**: The reason for this slightly annoying system of having to listen to the animation player's animation, instead of using the state machine's nodes directly, is that, as of Godot 4, the state machine nodes do not have built in callbacks for when animations or states have finished. The state machine simply acts as a controller to advance the AnimationPlayers animation.

Some people might find it easier to interpret to above logic directly by looking at the relevent code:

```gdscript
func on_tree_node_entered(node: StringName):
	if attack_nodes.has(node):
		var anim_tree: RTS_AnimationTreeComponent = entity.anim_tree
		anim_tree.tree_node_entered.disconnect(on_tree_node_entered)

		if use_overlay_anim_for_attack_duration:
			anim_tree.overlay_anim_player.animation_finished.connect(on_attack_anim_finished)
			assert(anim_tree.overlay_anim_player.current_animation_length > 0)
		else:
			anim_tree.animation_finished.connect(on_attack_anim_finished)
			assert(anim_tree.playback.get_current_length() > 0)
		start_immobilization_timer(active_weapon.attack_immobilize_duration)
```

### RTS_AttackVariant

RTS_AttackComponent can switch between multiple RTS_AttackVariant's via `set_active_variant(...)`. The main purpose of this is so that the state logic

```gdscript
func state_idle():
	pass
func state_cooldown():
	pass
func state_attacking():
	pass
```

can be implement in different flavors. Most, if not all but certain special units, probably want to use the **RTS_DefaultAttackVariant** implementation of RTS_AttackVariant. ExampleUnit.tscn demonstrate how this variant behaves. It exposes a few options to lock or override rotation during attack/cooldown,

```gdscript
@export var attack_overrides_rotation = true
@export var cooldown_overrides_rotation = true
```

and implements basic AI behavior, which automatically tries to attack enemy units if in range via `try_move_attack_chased_target(...)`.


### RTS_Weapon

So far we have explained how attack state (and transitions) are managed via RTS_AttackComponent and RTS_AnimationTreeComponent, and how RTS_AttackVariant implements moving and AI logic, but no actual damage has been dealt anywhere. This is where RTS_Weapons come into play.

Simple call its `use()` function to deal damage to its active target. This target (called `last_weapon_target`) is automatically set and updated by the other components introduced earlier. 

While it is possible to make this call from anywhere, the best place is probably to add a function call from the attack animation itself (the original or the overlay attack animation if using one):

![alt text](../images/example_unit_attack_anim.png)

ExampleUnit.tscn uses **RTS_InstantDamageWeapon** to deal instant damage to its targets (using the RTS_DamageDealer, see below.). One could write more complex weapons that inherit from RTS_Weapon and shoot projectiles or use the SpatialHashArea to deal AoE damage.

#### Weapon and Scan Areas

`RTS_AttackComponent` uses weapon and scan areas to determine which enemy defense areas (set up in `RTS_DefenseComponent`) it overlaps and collides with. `RTS_DefenseComponent`s within the **Weapon range** can be attacked. As soon as there is at least on valid target within weapon range, the combat system will try to attack this target. Defenses within the **Scan range** cannot yet be attacked, but are being tracked by `RTS_AttackComponent` and (depending on the AttackVariant logic) automatically chased down to attack. See the `RTS_DefaultAttackVariants`'s `try_move_attack_chased_target` for details if curious.

### RTS_DamageDealer

A simple node holding damage information used to damage RTS_Defenses.

```gdscript
@export var publisher: RTS_Entity #optional, who is dealing this damage
@export var from: Node3D #optional, where is the damage dealt from. usually publisher.global_position, but can also be projetile position
@export var damage: float = 1.0
```

Whilst optional, publisher and from should always bet set if possible. Without a `publisher`, a damage receiving entity won't know from which other entity the damage came from, for example in order to pursue and counter attack it. Similarly, `from` is used to determin the exact position where the damage has come from, for example to do spatial calculations useful for vfx and shaders.

## See Also

- [Defense Component](../components/defense.md) - Health management
- [Abilities System](../systems/abilities.md) - Ability details
