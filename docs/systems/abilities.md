# Abilities System

## Overview

Abilities are special actions that units can perform, such as spells, skills, or special attacks. They support cooldowns, costs, effects, and animations.

## Creating an Ability

Similar to `RTS_Entity`, in order to separate data from the execution logic, static data pertaining to an ability, such as its id, cooldown duration or action points is defined in the `AbilityResource` resource.

### AbilityResource

Start by creating an ability resource:

```gdscript
class_name AbilityResource extends Resource

@export var id: StringName #must be same as action input name

@export var is_common: bool = false # if is_common, always executable if entity is selected
@export var allow_trigger_multiple = false #can trigger multiple abilities with single button press
@export var activate_as_group = false # calls activate_group once instead of activate individually for reach ability
@export var cooldown_duration : float = 0.0 #cooldown in seconds
@export var is_chainable: bool = true #if false, ability will immediately be activated, even when shift pressed
@export var display: bool =  true #if false, ui will not display this icon (remove RTS_SImpleUI scene if unwanted)

@export var display_ap: bool = true 
@export var init_ap: int = 1
@export var max_ap: int = 1
@export var ap_cost: int = 1

@export var icon_normal: Texture2D
@export var icon_hover: Texture2D
@export var icon_pressed: Texture2D

@export var description: String #optional description for ability tooltip
```

A quick explanation of the above properties follows.

- **is_common**: Used to differentiate between common abilities (such as moving, patrolling, stopping) and unit unique abilities (such as a special attack of a certain unit). In the default implementation, this will for instance determine whether the UI displays the ability in the bottom left (common), or bottom right (special) corner. If `use_highest_entity_for_ability_selection` in the rts_settings.tres is set to true, this will also result in non-common abilities of only the highest selected unit to be displayed. This is for instance the behaviour in the RTS Starcraft2, where (apart from certain standard abilities), only the unit in the selected units with the highest priority can cast its spells.
- **allow_trigger_multiple**: If true, ALL selected entities with the same ability will activate their ability. If false, only one will do so.
- **activate_as_group**: If true, `func activate_group(abilities: Array):` instead of `func activate():` on the ability will be called. Useful if special group behaviour is required, for instance for formation walking (see RTS_MoveAbility)
- **cooldown_duration**: If positive, requires the time in seconds to elapse before ability can be cast again
- **is_chainable**: If false, abilities are immediately activated. If true, the ability will only activate or cast when the next movement target is reach. Imagine a "Sniping ability" that will only start casting once you've reached the next movement point. (This requires you to have chain the ability by pressing Ctrl + <ABILITY_INPUT>)
- **display**: If false, default UI does not display the action
- **display_ap**: If false, default UI does not display action points.
- **init_ap**: How many action points the entity initial has, for this ability.
- **max_ap**: How many action points the entity can maximally have, for this ability.
- **ap_cost**: How many action points it costs to activate this ability
- **description**: Optional description of the ability, used by the default UI.


Icon normal/hover/pressed are the textures displayed by the default UI in the left/right corner, when a ability is enabled/hovered/activated. If you're using a custom UI you can ignore these fields.

### RTS_Ability

After creating the resource, you can inherit from `RTS_Ability` to implement your custom ability logic. For a simple reference, check out `RTS_MoveAbility` or `RTS_HoldAbility`

  
## Ability Types

There are three basic Ability Component types, which you can extend, 

- `RTS_Ability`: Base class, providing functions such as `activate()`, `activate_group()`.
- `RTS_ClickAbility`: Inherting base class and adding functionality to **cast** abilities that require a target. Adds additional functionality, such as `is_valid_target()` or `can_cast()`. Note that activating this ability can potentially not immediately call `cast()`, for instance when the casting target is out of range. Additional casting properties, such as `auto_move_to_cast`, `cast_min_range` or `cast_max_range` can be set in the corresponding `ClickAbilityResource`. ClickAbilities can be cancelled by right clicking after activating them (before casting). To cast, left click the target.
  
- `RTS_ToggleAbility`: Extending the base class by adding a toggle on/off state to the ability. 
  
```gdscript
# RTS_ToggleAbility
enum State {
	DEACTIVATED,
	ACTIVATED
}
```


## RTS_AbilityManager

The managing script that parses and interprets input (coming from PlayerInput), and activates the respective abilities on one or more entities, either separately or as group. 
It handles complex behaviour such as chaining abilities (which adds a callback to activate certain abilities when the next move target is reached), and auto moving towards cast targets for `RTS_ClickAbility`.

The default implementation of RTS_AbilityManager supports two "modes", depending on whether `use_highest_entity_for_ability_selection` in rts_settings.tres is enabled or not.

**Standard** (not enabled). Any ability of any selected entity (that doesn't have an active cooldown and enough AP) can be activated.

**SC2-Style** (activated). Only the **special** abilties of the "highest" selected entity (this is determined viat the `@export var priority: int` property on RTS_Selectable) can be activated. Common abilities (of all units) can always be activated.




## See Also

- [Combat System](../systems/combat.md) - Damage and health
- [Attack System](../components/attack.md) - Basic attacks
- [Custom Integration](custom-integration.md) - Extending systems
