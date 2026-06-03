extends Node
## Sistema global para gestionar menús y prevenir múltiples abiertos

var menu_abierto: Control = null
var jugador_bloqueado: bool = false

func abrir_menu(menu: Control) -> bool:
	"""
	Intenta abrir un menú. Retorna true si se pudo abrir, false si ya hay uno abierto.
	"""
	if menu_abierto != null:
		push_warning("⚠️ Ya hay un menú abierto, no se puede abrir otro")
		return false
	
	menu_abierto = menu
	_bloquear_jugador()
	print("📋 Menú abierto: ", menu.name)
	return true

func cerrar_menu() -> void:
	"""
	Cierra el menú actual y desbloquea al jugador.
	"""
	if menu_abierto:
		print("📋 Menú cerrado: ", menu_abierto.name)
		menu_abierto = null
	
	_desbloquear_jugador()

func hay_menu_abierto() -> bool:
	"""
	Retorna true si hay un menú abierto.
	"""
	return menu_abierto != null

func _bloquear_jugador() -> void:
	"""
	Bloquea los controles del jugador.
	"""
	if jugador_bloqueado:
		return
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_input(false)
		jugador_bloqueado = true
		print("🔒 Jugador bloqueado")

func _desbloquear_jugador() -> void:
	"""
	Desbloquea los controles del jugador.
	"""
	if not jugador_bloqueado:
		return
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
		jugador_bloqueado = false
		print("🔓 Jugador desbloqueado")
