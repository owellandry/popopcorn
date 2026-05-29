extends Node3D

func _ready() -> void:
	# Solo realizamos la fusión en tiempo de ejecución (cuando el juego está corriendo).
	# En el editor no se ejecuta este script (ya que no tiene @tool),
	# por lo que podrás seguir viendo, moviendo y editando cada objeto de forma individual.
	_merge_children_to_multimesh()

func _merge_children_to_multimesh() -> void:
	var items: Array[Dictionary] = []
	var shared_mesh: Mesh = null
	var material: Material = null
	
	# 1. Recorrer los hijos directos para buscar sus mallas y guardar referencias
	for child in get_children():
		if child is Node3D:
			var mesh_instance = _find_mesh_instance(child)
			if mesh_instance and mesh_instance.mesh:
				if not shared_mesh:
					shared_mesh = mesh_instance.mesh
					# Intentar obtener el material override
					material = mesh_instance.material_override
					if not material and mesh_instance.get_surface_override_material_count() > 0:
						material = mesh_instance.get_surface_override_material(0)
				items.append({
					"child": child,
					"mesh_instance": mesh_instance
				})
				
	if items.is_empty() or not shared_mesh:
		return
		
	# 2. Crear y configurar el MultiMeshInstance3D
	var multimesh_instance := MultiMeshInstance3D.new()
	multimesh_instance.name = "MultiMeshOptimizado"
	
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = shared_mesh
	multimesh.instance_count = items.size()
	
	# Aplicar el material override si existía
	if material:
		multimesh_instance.material_override = material
		
	# 3. Copiar las transformaciones relativas reales de las mallas (resolviendo escalas internas de .tscn y .glb)
	var inv_self_global := global_transform.affine_inverse()
	for i in range(items.size()):
		var item = items[i]
		var mesh_inst: MeshInstance3D = item["mesh_instance"]
		# Calculamos el transform relativo de la malla con respecto a esta raíz
		var relative_transform = inv_self_global * mesh_inst.global_transform
		multimesh.set_instance_transform(i, relative_transform)
		
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)
	
	# 4. Eliminar los nodos hijos individuales para liberar memoria y reducir draw calls
	for item in items:
		item["child"].queue_free()

# Función auxiliar recursiva para encontrar el primer MeshInstance3D de un nodo (.glb)
func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null
