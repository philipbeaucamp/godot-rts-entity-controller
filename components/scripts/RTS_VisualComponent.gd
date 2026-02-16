class_name RTS_VisualComponent extends RTS_Component

@export var meshes : Array[MeshInstance3D] = []
@export var flash_time = 0.05

var mats : Array[StandardMaterial3D] = []
var timer: SceneTreeTimer
var albedo_color: Color

func _ready():
	super._ready()
	for mesh in meshes:
		var material : Material = mesh.material_override
		if material == null:
			material = mesh.get_surface_override_material(0)
		if material == null:
			material = mesh.get_active_material(0)
		if material != null && material is StandardMaterial3D:
			mats.append(material)
			material.emission = Color.WHITE
			material.emission_energy_multiplier = 0.0

	if entity.health != null:
		entity.health.health_damaged.connect(on_health_damaged)

func on_health_damaged(_health: RTS_HealthComponent):
	if mats.is_empty() || timer != null:
		return

	for mat in mats:
		mat.emission_energy_multiplier = 1.0

	timer = get_tree().create_timer(flash_time)
	timer.timeout.connect(on_timeout)	
		
func set_color(color: Color):
	for mat in mats:
		mat.albedo_color = color

func revert_color():
	for mat in mats:
		mat.albedo_color = albedo_color

func overwrite_material(material: Material):
	for mesh in meshes:
		mesh.material_override = material # set_surface_override_material(0,material)

func revert_material():
	for i in range(meshes.size()):
		meshes[i].material_override = mats[i]
		
func on_timeout():
	for mat in mats:
		# mat.emission_enabled = false
		mat.emission_energy_multiplier = 0.0
	timer = null

	
