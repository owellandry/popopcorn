@tool
extends Node3D

var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _is_walking := false
var _setup_done := false

func _ready():
	call_deferred("_setup")

func _setup():
	_anim_player = $AnimationPlayer
	if _anim_player:
		for child in find_children("*", "Skeleton3D", true, false):
			_skeleton = child
			break
		if _skeleton:
			_renombrar_huesos_a_mixamorig9()
			_anim_player.root_node = _skeleton.get_path()
		_corregir_animaciones()
	_aplicar_mate()
	if Engine.is_editor_hint():
		return
	_setup_done = true
	if _is_walking:
		_is_walking = false
		set_wandering(true)

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

func _renombrar_huesos_a_mixamorig9():
	if not _skeleton:
		return
	_renombrar_skin_binds()
	for i in range(_skeleton.get_bone_count()):
		var original := _skeleton.get_bone_name(i)
		if original.begins_with("mixamorig") and not original.begins_with("mixamorig9"):
			var rest := original.trim_prefix("mixamorig")
			var digitos := 0
			while digitos < rest.length() and rest[digitos] >= "0" and rest[digitos] <= "9":
				digitos += 1
			var sufijo := rest.substr(digitos)
			_skeleton.set_bone_name(i, "mixamorig9" + sufijo)

func _renombrar_skin_binds():
	var mesh_instances := find_children("*", "MeshInstance3D", true, false)
	for m in mesh_instances:
		var mi := m as MeshInstance3D
		if not mi or not mi.skin:
			continue
		var skin: Skin = mi.skin.duplicate()
		var modified := false
		for j in range(skin.get_bind_count()):
			var nombre: String = skin.get_bind_name(j)
			if nombre.is_empty():
				continue
			if nombre.begins_with("mixamorig") and not nombre.begins_with("mixamorig9"):
				var rest: String = nombre.trim_prefix("mixamorig")
				var digitos := 0
				while digitos < rest.length() and rest[digitos] >= "0" and rest[digitos] <= "9":
					digitos += 1
				var sufijo: String = rest.substr(digitos)
				skin.set_bind_name(j, "mixamorig9" + sufijo)
				modified = true
		if modified:
			mi.skin = skin

func _corregir_animaciones():
	var lib_original = _anim_player.get_animation_library(&"")
	if not lib_original:
		return
	var lib_nueva = AnimationLibrary.new()
	for anim_name in ["walk_start", "walk", "walk_stop"]:
		if not lib_original.has_animation(anim_name):
			continue
		var anim: Animation = lib_original.get_animation(anim_name).duplicate()
		_corregir_rotacion_caderas(anim)
		match anim_name:
			"walk":
				anim.loop_mode = Animation.LOOP_LINEAR
			_:
				anim.loop_mode = Animation.LOOP_NONE
		lib_nueva.add_animation(anim_name, anim)
	_anim_player.remove_animation_library(&"")
	_anim_player.add_animation_library(&"", lib_nueva)

func _corregir_rotacion_caderas(anim: Animation):
	for i in range(anim.get_track_count()):
		var path = anim.track_get_path(i)
		if str(path).ends_with("mixamorig9_Hips") and anim.track_get_key_count(i) > 0:
			var val = anim.track_get_key_value(i, 0)
			if typeof(val) == TYPE_QUATERNION and not (val as Quaternion).is_equal_approx(Quaternion.IDENTITY):
				var q_first: Quaternion = val
				for k in range(anim.track_get_key_count(i)):
					var q: Quaternion = anim.track_get_key_value(i, k)
					anim.track_set_key_value(i, k, q_first.inverse() * q)
			break

func set_wandering(walking: bool):
	if walking == _is_walking:
		return
	_is_walking = walking
	if not _anim_player or not _setup_done:
		return
	_anim_player.clear_queue()
	if walking:
		if _anim_player.has_animation("walk_start"):
			_anim_player.play("walk_start")
			if _anim_player.has_animation("walk"):
				_anim_player.queue("walk")
		elif _anim_player.has_animation("walk"):
			_anim_player.play("walk")
	else:
		if _anim_player.has_animation("walk_stop"):
			_anim_player.play("walk_stop")
		else:
			_anim_player.stop()
