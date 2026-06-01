extends Control

var cliente_actual: CharacterBody3D = null
var ui_canvas: CanvasLayer

func _ready():
	_crear_ui()

func _crear_ui():
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 200
	
	var fondo = ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = Color(0, 0, 0, 0.85)
	fondo.anchor_right = 1.0
	fondo.anchor_bottom = 1.0
	
	var panel = Control.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -320
	panel.offset_top = -220
	panel.offset_right = 320
	panel.offset_bottom = 220
	
	var titulo = Label.new()
	titulo.name = "Titulo"
	titulo.text = "Cliente!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1))
	titulo.anchor_left = 0.0
	titulo.anchor_top = 0.0
	titulo.anchor_right = 1.0
	titulo.anchor_bottom = 0.2
	
	var texto = Label.new()
	texto.name = "Texto"
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	texto.add_theme_font_size_override("font_size", 22)
	texto.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	texto.add_theme_constant_override("line_spacing", 6)
	texto.anchor_left = 0.0
	texto.anchor_top = 0.2
	texto.anchor_right = 1.0
	texto.anchor_bottom = 0.7
	
	var boton_ver = Button.new()
	boton_ver.name = "BotonVer"
	boton_ver.text = "Dar entrada ✔"
	boton_ver.add_theme_font_size_override("font_size", 20)
	boton_ver.anchor_left = 0.0
	boton_ver.anchor_top = 0.75
	boton_ver.anchor_right = 1.0
	boton_ver.anchor_bottom = 0.92
	
	var boton_cerrar = Button.new()
	boton_cerrar.name = "BotonCerrar"
	boton_cerrar.text = "Cerrar [Esc]"
	boton_cerrar.add_theme_font_size_override("font_size", 16)
	boton_cerrar.anchor_left = 0.0
	boton_cerrar.anchor_top = 0.92
	boton_cerrar.anchor_right = 1.0
	boton_cerrar.anchor_bottom = 1.0
	
	panel.add_child(titulo)
	panel.add_child(texto)
	panel.add_child(boton_ver)
	panel.add_child(boton_cerrar)
	ui_canvas.add_child(fondo)
	ui_canvas.add_child(panel)
	add_child(ui_canvas)
	
	boton_ver.pressed.connect(_dar_entrada)
	boton_cerrar.pressed.connect(_cerrar)
	
	ocultar()

func mostrar(cliente: CharacterBody3D):
	cliente_actual = cliente
	
	var titulo = ui_canvas.get_node("Panel/Titulo") as Label
	titulo.text = "¡Un cliente!"
	
	var texto = ui_canvas.get_node("Panel/Texto") as Label
	texto.text = "¡Hola! Quiero ver \"%s\", por favor.\n\nPor favor, me das una entrada para la sala %d?" % [cliente.nombre_pelicula, cliente.sala_asignada]
	
	ui_canvas.visible = true
	ui_canvas.get_node("Fondo").visible = true
	ui_canvas.get_node("Panel").visible = true

func ocultar():
	cliente_actual = null
	ui_canvas.visible = false

func _dar_entrada():
	if cliente_actual:
		print("Entrada dada para %s en sala %d!" % [cliente_actual.nombre_pelicula, cliente_actual.sala_asignada])
		var sistema_fila = get_tree().get_first_node_in_group("sistema_fila")
		if sistema_fila:
			sistema_fila.atender_cliente()
		ocultar()

func _cerrar():
	ocultar()

func _input(event):
	if ui_canvas.visible:
		if event.is_action_pressed("ui_cancel"):
			_cerrar()
