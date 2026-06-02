extends CanvasLayer
class_name HUD

signal interactivo_libre(object_name: String, can_interact: bool)

static var instance

@export var ray_length: float = 5.0
@export var interact_group: String = "interactuable"

var _crosshair: Control
var _reloj: Label
var _default_color: Color = Color(1, 1, 1, 1)
var _highlight_color: Color = Color(1, 1, 0.3, 1)
var _current_interactive: Node = null

func _ready() -> void:
	instance = self
	_crosshair = $Crosshair/Plus
	_reloj = get_node_or_null("Reloj") as Label
	_crosshair.add_theme_font_size_override("font_size", 24)
	_crosshair.add_theme_color_override("font_color", _default_color)
	if _reloj and GestorGameplay:
		_actualizar_reloj()
		GestorGameplay.hora_actualizada.connect(_on_hora_actualizada)

func _on_hora_actualizada(_hora: int, _minuto: int, _progreso: float) -> void:
	_actualizar_reloj()

func _actualizar_reloj() -> void:
	if not _reloj or not GestorGameplay:
		return
	_reloj.text = GestorGameplay.obtener_texto_hora()
	if GestorGameplay.es_despues_de_las_9pm():
		_reloj.add_theme_color_override("font_color", Color(1, 0.75, 0.45, 1))
	else:
		_reloj.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _process(_delta: float) -> void:
	_actualizar_crosshair()

func _actualizar_crosshair() -> void:
	if not is_instance_valid(_crosshair):
		return

	var camera = get_viewport().get_camera_3d()
	if not camera:
		_limpiar_estado_interaccion()
		return

	var world := camera.get_world_3d()
	if not world:
		_limpiar_estado_interaccion()
		return
	var space_state = world.direct_space_state
	var origin = camera.global_position
	var direction = -camera.global_transform.basis.z

	var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * ray_length)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 0x7FFFFFFF
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador is CollisionObject3D:
		query.exclude = [(jugador as CollisionObject3D).get_rid()]

	var result = space_state.intersect_ray(query)

	if result and result.collider:
		var current_node = result.collider
		var interactable_node = null
		
		while current_node != null and current_node != get_tree().root:
			if _es_interactuable(current_node):
				interactable_node = current_node
				break
			current_node = current_node.get_parent()

		if interactable_node:
			_crosshair.add_theme_color_override("font_color", _highlight_color)
			if _current_interactive != interactable_node:
				_current_interactive = interactable_node
				interactivo_libre.emit(interactable_node.name, true)
			return

	_crosshair.add_theme_color_override("font_color", _default_color)
	if _current_interactive != null:
		_current_interactive = null
		interactivo_libre.emit("", false)

func _limpiar_estado_interaccion() -> void:
	_crosshair.add_theme_color_override("font_color", _default_color)
	if _current_interactive != null:
		_current_interactive = null
		interactivo_libre.emit("", false)

func _es_interactuable(node: Node) -> bool:
	if node.is_in_group(interact_group):
		return true
	if node.has_method("can_interact"):
		return true
	if node.name.to_lower().contains("puerta") or \
	   node.name.to_lower().contains("colchon") or \
	   node.name.to_lower().contains("mattres") or \
	   node.name.to_lower().contains("mattress") or \
	   node.name.to_lower().contains("pantalla") or \
	   node.name.to_lower().contains("pc") or \
	   node.name.to_lower().contains("cama"):
		return true
	return false

func estoy_mirando_objeto(obj: Node) -> bool:
	if _current_interactive == null:
		return false
	return _current_interactive == obj or _current_interactive.get_parent() == obj

func obtener_objeto_mirado() -> Node:
	return _current_interactive

func puede_interactuar(obj: Node, jugador_en_rango: bool) -> bool:
	if not jugador_en_rango:
		return false
	return estoy_mirando_objeto(obj)
