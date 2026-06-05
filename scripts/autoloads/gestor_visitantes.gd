extends Node

const VisitanteScript := preload("res://scripts/components/visitante.gd")
const PuntoVisitanteScript := preload("res://scripts/components/punto_visitante.gd")
const MuebleSentarseScript := preload("res://scripts/components/mueble_sentarse.gd")

const PELICULAS := [
	"La Aventura Espacial", "El Gran Heist", "Historia de Amor", "Terror Nocturno", "Comedia de los 80s",
]
const COLORES := [
	Color(0.9, 0.2, 0.2), Color(0.2, 0.9, 0.3), Color(0.2, 0.3, 0.9),
	Color(0.9, 0.9, 0.2), Color(0.9, 0.2, 0.9), Color(0.3, 0.8, 0.8),
]

@export var intervalo_min: float = 10.0
@export var intervalo_max: float = 35.0
@export var max_visitantes_activos: int = 10

var _visitantes_activos: Array = []
var _puntos_por_tipo: Dictionary = {}
var _spawn_programado := false
var _indice_color := 0

var _pesos_arquetipo: Dictionary = {}

func _ready() -> void:
	_pesos_arquetipo = {
		VisitanteScript.Arquetipo.CLIENTE_LEGAL: 35,
		VisitanteScript.Arquetipo.EXPLORADOR: 20,
		VisitanteScript.Arquetipo.OCIO_LOBBY: 15,
		VisitanteScript.Arquetipo.PAREJA: 12,
		VisitanteScript.Arquetipo.COLADO: 8,
		VisitanteScript.Arquetipo.LADRON: 5,
		VisitanteScript.Arquetipo.PIRATA_FILM: 5,
	}
	get_tree().scene_changed.connect(_on_escena_cambiada)
	call_deferred("_inicializar")
	if GestorGameplay:
		GestorGameplay.condiciones_clientes_cambiadas.connect(_on_condiciones_cambiadas)

func _on_escena_cambiada() -> void:
	call_deferred("_recolectar_puntos")
	call_deferred("_configurar_salas_cine")

func _inicializar() -> void:
	while get_tree().current_scene == null:
		await get_tree().process_frame
	if get_tree().current_scene:
		if not get_tree().current_scene.is_node_ready():
			await get_tree().current_scene.ready
	_recolectar_puntos()
	_configurar_salas_cine()
	if GestorGameplay and GestorGameplay.pueden_llegar_clientes():
		_intentar_spawn()
	_programar_siguiente_spawn()

func _configurar_salas_cine() -> void:
	var raiz := get_tree().current_scene
	if raiz:
		_configurar_salas_recursivo(raiz)

func _configurar_salas_recursivo(nodo: Node) -> void:
	if nodo.get_node_or_null("Butacas") != null:
		var num := _numero_sala_desde_nombre(nodo.name)
		if not nodo.is_in_group("sala_cine"):
			if nodo.get_script() == null:
				nodo.set_script(preload("res://scripts/components/sala_cine.gd"))
			if num > 0:
				nodo.set("numero_sala", num)
			nodo.add_to_group("sala_cine")
		if nodo.has_method("_configurar_butacas"):
			nodo.call_deferred("_configurar_butacas")
	for hijo in nodo.get_children():
		_configurar_salas_recursivo(hijo)

func _numero_sala_desde_nombre(nombre: String) -> int:
	var digits := ""
	for c in nombre:
		if c.is_valid_int():
			digits += c
	if digits.is_empty():
		return 0
	return int(digits)

func _recolectar_puntos() -> void:
	_puntos_por_tipo.clear()
	for tipo in PuntoVisitanteScript.Tipo.values():
		_puntos_por_tipo[tipo] = []
	for n in get_tree().get_nodes_in_group("punto_visitante"):
		if n is PuntoVisitante:
			_puntos_por_tipo[n.tipo].append(n)

func _on_condiciones_cambiadas(pueden: bool) -> void:
	_spawn_programado = false
	if pueden:
		_recolectar_puntos()
		_intentar_spawn()
		_programar_siguiente_spawn()

func _programar_siguiente_spawn() -> void:
	if _spawn_programado:
		return
	_spawn_programado = true
	var espera := randf_range(intervalo_min, intervalo_max)
	get_tree().create_timer(espera).timeout.connect(_on_timer_spawn)

func _on_timer_spawn() -> void:
	_spawn_programado = false
	_intentar_spawn()
	if GestorGameplay and GestorGameplay.pueden_llegar_clientes():
		_programar_siguiente_spawn()

func _intentar_spawn() -> void:
	if not GestorGameplay or not GestorGameplay.pueden_llegar_clientes():
		return
	if _puntos_por_tipo.is_empty():
		_recolectar_puntos()
	var spawns: Array = _puntos_por_tipo.get(PuntoVisitanteScript.Tipo.SPAWN_EXTERIOR, [])
	if spawns.is_empty():
		return
	var arquetipo: VisitanteScript.Arquetipo = _elegir_arquetipo()
	if arquetipo == VisitanteScript.Arquetipo.PAREJA:
		if _visitantes_activos.size() + 2 > max_visitantes_activos:
			return
		_spawn_pareja(spawns)
	else:
		if _visitantes_activos.size() >= max_visitantes_activos:
			return
		_spawn_visitante(arquetipo, spawns.pick_random(), null)

func _elegir_arquetipo() -> VisitanteScript.Arquetipo:
	var total := 0
	for k in _pesos_arquetipo:
		total += _pesos_arquetipo[k]
	var r := randi_range(1, total)
	var acum := 0
	for k in _pesos_arquetipo:
		acum += _pesos_arquetipo[k]
		if r <= acum:
			return k
	return VisitanteScript.Arquetipo.CLIENTE_LEGAL

func _spawn_pareja(spawns: Array) -> void:
	var spawn = spawns.pick_random()
	var offset := Vector3(0.6, 0, 0)
	var v1: Visitante = _crear_visitante(VisitanteScript.Arquetipo.PAREJA, spawn.global_position, null)
	var v2: Visitante = _crear_visitante(VisitanteScript.Arquetipo.PAREJA, spawn.global_position + offset, null)
	v1.partner = v2
	v2.partner = v1
	var rutas := _construir_rutas_pareja(v1, v2)
	v1.iniciar_recorrido(rutas.ruta1)
	v2.iniciar_recorrido(rutas.ruta2)

func _spawn_visitante(arquetipo: VisitanteScript.Arquetipo, spawn: Node3D, pareja: Visitante) -> void:
	var v: Visitante = _crear_visitante(arquetipo, spawn.global_position, pareja)
	v.iniciar_recorrido(_construir_ruta(arquetipo, v))

func _crear_visitante(arquetipo: VisitanteScript.Arquetipo, pos: Vector3, pareja: Visitante) -> Visitante:
	var escena := load("res://scenes/jugabilidad/visitante.tscn") as PackedScene
	var v: Visitante = escena.instantiate()
	var color: Color = COLORES[_indice_color % COLORES.size()]
	_indice_color += 1
	var pelicula: String = PELICULAS[_indice_color % PELICULAS.size()]
	v.configurar(arquetipo, color, pelicula, (_indice_color % 4) + 1, pareja)
	var contenedor := get_tree().get_first_node_in_group("contenedor_visitantes")
	if contenedor:
		contenedor.add_child(v)
	else:
		get_tree().current_scene.add_child(v)
	v.global_position = pos
	_visitantes_activos.append(v)
	return v

func _construir_rutas_pareja(v1: Visitante, v2: Visitante) -> Dictionary:
	var ruta1 := _construir_ruta(VisitanteScript.Arquetipo.PAREJA, v1, v2)
	var ruta2: Array[Vector3] = []
	if v2.destino_sentado and not v2.pose_sentado.is_empty():
		ruta2 = _ruta_hacia_posicion(v2.pose_sentado.posicion)
	else:
		var offset := Vector3(0.6, 0, 0)
		for p in ruta1:
			ruta2.append(p + offset)
	return {"ruta1": ruta1, "ruta2": ruta2}

func _construir_ruta(arquetipo: VisitanteScript.Arquetipo, visitante: Visitante = null, pareja_reserva: Visitante = null) -> Array[Vector3]:
	var ruta: Array[Vector3] = []
	var puerta := _pos_aleatoria(PuntoVisitanteScript.Tipo.PUERTA_ENTRADA)
	if puerta != Vector3.ZERO:
		ruta.append(puerta)
	var destino_tipo: PuntoVisitanteScript.Tipo = PuntoVisitanteScript.Tipo.FILA
	match arquetipo:
		VisitanteScript.Arquetipo.CLIENTE_LEGAL:
			destino_tipo = PuntoVisitanteScript.Tipo.FILA
		VisitanteScript.Arquetipo.EXPLORADOR:
			destino_tipo = PuntoVisitanteScript.Tipo.PASILLO_SALAS
		VisitanteScript.Arquetipo.OCIO_LOBBY:
			var ocio_roll := randf()
			if ocio_roll < 0.35:
				destino_tipo = PuntoVisitanteScript.Tipo.BANCA
			elif ocio_roll < 0.7:
				destino_tipo = PuntoVisitanteScript.Tipo.MESA
			else:
				destino_tipo = PuntoVisitanteScript.Tipo.BANO
		VisitanteScript.Arquetipo.PAREJA:
			var roll_pareja := randf()
			if roll_pareja < 0.28:
				destino_tipo = PuntoVisitanteScript.Tipo.ZONA_PAREJA
			elif roll_pareja < 0.55:
				destino_tipo = PuntoVisitanteScript.Tipo.BANCA
			else:
				destino_tipo = PuntoVisitanteScript.Tipo.MESA
		VisitanteScript.Arquetipo.COLADO:
			destino_tipo = PuntoVisitanteScript.Tipo.ZONA_COLADO
		VisitanteScript.Arquetipo.LADRON:
			destino_tipo = PuntoVisitanteScript.Tipo.CONCESION
		VisitanteScript.Arquetipo.PIRATA_FILM:
			destino_tipo = PuntoVisitanteScript.Tipo.PASILLO_SALAS
	if destino_tipo == PuntoVisitanteScript.Tipo.BANCA and visitante:
		return _anexar_destino_mueble(ruta, visitante, pareja_reserva, "sofa")
	if destino_tipo == PuntoVisitanteScript.Tipo.MESA and visitante:
		return _anexar_destino_mueble(ruta, visitante, pareja_reserva, "mesa")
	var destino := _pos_aleatoria(destino_tipo)
	if destino != Vector3.ZERO:
		ruta.append(destino)
	return ruta

func _anexar_destino_mueble(ruta: Array[Vector3], visitante: Visitante, pareja_reserva: Visitante, filtro_tipo: String, permitir_reintento: bool = true) -> Array[Vector3]:
	var cupos := 2 if pareja_reserva else 1
	var mueble = MuebleSentarseScript.buscar_con_cupos(cupos, get_tree(), filtro_tipo)
	if mueble == null:
		if filtro_tipo == "mesa" and permitir_reintento and pareja_reserva:
			return _anexar_destino_mueble(ruta, visitante, pareja_reserva, "sofa", false)
		if filtro_tipo == "mesa" and permitir_reintento:
			return _anexar_destino_mueble(ruta, visitante, null, "sofa", false)
		return _fallback_destino_ocio(ruta, filtro_tipo, pareja_reserva)
	visitante.destino_sentado = true
	visitante.mueble_objetivo = mueble
	if pareja_reserva and (filtro_tipo == "sofa" or filtro_tipo == "mesa"):
		pareja_reserva.destino_sentado = true
		pareja_reserva.mueble_objetivo = mueble
		var poses := mueble.asignar_pareja(visitante, pareja_reserva)
		if poses.is_empty():
			visitante._liberar_mueble()
			pareja_reserva._liberar_mueble()
			if filtro_tipo == "mesa" and permitir_reintento:
				return _anexar_destino_mueble(ruta, visitante, pareja_reserva, "sofa", false)
			return _fallback_destino_ocio(ruta, filtro_tipo, pareja_reserva)
		visitante.pose_sentado = poses["a"]
		pareja_reserva.pose_sentado = poses["b"]
		ruta.append(poses["a"].posicion)
		return ruta
	var asiento := mueble.asignar_visitante(visitante)
	if asiento.is_empty():
		visitante._liberar_mueble()
		return _fallback_destino_ocio(ruta, filtro_tipo)
	visitante.pose_sentado = asiento
	ruta.append(asiento.posicion)
	return ruta

func _fallback_destino_ocio(ruta: Array[Vector3], filtro_tipo: String, _pareja_reserva: Visitante = null) -> Array[Vector3]:
	var tipo_fallback := PuntoVisitanteScript.Tipo.MESA if filtro_tipo == "mesa" else PuntoVisitanteScript.Tipo.BANCA
	var fallback := _pos_aleatoria(tipo_fallback)
	if fallback == Vector3.ZERO:
		fallback = _pos_aleatoria(PuntoVisitanteScript.Tipo.BANO)
	if fallback != Vector3.ZERO:
		ruta.append(fallback)
	return ruta

func _ruta_hacia_posicion(posicion: Vector3) -> Array[Vector3]:
	var ruta: Array[Vector3] = []
	var puerta := _pos_aleatoria(PuntoVisitanteScript.Tipo.PUERTA_ENTRADA)
	if puerta != Vector3.ZERO:
		ruta.append(puerta)
	ruta.append(posicion)
	return ruta

func _pos_aleatoria(tipo: PuntoVisitanteScript.Tipo) -> Vector3:
	var lista: Array = _puntos_por_tipo.get(tipo, [])
	if lista.is_empty():
		return Vector3.ZERO
	return lista.pick_random().global_position

func obtener_posicion_puerta() -> Vector3:
	return _pos_aleatoria(PuntoVisitanteScript.Tipo.PUERTA_ENTRADA)

func obtener_ruta_salida() -> Array[Vector3]:
	var ruta: Array[Vector3] = []
	var izquierda := _pos_aleatoria(PuntoVisitanteScript.Tipo.SALIDA_IZQUIERDA)
	if izquierda != Vector3.ZERO:
		ruta.append(izquierda)
	for p in _puntos_por_tipo.get(PuntoVisitanteScript.Tipo.SALIDA_EXTERIOR, []):
		ruta.append(p.global_position)
	if ruta.is_empty():
		for s in _puntos_por_tipo.get(PuntoVisitanteScript.Tipo.SPAWN_EXTERIOR, []):
			ruta.append(s.global_position)
	return ruta

func obtener_posiciones_salida() -> Array[Vector3]:
	return obtener_ruta_salida()

func notificar_visitante_salio(v: Visitante) -> void:
	_visitantes_activos.erase(v)
	if v.partner and is_instance_valid(v.partner):
		_visitantes_activos.erase(v.partner)
