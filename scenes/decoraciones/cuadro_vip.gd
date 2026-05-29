@tool
extends Node3D

@export var poster_texture: Texture2D : set = _set_texture

@onready var _poster: MeshInstance3D = $Poster

func _set_texture(tex: Texture2D) -> void:
	poster_texture = tex
	if is_inside_tree() and _poster:
		_apply_texture()

func _ready() -> void:
	_apply_texture()

func _apply_texture() -> void:
	if poster_texture and _poster:
		var mat := _poster.get_surface_override_material(0)
		if not mat:
			mat = StandardMaterial3D.new()
			mat.albedo_color = Color(1, 1, 1, 1)
			_poster.set_surface_override_material(0, mat)
		mat.albedo_texture = poster_texture
