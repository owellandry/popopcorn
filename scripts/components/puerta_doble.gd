extends Node3D
class_name PuertaDoble

## Script para controlar una puerta doble de cristal premium
## Ambas hojas se abren simultáneamente hacia adentro (-Z local) al interactuar.

@export_group("Configuración")
@export var es_puerta_entrada_tienda: bool = false
@export var velocidad_apertura: float = 3.0
@export var angulo_apertura: float = 90.0  # El pivot izquierdo rotará +90, el derecho -90
@export var texto_cerrada: String = "Entrada Sala Premium"
@export var texto_interaccion: String = "Presiona E para abrir"
@export var distancia_interaccion: float = 2.5

@export_group("Vidrio unidireccional")
## Lado local desde el que se ve transparente (hacia el otro espacio). Por defecto +Z (manillas frontales).
@export var lado_transparente: Vector3 = Vector3(0.0, 0.0, 1.0)
@export var invertir_lados_vidrio: bool = false

@onready var pivot_izq: Node3D = $PivotIzq
@onready var pivot_der: Node3D = $PivotDer
@onready var area_izq: Area3D = $PivotIzq/AreaInteraccion
@onready var area_der: Area3D = $PivotDer/AreaInteraccion
@onready var label_ui: Label = $CanvasLayer/Label

var _abierta := false
var _animando := false
var _angulo_actual := 0.0
var _angulo_objetivo := 0.0
var _jugador_cerca := false
var _hud: Node

func _ready() -> void:
	if es_puerta_entrada_tienda:
		add_to_group("puerta_entrada_tienda")
	if area_izq:
		area_izq.body_entered.connect(_on_jugador_entro)
		area_izq.body_exited.connect(_on_jugador_salio)
	if area_der:
		area_der.body_entered.connect(_on_jugador_entro)
		area_der.body_exited.connect(_on_jugador_salio)
	$CanvasLayer.visible = false
	_aplicar_material_vidrio()
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

func _aplicar_material_vidrio() -> void:
	var dir := lado_transparente
	if invertir_lados_vidrio:
		dir = -dir
	for pivot in [pivot_izq, pivot_der]:
		if pivot == null:
			continue
		var vidrio := pivot.get_node_or_null("Vidrio") as MeshInstance3D
		if vidrio == null or vidrio.mesh == null:
			continue
		var mat := vidrio.get_surface_override_material(0)
		if mat == null:
			var base := vidrio.mesh.surface_get_material(0) as ShaderMaterial
			if base == null:
				continue
			mat = base.duplicate() as ShaderMaterial
			vidrio.set_surface_override_material(0, mat)
		if mat is ShaderMaterial:
			(mat as ShaderMaterial).set_shader_parameter("lado_transparente", dir)

func _physics_process(delta: float) -> void:
	if _animando:
		# Mover ángulo hacia el objetivo
		_angulo_actual = move_toward(_angulo_actual, _angulo_objetivo, velocidad_apertura * delta * 60.0)
		
		# Aplicar rotación (hoja izquierda abre positivo, hoja derecha abre negativo)
		if pivot_izq:
			pivot_izq.rotation_degrees.y = _angulo_actual
		if pivot_der:
			pivot_der.rotation_degrees.y = -_angulo_actual
			
		if abs(_angulo_actual - _angulo_objetivo) < 0.1:
			_angulo_actual = _angulo_objetivo
			if pivot_izq:
				pivot_izq.rotation_degrees.y = _angulo_actual
			if pivot_der:
				pivot_der.rotation_degrees.y = -_angulo_actual
			_animando = false

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
	_notificar_gestor()

func esta_abierta() -> bool:
	return _abierta

func cerrar_puerta() -> void:
	if _abierta and not _animando:
		_toggle_puerta()

func abrir_puerta() -> void:
	if not _abierta and not _animando:
		_toggle_puerta()

func _notificar_gestor() -> void:
	if es_puerta_entrada_tienda and GestorGameplay:
		GestorGameplay.notificar_puerta_entrada_cambiada()

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
