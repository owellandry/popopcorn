extends CharacterBody3D

# ================================================
# CONTROLADOR DEL PERSONAJE - VERSIÓN SIMPLE Y ROBUSTA
# ================================================

const SPEED = 5.5
const JUMP_VELOCITY = 4.2
const MOUSE_SENSITIVITY = 0.0018

@export var show_debug_mesh: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D
@onready var linterna: SpotLight3D = $Camera3D/Linterna
@onready var debug_mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	debug_mesh.visible = show_debug_mesh

	if linterna:
		# Configuración correcta de la linterna:
		# - Sin sombras (evita stutter y reduce costo)
		# - Pequeño offset hacia adelante para que no se recorte con el near plane
		# - Energía razonable
		linterna.shadow_enabled = false
		linterna.transform.origin = Vector3(0, 0, -0.35)
		linterna.light_energy = 3.5
	else:
		push_warning("[Personaje] No se encontró la Linterna")

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	# Click para recapturar ratón
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Alternar linterna (F)
	if event.is_action_pressed("toggle_flashlight"):
		_toggle_flashlight()
		get_viewport().set_input_as_handled()

	# ESC para liberar ratón
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# === MOVIMIENTO CON TECLAS DIRECTAS (LO MÁS SIMPLE Y CONFIABLE) ===
	var input_dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _toggle_flashlight() -> void:
	if linterna:
		linterna.visible = !linterna.visible
	else:
		push_warning("[Personaje] Linterna es null, no se puede alternar")
