extends Node3D

var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _is_walking := false
var _is_sitting := false
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
			_anim_player.root_node = _anim_player.get_path_to(_skeleton)
		_corregir_animaciones()
	_aplicar_mate()
	_setup_done = true
	if _is_walking:
		_is_walking = false
		set_wandering(true)
	elif _anim_player and _anim_player.has_animation("Standing"):
		_anim_player.play("Standing")

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
	var lib_original = load("res://assets/animations/nuevas/npc_animaciones_nuevas.tres") as AnimationLibrary
	if not lib_original:
		return
	var lib_nueva := AnimationLibrary.new()
	for anim_name in lib_original.get_animation_list():
		var anim_original := lib_original.get_animation(anim_name)
		if not anim_original:
			continue
		var anim := anim_original.duplicate(true) as Animation
		_renombrar_tracks_animacion(anim)
		_corregir_rotacion_caderas(anim, anim_name)
		if anim_name in ["Walking", "Standing", "Sitting_Idle"]:
			anim.loop_mode = Animation.LOOP_LINEAR
		else:
			anim.loop_mode = Animation.LOOP_NONE
		lib_nueva.add_animation(anim_name, anim)
	if _anim_player.has_animation_library(&""):
		_anim_player.remove_animation_library(&"")
	_anim_player.add_animation_library(&"", lib_nueva)

func _renombrar_tracks_animacion(anim: Animation):
	for i in range(anim.get_track_count()):
		var path_str := str(anim.track_get_path(i))
		if path_str.begins_with("Skeleton3D:"):
			path_str = ":" + path_str.substr("Skeleton3D:".length())
		var idx := path_str.find("mixamorig")
		if idx >= 0:
			var prefix_end := idx + len("mixamorig")
			while prefix_end < path_str.length() and path_str[prefix_end] >= "0" and path_str[prefix_end] <= "9":
				prefix_end += 1
			path_str = path_str.substr(0, idx) + "mixamorig9" + path_str.substr(prefix_end)
		anim.track_set_path(i, path_str)

func _corregir_rotacion_caderas(anim: Animation, anim_name: String = ""):
	var es_looped := anim_name in ["Walking", "Standing", "Sitting_Idle"]
	for i in range(anim.get_track_count()):
		var path_str := str(anim.track_get_path(i))
		if not path_str.ends_with("mixamorig9_Hips"):
			continue
		if anim.track_get_key_count(i) == 0:
			continue
		match anim.track_get_type(i):
			Animation.TYPE_POSITION_3D:
				for k in range(anim.track_get_key_count(i)):
					var pos: Vector3 = anim.track_get_key_value(i, k)
					pos *= 100.0
					if es_looped:
						pos.x = 0.0
						pos.z = 0.0
					anim.track_set_key_value(i, k, pos)
			Animation.TYPE_ROTATION_3D:
				var q_first := anim.track_get_key_value(i, 0) as Quaternion
				var q_inv := q_first.inverse()
				for k in range(anim.track_get_key_count(i)):
					var q := anim.track_get_key_value(i, k) as Quaternion
					anim.track_set_key_value(i, k, q_inv * q)

func set_wandering(walking: bool):
	if walking == _is_walking:
		return
	_is_walking = walking
	_is_sitting = false
	if not _anim_player or not _setup_done:
		return
	
	if walking:
		if _anim_player.current_animation == "Sit_To_Stand":
			if _anim_player.has_animation("Walking"):
				_anim_player.queue("Walking")
		else:
			_anim_player.clear_queue()
			if _anim_player.has_animation("Walking"):
				_anim_player.play("Walking")
	else:
		if _anim_player.current_animation == "Sit_To_Stand" or _anim_player.current_animation == "Stand_To_Sit":
			if _anim_player.has_animation("Standing"):
				_anim_player.queue("Standing")
		else:
			_anim_player.clear_queue()
			if _anim_player.has_animation("Standing"):
				_anim_player.play("Standing")

func play_stand_to_sit():
	if not _anim_player or not _setup_done:
		return
	_is_sitting = true
	_is_walking = false
	_anim_player.clear_queue()
	if _anim_player.has_animation("Stand_To_Sit"):
		_anim_player.play("Stand_To_Sit")
		if _anim_player.has_animation("Sitting_Idle"):
			_anim_player.queue("Sitting_Idle")

func play_sitting_idle():
	if not _anim_player or not _setup_done:
		return
	_anim_player.clear_queue()
	if _anim_player.has_animation("Sitting_Idle"):
		_anim_player.play("Sitting_Idle")

func play_sit_to_stand():
	if not _anim_player or not _setup_done:
		return
	_is_sitting = false
	_anim_player.clear_queue()
	if _anim_player.has_animation("Sit_To_Stand"):
		_anim_player.play("Sit_To_Stand")
