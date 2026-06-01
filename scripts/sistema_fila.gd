extends Node3D

@export var punto_frente: Node3D
@export var puntos_espera: Array[Node3D] = []

var clientes: Array[CharacterBody3D] = []
var cliente_en_frente: CharacterBody3D = null
var ui_prompt: Label = null
var dialogo: Control = null

const COLORES = [
	Color(0.9, 0.2, 0.2, 1), Color(0.2, 0.9, 0.3, 1), Color(0.2, 0.3, 0.9, 1),
	Color(0.9, 0.9, 0.2, 1), Color(0.9, 0.2, 0.9, 1)
]

const PELICULAS = [
	"La Aventura Espacial", "El Gran Heist", "Historia de Amor", "Terror Nocturno", "Comedia de los 80s"
]

func _ready():
	# Inicializar los puntos
	punto_frente = get_node_or_null("PuntoFrente")
	var temp_puntos = [
		get_node_or_null("PuntoEspera1"),
		get_node_or_null("PuntoEspera2"),
		get_node_or_null("PuntoEspera3"),
		get_node_or_null("PuntoEspera4")
	]
	puntos_espera.clear()
	for p in temp_puntos:
		if p:
			puntos_espera.append(p)
	
	# Crear UI para prompt
	var canvas = CanvasLayer.new()
	ui_prompt = Label.new()
	ui_prompt.text = "[E] Atender cliente"
	ui_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui_prompt.add_theme_font_size_override("font_size", 22)
	ui_prompt.add_theme_color_override("font_color", Color(1,1,1,1))
	ui_prompt.add_theme_color_override("font_outline_color", Color(0,0,0,1))
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
	
	# Obtener el dialogo
	dialogo = get_parent().get_node_or_null("DialogoCliente")
	
	# Spawn de clientes iniciales
	await get_tree().process_frame
	_spawn_clientes()

func _process(_delta):
	if ui_prompt:
		var jugador = get_tree().get_first_node_in_group("jugador")
		if jugador and cliente_en_frente:
			var distancia = global_position.distance_to(jugador.global_position)
			ui_prompt.visible = distancia < 4.0
		else:
			ui_prompt.visible = false

func _input(event):
	if event.is_action_pressed("interactuar") and ui_prompt and ui_prompt.visible:
		if cliente_en_frente and dialogo:
			dialogo.mostrar(cliente_en_frente)

func _spawn_clientes():
	for i in range(min(5, puntos_espera.size())):
		var nuevo_cliente = CharacterBody3D.new()
		
		var script = load("res://scripts/cliente.gd")
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

func _actualizar_fila():
	if clientes.size() > 0:
		cliente_en_frente = clientes[0]
		if punto_frente:
			var tween = cliente_en_frente.create_tween()
			tween.tween_property(cliente_en_frente, "global_position", punto_frente.global_position, 0.5)
			tween.tween_property(cliente_en_frente, "global_rotation", punto_frente.global_rotation, 0.5)

func atender_cliente():
	if cliente_en_frente:
		cliente_en_frente.ir_a_sala()
		clientes.erase(cliente_en_frente)
		cliente_en_frente = null
		
		# Mover los clientes de la fila hacia adelante
		for i in range(clientes.size()):
			if i < puntos_espera.size():
				var cliente = clientes[i]
				var tween = cliente.create_tween()
				tween.tween_property(cliente, "global_position", puntos_espera[i].global_position, 0.3)
		
		await get_tree().create_timer(0.5).timeout
		_actualizar_fila()
