@tool
extends Node3D

@export var poster_texture: Texture2D : set = _set_texture

func _set_texture(tex: Texture2D) -> void:
	poster_texture = tex
	if is_inside_tree():
		_apply_texture()

func _ready() -> void:
	_apply_texture()

func _apply_texture() -> void:
	var poster_mesh := $Poster as MeshInstance3D
	if poster_texture and poster_mesh:
		var mat := poster_mesh.get_surface_override_material(0)
		if not mat:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1, 1, 1, 1)
			poster_mesh.set_surface_override_material(0, mat)
		mat.albedo_texture = poster_texture
