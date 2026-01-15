extends Ability

class_name CommonAbility

func fetch_entity(): 
	var optional_entity = get_parent() as Entity
	if optional_entity == null:
		optional_entity = get_parent().get_parent() as Entity
	return optional_entity
