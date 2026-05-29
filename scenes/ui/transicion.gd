extends CanvasLayer

@onready var rect: ColorRect = $ColorRect
var _shader_material: ShaderMaterial
var _tween: Tween
const DURACION_CUBRIR := 0.8
const DURACION_REVELAR := 0.7

func _ready() -> void:
	layer = 100
	_shader_material = rect.material as ShaderMaterial
	_shader_material.set_shader_parameter("progress", 0.0)
	_shader_material.set_shader_parameter("reverse", false)
	rect.visible = false

func transicionar(escena_destino: String) -> void:
	rect.visible = true
	# Fase 1: Cubrir pantalla (palomitas caen de arriba a abajo)
	_shader_material.set_shader_parameter("reverse", false)
	_shader_material.set_shader_parameter("progress", 0.0)
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_progress, 0.0, 1.0, DURACION_CUBRIR)
	await _tween.finished
	
	# Pantalla completamente cubierta - ahora cargar escena
	# Iniciar carga en background
	var error := ResourceLoader.load_threaded_request(escena_destino)
	if error != OK:
		push_error("Error cargando escena: " + escena_destino)
		_revelar()
		return
	
	# Esperar a que cargue (pantalla sigue cubierta)
	while true:
		var status := ResourceLoader.load_threaded_get_status(escena_destino)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Fallo al cargar: " + escena_destino)
			_revelar()
			return
		await get_tree().process_frame
	
	# Cambiar escena mientras pantalla está cubierta
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(escena_destino)
	get_tree().change_scene_to_packed(packed_scene)
	
	# Esperar varios frames para que la nueva escena se renderice
	for i in range(5):
		await get_tree().process_frame
	
	# Fase 3: Revelar (palomitas caen hacia abajo)
	_revelar()

func _revelar() -> void:
	_shader_material.set_shader_parameter("reverse", true)
	_shader_material.set_shader_parameter("progress", 0.0)
	
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_progress, 0.0, 1.0, DURACION_REVELAR)
	await _tween.finished
	
	rect.visible = false
	_shader_material.set_shader_parameter("progress", 0.0)
	_shader_material.set_shader_parameter("reverse", false)

func _set_progress(value: float) -> void:
	_shader_material.set_shader_parameter("progress", value)
