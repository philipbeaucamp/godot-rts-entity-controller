class_name RTS_Selectable extends RTS_Component

var selection: RTS_Selection

signal on_stop()
signal selected(value: bool)

@export var priority: int = 0 #determins which selectable has priority of its action being displayed, also determins camera hotkey jumping
@export var pickable: RTS_PickablePhysicsComponent 
@export var boxable: RTS_BoxableComponent

@export var selection_cone: MeshInstance3D
@export var hover_quad: MeshInstance3D

var pref_selection: MeshInstance3D
var preferred_hover: MeshInstance3D
var color : Color

func _ready():
	selection = Controls.selection
	super._ready()

	color = RTS_Entity.get_color(entity.faction)
	
	pref_selection = selection_cone
	preferred_hover = hover_quad
	
	if selection_cone:
		selection_cone.visible = false
	if hover_quad:
		hover_quad.visible = false

func _exit_tree():
	if selection:
		selection.remove_from_selection(self)
		selection.remove_from_selectables_on_screen(self)

func stop():
	on_stop.emit()

func set_component_active():
	super.set_component_active()
	entity.visible_on_screen.screen_entered.connect(on_screen_entered)
	entity.visible_on_screen.screen_exited.connect(on_screen_exited)
	#screen_entered is not always called when entity is already in scene
	#the moment the game starts, so we check manually
	if entity.visible_on_screen.is_on_screen():
		on_screen_entered()
	
	if pickable && !pickable.component_is_active:
		pickable.set_component_active()

func set_component_inactive():
	super.set_component_inactive()
	entity.visible_on_screen.screen_entered.disconnect(on_screen_entered)
	entity.visible_on_screen.screen_exited.disconnect(on_screen_exited)
	selection.remove_from_selection(self)
	selection.remove_from_selectables_on_screen(self)

	if pickable && pickable.component_is_active:
		pickable.set_component_inactive()

func is_same_type_and_faction(other: RTS_Selectable) -> bool:
	return entity.faction == other.entity.faction  && entity.id == other.entity.id

func on_screen_entered():
	selection.add_to_selectables_on_screen(self)

func on_screen_exited():
	if selection:
		selection.remove_from_selectables_on_screen(self)

func on_selected():
	if pref_selection:
		pref_selection.material_override.set_shader_parameter("color",color)
		pref_selection.visible = true
	selected.emit(true)

func on_deselected():
	if pref_selection:
		pref_selection.visible = false
	selected.emit(false)

func on_hovered():
	if hover_quad:
		hover_quad.material_override.set_shader_parameter("color",color)
		hover_quad.visible = true

func on_unhovered():
	if hover_quad:
		hover_quad.visible = false
