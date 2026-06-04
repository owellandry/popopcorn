@tool
extends Node3D

var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _is_walking := false

func _ready():
	call_deferred("_setup")

func _setup():
	_aplicar_mate()
	if Engine.is_editor_hint():
		return
	_anim_player = $AnimationPlayer
	if not _anim_player:
		return
	for child in find_children("*", "Skeleton3D", true, false):
		_skeleton = child
		break
	if _skeleton:
		_anim_player.root_node = _skeleton.get_path()

func _aplicar_mate():
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var mesh_copy := mi.mesh.duplicate()
		if mesh_copy is Mesh:
			mi.mesh = mesh_copy
		for surf in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(surf)
			var nuevo := StandardMaterial3D.new()
			if mat and mat is StandardMaterial3D:
				nuevo.albedo_texture = mat.albedo_texture
			nuevo.roughness = 1.0
			nuevo.metallic = 0.0
			mi.mesh.surface_set_material(surf, nuevo)

func set_wandering(walking: bool):
	if walking == _is_walking or not _anim_player:
		return
	_is_walking = walking
	if walking:
		if _anim_player.has_animation("walk"):
			_anim_player.play("walk")
	else:
		if _anim_player.has_animation("walk_stop"):
			_anim_player.play("walk_stop")
		else:
			_anim_player.stop()
