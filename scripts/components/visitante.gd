extends CharacterBody3D
class_name Visitante

enum Arquetipo {
	CLIENTE_LEGAL,
	EXPLORADOR,
	OCIO_LOBBY,
	PAREJA,
	COLADO,
	LADRON,
	PIRATA_FILM,
}

enum Estado {
	EXTERIOR,
	ENTRANDO,
	EN_INTERIOR,
	EN_FILA,
	ACTIVIDAD,
	INTIMIDAD,
	SALIENDO,
}

const VELOCIDAD_CAMINAR := 3.2
const VELOCIDAD_HUIDA := 6.0
const DURACION_ACTIVIDAD_MIN := 8.0
const DURACION_ACTIVIDAD_MAX := 22.0
const TOLERANCIA_LLEGADA := 0.55
const LAYER_MUNDO := 1
const LAYER_VISITANTE := 4
const UtilAsientoScript := preload("res://scripts/components/util_asiento.gd")

const RUTAS_NPC: Array[String] = [
	"res://assets/models/npc/antonio.tscn",
	"res://assets/models/npc/ismael.tscn",
	"res://assets/models/npc/juan.tscn",
	"res://assets/models/npc/juana.tscn",
	"res://assets/models/npc/karla.tscn",
	"res://assets/models/npc/karo.tscn",
	"res://assets/models/npc/maria.tscn",
	"res://assets/models/npc/mario.tscn",
	"res://assets/models/npc/marta.tscn",
	"res://assets/models/npc/martin.tscn",
	"res://assets/models/npc/miguel.tscn",
	"res://assets/models/npc/pedro.tscn",
	"res://assets/models/npc/samuel.tscn",
	"res://assets/models/npc/sara.tscn",
]

@export var color: Color = Color(0.8, 0.2, 0.2, 1)
@export var nombre_pelicula: String = "La Aventura Espacial"
@export var sala_asignada: int = 1

var arquetipo: Arquetipo = Arquetipo.CLIENTE_LEGAL
var estado: Estado = Estado.EXTERIOR
var partner: Visitante = null
var mueble_objetivo = null
var destino_sentado: bool = false
var pose_sentado: Dictionary = {}
var _ruta: Array[Vector3] = []
var _indice_ruta := 0
var _en_movimiento := false
var _destino_actual := Vector3.ZERO
var _velocidad_actual := VELOCIDAD_CAMINAR
var _rotacion_al_llegar: Variant = null
var _timer_actividad: SceneTreeTimer
var _golpes_recibidos := 0
var _al_terminar_movimiento: Callable = Callable()
var _hizo_accion_entrada := false
var _gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _npc_mesh: Node3D

signal cliente_habla(cliente: Node3D, pelicula: String)

func _ready() -> void:
	add_to_group("visitante")
	collision_layer = LAYER_VISITANTE
	collision_mask = LAYER_MUNDO | LAYER_VISITANTE
	floor_stop_on_slope = true
	_construir_malla()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravedad * delta
	else:
		velocity.y = 0.0
	var quieto := _esta_quieto_por_estado()
	if not _en_movimiento or quieto:
		if quieto:
			velocity.x = 0.0
			velocity.z = 0.0
		move_and_slide()
		_actualizar_animacion(false)
		return
	var dir := _destino_actual - global_position
	dir.y = 0.0
	var dist := dir.length()
	if dist <= TOLERANCIA_LLEGADA:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		_actualizar_animacion(false)
		_llegar_a_destino()
		return
	velocity.x = dir.x / dist * _velocidad_actual
	velocity.z = dir.z / dist * _velocidad_actual
	_actualizar_animacion(true)
	if dist > 0.05:
		look_at(global_position + dir.normalized(), Vector3.UP)
	move_and_slide()

func _process(_delta: float) -> void:
	if estado == Estado.SALIENDO and not _visible_para_jugador():
		_finalizar_salida()

func _esta_quieto_por_estado() -> bool:
	return estado == Estado.ACTIVIDAD or estado == Estado.INTIMIDAD or estado == Estado.EN_FILA

func _visible_para_jugador() -> bool:
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return true
	return camara.is_position_in_frustum(global_position)

func _actualizar_animacion(moviendo: bool) -> void:
	if not _npc_mesh or not _npc_mesh.has_method("set_wandering"):
		return
	_npc_mesh.set_wandering(moviendo)

func _construir_malla() -> void:
	var ruta := RUTAS_NPC[randi() % RUTAS_NPC.size()]
	var escena := load(ruta) as PackedScene
	if escena == null:
		return
	_npc_mesh = escena.instantiate()
	add_child(_npc_mesh)

func configurar(tipo_arc: Arquetipo, color_arc: Color, pelicula: String, sala: int, pareja: Visitante = null) -> void:
	arquetipo = tipo_arc
	color = color_arc
	nombre_pelicula = pelicula
	sala_asignada = sala
	partner = pareja

func iniciar_recorrido(ruta_global: Array[Vector3]) -> void:
	if ruta_global.is_empty():
		return
	_ruta = ruta_global
	_indice_ruta = 0
	estado = Estado.EXTERIOR if _indice_ruta == 0 else Estado.ENTRANDO
	_avanzar_siguiente_punto()

func _avanzar_siguiente_punto() -> void:
	if _indice_ruta >= _ruta.size():
		_al_llegar_destino_final()
		return
	var destino := _ruta[_indice_ruta]
	_indice_ruta += 1
	_mover_hacia(destino, VELOCIDAD_CAMINAR, Callable(self, "_on_punto_alcanzado"))

func _on_punto_alcanzado() -> void:
	if estado == Estado.SALIENDO:
		if _indice_ruta >= _ruta.size():
			_finalizar_salida()
		else:
			_avanzar_siguiente_punto()
		return
	if _indice_ruta == 1 and not _hizo_accion_entrada:
		_hizo_accion_entrada = true
		_accion_ingreso_cine()
		return
	_continuar_recorrido()

func _accion_ingreso_cine() -> void:
	_en_movimiento = false
	velocity = Vector3.ZERO
	estado = Estado.ENTRANDO
	var rot_inicial := rotation.y
	var tween := create_tween()
	tween.tween_property(self, "rotation:y", rot_inicial + deg_to_rad(35.0), 0.7)
	tween.tween_property(self, "rotation:y", rot_inicial - deg_to_rad(70.0), 1.0)
	tween.tween_property(self, "rotation:y", rot_inicial, 0.6)
	await tween.finished
	await get_tree().create_timer(randf_range(0.4, 0.9)).timeout
	_continuar_recorrido()

func _continuar_recorrido() -> void:
	if _indice_ruta >= _ruta.size():
		_al_llegar_destino_final()
	else:
		if _indice_ruta >= 2:
			estado = Estado.EN_INTERIOR
		_avanzar_siguiente_punto()

func ir_a_posicion_fila(posicion: Vector3, rotacion: Vector3) -> void:
	_rotacion_al_llegar = rotacion
	_mover_hacia(posicion, VELOCIDAD_CAMINAR, Callable(self, "_al_llegar_slot_fila"))

func _al_llegar_slot_fila() -> void:
	if _rotacion_al_llegar is Vector3:
		global_rotation = _rotacion_al_llegar
	_rotacion_al_llegar = null
	estado = Estado.EN_FILA
	_en_movimiento = false
	velocity = Vector3.ZERO

func _al_llegar_destino_final() -> void:
	match arquetipo:
		Arquetipo.CLIENTE_LEGAL:
			_entrar_en_fila()
		Arquetipo.COLADO:
			estado = Estado.ACTIVIDAD
			_iniciar_actividad_temporal()
		Arquetipo.LADRON, Arquetipo.PIRATA_FILM:
			estado = Estado.ACTIVIDAD
			_iniciar_actividad_temporal()
		Arquetipo.EXPLORADOR:
			estado = Estado.ACTIVIDAD
			_iniciar_actividad_temporal()
		Arquetipo.OCIO_LOBBY:
			_iniciar_actividad_en_destino()
		Arquetipo.PAREJA:
			_intentar_evento_pareja()

func _entrar_en_fila() -> void:
	var fila := get_tree().get_first_node_in_group("sistema_fila")
	if fila and fila.has_method("registrar_visitante"):
		if fila.registrar_visitante(self):
			return
	_salir_del_cine()

func _iniciar_actividad_temporal() -> void:
	var duracion := randf_range(DURACION_ACTIVIDAD_MIN, DURACION_ACTIVIDAD_MAX)
	_timer_actividad = get_tree().create_timer(duracion)
	_timer_actividad.timeout.connect(_salir_del_cine, CONNECT_ONE_SHOT)

func _iniciar_actividad_en_destino() -> void:
	estado = Estado.ACTIVIDAD
	if destino_sentado and _aplicar_pose_sentado():
		_iniciar_actividad_temporal()
		return
	_iniciar_actividad_temporal()

func _aplicar_pose_sentado() -> bool:
	if pose_sentado.is_empty():
		return false
	if pose_sentado.has("posicion"):
		global_position = pose_sentado.posicion
	if pose_sentado.has("rotacion"):
		global_rotation = pose_sentado.rotacion
	_en_movimiento = false
	velocity = Vector3.ZERO
	collision_layer = 0
	return true

func _restaurar_colision() -> void:
	collision_layer = LAYER_VISITANTE

func _liberar_mueble() -> void:
	if mueble_objetivo and is_instance_valid(mueble_objetivo):
		mueble_objetivo.liberar_visitante(self)
	mueble_objetivo = null
	destino_sentado = false
	pose_sentado.clear()
	_restaurar_colision()

func _intentar_evento_pareja() -> void:
	if partner == null or not is_instance_valid(partner):
		_iniciar_actividad_temporal()
		return
	if partner.estado == Estado.INTIMIDAD:
		return
	if randf() < 0.12 and not destino_sentado:
		_iniciar_intimidad_pareja()
	else:
		_iniciar_actividad_en_destino()
		if partner and partner.estado != Estado.INTIMIDAD and partner.destino_sentado:
			partner._iniciar_actividad_en_destino()

func _iniciar_intimidad_pareja() -> void:
	estado = Estado.INTIMIDAD
	if partner:
		partner.estado = Estado.INTIMIDAD
		if partner.has_method("_cancelar_actividad"):
			partner._cancelar_actividad()
	_cancelar_actividad()
	_mirar_a_partner()
	if partner:
		partner._mirar_a_partner()
	await get_tree().create_timer(2.5).timeout
	_animacion_beso_simple()
	if partner:
		partner._animacion_beso_simple()
	await get_tree().create_timer(2.0).timeout
	_salir_del_cine()
	if partner and is_instance_valid(partner):
		partner._salir_del_cine()

func _cancelar_actividad() -> void:
	if _timer_actividad:
		_timer_actividad = null

func _mirar_a_partner() -> void:
	if partner == null:
		return
	var dir := partner.global_position - global_position
	dir.y = 0
	if dir.length_squared() > 0.01:
		look_at(global_position + dir.normalized(), Vector3.UP)

func _animacion_beso_simple() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 0.05, 0.4)
	tween.tween_property(self, "position:y", position.y, 0.4)

func hablar() -> void:
	emit_signal("cliente_habla", self, nombre_pelicula)

func ir_a_sala() -> void:
	var sala: Node = _buscar_sala_asignada()
	if sala and sala.has_method("asignar_asiento") and sala.asignar_asiento(self):
		estado = Estado.ACTIVIDAD
		_iniciar_actividad_temporal()
		return
	estado = Estado.ACTIVIDAD
	_iniciar_actividad_temporal()

func _buscar_sala_asignada() -> Node:
	for n in get_tree().get_nodes_in_group("sala_cine"):
		if n.get("numero_sala") == sala_asignada:
			return n
	return null

func sentarse_en_pose(pose: Dictionary, mueble = null) -> void:
	if mueble:
		mueble_objetivo = mueble
	destino_sentado = true
	pose_sentado = pose.duplicate()
	estado = Estado.ACTIVIDAD
	_aplicar_pose_sentado()

func sentarse(asiento_obj: Variant) -> void:
	estado = Estado.ACTIVIDAD
	if asiento_obj is Dictionary:
		sentarse_en_pose(asiento_obj)
		return
	if asiento_obj is Node3D:
		sentarse_en_pose(UtilAsientoScript.pose_desde_nodo(asiento_obj))

func ver_pelicula() -> void:
	estado = Estado.ACTIVIDAD

func irse() -> void:
	_salir_del_cine()

func recibir_golpe_bate(_origen: Vector3) -> void:
	_golpes_recibidos += 1
	if estado == Estado.INTIMIDAD:
		return
	var fila := get_tree().get_first_node_in_group("sistema_fila")
	if fila and fila.has_method("remover_visitante"):
		fila.remover_visitante(self)
	_salir_del_cine(true)

func _salir_del_cine(huida: bool = false) -> void:
	if estado == Estado.SALIENDO:
		return
	_cancelar_actividad()
	_liberar_mueble()
	estado = Estado.SALIENDO
	if partner and is_instance_valid(partner) and partner.estado != Estado.SALIENDO and partner != self:
		if huida:
			partner.recibir_golpe_bate(global_position)
		else:
			partner._salir_del_cine(huida)
	_ruta.clear()
	_indice_ruta = 0
	var gv := get_tree().root.get_node_or_null("GestorVisitantes")
	if gv and gv.has_method("obtener_ruta_salida"):
		_ruta = gv.obtener_ruta_salida()
	else:
		_ruta.append(global_position + Vector3(-5.0, 0.0, 5.0))
	var vel := VELOCIDAD_HUIDA if huida else VELOCIDAD_CAMINAR
	if _ruta.is_empty():
		queue_free()
		return
	_mover_hacia(_ruta[0], vel, Callable(self, "_continuar_salida"))

func _continuar_salida() -> void:
	_indice_ruta = 1
	_avanzar_siguiente_punto()

func _finalizar_salida() -> void:
	var gv := get_tree().root.get_node_or_null("GestorVisitantes")
	if gv:
		gv.notificar_visitante_salio(self)
	queue_free()

func _mover_hacia(destino: Vector3, velocidad: float, al_terminar: Callable = Callable()) -> void:
	_destino_actual = destino
	_velocidad_actual = velocidad
	_al_terminar_movimiento = al_terminar
	_en_movimiento = true

func _llegar_a_destino() -> void:
	_en_movimiento = false
	velocity.x = 0.0
	velocity.z = 0.0
	if _rotacion_al_llegar is Vector3:
		global_rotation = _rotacion_al_llegar
		_rotacion_al_llegar = null
	if _al_terminar_movimiento.is_valid():
		_al_terminar_movimiento.call()
	_al_terminar_movimiento = Callable()
