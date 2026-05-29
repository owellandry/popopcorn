extends Node3D
class_name PuertaDoble

## Script para controlar una puerta doble de cristal premium
## Ambas hojas se abren simultáneamente hacia adentro (-Z local) al interactuar.

@export_group("Configuración")
@export var velocidad_apertura: float = 3.0
@export var angulo_apertura: float = 90.0  # El pivot izquierdo rotará +90, el derecho -90
@export var texto_cerrada: String = "Entrada Sala Premium"
@export var texto_interaccion: String = "Presiona E para abrir"

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

func _ready() -> void:
	if area_izq:
		area_izq.body_entered.connect(_on_jugador_entro)
		area_izq.body_exited.connect(_on_jugador_salio)
	if area_der:
		area_der.body_entered.connect(_on_jugador_entro)
		area_der.body_exited.connect(_on_jugador_salio)
	$CanvasLayer.visible = false

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
		_toggle_puerta()

func _toggle_puerta() -> void:
	if _animando:
		return
	_abierta = not _abierta
	_angulo_objetivo = angulo_apertura if _abierta else 0.0
	_animando = true
	_actualizar_label()

func _on_jugador_entro(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = true
		$CanvasLayer.visible = true
		_actualizar_label()

func _on_jugador_salio(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		_jugador_cerca = false
		$CanvasLayer.visible = false

func _actualizar_label() -> void:
	if label_ui:
		if _abierta:
			label_ui.text = "Presiona E para cerrar"
		else:
			label_ui.text = texto_interaccion
