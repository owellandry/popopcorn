extends Node
## Sistema global para gestionar el nombre del cine
## Se guarda en user://nombre_cine.save

signal nombre_cambiado(nuevo_nombre: String)

const RUTA_GUARDADO = "user://nombre_cine.save"
const NOMBRE_DEFAULT = "CINEMA"

var nombre_cine: String = ""
var primera_vez: bool = true

func _ready() -> void:
	cargar_nombre()

func cargar_nombre() -> void:
	"""Carga el nombre del cine desde el archivo guardado"""
	if FileAccess.file_exists(RUTA_GUARDADO):
		var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
		if archivo:
			nombre_cine = archivo.get_line()
			primera_vez = false
			archivo.close()
			print("✅ Nombre del cine cargado: ", nombre_cine)
		else:
			print("⚠️ Error al abrir archivo de guardado")
			nombre_cine = NOMBRE_DEFAULT
			primera_vez = true
	else:
		print("ℹ️ Primera vez jugando - no hay nombre guardado")
		nombre_cine = NOMBRE_DEFAULT
		primera_vez = true

func guardar_nombre(nuevo_nombre: String) -> bool:
	"""Guarda el nombre del cine en un archivo"""
	if nuevo_nombre.strip_edges().is_empty():
		push_error("❌ El nombre no puede estar vacío")
		return false
	
	# Limpiar el nombre (máximo 20 caracteres, sin caracteres especiales peligrosos)
	nuevo_nombre = nuevo_nombre.strip_edges().substr(0, 20)
	
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		archivo.store_line(nuevo_nombre)
		archivo.close()
		nombre_cine = nuevo_nombre
		primera_vez = false
		nombre_cambiado.emit(nuevo_nombre)
		print("💾 Nombre del cine guardado: ", nombre_cine)
		return true
	else:
		push_error("❌ Error al guardar el nombre del cine")
		return false

func obtener_nombre() -> String:
	"""Devuelve el nombre actual del cine"""
	return nombre_cine

func es_primera_vez() -> bool:
	"""Devuelve true si es la primera vez que se juega"""
	return primera_vez

func cambiar_nombre(nuevo_nombre: String) -> bool:
	"""Cambia el nombre del cine (para uso posterior si quieres permitir cambios)"""
	return guardar_nombre(nuevo_nombre)
