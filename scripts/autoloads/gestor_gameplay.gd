extends Node

signal hora_actualizada(hora: int, minuto: int, progreso: float)
signal tienda_estado_cambiado(abierta: bool)
signal condiciones_clientes_cambiadas(pueden_llegar: bool)

const HORA_INICIO_DIA: int = 8
const HORA_FIN_CLIENTES: int = 21
const PROGRESO_8AM: float = 0.3333
const PROGRESO_9PM: float = 0.875
const DURACION_DIA_SEGUNDOS: float = 1440.0
const SEGUNDOS_POR_HORA_JUEGO: float = 60.0

var tienda_abierta: bool = false
var progreso_tiempo: float = PROGRESO_8AM
var tiempo_pausado: bool = false
var _pueden_clientes_cache: bool = false
var _ultimo_minuto_juego: int = -1

func _ready() -> void:
	call_deferred("_iniciar_jornada")

func _iniciar_jornada() -> void:
	while true:
		if get_tree().get_first_node_in_group("sol_ciclo"):
			iniciar_pausa_manana()
			return
		await get_tree().process_frame

func actualizar_tiempo(progreso: float) -> void:
	progreso_tiempo = progreso
	var minuto_total := int(fposmod(progreso, 1.0) * 1440.0)
	if minuto_total != _ultimo_minuto_juego:
		_ultimo_minuto_juego = minuto_total
		_emitir_hora()
		_emitir_condiciones_clientes()

func _emitir_hora() -> void:
	var hm := progreso_a_hora_minuto(progreso_tiempo)
	hora_actualizada.emit(hm.hora, hm.minuto, progreso_tiempo)

func progreso_a_hora_minuto(progreso: float) -> Dictionary:
	var minutos_totales := int(fposmod(progreso, 1.0) * 1440.0)
	return {"hora": int(minutos_totales / 60.0), "minuto": minutos_totales % 60}

func obtener_hora() -> int:
	return progreso_a_hora_minuto(progreso_tiempo).hora

func obtener_minuto() -> int:
	return progreso_a_hora_minuto(progreso_tiempo).minuto

func obtener_texto_hora() -> String:
	var hm := progreso_a_hora_minuto(progreso_tiempo)
	return "%02d:%02d" % [hm.hora, hm.minuto]

func es_despues_de_las_9pm() -> bool:
	return obtener_hora() >= HORA_FIN_CLIENTES

func set_tienda_abierta(abierta: bool) -> void:
	if tienda_abierta == abierta:
		print("[Gestor] set_tienda(%s) IGNORADO, ya=%s" % [abierta, tienda_abierta])
		return
	tienda_abierta = abierta
	print("[Gestor] set_tienda(%s)" % [abierta])
	tienda_estado_cambiado.emit(abierta)
	_emitir_condiciones_clientes()
	_intentar_reanudar()

func alguna_puerta_entrada_abierta() -> bool:
	var puertas := get_tree().get_nodes_in_group("puerta_entrada_tienda")
	if puertas.is_empty():
		return false
	for p in puertas:
		if p.has_method("esta_abierta") and p.esta_abierta():
			return true
	return false

func todas_puertas_entrada_abiertas() -> bool:
	var puertas := get_tree().get_nodes_in_group("puerta_entrada_tienda")
	if puertas.is_empty():
		return false
	for p in puertas:
		if p.has_method("esta_abierta") and not p.esta_abierta():
			return false
	return true

func todas_puertas_entrada_cerradas() -> bool:
	var puertas := get_tree().get_nodes_in_group("puerta_entrada_tienda")
	if puertas.is_empty():
		return true
	for p in puertas:
		if p.has_method("esta_abierta") and p.esta_abierta():
			return false
	return true

func notificar_puerta_entrada_cambiada() -> void:
	print("[Gestor] notificar_puerta_entrada_cambiada()")
	_intentar_reanudar()

func iniciar_pausa_manana() -> void:
	print("[Gestor] iniciar_pausa_manana()")
	tiempo_pausado = true
	progreso_tiempo = PROGRESO_8AM
	_ultimo_minuto_juego = -1
	var sol := get_tree().get_first_node_in_group("sol_ciclo")
	if sol:
		sol.progreso_normalizado = PROGRESO_8AM
		sol.ciclo_automatico = false
		if sol.has_method("actualizar_ciclo"):
			sol.actualizar_ciclo()
	_emitir_hora()
	_emitir_condiciones_clientes()

func _intentar_reanudar() -> void:
	print("[Gestor] _reanudar → pausado=%s tienda=%s puertas=%s" % [tiempo_pausado, tienda_abierta, alguna_puerta_entrada_abierta()])
	if not tiempo_pausado:
		return
	if not tienda_abierta or not alguna_puerta_entrada_abierta():
		return
	tiempo_pausado = false
	var sol := get_tree().get_first_node_in_group("sol_ciclo")
	if sol:
		sol.ciclo_automatico = true
		print("[Gestor] TIEMPO REANUDADO! sol.ciclo_automatico=true")
	_emitir_condiciones_clientes()

func _emitir_condiciones_clientes() -> void:
	var pueden := pueden_llegar_clientes()
	if pueden == _pueden_clientes_cache:
		return
	_pueden_clientes_cache = pueden
	print("[Gestor] condiciones_clientes: pueden=%s" % [pueden])
	condiciones_clientes_cambiadas.emit(pueden)

func pueden_llegar_clientes() -> bool:
	if tiempo_pausado:
		return false
	return tienda_abierta and alguna_puerta_entrada_abierta() and not es_despues_de_las_9pm()

func puede_abrir_tienda() -> bool:
	return not es_despues_de_las_9pm()

func puede_dormir() -> bool:
	return es_despues_de_las_9pm() and not tienda_abierta and todas_puertas_entrada_cerradas()

func mensaje_no_puede_dormir() -> String:
	if not es_despues_de_las_9pm():
		return "Aún no es hora de dormir (cierra a las 21:00)."
	if tienda_abierta:
		return "Apaga el cartel y cierra la tienda antes de dormir."
	if not todas_puertas_entrada_cerradas():
		return "Cierra las puertas de entrada antes de dormir."
	return "No puedes dormir ahora."

func mensaje_no_puede_abrir_tienda() -> String:
	return "Son más de las 21:00. Ya no puedes abrir la tienda."
