# Defense Component 

This components requires `RTS_Health` to translate received damage from attacks and weapons into actual health damage on `RTS_Health`. 
It is in a way the couterpart to `RTS_AttackComponent`, since attack components keep track (and attack) defense components (and not entities or health components).

### Properties


```gdscript
@export var armor: int = 0
@export var atp: int = 20 #RTS_AttackComponent-RTS_Target-Priority. Higher values are considered higher threats. This is different from selection priority.
@export var vfxs: Array[RTS_Particles3DContainer]
@export var area : Area3D
```

**armor** is a crude implementation of a damage reduction system. For a more complex armor system you could simply extend `RTS_DefenseComponent` and override the logic.

An important property is the **atp** attack target priority (stolen from [SC2's Automatic Targeting System](https://liquipedia.net/starcraft2/Automatic_Targeting)), which determins the priority of attacks. The highe the `atp`, the more this defense component is prioritized by enemy attack components.


The optional **vfxs** takes an array of `RTS_Particles3DContainer` which are played when being attacked.

As with other components, it requires a `Area3D` **area** to determin collisions with weapon and scan areas.



See [Combat System](../systems/combat.md) for complete combat details.
