extends Node3D

# Sistema de dormir - Interacción con colchón
# Al dormir: Se establece la hora a las 9 PM y avanza hasta las 8 AM en 5 segundos

@export var duracion_fade_out: float = 1.0  # Tiempo para oscurecer
@export var duracion_fade_in: float = 1.0   # Tiempo para aclarar
@export var duracion_ciclo_noche: float = 5.0  # Duración del ciclo nocturno (5 segundos)
@export var distancia_interaccion: float = 2.5

# Horas del día en formato progreso_normalizado (0-1)
# 0.0 = 00:00 (medianoche), 0.25 = 06:00, 0.5 = 12:00, 0.75 = 18:00, 1.0 = 24:00
const HORA_9PM: float = 0.875  # 21:00 = 0.75 + (3/24) = 0.875
const HORA_8AM: float = 0.3333  # 08:00 = 0.25 + (2/24) ≈ 0.333

var _jugador_cerca := false
var _durmiendo := false
var _aviso_dormir: Label

# Referencias a nodos
var _area_interaccion: Area3D
var _ui_canvas_layer: CanvasLayer
var _fade_canvas_layer: CanvasLayer
var _label_interaccion: Label
var _panel_fade: ColorRect
var _hud: Node

func _ready() -> void:
	_crear_area_interaccion()
	_crear_ui_interaccion()
	_crear_aviso_dormir()
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
	_panel_fade.visible = true

func _actualizar_visibilidad_prompt() -> void:
	if not _jugador_cerca or _durmiendo:
		_ui_canvas_layer.visible = false
		return

	if GestorGameplay and GestorGameplay.es_despues_de_las_9pm() and _label_interaccion:
		if GestorGameplay.puede_dormir():
			_label_interaccion.text = "[E] Dormir"
		else:
			_label_interaccion.text = GestorGameplay.mensaje_no_puede_dormir()

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

func _crear_aviso_dormir() -> void:
	_aviso_dormir = Label.new()
	_aviso_dormir.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso_dormir.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_aviso_dormir.add_theme_font_size_override("font_size", 20)
	_aviso_dormir.add_theme_color_override("font_color", Color(1, 0.85, 0.5, 1))
	_aviso_dormir.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_aviso_dormir.add_theme_constant_override("outline_size", 6)
	_aviso_dormir.anchor_left = 0.5
	_aviso_dormir.anchor_right = 0.5
	_aviso_dormir.anchor_top = 0.5
	_aviso_dormir.anchor_bottom = 0.5
	_aviso_dormir.offset_left = -280
	_aviso_dormir.offset_right = 280
	_aviso_dormir.offset_top = -60
	_aviso_dormir.offset_bottom = 60
	_aviso_dormir.visible = false
	_ui_canvas_layer.add_child(_aviso_dormir)

func _mostrar_aviso_dormir(texto: String) -> void:
	if _aviso_dormir:
		_aviso_dormir.text = texto
		_aviso_dormir.visible = true
		await get_tree().create_timer(2.5).timeout
		_aviso_dormir.visible = false

func _iniciar_dormir() -> void:
	if _durmiendo:
		return

	if GestorGameplay and not GestorGameplay.puede_dormir():
		await _mostrar_aviso_dormir(GestorGameplay.mensaje_no_puede_dormir())
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
	
	# Paso 2: Configurar hora a las 9 PM (0.875) y preparar ciclo hasta 8 AM (0.333)
	print("Paso 2: Configurando hora a las 9 PM...")
	var sol = get_tree().get_first_node_in_group("sol_ciclo")
	if sol == null:
		sol = get_node_or_null("/root/Juego/Sol")
	if sol == null:
		sol = get_node_or_null("/root/JuegoV2/Sol")

	if sol:
		sol.progreso_normalizado = HORA_9PM
		sol.actualizar_ciclo()
		print("  Hora establecida a las 9 PM (progreso: %f)" % HORA_9PM)
	
	print("Paso 2 completado!")
	
	# Paso 3: Activar cámara cinemática
	print("Paso 3: Activando cámara cinemática...")
	var camara_cinematica = get_node_or_null("/root/Juego/CamaraCinematica") as Camera3D
	if not camara_cinematica:
		camara_cinematica = get_node_or_null("/root/JuegoV2/CamaraCinematica") as Camera3D
	
	var camara_jugador: Camera3D
	if jugador and jugador.has_node("Camera3D"):
		camara_jugador = jugador.get_node("Camera3D") as Camera3D
	
	if camara_jugador and camara_cinematica:
		camara_jugador.current = false
		camara_cinematica.current = true
		print("  Cámara cinemática activada!")
	else:
		print("  ERROR: No se encontró cámara jugador o cámara cinemática!")
	
	print("Paso 3 completado!")
	
	# Paso 4: Fade in con cielo nocturno (9 PM ya aplicado en paso 2)
	print("Paso 4: Fade in a cinemática exterior (cielo oscuro)...")
	if sol:
		sol.actualizar_ciclo()
	await _fade_a_claro()
	print("Paso 4 completado!")
	
	# Paso 5: Iniciar ciclo nocturno (9 PM -> 8 AM en 5 segundos)
	print("Paso 5: Iniciando ciclo nocturno (9 PM -> 8 AM en 5 segundos)...")
	if sol:
		# El ciclo debe ir desde 0.875 (9 PM) hasta 0.333 (8 AM)
		# Como 0.333 es menor que 0.875, debemos ir hasta 1.0 y luego desde 0.0 hasta 0.333
		# Total de progreso a recorrer: (1.0 - 0.875) + 0.333 = 0.458
		await sol.avanzar_ciclo(HORA_9PM, 1.0, duracion_ciclo_noche * 0.27)  # Hasta medianoche
		await sol.avanzar_ciclo(0.0, HORA_8AM, duracion_ciclo_noche * 0.73)  # Desde medianoche hasta 8 AM
		print("  Ciclo nocturno completado!")
	else:
		print("  ERROR: No se encontró el sol!")
		await get_tree().create_timer(duracion_ciclo_noche).timeout
	
	print("Paso 5 completado!")
	
	# Paso 6: Fade a negro de nuevo
	print("Paso 6: Fade a negro...")
	await _fade_a_negro()
	print("Paso 6 completado!")
	
	# Paso 7: Volver a la cámara del jugador
	print("Paso 7: Volviendo a cámara del jugador...")
	if camara_jugador and camara_cinematica:
		camara_cinematica.current = false
		camara_jugador.current = true
		print("  Cámara del jugador activada!")
	
	# Mostrar el HUD normal
	if _hud and is_instance_valid(_hud):
		_hud.visible = true
	
	print("Paso 7 completado!")
	
	# Paso 8: Fade in de vuelta al interior
	print("Paso 8: Fade in final...")
	await _fade_a_claro()
	print("Paso 8 completado!")
	
	# Reactivar controles del jugador
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
	
	_durmiendo = false
	_label_interaccion.visible = true

	if GestorGameplay:
		GestorGameplay.iniciar_pausa_manana()

	print("☀️ Secuencia de dormir completada! Son las 8:00 AM (tiempo en pausa hasta abrir tienda)")

func _fade_a_negro() -> void:
	print("  _fade_a_negro: Iniciando...")
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_panel_fade, "color:a", 1.0, duracion_fade_out)
	print("  _fade_a_negro: Esperando tween...")
	await tween.finished
	print("  _fade_a_negro: Completado!")

func _fade_a_claro() -> void:
	print("  _fade_a_claro: Iniciando...")
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_panel_fade, "color:a", 0.0, duracion_fade_in)
	print("  _fade_a_claro: Esperando tween...")
	await tween.finished
	print("  _fade_a_claro: Completado!")
