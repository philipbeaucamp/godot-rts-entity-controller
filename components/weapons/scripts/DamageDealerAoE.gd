extends DamageDealer

class_name DamageDealerAoE

@export var radius : float = 0.6

func deal_damage(_target: RTS_Defense,pos: Vector3, override_radius: float = -1):
	var _radius : float = override_radius if override_radius > 0 else radius
	var entities : Array[RTS_Entity] = SpatialHashArea.main_grid.find_entities(pos,_radius,true)
	for e in entities:
		if e.defense != null:
			e.defense.get_attacked_by(self)
	if publisher.is_debugged:
		##DebugDraw3D.draw_cylinder_ab(pos,pos + 0.01 * Vector3.UP,_radius,Color.RED,1)
		pass
