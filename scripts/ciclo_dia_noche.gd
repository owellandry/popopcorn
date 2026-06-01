extends DirectionalLight3D

# Variables para controlar el ciclo
@export var ciclo_automatico: bool = true
@export var duracion_ciclo_normal: float = 120.0
@export var multiplicador_noche: float = 6.0
@export var multiplicador_dia: float = 0.5

var progreso_normalizado: float = 0.5
var velocidad_ciclo: float = 1.0
var es_noche: bool = false

var sky_material_cache: ShaderMaterial = null
var world_env_cache: WorldEnvironment = null

func _ready():
	_cargar_sky_material()
	actualizar_ciclo()

func _process(delta: float):
	if ciclo_automatico:
		var mult_tiempo = multiplicador_noche if es_noche else multiplicador_dia
		progreso_normalizado += (delta / duracion_ciclo_normal) * velocidad_ciclo * mult_tiempo
		if progreso_normalizado > 1.0:
			progreso_normalizado -= 1.0
		actualizar_ciclo()

func _a_rango_shader(progreso: float) -> float:
	return sin((progreso - 0.25) * PI * 2.0)

func _cargar_sky_material() -> void:
	world_env_cache = get_node_or_null("/root/Juego/WorldEnvironment") as WorldEnvironment
	if not world_env_cache:
		world_env_cache = get_node_or_null("/root/JuegoV2/WorldEnvironment") as WorldEnvironment
	
	if world_env_cache and world_env_cache.environment and world_env_cache.environment.sky:
		sky_material_cache = world_env_cache.environment.sky.sky_material
		print("✅ Sky material encontrado y cacheado!")
	else:
		print("⚠️ No se encontró el sky material!")

func avanzar_ciclo(_desde_normalizado: float, hasta_normalizado: float, duracion: float) -> void:
	if not world_env_cache or not sky_material_cache:
		_cargar_sky_material()
	
	var estaba_automatico = ciclo_automatico
	ciclo_automatico = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_method(
		func(x): 
			progreso_normalizado = x
			actualizar_ciclo(),
		_desde_normalizado,
		hasta_normalizado,
		duracion
	)
	
	await tween.finished
	ciclo_automatico = estaba_automatico
	print("✅ Ciclo completado!")

func actualizar_ciclo() -> void:
	rotation_degrees.x = lerp(90.0, -270.0, progreso_normalizado)
	
	if progreso_normalizado < 0.2 or progreso_normalizado > 0.8:
		light_energy = 0.0
		es_noche = true
	elif progreso_normalizado >= 0.2 and progreso_normalizado < 0.3:
		light_energy = lerp(0.0, 1.2, (progreso_normalizado - 0.2) / 0.1)
		es_noche = false
	elif progreso_normalizado > 0.7 and progreso_normalizado <= 0.8:
		light_energy = lerp(1.2, 0.0, (progreso_normalizado - 0.7) / 0.1)
		es_noche = false
	else:
		light_energy = 1.2
		es_noche = false
	
	if sky_material_cache:
		sky_material_cache.set_shader_parameter("day_night_mix", _a_rango_shader(progreso_normalizado))

func get_progreso_normalizado() -> float:
	return progreso_normalizado
