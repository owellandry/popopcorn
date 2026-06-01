extends StaticBody3D

@export var distancia_interaccion: float = 2.0

var ui_canvas: CanvasLayer
var texto_actual: int = 0
var carta_abierta: bool = false
var _hud: Node

const PAGINAS = [
	"""
¡Felicidades por tu nuevo cine!
	
Te has gastado la mitad de tus ahorros en esta
maravillosa inversión... ¡Y ya has pagado todo!
	""",
	"""
Gastos incurridos:
- Super oferta del local
- Renovación completa del establecimiento
- Pequeña campaña de publicidad

¡La campaña ya ha dado resultado! Pronto llegará
una pequeña cantidad de clientes.
	""",
	"""
¡Tu trabajo empieza hoy!

- Atiende a los clientes en la fila
- Vende entradas para las películas
- ¡Todo saldrá bien, confía en ti!

¡Suerte! 💫
	"""
]

func _ready():
	_crear_ui()
	add_to_group("interactuable")
	_esperar_hud()

func _esperar_hud() -> void:
	await get_tree().process_frame
	# Buscar el HUD en el árbol de la escena principal
	_hud = get_node_or_null("/root/Juego/HUD")
	if _hud == null:
		_hud = get_node_or_null("/root/JuegoV2/HUD")
	if _hud == null:
		# Si no lo encuentra en esas rutas, buscarlo en todo el árbol
		var root = get_tree().root
		for i in range(root.get_child_count()):
			var child = root.get_child(i)
			if child.name == "HUD":
				_hud = child
				break

func _crear_ui():
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 100
	
	var fondo = ColorRect.new()
	fondo.name = "ColorRect"
	fondo.color = Color(0, 0, 0, 0.85)
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	
	var panel = Control.new()
	panel.name = "Control"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300
	panel.offset_top = -200
	panel.offset_right = 300
	panel.offset_bottom = 200
	
	var texto = Label.new()
	texto.name = "TextoCarta"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	texto.add_theme_font_size_override("font_size", 20)
	texto.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	texto.add_theme_constant_override("line_spacing", 4)
	texto.anchor_right = 1.0
	texto.anchor_bottom = 1.0
	texto.text = PAGINAS[0]
	
	var boton = Button.new()
	boton.name = "BotonSiguiente"
	boton.text = "Siguiente [Enter]"
	boton.offset_left = 200
	boton.offset_top = 350
	boton.offset_right = 580
	boton.offset_bottom = 390
	boton.add_theme_font_size_override("font_size", 18)
	
	var prompt = Label.new()
	prompt.name = "PromptInteraccion"
	prompt.text = "[E] Leer carta"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	prompt.add_theme_constant_override("outline_size", 4)
	prompt.anchor_left = 0.5
	prompt.anchor_top = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_bottom = 0.5
	prompt.offset_left = -100
	prompt.offset_top = -150
	prompt.offset_right = 100
	prompt.offset_bottom = -130
	
	panel.add_child(texto)
	panel.add_child(boton)
	ui_canvas.add_child(fondo)
	ui_canvas.add_child(panel)
	ui_canvas.add_child(prompt)
	add_child(ui_canvas)
	
	ui_canvas.get_node("ColorRect").visible = false
	ui_canvas.get_node("Control").visible = false
	boton.pressed.connect(_siguiente_pagina)

func puede_interactuar(_obj: Node, jugador_en_rango: bool) -> bool:
	if not jugador_en_rango:
		return false
	if _hud and _hud.has_method("estoy_mirando_objeto"):
		return _hud.estoy_mirando_objeto(self)
	return false

func _process(_delta):
	var jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		return
	
	var distancia = global_position.distance_to(jugador.global_position)
	var prompt = ui_canvas.get_node("PromptInteraccion")
	
	var puede_interactuar_ahora = false
	if _hud and _hud.has_method("puede_interactuar"):
		puede_interactuar_ahora = _hud.puede_interactuar(self, distancia <= distancia_interaccion)
	
	if puede_interactuar_ahora and not carta_abierta:
		prompt.visible = true
	else:
		prompt.visible = false

func _input(event):
	if carta_abierta:
		if event.is_action_pressed("ui_cancel"):
			_ocultar_carta()
			return
		if event.is_action_pressed("interactuar") or event.is_action_pressed("ui_accept"):
			_siguiente_pagina()
			return
	else:
		var jugador = get_tree().get_first_node_in_group("jugador")
		if not jugador:
			return
		
		var distancia = global_position.distance_to(jugador.global_position)
		var puede_interactuar_ahora = false
		if _hud and _hud.has_method("puede_interactuar"):
			puede_interactuar_ahora = _hud.puede_interactuar(self, distancia <= distancia_interaccion)
		
		if event.is_action_pressed("interactuar") and puede_interactuar_ahora:
			_mostrar_carta()

func _mostrar_carta():
	carta_abierta = true
	texto_actual = 0
	ui_canvas.get_node("ColorRect").visible = true
	ui_canvas.get_node("Control").visible = true
	ui_canvas.get_node("PromptInteraccion").visible = false
	
	var texto = ui_canvas.get_node("Control/TextoCarta") as Label
	texto.text = PAGINAS[0]
	
	var boton = ui_canvas.get_node("Control/BotonSiguiente") as Button
	boton.text = "Siguiente [Enter]"
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_input(false)

func _ocultar_carta():
	carta_abierta = false
	ui_canvas.get_node("ColorRect").visible = false
	ui_canvas.get_node("Control").visible = false
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)

func _siguiente_pagina():
	texto_actual += 1
	
	if texto_actual >= PAGINAS.size():
		_ocultar_carta()
		queue_free()
	else:
		var texto = ui_canvas.get_node("Control/TextoCarta") as Label
		texto.text = PAGINAS[texto_actual]
		
		var boton = ui_canvas.get_node("Control/BotonSiguiente") as Button
		if texto_actual == PAGINAS.size() - 1:
			boton.text = "¡Empezar a trabajar! [Enter]"
