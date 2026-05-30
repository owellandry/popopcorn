extends Control
## Diálogo para pedir el nombre del cine al jugador

signal nombre_confirmado(nombre: String)

@onready var panel: Panel = $Panel
@onready var label_titulo: Label = $Panel/VBox/Titulo
@onready var label_descripcion: Label = $Panel/VBox/Descripcion
@onready var line_edit: LineEdit = $Panel/VBox/LineEdit
@onready var btn_confirmar: Button = $Panel/VBox/BtnConfirmar
@onready var label_error: Label = $Panel/VBox/LabelError

func _ready() -> void:
	# Crear UI si no existe
	if not has_node("Panel"):
		_crear_ui()
	
	# Conectar señales
	if btn_confirmar:
		btn_confirmar.pressed.connect(_on_confirmar_pressed)
	if line_edit:
		line_edit.text_submitted.connect(_on_text_submitted)
	
	# Pausar el juego
	get_tree().paused = true
	
	# Enfocar el campo de texto
	if line_edit:
		line_edit.grab_focus()

func _crear_ui() -> void:
	"""Crea la interfaz del diálogo"""
	# Panel principal
	panel = Panel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(500, 300)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -250
	panel.offset_top = -150
	panel.offset_right = 250
	panel.offset_bottom = 150
	add_child(panel)
	
	# VBox para organizar elementos
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# Título
	label_titulo = Label.new()
	label_titulo.name = "Titulo"
	label_titulo.text = "🎬 ¡Bienvenido a tu Cine! 🎬"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 28)
	vbox.add_child(label_titulo)
	
	# Descripción
	label_descripcion = Label.new()
	label_descripcion.name = "Descripcion"
	label_descripcion.text = "Antes de empezar, elige un nombre para tu cine:"
	label_descripcion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_descripcion.add_theme_font_size_override("font_size", 18)
	label_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(label_descripcion)
	
	# Campo de texto
	line_edit = LineEdit.new()
	line_edit.name = "LineEdit"
	line_edit.placeholder_text = "Escribe el nombre aquí..."
	line_edit.max_length = 20
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.add_theme_font_size_override("font_size", 24)
	line_edit.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(line_edit)
	
	# Label de error
	label_error = Label.new()
	label_error.name = "LabelError"
	label_error.text = ""
	label_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_error.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	label_error.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label_error)
	
	# Botón confirmar
	btn_confirmar = Button.new()
	btn_confirmar.name = "BtnConfirmar"
	btn_confirmar.text = "Confirmar"
	btn_confirmar.custom_minimum_size = Vector2(0, 50)
	btn_confirmar.add_theme_font_size_override("font_size", 20)
	vbox.add_child(btn_confirmar)

func _on_confirmar_pressed() -> void:
	_validar_y_confirmar()

func _on_text_submitted(_text: String) -> void:
	_validar_y_confirmar()

func _validar_y_confirmar() -> void:
	var nombre = line_edit.text.strip_edges()
	
	if nombre.is_empty():
		label_error.text = "⚠️ Por favor, escribe un nombre"
		return
	
	if nombre.length() < 3:
		label_error.text = "⚠️ El nombre debe tener al menos 3 caracteres"
		return
	
	# Nombre válido
	nombre_confirmado.emit(nombre)
	get_tree().paused = false
	queue_free()
