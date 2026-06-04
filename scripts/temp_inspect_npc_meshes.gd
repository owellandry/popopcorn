extends SceneTree

func _init() -> void:
	inspect_scene("res://assets/models/npc/juan.tscn")
	inspect_scene("res://assets/models/npc/antonio.tscn")
	quit()

func inspect_scene(path: String) -> void:
	print("=== ", path, " ===")
	var packed := load(path) as PackedScene
	if packed == null:
		print("Failed to load scene")
		return
	var root := packed.instantiate()
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		print("MeshInstance: ", mi.name)
		print("  mesh class: ", mi.mesh.get_class())
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var idx: Variant = arrays[Mesh.ARRAY_INDEX]
			var vtx: Variant = arrays[Mesh.ARRAY_VERTEX]
			var idx_count := 0
			var vtx_count := 0
			if idx is PackedInt32Array:
				idx_count = idx.size()
			elif idx is PackedInt64Array:
				idx_count = idx.size()
			if vtx is PackedVector3Array:
				vtx_count = vtx.size()
			var prim: int = mi.mesh.surface_get_primitive_type(s)
			print("  surface ", s, ": prim=", prim, " vtx=", vtx_count, " idx=", idx_count)
