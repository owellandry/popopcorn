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
var _id_animacion: int = 0
var _escala_base: Vector3 = Vector3.ONE
var _ancho_mundo_objetivo: float = 0.0

func _ready() -> void:
	mesh_texto = get_node_or_null("Texto")
	mesh_letras = get_node_or_null("Letras")
	luz = get_node_or_null("Luz")

	if mesh_texto:
		mesh_texto.visible = false

	if mesh_letras and mesh_letras.mesh is TextMesh:
		var tm := mesh_letras.mesh as TextMesh
		tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_escala_base = mesh_letras.scale
		var ancho_abierto := _medir_ancho_mesh(texto_abierto)
		var ancho_cerrado := _medir_ancho_mesh(texto_cerrado)
		var ancho_max := maxf(ancho_abierto, ancho_cerrado)
		_ancho_mundo_objetivo = ancho_max * _escala_base.x

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
	_id_animacion += 1
	var id := _id_animacion
	_actualizar_texto()
	_animar_parpadeo(abierto, id)

func _medir_ancho_mesh(texto: String) -> float:
	if mesh_letras == null or mesh_letras.mesh == null:
		return 1.0
	var ref := mesh_letras.mesh as TextMesh
	var tm := TextMesh.new()
	tm.font = ref.font
	tm.font_size = ref.font_size
	tm.depth = ref.depth
	tm.horizontal_alignment = ref.horizontal_alignment
	tm.text = texto
	var temp := MeshInstance3D.new()
	temp.mesh = tm
	return temp.get_aabb().size.x

func _ajustar_escala_texto(texto: String) -> void:
	if mesh_letras == null or _ancho_mundo_objetivo <= 0.0:
		return
	var ancho := _medir_ancho_mesh(texto)
	if ancho <= 0.001:
		return
	mesh_letras.scale = Vector3(
		_ancho_mundo_objetivo / ancho,
		_escala_base.y,
		_escala_base.z
	)

func _actualizar_texto() -> void:
	var texto := texto_abierto if tienda_abierta else texto_cerrado
	if mesh_letras and mesh_letras.mesh is TextMesh:
		(mesh_letras.mesh as TextMesh).text = texto
		_ajustar_escala_texto(texto)

func _animar_parpadeo(encender: bool, id: int) -> void:
	var pasos: Array[Vector2]
	if encender:
		pasos = [
			Vector2(0.0, 0.04), Vector2(1.0, 0.07), Vector2(0.0, 0.03),
			Vector2(0.45, 0.05), Vector2(0.0, 0.025), Vector2(0.75, 0.06),
			Vector2(0.15, 0.04), Vector2(1.0, 0.09),
		]
	else:
		pasos = [
			Vector2(0.65, 0.05), Vector2(0.2, 0.04), Vector2(0.8, 0.03),
			Vector2(0.3, 0.05), Vector2(0.55, 0.04), Vector2(0.1, 0.05),
			Vector2(0.4, 0.03), Vector2(0.0, 0.1),
		]

	for paso in pasos:
		if id != _id_animacion:
			return
		_aplicar_brillo(paso.x)
		await get_tree().create_timer(paso.y).timeout

	if id != _id_animacion:
		return
	_actualizar()

func _aplicar_brillo(intensidad: float) -> void:
	var t := clampf(intensidad, 0.0, 1.0)
	var color := COLOR_NEON_OFF.lerp(COLOR_NEON_ON, t)
	var emission := lerpf(0.2, 4.0, t)

	for mesh in [mesh_letras, mesh_texto]:
		if mesh == null:
			continue
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
		mat.roughness = 0.1
		mesh.material_override = mat
		mesh.set_surface_override_material(0, mat)

	if luz:
		luz.visible = t > 0.02
		luz.light_energy = lerpf(0.15, 4.0, t)
		luz.light_color = color.lerp(Color(0.25, 0.25, 0.25), 1.0 - t)
		luz.omni_range = lerpf(2.0, 10.0, t)

func _actualizar() -> void:
	_actualizar_texto()
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