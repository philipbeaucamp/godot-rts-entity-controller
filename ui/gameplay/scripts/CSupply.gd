extends Control

class_name CSupply

@onready var label: Label = $Label
@onready var point_label: Label = $Points
@onready var core_label: Label = $Cores

func _ready():
	RTSEventBus.economy_supply_changed.connect(on_supply_change)
	RTSEventBus.economy_supply_cap_changed.connect(on_supply_cap_changed)
	RTSEventBus.economy_rp_changed.connect(on_eco_rp_changed)
	RTSEventBus.economy_cores_changed.connect(on_eco_cores_changed)
	
	#update once on ready:
	if Globals.run:
		var eco = Globals.run.economy
		on_eco_cores_changed(eco)
		on_supply_change(eco)
		on_eco_cores_changed(eco)
	
	# RTSEventBus.points_change.connect(on_points_change)

# func on_points_change():
# 	point_label.text =  "Points: " + str(Globals.points)
func on_eco_rp_changed(economy: Economy):
	point_label.text =  "RP: " + str(economy.rp) + "/" + str(economy.rp_limit)

func on_supply_change(economy: Economy):
	var supply :int = ceil(economy.supply)
	var format_string = "Supply: %s/%d"
	label.text = format_string % [economy.supply,economy.player_supply_cap]

func on_supply_cap_changed(economy: Economy):
	var supply :int = ceil(economy.supply)
	var format_string = "Supply: %s/%d"
	label.text = format_string % [economy.supply,economy.player_supply_cap]

func on_eco_cores_changed(eco: Economy):
	var rst = "Cores: \n"
	for key in eco.cores:
		rst += str(Economy.CORE.keys()[key]) + ": " + str(eco.cores[key]) + "\n"
	core_label.text = rst
