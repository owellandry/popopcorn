extends Node
## Gestor de inicio del juego - Muestra el diálogo de nombre si es primera vez

const DIALOGO_NOMBRE = preload("res://scenes/ui/dialogo_nombre_cine.tscn")

func _ready() -> void:
	# Esperar a que la escena esté completamente cargada
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Verificar si es primera vez
	if SistemaNombreCine and SistemaNombreCine.es_primera_vez():
		_mostrar_dialogo_nombre()

func _mostrar_dialogo_nombre() -> void:
	"""Muestra el diálogo para pedir el nombre del cine"""
	print("🎬 Primera vez jugando - mostrando diálogo de nombre")
	
	# Instanciar el diálogo
	var dialogo = DIALOGO_NOMBRE.instantiate()
	
	# Conectar la señal de confirmación
	dialogo.nombre_confirmado.connect(_on_nombre_confirmado)
	
	# Agregar a la escena
	get_tree().root.add_child(dialogo)

func _on_nombre_confirmado(nombre: String) -> void:
	"""Callback cuando el jugador confirma el nombre"""
	print("✅ Nombre confirmado: ", nombre)
	
	# Guardar el nombre
	if SistemaNombreCine:
		SistemaNombreCine.guardar_nombre(nombre)
