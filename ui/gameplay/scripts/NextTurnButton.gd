extends Node

func _ready():
	RTSEventBus.economy_supply_changed.connect(on_supply_changed)
	RTSEventBus.run_started.connect(on_run_started)
	if Globals.run:
		check(Globals.run.economy)
	
	
func on_run_started(run: Run):
	check(run.economy)
	
func on_supply_changed(eco:Economy):
	if Island.current && Island.current.sm.current_state != Island.State.IN_TURN:
		check(eco)
	
func check(eco: Economy):
	self.visible = eco.supply > 0
