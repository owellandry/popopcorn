extends Node3D
## Sistema de interacción con la pantalla del mostrador
## Presiona E para abrir el navegador/PC

@export var distancia_interaccion: float = 2.5

var _jugador_cerca := false
var _canvas_layer: CanvasLayer
var _label_interaccion: Label
var _area_interaccion: Area3D
var _hud: Node

func _ready() -> void:
	_crear_area_interaccion()
	_crear_ui_interaccion()
	# Buscar el HUD en el árbol una vez al iniciar
	_esperar_hud()

func _process(_delta: float) -> void:
	_sincronizar_area_interaccion()
	_actualizar_visibilidad_prompt()

func _sincronizar_area_interaccion() -> void:
	if _area_interaccion:
		_area_interaccion.global_position = global_position

func _crear_area_interaccion() -> void:
	"""Crea el área de detección del jugador"""
	_area_interaccion = Area3D.new()
	_area_interaccion.top_level = true
	add_child(_area_interaccion)
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = distancia_interaccion
	collision.shape = shape
	_area_interaccion.add_child(collision)
	
	_area_interaccion.global_position = global_position
	_area_interaccion.body_entered.connect(_on_jugador_entro)
	_area_interaccion.body_exited.connect(_on_jugador_salio)

func _crear_ui_interaccion() -> void:
	"""Crea la UI para mostrar el mensaje de interacción"""
	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)
	
	_label_interaccion = Label.new()
	_label_interaccion.text = "[E] Abrir PC"
	_label_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_interaccion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_label_interaccion.add_theme_font_size_override("font_size", 24)
	_label_interaccion.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label_interaccion.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_label_interaccion.add_theme_constant_override("outline_size", 8)
	
	_label_interaccion.position = Vector2(0, -100)
	_label_interaccion.size = Vector2(400, 50)
	_label_interaccion.anchor_left = 0.5
	_label_interaccion.anchor_right = 0.5
	_label_interaccion.anchor_top = 0.5
	_label_interaccion.anchor_bottom = 0.5
	_label_interaccion.offset_left = -200
	_label_interaccion.offset_right = 200
	
	_canvas_layer.add_child(_label_interaccion)
	_canvas_layer.visible = false

func _input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	
	if event.is_action_pressed("interactuar"):
		if _hud and _hud.has_method("puede_interactuar"):
			if _hud.puede_interactuar(self, _jugador_cerca):
				_abrir_pc()

func _actualizar_visibilidad_prompt() -> void:
	if not _jugador_cerca:
		_canvas_layer.visible = false
		return
	
	if _hud and _hud.has_method("puede_interactuar"):
		_canvas_layer.visible = _hud.puede_interactuar(self, _jugador_cerca)
	else:
		_canvas_layer.visible = false

func _on_jugador_entro(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = true

func _on_jugador_salio(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = false
		_canvas_layer.visible = false

func _esperar_hud() -> void:
	await get_tree().process_frame
	if HUD.instance != null:
		_hud = HUD.instance
		return
	# Fallback: buscar en el árbol
	var root = get_tree().root
	for i in range(root.get_child_count()):
		var child = root.get_child(i)
		if child.name == "HUD":
			_hud = child
			break

func _abrir_pc() -> void:
	"""Abre la interfaz del navegador con transición"""
	print("💻 Abriendo PC...")
	
	# Mostrar el mouse para interactuar con el menú
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Deshabilitar controles del jugador
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_input(false)
	
	# Ocultar el label de interacción
	_canvas_layer.visible = false
	
	# Crear y mostrar la interfaz del navegador con transición
	var navegador = preload("res://scenes/ui/navegador_pc.tscn").instantiate()
	get_tree().root.add_child(navegador)
	
	# Conectar señal de cierre
	if navegador.has_signal("cerrado"):
		navegador.cerrado.connect(_on_navegador_cerrado)

func _on_navegador_cerrado() -> void:
	"""Callback cuando se cierra el navegador"""
	print("💻 PC cerrada")
	
	# Ocultar el mouse y volver al control de primera persona
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Reactivar controles del jugador
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
