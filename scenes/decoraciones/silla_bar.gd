@tool
extends StaticBody3D

const COLOR_PATH := "res://assets/textures/plastico_silla_bar/Plastic010_1K-JPG_Color.jpg"
const NORMAL_PATH := "res://assets/textures/plastico_silla_bar/Plastic010_1K-JPG_NormalGL.jpg"
const ROUGH_PATH := "res://assets/textures/plastico_silla_bar/Plastic010_1K-JPG_Roughness.jpg"

# Preload textures to avoid loading from disk at runtime
var normal_tex: Texture2D = preload(NORMAL_PATH)
var roughness_tex: Texture2D = preload(ROUGH_PATH)

var _modelo: Node3D

func _ready() -> void:
	_modelo = $Modelo
	_apply_texture()

func _apply_texture() -> void:
	if not _modelo:
		_modelo = $Modelo
	if not _modelo:
		return
	var mesh_inst := _find_mesh(_modelo)
	if not mesh_inst:
		return
	var mat := mesh_inst.get_surface_override_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		mesh_inst.set_surface_override_material(0, mat)
	mat.albedo_color = Color(0.0, 0.338, 0.37, 1.0)
	mat.albedo_texture = null
	mat.roughness_texture = roughness_tex
	mat.normal_enabled = true
	mat.normal_texture = normal_tex
	mat.uv1_triplanar = true

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh(child)
		if result:
			return result
	return null
