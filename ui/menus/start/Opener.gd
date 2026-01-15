extends RefCounted

class_name Opener

var strategy: Strategy
var rp: int
var rp_rate: int
var production: Array[UnitProductionItem] = []
var units: Array[EntityResource] = []

static var starter_units: Array[StringName] = [
	"rusher",
	"striker",
	"mauler"
	# "hammer",
	# "stratos"
	]

func _init(_strategy: Strategy, _unit: Array[EntityResource],_rp: int,_production: Array[UnitProductionItem]):
	strategy = _strategy
	rp = _rp
	production = _production
	units = _unit
	match _strategy:
		Strategy.ECO:
			rp_rate = 4
		Strategy.BALANCED:
			rp_rate = 3
		Strategy.RUSH:
			rp_rate = 2
		Strategy.CHEESE:
			printerr("not implemented")

enum Strategy {
	ECO,
	BALANCED,
	RUSH,
	CHEESE
}

#move this into proper model/data class later:
static func generate_opener(_strategy: Strategy) -> Opener:
	#var supply_cap: int = 20
	var resource_points : int = 6
	match _strategy:
		Strategy.ECO:
			resource_points = 5
		Strategy.BALANCED:
			resource_points = 5
		Strategy.RUSH:
			resource_points = 5
		Strategy.CHEESE:
			printerr("not implemented")
			return null
	
	var resources : Array[EntityResource] = []
	for starter in starter_units:
		resources.append(ResourceDB.get_entity_resource(starter))

	var _units : Array[EntityResource] = UnitUtils.generate_units(resource_points,1,1000,resources)
	var prod_items : Array[UnitProductionItem] = []
	prod_items.assign(ResourceDB.get_all_items().filter(func(item: Item): return item is UnitProductionItem))
	prod_items = prod_items.filter(func(item: UnitProductionItem): return _units.has(item.unit))

	# var items = Globals.run.item_pool.keys().filter(func(item: Item) -> bool : return item is UnitProductionItem)
	# var prod_items: Array[UnitProductionItem] = []
	# prod_items.assign(items)

	# var production : Array[UnitProductionItem] = UnitUtils.generate_production(supply_cap,prod_items)
	return Opener.new(_strategy,_units,resource_points,prod_items)
	
