extends Node3D

# Sistema de dormir - Interacción con colchón
# Presiona E para dormir y ver una cinemática de fade a negro

@export var duracion_fade_out: float = 2.5  # Tiempo para oscurecer (más lento)
@export var duracion_oscuro: float = 1.0    # Tiempo en negro (breve)
@export var duracion_fade_in: float = 2.5   # Tiempo para aclarar (más lento)
@export var duracion_ciclo_exterior: float = 10.0  # Duración de la cinemática exterior
@export var distancia_interaccion: float = 2.5

var _jugador_cerca := false
var _durmiendo := false

# Referencias a nodos
var _area_interaccion: Area3D
var _ui_canvas_layer: CanvasLayer  # Para el label de interacción
var _fade_canvas_layer: CanvasLayer  # Para el panel de fade
var _label_interaccion: Label
var _panel_fade: ColorRect
var _hud: Node

func _ready() -> void:
	_crear_area_interaccion()
	_crear_ui_interaccion()
	_crear_panel_fade()
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

func _crear_area_interaccion() -> void:
	_area_interaccion = Area3D.new()
	_area_interaccion.top_level = true
	add_child(_area_interaccion)
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3, 2, 3)
	collision.shape = shape
	collision.position = Vector3(0, 0.5, 0)
	_area_interaccion.add_child(collision)
	
	_area_interaccion.global_position = global_position
	_area_interaccion.body_entered.connect(_on_jugador_entro)
	_area_interaccion.body_exited.connect(_on_jugador_salio)

func _crear_ui_interaccion() -> void:
	_ui_canvas_layer = CanvasLayer.new()
	add_child(_ui_canvas_layer)
	
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
	
	_ui_canvas_layer.add_child(_label_interaccion)
	_ui_canvas_layer.visible = false

func _crear_panel_fade() -> void:
	_panel_fade = ColorRect.new()
	_panel_fade.name = "FadePanel"
	_panel_fade.color = Color(0, 0, 0, 0)
	_panel_fade.anchor_right = 1.0
	_panel_fade.anchor_bottom = 1.0
	_panel_fade.offset_left = 0
	_panel_fade.offset_top = 0
	_panel_fade.offset_right = 0
	_panel_fade.offset_bottom = 0
	_panel_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_fade_canvas_layer = CanvasLayer.new()
	_fade_canvas_layer.layer = 500
	_fade_canvas_layer.add_child(_panel_fade)
	get_tree().root.add_child(_fade_canvas_layer)
	_panel_fade.visible = true  # Siempre visible, solo cambiamos el alpha

func _actualizar_visibilidad_prompt() -> void:
	if not _jugador_cerca or _durmiendo:
		_ui_canvas_layer.visible = false
		return
	
	if _hud and _hud.has_method("puede_interactuar"):
		_ui_canvas_layer.visible = _hud.puede_interactuar(self, _jugador_cerca)
	else:
		_ui_canvas_layer.visible = false

func _input(event: InputEvent) -> void:
	if not _jugador_cerca or _durmiendo:
		return
	
	if event.is_action_pressed("interactuar"):
		if _hud and _hud.has_method("puede_interactuar"):
			if _hud.puede_interactuar(self, _jugador_cerca):
				_iniciar_dormir()

func _on_jugador_entro(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = true

func _on_jugador_salio(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = false
		_ui_canvas_layer.visible = false

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
	
	# Ocultar el HUD normal
	if _hud and is_instance_valid(_hud):
		_hud.visible = false
	
	# Paso 1: Fade a negro
	print("Paso 1: Fade a negro...")
	await _fade_a_negro()
	print("Paso 1 completado!")
	
	# Pasos 2: Activar la camara cinemática y empezar el ciclo rápido
	print("Paso 2: Activar cámara cinemática...")
	var tiempo_suenyo: float = 20.0  # Más rápido: 20 segundos en vez de 55
	var camara_cinematica = get_node_or_null("/root/Juego/CamaraCinematica") as Camera3D
	if not camara_cinematica:
		camara_cinematica = get_node_or_null("/root/JuegoV2/CamaraCinematica") as Camera3D
	
	var camara_jugador: Camera3D
	if jugador and jugador.has_node("Camera3D"):
		camara_jugador = jugador.get_node("Camera3D") as Camera3D
	
	if camara_jugador and camara_cinematica:
		camara_jugador.current = false
		camara_cinematica.current = true
		print("Cámara cinemática activada!")
	else:
		print("ERROR: No se encontró cámara jugador o cámara cinemática!")
	
	# Obtener el script del sol para controlar el ciclo
	print("Paso 3: Empezar ciclo día/noche rápido...")
	var sol = get_node_or_null("/root/Juego/Sol")
	if not sol:
		sol = get_node_or_null("/root/JuegoV2/Sol")
	
	if sol:
		# Empezar el día-night cycle rápido (de noche 75% a día 25% = de noche a amanecer/día)
		print("  Sol encontrado, empezando animación...")
		# Fade in a la cinemática exterior y esperar el ciclo al mismo tiempo
		print("Paso 4: Fade a claro y empezar ciclo...")
		await _fade_a_claro()
		print("Paso 4 completado!")
		# Esperamos a que termine el ciclo (ahora avanzar_ciclo tiene await)
		print("Paso 5: Esperando ciclo día/noche...")
		await sol.avanzar_ciclo(sol.get_progreso_normalizado(), 0.25, tiempo_suenyo)
		print("Paso 5 completado!")
	else:
		print("  ERROR: No se encontró el sol!")
		await _fade_a_claro()
		await get_tree().create_timer(tiempo_suenyo).timeout
	
	# Fade a negro de nuevo
	print("Paso 6: Fade a negro de nuevo...")
	await _fade_a_negro()
	print("Paso 6 completado!")
	
	# Volver a la cámara del jugador
	print("Paso 7: Volver a cámara jugador...")
	if camara_jugador and camara_cinematica:
		camara_cinematica.current = false
		camara_jugador.current = true
		print("Cámara jugador activada!")
	
	# Mostrar el HUD normal
	if _hud and is_instance_valid(_hud):
		_hud.visible = true
	
	# Fade in de vuelta al interior
	print("Paso 8: Fade a claro final...")
	await _fade_a_claro()
	print("Paso 8 completado!")
	
	# Reactivar controles del jugador
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
	
	_durmiendo = false
	_label_interaccion.visible = true
	
	print("☀️ Secuencia de dormir completada, es de día!")

func _fade_a_negro() -> void:
	print("  _fade_a_negro: Empezando...")
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_panel_fade, "color:a", 1.0, duracion_fade_out)
	print("  _fade_a_negro: Esperando tween...")
	await tween.finished
	print("  _fade_a_negro: Completado!")

func _fade_a_claro() -> void:
	print("  _fade_a_claro: Empezando...")
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_panel_fade, "color:a", 0.0, duracion_fade_in)
	print("  _fade_a_claro: Esperando tween...")
	await tween.finished
	print("  _fade_a_claro: Completado!")
