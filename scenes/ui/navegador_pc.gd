extends Control
## Interfaz de navegador/PC con transición tipo View Transitions

signal cerrado

@export var duracion_transicion: float = 0.5

var _panel_principal: Panel
var _barra_superior: Panel
var _label_url: Label
var _btn_cerrar: Button
var _contenido: Panel
var _fondo_negro: ColorRect

func _ready() -> void:
	# Crear UI
	_crear_interfaz()
	
	# Iniciar con transición
	_animar_entrada()
	
	# NO cambiar el modo del mouse - mantener capturado

func _crear_interfaz() -> void:
	"""Crea la interfaz del navegador"""
	# Fondo negro semitransparente
	_fondo_negro = ColorRect.new()
	_fondo_negro.color = Color(0, 0, 0, 0)
	_fondo_negro.anchor_right = 1.0
	_fondo_negro.anchor_bottom = 1.0
	add_child(_fondo_negro)
	
	# Panel principal del navegador
	_panel_principal = Panel.new()
	_panel_principal.anchor_left = 0.5
	_panel_principal.anchor_top = 0.5
	_panel_principal.anchor_right = 0.5
	_panel_principal.anchor_bottom = 0.5
	_panel_principal.offset_left = -600
	_panel_principal.offset_top = -400
	_panel_principal.offset_right = 600
	_panel_principal.offset_bottom = 400
	_panel_principal.modulate = Color(1, 1, 1, 0)  # Invisible al inicio
	add_child(_panel_principal)
	
	# Barra superior
	_barra_superior = Panel.new()
	_barra_superior.custom_minimum_size = Vector2(0, 50)
	_barra_superior.anchor_right = 1.0
	add_child_to_panel(_panel_principal, _barra_superior)
	
	# Label de URL
	_label_url = Label.new()
	_label_url.text = "🌐 Cinema Manager v1.0"
	_label_url.add_theme_font_size_override("font_size", 20)
	_label_url.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_label_url.position = Vector2(20, 15)
	_barra_superior.add_child(_label_url)
	
	# Botón cerrar
	_btn_cerrar = Button.new()
	_btn_cerrar.text = "✕"
	_btn_cerrar.custom_minimum_size = Vector2(50, 50)
	_btn_cerrar.anchor_left = 1.0
	_btn_cerrar.anchor_right = 1.0
	_btn_cerrar.offset_left = -50
	_btn_cerrar.add_theme_font_size_override("font_size", 24)
	_btn_cerrar.pressed.connect(_on_cerrar_pressed)
	_barra_superior.add_child(_btn_cerrar)
	
	# Contenido del navegador
	_contenido = Panel.new()
	_contenido.anchor_top = 0.0625  # Después de la barra
	_contenido.anchor_right = 1.0
	_contenido.anchor_bottom = 1.0
	_contenido.offset_top = 50
	add_child_to_panel(_panel_principal, _contenido)
	
	# Contenido de ejemplo
	_crear_contenido_ejemplo()

func add_child_to_panel(parent: Panel, child: Node) -> void:
	"""Helper para agregar hijos al panel"""
	parent.add_child(child)

func _crear_contenido_ejemplo() -> void:
	"""Crea contenido de ejemplo para el navegador"""
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 20)
	_contenido.add_child(vbox)
	
	# Título
	var titulo = Label.new()
	titulo.text = "Sistema de Gestión del Cine"
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(titulo)
	
	# Descripción
	var desc = Label.new()
	desc.text = "Bienvenido al sistema de gestión de tu cine.\nAquí podrás administrar películas, horarios y más."
	desc.add_theme_font_size_override("font_size", 18)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	# Espaciador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer)
	
	# Botones de ejemplo
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	vbox.add_child(grid)
	
	var opciones = [
		"📽️ Gestionar Películas",
		"🎫 Vender Entradas",
		"📊 Ver Estadísticas",
		"⚙️ Configuración",
		"👥 Gestionar Personal",
		"🍿 Inventario Snacks"
	]
	
	for opcion in opciones:
		var btn = Button.new()
		btn.text = opcion
		btn.custom_minimum_size = Vector2(250, 80)
		btn.add_theme_font_size_override("font_size", 18)
		grid.add_child(btn)
	
	# Info al pie
	var info = Label.new()
	info.text = "Presiona ESC o el botón ✕ para cerrar"
	info.add_theme_font_size_override("font_size", 14)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(info)

func _animar_entrada() -> void:
	"""Animación de entrada tipo View Transitions"""
	# Fade in del fondo
	var tween_fondo = create_tween()
	tween_fondo.tween_property(_fondo_negro, "color:a", 0.8, duracion_transicion)
	
	# Escala y fade del panel
	_panel_principal.scale = Vector2(0.8, 0.8)
	_panel_principal.pivot_offset = _panel_principal.size / 2
	
	var tween_panel = create_tween()
	tween_panel.set_parallel(true)
	tween_panel.tween_property(_panel_principal, "scale", Vector2(1, 1), duracion_transicion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_panel.tween_property(_panel_principal, "modulate:a", 1.0, duracion_transicion)

func _animar_salida() -> void:
	"""Animación de salida tipo View Transitions"""
	# Fade out del fondo
	var tween_fondo = create_tween()
	tween_fondo.tween_property(_fondo_negro, "color:a", 0.0, duracion_transicion)
	
	# Escala y fade del panel
	var tween_panel = create_tween()
	tween_panel.set_parallel(true)
	tween_panel.tween_property(_panel_principal, "scale", Vector2(0.8, 0.8), duracion_transicion).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween_panel.tween_property(_panel_principal, "modulate:a", 0.0, duracion_transicion)
	
	await tween_panel.finished
	_cerrar()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancelar"):
		_on_cerrar_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()

func _on_cerrar_pressed() -> void:
	"""Cierra el navegador con animación"""
	_animar_salida()

func _cerrar() -> void:
	"""Cierra y elimina el navegador"""
	cerrado.emit()
	queue_free()
