extends Node
class_name DamageDealer

@export var publisher: Entity #optional, who is dealing this damage
@export var from: Node3D #optional, where is the damage dealt from. usually publisher.global_position, but can also be projetile position
@export var damage: float = 1.0

func deal_damage(target: Defense,_pos: Vector3):# todo what is _pos doing ?
	if target:
		target.get_attacked_by(self)
