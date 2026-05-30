extends Node3D
## Script para el letrero de neón que muestra el nombre del cine

@export var usar_label_3d: bool = true  # Si true, usa Label3D, si false usa el mesh existente

var label_3d: Label3D

func _ready() -> void:
	# Esperar un frame para que el sistema de nombre esté listo
	await get_tree().process_frame
	
	# Conectar al sistema de nombre
	if SistemaNombreCine:
		SistemaNombreCine.nombre_cambiado.connect(_on_nombre_cambiado)
		_actualizar_nombre(SistemaNombreCine.obtener_nombre())
	else:
		push_warning("⚠️ SistemaNombreCine no está disponible como autoload")

func _actualizar_nombre(nombre: String) -> void:
	"""Actualiza el texto del letrero con el nombre del cine"""
	if usar_label_3d:
		_crear_o_actualizar_label_3d(nombre)
	else:
		_actualizar_mesh_texto(nombre)

func _crear_o_actualizar_label_3d(nombre: String) -> void:
	"""Crea o actualiza un Label3D con el nombre"""
	if not label_3d:
		# Buscar si ya existe
		label_3d = get_node_or_null("Label3D")
		
		if not label_3d:
			# Crear nuevo Label3D
			label_3d = Label3D.new()
			label_3d.name = "Label3D"
			add_child(label_3d)
			
			# Configurar propiedades
			label_3d.pixel_size = 0.01
			label_3d.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			label_3d.modulate = Color(1, 0.3, 0.3)  # Color rojo neón
			label_3d.outline_size = 8
			label_3d.outline_modulate = Color(0, 0, 0, 1)
			
			# Posicionar el texto
			label_3d.position = Vector3(0, 0, 0.05)
	
	# Actualizar el texto
	label_3d.text = nombre.to_upper()
	
	# Ajustar tamaño de fuente según longitud
	if nombre.length() <= 8:
		label_3d.font_size = 128
	elif nombre.length() <= 12:
		label_3d.font_size = 96
	elif nombre.length() <= 16:
		label_3d.font_size = 72
	else:
		label_3d.font_size = 64
	
	print("✨ Letrero actualizado: ", nombre)

func _actualizar_mesh_texto(nombre: String) -> void:
	"""Actualiza el mesh de texto existente (implementación futura)"""
	# Por ahora, usar Label3D
	_crear_o_actualizar_label_3d(nombre)

func _on_nombre_cambiado(nuevo_nombre: String) -> void:
	"""Callback cuando el nombre del cine cambia"""
	_actualizar_nombre(nuevo_nombre)
