extends Node3D

@export var numero_sala: int = 1
@export var asientos: Array[Node3D] = []
@export var pantalla: Node3D = null

func _ready():
	if asientos.is_empty():
		_crear_asientos_default()

func _crear_asientos_default():
	for i in range(3):
		for j in range(5):
			var asiento = Node3D.new()
			asiento.name = "Asiento_%d_%d" % [i, j]
			asiento.position = Vector3(j * 1.2 - 2.4, 0, i * 1.5)
			add_child(asiento)
			asientos.append(asiento)

func asignar_asiento(cliente: CharacterBody3D) -> bool:
	for asiento in asientos:
		var libre = true
		# Aquí se podría checar si el asiento está ocupado
		if libre:
			cliente.sentarse(asiento)
			cliente.ver_pelicula()
			return true
	return false
