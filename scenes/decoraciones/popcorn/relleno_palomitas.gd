@tool
extends Node3D

@export var cantidad: int = 40
@export var radio_superior: float = 0.06
@export var altura_base: float = 0.18
@export var altura_variacion: float = 0.06

var popcorn_scene: PackedScene = preload("res://assets/models/machines/popcorn/popcorn.glb")

func _ready() -> void:
	# Only generate in editor. Runtime generation of many individual MeshInstances kills performance.
	if Engine.is_editor_hint():
		_generar_palomitas()

func _generar_palomitas() -> void:
	# Limpiar hijos previos (evita duplicados en editor)
	for child in get_children():
		child.queue_free()
	for i in range(cantidad):
		var instance: Node3D = popcorn_scene.instantiate()
		add_child(instance)
		
		# Posicion aleatoria en disco circular
		var angle := randf() * TAU
		var r := sqrt(randf()) * radio_superior
		var x := cos(angle) * r
		var z := sin(angle) * r
		var y := altura_base + randf() * altura_variacion
		# Efecto domo - mas al centro, mas arriba
		var centro_factor := 1.0 - (r / radio_superior)
		y += centro_factor * 0.03
		
		instance.position = Vector3(x, y, z)
		instance.rotation = Vector3(randf_range(-0.4, 0.4), randf() * TAU, randf_range(-0.4, 0.4))
		var s := 5.0
		instance.scale = Vector3(s, s, s)
