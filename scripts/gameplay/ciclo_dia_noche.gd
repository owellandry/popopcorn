extends DirectionalLight3D

@export var ciclo_automatico: bool = true
## 24 minutos reales = 24 horas de juego (1 minuto real por hora)
@export var duracion_ciclo_normal: float = 1440.0
@export var multiplicador_noche: float = 1.0
@export var multiplicador_dia: float = 1.0

var progreso_normalizado: float = 0.3333
var velocidad_ciclo: float = 1.0
var es_noche: bool = false

var sky_material_cache: ShaderMaterial = null
var world_env_cache: WorldEnvironment = null

func _ready() -> void:
	add_to_group("sol_ciclo")
	progreso_normalizado = 0.3333
	ciclo_automatico = false
	if _es_sol_principal():
		_cargar_sky_material()
	actualizar_ciclo()

func _es_sol_principal() -> bool:
	return get_tree().get_first_node_in_group("sol_ciclo") == self

func _process(delta: float) -> void:
	if not _es_sol_principal():
		_sincronizar_desde_principal()
		return
	if ciclo_automatico and (not GestorGameplay or not GestorGameplay.tiempo_pausado):
		var mult_tiempo = multiplicador_noche if es_noche else multiplicador_dia
		progreso_normalizado += (delta / duracion_ciclo_normal) * velocidad_ciclo * mult_tiempo
		if progreso_normalizado > 1.0:
			progreso_normalizado -= 1.0
		actualizar_ciclo()
	else:
		if GestorGameplay and GestorGameplay.tiempo_pausado:
			pass  # pausado normal

func _mezcla_dia_noche(progreso: float) -> float:
	if progreso < 0.2 or progreso > 0.8:
		return -1.0
	elif progreso < 0.3:
		return lerpf(-1.0, 1.0, (progreso - 0.2) / 0.1)
	elif progreso > 0.7:
		return lerpf(1.0, -1.0, (progreso - 0.7) / 0.1)
	else:
		return 1.0

func _cargar_sky_material() -> void:
	world_env_cache = get_node_or_null("/root/Juego/WorldEnvironment") as WorldEnvironment
	if not world_env_cache:
		world_env_cache = get_node_or_null("/root/JuegoV2/WorldEnvironment") as WorldEnvironment

	if world_env_cache and world_env_cache.environment and world_env_cache.environment.sky:
		sky_material_cache = world_env_cache.environment.sky.sky_material as ShaderMaterial

func _sincronizar_desde_principal() -> void:
	var principal = get_tree().get_first_node_in_group("sol_ciclo")
	if principal and principal != self:
		progreso_normalizado = principal.progreso_normalizado
		rotation_degrees.x = principal.rotation_degrees.x
		light_energy = principal.light_energy

func _aplicar_a_todas_luces() -> void:
	for sol in get_tree().get_nodes_in_group("sol_ciclo"):
		if sol == self:
			continue
		sol.progreso_normalizado = progreso_normalizado
		sol.rotation_degrees.x = rotation_degrees.x
		sol.light_energy = light_energy
		sol.es_noche = es_noche

func avanzar_ciclo(desde_normalizado: float, hasta_normalizado: float, duracion: float) -> void:
	if not _es_sol_principal():
		var principal = get_tree().get_first_node_in_group("sol_ciclo")
		if principal:
			await principal.avanzar_ciclo(desde_normalizado, hasta_normalizado, duracion)
		return

	if not world_env_cache or not sky_material_cache:
		_cargar_sky_material()

	var estaba_automatico = ciclo_automatico
	ciclo_automatico = false
	progreso_normalizado = desde_normalizado
	actualizar_ciclo()

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(x: float) -> void:
			progreso_normalizado = x
			actualizar_ciclo(),
		desde_normalizado,
		hasta_normalizado,
		duracion
	)

	await tween.finished
	ciclo_automatico = estaba_automatico
	if GestorGameplay:
		GestorGameplay.actualizar_tiempo(progreso_normalizado)

func actualizar_ciclo() -> void:
	rotation_degrees.x = lerpf(90.0, -270.0, progreso_normalizado)

	if progreso_normalizado < 0.2 or progreso_normalizado > 0.8:
		light_energy = 0.0
		es_noche = true
	elif progreso_normalizado >= 0.2 and progreso_normalizado < 0.3:
		light_energy = lerpf(0.0, 1.2, (progreso_normalizado - 0.2) / 0.1)
		es_noche = false
	elif progreso_normalizado > 0.7 and progreso_normalizado <= 0.8:
		light_energy = lerpf(1.2, 0.0, (progreso_normalizado - 0.7) / 0.1)
		es_noche = false
	else:
		light_energy = 1.2
		es_noche = false

	if _es_sol_principal() and sky_material_cache:
		sky_material_cache.set_shader_parameter("day_night_mix", _mezcla_dia_noche(progreso_normalizado))

	_aplicar_a_todas_luces()
	if _es_sol_principal() and GestorGameplay:
		GestorGameplay.actualizar_tiempo(progreso_normalizado)

func get_progreso_normalizado() -> float:
	return progreso_normalizado
