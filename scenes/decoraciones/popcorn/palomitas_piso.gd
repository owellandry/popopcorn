@tool
extends Node3D

@export var cantidad: int = 250
@export var radio_dispersion: float = 0.4
@export var altura_piso: float = 0.02

var popcorn_scene: PackedScene = preload("res://assets/models/machines/popcorn/popcorn.glb")

func _ready() -> void:
	# Only generate in editor for preview. At runtime this is extremely expensive (hundreds of nodes).
	if Engine.is_editor_hint():
		_generar_palomitas()

func _generar_palomitas() -> void:
	# Limpiar hijos previos (evita duplicados en editor)
	for child in get_children():
		child.queue_free()
	for i in range(cantidad):
		var instance: Node3D = popcorn_scene.instantiate()
		add_child(instance)
		
		# Posicion aleatoria en area circular en el suelo
		var angle := randf() * TAU
		var r := sqrt(randf()) * radio_dispersion
		var x := cos(angle) * r
		var z := sin(angle) * r
		
		instance.position = Vector3(x, altura_piso, z)
		instance.rotation = Vector3(randf_range(-1.0, 1.0), randf() * TAU, randf_range(-1.0, 1.0))
		var s := randf_range(0.015, 0.03)
		instance.scale = Vector3(s, s, s)
