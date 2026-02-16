@tool
extends MeshInstance3D

class_name RadiusRing

@export var radius : float = 4
var mat: ShaderMaterial

@export_tool_button("Update Shader with Radius", "Callable") var action1 = update_shader

func _ready():
	if Engine.is_editor_hint():
		return
	mat = material_override as ShaderMaterial
	visible = false

func show_ring(_override_radius: float = -1):
	if _override_radius > -1:
		radius = _override_radius
	visible = true
	mat.set_shader_parameter("radius_world",radius)

func hide_ring():
	visible = false

#EDITOR ONLY
func update_shader():
	(material_override as ShaderMaterial).set_shader_parameter("radius_world",radius)
