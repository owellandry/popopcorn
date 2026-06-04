extends Node3D
## Sistema de interacción con la pantalla del mostrador
## Presiona E para abrir el navegador/PC
## Mismo patrón de detección que puerta.gd e interruptor_tienda.gd (distance_to + HUD)

@export var distancia_interaccion: float = 2.5

var _jugador_cerca := false
var _canvas_layer: CanvasLayer
var _label_interaccion: Label
var _hud: Node

func _ready() -> void:
	_crear_ui_interaccion()
	_esperar_hud()

func _process(_delta: float) -> void:
	_actualizar_rango()
	_actualizar_visibilidad_prompt()

func _actualizar_rango() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Node3D
	if jugador == null:
		_jugador_cerca = false
		return
	_jugador_cerca = jugador.global_position.distance_to(global_position) <= distancia_interaccion

func _crear_ui_interaccion() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 10
	get_tree().root.add_child(_canvas_layer)
	
	_label_interaccion = Label.new()
	_label_interaccion.text = "[E] Abrir PC"
	_label_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_interaccion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_label_interaccion.add_theme_font_size_override("font_size", 24)
	_label_interaccion.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label_interaccion.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_label_interaccion.add_theme_constant_override("outline_size", 8)
	
	_label_interaccion.anchor_left = 0.5
	_label_interaccion.anchor_right = 0.5
	_label_interaccion.anchor_top = 0.5
	_label_interaccion.anchor_bottom = 0.5
	_label_interaccion.offset_left = -200
	_label_interaccion.offset_top = -140
	_label_interaccion.offset_right = 200
	_label_interaccion.offset_bottom = -90
	
	_canvas_layer.add_child(_label_interaccion)
	_canvas_layer.visible = false

func _input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	
	if event.is_action_pressed("interactuar"):
		_ensure_hud()
		if _hud and _hud.has_method("puede_interactuar"):
			if _hud.puede_interactuar(self, _jugador_cerca):
				_abrir_pc()

func _actualizar_visibilidad_prompt() -> void:
	if not _jugador_cerca:
		if _canvas_layer:
			_canvas_layer.visible = false
		return
	
	_ensure_hud()
	if _hud and _hud.has_method("puede_interactuar"):
		if _canvas_layer:
			_canvas_layer.visible = _hud.puede_interactuar(self, _jugador_cerca)
	else:
		if _canvas_layer:
			_canvas_layer.visible = false

func _ensure_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		return
	if HUD.instance != null:
		_hud = HUD.instance
		return
	_hud = get_node_or_null("/root/JuegoV2/HUD")
	if _hud == null:
		_hud = get_node_or_null("/root/Juego/HUD")

func _esperar_hud() -> void:
	await get_tree().process_frame
	# Mismo orden de búsqueda que puerta.gd
	_hud = get_node_or_null("/root/Juego/HUD")
	if _hud == null:
		_hud = get_node_or_null("/root/JuegoV2/HUD")
	if _hud == null:
		var root = get_tree().root
		for i in range(root.get_child_count()):
			var child = root.get_child(i)
			if child.name == "HUD":
				_hud = child
				break

func _abrir_pc() -> void:
	print("[PC] Abriendo PC...")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_input(false)
	
	if _canvas_layer:
		_canvas_layer.visible = false
	
	var navegador = preload("res://scenes/ui/navegador_pc.tscn").instantiate()
	get_tree().root.add_child(navegador)
	
	if navegador.has_signal("cerrado"):
		navegador.cerrado.connect(_on_navegador_cerrado)

func _on_navegador_cerrado() -> void:
	print("[PC] PC cerrada")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
