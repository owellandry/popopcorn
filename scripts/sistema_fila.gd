extends Node3D

@export var punto_frente: Node3D
@export var puntos_espera: Array[Node3D] = []
@export var intervalo_spawn: float = 12.0
@export var max_clientes_fila: int = 4

var clientes: Array[CharacterBody3D] = []
var cliente_en_frente: CharacterBody3D = null
var ui_prompt: Label = null
var dialogo: Control = null
var _timer_spawn: Timer

const COLORES = [
	Color(0.9, 0.2, 0.2, 1), Color(0.2, 0.9, 0.3, 1), Color(0.2, 0.3, 0.9, 1),
	Color(0.9, 0.9, 0.2, 1), Color(0.9, 0.2, 0.9, 1)
]

const PELICULAS = [
	"La Aventura Espacial", "El Gran Heist", "Historia de Amor", "Terror Nocturno", "Comedia de los 80s"
]

func _ready() -> void:
	punto_frente = get_node_or_null("PuntoFrente")
	var temp_puntos := [
		get_node_or_null("PuntoEspera1"),
		get_node_or_null("PuntoEspera2"),
		get_node_or_null("PuntoEspera3"),
		get_node_or_null("PuntoEspera4")
	]
	puntos_espera.clear()
	for p in temp_puntos:
		if p:
			puntos_espera.append(p)

	var canvas := CanvasLayer.new()
	ui_prompt = Label.new()
	ui_prompt.text = "[E] Atender cliente"
	ui_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_prompt.add_theme_font_size_override("font_size", 22)
	ui_prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	ui_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	ui_prompt.add_theme_constant_override("outline_size", 4)
	ui_prompt.anchor_left = 0.5
	ui_prompt.anchor_top = 0.5
	ui_prompt.anchor_right = 0.5
	ui_prompt.anchor_bottom = 0.5
	ui_prompt.offset_left = -100
	ui_prompt.offset_top = -150
	ui_prompt.offset_right = 100
	ui_prompt.offset_bottom = -130
	canvas.add_child(ui_prompt)
	add_child(canvas)

	dialogo = get_parent().get_node_or_null("DialogoCliente")

	_timer_spawn = Timer.new()
	_timer_spawn.wait_time = intervalo_spawn
	_timer_spawn.autostart = true
	_timer_spawn.timeout.connect(_intentar_spawn_cliente)
	add_child(_timer_spawn)

	if GestorGameplay:
		GestorGameplay.condiciones_clientes_cambiadas.connect(_on_condiciones_clientes_cambiadas)

func _process(_delta: float) -> void:
	if ui_prompt:
		var jugador := get_tree().get_first_node_in_group("jugador")
		if jugador and cliente_en_frente:
			var distancia := global_position.distance_to(jugador.global_position)
			ui_prompt.visible = distancia < 4.0
		else:
			ui_prompt.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar") and ui_prompt and ui_prompt.visible:
		if cliente_en_frente and dialogo:
			dialogo.mostrar(cliente_en_frente)

func _on_condiciones_clientes_cambiadas(pueden: bool) -> void:
	if not pueden:
		_timer_spawn.stop()
	else:
		if _timer_spawn.is_stopped():
			_timer_spawn.start()
		_intentar_spawn_cliente()

func _intentar_spawn_cliente() -> void:
	if not GestorGameplay or not GestorGameplay.pueden_llegar_clientes():
		return
	if clientes.size() >= max_clientes_fila or clientes.size() >= puntos_espera.size():
		return
	_spawn_un_cliente()

func _spawn_un_cliente() -> void:
	var i := clientes.size()
	var nuevo_cliente := CharacterBody3D.new()
	var script := load("res://scripts/cliente.gd")
	nuevo_cliente.set_script(script)
	nuevo_cliente.color = COLORES[i % COLORES.size()]
	nuevo_cliente.nombre_pelicula = PELICULAS[i % PELICULAS.size()]
	nuevo_cliente.sala_asignada = (i % 2) + 1
	add_child(nuevo_cliente)
	if i < puntos_espera.size():
		nuevo_cliente.global_position = puntos_espera[i].global_position
		nuevo_cliente.global_rotation = puntos_espera[i].global_rotation
	clientes.append(nuevo_cliente)
	_actualizar_fila()

func _actualizar_fila() -> void:
	if clientes.is_empty():
		cliente_en_frente = null
		return
	cliente_en_frente = clientes[0]
	if punto_frente:
		var tween := cliente_en_frente.create_tween()
		tween.tween_property(cliente_en_frente, "global_position", punto_frente.global_position, 0.5)
		tween.tween_property(cliente_en_frente, "global_rotation", punto_frente.global_rotation, 0.5)

func atender_cliente() -> void:
	if cliente_en_frente:
		cliente_en_frente.ir_a_sala()
		clientes.erase(cliente_en_frente)
		cliente_en_frente = null
		for i in range(clientes.size()):
			if i < puntos_espera.size():
				var cliente := clientes[i]
				var tween := cliente.create_tween()
				tween.tween_property(cliente, "global_position", puntos_espera[i].global_position, 0.3)
		await get_tree().create_timer(0.5).timeout
		_actualizar_fila()