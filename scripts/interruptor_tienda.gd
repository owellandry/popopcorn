extends StaticBody3D
class_name InterruptorTienda

@export var letrero_asociado: Node3D
@export var texto_cerrado: String = "CERRADO"
@export var texto_abierto: String = "ABIERTO"
@export var distancia_interaccion: float = 2.5

var esta_abierto: bool = false
var mesh_texto: MeshInstance3D
var luz: OmniLight3D
var pivote_palanca: Node3D
var material_activo: StandardMaterial3D
var material_inactivo: StandardMaterial3D

var _jugador_cerca := false
var _ui_canvas_layer: CanvasLayer
var _label_interaccion: Label
var _hud: Node

var _panel_fade: ColorRect
var _fade_canvas_layer: CanvasLayer

func _ready() -> void:
	if letrero_asociado == null and get_parent():
		letrero_asociado = get_parent().get_node_or_null("LetreroTiendaAbierta") as Node3D

	mesh_texto = get_node_or_null("Texto")
	luz = get_node_or_null("Luz")
	pivote_palanca = get_node_or_null("PivotePalanca")
	
	material_activo = StandardMaterial3D.new()
	material_activo.albedo_color = Color(0, 1, 0.4, 1)
	material_activo.emission_enabled = true
	material_activo.emission = Color(0, 1, 0.4, 1)
	material_activo.emission_energy_multiplier = 4.0
	
	material_inactivo = StandardMaterial3D.new()
	material_inactivo.albedo_color = Color(0.15, 0.15, 0.15, 1)
	material_inactivo.emission_enabled = true
	material_inactivo.emission = Color(0.1, 0.1, 0.1, 1)
	material_inactivo.emission_energy_multiplier = 0.5
	
	_crear_ui_interaccion()
	_crear_panel_fade()
	_esperar_hud()
	_actualizar_estado()

func _process(_delta: float) -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Node3D
	if jugador == null:
		_jugador_cerca = false
	else:
		_jugador_cerca = jugador.global_position.distance_to(global_position) <= distancia_interaccion
		
	_actualizar_visibilidad_prompt()

func _actualizar_estado() -> void:
	if mesh_texto:
		if esta_abierto:
			mesh_texto.set_surface_override_material(0, material_activo)
		else:
			mesh_texto.set_surface_override_material(0, material_inactivo)
			
	if luz:
		if esta_abierto:
			luz.light_energy = 2.5
			luz.light_color = Color(0, 1, 0.4)
		else:
			luz.light_energy = 0.3
			luz.light_color = Color(0.5, 0.5, 0.5)
			
	if pivote_palanca:
		if is_inside_tree():
			var tween = create_tween()
			if esta_abierto:
				tween.tween_property(pivote_palanca, "rotation_degrees:x", 15.0, 0.15)
			else:
				tween.tween_property(pivote_palanca, "rotation_degrees:x", -15.0, 0.15)
		else:
			pivote_palanca.rotation_degrees.x = 15.0 if esta_abierto else -15.0
			
	if _label_interaccion:
		_label_interaccion.text = "[E] Cerrar tienda" if esta_abierto else "[E] Abrir tienda"

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
	get_tree().root.add_child.call_deferred(_fade_canvas_layer)

func toggle() -> void:
	if _panel_fade and _panel_fade.color.a > 0.0:
		return

	if not esta_abierto and GestorGameplay and not GestorGameplay.puede_abrir_tienda():
		if _label_interaccion:
			_label_interaccion.text = GestorGameplay.mensaje_no_puede_abrir_tienda()
		return
		
	# Deshabilitar controles del jugador
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.set_physics_process(false)
		jugador.set_process_input(false)
		
	# Ocultar el HUD normal y el prompt de interacción
	if _hud and is_instance_valid(_hud):
		_hud.visible = false
	if _ui_canvas_layer:
		_ui_canvas_layer.visible = false
		
	# Paso 1: Fade a negro
	await _fade_a_negro()
	
	# Paso 2: Activar cámara cinemática
	var camara_cinematica = get_node_or_null("/root/Juego/CamaraCinematica") as Camera3D
	if not camara_cinematica:
		camara_cinematica = get_node_or_null("/root/JuegoV2/CamaraCinematica") as Camera3D
	
	var camara_jugador: Camera3D
	if jugador and jugador.has_node("Camera3D"):
		camara_jugador = jugador.get_node("Camera3D") as Camera3D
	
	if camara_jugador and camara_cinematica:
		camara_jugador.current = false
		camara_cinematica.current = true
		
	# Paso 3: Fade in para ver la cinemática
	await _fade_a_claro()
	
	# Paso 4: Realizar el cambio de estado (encender/apagar)
	esta_abierto = not esta_abierto
	_actualizar_estado()
	if GestorGameplay:
		GestorGameplay.set_tienda_abierta(esta_abierto)
	if letrero_asociado and letrero_asociado.has_method("set_tienda_abierta"):
		letrero_asociado.set_tienda_abierta(esta_abierto)
		
	# Pequeña pausa para apreciar el cambio visual
	await get_tree().create_timer(1.5).timeout
	
	# Paso 5: Fade a negro de nuevo
	await _fade_a_negro()
	
	# Paso 6: Volver a la cámara del jugador
	if camara_jugador and camara_cinematica:
		camara_cinematica.current = false
		camara_jugador.current = true
		
	# Restaurar el HUD normal
	if _hud and is_instance_valid(_hud):
		_hud.visible = true
		
	# Paso 7: Fade in de vuelta al interior
	await _fade_a_claro()
	
	# Reactivar controles del jugador
	if jugador:
		jugador.set_physics_process(true)
		jugador.set_process_input(true)
		
	if _ui_canvas_layer:
		_ui_canvas_layer.visible = true

func _fade_a_negro() -> void:
	if not _panel_fade: return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_panel_fade, "color:a", 1.0, 1.0)
	await tween.finished

func _fade_a_claro() -> void:
	if not _panel_fade: return
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_panel_fade, "color:a", 0.0, 1.0)
	await tween.finished

func _crear_ui_interaccion() -> void:
	_ui_canvas_layer = CanvasLayer.new()
	add_child(_ui_canvas_layer)
	
	_label_interaccion = Label.new()
	_label_interaccion.text = "[E] Abrir tienda"
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
	
	_ui_canvas_layer.add_child(_label_interaccion)
	_ui_canvas_layer.visible = false

func _esperar_hud() -> void:
	await get_tree().process_frame
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

func _actualizar_visibilidad_prompt() -> void:
	if not _jugador_cerca:
		if _ui_canvas_layer: _ui_canvas_layer.visible = false
		return
	
	if _hud and _hud.has_method("puede_interactuar"):
		if _ui_canvas_layer: _ui_canvas_layer.visible = _hud.puede_interactuar(self, _jugador_cerca)
	else:
		if _ui_canvas_layer: _ui_canvas_layer.visible = false

func _input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	
	if event.is_action_pressed("interactuar"):
		if _hud and _hud.has_method("puede_interactuar"):
			if _hud.puede_interactuar(self, _jugador_cerca):
				toggle()

func puede_interactuar(_obj: Node, jugador_en_rango: bool) -> bool:
	if not jugador_en_rango:
		return false
	if _hud and _hud.has_method("estoy_mirando_objeto"):
		return _hud.estoy_mirando_objeto(self)
	return false
