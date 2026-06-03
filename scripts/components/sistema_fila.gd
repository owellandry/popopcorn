extends Node3D

@export var punto_frente: Node3D
@export var puntos_espera: Array[Node3D] = []
@export var max_clientes_fila: int = 4

var clientes: Array[CharacterBody3D] = []
var cliente_en_frente: CharacterBody3D = null
var ui_prompt: Label = null
var dialogo: Control = null

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

func registrar_visitante(visitante: CharacterBody3D) -> bool:
	if clientes.size() >= max_clientes_fila or clientes.size() >= puntos_espera.size():
		return false
	var i := clientes.size()
	clientes.append(visitante)
	if i < puntos_espera.size():
		var punto := puntos_espera[i]
		if visitante.has_method("ir_a_posicion_fila"):
			visitante.ir_a_posicion_fila(punto.global_position, punto.global_rotation)
	_actualizar_fila()
	return true

func remover_visitante(visitante: CharacterBody3D) -> void:
	if not clientes.has(visitante):
		return
	clientes.erase(visitante)
	if cliente_en_frente == visitante:
		cliente_en_frente = null
	_reordenar_fila()

func _reordenar_fila() -> void:
	for i in range(clientes.size()):
		if i >= puntos_espera.size():
			break
		var visitante := clientes[i]
		var punto := puntos_espera[i]
		if visitante.has_method("ir_a_posicion_fila"):
			visitante.ir_a_posicion_fila(punto.global_position, punto.global_rotation)
	_actualizar_fila()

func _actualizar_fila() -> void:
	if clientes.is_empty():
		cliente_en_frente = null
		return
	cliente_en_frente = clientes[0]
	if punto_frente and cliente_en_frente.has_method("ir_a_posicion_fila"):
		cliente_en_frente.ir_a_posicion_fila(punto_frente.global_position, punto_frente.global_rotation)

func atender_cliente() -> void:
	if cliente_en_frente:
		cliente_en_frente.ir_a_sala()
		clientes.erase(cliente_en_frente)
		cliente_en_frente = null
		_reordenar_fila()
		await get_tree().create_timer(0.5).timeout
		_actualizar_fila()
