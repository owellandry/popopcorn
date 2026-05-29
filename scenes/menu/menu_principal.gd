extends Node3D

@onready var btn_jugar: Button = $CanvasLayer/UI/Botones/BtnJugar
@onready var btn_opciones: Button = $CanvasLayer/UI/Botones/BtnOpciones
@onready var btn_puntajes: Button = $CanvasLayer/UI/Botones/BtnPuntajes
@onready var objetos: Node3D = $Objetos
@onready var objetos2: Node3D = $Objetos2

const MOUSE_INFLUENCE := 0.03  # qué tanto se mueven (radianes)
const SMOOTH_SPEED := 3.0  # velocidad de suavizado

var _target_rotation := Vector2.ZERO
var _viewport_size := Vector2(1920, 1080)

func _ready() -> void:
	btn_jugar.pressed.connect(_on_jugar)
	btn_opciones.pressed.connect(_on_opciones)
	btn_puntajes.pressed.connect(_on_puntajes)
	
	# Cache original viewport size and connect to resize signal
	_viewport_size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	_viewport_size = get_viewport().get_visible_rect().size

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Normalizar posición del mouse a rango -1 a 1 usando el tamaño cacheado
		var normalized: Vector2 = (event.position / _viewport_size - Vector2(0.5, 0.5)) * 2.0
		_target_rotation = normalized * MOUSE_INFLUENCE

func _process(delta: float) -> void:
	var target_y := _target_rotation.x
	var target_x := _target_rotation.y
	
	# Mover Objetos
	if objetos:
		if abs(objetos.rotation.y - target_y) > 0.0001 or abs(objetos.rotation.x - target_x) > 0.0001:
			objetos.rotation.y = lerp(objetos.rotation.y, target_y, delta * SMOOTH_SPEED)
			objetos.rotation.x = lerp(objetos.rotation.x, target_x, delta * SMOOTH_SPEED)
	
	# Mover Objetos2
	if objetos2:
		if abs(objetos2.rotation.y - target_y) > 0.0001 or abs(objetos2.rotation.x - target_x) > 0.0001:
			objetos2.rotation.y = lerp(objetos2.rotation.y, target_y, delta * SMOOTH_SPEED)
			objetos2.rotation.x = lerp(objetos2.rotation.x, target_x, delta * SMOOTH_SPEED)

func _on_jugar() -> void:
	# === TEMPORAL - Apuntando a AreaBase (la nueva área base) ===
	Transicion.transicionar("res://levels/AreaBase/AreaBase.tscn")
	
	# Para volver a la versión anterior (juego original), descomenta abajo:
	# Transicion.transicionar("res://scenes/juego/juego.tscn")

func _on_opciones() -> void:
	pass

func _on_puntajes() -> void:
	pass
