extends Node3D
class_name LetreroTienda

@export var texto_abierto: String = "ABIERTO"
@export var texto_cerrado: String = "CERRADO"

const COLOR_NEON_ON := Color(0, 1, 0.45, 1)
const COLOR_NEON_OFF := Color(0.1, 0.1, 0.1, 1)

var mesh_texto: MeshInstance3D
var mesh_letras: MeshInstance3D
var luz: OmniLight3D
var material_on: StandardMaterial3D
var material_off: StandardMaterial3D

var tienda_abierta: bool = false

func _ready() -> void:
	mesh_texto = get_node_or_null("Texto")
	mesh_letras = get_node_or_null("Letras")
	luz = get_node_or_null("Luz")

	if mesh_texto:
		mesh_texto.visible = false

	_crear_materiales_neon()
	_actualizar()

func _crear_materiales_neon() -> void:
	material_on = StandardMaterial3D.new()
	material_on.albedo_color = COLOR_NEON_ON
	material_on.emission_enabled = true
	material_on.emission = COLOR_NEON_ON
	material_on.emission_energy_multiplier = 4.0
	material_on.roughness = 0.1

	material_off = StandardMaterial3D.new()
	material_off.albedo_color = COLOR_NEON_OFF
	material_off.emission_enabled = true
	material_off.emission = COLOR_NEON_OFF
	material_off.emission_energy_multiplier = 0.2

func set_tienda_abierta(abierto: bool) -> void:
	tienda_abierta = abierto
	_actualizar()

func _actualizar() -> void:
	var texto := texto_abierto if tienda_abierta else texto_cerrado

	if mesh_letras and mesh_letras.mesh is TextMesh:
		(mesh_letras.mesh as TextMesh).text = texto

	_aplicar_material(mesh_letras, tienda_abierta)
	_aplicar_material(mesh_texto, tienda_abierta)

	if luz:
		if tienda_abierta:
			luz.visible = true
			luz.light_energy = 4.0
			luz.light_color = COLOR_NEON_ON
			luz.omni_range = 10.0
		else:
			luz.light_energy = 0.15
			luz.light_color = Color(0.25, 0.25, 0.25)
			luz.omni_range = 2.0

func _aplicar_material(mesh: MeshInstance3D, encendido: bool) -> void:
	if mesh == null:
		return
	var mat := material_on if encendido else material_off
	mesh.material_override = mat
	mesh.set_surface_override_material(0, mat)