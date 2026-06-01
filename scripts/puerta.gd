extends Node3D
class_name Puerta

## Configurable door with frame, panel, and handle.
## Supports open/close animation and optional authorization.

@export_group("Texturas")
@export var textura_puerta: Texture2D : set = _set_textura_puerta
@export var textura_marco: Texture2D : set = _set_textura_marco
@export var textura_normal_puerta: Texture2D : set = _set_normal_puerta
@export var textura_normal_marco: Texture2D : set = _set_normal_marco

@export_group("Configuración")
@export var requiere_autorizacion: bool = true
@export var velocidad_apertura: float = 2.0
@export var angulo_apertura: float = 90.0
@export var texto_cerrada: String = "Personal autorizado"
@export var texto_interaccion: String = "Presiona E para abrir"
@export var distancia_interaccion: float = 2.5

@onready var puerta_pivot: Node3D = $PuertaPivot
@onready var mesh_puerta: MeshInstance3D = $PuertaPivot/MeshPuerta
@onready var mesh_marco: MeshInstance3D = $Marco/MeshMarco
@onready var mesh_manilla: MeshInstance3D = $PuertaPivot/MeshManilla
@onready var area_interaccion: Area3D = $AreaInteraccion
@onready var label_ui: Label = $CanvasLayer/Label

var _abierta := false
var _animando := false
var _angulo_actual := 0.0
var _angulo_objetivo := 0.0
var _jugador_cerca := false
var _hud: Node

func _ready() -> void:
	if area_interaccion:
		area_interaccion.body_entered.connect(_on_jugador_entro)
		area_interaccion.body_exited.connect(_on_jugador_salio)
	$CanvasLayer.visible = false
	_esperar_hud()

func _set_textura_puerta(tex: Texture2D) -> void:
	textura_puerta = tex
	if is_inside_tree() and mesh_puerta:
		var mat: StandardMaterial3D = mesh_puerta.get_surface_override_material(0)
		if mat:
			mat.albedo_texture = tex

func _set_textura_marco(tex: Texture2D) -> void:
	textura_marco = tex
	if is_inside_tree() and mesh_marco:
		var mat: StandardMaterial3D = mesh_marco.get_surface_override_material(0)
		if mat:
			mat.albedo_texture = tex

func _set_normal_puerta(tex: Texture2D) -> void:
	textura_normal_puerta = tex
	if is_inside_tree() and mesh_puerta:
		var mat: StandardMaterial3D = mesh_puerta.get_surface_override_material(0)
		if mat:
			mat.normal_enabled = true
			mat.normal_texture = tex

func _set_normal_marco(tex: Texture2D) -> void:
	textura_normal_marco = tex
	if is_inside_tree() and mesh_marco:
		var mat: StandardMaterial3D = mesh_marco.get_surface_override_material(0)
		if mat:
			mat.normal_enabled = true
			mat.normal_texture = tex

func _process(delta: float) -> void:
	_actualizar_rango()
	_actualizar_visibilidad_prompt()
	if _animando:
		_angulo_actual = move_toward(_angulo_actual, _angulo_objetivo, velocidad_apertura * delta * 60.0)
		puerta_pivot.rotation_degrees.y = _angulo_actual
		if abs(_angulo_actual - _angulo_objetivo) < 0.1:
			_animando = false

func _actualizar_rango() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Node3D
	if jugador == null:
		_jugador_cerca = false
		return
	_jugador_cerca = jugador.global_position.distance_to(global_position) <= distancia_interaccion

func _input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	if event.is_action_pressed("interactuar"):
		if _hud and _hud.has_method("puede_interactuar"):
			if _hud.puede_interactuar(self, _jugador_cerca):
				_toggle_puerta()

func _toggle_puerta() -> void:
	if _animando:
		return
	_abierta = not _abierta
	_angulo_objetivo = angulo_apertura if _abierta else 0.0
	_animando = true
	_actualizar_label()

func _actualizar_visibilidad_prompt() -> void:
	if not _jugador_cerca:
		$CanvasLayer.visible = false
		return
	
	if _hud and _hud.has_method("puede_interactuar"):
		$CanvasLayer.visible = _hud.puede_interactuar(self, _jugador_cerca)
	else:
		$CanvasLayer.visible = false

func _on_jugador_entro(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = true
		_actualizar_label()

func _on_jugador_salio(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = false
		$CanvasLayer.visible = false

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

func _actualizar_label() -> void:
	if label_ui:
		if _abierta:
			label_ui.text = "Presiona E para cerrar"
		else:
			label_ui.text = texto_interaccion
