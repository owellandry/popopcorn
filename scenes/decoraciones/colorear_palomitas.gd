extends Node3D

# Colores para asignar a cada parte de la máquina
var colores = [
	Color(0.9, 0.15, 0.15, 1),  # Rojo
	Color(0.85, 0.85, 0.85, 1), # Plateado metálico
	Color(0.2, 0.4, 0.9, 1),     # Azul
	Color(0.2, 0.8, 0.3, 1),     # Verde
	Color(0.95, 0.5, 0.1, 1),    # Naranja
	Color(0.7, 0.2, 0.9, 1),     # Morado
	Color(0.1, 0.8, 0.9, 1),     # Cyan
	Color(0.95, 0.4, 0.7, 1),    # Rosa
]

# Propiedades metálicas para cada color (metallic, roughness)
var propiedades_metalicas = [
	[0.3, 0.4],   # Rojo - normal
	[1.0, 0.15],  # Plateado - full metálico, muy pulido
	[0.4, 0.3],   # Azul - algo metálico
	[0.3, 0.4],   # Verde - normal
	[0.25, 0.45], # Naranja - normal
	[0.35, 0.35], # Morado - algo metálico
	[0.3, 0.4],   # Cyan - normal
	[0.2, 0.5],   # Rosa - normal
]

func _ready():
	# Esperar un frame para que el modelo se cargue completamente
	await get_tree().process_frame
	colorear_nodos()

func colorear_nodos():
	var modelo = get_node_or_null("Modelo")
	if not modelo:
		print("No se encontró el nodo Modelo")
		return
	
	# Obtener todos los MeshInstance3D del modelo
	var meshes = []
	buscar_meshes(modelo, meshes)
	
	print("Encontrados ", meshes.size(), " meshes en la máquina de palomitas")
	
	# Asignar un color diferente a cada mesh
	for i in range(meshes.size()):
		var mesh_instance = meshes[i]
		var color = colores[i % colores.size()]
		var props = propiedades_metalicas[i % propiedades_metalicas.size()]
		
		# Crear un nuevo material con el color
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.metallic = props[0]
		material.roughness = props[1]
		
		# FORZAR el material - limpiar todos los materiales existentes primero
		mesh_instance.material_override = null
		mesh_instance.material_overlay = null
		
		# Asignar el material al mesh
		if mesh_instance.mesh:
			var surface_count = mesh_instance.mesh.get_surface_count()
			for j in range(surface_count):
				mesh_instance.set_surface_override_material(j, material)
		
		# También usar material_override como respaldo
		mesh_instance.material_override = material
		
		print("Coloreado: ", mesh_instance.name, " con color ", color, " (metallic: ", props[0], ", roughness: ", props[1], ")")

func buscar_meshes(nodo: Node, lista: Array):
	# Si el nodo es un MeshInstance3D, agregarlo a la lista
	if nodo is MeshInstance3D:
		lista.append(nodo)
	
	# Buscar recursivamente en los hijos
	for hijo in nodo.get_children():
		buscar_meshes(hijo, lista)
