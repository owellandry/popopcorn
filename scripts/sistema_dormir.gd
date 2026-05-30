extends Node3D

# Sistema de dormir - Interacción con colchón
# Presiona E para dormir y ver una cinemática de fade a negro

@export var duracion_fade_out: float = 1.5  # Tiempo para oscurecer
@export var duracion_oscuro: float = 2.0    # Tiempo en negro
@export var duracion_fade_in: float = 1.5   # Tiempo para aclarar

var _jugador_cerca := false
var _durmiendo := false

# Referencias a nodos
var _area_interaccion: Area3D
var _canvas_layer: CanvasLayer
var _label_interaccion: Label
var _panel_fade: ColorRect

func _ready() -> void:
	# Crear área de interacción
	_crear_area_interaccion()
	
	# Crear UI de interacción
	_crear_ui_interaccion()
	
	# Crear panel de fade
	_crear_panel_fade()

func _crear_area_interaccion() -> void:
	_area_interaccion = Area3D.new()
	add_child(_area_interaccion)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3, 2, 3)  # Área de interacción alrededor del colchón
	collision.shape = shape
	collision.position = Vector3(0, 0.5, 0)
	_area_interaccion.add_child(collision)
	
	_area_interaccion.body_entered.connect(_on_jugador_entro)
	_area_interaccion.body_exited.connect(_on_jugador_salio)

func _crear_ui_interaccion() -> void:
	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)
	
	_label_interaccion = Label.new()
	_label_interaccion.text = "[E] Dormir"
	_label_interaccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_interaccion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Estilo del label
	_label_interaccion.add_theme_font_size_override("font_size", 24)
	_label_interaccion.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label_interaccion.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_label_interaccion.add_theme_constant_override("outline_size", 8)
	
	# Posición en pantalla
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

func _crear_panel_fade() -> void:
	_panel_fade = ColorRect.new()
	_panel_fade.color = Color(0, 0, 0, 0)  # Negro transparente
	_panel_fade.anchor_right = 1.0
	_panel_fade.anchor_bottom = 1.0
	_panel_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_panel_fade)

func _input(event: InputEvent) -> void:
	if not _jugador_cerca or _durmiendo:
		return
	
	if event.is_action_pressed("interactuar"):  # Tecla E
		_iniciar_dormir()

func _on_jugador_entro(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = true
		_canvas_layer.visible = true

func _on_jugador_salio(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = false
		_canvas_layer.visible = false

func _iniciar_dormir() -> void:
	if _durmiendo:
		return
	
	_durmiendo = true
	_label_interaccion.visible = false
	
	print("💤 Iniciando secuencia de dormir...")
	
	# Deshabilitar controles del jugador
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_input(false)
	
	# Secuencia de fade
	await _fade_a_negro()
	await get_tree().create_timer(duracion_oscuro).timeout
	await _fade_a_claro()
	
	# Reactivar controles del jugador
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
	
	_durmiendo = false
	_label_interaccion.visible = true
	
	print("☀️ Secuencia de dormir completada")

func _fade_a_negro() -> void:
	var tween = create_tween()
	tween.tween_property(_panel_fade, "color:a", 1.0, duracion_fade_out)
	await tween.finished

func _fade_a_claro() -> void:
	var tween = create_tween()
	tween.tween_property(_panel_fade, "color:a", 0.0, duracion_fade_in)
	await tween.finished
